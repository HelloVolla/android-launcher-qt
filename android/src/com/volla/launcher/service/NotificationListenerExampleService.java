package com.volla.launcher.service;

import android.app.PendingIntent;
import android.content.Intent;
import android.graphics.drawable.Icon;
import android.graphics.drawable.Drawable;
import android.os.Build;
import android.os.Bundle;
import android.os.IBinder;
import android.service.notification.NotificationListenerService;
import android.service.notification.StatusBarNotification;
import android.util.Log;
import android.graphics.Bitmap;
import androidx.annotation.RequiresApi;
import androidx.core.app.NotificationCompat;
import java.io.ByteArrayOutputStream;
import com.volla.launcher.models.Action;
import com.volla.launcher.models.Notification;
import com.volla.launcher.models.NotificationData;
import com.volla.launcher.repository.MessageRepository;
import com.volla.launcher.storage.Message;
import com.volla.launcher.storage.Users;
import com.volla.launcher.util.NotificationUtils;
import com.volla.launcher.util.SignalUtil;
import java.io.ByteArrayOutputStream;
import android.util.Base64;
import java.util.UUID;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import android.content.Context;
import android.app.Service;
import java.io.IOException;
import android.net.Uri;
import android.graphics.BitmapFactory;
import java.io.InputStream;
import android.os.Parcelable;
import android.graphics.Matrix;

