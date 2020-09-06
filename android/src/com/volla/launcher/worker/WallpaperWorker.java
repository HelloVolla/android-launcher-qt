package com.volla.launcher.worker;

import androidnative.SystemDispatcher;
import android.app.Activity;
import android.app.WallpaperManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.BitmapDrawable;
import android.util.Base64;
import android.util.Log;
import java.util.Map;
import java.util.HashMap;
import java.io.ByteArrayOutputStream;
import org.qtproject.qt5.android.QtNative;

public class WallpaperWorker {

    private static final String TAG = "WallpaperWorker";

    public static final String GET_WALLPAPER = "volla.launcher.wallpaperAction";
    public static final String GOT_WALLPAPER = "volla.launcher.wallpaperResponse";

    static {
        SystemDispatcher.addListener(new SystemDispatcher.Listener() {

            public void onDispatched(String type, Map dmessage) {

                final Activity activity = QtNative.activity();
                final Map message = dmessage;

                if (type.equals(GET_WALLPAPER)) {

                    Runnable runnable = new Runnable () {
                        public void run() {
                            WallpaperManager wallpaperManager = WallpaperManager.getInstance(activity);
                            Map reply = new HashMap();

                            int wallpaperId = wallpaperManager.getWallpaperId(WallpaperManager.FLAG_SYSTEM);
                            Log.d(TAG, "Wallpaper ID is: " + wallpaperId);
                            reply.put("wallpaperId", wallpaperId);

                            if (!message.get("wallpaperId").equals(wallpaperId)) {
                                Drawable wallpaperDrawable = wallpaperManager.getDrawable();
                                String wallpaperBitmap = WallpaperWorker.drawableToBase64(wallpaperDrawable);
                                reply.put("wallpaper", wallpaperBitmap);
                            }

                            SystemDispatcher.dispatch(GOT_WALLPAPER, reply);
                        }
                    };

                    activity.runOnUiThread(runnable);
                }
            }
        });
    }

    public static String drawableToBase64 (Drawable drawable) {
        Log.d(TAG, drawable.getClass().toString());

        Bitmap bitmap = null;

        if (drawable instanceof BitmapDrawable) {
            BitmapDrawable bitmapDrawable = (BitmapDrawable) drawable;
            if (bitmapDrawable.getBitmap() != null) {
                bitmap = bitmapDrawable.getBitmap();
            }
        }

        if (bitmap == null) {
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

        return Base64.encodeToString(imageBytes, Base64.NO_WRAP);
    }
}
