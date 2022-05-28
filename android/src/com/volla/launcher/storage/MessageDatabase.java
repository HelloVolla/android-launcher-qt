package com.volla.launcher.storage;

import android.content.Context;
import androidx.room.Database;
import androidx.room.Room;
import androidx.room.RoomDatabase;

@Database(entities = {Message.class, Users.class}, version = 1)
public abstract class MessageDatabase extends RoomDatabase {

    public static final String DATABASE_NAME = "volla_launcher_database";
    private static MessageDatabase INSTANCE;

    public abstract MessageDao messageDao();
    public abstract UsersDao usersDao();

    public static MessageDatabase getInstance(final Context context) {
        if (INSTANCE == null) {
            synchronized (MessageDatabase.class) {
                if (INSTANCE == null) {
                    INSTANCE = Room.databaseBuilder(context.getApplicationContext(),
                            MessageDatabase.class, DATABASE_NAME).build();
                }
            }
        }
        return INSTANCE;
    }

}
