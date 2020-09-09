package com.volla.launcher.worker;

import androidnative.SystemDispatcher;
import android.app.Activity;
import android.os.Build;
import android.content.Intent;
import android.content.ContentResolver;
import android.util.Log;
import android.util.Base64;
import android.net.Uri;
import android.database.Cursor;
import android.database.sqlite.SQLiteException;
import android.provider.Settings;
import android.provider.Telephony;
import android.provider.Telephony.TextBasedSmsColumns;
import android.provider.Telephony.Threads;
import android.provider.Telephony.ThreadsColumns;
import android.provider.Telephony.MmsSms;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import org.qtproject.qt5.android.QtNative;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;
import java.io.InputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStreamReader;
import java.io.BufferedReader;
import java.io.IOException;

public class MessageWorker {

    private static final String TAG = "MessageWorker";

    public static final String GET_CONVERSATION = "volla.launcher.conversationAction";
    public static final String GOT_CONVERSATION = "volla.launcher.conversationResponse";
    public static final String GET_THREADS  = "volla.launcher.threadAction";
    public static final String GOT_THREADS  = "volla.launcher.threadResponse";
    public static final String GET_THREADS_COUNT = "volla.launcher.threadsCountAction";
    public static final String GOT_THREADS_COUNT  = "volla.launcher.threadsCountResponse";
    public static final String THREAD_ID = Telephony.TextBasedSmsColumns.THREAD_ID;
    public static final String RECIPIENT_IDs = Telephony.ThreadsColumns.RECIPIENT_IDS;

    static {
        SystemDispatcher.addListener(new SystemDispatcher.Listener() {

            public void onDispatched(String dtype, Map dmessage) {

                final Activity activity = QtNative.activity();
                final Map message = dmessage;
                final String type = dtype;

                Runnable runnable = new Runnable () {

                    public void run() {
                        if (type.equals(GET_CONVERSATION)) {
                            getConversation(message, activity);
                        } else if (type.equals(GET_THREADS)) {
                            getThreads(message, activity);
                        } else if (type.equals(GET_THREADS_COUNT)) {
                            getThreadsCount(message, activity);
                        }
                    }
                };

                Thread thread = new Thread(runnable);
                thread.start();
            }
        });
    }

