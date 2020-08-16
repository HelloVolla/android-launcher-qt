package com.volla.launcher.util;

import androidnative.SystemDispatcher;
import android.os.Build;
import android.app.Activity;
import android.app.WallpaperManager;
import android.util.Log;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.content.Context;
import android.graphics.Color;
import java.util.Map;
import java.io.IOException;
import org.qtproject.qt5.android.QtNative;
import com.volla.launcher.R;

public class LayoutUtil {

    private static final String TAG = "LayoutUtil";

    public static final String SET_LAYOUT = "volla.launcher.layoutAction";
    public static final String SET_COLOR = "volla.launcher.colorAction";

    static {
        SystemDispatcher.addListener(new SystemDispatcher.Listener() {

            public void onDispatched(String type, Map message) {
                if (type.equals(SET_LAYOUT)) {
                    Log.d(TAG, "Invoked JAVA setLayout" );

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
                            WallpaperManager wm = WallpaperManager.getInstance(activity);

                            if (value > 0) {
                                // light view
                                int flags = w.getDecorView().getSystemUiVisibility();
                                flags |= View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR;
                                flags &= ~View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
                                w.getDecorView().setSystemUiVisibility(flags);
//                                try {
                                    int wallpaperId = R.drawable.wallpaper_white;
                                    Log.d(TAG, "Wallpaper ID is: " + wallpaperId);
//                                    wm.setResource(wallpaperId, WallpaperManager.FLAG_LOCK);
//                                } catch (IOException e) {
//                                    Log.d(TAG, "Couldn't load white wallpaper: " + e.getMessage());
//                                }
                            } else {
                                int flags = w.getDecorView().getSystemUiVisibility();
                                flags &= ~View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR;
                                flags |= View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
                                w.getDecorView().setSystemUiVisibility(flags);
                                //wm.setResource(R.drawable.wallpaper_black, WallpaperManager.FLAG_LOCK);
                            }
                        }
                    };

                    activity.runOnUiThread(runnable);
                }
            }
        });
    }
}
