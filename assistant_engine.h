#ifndef ASSISTANT_ENGINE_H
#define ASSISTANT_ENGINE_H

#include <QObject>
#include <QString>
#include <QThread>

class assistant_worker;
// The assistant_engine class manages the assistant_worker.
class assistant_engine : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool ready READ isReady NOTIFY readyChanged)
    Q_PROPERTY(bool busy READ isBusy NOTIFY busyChanged)

public:
    explicit assistant_engine(QObject *parent = nullptr);
    ~assistant_engine() override;

    bool isReady() const { return m_ready; }
    bool isBusy() const { return m_busy; }

    // Initalize engine.
    Q_INVOKABLE void start();

    // Invoke the assistant with a prompt.
    Q_INVOKABLE void ask(const QString &prompt);

signals:
    void readyChanged();
    void busyChanged();
    void responseReady(const QString &reply);
    void errorOccurred(const QString &message);

    void initRequested(const QString &configPath);
    void askRequested(const QString &prompt);

private:
    // Set the busy state.
    void setBusy(bool busy);

    QThread m_thread;
    assistant_worker *m_worker = nullptr;
    bool m_ready = false;
    bool m_busy = false;
    bool m_started = false;
};

#endif 
