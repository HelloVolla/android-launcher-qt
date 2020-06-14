package com.volla.launcher.util;

import androidnative.SystemDispatcher;
import android.os.Build;
import android.app.Activity;
import android.util.Log;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.graphics.Color;
import java.util.Map;
import org.qtproject.qt5.android.QtNative;

public class LayoutUtil {

    private static final String TAG = "LayoutUtil";

    public static final String SET_LAYOUT = "volla.launcher.layoutAction";
    public static final String SET_COLOR = "volla.launcher.colorAction";

    static {
        SystemDispatcher.addListener(new SystemDispatcher.Listener() {

            public void onDispatched(String type, Map message) {
                if (type.equals(SET_LAYOUT)) {

                    final Activity activity = QtNative.activity();

                    Runnable runnable = new Runnable () {

                        public void run() {
                            Window w = activity.getWindow(); // in Activity's onCreate() for instance
                            WindowManager.LayoutParams winParams = w.getAttributes();

                            w.setFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS, WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS);

                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                                w.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
                            }
                        }
                    };

                    activity.runOnUiThread(runnable);
                } else if (type.equals(SET_COLOR)) {
                    final int value = (int) message.get("value");
                    final Activity activity = QtNative.activity();

                    Runnable runnable = new Runnable () {

                        public void run() {
                            Window w = activity.getWindow(); // in Activity's onCreate() for instance
                            WindowManager.LayoutParams winParams = w.getAttributes();

                            if (value > 0) {
                                // light view
                                int flags = w.getDecorView().getSystemUiVisibility();
                                flags |= View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR;
                                flags &= ~View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
                                w.getDecorView().setSystemUiVisibility(flags);
                            } else {
                                int flags = w.getDecorView().getSystemUiVisibility();
                                flags &= ~View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR;
                                flags |= View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
                                w.getDecorView().setSystemUiVisibility(flags);
                            }
                        }
                    };

                    activity.runOnUiThread(runnable);
                }
            }
        });
    }
}
