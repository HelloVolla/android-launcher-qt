package com.volla.launcher.activity;

import android.app.Activity;
import android.content.pm.PackageManager;
import android.content.pm.LauncherApps;
import android.content.pm.LauncherApps.PinItemRequest;
import android.content.pm.ShortcutInfo;
import android.content.Intent;
import android.util.Log;
import android.os.Bundle;

import com.volla.launcher.activity.ReceiveTextActivity;

public class AddShortcutActivity extends Activity {

    private static final String TAG = "AddShortcutActivity";

    @Override
    public void onCreate (Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Log.d(TAG, "onCreated() called");

        Intent intent = getIntent();
        String action = intent.getAction();
        String type = intent.getType();

        Log.d(TAG, "Intend: " + intent + ", Action: " + action + ", type: " + type);

        if (LauncherApps.ACTION_CONFIRM_PIN_SHORTCUT.equals(action)) {
            LauncherApps.PinItemRequest pinItemRequest = intent.getParcelableExtra(LauncherApps.EXTRA_PIN_ITEM_REQUEST);
            if (pinItemRequest.getRequestType() == PinItemRequest.REQUEST_TYPE_SHORTCUT) {
                ShortcutInfo shortcutInfo = pinItemRequest.getShortcutInfo();
                Log.d(TAG, "New shortcut: " + shortcutInfo.getId());

                Intent app = new Intent(this, ReceiveTextActivity.class);
                app.putExtra(LauncherApps.EXTRA_PIN_ITEM_REQUEST, pinItemRequest);
                app.setAction(LauncherApps.ACTION_CONFIRM_PIN_SHORTCUT);
                startActivity(app);
            } else {
                Log.w(TAG, "Not valid pin item request");
            }
        } else {
            Log.w(TAG, "No shortcut intent or action" );
        }
        finish();
    }
}
