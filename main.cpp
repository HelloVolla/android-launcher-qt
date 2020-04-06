#include <QtGui>
#include <QtQuick>
#include <QtAndroidExtras/QtAndroid>

#include "backend.h"
#include "fileio.h"

#ifdef Q_OS_ANDROID
#include "AndroidNative/systemdispatcher.h"
#include "AndroidNative/environment.h"
#include "AndroidNative/debug.h"
#include "AndroidNative/mediascannerconnection.h"
#include <QtAndroidExtras/QAndroidJniObject>
#include <QtAndroidExtras/QAndroidJniEnvironment>

const QVector<QString> permissions({"android.permission.READ_CONTACTS",
                                    "android.permission.READ_SMS",
                                    "android.permission.READ_CALL_LOG"});

JNIEXPORT jint JNI_OnLoad(JavaVM* vm, void*) {
    Q_UNUSED(vm);
    qDebug("NativeInterface::JNI_OnLoad()");

    // It must call this function within JNI_OnLoad to enable System Dispatcher
    AndroidNative::SystemDispatcher::registerNatives();

    return JNI_VERSION_1_6;
}
#endif

int main(int argc, char *argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QGuiApplication app(argc, argv);

    qmlRegisterType<BackEnd>("com.volla.launcher.backend", 1, 0, "BackEnd");
    qmlRegisterType<FileIO, 1>("FileIO", 1, 0, "FileIO");

    AndroidNative::SystemDispatcher::instance()->loadClass("com.volla.launcher.worker.ContactWorker");
    AndroidNative::SystemDispatcher::instance()->loadClass("com.volla.launcher.worker.MessageWorker");
    AndroidNative::SystemDispatcher::instance()->loadClass("com.volla.launcher.worker.CallWorker");

    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);

    QtAndroid::hideSplashScreen(250);

    for (const QString &permission : permissions){
        auto result = QtAndroid::checkPermission(permission);
        if (result == QtAndroid::PermissionResult::Denied){
            auto resultHash = QtAndroid::requestPermissionsSync(QStringList({permission}));
            if(resultHash[permission] == QtAndroid::PermissionResult::Denied)
                return 0;
        }
    }

    return app.exec();
}
