package com.volla.launcher.util;

import androidnative.SystemDispatcher;
import android.app.Activity;
import android.app.AlarmManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.provider.AlarmClock;
import android.util.Log;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.qtproject.qt5.android.QtNative;


public class AlarmUtil {
    private static final String TAG = "AlarmUtil";
    public static final String SET_ALARM = "volla.launcher.setAlarmAction";
    public static final String SET_TIMER = "volla.launcher.setTimerAction";
    public static final String DISMISS_ALARM = "volla.launcher.dismissAlarmAction";
    public static final String GET_SI_ALARMS = "volla.launcher.getSiAlarmsAction";
    public static final String GOT_SI_ALARMS = "volla.launcher.gotSiAlarmsResponse";

    private static final String PREFS = "volla_si_alarms";
    private static final String PREFS_KEY = "alarms";


    private static final ComponentName FOSSIFY_CLOCK =
            new ComponentName("org.fossify.clock", "org.fossify.clock.activities.SplashActivity");

    // ------------------------------------------------------------ storage

    private static SharedPreferences prefs(Context context) {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    private static JSONArray loadAlarms(Context context) {
        try {
            return new JSONArray(prefs(context).getString(PREFS_KEY, "[]"));
        } catch (JSONException e) {
            Log.w(TAG, "Stored SI alarms are invalid, starting empty", e);
            return new JSONArray();
        }
    }

    private static void saveAlarms(Context context, JSONArray alarms) {
        prefs(context).edit().putString(PREFS_KEY, alarms.toString()).apply();
    }


    private static long nextTrigger(int hour, int minutes) {
        Calendar c = Calendar.getInstance();
        c.set(Calendar.HOUR_OF_DAY, hour);
        c.set(Calendar.MINUTE, minutes);
        c.set(Calendar.SECOND, 0);
        c.set(Calendar.MILLISECOND, 0);
        if (c.getTimeInMillis() <= System.currentTimeMillis())
            c.add(Calendar.DAY_OF_MONTH, 1);
        return c.getTimeInMillis();
    }

    private static boolean sameTime(JSONObject alarm, int hour, int minutes) {
        return alarm.optInt("hour") == hour && alarm.optInt("minutes") == minutes;
    }

    private static JSONObject findUpcoming(Context context, int hour, int minutes) {
        long now = System.currentTimeMillis();
        JSONArray stored = loadAlarms(context);
        for (int i = 0; i < stored.length(); i++) {
            JSONObject a = stored.optJSONObject(i);
            if (a != null && a.optLong("time") > now && sameTime(a, hour, minutes))
                return a;
        }
        return null;
    }

    // ------------------------------------------------------------ actions

    static void setAlarm(Activity activity, int hour, int minutes) {
        if (hour < 0 || hour > 23 || minutes < 0 || minutes > 59) {
            Log.w(TAG, "Invalid alarm time " + hour + ":" + minutes);
            return;
        }

        if (findUpcoming(activity, hour, minutes) != null) {
            Log.i(TAG, "SI alarm at " + hour + ":" + minutes + " already set");
            return;
        }

        Intent intent = new Intent(AlarmClock.ACTION_SET_ALARM);
        intent.putExtra(AlarmClock.EXTRA_HOUR, hour);
        intent.putExtra(AlarmClock.EXTRA_MINUTES, minutes);
        intent.putExtra(AlarmClock.EXTRA_SKIP_UI, true);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        try {
            activity.startActivity(intent);
        } catch (Exception e) {
            Log.e(TAG, "No clock app handles SET_ALARM", e);
            return;
        }
        String id = String.valueOf(System.currentTimeMillis());
        try {
            JSONObject alarm = new JSONObject();
            alarm.put("id", id);
            alarm.put("hour", hour);
            alarm.put("minutes", minutes);
            alarm.put("time", nextTrigger(hour, minutes));
            JSONArray alarms = loadAlarms(activity);
            alarms.put(alarm);
            saveAlarms(activity, alarms);
            Log.i(TAG, "Set alarm " + id + " at " + hour + ":" + minutes);
        } catch (JSONException e) {
            Log.e(TAG, "Could not store alarm " + id, e);
        }
    }

    static void setTimer(Activity activity, int hour, int minutes) {
        int seconds = hour * 3600 + minutes * 60;
        if (seconds < 1 || seconds > 86400) {
            Log.w(TAG, "Timer length out of range: " + seconds);
            return;
        }
        Intent intent = new Intent(AlarmClock.ACTION_SET_TIMER);
        intent.putExtra(AlarmClock.EXTRA_LENGTH, seconds);
        intent.putExtra(AlarmClock.EXTRA_SKIP_UI, true);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        try {
            activity.startActivity(intent);
        } catch (Exception e) {
            Log.e(TAG, "No clock app handles SET_TIMER", e);
        }
    }

    static void getSiAlarms(Activity activity) {
        long now = System.currentTimeMillis();

        long nextSystemAlarm = 0;
        AlarmManager am = (AlarmManager) activity.getSystemService(Context.ALARM_SERVICE);
        if (am != null) {
            AlarmManager.AlarmClockInfo next = am.getNextAlarmClock();
            nextSystemAlarm = next != null ? next.getTriggerTime() : Long.MAX_VALUE;
        }
        Log.i(TAG, "Next system alarm: " + (nextSystemAlarm == Long.MAX_VALUE ? "none" : String.valueOf(nextSystemAlarm)));
        JSONArray stored = loadAlarms(activity);
        JSONArray kept = new JSONArray();
        List<Map<String, Object>> alarms = new ArrayList<>();
        for (int i = 0; i < stored.length(); i++) {
            JSONObject a = stored.optJSONObject(i);
            if (a == null || a.optLong("time") <= now)
                continue;

            if (a.optLong("time") + 60000 <= nextSystemAlarm) {
                Log.i(TAG, "SI alarm at " + a.optInt("hour") + ":" + a.optInt("minutes") + " was turned off in the clock app");
                continue;
            }
            kept.put(a);
            Map<String, Object> entry = new HashMap<>();
            entry.put("id", a.optString("id"));
            entry.put("hour", a.optInt("hour"));
            entry.put("minutes", a.optInt("minutes"));
            entry.put("time", (double) a.optLong("time"));
            alarms.add(entry);
        }
        if (kept.length() != stored.length())
            saveAlarms(activity, kept);
        Collections.sort(alarms, new Comparator<Map<String, Object>>() {
            public int compare(Map<String, Object> x, Map<String, Object> y) {
                return Double.compare((Double) x.get("time"), (Double) y.get("time"));
            }
        });

        Map<String, Object> reply = new HashMap<>();
        reply.put("count", alarms.size());
        reply.put("alarms", new ArrayList<Object>(alarms));
        SystemDispatcher.dispatch(GOT_SI_ALARMS, reply);
    }

    /*
     * Dismisses the SI alarms at the given time
     */
    static void dismissAlarm(Activity activity, Map message) {
        int hour = intValue(message, "hour");
        int minutes = intValue(message, "minutes");
        if (hour < 0 || hour > 23 || minutes < 0 || minutes > 59) {
            Log.w(TAG, "Invalid alarm time " + hour + ":" + minutes);
            return;
        }
        JSONArray stored = loadAlarms(activity);
        JSONArray kept = new JSONArray();
        for (int i = 0; i < stored.length(); i++) {
            JSONObject a = stored.optJSONObject(i);
            if (a != null && !sameTime(a, hour, minutes))
                kept.put(a);
        }

        Intent intent = new Intent(AlarmClock.ACTION_DISMISS_ALARM);
        intent.putExtra(AlarmClock.EXTRA_ALARM_SEARCH_MODE, AlarmClock.ALARM_SEARCH_MODE_TIME);
        intent.putExtra(AlarmClock.EXTRA_HOUR, hour);
        intent.putExtra(AlarmClock.EXTRA_MINUTES, minutes);
        intent.putExtra(AlarmClock.EXTRA_IS_PM, hour >= 12);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        boolean sent = false;
        try {
            intent.setComponent(FOSSIFY_CLOCK);
            activity.startActivity(intent);
            sent = true;
        } catch (Exception e) {
            intent.setComponent(null);
            try {
                activity.startActivity(intent);
                sent = true;
            } catch (Exception e2) {
                Log.e(TAG, "No clock app handles DISMISS_ALARM", e2);
            }
        }
        if (!sent)
            return;
        saveAlarms(activity, kept);
        Log.i(TAG, "Dismissed alarm at " + hour + ":" + minutes);
    }

    private static int intValue(Map message, String key) {
        Object value = message != null ? message.get(key) : null;
        return value instanceof Number ? ((Number) value).intValue() : 0;
    }

    static {
        SystemDispatcher.addListener(new SystemDispatcher.Listener() {
            public void onDispatched(String type, Map message) {
                if (type.equals(SET_ALARM))
                    setAlarm(QtNative.activity(), intValue(message, "hour"), intValue(message, "minutes"));
                else if (type.equals(SET_TIMER))
                    setTimer(QtNative.activity(), intValue(message, "hour"), intValue(message, "minutes"));
                else if (type.equals(GET_SI_ALARMS))
                    getSiAlarms(QtNative.activity());
                else if (type.equals(DISMISS_ALARM))
                    dismissAlarm(QtNative.activity(), message);
            }
        });
    }
}
