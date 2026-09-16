#include "assistant.h"

#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QStandardPaths>

#ifdef VOLLA_ASSISTANT

#include <string.h>

#include "agent_core.h"
#include "config.h"
#include "inference.h"
#include "states.h"

namespace {

llama_inference g_inference;
state_type g_state;

AssistantEngine *g_streaming = nullptr;

void releaseAssistant()
{
    free_ptr(&g_state);
    free_llama_inference(&g_inference);
}

int validUtf8PrefixLength(const char *text)
{
    if (text == nullptr)
        return 0;

    const unsigned char *bytes = reinterpret_cast<const unsigned char *>(text);
    int pos = 0;

    while (bytes[pos] != '\0') {
        const unsigned char c = bytes[pos];
        int len = 0;

        if (c <= 0x7F)
            len = 1;
        else if ((c >> 5) == 0x6)
            len = 2;
        else if ((c >> 4) == 0xE)
            len = 3;
        else if ((c >> 3) == 0x1E)
            len = 4;
        else
            break;

        for (int i = 1; i < len; ++i) {
            if ((bytes[pos + i] >> 6) != 0x2)
                return pos;
        }
        pos += len;
    }

    return pos;
}

QString toString(const char *text)
{
    return QString::fromUtf8(text, validUtf8PrefixLength(text));
}

void appendUserTurn(const QString &prompt, bool thinker)
{
    const QByteArray utf8 = prompt.toUtf8();

    g_state.messages = extend_messages(g_state.messages, "<|im_start|>user\n");
    if (g_state.messages == nullptr)
        return;

    g_state.messages = extend_messages(g_state.messages, utf8.constData());
    if (g_state.messages == nullptr)
        return;

    g_state.messages = extend_messages(g_state.messages,
                                       thinker
                                           ? "<|im_end|><|im_start|>assistant\n<think>\n\n</think>\n\n"
                                           : "<|im_end|><|im_start|>assistant\n");
}

void appendAssistantTurn()
{
    if (g_state.messages == nullptr)
        return;

    g_state.messages = extend_messages(g_state.messages, g_state.assistant_response);
    if (g_state.messages == nullptr)
        return;

    g_state.kv_applied_chars = strlen(g_state.messages);
    g_state.messages = extend_messages(g_state.messages, "<|im_end|>");
}

} // namespace

// Defined by the host application; the assistant core calls it once per token.
void callPartiallyUpdate(const char *text)
{
    if (g_streaming != nullptr)
        g_streaming->reportPartial(toString(text));
}

#endif // VOLLA_ASSISTANT

AssistantEngine::AssistantEngine(QObject *parent)
    : QObject(parent)
{
}

AssistantEngine::~AssistantEngine()
{
#ifdef VOLLA_ASSISTANT
    if (m_loaded)
        releaseAssistant();
#endif
}

void AssistantEngine::reportPartial(const QString &text)
{
    emit partial(text);
}

void AssistantEngine::unload()
{
#ifdef VOLLA_ASSISTANT
    releaseAssistant();
#endif
    if (m_loaded) {
        m_loaded = false;
        emit unloaded();
    }
}

void AssistantEngine::load()
{
#ifndef VOLLA_ASSISTANT
    emit failed(tr("This build has no assistant"));
#else
    if (m_loaded)
        return;

    const QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    const QString cacheDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation)
                             + QStringLiteral("/assistant");

    const QString configPath = dataDir + QStringLiteral("/configs/assistant_config.json");
    const QString modelPath = dataDir + QStringLiteral("/models/assistant/model.gguf");
    const QString cachePath = cacheDir + QStringLiteral("/cache.bin");

    if (!QFileInfo::exists(configPath)) {
        emit failed(tr("Assistant config is missing at %1").arg(configPath));
        return;
    }
    if (!QFileInfo::exists(modelPath)) {
        emit failed(tr("Assistant model is missing at %1").arg(modelPath));
        return;
    }
    QDir().mkpath(cacheDir);

    const QByteArray configUtf8 = configPath.toUtf8();
    const QByteArray modelUtf8 = modelPath.toUtf8();
    const QByteArray cacheUtf8 = cachePath.toUtf8();

    memset(&g_inference, 0, sizeof(llama_inference));
    memset(&g_state, 0, sizeof(state_type));

    model_config config;
    if (config.load_config(configUtf8.constData()) != 0) {
        emit failed(tr("The assistant config could not be loaded"));
        return;
    }

    m_isThinker = config.is_thinker();

    const std::string systemPrompt = config.get_system_prompt();
    init_default_state(&g_state, systemPrompt.c_str());
    load_backend();

    g_inference.n_threads = config.get_n_threads();
    g_inference.n_batch = config.get_n_batch();
    g_inference.n_ctx = config.get_n_ctx();

    qDebug() << "Assistant | Loading model" << modelPath;

    if (load_model(modelUtf8.constData(), &g_inference) != 0) {
        releaseAssistant();
        emit failed(tr("The assistant model could not be loaded"));
        return;
    }
    if (get_vocab(&g_inference) != 0) {
        releaseAssistant();
        emit failed(tr("The assistant vocabulary could not be read"));
        return;
    }
    if (create_ctx(&g_inference) != 0) {
        releaseAssistant();
        emit failed(tr("The assistant context could not be created"));
        return;
    }
    if (set_sampler(&g_inference) != 0) {
        releaseAssistant();
        emit failed(tr("The assistant sampler could not be created"));
        return;
    }

    if (QFileInfo::exists(cachePath) && load_memory(cacheUtf8.constData(), &g_inference) == 0) {
        qDebug() << "Assistant | Reused the kv-cache at" << cachePath;
    } else {
        if (allocate_prompt(&g_inference, &g_state) != 0 || digest_prompt(&g_inference) != 0) {
            releaseAssistant();
            emit failed(tr("The assistant prompt could not be prepared"));
            return;
        }
        if (save_memory(cacheUtf8.constData(), &g_inference) != 0)
            qDebug() << "Assistant | Could not save the kv-cache (non-fatal)";
    }

    g_state.kv_applied_chars = g_state.messages != nullptr ? strlen(g_state.messages) : 0;
    m_loaded = true;

    qDebug() << "Assistant | Ready," << g_state.kv_applied_chars << "prompt chars digested";
    emit loaded();
