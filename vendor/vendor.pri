
DEFINES += QPM_INIT\\(E\\)=\"E.addImportPath(QStringLiteral(\\\"qrc:/\\\"));\"
DEFINES += QPM_USE_NS
INCLUDEPATH += $$PWD
QML_IMPORT_PATH += $$PWD


include($$PWD/android/native/pri/androidnative.pri)
include($$PWD/android/native/pri/examples/androidnativeexample/.pri)
