package com.volla.launcher.activity;

import android.app.Activity;
import android.content.pm.PackageManager;
import android.content.pm.LauncherApps;
import android.content.pm.LauncherApps.PinItemRequest;
import android.content.pm.ShortcutInfo;
import android.content.Intent;
import android.view.Window;
import android.view.View;
import android.view.WindowManager;
import android.app.UiModeManager;
import android.graphics.Color;
import android.graphics.drawable.Drawable;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.util.Log;
import android.os.Bundle;
import android.os.Build;
import android.os.Handler;
import android.content.Context;
import android.content.IntentFilter;
import android.content.res.Configuration;
import android.util.Base64;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.Arrays;
import java.io.ByteArrayOutputStream;
import androidnative.SystemDispatcher;
import android.widget.Toast; 

public class ReceiveTextActivity extends org.qtproject.qt5.android.bindings.QtActivity
{
    private static final String TAG = "ReceiveTextActivity";

    public static final String GOT_TEXT = "volla.launcher.receiveTextResponse";
    public static final String GOT_SHORTCUT = "volla.launcher.receivedShortcut";

    @Override
    public void onCreate (Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Log.d(TAG, "onCreated() called");

        Window w = getWindow(); // in Activity's onCreate() for instance
        WindowManager.LayoutParams winParams = w.getAttributes();
        w.setFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS, WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS);
        w.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
    }

    @Override
    public void onNewIntent(Intent intent) {
        Log.d(TAG, "onNewIntend() called");

        super.onNewIntent(intent);

        String action = intent.getAction();
        String type = intent.getType();

        Log.d(TAG, "Intend: " + intent + ", Action: " + action + ", type: " + type);

        if (Intent.ACTION_SEND.equals(action) && type != null && "text/plain".equals(type)) {
            String sharedText = intent.getStringExtra(Intent.EXTRA_TEXT);
            if (sharedText != null) {
                Map reply = new HashMap();
                reply.put("sharedText", sharedText );
                SystemDispatcher.dispatch(GOT_TEXT, reply);
            }
            Log.d(TAG, "Shared text: " +  sharedText);
        } else if (intent.hasExtra(LauncherApps.EXTRA_PIN_ITEM_REQUEST)) {
            LauncherApps.PinItemRequest pinItemRequest = intent.getParcelableExtra(LauncherApps.EXTRA_PIN_ITEM_REQUEST);
            if (pinItemRequest.getRequestType() == PinItemRequest.REQUEST_TYPE_SHORTCUT) {
                ShortcutInfo shortcutInfo = pinItemRequest.getShortcutInfo();
                LauncherApps launcher = (LauncherApps) getSystemService(Context.LAUNCHER_APPS_SERVICE);
                Drawable shortcutIcon = launcher.getShortcutIconDrawable(shortcutInfo,0);

                Map reply = new HashMap();
                reply.put("shortcutId", shortcutInfo.getId() );
                reply.put("package", shortcutInfo.getPackage() );
                reply.put("label", shortcutInfo.getShortLabel().toString() );
                reply.put("icon", drawableToBase64(shortcutIcon) );

                SystemDispatcher.dispatch(GOT_SHORTCUT, reply);

                boolean success = pinItemRequest.accept();

                Log.d(TAG, "New shortcut: " + shortcutInfo.getId());
                Log.d(TAG, "Shortcut is accepted: " + success);
                //Toast.makeText(this, "New Shorcut " + shortcutInfo.getId(), Toast.LENGTH_LONG).show();

            } else {
                Log.w(TAG, "Not valid pin item request");
            }
        }
    }

    @Override
    public void onResume() {
        super.onResume();
        Log.d(TAG, "On Resume called");
        // todo: Adopt ui mode
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String permissions[], int[] grantResults) {
        Log.d(TAG, "Received permission result for request " + requestCode);
    }

    @Override
    public void onBackPressed() {
        Log.d(TAG, "Prevent closing app");
    }

    private String drawableToBase64 (Drawable drawable) {
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
         return Base64.encodeToString(imageBytes, Base64.NO_WRAP);
    }
}
