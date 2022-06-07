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
import com.volla.launcher.util.ImagesHelper;
import java.io.ByteArrayOutputStream;
import android.util.Base64;
import java.util.UUID;
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
    private static final class ApplicationPackageNames {
        public static final String SIGNAL_PACK_NAME = "org.thoughtcrime.securesms";
    }
    private static final String KEY_TEXT_REPLY = "key_text_reply";
    /*
        These are the return codes we use in the method which intercepts
        the notifications, to decide whether we should do something or not
     */
    public static final class InterceptedNotificationCode {
        public static final int SIGNAL_CODE = 1;
        public static final int OTHER_NOTIFICATIONS_CODE = 2;
    }

    private StatusBarNotification my_custom;
    private MessageRepository repository;

    @Override
    public IBinder onBind(Intent intent) {
        repository = new MessageRepository(getApplication());
        return super.onBind(intent);
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    @Override
    public void onNotificationPosted(StatusBarNotification sbn){
        //NotificationListenerExampleService.this.cancelAllNotifications();
        int notificationCode = matchNotificationCode(sbn);
        if(notificationCode == InterceptedNotificationCode.SIGNAL_CODE) {
            my_custom = sbn;

            Message message = new Message();
            NotificationData notificationData = new NotificationData();
            notificationData.id = sbn.getId();
            notificationData.key = sbn.getKey();
            notificationData.userHandle = sbn.getUser().describeContents();
            com.volla.launcher.models.Notification notification = new Notification();
            notification.channel = sbn.getNotification().getChannelId();
            notification.shortcut= sbn.getNotification().getShortcutId();
            notification.sortKey = sbn.getNotification().getSortKey();
            notificationData.notification = notification;

            //String extras = sbn.toString();
            NotificationListenerExampleService.this.cancelAllNotifications();
            //Log.d("ArvindVolla", extras);
            Bundle bundle = sbn.getNotification().extras;
            for (String key : bundle.keySet()) {
                Object value = bundle.get(key);
                Log.d("VollaNotification sbn  key: ", key + "  :: value:" + (value == null ? "null" : value.toString()));
                //Log.d("ArvindVolla sbn value: ",value.toString());
            }
            Bundle extras = NotificationCompat.getExtras(sbn.getNotification());
            long timeInMillis = System.currentTimeMillis();
            String uuid = UUID.randomUUID().toString();
            String title = NotificationUtils.getTitle(extras);
            String notificationStr = notificationData.toJson();

            Icon icon = sbn.getNotification().getLargeIcon();
            Drawable drawable = icon.loadDrawable(getApplication());
            Bitmap appIcon = ImagesHelper.drawableToBitmap(drawable);
            ByteArrayOutputStream outStream = new ByteArrayOutputStream();
            if (appIcon.getWidth() > 128) {
                 appIcon = Bitmap.createScaledBitmap(appIcon, 96, 96, true);
            }
            appIcon.compress(Bitmap.CompressFormat.PNG, 90, outStream);
            byte[] bitmapData = outStream.toByteArray();
            String largeIcon = Base64.encodeToString(bitmapData, Base64.NO_WRAP);
            message.uuid = uuid;
            message.largeIcon = largeIcon;
            message.notification = notificationStr;
            message.title = title;
            message.selfDisplayName = extras.getString(android.app.Notification.EXTRA_SELF_DISPLAY_NAME);
            message.text = NotificationUtils.getMessage(extras);
            message.timeStamp = timeInMillis;
			Log.d("VollaNotification Inserting data into db","");
            repository.insertMessage(message);

            Users users = new Users();
            users.uuid = uuid;
            users.body = NotificationUtils.getMessage(extras);
            users.user_name = title;
            users.user_contact_number = "";
            users.read = false;
            users.isSent = false;
            users.notification = notificationStr;
            users.largeIcon = largeIcon;
            users.timeStamp = timeInMillis;
            
            
           
            repository.insertUser(users);
            message = null;
            notification = null;
            notificationData = null;
            uuid = null;
            largeIcon = null;
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


    private int matchNotificationCode(StatusBarNotification sbn) {
        String packageName = sbn.getPackageName();
        String extras = sbn.toString();
        if (packageName.equals(ApplicationPackageNames.SIGNAL_PACK_NAME)){
            return(InterceptedNotificationCode.SIGNAL_CODE);
        } else
            return(InterceptedNotificationCode.OTHER_NOTIFICATIONS_CODE);
    }


    public void reply(){
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
    }
}
