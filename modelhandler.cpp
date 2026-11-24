#include "modelhandler.h"

#include <QDebug>
#include <QMetaObject>
#include <QStandardPaths>

#ifdef Q_OS_ANDROID
#include <QtAndroid>
#include <QAndroidJniObject>
#include <QAndroidJniEnvironment>
#endif

#ifdef VOLLA_ASSISTANT
#include "model_handler.h"
#endif

#ifdef VOLLA_ASSISTANT
namespace {
// The launcher's own SI config, kept in the launcher's sandbox
// TODO(model-handler): real URL, SHA-256 and size of the launcher's assistant_config.json.
QString configPath()
{
    return QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
           + QStringLiteral("/configs/assistant_config.json");
}
const char *const kConfigUrl = "https://volla.tech/filedump/si-assets/volla_si_config.json";
const char *const kConfigSha256 = "";
const quint64 kConfigSize = 0;
}
#endif

ModelHandler::ModelHandler(QObject *parent)
    : QObject(parent)
{
#ifdef VOLLA_ASSISTANT
    if (mh_set_app_config(configPath().toUtf8().constData(), kConfigUrl, kConfigSha256, kConfigSize) != 0)
        qWarning() << "ModelHandler | Invalid app config";
    m_installed = mh_installed();
    m_doneBytes = static_cast<qint64>(mh_total_bytes() - mh_missing_bytes());
    qDebug() << "ModelHandler | Directory" << directory() << "installed:" << m_installed;
#endif
}

bool ModelHandler::available() const
{
#ifdef VOLLA_ASSISTANT
    return true;
#else
    return false;
#endif
}

qint64 ModelHandler::totalBytes() const
{
#ifdef VOLLA_ASSISTANT
    return static_cast<qint64>(mh_total_bytes());
#else
    return 0;
#endif
}

qint64 ModelHandler::missingBytes() const
{
    return qMax<qint64>(0, totalBytes() - m_doneBytes);
}

qreal ModelHandler::progress() const
{
    const qint64 total = totalBytes();
    return total > 0 ? qreal(m_doneBytes) / qreal(total) : (m_installed ? 1.0 : 0.0);
}

QString ModelHandler::directory() const
{
#ifdef VOLLA_ASSISTANT
    return QString::fromUtf8(mh_dir());
#else
    return QString();
#endif
}

QString ModelHandler::path(File file) const
{
#ifdef VOLLA_ASSISTANT
    const char *p = mh_path(static_cast<mh_file>(file));
    return p != nullptr ? QString::fromUtf8(p) : QString();
#else
    Q_UNUSED(file)
    return QString();
#endif
}

bool ModelHandler::isMeteredNetwork() const
{
#ifdef Q_OS_ANDROID
    QAndroidJniObject context = QtAndroid::androidContext();
    QAndroidJniObject manager = context.callObjectMethod(
        "getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;",
        QAndroidJniObject::fromString(QStringLiteral("connectivity")).object<jstring>());
    if (!manager.isValid())
        return true; // unknown: be careful with the user's data plan
    const bool metered = manager.callMethod<jboolean>("isActiveNetworkMetered");
    QAndroidJniEnvironment env;
    if (env->ExceptionCheck()) {
        env->ExceptionClear();
        return true;
    }
    return metered;
#else
    return false;
#endif
}

void ModelHandler::refresh()
{
#ifdef VOLLA_ASSISTANT
    if (m_downloading)
        return;
    m_doneBytes = static_cast<qint64>(mh_total_bytes() - mh_missing_bytes());
    setInstalled(mh_installed());
    emit progressChanged();
#endif
}

bool ModelHandler::download()
{
#ifdef VOLLA_ASSISTANT
    if (m_downloading)
        return false;
    m_error.clear();
    const int rc = mh_download_start(
        [](void *user, const mh_status *status) { onNativeProgress(user, status); }, this);
    if (rc == 1) {
        setInstalled(true);
        emit finished();
        return false;
    }
    if (rc != 0) {
        qWarning() << "ModelHandler | Could not start the download";
        return false;
    }
    qDebug() << "ModelHandler | Download started," << missingBytes() << "bytes missing";
    setDownloading(true);
    return true;
#else
    return false;
#endif
}

void ModelHandler::cancel()
{
#ifdef VOLLA_ASSISTANT
    if (m_downloading)
        mh_download_cancel();
#endif
}

// Runs on the native download thread: hand the status to the Qt main thread.
void ModelHandler::onNativeProgress(void *user, const void *rawStatus)
{
#ifdef VOLLA_ASSISTANT
    auto *self = static_cast<ModelHandler *>(user);
    const auto *status = static_cast<const mh_status *>(rawStatus);
    const int state = status->state;
    const qint64 done = static_cast<qint64>(status->done_bytes);
    const qint64 total = static_cast<qint64>(status->total_bytes);
    const QString error = QString::fromUtf8(status->error);
    QMetaObject::invokeMethod(self, [self, state, done, total, error]() {
        self->applyStatus(state, done, total, error);
    }, Qt::QueuedConnection);
#else
    Q_UNUSED(user)
    Q_UNUSED(rawStatus)
#endif
}

void ModelHandler::applyStatus(int state, qint64 done, qint64 total, const QString &error)
{
#ifdef VOLLA_ASSISTANT
    Q_UNUSED(total)
    if (done != m_doneBytes) {
        m_doneBytes = done;
        emit progressChanged();
    }
    switch (state) {
    case MH_STATE_DOWNLOADING:
        setDownloading(true);
        break;
    case MH_STATE_DONE:
        qDebug() << "ModelHandler | All model files installed";
        setDownloading(false);
        setInstalled(true);
        emit finished();
        break;
    case MH_STATE_FAILED:
    case MH_STATE_CANCELLED:
        m_error = state == MH_STATE_CANCELLED ? tr("Download cancelled") : error;
        qWarning() << "ModelHandler | Download stopped:" << m_error;
        setDownloading(false);
        setInstalled(mh_installed());
        emit failed(m_error, state == MH_STATE_CANCELLED);
        break;
    default:
        break;
    }
#else
    Q_UNUSED(state) Q_UNUSED(done) Q_UNUSED(total) Q_UNUSED(error)
#endif
}

void ModelHandler::setInstalled(bool value)
{
    if (m_installed == value)
        return;
    m_installed = value;
    emit installedChanged();
}

void ModelHandler::setDownloading(bool value)
{
    if (m_downloading == value)
        return;
    m_downloading = value;
    emit downloadingChanged();
}
