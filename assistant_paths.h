#ifndef ASSISTANT_PATHS_H
#define ASSISTANT_PATHS_H

#include <QString>

// Single source of truth for every filesystem location the assistant uses.
namespace AssistantPaths {

// Resolves the root and creates the directory layout. Idempotent.
void initialize();

// Root of the assistant data tree.
QString root();

QString configsDir();
QString modelsDir();
QString cacheDir();

QString assistantConfig();                      // <configs>/assistant_config.json
QString agentsMap();                            // <configs>/agents_map.json
QString agentConfig(const QString &agentId);    // <configs>/<agentId>/<agentId>_config.json

QString modelFile(const QString &id);           // <models>/<id>/model.gguf
QString cacheFile(const QString &id);           // <cache>/<id>/cache.bin

}

#endif // ASSISTANT_PATHS_H
