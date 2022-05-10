package com.volla.launcher.storage;

import androidx.room.Database;
import androidx.room.RoomDatabase;

@Database(entities={Message.class}, version=1)
public abstract class MessageDatabase extends RoomDatabase {

    public static final String DATABASE_NAME = "volla_launcher_database";

    public abstract MessageDao messageDao();


}
