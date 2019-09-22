//#include <QGuiApplication>
//#include <QQmlApplicationEngine>

#include <QtGui>
#include <QtQuick>

#include "backend.h"
#include "fileio.h"

int main(int argc, char *argv[])
{
//    QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
//    QGuiApplication app(argc, argv);
//    QQuickView viewer;
//    viewer.setResizeMode(QQuickView::SizeRootObjectToView);

//    BackEnd backend(viewer);

//    viewer.rootContext()->setContextProperty("backEnd", &backend);

//    QObject::connect(viewer.engine(), &QQmlEngine::quit, &viewer, &QWindow::close);
//    viewer.setSource(QUrl("qrc:/main.qml"));
//    viewer.show();
//    return app.exec();

    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QGuiApplication app(argc, argv);

    qmlRegisterType<BackEnd>("com.volla.launcher.backend", 1, 0, "BackEnd");
    qmlRegisterType<FileIO, 1>("FileIO", 1, 0, "FileIO");

    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);



    return app.exec();
}
