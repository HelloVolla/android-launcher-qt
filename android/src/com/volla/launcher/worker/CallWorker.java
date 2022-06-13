package com.volla.launcher.worker;

import androidnative.SystemDispatcher;
import android.Manifest;
import android.app.Activity;
import android.os.Build;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.provider.CallLog;
import android.util.Log;
import android.util.Base64;
import android.net.Uri;
import android.database.Cursor;
import android.database.sqlite.SQLiteException;
import org.qtproject.qt5.android.QtNative;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;

public class CallWorker {

    private static final String TAG = "CallWorker";

    public static final String GET_CALLS = "volla.launcher.callLogAction";
    public static final String GOT_CALLS = "volla.launcher.callLogResponse";
    public static final String GET_CONVERSATION = "volla.launcher.callConversationAction";
    public static final String GOT_CONVERSATION = "volla.launcher.callConversationResponse";

    static {
        SystemDispatcher.addListener(new SystemDispatcher.Listener() {

            public void onDispatched(String type, Map dmessage) {

                final Activity activity = QtNative.activity();
                final Map message = dmessage;

                if (type.equals(GET_CALLS)) {
                    Runnable runnable = new Runnable () {
                        public void run() {
                            if (activity.checkSelfPermission(Manifest.permission.READ_CALL_LOG) == PackageManager.PERMISSION_GRANTED) {
                                getCalls(message, GOT_CALLS, activity);
                            } else {
                                Map reply = new HashMap();
                                ArrayList<Map> callList = new ArrayList();
                                reply.put("calls", callList );
                                reply.put("callsCount", callList.size() );
                                SystemDispatcher.dispatch(GOT_CALLS, reply);
                            }
                        }
                    };

                    activity.runOnUiThread(runnable);
                } else if (type.equals(GET_CONVERSATION)) {
                    Runnable runnable = new Runnable () {
                        public void run() {
                            if (activity.checkSelfPermission(Manifest.permission.READ_CALL_LOG) == PackageManager.PERMISSION_GRANTED) {
                                getCalls(message, GOT_CONVERSATION, activity);
                            } else {
                                Map reply = new HashMap();
                                ArrayList<Map> callList = new ArrayList();
                                reply.put("calls", callList );
                                reply.put("callsCount", callList.size() );
                                SystemDispatcher.dispatch(GOT_CONVERSATION, reply);
                            }
                        }
                    };

                    Thread thread = new Thread(runnable);
                    thread.start();
                }
            }
        });
    }

    static void getCalls(Map message, String responseType, Activity activity) {
        Log.d(TAG, "Invoked JAVA getCalls" );

        // params are ...

        ArrayList<Map> callList = new ArrayList();

        Uri uriCalls = CallLog.Calls.CONTENT_URI;
        String[] projection = new String[] { CallLog.Calls.NUMBER, CallLog.Calls.DATE, CallLog.Calls.IS_READ, CallLog.Calls._ID,
            CallLog.Calls.TYPE, CallLog.Calls.CACHED_NAME, CallLog.Calls.CACHED_MATCHED_NUMBER};

        long cutOffTimeStamp = 0;
        try {
            String filter = " 1=1 " ;

            if ( message.containsKey("age") ) {
                int age = (Integer) message.get("age");   // age in seconds
                cutOffTimeStamp = System.currentTimeMillis() - age * 1000 ;
                filter = filter + " and date >= " + cutOffTimeStamp ;
            }

            if ( message.containsKey("after") ) {
                String after = (String) message.get("after") ;   // after is milliseconds since epoch
                filter = filter + " and date > " + after  ;
            }

            if ( message.containsKey("afterId") ) {
                int   afterId = (Integer) message.get("afterId");
                filter = filter + " and _id > " + afterId ;
            }

            if ( message.containsKey("is_read") ) {
                int new_status = (Integer) message.get("is_read");
                filter = filter + " and is_read = " + new_status ;
            }

            String sortOrder  = " date desc " ;

            if ( message.containsKey("count") ) {
                int count = (Integer) message.get("count");
                sortOrder = sortOrder + "limit " +  count ;
            }

            String[] selectionArgs = {""};

            if ( message.containsKey("match") ) {
               String match = (String) message.get("match");
               filter = filter + " and name like ? "  ;
               selectionArgs[0] = '%' + match + '%' ;
            }

            Cursor cursor;

            if (selectionArgs[0].length() > 0) {
                cursor = activity.getContentResolver().query(uriCalls , null , filter , selectionArgs , sortOrder );
            } else {
                cursor = activity.getContentResolver().query(uriCalls , null , filter , null , sortOrder );
            }

            int mesgCount = cursor.getCount();
            Log.d(TAG, "Call count = " + mesgCount );
            callList.ensureCapacity(mesgCount);

            if (cursor != null)
            {
                int index_id = cursor.getColumnIndex(CallLog.Calls._ID); // message id
                int index_number = cursor.getColumnIndex(CallLog.Calls.NUMBER);
                int index_date = cursor.getColumnIndex(CallLog.Calls.DATE);
                int index_is_read = cursor.getColumnIndex(CallLog.Calls.IS_READ);
                int index_type = cursor.getColumnIndex(CallLog.Calls.TYPE);
                int index_name = cursor.getColumnIndex(CallLog.Calls.CACHED_NAME);
                int index_match = cursor.getColumnIndex(CallLog.Calls.CACHED_MATCHED_NUMBER);

                while (cursor.moveToNext()) {
                    String call_id = cursor.getString(index_id);
                    String number = cursor.getString(index_number);
                    String name = cursor.getString(index_name);
                    String match = cursor.getString(index_match);
                    Long d = cursor.getLong(index_date);
                    int state = cursor.getInt(index_is_read);
                    int type = cursor.getInt(index_type);

                    if (match != null) {
                        number = match;
                    }

                    Map call = new HashMap();

                    call.put("id", call_id);
                    call.put("number", number);
                    call.put("isSent", type == CallLog.Calls.OUTGOING_TYPE ? true : false);
                    call.put("name", name);
                    call.put("date", Long.toString(d));
                    call.put("is_read", state == 0 ? false : true);

                    callList.add( call );
                }
                if (!cursor.isClosed()) {
                    cursor.close();
                    cursor = null;
                } else {
                    Log.d(TAG, "cursor is not defined");
                }
            }
        } catch (SQLiteException ex) {
            Log.d("SQLiteException", ex.getMessage());
        } catch (IllegalArgumentException iae) {
            Log.d("IllegalArgumentException", iae.getMessage());
        }

        Map reply = new HashMap();
        reply.put("calls", callList );
        reply.put("callsCount", callList.size() );
        SystemDispatcher.dispatch(responseType, reply);
    }
}
