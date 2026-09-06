#include "assistant_worker.h"

#include <cstring>
#include <filesystem>

#include <QDebug>

void callPartiallyUpdate(const char *text)
{
    if (text != nullptr)
        qDebug() << "assistant_worker: partial token (unused):" << text;
}

assistant_worker::assistant_worker(QObject *parent) : QObject(parent)
{
    memset(&m_inference, 0, sizeof(llama_inference));
    memset(&m_state, 0, sizeof(state_type));
}

assistant_worker::~assistant_worker()
{
    free_ptr(&m_state);
    free_llama_inference(&m_inference);
}

void assistant_worker::init(const QString &configPath)
{
    if (configPath.isEmpty()) {
        emit errorOccurred(QStringLiteral("init() called without a config path"));
        return;
    }

    if (m_config.load_config(configPath.toStdString()) != 0) {
        emit errorOccurred(QStringLiteral("Failed to load config from %1").arg(configPath));
        return;
    }

    const std::string cachePath = m_config.get_cache_path();
    const bool cacheExistedBefore = !cachePath.empty() && std::filesystem::exists(cachePath);

    init_default_state(&m_state, m_config.get_system_prompt().c_str());
    load_backend();

    m_inference.n_threads = m_config.get_n_threads();
    m_inference.n_batch   = m_config.get_n_batch();
    m_inference.n_ctx      = m_config.get_n_ctx();

    if (load_model(m_config.get_model_path().c_str(), &m_inference) != 0) {
        emit errorOccurred(QStringLiteral("Failed to load model from %1")
                                .arg(QString::fromStdString(m_config.get_model_path())));
        return;
    }
    if (get_vocab(&m_inference) != 0) {
        emit errorOccurred(QStringLiteral("get_vocab failed"));
        return;
    }
    if (create_ctx(&m_inference) != 0) {
        emit errorOccurred(QStringLiteral("create_ctx failed"));
        return;
    }
    if (set_sampler(&m_inference) != 0) {
        emit errorOccurred(QStringLiteral("set_sampler failed"));
        return;
    }

    bool needsDigest = !cacheExistedBefore;
    if (cacheExistedBefore) {
        if (load_memory(cachePath.c_str(), &m_inference) != 0) {
            qWarning() << "assistant_worker: cache load failed, rebuilding";
            needsDigest = true;
        }
    }

    if (needsDigest) {
        if (allocate_prompt(&m_inference, &m_state) != 0) {
            emit errorOccurred(QStringLiteral("allocate_prompt failed"));
            return;
        }
        if (digest_prompt(&m_inference) != 0) {
            emit errorOccurred(QStringLiteral("digest_prompt failed"));
            return;
        }
        if (!cachePath.empty() && save_memory(cachePath.c_str(), &m_inference) != 0)
            qWarning() << "assistant_worker: failed to save kv-cache (non-fatal)";
    }

    m_state.kv_applied_chars = m_state.messages != nullptr ? strlen(m_state.messages) : 0;
    m_loaded = true;

    emit ready();
}

bool assistant_worker::updateMessages(const std::string &userPrompt)
{
    m_state.messages = extend_messages(m_state.messages, "<|im_start|>user\n");
    if (m_state.messages == nullptr) return false;

    m_state.messages = extend_messages(m_state.messages, userPrompt.c_str());
    if (m_state.messages == nullptr) return false;

    const char *turnClose = m_config.is_thinker()
        ? "<|im_end|><|im_start|>assistant\n<think>\n\n</think>\n\n"
        : "<|im_end|><|im_start|>assistant\n";

    m_state.messages = extend_messages(m_state.messages, turnClose);
    return m_state.messages != nullptr;
}

void assistant_worker::ask(const QString &userPrompt)
{
    if (!m_loaded) {
        emit errorOccurred(QStringLiteral("ask() called before init() completed"));
        return;
    }

    if (!updateMessages(userPrompt.toStdString())) {
        emit errorOccurred(QStringLiteral("failed to extend message buffer (out of memory?)"));
        return;
    }

    if (allocate_prompt(&m_inference, &m_state) != 0) {
        emit errorOccurred(QStringLiteral("allocate_prompt failed"));
        return;
    }

    if (run_inference(&m_inference, &m_state) != 0) {
        emit errorOccurred(QStringLiteral("inference failed"));
        return;
    }

    if (is_agent_called(m_state.assistant_response)) {
        const std::string agentId = extract_agent_id(m_state.assistant_response);
        emit errorOccurred(QStringLiteral(
            "Model requested agent '%1' but agent dispatch isn't implemented yet")
                                .arg(QString::fromStdString(agentId)));
    }

    m_state.messages = extend_messages(m_state.messages, m_state.assistant_response);
    if (m_state.messages != nullptr) {
        m_state.kv_applied_chars = strlen(m_state.messages);
        m_state.messages = extend_messages(m_state.messages, "<|im_end|>");
    }

    emit responseReady(QString::fromUtf8(m_state.assistant_response));
}
