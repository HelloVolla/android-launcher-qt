package com.volla.launcher.util;

import androidnative.SystemDispatcher;
import android.Manifest;
import android.os.Build;
import android.app.Activity;
import android.app.WallpaperManager;
import android.app.UiModeManager;
import android.util.Log;
import android.graphics.Color;
import android.inputmethodservice.KeyboardView;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.view.Display;
import android.content.Intent;
import android.content.Context;
import android.content.res.Resources;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.content.ComponentName;
import android.graphics.Color;
import android.graphics.Point;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.io.IOException;
import java.lang.reflect.InvocationTargetException;
import org.qtproject.qt5.android.QtNative;
import com.volla.launcher.R;

public class LayoutUtil {

    private static final String TAG = "LayoutUtil";

    public static final String SET_COLOR = "volla.launcher.colorAction";
    public static final String GET_NAVBAR_HEIGHT = "volla.launcher.navBarAction";
    public static final String GOT_NAVBAR_HEIGHT = "volla.launcher.navBarResponse";

    static {
        SystemDispatcher.addListener(new SystemDispatcher.Listener() {

            public void onDispatched(String type, Map message) {
                if (type.equals(SET_COLOR)) {
                    final int value = (int) message.get("value");
                    boolean isDarkActive = (value == 1 || value == 3 ) ? true : false;
                    final boolean updateLockScreen = (boolean) message.get("updateLockScreen");
                    final Activity activity = QtNative.activity();

                    Log.d(TAG, "Will change lock screen clock color for value " + value + " to " + (isDarkActive ? "white" : "black"));

                    Intent intent = new Intent();
                    intent.setAction("android.widget.VollaClock.action.CHANGE_COLORS");
                    intent.putExtra("android.widget.VollaClock.param.HOURS", (isDarkActive ? Color.WHITE : Color.BLACK));
                    intent.putExtra("android.widget.VollaClock.param.DATE", (isDarkActive ? Color.WHITE : Color.BLACK));
                    activity.sendBroadcast(intent);

                    Intent i = new Intent();
                    i.setAction("com.volla.simpleappstheme.action.CHANGE_COLORS");
                    i.putExtra("com.volla.simpleappstheme.param.TEXT_COLOR", (isDarkActive ? Color.WHITE : -13421773));
                    i.putExtra("com.volla.simpleappstheme.param.BACKGROUND_COLOR", (isDarkActive ? Color.BLACK : Color.WHITE));
                    i.putExtra("com.volla.simpleappstheme.param.PRIMARY_COLOR", (isDarkActive ? Color.BLACK : Color.WHITE));
                    i.putExtra("com.volla.simpleappstheme.param.ACCENT_COLOR", (isDarkActive ? Color.WHITE : Color.BLACK));
                    i.putExtra("com.volla.simpleappstheme.param.APP_ICON_COLOR", (isDarkActive ? Color.BLACK : Color.WHITE));
                    i.putExtra("com.volla.simpleappstheme.param.NAVIGATION_BAR_COLOR", (isDarkActive  ? Color.BLACK : Color.WHITE));

                    PackageManager packageManager = activity.getPackageManager();
                    List<ResolveInfo> infos = packageManager.queryBroadcastReceivers(i, 0);
                    for (ResolveInfo info : infos) {
                        ComponentName cn = new ComponentName(info.activityInfo.packageName, info.activityInfo.name);
                        i.setComponent(cn);
                        activity.sendBroadcast(i);
                    }

                    activity.sendBroadcast(i);

                    Runnable runnable = new Runnable () {

                        public void run() {
                            Window w = activity.getWindow();
                            WindowManager.LayoutParams winParams = w.getAttributes();
                            WallpaperManager wm = WallpaperManager.getInstance(activity);
                            int wallpaperId;
                            UiModeManager umm = (UiModeManager) activity.getSystemService(Context.UI_MODE_SERVICE);

                            if (isDarkActive) {
                                // dark or dark translucent mode
                                int flags = w.getDecorView().getSystemUiVisibility();
                                flags &= ~View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR;
                                flags &= ~View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
                                w.getDecorView().setSystemUiVisibility(flags);
                                if (value == 1) {
                                    Log.d(TAG, "Set night mode and black wallpaper");
                                    wallpaperId = R.drawable.wallpaper_black;
                                } else {
                                    Log.d(TAG, "Set dark mode and system wallpaper");
                                    Log.d(TAG, "Retrieve system wallpaper" );
                                    if (activity.checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED) {
                                        wallpaperId = wm.getWallpaperId(WallpaperManager.FLAG_SYSTEM);
                                    } else {
                                        wallpaperId = R.drawable.wallpaper_image;
                                    }
                                }

                                Log.d(TAG, "Will change system ui mode to " + UiModeManager.MODE_NIGHT_YES);
                                umm.setNightMode(UiModeManager.MODE_NIGHT_YES);
                            } else {
                                // light mode
                                Log.d(TAG, "Set light mode and white wallpaper");
                                int flags = w.getDecorView().getSystemUiVisibility();
                                flags |= View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR;
                                flags |= View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
                                w.getDecorView().setSystemUiVisibility(flags);

                                if (value == 0) {
                                    Log.d(TAG, "Set light mode and white wallpaper");
                                    wallpaperId = R.drawable.wallpaper_white;
                                } else {
                                    Log.d(TAG, "Set light mode and system wallpaper");
                                    Log.d(TAG, "Retrieve system wallpaper" );
                                    if (activity.checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED) {
                                        wallpaperId = wm.getWallpaperId(WallpaperManager.FLAG_SYSTEM);
                                    } else {
                                        wallpaperId = R.drawable.wallpaper_image;
                                    }
                                }

                                Log.d(TAG, "Will change system ui mode to " + UiModeManager.MODE_NIGHT_NO);
                                umm.setNightMode(UiModeManager.MODE_NIGHT_NO);
                            }

                            Log.d(TAG, "Changed system ui mode is " + umm.getNightMode());

                            if (activity.checkSelfPermission(Manifest.permission.SET_WALLPAPER) == PackageManager.PERMISSION_GRANTED
                                && wm.getWallpaperId(WallpaperManager.FLAG_LOCK) != wallpaperId
                                && updateLockScreen) {
                                Log.d(TAG, "Update lock screen wallpaper");
                                try {
                                    if (value == 2 || value == 3) {
                                        Log.d(TAG, "Clear lock screen wallpaper");
                                        wm.clear(WallpaperManager.FLAG_LOCK);
                                    } else {
                                        wm.setResource(wallpaperId, WallpaperManager.FLAG_LOCK);
                                    }
                                } catch (IOException e) {
                                    Log.d(TAG, "Couldn't load white wallpaper: " + e.getMessage());
                                }
                            }
                        }
                    };

                    activity.runOnUiThread(runnable);
                } else if (type.equals(GET_NAVBAR_HEIGHT)) {
                    final Activity activity = QtNative.activity();

                    Runnable runnable = new Runnable () {
                        public void run() {
                            Map responseMessage = new HashMap();
                            responseMessage.put("height", getNavigationBarSize(activity));
                            SystemDispatcher.dispatch(GOT_NAVBAR_HEIGHT, responseMessage);
                        }
                    };

                    Thread thread = new Thread(runnable);
                    thread.start();
                }
            }
        });
    }

    public static int getNavigationBarSize(Context context) {
        Resources resources = context.getResources();
        int resourceId = resources.getIdentifier("navigation_bar_height", "dimen", "android");
        return resources.getDimensionPixelSize(resourceId);
    }

}
