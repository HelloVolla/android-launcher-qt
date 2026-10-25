# Lists the volla_assistant_native sources so they show up in Qt Creator's
# project tree. Nothing here is compiled: the library is built by its own
# Makefile and linked from volla-launcher.pro via ASSISTANT_ROOT.

VAN = $$PWD/volla_assistant_native

INCLUDEPATH += $$VAN/assistant-core/include \
               $$VAN/ai-agents/include \
               $$VAN/router/include

HEADERS += $$files($$VAN/assistant-core/include/*.h) \
           $$files($$VAN/ai-agents/include/*.h) \
           $$files($$VAN/router/include/*.h)

OTHER_FILES += $$files($$VAN/assistant-core/src/*.cpp) \
               $$files($$VAN/ai-agents/src/*.cpp) \
               $$files($$VAN/router/src/*.cpp) \
               $$files($$VAN/jni/src/*.cpp) \
               $$VAN/Makefile
