package com.volla.launcher.util;

import android.app.PendingIntent;
import android.app.RemoteInput;

import java.util.ArrayList;
import java.util.UUID;

public class RepliableNotification {
    public final String id = UUID.randomUUID().toString();
    public PendingIntent pendingIntent;
    public final ArrayList<RemoteInput> remoteInputs = new ArrayList<>();
    public String packageName;
    public String tag;
}