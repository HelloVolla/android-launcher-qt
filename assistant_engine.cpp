#include "assistant_engine.h"

#include <QDebug>
#include <QFileInfo>

#include "assistant_paths.h"
#include "assistant_worker.h"

assistant_engine::assistant_engine(QObject *parent) : QObject(parent)
{
    m_worker = new assistant_worker;
    m_worker->moveToThread(&m_thread);
    connect(&m_thread, &QThread::finished, m_worker, &QObject::deleteLater);

    connect(this, &assistant_engine::initRequested, m_worker, &assistant_worker::init);
    connect(this, &assistant_engine::askRequested, m_worker, &assistant_worker::ask);

    connect(m_worker, &assistant_worker::ready, this, [this] {
        m_ready = true;
        emit readyChanged();
        setBusy(false);
    });
    connect(m_worker, &assistant_worker::responseReady, this, [this](const QString &reply) {
        setBusy(false);
        emit responseReady(reply);
    });
    connect(m_worker, &assistant_worker::errorOccurred, this, [this](const QString &message) {
        qWarning() << "assistant_engine |" << message;
        setBusy(false);
        emit errorOccurred(message);
    });

    m_thread.start();
}

assistant_engine::~assistant_engine()
{
    m_thread.quit();
    m_thread.wait();
}

void assistant_engine::setBusy(bool busy)
{
    if (m_busy == busy)
        return;
    m_busy = busy;
    emit busyChanged();
}

void assistant_engine::start()
{
    if (m_started)
        return;

    const QString configPath = AssistantPaths::assistantConfig();
    if (!QFileInfo::exists(configPath)) {
        emit errorOccurred(tr("Assistant config is missing at %1").arg(configPath));
        return;
    }

    m_started = true;
    setBusy(true);
    qDebug() << "assistant_engine | loading model, config:" << configPath;
    emit initRequested(configPath);
}

void assistant_engine::ask(const QString &prompt)
{
    if (prompt.trimmed().isEmpty())
        return;

    if (!m_ready) {
        start();
        emit errorOccurred(tr("The assistant is still starting up"));
        return;
    }
    if (m_busy) {
        emit errorOccurred(tr("The assistant is still answering"));
        return;
    }

    setBusy(true);
    emit askRequested(prompt);
}
