package com.volla.launcher.activity;

import android.app.Activity;
import android.content.pm.PackageManager;
import android.content.Intent;
import android.util.Log;
import android.os.Bundle;
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

        Intent intent = getIntent();
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
            Toast.makeText(this, sharedText, Toast.LENGTH_LONG).show();
        } else {
            Log.d(TAG, "No shared text" );
        }

        PackageManager pm = this.getPackageManager();
        Intent app = pm.getLaunchIntentForPackage("com.volla.launcher");
        startActivity(app);

        finish();
    }
}
