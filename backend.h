#ifndef BACKEND_H
#define BACKEND_H

#include <QObject>
#include <QQuickView>

class BackEnd : public QObject
{
    Q_OBJECT

//QQuickView *viewer;

public:
//BackEnd(QQuickView &viewer);
explicit BackEnd(QObject *parent = nullptr);

public slots:
    QString getApplist();
    void runApp(QString ID);
};

#endif // BACKEND_H
