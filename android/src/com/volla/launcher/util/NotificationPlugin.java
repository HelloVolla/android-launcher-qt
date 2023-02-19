package com.volla.launcher.util;

import android.app.Notification;
import android.app.PendingIntent;
import android.app.RemoteInput;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.Icon;
import android.os.Build;
import android.os.Bundle;
import android.os.Parcelable;
import android.service.notification.StatusBarNotification;
import android.text.SpannableString;
import android.text.TextUtils;
import android.util.Log;
import android.util.Pair;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.core.app.NotificationCompat;
import com.volla.launcher.NotificationListenerExampleService;
import org.apache.commons.collections4.MultiValuedMap;
import org.apache.commons.collections4.multimap.ArrayListValuedHashMap;
import org.apache.commons.lang3.ArrayUtils;
import org.json.JSONArray;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

public class NotificationPlugin implements NotificationListenerExampleService.NotificationListener{

    private final static String TAG = "Volla/NotificationPlugi";
    private Set<String> currentNotifications;
    private Map<String, RepliableNotification> pendingIntents;
    private MultiValuedMap<String, Notification.Action> actions;
    private boolean serviceReady;
    private SharedPreferences sharedPreferences;
    private final static String PREF_KEY = "prefKey";
    public Context context;

    public NotificationPlugin(Context context){
        this.context = context;
        Log.d(TAG, "NotificationPlugin Condtructor0");
        pendingIntents = new HashMap<>();
        currentNotifications = new HashSet<>();
        actions = new ArrayListValuedHashMap<>();
        sharedPreferences = context.getSharedPreferences(getSharedPreferencesName(), Context.MODE_PRIVATE);
        Log.d(TAG, "NotificationPlugin getSharedPref");
        NotificationListenerExampleService.RunCommand(context, service -> {
            Log.d(TAG, "NotificationPlugin Adding Listner");
            service.addListener(NotificationPlugin.this);
            serviceReady = service.isConnected();
            Log.d(TAG, "NotificationPlugin serviceReady "+ serviceReady);

        });
    }
    public String getSharedPreferencesName() {
        return  "volla_preferences";
    }
    @Override
    public void onListenerConnected(NotificationListenerExampleService service) {
        serviceReady = true;
    }

    @Override
    public void onNotificationPosted(StatusBarNotification statusBarNotification) {
        sendNotification(statusBarNotification);
    }

    @Override
    public void onNotificationRemoved(StatusBarNotification statusBarNotification) {
        if (statusBarNotification == null) {
            Log.w(TAG, "onNotificationRemoved: notification is null");
            return;
        }
        String id = getNotificationKeyCompat(statusBarNotification);
        actions.remove(id);
        NetworkPacket np = new NetworkPacket(SignalUtil.PACKET_TYPE_NOTIFICATION);
        np.set("id", id);
        np.set("isCancel", true);
        currentNotifications.remove(id);
    }

    private void sendNotification(StatusBarNotification statusBarNotification) {
        Notification notification = statusBarNotification.getNotification();
        String key = getNotificationKeyCompat(statusBarNotification);
        String packageName = statusBarNotification.getPackageName();
        String appName = AppsHelper.appNameLookup(context, packageName);
        NetworkPacket np = new NetworkPacket(SignalUtil.PACKET_TYPE_NOTIFICATION);
        boolean isUpdate = currentNotifications.contains(key);
        //If it's an update, the other end should have the icon already: no need to extract it and create the payload again
        if (!isUpdate) {
            currentNotifications.add(key);
            Bitmap appIcon = extractIcon(statusBarNotification, notification);
        }

        np.set("actions", extractActions(notification, key));
        np.set("id", key);
        np.set("onlyOnce", (notification.flags & NotificationCompat.FLAG_ONLY_ALERT_ONCE) != 0);
        np.set("isClearable", statusBarNotification.isClearable());
        np.set("appName", appName);
        np.set("time", Long.toString(statusBarNotification.getPostTime()));
        Log.d(TAG, "RepliableNotification id "+ statusBarNotification.getId());
        RepliableNotification rn = extractRepliableNotification(statusBarNotification);
        if (rn != null) {
            np.set("requestReplyId", rn.id);
            pendingIntents.put(String.valueOf(statusBarNotification.getId()), rn);
        }
        np.set("ticker", getTickerText(notification));
        Pair<String, String> conversation = extractConversation(notification);
        if (conversation.first != null) {
            np.set("title", conversation.first);
        } else {
            np.set("title", extractStringFromExtra(getExtras(notification), NotificationCompat.EXTRA_TITLE));
        }
        np.set("text", extractText(notification, conversation));
        Log.d(TAG, "RepliableNotification id "+ rn.id);
    }

    public void replyToNotification(String id, String message) {
        if (pendingIntents.isEmpty() || !pendingIntents.containsKey(id)) {
            Log.e(TAG, "No such notification");
            return;
        }
        RepliableNotification repliableNotification = pendingIntents.get(id);
        if (repliableNotification == null) {
            Log.e(TAG, "No such notification");
            return;
        }
        RemoteInput[] remoteInputs = new RemoteInput[repliableNotification.remoteInputs.size()];
        Intent localIntent = new Intent();
        localIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        Bundle localBundle = new Bundle();
        int i = 0;
        for (RemoteInput remoteIn : repliableNotification.remoteInputs) {
            remoteInputs[i] = remoteIn;
            localBundle.putCharSequence(remoteInputs[i].getResultKey(), message);
            i++;
        }
        RemoteInput.addResultsToIntent(remoteInputs, localIntent, localBundle);
        try {
            repliableNotification.pendingIntent.send(context, 0, localIntent);
        } catch (PendingIntent.CanceledException e) {
            Log.e(TAG, "replyToNotification error: " + e.getMessage());
        }
        pendingIntents.remove(id);
    }
    private String extractText(Notification notification, Pair<String, String> conversation) {

        if (conversation.second != null) {
            return conversation.second;
        }

        Bundle extras = getExtras(notification);

        if (extras.containsKey(NotificationCompat.EXTRA_BIG_TEXT)) {
            return extractStringFromExtra(extras, NotificationCompat.EXTRA_BIG_TEXT);
        }

        return extractStringFromExtra(extras, NotificationCompat.EXTRA_TEXT);
    }



}