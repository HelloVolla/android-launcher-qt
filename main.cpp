#include <QtGui>
#include <QtQuick>
#include <QtAndroidExtras/QtAndroid>

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
                                    "android.permission.SEND_SMS",
                                    "android.permission.READ_CALL_LOG",
                                    "android.permission.WRITE_CALL_LOG",
                                    "android.permission.WRITE_SMS",
                                    "android.permission.READ_EXTERNAL_STORAGE",
                                    "android.permission.WRITE_EXTERNAL_STORAGE",
                                    "android.permission.SET_WALLPAPER",
                                    "android.permission.CALL_PHONE",
                                    "android.permission.WRITE_APN_SETTINGS",
                                    "android.permission.MANAGE_APP_OPS_MODES",
                                    "android.permission.CHANGE_COMPONENT_ENABLED_STATE",
                                    "android.permission.QUERY_ALL_PACKAGES"});

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
    app.setOrganizationName("Hallo Welt Systeme UG");
    app.setOrganizationDomain("volla.online");
    app.setApplicationName("Volla Launcher");

    QTranslator myappTranslator;
    if (myappTranslator.load(QLocale(), QLatin1String("Volla"), QLatin1String("_"), QLatin1String(":/i18n/")) != 1) {
        qDebug() << "FAILED TO LOAD TRANSLATOR for LOCALE" << QLocale();
    }
    app.installTranslator(&myappTranslator);

    qmlRegisterType<FileIO, 1>("FileIO", 1, 0, "FileIO");

    AndroidNative::SystemDispatcher::instance()->loadClass("com.volla.launcher.worker.ContactWorker");
    AndroidNative::SystemDispatcher::instance()->loadClass("com.volla.launcher.worker.MessageWorker");
    AndroidNative::SystemDispatcher::instance()->loadClass("com.volla.launcher.worker.CallWorker");
    AndroidNative::SystemDispatcher::instance()->loadClass("com.volla.launcher.worker.WallpaperWorker");
    AndroidNative::SystemDispatcher::instance()->loadClass("com.volla.launcher.worker.AppWorker");
    AndroidNative::SystemDispatcher::instance()->loadClass("com.volla.launcher.worker.ShortcutsWorker");
    AndroidNative::SystemDispatcher::instance()->loadClass("com.volla.launcher.parser.ArticleParser");
    AndroidNative::SystemDispatcher::instance()->loadClass("com.volla.launcher.util.LayoutUtil");
    AndroidNative::SystemDispatcher::instance()->loadClass("com.volla.launcher.util.AppUtil");
    AndroidNative::SystemDispatcher::instance()->loadClass("com.volla.launcher.util.CalendarUtil");
    AndroidNative::SystemDispatcher::instance()->loadClass("com.volla.launcher.util.MessageUtil");
    AndroidNative::SystemDispatcher::instance()->loadClass("com.volla.launcher.util.CallUtil");
    AndroidNative::SystemDispatcher::instance()->loadClass("com.volla.launcher.util.VibrationUtil");
    AndroidNative::SystemDispatcher::instance()->loadClass("com.volla.launcher.util.ShortcutUtil");
    AndroidNative::SystemDispatcher::instance()->loadClass("com.volla.launcher.util.SignalUtil");
    AndroidNative::SystemDispatcher::instance()->loadClass("com.volla.launcher.worker.SignalWorker");

    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);

    QtAndroid::hideSplashScreen();

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