/**
 * MIT License
 *
 *  Copyright (c) 2016 Fábio Alves Martins Pereira (Chagall)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
public class NotificationListenerExampleService extends NotificationListenerService {

    /*
        These are the package names of the apps. for which we want to
        listen the notifications
     */
    private final static String TAG = "NotificationListener";
    private static final class ApplicationPackageNames {
        public static final String SIGNAL_PACK_NAME = "org.thoughtcrime.securesms";
    }
    private static final String KEY_TEXT_REPLY = "key_text_reply";
    /*
        These are the return codes we use in the method which 1intercepts
        the notifications, to decide whether we should do somehing or not
     */
    public static final class InterceptedNotificationCode {
        public static final int SIGNAL_CODE = 1;
        public static final int OTHER_NOTIFICATIONS_CODE = 2;
    }

    private StatusBarNotification my_custom;
    private MessageRepository repository;
    private static boolean isSignaldEnable = false;
    private final static ArrayList<InstanceCallback> callbacks = new ArrayList<>();
    private final static Lock mutex = new ReentrantLock(true);
    private boolean connected = true;
    public NotificationData notificationData;
    void NotificationListenerExampleService(){

    }


    public static void enableSignald(boolean enable){
       isSignaldEnable = enable;
    }

    public interface InstanceCallback {
        void onServiceStart(NotificationListenerExampleService service);
    }
    public interface NotificationListener {
        boolean onCreate();

        void onNotificationPosted(StatusBarNotification statusBarNotification);

        void onNotificationRemoved(StatusBarNotification statusBarNotification);

        void onListenerConnected(NotificationListenerExampleService service);
    }

    private final ArrayList<NotificationListener> listeners = new ArrayList<>();

    public void addListener(NotificationListener listener) {
        Log.d(TAG,"Adding Listener");
	if(!listeners.contains(listener)){
            listeners.add(listener);
        }
    }

    public void removeListener(NotificationListener listener) {
        listeners.remove(listener);
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        //Log.e("NotificationReceiver", "onStartCommand");
        mutex.lock();
        try {
            for (InstanceCallback c : callbacks) {
                c.onServiceStart(this);
            }
            callbacks.clear();
        } finally {
            mutex.unlock();
        }
        return Service.START_STICKY;
    }

    @Override
    public void onListenerConnected() {
        super.onListenerConnected();
        for (NotificationListener listener : listeners) {
            listener.onListenerConnected(this);
        }
        connected = true;
    }

    @Override
    public IBinder onBind(Intent intent) {
        repository = new MessageRepository(getApplication());
        return super.onBind(intent);
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    @Override
    public void onNotificationPosted(StatusBarNotification sbn){
        Log.d(TAG, "onNotificationPosted");

        Log.d(TAG, "listeners size  : " +listeners.size());
        for (NotificationListener listener : listeners) {
            listener.onNotificationPosted(sbn);
        }

        if (!isSignaldEnable){
              return;
        }

        int notificationCode = matchNotificationCode(sbn);
        if (notificationCode == InterceptedNotificationCode.SIGNAL_CODE) {
            my_custom = sbn;
            notificationData = new NotificationData();
            notificationData.id = sbn.getId();
            notificationData.key = sbn.getKey();
            notificationData.userHandle = sbn.getUser().describeContents();
            com.volla.launcher.models.Notification notification = new Notification();
            notification.channel = sbn.getNotification().getChannelId();
            notification.shortcut= sbn.getNotification().getShortcutId();
            notification.sortKey = sbn.getNotification().getSortKey();
            notificationData.notification = notification;

            //String extras = sbn.toString();
            //Log.d("ArvindVolla", extras);
            Bundle bundle = sbn.getNotification().extras;
            /*for (String key : bundle.keySet()) {
                Object value = bundle.get(key);
                Log.d("VollaNotification sbn  key: ", key + "  :: value:" + (value == null ? "null" : value.toString()));
                //Log.d("ArvindVolla sbn value: ",value.toString());
            }*/
            Bundle extras = NotificationCompat.getExtras(sbn.getNotification());
            long timeInMillis = System.currentTimeMillis();
            String uuid = UUID.randomUUID().toString();
            String title = NotificationUtils.getTitle(extras);
            String notificationStr = notificationData.toJson();
            Users users = new Users();
            Icon icon = sbn.getNotification().getLargeIcon();
            byte[] bitmapData = null;
            if(icon != null){
                Drawable drawable = icon.loadDrawable(getApplication());
                Bitmap appIcon = SignalUtil.drawableToBitmap(drawable);
                Log.d("VollaNotification extra", "capturing large Icon");
                ByteArrayOutputStream outStream = new ByteArrayOutputStream();
                if (appIcon != null && appIcon.getWidth() > 128) {
                    appIcon = Bitmap.createScaledBitmap(appIcon, 96, 96, true);
                }
                appIcon.compress(Bitmap.CompressFormat.PNG, 10, outStream);
                bitmapData = outStream.toByteArray();
                String largeIcon = Base64.encodeToString(bitmapData, Base64.NO_WRAP);
		Log.d("com.volla.launcher", "image : "+largeIcon);
                users.largeIcon = largeIcon;
            }

            // Droping the Notifications received for attachments but contains no attachment data
            Message msg = new Message();
            msg = storeNotificationMessage(sbn);
            if(msg.getText().equalsIgnoreCase("\uD83D\uDCF7 Photo") && msg.getLargeIcon().length() <=2){
               return;
            }
            repository.insertMessage(msg);
 
            users.uuid = String.valueOf(sbn.getId());
            users.body = NotificationUtils.getMessage(extras);
            users.user_name = title;
            users.user_contact_number = "";
            users.read = false;
            users.isSent = false;
            users.notification = notificationStr;
            users.timeStamp = timeInMillis;           
            repository.insertUser(users);

            notification = null;
            notificationData = null;
            uuid = null;
            title = null;

            try {
                Log.d("VollaNotification extra", String.valueOf(sbn.getNotification().extras));
                String channel_id;
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    channel_id = sbn.getNotification().getChannelId();
                    Log.d("VollaNotification  channel_id: ", channel_id);
                    //if(notificationCode != InterceptedNotificationCode.OTHER_NOTIFICATIONS_CODE){
                    Intent intent = new Intent("com.volla.launcher.notification");
                    intent.putExtra("Notification Code", notificationCode);
                    intent.putExtra("channel_d", channel_id);
                    intent.setAction("com.volla.launcher.notification");
                    intent.putExtra("largeIcon", bitmapData);
                    intent.putExtra("title", NotificationUtils.getTitle(extras));
                    intent.putExtra("body", NotificationUtils.getMessage(extras));
                    sendBroadcast(intent);
                }
            } catch(Exception e){
                e.printStackTrace();
                Log.e("NotificationsPlugin", "Error retrieving icon");
            }
        }
    }

    @Override
    public void onNotificationRemoved(StatusBarNotification sbn){
        Log.d(TAG, "onNotificationPosted");

        int notificationCode = matchNotificationCode(sbn);
        if(notificationCode != InterceptedNotificationCode.OTHER_NOTIFICATIONS_CODE) {
            StatusBarNotification[] activeNotifications = this.getActiveNotifications();
            if(activeNotifications != null && activeNotifications.length > 0) {
                for (int i = 0; i < activeNotifications.length; i++) {
                    if (notificationCode == matchNotificationCode(activeNotifications[i])) {
                        Intent intent = new  Intent("com.volla.launcher.notification");
                        intent.putExtra("Notification Code", notificationCode);
                        sendBroadcast(intent);
                        break;
                    }
                }
            }
        }
    }

    private Message storeNotificationMessage(StatusBarNotification sbn){
        Log.d(TAG, "storeNotificationMessage");
        Message msg = new Message();
        Bundle extras = NotificationCompat.getExtras(sbn.getNotification());
        if(!extras.containsKey(NotificationCompat.EXTRA_MESSAGES)){
            return msg;
        }
        Parcelable[] messageArray =extras.getParcelableArray(NotificationCompat.EXTRA_MESSAGES);
        Log.d(TAG, "message array length" +messageArray.length);
        Parcelable parcel = (Parcelable) messageArray[messageArray.length-1];
        Bundle latestMessageBundle = (Bundle) parcel;
        msg.largeIcon = getBase64OfAttachment(latestMessageBundle);
        msg.uuid = String.valueOf(sbn.getId());
        msg.notification = notificationData.toJson();
        if(latestMessageBundle.containsKey("text")){
            msg.text = String.valueOf(latestMessageBundle.get("text"));
            msg.title = String.valueOf(latestMessageBundle.get("text"));
        }
        if(latestMessageBundle.containsKey("sender")){
            msg.selfDisplayName = latestMessageBundle.getString("sender");
        }
        if(latestMessageBundle.containsKey("time")){
            msg.timeStamp = latestMessageBundle.getLong("time");
        }
        Log.d("VollaNotification ","Inserting data into db "+msg.toString());
        return msg;
    }

    private String getBase64OfAttachment(Bundle latestMessageBundle){
        Log.d(TAG, "getBase64OfAttachment");

        String base64 = "";
        if (latestMessageBundle.containsKey("text")) {
            Log.d(TAG,"Last mesage text "+latestMessageBundle.get("text"));
        }
        if (latestMessageBundle.containsKey("uri")) {
            try {
                byte[] bitmapData = null;
                Log.d(TAG,"Last mesage contains attachment "+latestMessageBundle.get("uri"));
                Bitmap attachmentBitmap = getBitmapFromUri(this,Uri.parse(Uri.decode(latestMessageBundle.get("uri").toString())));
                if (attachmentBitmap == null) return base64;
                ByteArrayOutputStream outStream = new ByteArrayOutputStream();
                int maxHeight = 640;
                int maxWidth = 640;
                if (attachmentBitmap.getHeight() > maxHeight || attachmentBitmap.getWidth() > maxWidth) {
                       float scale = Math.min(((float)maxHeight / attachmentBitmap.getWidth()), ((float)maxWidth / attachmentBitmap.getHeight()));
                       Matrix matrix = new Matrix();
                       matrix.postScale(scale, scale);
                       attachmentBitmap = Bitmap.createBitmap(attachmentBitmap, 0, 0, attachmentBitmap.getWidth(), attachmentBitmap.getHeight(), matrix, true);
                }
                attachmentBitmap.compress(Bitmap.CompressFormat.PNG, 100, outStream);
                bitmapData = outStream.toByteArray();
                base64 = Base64.encodeToString(bitmapData, Base64.NO_WRAP);
            } catch (IOException e) {
                Log.e(TAG, "IOException: " + e.getMessage());
            } catch (SecurityException se) {
                Log.e(TAG, "SecurityExcetion: " + se.getMessage());
            }
        }
        return base64;
    }

    public Bitmap getBitmapFromUri(Context context, Uri uri) throws IOException {
        InputStream input;
        BitmapFactory.Options onlyBoundsOptions;
        try {
            input = context.getContentResolver().openInputStream(uri);
            onlyBoundsOptions = new BitmapFactory.Options();
            onlyBoundsOptions.inJustDecodeBounds = true;
            BitmapFactory.decodeStream(input, null, onlyBoundsOptions);
            input.close();
        } catch (SecurityException se) {
            Log.e(TAG, "SecurityExcetion: " + se.getMessage());
            return null;
        }

        if ((onlyBoundsOptions.outWidth == -1) || (onlyBoundsOptions.outHeight == -1))
            return null;
        int originalSize = (onlyBoundsOptions.outHeight > onlyBoundsOptions.outWidth) ? onlyBoundsOptions.outHeight : onlyBoundsOptions.outWidth;
        BitmapFactory.Options bitmapOptions = new BitmapFactory.Options();

        input = context.getContentResolver().openInputStream(uri);
        Bitmap bitmap = BitmapFactory.decodeStream(input, null, bitmapOptions);
        input.close();
        return bitmap;
    }

    public void storeMessage(Message msg){
        msg.timeStamp = System.currentTimeMillis();
        repository.insertMessage(msg);
	Log.d(TAG, "msg.id :"+msg.id);
        Log.d(TAG, "msg.id :"+msg.text);
        Log.d(TAG, "msg.id :"+msg.timeStamp);
    }

    private int matchNotificationCode(StatusBarNotification sbn) {
        String packageName = sbn.getPackageName();
        String extras = sbn.toString();
        if (packageName.equals(ApplicationPackageNames.SIGNAL_PACK_NAME)){
            return(InterceptedNotificationCode.SIGNAL_CODE);
        } else
            return(InterceptedNotificationCode.OTHER_NOTIFICATIONS_CODE);
    }

  /*  public void reply(){
        Action action = NotificationUtils.getQuickReplyAction(my_custom.getNotification(), getPackageName());
        if (action != null) {
            Log.i("ArvindVolla", "success");
            try {
                action.sendReply(getApplicationContext(), "Hello Arvind");
            } catch (PendingIntent.CanceledException e) {
                Log.i("ArvindVolla", "CRAP " + e.toString());
            }
        } else {
            Log.i("ArvindVolla", "not success");
        }
    }*/

    public boolean isConnected() {
        return connected;
    }

    public static void Start(Context c) {
        RunCommand(c, null);
    }

    public static void RunCommand(Context c, final InstanceCallback callback) {
        Log.d(TAG,"RunCommand "+callback);
        if (callback != null) {
            Log.d(TAG,"callback != null "+callback);
            mutex.lock();
            try {
                callbacks.add(callback);
                Log.d(TAG,"RunCommand callbacks.add"+callback);
            } finally {
                mutex.unlock();
            }
        }
        Intent serviceIntent = new Intent(c, NotificationListenerExampleService.class);
        c.startService(serviceIntent);
    }
}
