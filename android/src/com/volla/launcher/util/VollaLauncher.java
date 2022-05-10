package com.volla.launcher.util;

import android.app.Application;

import androidx.room.Room;

import com.volla.launcher.storage.MessageDatabase;

public class VollaLauncher extends Application {

    private MessageDatabase messageDatabase;

    @Override
    public void onCreate() {
        super.onCreate();
        messageDatabase = Room.databaseBuilder(this, MessageDatabase.class, MessageDatabase.DATABASE_NAME).fallbackToDestructiveMigration().build();
    }

    public MessageDatabase getMessageDatabase() {
        return messageDatabase;
    }
}
