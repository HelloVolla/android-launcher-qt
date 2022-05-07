package com.volla.launcher.storage;

import androidx.room.ColumnInfo;
import androidx.room.Entity;
import androidx.room.PrimaryKey;

@Entity(tableName = "messages")
public class Message {

    @ColumnInfo
    @PrimaryKey(autoGenerate = true)
    public int id;

    @ColumnInfo
    public String title;

    @ColumnInfo
    public String selfDisplayName;

    @ColumnInfo
    public String largeIcon;

    @ColumnInfo
    public String channelId;
}
