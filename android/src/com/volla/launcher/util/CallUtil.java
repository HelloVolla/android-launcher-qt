package com.volla.launcher.util;

import androidnative.SystemDispatcher;
import android.Manifest;
import android.app.Activity;
import android.net.Uri;
import android.util.Log;
import android.content.pm.PackageManager;
import android.content.ContentValues;
import android.provider.CallLog;
import java.util.Map;
import org.qtproject.qt5.android.QtNative;

public class CallUtil {
    private static final String TAG = "CallUtil";

    public static final String UPDATE_CALLS_AS_READ = "volla.launcher.updateCallsAsRead";

    static {
        SystemDispatcher.addListener(new SystemDispatcher.Listener() {

            public void onDispatched(String type, Map dmessage) {
                final Activity activity = QtNative.activity();
                final Map message = dmessage;

                if (type.equals(UPDATE_CALLS_AS_READ)) {
                    Runnable runnable = new Runnable () {
                        public void run() {
                            if (activity.checkSelfPermission(Manifest.permission.WRITE_CALL_LOG) == PackageManager.PERMISSION_GRANTED) {
                                updateCalls(activity);
                            }
                        }
                    };

                    Thread thread = new Thread(runnable);
                    thread.start();
                } 
            }
        });
    }

    static void updateCalls(Activity activity) {
        Log.d(TAG, "Invoked JAVA updateCalls" );

        Uri uriCalls = CallLog.Calls.CONTENT_URI;
        ContentValues values = new ContentValues();
        values.put(CallLog.Calls.IS_READ, 1);
        String whereClause = CallLog.Calls.IS_READ + " = ?";
        String placeHolderValueArr[] = {"0"};
        int k = activity.getContentResolver().update(uriCalls, values, whereClause, placeHolderValueArr);

        Log.d(TAG, k + " rows updated");
    }
}
