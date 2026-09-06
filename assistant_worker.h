#ifndef ASSISTANT_WORKER_H
#define ASSISTANT_WORKER_H

#include <QObject>
#include <QString>
#include <string>

#include "config.h"
#include "inference.h"
#include "states.h"
#include "agent_core.h"

class assistant_worker : public QObject
{
    Q_OBJECT
public:
    explicit assistant_worker(QObject *parent = nullptr);
    ~assistant_worker() override;

public slots:
    void init(const QString &configPath);

    void ask(const QString &userPrompt);

signals:
    void ready();                              
    void partialToken(const QString &token);    
    void responseReady(const QString &reply);   
    void errorOccurred(const QString &message);

private:
    bool updateMessages(const std::string &userPrompt);

    model_config m_config;
    llama_inference m_inference;
    state_type m_state;
    bool m_loaded = false;
};

#endif 