package com.volla.launcher.storage;

import android.content.Context;
import android.content.SharedPreferences;

import java.util.HashMap;
import java.util.Map;

public class NotificationStorageManager {

    private static final String PREF_NAME = "PendingNotifications";
    private static final String KEY_PACKAGE_PREFIX = "volla_";
    private static final String KEY_COUNT_SUFFIX = "_count";

    private SharedPreferences sharedPreferences;

    public NotificationStorageManager(Context context) {
        sharedPreferences = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE);
    }

    public void storeNotificationCount(String packageName, int count) {
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.putInt(KEY_PACKAGE_PREFIX + packageName + KEY_COUNT_SUFFIX, count);
        editor.apply();
    }

    public int getNotificationCount(String packageName) {
       return sharedPreferences.getInt(KEY_PACKAGE_PREFIX + packageName + KEY_COUNT_SUFFIX, 0);
    }

   public void clearNotificationCount(String packageName) {
       SharedPreferences.Editor editor = sharedPreferences.edit();
       editor.remove(KEY_PACKAGE_PREFIX + packageName + KEY_COUNT_SUFFIX);
       editor.apply();
   }


    public Map<String, Integer> getAllNotificationCounts() {
        Map<String, Integer> notificationCounts = new HashMap<>();
        Map<String, ?> allEntries = sharedPreferences.getAll();
        for (Map.Entry<String, ?> entry : allEntries.entrySet()) {
            String key = entry.getKey();
            if (key.startsWith(KEY_PACKAGE_PREFIX) && key.endsWith(KEY_COUNT_SUFFIX)) {
                String packageName = key.substring(KEY_PACKAGE_PREFIX.length(), key.length() - KEY_COUNT_SUFFIX.length());
                int count = (Integer) entry.getValue();
                notificationCounts.put(packageName, count);
            }
        }
        return notificationCounts;
       }
   }
