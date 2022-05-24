package com.volla.launcher.models;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

public class Notification {
    public String channel;
    public String shortcut;
    public String sortKey;

    public String toJson() {
        return new GsonBuilder().create().toJson(this, Notification.class);
    }

    public Notification fromJson(String json) {
        Gson gson = new Gson();
        return gson.fromJson(json, Notification.class);
    }
}
