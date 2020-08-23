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
import android.content.res.Configuration;
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
                            int wallpaperId;
                            Configuration validConfig = new Configuration();
                            validConfig.setToDefaults();
                            Configuration deltaOnlyConfig = new Configuration();

                            if (value > 0) {
                                // dark or translucent mode
                                int flags = w.getDecorView().getSystemUiVisibility();
                                flags |= View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR;
                                flags &= ~View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
                                w.getDecorView().setSystemUiVisibility(flags);
                                if (value == 1) {
                                    wallpaperId = R.drawable.wallpaper_black;
                                } else {
                                    Log.d(TAG, "Retrieve system wallpaper" );
                                    wallpaperId = wm.getWallpaperId(WallpaperManager.FLAG_SYSTEM);
                                }
                                deltaOnlyConfig.uiMode = Configuration.UI_MODE_NIGHT_YES;
                            } else {
                                // light mode
                                int flags = w.getDecorView().getSystemUiVisibility();
                                flags &= ~View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR;
                                flags |= View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
                                w.getDecorView().setSystemUiVisibility(flags);
                                wallpaperId = R.drawable.wallpaper_white;
                                deltaOnlyConfig.uiMode = Configuration.UI_MODE_NIGHT_NO;
                            }

                            if (wm.getWallpaperId(WallpaperManager.FLAG_LOCK) != wallpaperId) {
                                try {
                                    if (value == 2) {
                                        Log.d(TAG, "Clear lock screen wallpaper");
                                        wm.clear(WallpaperManager.FLAG_LOCK);
                                    } else {
                                        wm.setResource(wallpaperId, WallpaperManager.FLAG_LOCK);
                                    }
                                } catch (IOException e) {
                                    Log.d(TAG, "Couldn't load white wallpaper: " + e.getMessage());
                                }
                            }

                            if (validConfig.uiMode != deltaOnlyConfig.uiMode) {
                                Log.d(TAG, "Will update uiMode to " + deltaOnlyConfig.uiMode);
                                validConfig.updateFrom(deltaOnlyConfig);
                            }
                        }
                    };

                    activity.runOnUiThread(runnable);
                }
            }
        });
    }
}