#endif
}

void AssistantEngine::query(const QString &prompt)
{
#ifndef VOLLA_ASSISTANT
    Q_UNUSED(prompt)
    emit failed(tr("This build has no assistant"));
#else
    if (!m_loaded) {
        emit failed(tr("The assistant is not available"));
        return;
    }

    appendUserTurn(prompt, m_isThinker);
    if (g_state.messages == nullptr) {
        unload();
        emit failed(tr("The assistant prompt could not be prepared"));
        return;
    }

    if (allocate_prompt(&g_inference, &g_state) != 0) {
        unload();
        emit failed(tr("The assistant prompt could not be prepared"));
        return;
    }

    qDebug() << "Assistant | Running inference";

    g_streaming = this;
    const int res = run_inference_stream(&g_inference, &g_state);
    g_streaming = nullptr;

    if (res != 0) {
        unload();
        emit failed(tr("The assistant failed to answer"));
        return;
    }

    appendAssistantTurn();

    const QString answer = toString(g_state.assistant_response);

    if (is_agent_called(answer.toStdString())) {
        const QString agentId = QString::fromStdString(extract_agent_id(answer.toStdString()));
        qDebug() << "Assistant | The model requested agent" << agentId;
        emit failed(tr("Agent '%1' is not available yet").arg(agentId));
        return;
    }

    emit answered(answer);
#endif
}

Assistant::Assistant(QObject *parent)
    : QObject(parent)
    , m_engine(new AssistantEngine)
{
    m_engine->moveToThread(&m_thread);

    connect(&m_thread, &QThread::finished, m_engine, &QObject::deleteLater);
    connect(this, &Assistant::loadRequested, m_engine, &AssistantEngine::load);
    connect(this, &Assistant::queryRequested, m_engine, &AssistantEngine::query);

    connect(m_engine, &AssistantEngine::loaded, this, [this]() {
        m_ready = true;
        emit readyChanged();
    });
    connect(m_engine, &AssistantEngine::unloaded, this, [this]() {
        m_startRequested = false;
        if (m_ready) {
            m_ready = false;
            emit readyChanged();
        }
    });
    connect(m_engine, &AssistantEngine::failed, this, [this](const QString &message) {
        qWarning() << "Assistant |" << message;
        if (!m_ready)
            m_startRequested = false;
        emit error(message);
    });
    connect(m_engine, &AssistantEngine::partial, this, &Assistant::partialResponse);
    connect(m_engine, &AssistantEngine::answered, this, &Assistant::response);

    m_thread.start();
}

Assistant::~Assistant()
{
    m_thread.quit();
    m_thread.wait();
}

bool Assistant::available() const
{
#ifdef VOLLA_ASSISTANT
    return true;
#else
    return false;
#endif
}

void Assistant::init()
{
    if (m_startRequested)
        return;
    m_startRequested = true;

    qDebug() << "Assistant | Init requested";
    emit loadRequested();
}

void Assistant::ask(const QString &prompt)
{
    if (prompt.trimmed().isEmpty())
        return;

    qDebug() << "Assistant | Ask:" << prompt;
    emit queryRequested(prompt);
}
