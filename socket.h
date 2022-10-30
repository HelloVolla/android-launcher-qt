#pragma once

#include <QAbstractSocket>
#include <memory>

class Socket : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString url MEMBER mUrl NOTIFY urlChanged)
    Q_PROPERTY(SocketState state MEMBER mState NOTIFY stateChanged)

public:
    enum SocketState{
       DisconnectedState,
       ConnectingState,
       ConnectedState,
       DisconnectingState
    };
    Q_ENUM(SocketState)

signals:
    void urlChanged();
    void stateChanged();

    void read(const QString &message);
    void connected();
    void disconnected();

public:
    Socket(QObject* parent = nullptr);

public slots:
    void connect();
    void disconnect();
    void reconnect();
    void write(const QString& message);
    QString uuid() const;

public:
    bool mIsTcpSocket;
    QString mUrl;
    SocketState mState = DisconnectedState;
    std::unique_ptr<QIODevice> mSocket;
};
