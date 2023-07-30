package com.volla.launcher.storage;

import androidx.room.migration.Migration;
import androidx.sqlite.db.SupportSQLiteDatabase;

public class MigrationFromVersion1To2 extends Migration {
    public MigrationFromVersion1To2() {
        super(1, 2);
    }

    @Override
    public void migrate(SupportSQLiteDatabase database) {
        // Create the new table with the new schema (new_table_name)
        database.execSQL("CREATE TABLE IF NOT EXISTS messagesv2 (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, uuid TEXT,title TEXT, address TEXT,selfDisplayName TEXT, largeIcon TEXT, text TEXT,notification TEXT, timeStamp INTEGER)");

        // Copy data from the old table to the new table
        database.execSQL("INSERT INTO messagesv2 (id,uuid,title,address,selfDisplayName,largeIcon,text,notification,timeStamp) SELECT id,uuid,title,address,selfDisplayName,largeIcon,text,notification,timeStamp FROM messages");

         database.execSQL("CREATE UNIQUE INDEX IF NOT EXISTS index_messagesv2_timeStamp ON messagesv2(timeStamp)");

          database.execSQL("CREATE INDEX IF NOT EXISTS index_messagesv2_title ON messagesv2(title)");

        // Drop the old table if you no longer need it
        database.execSQL("DROP TABLE messages");

        database.execSQL("ALTER TABLE messagesv2 RENAME TO messages");
    }
}
