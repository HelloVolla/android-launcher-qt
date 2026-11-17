#ifndef MODELHANDLER_H
#define MODELHANDLER_H

#include <QObject>
#include <QString>

/*
 * QML wrapper around libmodel_handler (volla_assistant_native/model-handler),
 * exposed as the "modelHandler" context property.
 *
 * The SI model files live in shared storage (/storage/emulated/0/si_models).
 * This class reports whether they are installed and downloads them; whether
 * a download is allowed (consent, mobile data) is decided in QML.
 *
 * The models are shared between apps; the config is the launcher's own
 * (files/si/assistant_config.json in its sandbox), registered in the constructor.
 *
 * Create it once, before Assistant, and never delete it: the native download
 * thread calls back into this object.
 */
class ModelHandler : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool available READ available CONSTANT)
    Q_PROPERTY(bool installed READ installed NOTIFY installedChanged)
    Q_PROPERTY(bool downloading READ downloading NOTIFY downloadingChanged)
    Q_PROPERTY(qreal progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(qint64 totalBytes READ totalBytes CONSTANT)
    Q_PROPERTY(qint64 missingBytes READ missingBytes NOTIFY progressChanged)
    Q_PROPERTY(QString errorString READ errorString NOTIFY downloadingChanged)
    Q_PROPERTY(QString directory READ directory CONSTANT)

public:
    enum File { Model = 0, Laya = 1, Config = 2 };
    Q_ENUM(File)

    explicit ModelHandler(QObject *parent = nullptr);

    bool available() const;
    bool installed() const { return m_installed; }
    bool downloading() const { return m_downloading; }
    qreal progress() const;
    qint64 totalBytes() const;
    qint64 missingBytes() const;
    QString errorString() const { return m_error; }
    QString directory() const;

    // Absolute path of a model file (it may not exist yet).
    Q_INVOKABLE QString path(File file) const;
    // True when the active network is metered (mobile data).
    Q_INVOKABLE bool isMeteredNetwork() const;
    // Re-check the files on disk, e.g. after the user deleted them.
    Q_INVOKABLE void refresh();

public slots:
    // Start downloading the missing files. Returns false if nothing was started.
    bool download();
    void cancel();

signals:
    void installedChanged();
    void downloadingChanged();
    void progressChanged();
    // The download ended: all files installed.
    void finished();
    // The download ended without installing everything (also on cancel).
    void failed(const QString &message, bool cancelled);

private:
    static void onNativeProgress(void *user, const void *status);
    void applyStatus(int state, qint64 done, qint64 total, const QString &error);
    void setInstalled(bool value);
    void setDownloading(bool value);

    bool m_installed = false;
    bool m_downloading = false;
    qint64 m_doneBytes = 0;
    QString m_error;
};

#endif // MODELHANDLER_H