    static void getConversation(Map message, Activity activity) {
        Log.d(TAG, "Invoked JAVA getConversation" );

        // params are threadId, age , after, afterId, read , match , count

        ArrayList<Map> messageList = new ArrayList();

        String threadId = (String) message.get("threadId");
        String personId = (String) message.get("personId");

        ArrayList<String> threadList = new ArrayList();

        if (threadId != null) {
            threadList.add( threadId );
        }

        if (personId != null) {
            Uri uriThread = Uri.parse("content://mms-sms/conversations?simple=true");

            try {
                Cursor cursor = activity.getContentResolver().query(uriThread, null, null, null , null );

                if (cursor != null)
                {
                    int index_thread_id = cursor.getColumnIndex("_id");

                    while (cursor.moveToNext()) {
                        String thId = cursor.getString(index_thread_id);
                        Uri thUri = Uri.parse("content://mms-sms/conversations/" + thId + "/");
                        String thFilter = " 1=1 ";
                        String[] thProjection = new String[] { "_id", "address", "date", "body", "person", "read", "ct_t", "type" };
                        String[] thSelectionArgs = {""};
                        String thSortOrder  = " date desc"; // limit 1";
                        Cursor thCursor = activity.getContentResolver().query(thUri , thProjection , thFilter , null , thSortOrder );
                        List numbers = (List) message.get("numbers");

                        Log.d(TAG, "Check thread " + thId);
                        boolean matched = false;

                        if (thCursor.moveToFirst()) {
                            do {
                                int index_address = thCursor.getColumnIndex("address");

                                String address = thCursor.getString(index_address);

                                for (int i = 0; i < numbers.size(); i++) {
                                    String number = ( String ) numbers.get(i);
                                    Log.d(TAG, "Compare message address " + address + " with contact number " + number);
                                    if (number.equals(address)) {
                                        Log.d(TAG, "Match");
                                        matched = true;
                                        threadList.add( thId );
                                        break;
                                    }
                                }
                            } while (thCursor.moveToNext() && !matched);
                        }

                        if (!thCursor.isClosed()) {
                            thCursor.close();
                            thCursor = null;
                        } else {
                            Log.d(TAG, "cursor is not defined");
                        }
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
        }

        for (String thId : threadList) {
            Log.d(TAG, "Check messages of therad " + thId);

            Uri uriSmsMms = Uri.parse("content://mms-sms/conversations/" + thId + "/");
            String[] projection = new String[] { "_id", "address", "date", "body", "person", "read", "ct_t", "type" };

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

                String sortOrder  = " date asc " ;

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

                Log.d(TAG,  "Message Filter is : " + filter );

                Cursor cursor = activity.getContentResolver().query(uriSmsMms , projection , filter , null , sortOrder );

                int mesgCount = cursor.getCount();
                Log.d(TAG,  "MessagesCount = " + mesgCount );
                messageList.ensureCapacity(mesgCount);

                if (cursor != null)
                {
                    int index_id = cursor.getColumnIndex("_id"); // message id
                    int index_body = cursor.getColumnIndex("body");
                    int index_date = cursor.getColumnIndex("date");
                    int index_read = cursor.getColumnIndex("read");
                    int index_person = cursor.getColumnIndex("person");
                    int index_address = cursor.getColumnIndex("address");
                    int index_type = cursor.getColumnIndex("type");
                    int index_ct_t = cursor.getColumnIndex("ct_t");

                    while (cursor.moveToNext()) {

                        String message_id = cursor.getString(index_id);
                        String body = cursor.getString(index_body);
                        String person = cursor.getString(index_person);
                        String address = cursor.getString(index_address);
                        String ct_t = cursor.getString(index_ct_t);
                        Long d = cursor.getLong(index_date);
                        int read = cursor.getInt(index_read);
                        int type = cursor.getInt(index_type);
                        boolean isMMS = false;

                        Map smsMms = new HashMap();

                        smsMms.put("id", message_id);
                        smsMms.put("body", body);
                        smsMms.put("person", person);
                        smsMms.put("address", address);
                        smsMms.put("date", Long.toString(d));
                        smsMms.put("read", read == 1 ? true : false);
                        smsMms.put("isSent", type == 2 ? true : false);
                        smsMms.put("isMMS", isMMS);

                        if ("application/vnd.wap.multipart.related".equals(ct_t)) {
                            // it's MMS
                            isMMS = true;

                            String selectionPart = "mid=" + message_id;
                            Uri uri = Uri.parse("content://mms/part");
                            Cursor mmsCursor = activity.getContentResolver().query(uri, null, selectionPart, null, null);
                            if (mmsCursor.moveToFirst()) {
                                do {
                                    String partId = mmsCursor.getString(mmsCursor.getColumnIndex("_id"));
                                    String mmsType = mmsCursor.getString(mmsCursor.getColumnIndex("ct"));
                                    if ("text/plain".equals(mmsType) && body == null) {
                                        String data = mmsCursor.getString(mmsCursor.getColumnIndex("_data"));
                                        if (data != null) {
                                            body = getMmsText(partId, activity);
                                        } else {
                                            body = mmsCursor.getString(mmsCursor.getColumnIndex("text"));
                                        }
                                        smsMms.put("body", body);
                                    }

                                    Bitmap bitmap = getMmsImage(partId, activity);
                                    if (bitmap != null) {
                                        ByteArrayOutputStream baos = new ByteArrayOutputStream();
                                        bitmap.compress(Bitmap.CompressFormat.PNG, 100, baos);
                                        byte[] imageBytes = baos.toByteArray();
                                        String image = Base64.encodeToString(imageBytes, Base64.NO_WRAP);
                                        smsMms.put("image", image);
                                    }
                                } while (mmsCursor.moveToNext());
                            }
                        }

                        messageList.add( smsMms );
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
        }

        Map reply = new HashMap();
        reply.put("messages", messageList );
        reply.put("messagesCount", messageList.size() );
        SystemDispatcher.dispatch(GOT_CONVERSATION, reply);
    }

    static void getThreadsCount(Map message, Activity activity) {
        Log.d(TAG, "Invoked JAVA getThreadsCount" );

        // params are age , read , match , count

        Uri uriThread = Uri.parse("content://mms-sms/conversations?simple=true");

        ArrayList<Map> threadlist = new ArrayList();
        long cutOffTimeStamp = 0;
        int threadsCount = -1;

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
                int new_status = (Integer) message.get("read");
                filter = filter + " and  read = " + new_status ;
            }

            String sortOrder  = " date desc " ;

            if ( message.containsKey("count") ) {
                int count = (Integer) message.get("count");
                sortOrder = sortOrder + " limit " +  count ;
            }

            String[] selectionArgs = {""};

            if ( message.containsKey("match") ) {
               String match = (String) message.get("match");
               filter = filter + " and snipped like ? "  ;
               selectionArgs[0] = '%' + match + '%' ;
            }

            Log.d(TAG, "Call filter is : " + filter );

            Cursor cursor;

            if (selectionArgs[0].length() > 0) {
                cursor = activity.getContentResolver().query(uriThread, null, filter, selectionArgs , sortOrder );
            } else {
                cursor = activity.getContentResolver().query(uriThread, null, filter, null , sortOrder );
            }

            threadsCount = cursor.getCount();
            Log.d(TAG,  "ThreadsCount = " + threadsCount );

            if (cursor != null)
            {
//                while (cursor.moveToNext()) {
//                    for (int i = 0; i < cursor.getColumnCount(); i++) {
//                        Log.d(cursor.getColumnName(i) + "", cursor.getString(i) + "");
//                    }
//                }

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
        reply.put("threadsCount", threadsCount );
        SystemDispatcher.dispatch(GOT_THREADS_COUNT, reply);
    }

    static void getThreads(Map message, Activity activity) {
        Log.d(TAG, "Invoked JAVA getThreads" );

        // params are age , read , match , count

        Uri uriThread = Uri.parse("content://mms-sms/conversations?simple=true");

        ArrayList<Map> threadlist = new ArrayList();
        long cutOffTimeStamp = 0;

        try {
            Cursor cursor = activity.getContentResolver().query(uriThread, null, null, null , null );

            int mesgCount = cursor.getCount();
            Log.d(TAG,  "ThreadsCount = " + mesgCount );
            threadlist.ensureCapacity(mesgCount);

            if (cursor != null)
            {
                int index_thread_id = cursor.getColumnIndex("_id");

                while (cursor.moveToNext()) {
//                    for (int i = 0; i < cursor.getColumnCount(); i++) {
//                        Log.d(cursor.getColumnName(i) + "", cursor.getString(i) + "");
//                    }

                    String thId = cursor.getString(index_thread_id);
                    Uri thUri = Uri.parse("content://mms-sms/conversations/" + thId + "/");
                    String thFilter = " 1=1 ";
                    String[] thProjection = new String[] { "_id", "address", "date", "body", "person", "read", "ct_t", "type" };
                    String[] thSelectionArgs = {""};
                    String thSortOrder  = " date desc limit 1";
                    Cursor thCursor = activity.getContentResolver().query(thUri , thProjection , thFilter , null , thSortOrder );

                    if (thCursor.moveToFirst()) {
                        do {
//                            for (int i = 0; i < thCursor.getColumnCount(); i++) {
//                                Log.d(thCursor.getColumnName(i) + "", thCursor.getString(i) + "");
//                            }

                            int index_id = thCursor.getColumnIndex("_id"); // message id
                            int index_body = thCursor.getColumnIndex("body");
                            int index_date = thCursor.getColumnIndex("date");
                            int index_read = thCursor.getColumnIndex("read");
                            int index_person = thCursor.getColumnIndex("person");
                            int index_address = thCursor.getColumnIndex("address");
                            int index_type = thCursor.getColumnIndex("type");
                            int index_ct_t = thCursor.getColumnIndex("ct_t");

                            String message_id = thCursor.getString(index_id);
                            String thread_id = thId;
                            String body = thCursor.getString(index_body);
                            String person = thCursor.getString(index_person);
                            String address = thCursor.getString(index_address);
                            String ct_t = thCursor.getString(index_ct_t);
                            Long d = thCursor.getLong(index_date);
                            int read = thCursor.getInt(index_read);
                            int type = thCursor.getInt(index_type);
                            boolean isMMS = false;

                            Map thread = new HashMap();

                            thread.put("id", message_id);
                            thread.put("thread_id", thread_id);
                            thread.put("body", body);
                            thread.put("person", person);
                            thread.put("address", address);
                            thread.put("date", Long.toString(d));
                            thread.put("read", read == 1 ? true : false);
                            thread.put("isSent", type == 2 ? true : false);
                            thread.put("isMMS", isMMS);

                            if ("application/vnd.wap.multipart.related".equals(ct_t)) {
                                // it's MMS
                                isMMS = true;
                                if ("application/vnd.wap.multipart.related".equals(ct_t)) {
                                    // it's MMS
                                    isMMS = true;

                                    String selectionPart = "mid=" + message_id;
                                    Uri uri = Uri.parse("content://mms/part");
                                    Cursor mmsCursor = activity.getContentResolver().query(uri, null, selectionPart, null, null);
                                    if (mmsCursor.moveToFirst()) {
                                        do {
                                            String partId = mmsCursor.getString(mmsCursor.getColumnIndex("_id"));
                                            String mmsType = mmsCursor.getString(mmsCursor.getColumnIndex("ct"));
                                            if ("text/plain".equals(mmsType)) {
                                                String data = mmsCursor.getString(mmsCursor.getColumnIndex("_data"));
                                                if (data != null) {
                                                    body = getMmsText(partId, activity);
                                                } else {
                                                    body = mmsCursor.getString(mmsCursor.getColumnIndex("text"));
                                                }
                                                thread.put("body", body);
                                            }

                                            Bitmap bitmap = getMmsImage(message_id, activity);
                                            if (bitmap != null) {
                                                ByteArrayOutputStream baos = new ByteArrayOutputStream();
                                                bitmap.compress(Bitmap.CompressFormat.PNG, 100, baos);
                                                byte[] imageBytes = baos.toByteArray();
                                                String image = Base64.encodeToString(imageBytes, Base64.NO_WRAP);
                                                thread.put("image", image);
                                            }
                                        } while (mmsCursor.moveToNext());
                                    }
                                }
                            }

                            threadlist.add( thread );
                        } while (thCursor.moveToNext());
                    }

                    if (!thCursor.isClosed()) {
                        thCursor.close();
                        thCursor = null;
                    } else {
                        Log.d(TAG, "cursor is not defined");
                    }
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

    static String getMmsText(String id, Activity activity) {
        Uri partURI = Uri.parse("content://mms/part/" + id);
        InputStream is = null;
        StringBuilder sb = new StringBuilder();
        try {
            is = activity.getContentResolver().openInputStream(partURI);
            if (is != null) {
                InputStreamReader isr = new InputStreamReader(is, "UTF-8");
                BufferedReader reader = new BufferedReader(isr);
                String temp = reader.readLine();
                while (temp != null) {
                    sb.append(temp);
                    temp = reader.readLine();
                }
            }
        } catch (IOException e) {
        } finally {
            if (is != null) {
                try {
                    is.close();
                } catch (IOException e) {}
            }
        }
        return sb.toString();
    }

    static Bitmap getMmsImage(String id, Activity activity) {
        Uri partURI = Uri.parse("content://mms/part/" + id);
        InputStream is = null;
        Bitmap bitmap = null;
        try {
            is = activity.getContentResolver().openInputStream(partURI);
            bitmap = BitmapFactory.decodeStream(is);
        } catch (IOException ioe) {
            Log.d(TAG, "Could not create bitmap: " + ioe.getMessage());
        } catch (NullPointerException npe) {
            Log.d(TAG, "Could not create bitmap: " + npe.getMessage());
        } finally {
            if (is != null) {
                try {
                    is.close();
                } catch (IOException e) {}
            }
        }
        return bitmap;
    }
}
