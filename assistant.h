#ifndef ASSISTANT_H
#define ASSISTANT_H

#include <QObject>
#include <QString>
#include <QThread>
#include <QVariantMap>
#include <QUrl>
#include <QStandardPaths>

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

public slots:
    void load();
    void query(const QString &prompt);
    // Pick the app that should handle the prompt and report it via decided().
    void decide(const QString &prompt, const QStringList & keys, const QStringList & desc,
                const QString & rule, qint16 nOptions);

signals:
    void loaded();
    // The engine freed its state and has to be loaded again before the next query.
    void unloaded();
    void failed(const QString &message);
    void answered(const QString &text);
    // key, best, value, confidence, actProbability, temperature, nTokens, probs
    void decided(const QVariantMap &answer);

private:
    #define RULE "Select the application that will be helpfull based on user's query, user's query will be one of German, Dutch, Norwegian or English."
    // Free the native state and report that a reload is needed.
    void unload();

    bool m_loaded = false;
    bool m_isThinker = false;
};

class Assistant : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool ready READ ready NOTIFY readyChanged)
    Q_PROPERTY(QString configUrl READ configUrl CONSTANT)
    Q_PROPERTY(bool available READ available CONSTANT)
    Q_PROPERTY(bool ready READ ready NOTIFY readyChanged)

public:
    explicit Assistant(QObject *parent = nullptr);
    ~Assistant() override;

    bool available() const;
    bool ready() const { return m_ready; }
    QString configUrl() const {
        return QUrl::fromLocalFile(
            QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
            + "/configs/assistant_config.json").toString();
    }

public slots:
    // Load the model.
    void init();
    // Ask the assistant. Queued behind init(), so it is safe to call while
    // the model is still loading.
    void ask(const QString &prompt);
    // Classify the prompt with laya. The result arrives in decision().
    void decide(const QString &prompt, const QStringList & keys, const QStringList & desc,
                const QString & rule, qint16 nOptions);

signals:
    void readyChanged();
    void error(const QString &message);
    void response(const QString &text);
    void decision(const QVariantMap &answer);

    void loadRequested();
    void queryRequested(const QString &prompt);
    void decideRequested(const QString &prompt, const QStringList & keys, const QStringList & desc,
                         const QString & rule, qint16 nOptions);

private:
    QThread m_thread;
    AssistantEngine *m_engine = nullptr;
    bool m_ready = false;
    bool m_startRequested = false;
};

#endif // ASSISTANT_H
