#include "socket.h"
#include <QUuid>
#include <QUrl>
#include <QTcpSocket>
#include <QLocalSocket>

Socket::Socket(QObject *parent):
    QObject(parent)
{}

void Socket::connect() {
    if (mSocket) {
        QObject::disconnect(mSocket.get());
        mSocket->deleteLater();
        mSocket.release();
    }

    QUrl url = QUrl(mUrl);
    setProperty("state", ConnectingState);

    if (url.scheme().toLower() == "tcp") {
        mIsTcpSocket = true;
        QTcpSocket *socket = new QTcpSocket();
        mSocket.reset(socket);

        QObject::connect(socket,
                         &QAbstractSocket::readyRead,
                         [=]() { emit read(mSocket->readAll()); });

        QObject::connect(socket, &QTcpSocket::connected, this, &Socket::connected);
        QObject::connect(socket, &QTcpSocket::disconnected, this, &Socket::disconnected);

        QObject::connect(socket,
                         &QAbstractSocket::stateChanged,
                         [=](QAbstractSocket::SocketState s)
        {
            SocketState state = s == QAbstractSocket::UnconnectedState ? DisconnectedState :
                                s == QAbstractSocket::HostLookupState  ? ConnectingState   :
                                s == QAbstractSocket::ConnectingState  ? ConnectingState   :
                                s == QAbstractSocket::ConnectedState   ? ConnectedState    :
                                s == QAbstractSocket::BoundState       ? ConnectedState    :
                                s == QAbstractSocket::ClosingState     ? DisconnectingState:
                                                                         ConnectingState;
            setProperty("state", state);
        });

        socket->connectToHost(url.host(), url.port(8080));

    } else {
        mIsTcpSocket = false;
        QLocalSocket *socket = new QLocalSocket();
        mSocket.reset(socket);

        QObject::connect(socket,
                         &QLocalSocket::readyRead,
                         [=]() { emit read(mSocket->readAll()); });

        QObject::connect(socket, &QLocalSocket::connected, this, &Socket::connected);
        QObject::connect(socket, &QLocalSocket::disconnected, this, &Socket::disconnected);

        QObject::connect(socket,
                         &QLocalSocket::stateChanged,
                         [=](QLocalSocket::LocalSocketState s)
        {
            SocketState state =  s == QLocalSocket::UnconnectedState ? DisconnectedState :
                                 s == QLocalSocket::ConnectingState  ? ConnectingState   :
                                 s == QLocalSocket::ConnectedState   ? ConnectedState    :
                                                                       DisconnectingState;
            setProperty("state", static_cast<SocketState>(state));
        });

        socket->connectToServer(mUrl);
    }
}

void Socket::disconnect() {
    setProperty("state", DisconnectingState);

    if (mIsTcpSocket) {
        static_cast<QTcpSocket*>(mSocket.get())->disconnectFromHost();
    } else {
        static_cast<QLocalSocket*>(mSocket.get())->disconnectFromServer();
    }
}

void Socket::reconnect() {
    disconnect();
    connect();
}

void Socket::write(const QString& message) {
    if (mSocket) {
        mSocket->write(message.toLocal8Bit());

        if (mIsTcpSocket) {
            static_cast<QTcpSocket*>(mSocket.get())->flush();
        } else {
            static_cast<QLocalSocket*>(mSocket.get())->flush();
        }
    }
}

QString Socket::uuid() const
{
    return QUuid::createUuid().toString();
}
