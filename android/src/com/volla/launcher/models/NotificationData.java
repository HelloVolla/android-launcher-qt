package com.volla.launcher.models;
import android.util.Log;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

public class NotificationData {

    public int userHandle;
    public int id;
    public String key;
    public Notification notification;

    public String toJson() {
        return new GsonBuilder().create().toJson(this, NotificationData.class);
    }

    public static NotificationData fromJson(String json) {
        Log.d("VollaNotification json", json);
        Gson gson = new Gson();
        return gson.fromJson(json, NotificationData.class);
    }
    @Override
    public String toString() {
        return "NotificationData{" +
                "userHandle=" + userHandle +
                ", id=" + id +
                ", key='" + key + '\'' +
                ", notification=" + notification +
                '}';
    }
}

