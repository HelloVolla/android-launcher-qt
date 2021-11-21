package com.volla.launcher.util;

import androidnative.SystemDispatcher;
import android.app.Activity;
import android.content.pm.ShortcutManager;
import android.content.pm.LauncherApps;
import android.content.Context;
import android.util.Log;
import android.os.UserHandle;
import android.widget.Toast;
import java.util.Map;
import java.util.List;
import java.util.LinkedList;
import org.qtproject.qt5.android.QtNative;

public class ShortcutUtil {

    private static final String TAG = "ShortcutsUtils";

    public static final String LAUNCH_SHORTCUT = "volla.launcher.launchShortcut";
    public static final String REMOVE_SHORTCUT = "volla.launcher.removeShortcut";

    static {
        SystemDispatcher.addListener(new SystemDispatcher.Listener() {

            public void onDispatched(String type, Map dmessage) {
                final Activity activity = QtNative.activity();
                final Map message = dmessage;

                if (type.equals(LAUNCH_SHORTCUT)) {
                    Runnable runnable = new Runnable () {
                        public void run() {
                           launchShortcut(message, activity);
                        }
                    };

                    Thread thread = new Thread(runnable);
                    thread.start();
                } else if (type.equals(REMOVE_SHORTCUT)) {
                    Runnable runnable = new Runnable () {
                        public void run() {
                           removeShortcut(message, activity);
                        }
                    };

                    Thread thread = new Thread(runnable);
                    thread.start();
                }
            }
        });
    }

    static void launchShortcut(Map message, Activity activity) {
        Log.d(TAG, "Invoked JAVA launchShortcut" );

        LauncherApps launcher = (LauncherApps) activity.getSystemService(Context.LAUNCHER_APPS_SERVICE);
        String shortcutId = (String) message.get("shortcutId");
        String shortcutPackage = (String) message.get("package");
        int uid = activity.getApplicationInfo().uid;
        launcher.startShortcut(shortcutId, shortcutPackage, null, null, UserHandle.getUserHandleForUid(uid));
    }

    static void removeShortcut(Map message, Activity activity) {
        Log.d(TAG, "Invoked JAVA removeShortcut" );

        ShortcutManager shortcutManager = activity.getSystemService(ShortcutManager.class);
        String shortcutId = (String) message.get("shortcutId");
        List<String> shortcutList = new LinkedList<String>();
        shortcutList.add(shortcutId);
        try {
            shortcutManager.disableShortcuts(shortcutList);
        } catch (IllegalStateException ise) {
            Log.d(TAG, ise.getMessage());
            Toast.makeText(activity, ise.getLocalizedMessage(), Toast.LENGTH_LONG).show();
        } catch (IllegalArgumentException iae) {
            Log.d(TAG, iae.getMessage());
            Toast.makeText(activity, iae.getLocalizedMessage(), Toast.LENGTH_LONG).show();

        }
    }
}
