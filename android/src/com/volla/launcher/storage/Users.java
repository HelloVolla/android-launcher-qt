package com.volla.launcher.storage;

import android.util.Log;

import androidx.room.ColumnInfo;
import androidx.room.Entity;
import androidx.room.Index;
import androidx.room.PrimaryKey;

import com.volla.launcher.models.NotificationData;

@Entity(tableName = "users", indices = {@Index (value = {"user_name"}, unique = true)})
public class Users {

    @ColumnInfo
    @PrimaryKey(autoGenerate = true)
    public int id;

    @ColumnInfo
    public String uuid;

    @ColumnInfo
    public String body;


    @ColumnInfo
    public String user_name; // sender name

    @ColumnInfo
    public String user_contact_number; // sender mobile number

    @ColumnInfo
    public Boolean read; 

    @ColumnInfo
    public Boolean isSent; 

    @ColumnInfo
    public String largeIcon;

    @ColumnInfo
    public String notification;

    @ColumnInfo
    public Long timeStamp;

    public NotificationData getNotificationData() {
        return NotificationData.fromJson(notification);
    }

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

    public String getBody() {
        return body;
    }

    public void setBody(String body) {
        this.body = body;
    }

    public String getUser_name() {
        return user_name;
    }

    public void setUser_name(String user_name) {
        this.user_name = user_name;
    }

    public String getUser_contact_number() {
        return user_contact_number;
    }

    public void setUser_contact_number(String user_contact_number) {
        this.user_contact_number = user_contact_number;
    }

    public Boolean getRead() {
        return read;
    }

    public void setRead(Boolean read) {
        this.read = read;
    }

    public Boolean getSent() {
        return isSent;
    }

    public void setSent(Boolean sent) {
        isSent = sent;
    }

    public String getLargeIcon() {
        return largeIcon;
    }

    public void setLargeIcon(String largeIcon) {
        this.largeIcon = largeIcon;
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

    @Override
    public String toString() {
        return "Message{" +
                "id=" + id +
                ", uuid='" + uuid + '\'' +
                ", body='" + body + '\'' +
                ", user_name='" + user_name + '\'' +
                ", user_contact_number='" + user_contact_number + '\'' +
                ", read='" + read + '\'' +
                ", isSent='" + isSent + '\'' +
                ", largeIcon='" + largeIcon + '\'' +
                ", notification='" + notification + '\'' +
                ", timeStamp='" + timeStamp + '\'' +
                '}';
    }
}

