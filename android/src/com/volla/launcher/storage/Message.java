package com.volla.launcher.storage;

import androidx.room.ColumnInfo;
import androidx.room.Entity;
import androidx.room.Index;
import androidx.room.PrimaryKey;

import com.volla.launcher.models.NotificationData;
@Entity(tableName = "messages", indices = {@Index("title"), @Index("timeStamp")})
public class Message {

    @ColumnInfo
    @PrimaryKey(autoGenerate = true)
    public int id;

    @ColumnInfo
    public String uuid;
    @ColumnInfo
    public String title;

    @ColumnInfo
    public String address; // sender mobile number
    @ColumnInfo
    public String selfDisplayName;

    @ColumnInfo
    public String largeIcon;

    @ColumnInfo
    public String text;
    @ColumnInfo
    public String notification;
    @ColumnInfo
    public Long timeStamp;
    public NotificationData getNotificationData() {
        return NotificationData.fromJson(notification);
    }
    @Override
    public String toString() {
        return "Message{" +
                "id=" + id +
                ", uuid='" + uuid + '\'' +
                ", title='" + title + '\'' +
                ", selfDisplayName='" + selfDisplayName + '\'' +
                ", address='" + address + '\'' +
                ", largeIcon='" + largeIcon + '\'' +
                ", text='" + text + '\'' +
                ", notification='" + notification + '\'' +
                ", timeStamp='" + timeStamp + '\'' +
                '}';
    }
}
