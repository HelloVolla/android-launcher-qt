package com.volla.launcher.worker;

import androidnative.SystemDispatcher;
import android.app.Activity;
import android.content.pm.ShortcutManager;
import android.content.pm.ShortcutInfo;
import android.content.pm.LauncherApps;
import android.content.pm.LauncherApps.ShortcutQuery;
import android.content.Context;
import android.util.Log;
import android.util.Base64;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.os.UserHandle;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.LinkedList;
import java.io.ByteArrayOutputStream;
import org.qtproject.qt5.android.QtNative;

public class ShortcutsWorker {

    private static final String TAG = "ShortcutsWorker";

    public static final String GET_SHORTCUTS = "volla.launcher.getShortcuts";
    public static final String GOT_SHORTCUTS = "volla.launcher.gotShortcuts";

    static {
        SystemDispatcher.addListener(new SystemDispatcher.Listener() {

            public void onDispatched(String type, Map dmessage) {
                final Activity activity = QtNative.activity();
                final Map message = dmessage;

                if (type.equals(GET_SHORTCUTS)) {
                    Runnable runnable = new Runnable () {
                        public void run() {
                            LauncherApps launcher = (LauncherApps) activity.getSystemService(Context.LAUNCHER_APPS_SERVICE);
                            ShortcutQuery query = new ShortcutQuery();
                            query.setQueryFlags(ShortcutQuery.FLAG_MATCH_PINNED);
                            int uid = activity.getApplicationInfo().uid;

                            List pinnedShortcuts = new LinkedList();

                            try {
                                List<ShortcutInfo> shortcutInfos = launcher.getShortcuts(query, UserHandle.getUserHandleForUid(uid));

                                Log.d(TAG, shortcutInfos.size() + " pinned shortucts retrieved");

                                for (int i = 0; i < shortcutInfos.size(); i++) {
                                    ShortcutInfo shortcutInfo = shortcutInfos.get(i);
                                    if (shortcutInfo.isEnabled()) {
                                        Drawable shortcutIcon = launcher.getShortcutIconDrawable(shortcutInfo,0);
                                        Map pinnedShortcut = new HashMap();
                                        pinnedShortcut.put("shortcutId", shortcutInfo.getId() );
                                        pinnedShortcut.put("package", shortcutInfo.getPackage() );
                                        pinnedShortcut.put("label", shortcutInfo.getShortLabel().toString() );
                                        pinnedShortcut.put("icon", drawableToBase64(shortcutIcon) );
                                        pinnedShortcuts.add(pinnedShortcut);
                                    } else {
                                        Log.d(TAG, "Disabled shortcut: " + shortcutInfo.getId());
                                    }
                                }
                            } catch (SecurityException se) {
                                Log.e(TAG, "An error occured: " + se.getMessage());
                            }

                            Map responseMessage = new HashMap();
                            responseMessage.put("pinnedShortcuts", pinnedShortcuts);
                            SystemDispatcher.dispatch(GOT_SHORTCUTS, responseMessage);
                        }
                    };

                    Thread thread = new Thread(runnable);
                    thread.start();
                }
            }
        });
    }

    static String drawableToBase64 (Drawable drawable) {
         Bitmap bitmap = null;

         if (drawable instanceof BitmapDrawable) {
             BitmapDrawable bitmapDrawable = (BitmapDrawable) drawable;
             if(bitmapDrawable.getBitmap() != null) {
                 bitmap = bitmapDrawable.getBitmap();
             }
         } else {
             if (drawable.getIntrinsicWidth() <= 0 || drawable.getIntrinsicHeight() <= 0) {
                 bitmap = Bitmap.createBitmap(1, 1, Bitmap.Config.ARGB_8888); // Single color bitmap will be created of 1x1 pixel
             } else {
                 bitmap = Bitmap.createBitmap(drawable.getIntrinsicWidth(), drawable.getIntrinsicHeight(), Bitmap.Config.ARGB_8888);
             }

             Canvas canvas = new Canvas(bitmap);
             drawable.setBounds(0, 0, canvas.getWidth(), canvas.getHeight());
             drawable.draw(canvas);
         }

         ByteArrayOutputStream baos = new ByteArrayOutputStream();
         bitmap.compress(Bitmap.CompressFormat.PNG, 100, baos);
         byte[] imageBytes = baos.toByteArray();
         String icon = Base64.encodeToString(imageBytes, Base64.NO_WRAP);

         return icon;
    }
}
