package com.volla.launcher.worker;

import androidnative.SystemDispatcher;
import android.app.Activity;
import android.os.Build;
import android.content.Intent;
import android.util.Log;
import android.net.Uri;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.database.Cursor;
import android.database.sqlite.SQLiteException;
import android.location.LocationManager;
import android.provider.Settings;
import android.provider.Telephony;
import android.provider.Telephony.TextBasedSmsColumns;
import android.provider.Telephony.Threads;
import android.provider.Telephony.ThreadsColumns;
import org.qtproject.qt5.android.QtNative;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;

public class MessageWorker {

    private static final String TAG = "MessageWorker";

    public static final String GET_MESSAGES = "volla.launcher.messageAction";
    public static final String GOT_MESSAGES = "volla.launcher.messageResponse";
    public static final String GET_THREADS  = "volla.launcher.threadAction";
    public static final String GOT_THREADS  = "volla.launcher.threadResponse";
    public static final String GET_SMS_MESSAGE = "volla.launcher.smsAction";
    public static final String GOT_SMS_MESSAGE = "volla.launcher.smsResponse";
    public static final String THREAD_ID = Telephony.TextBasedSmsColumns.THREAD_ID;
    public static final String RECIPIENT_IDs = Telephony.ThreadsColumns.RECIPIENT_IDS;

    static {
        SystemDispatcher.addListener(new SystemDispatcher.Listener() {

            public void onDispatched(String type, Map message) {
                if (type.equals(GET_SMS_MESSAGE)) {
                    getSMSMessages(message);
                } else if (type.equals(GET_MESSAGES)) {
                    getMessages(message);
                } else if (type.equals(GET_THREADS)) {
                    getThreads(message);
                }
            }
        });
    }

    static void getSMSMessages(Map message) {
        Log.d(TAG, "Invoked JAVA getSMSMessages" );

        // params are age , read , match , count

        Activity activity = org.qtproject.qt5.android.QtNative.activity();

        Uri uriSms = Uri.parse("content://sms/inbox");
        String[] projection = new String[] { "_id", "address", "date", "body", "person", "read", THREAD_ID };

        ArrayList<Map> smslist = new ArrayList();

        long cutOffTimeStamp = 0;
        try {
            String filter = " 1=1 " ;

            if ( message.containsKey("age") ) {
                int   age = (Integer) message.get("age");   // age in seconds
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

            if ( message.containsKey("read") ) {
                int read_status = (Integer) message.get("read");
                filter = filter + " and read = " + read_status ;
                }

            String sortOrder  = " date desc " ;

            if ( message.containsKey("count") ) {
                int count = (Integer) message.get("count");
                sortOrder = sortOrder + " limit " +  count ;
                }

            String[] selectionArgs = {""};
            if ( message.containsKey("match") ) {
                String match = (String) message.get("match");
                filter = filter + " and body like ? "  ;
                selectionArgs[0] = '%' + match + '%' ;
             }

            Log.d(TAG,  "SMS Filter is : " + filter );

            Cursor cursor = activity.getContentResolver().query(uriSms, projection , filter, selectionArgs , sortOrder );

            int mesgCount = cursor.getCount();
            Log.d(TAG,  "MessagesCount = " + mesgCount );
            smslist.ensureCapacity(mesgCount);

            if (cursor != null)
            {
                int index_id = cursor.getColumnIndex("_id");
                int index_address = cursor.getColumnIndex("address");
                int index_body = cursor.getColumnIndex("body");
                int index_date = cursor.getColumnIndex("date");
                int index_person = cursor.getColumnIndex("person");
                int index_read = cursor.getColumnIndex("read");
                int index_thread_id = cursor.getColumnIndex(THREAD_ID);

                while (cursor.moveToNext()) {
                    String sms_id = cursor.getString(index_id);
                    String address = cursor.getString(index_address);
                    String body = cursor.getString(index_body);
                    Long d = cursor.getLong(index_date);
                    String person = cursor.getString(index_person);
                    int read = cursor.getInt(index_read);
                    String thread_id = cursor.getString(index_thread_id);

                    Map sms = new HashMap();

                    sms.put("id", sms_id);
                    sms.put("address", address);
                    sms.put("body", body);
                    sms.put("date", d);
                    sms.put("person", person);
                    sms.put("read", read == 1 ? true : false);
                    sms.put("thread_id", thread_id);
                    smslist.add( sms );
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
        }

        Map reply = new HashMap();
        reply.put("messages", smslist );
        reply.put("messagesCount", smslist.size() );
        SystemDispatcher.dispatch(GOT_SMS_MESSAGE,reply);
    }

    static void getMessages(Map message) {
    }

    static void getThreads(Map message) {
        Log.d(TAG, "Invoked JAVA getThreads" );

        // params are age , read , match , count

        Activity activity = org.qtproject.qt5.android.QtNative.activity();

        Uri uriThread = Uri.parse("content://mms-sms/conversations/");
        String[] projection = new String[] { "*"};

        ArrayList<Map> threadlist = new ArrayList();
        long cutOffTimeStamp = 0;

        try {
            String filter = " 1=1 " ;

            if ( message.containsKey("read") ) {
                int read_status = (Integer) message.get("read");
                filter = filter + " and read = " + read_status ;
            }

            String sortOrder  = " date desc " ;

            Log.d(TAG,  "Thread Filter is : " + filter );

            Cursor cursor = activity.getContentResolver().query(uriThread, projection , filter, null , sortOrder );

            int mesgCount = cursor.getCount();
            Log.d(TAG,  "ThreadsCount = " + mesgCount );
            threadlist.ensureCapacity(mesgCount);

            if (cursor != null)
            {
                int index_id = cursor.getColumnIndex("_id"); // message id
                int index_thread_id = cursor.getColumnIndex("thread_id");
                int index_body = cursor.getColumnIndex("body");
                int index_date = cursor.getColumnIndex("date");
                int index_read = cursor.getColumnIndex("read");
                int index_person = cursor.getColumnIndex("person");
                int index_address = cursor.getColumnIndex("address");
                int index_type = cursor.getColumnIndex("ct_t");

                while (cursor.moveToNext()) {
                    for (int i = 0; i < cursor.getColumnCount(); i++) {
                        Log.d(cursor.getColumnName(i) + "", cursor.getString(i) + "");
                    }

                    String message_id = cursor.getString(index_id);
                    String thread_id = cursor.getString(index_thread_id);
                    String body = cursor.getString(index_body);
                    String person = cursor.getString(index_person);
                    String address = cursor.getString(index_address);
                    String type = cursor.getString(index_type);
                    Long d = cursor.getLong(index_date);
                    int read = cursor.getInt(index_read);

                    Map thread = new HashMap();

                    thread.put("id", message_id);
                    thread.put("thread_id", thread_id);
                    thread.put("body", body);
                    thread.put("person", person);
                    thread.put("address", address);
                    thread.put("type", type);
                    thread.put("date", d);
                    thread.put("read", read == 1 ? true : false);
                    threadlist.add( thread );
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
        }

        Map reply = new HashMap();
        reply.put("threads", threadlist );
        reply.put("threadsCount", threadlist.size() );
        SystemDispatcher.dispatch(GOT_THREADS,reply);
    }
}
