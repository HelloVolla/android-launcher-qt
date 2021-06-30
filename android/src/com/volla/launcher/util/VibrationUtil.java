package com.volla.launcher.util;

import androidnative.SystemDispatcher;
import android.app.Activity;
import android.util.Log;
import android.os.Vibrator;
import android.os.VibrationEffect;
import android.os.Build;
import android.content.Context;
import java.util.Map;
import org.qtproject.qt5.android.QtNative;

public class VibrationUtil {

    private static final String TAG = "VibrationUtil";

    public static final String VIBRATE = "volla.launcher.vibrationAction";

    static {
        SystemDispatcher.addListener(new SystemDispatcher.Listener() {

            public void onDispatched(String type, Map dmessage) {

                if (type.equals(VIBRATE)) {
                    Log.d(TAG, "Will vibrate" );

                    final Activity activity = QtNative.activity();
                    final Map message = dmessage;

                    Runnable runnable = new Runnable () {
                        public void run() {
                            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                                Vibrator v = (Vibrator) activity.getSystemService(Context.VIBRATOR_SERVICE);
                                v.cancel();
                                v.vibrate(VibrationEffect.createPredefined(VibrationEffect.EFFECT_TICK));
                            }
                        }
                    };

                    Thread thread = new Thread(runnable);
                    thread.start();
                }
            }
        });
    }
}
