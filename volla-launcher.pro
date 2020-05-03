QT += quick androidextras

CONFIG += c++11

# The following define makes your compiler emit warnings if you use
# any Qt feature that has been marked deprecated (the exact warnings
# depend on your compiler). Refer to the documentation for the
# deprecated API to know how to port your code away from it.
DEFINES += QT_DEPRECATED_WARNINGS

# You can also make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
# You can also select to disable deprecated APIs only up to a certain version of Qt.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

SOURCES += \
        backend.cpp \
        fileio.cpp \
        main.cpp

RESOURCES += qml.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

include(vendor/vendor.pri)
#include(vendor/android/native/pri/androidnative.pri)
include(vendor/android_openssl/openssl.pri)

# ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android
android {
    ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android
}

OTHER_FILES += \
    android/AndroidManifest.xml \
    android/build.gradle \
    android/src/com/volla/launcher/worker/AppWorker.java

contains(ANDROID_TARGET_ARCH,x86) {
    ANDROID_PACKAGE_SOURCE_DIR = \
        $$PWD/android
}

HEADERS += \
    backend.h \
    fileio.h

DISTFILES += \
    android/src/com/volla/launcher/parser/ArticleParser.java \
    android/src/com/volla/launcher/worker/AccountWorker.java \
    android/src/com/volla/launcher/worker/CallWorker.java \
    android/src/com/volla/launcher/worker/ContactWorker.java \
    android/src/com/volla/launcher/worker/MessageWorker.java
