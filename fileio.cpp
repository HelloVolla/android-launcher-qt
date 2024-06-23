#include "fileio.h"
#include <QFile>
#include <QTextStream>
#include <QStandardPaths>
#include <QDebug>
#include <QDir>

FileIO::FileIO(QObject *parent) :
    QObject(parent)
{

}

QString FileIO::read()
{
    if (mSource.isEmpty()){
        emit error("source is empty");
        return QString();
    }

    QString mDataPath = QStandardPaths::standardLocations(QStandardPaths::DocumentsLocation).value(0);
    qDebug() << "Data Path: " << mDataPath;
    QDir myDir(mDataPath);
    if (!myDir.exists()) {
        bool ok = myDir.mkpath(mDataPath);
        if(!ok) {
            qWarning() << "Couldn't create dir. " << mDataPath;
        }
        qDebug() << "created directory path" << mDataPath;
    }

    QFile file(mDataPath + "/" + mSource);
    QString fileContent;
    if ( file.open(QIODevice::ReadOnly) ) {
        QString line;
        QTextStream t( &file );
        do {
            line = t.readLine();
            fileContent += line;
         } while (!line.isNull());

        file.close();
    } else {
        emit error("Unable to open the file");
        return QString();
    }
    return fileContent;
}

QString FileIO::readPrivate()
{
    if (mSource.isEmpty()){
        emit error("source is empty");
        return QString();
    }

    QString mDataPath = QStandardPaths::standardLocations(QStandardPaths::AppLocalDataLocation).value(0);
    qDebug() << "Data Path: " << mDataPath;
    QDir myDir(mDataPath);
    if (!myDir.exists()) {
        bool ok = myDir.mkpath(mDataPath);
        if(!ok) {
            qWarning() << "Couldn't create dir. " << mDataPath;
        }
        qDebug() << "created directory path" << mDataPath;
    }

    QFile file(mDataPath + "/" + mSource);
    QString fileContent;
    if ( file.open(QIODevice::ReadOnly) ) {
        QString line;
        QTextStream t( &file );
        fileContent = t.readAll();
        file.close();
    } else {
        emit error("Unable to open the file");
        return QString();
    }
    return fileContent;
}

bool FileIO::write(const QString& data)
{
    if (mSource.isEmpty())
        return false;

    QString mDataPath = QStandardPaths::standardLocations(QStandardPaths::DocumentsLocation).value(0);
    qDebug() << "Data Path: " << mDataPath;
    QDir myDir(mDataPath);
    if (!myDir.exists()) {
        bool ok = myDir.mkpath(mDataPath);
        if(!ok) {
            qWarning() << "Couldn't create dir. " << mDataPath;
        }
        qDebug() << "created directory path" << mDataPath;
    }

    QFile file(mDataPath + "/" + mSource);
    if (!file.open(QFile::WriteOnly | QFile::Truncate))
        return false;

    QTextStream out(&file);
    out << data;

    file.close();

    return true;
}

bool FileIO::writePrivate(const QString& data)
{
    if (mSource.isEmpty())
        return false;

    QString mDataPath = QStandardPaths::standardLocations(QStandardPaths::AppLocalDataLocation).value(0);
    qDebug() << "Data Path: " << mDataPath;
    QDir myDir(mDataPath);
    if (!myDir.exists()) {
        bool ok = myDir.mkpath(mDataPath);
        if(!ok) {
            qWarning() << "Couldn't create dir. " << mDataPath;
        }
        qDebug() << "created directory path" << mDataPath;
    }

    QFile file(mDataPath + "/" + mSource);
    if (!file.open(QFile::WriteOnly | QFile::Truncate))
        return false;

    QTextStream out(&file);
    out << data;

    file.close();

    return true;
}

QString FileIO::readPresets()
{
    QString mDataPath = "/system/etc/com.volla.launcher/volla_properties.json";
    qDebug() << "Data Path: " << mDataPath;
    QFile file(mDataPath);
    QString fileContent;
    if ( file.open(QIODevice::ReadOnly) ) {
        QString line;
        QTextStream t( &file );
        fileContent = t.readAll();
        file.close();
    } else {
        emit error("Unable to open the file");
        return QString();
    }
    return fileContent;
}
