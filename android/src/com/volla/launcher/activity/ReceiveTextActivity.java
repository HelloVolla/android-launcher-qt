package com.volla.launcher.activity;

import android.app.Activity;
import android.content.pm.PackageManager;
import android.content.Intent;
import android.view.Window;
import android.view.View;
import android.view.WindowManager;
import android.app.UiModeManager;
import android.graphics.Color;
import android.content.Context;
import android.util.Log;
import android.os.Bundle;
import android.os.Build;
import android.os.Handler;
import android.content.res.Configuration;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.Arrays;
import androidnative.SystemDispatcher;
import android.widget.Toast; 

public class ReceiveTextActivity extends org.qtproject.qt5.android.bindings.QtActivity
{
    private static final String TAG = "ReceiveTextActivity";

    public static final String GOT_TEXT = "volla.launcher.receiveTextResponse";

    @Override
    public void onCreate (Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Log.d(TAG, "onCreated() called");

        Window w = getWindow(); // in Activity's onCreate() for instance
        WindowManager.LayoutParams winParams = w.getAttributes();
        w.setFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS, WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS);
        w.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);

        Intent intent = getIntent();
        String action = intent.getAction();
        String type = intent.getType();

        Log.d(TAG, "Intend: " + intent + ", Action: " + action + ", type: " + type);

        if (Intent.ACTION_SEND.equals(action) && type != null && "text/plain".equals(type)) {
            String sharedText = intent.getStringExtra(Intent.EXTRA_TEXT);
            if (sharedText != null) {

                // todo: Check Url, source, save updated settings and send notification

                Map reply = new HashMap();
                reply.put("sharedText", sharedText );
                SystemDispatcher.dispatch(GOT_TEXT, reply);
            }
            Log.d(TAG, "Shared text: " +  sharedText);
        } else {
            Log.d(TAG, "No shared text" );
        }
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
        } else {
            Log.d(TAG, "No shared text" );
        }
    }

    @Override
    public void onResume() {
        super.onResume();
        Log.d(TAG, "On Resume called");
        // todo: Adopt ui mode
    }

    @Override
    public void onBackPressed() {
        Log.d(TAG, "Prevent closing app");
    }
}
