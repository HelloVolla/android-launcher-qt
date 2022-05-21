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

public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getUuid() {
        return uuid;
    }

    public void setUuid(String uuid) {
        this.uuid = uuid;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public String getSelfDisplayName() {
        return selfDisplayName;
    }

    public void setSelfDisplayName(String selfDisplayName) {
        this.selfDisplayName = selfDisplayName;
    }

    public String getLargeIcon() {
        return largeIcon;
    }

    public void setLargeIcon(String largeIcon) {
        this.largeIcon = largeIcon;
    }

    public String getText() {
        return text;
    }

    public void setText(String text) {
        this.text = text;
    }

    public String getNotification() {
        return notification;
    }

    public void setNotification(String notification) {
        this.notification = notification;
    }

    public Long getTimeStamp() {
        return timeStamp;
    }

    public void setTimeStamp(Long timeStamp) {
        this.timeStamp = timeStamp;
    }
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
