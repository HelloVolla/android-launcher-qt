#include "backend.h"
#include <QtAndroidExtras/QAndroidJniObject>
#include <QtAndroid>

//BackEnd::BackEnd(QQuickView &v){
//    viewer=&v;
//}

BackEnd::BackEnd(QObject *parent) :
    QObject(parent)
{
}

QString BackEnd::getApplist(){
    QAndroidJniObject activity = QAndroidJniObject::callStaticObjectMethod("org/qtproject/qt5/android/QtNative", "activity", "()Landroid/app/Activity;");
    QAndroidJniObject str = QAndroidJniObject::callStaticObjectMethod("com/volla/launcher/worker/AppWorker", "getApplist", "(Landroid/app/Activity;)Ljava/lang/String;", activity.object<jobject>());
    return str.toString();
}

QString BackEnd::getApplistAsJSON(){
    QAndroidJniObject activity = QAndroidJniObject::callStaticObjectMethod("org/qtproject/qt5/android/QtNative", "activity", "()Landroid/app/Activity;");
    QAndroidJniObject str = QAndroidJniObject::callStaticObjectMethod("com/volla/launcher/worker/AppWorker", "getApplistAsJSON", "(Landroid/app/Activity;)Ljava/lang/String;", activity.object<jobject>());
    return str.toString();
}

void BackEnd::runApp(QString ID){
    qDebug() << ID;

    QAndroidJniObject string = QAndroidJniObject::fromString(ID);
    QAndroidJniObject activity = QAndroidJniObject::callStaticObjectMethod("org/qtproject/qt5/android/QtNative", "activity", "()Landroid/app/Activity;");
    QAndroidJniObject intent = QAndroidJniObject::callStaticObjectMethod("com/volla/launcher/worker/AppWorker", "getAppIntent", "(Landroid/app/Activity;Ljava/lang/String;)Landroid/content/Intent;", activity.object<jobject>(), string.object<jstring>());
    QtAndroid::startActivity(intent,0);
}
