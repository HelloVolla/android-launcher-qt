#ifndef ASSISTANT_H
#define ASSISTANT_H

#include <QObject>
#include <QString>
#include <QThread>

/*
 * On-device assistant, exposed to QML as the "assistant" context property.
 *
 */

class AssistantEngine : public QObject
{
    Q_OBJECT

public:
    explicit AssistantEngine(QObject *parent = nullptr);
    ~AssistantEngine() override;

    // Called from the inference callback, on this object's thread.
    void reportPartial(const QString &text);

public slots:
    void load();
    void query(const QString &prompt);

signals:
    void loaded();
    // The engine freed its state and has to be loaded again before the next query.
    void unloaded();
    void failed(const QString &message);
    void partial(const QString &text);
    void answered(const QString &text);

private:
    // Free the native state and report that a reload is needed.
    void unload();

    bool m_loaded = false;
    bool m_isThinker = false;
};

class Assistant : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool available READ available CONSTANT)
    Q_PROPERTY(bool ready READ ready NOTIFY readyChanged)

public:
    explicit Assistant(QObject *parent = nullptr);
    ~Assistant() override;

    bool available() const;
    bool ready() const { return m_ready; }

public slots:
    // Load the model.
    void init();
    // Ask the assistant. Queued behind init(), so it is safe to call while
    // the model is still loading.
    void ask(const QString &prompt);

signals:
    void readyChanged();
    void error(const QString &message);
    void partialResponse(const QString &text);
    void response(const QString &text);

    void loadRequested();
    void queryRequested(const QString &prompt);

private:
    QThread m_thread;
    AssistantEngine *m_engine = nullptr;
    bool m_ready = false;
    bool m_startRequested = false;
};

#endif // ASSISTANT_H
