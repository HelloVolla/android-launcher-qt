#include "assistant_paths.h"

#include <QDebug>
#include <QDir>
#include <QStandardPaths>

namespace {

QString sRoot;
QString sCacheRoot;

QString resolveRoot()
{
    const QByteArray env = qgetenv("VOLLA_ASSISTANT_ROOT");
    if (!env.isEmpty())
        return QDir::cleanPath(QString::fromLocal8Bit(env));

    return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
}

QString resolveCacheRoot()
{
    
    if (!qgetenv("VOLLA_ASSISTANT_ROOT").isEmpty())
        return sRoot + QStringLiteral("/caches");

    const QString cache = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
    return cache.isEmpty() ? sRoot + QStringLiteral("/caches")
                           : cache + QStringLiteral("/assistant");
}


void ensure(const QString &dir)
{
    QDir d(dir);
    if (!d.exists() && !d.mkpath(QStringLiteral(".")))
        qWarning() << "AssistantPaths | Failed to create" << dir;
}

}

void AssistantPaths::initialize()
{
    if (!sRoot.isEmpty())
        return;

    sRoot = resolveRoot();
    if (sRoot.isEmpty()) {
        qWarning() << "AssistantPaths | No writable location for assistant data";
        return;
    }
    sCacheRoot = resolveCacheRoot();

    ensure(sRoot);
    ensure(configsDir());
    ensure(modelsDir());
    ensure(cacheDir());

    qDebug() << "AssistantPaths | root:" << sRoot << "cache:" << sCacheRoot;
}

QString AssistantPaths::root()
{
    if (sRoot.isEmpty())
        initialize();
    return sRoot;
}

QString AssistantPaths::configsDir()
{
    return root() + QStringLiteral("/configs");
}

QString AssistantPaths::modelsDir()
{
    return root() + QStringLiteral("/models");
}

QString AssistantPaths::cacheDir()
{
    if (sRoot.isEmpty())
        initialize();
    return sCacheRoot;
}

QString AssistantPaths::assistantConfig()
{
    return configsDir() + QStringLiteral("/assistant_config.json");
}

QString AssistantPaths::agentsMap()
{
    return configsDir() + QStringLiteral("/agents_map.json");
}

QString AssistantPaths::agentConfig(const QString &agentId)
{
    return configsDir() + QStringLiteral("/%1/%1_config.json").arg(agentId);
}

QString AssistantPaths::modelFile(const QString &id)
{
    return modelsDir() + QStringLiteral("/%1/model.gguf").arg(id);
}

QString AssistantPaths::cacheFile(const QString &id)
{
    return cacheDir() + QStringLiteral("/%1/cache.bin").arg(id);
}
