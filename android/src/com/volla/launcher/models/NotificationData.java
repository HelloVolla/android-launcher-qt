package com.volla.launcher.models;

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

    public NotificationData fromJson(String json) {
        Gson gson = new Gson();
        return gson.fromJson(json, NotificationData.class);
    }
}

