package com.volla.launcher.util;

import androidnative.SystemDispatcher;
import android.app.Activity;
import android.content.Intent;
import android.provider.AlarmClock;
import android.util.Log;
import java.util.Map;
import org.qtproject.qt5.android.QtNative;

public class AlarmUtil {
    private static final String TAG = "AlarmUtil";
    public static final String SET_ALARM = "volla.launcher.setAlarmAction";
    
    static {
        SystemDispatcher.addListener(new SystemDispatcher.Listener() {
            public void onDispatched(String type, Map message) {
                if (!type.equals(SET_ALARM)) return;
                final Activity activity = QtNative.activity();
                Object h = message.get("hour");
                int hour = h != null ? ((Number) h).intValue() : 0;
                Object m = message.get("minutes");
                int minutes = m != null ? ((Number) m).intValue() : 0;
                Intent intent = new Intent(AlarmClock.ACTION_SET_ALARM);
                intent.putExtra(AlarmClock.EXTRA_HOUR, hour);
                intent.putExtra(AlarmClock.EXTRA_MINUTES, minutes);
                intent.putExtra(AlarmClock.EXTRA_SKIP_UI, true);
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                try {
                    activity.startActivity(intent);
                } catch (Exception e) {
                    Log.e(TAG, "No clock app handles SET_ALARM", e);
                }
            }
        });
    }
}
