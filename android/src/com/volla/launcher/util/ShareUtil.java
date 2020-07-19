package com.volla.launcher.util;

import androidnative.SystemDispatcher;
import android.app.Activity;
import android.content.Intent;
import android.util.Log;
import org.qtproject.qt5.android.QtNative;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;

public class ShareUtil {

    private static final String TAG = "Shareutil";

    public static final String GET_TEXT = "volla.launcher.receiveTextAction";
    public static final String GOT_TEXT = "volla.launcher.receiveTextResponse";

    static {
        SystemDispatcher.addListener(new SystemDispatcher.Listener() {

            public void onDispatched(String type, Map message) {
                if (type.equals(GET_TEXT)) {
                    getText(message);
                }
            }
        });
    }

    static void getText(Map message) {
        Log.d(TAG, "Invoked JAVA getText" );

        Activity activity = QtNative.activity();
        Intent intent = activity.getIntent();
        String action = intent.getAction();
        String type = intent.getType();

        Log.d(TAG, "Activity: " + activity + ", " + Action: " + action + ", type: " + type);

        if (Intent.ACTION_SEND.equals(action) && type == null && "text/plain".equals(type)) {
            String sharedText = intent.getStringExtra(Intent.EXTRA_TEXT);
            if (sharedText != null) {
                Map reply = new HashMap();
                reply.put("sharedText", sharedText );
                SystemDispatcher.dispatch(GOT_TEXT, reply);
            }
        } else {
            Log.d(TAG, "No shared text" );
        }
    }
}
