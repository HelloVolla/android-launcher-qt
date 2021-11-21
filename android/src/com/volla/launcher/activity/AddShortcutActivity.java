package com.volla.launcher.activity;

import android.app.Activity;
import android.content.pm.PackageManager;
import android.content.pm.LauncherApps;
import android.content.pm.LauncherApps.PinItemRequest;
import android.content.pm.ShortcutInfo;
import android.content.Intent;
import android.util.Log;
import android.os.Bundle;

public class AddShortcutActivity extends Activity {

    private static final String TAG = "AddShortcutActivity";

    public static final String GOT_SHORTCUT = "volla.launcher.receivedShortcut";

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

                Intent app = new Intent(Intent.ACTION_MAIN);
                app.addCategory(Intent.CATEGORY_HOME);
                app.putExtra(LauncherApps.EXTRA_PIN_ITEM_REQUEST, pinItemRequest);
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
