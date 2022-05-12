package com.volla.launcher.service;

import android.app.PendingIntent;
import android.content.Intent;
import android.graphics.drawable.Icon;
import android.os.Build;
import android.os.Bundle;
import android.os.IBinder;
import android.service.notification.NotificationListenerService;
import android.service.notification.StatusBarNotification;
import android.util.Log;

import androidx.annotation.RequiresApi;
import androidx.core.app.NotificationCompat;

import com.volla.launcher.models.Action;
import com.volla.launcher.models.Notification;
import com.volla.launcher.models.NotificationData;
import com.volla.launcher.repository.MessageRepository;
import com.volla.launcher.storage.Message;
import com.volla.launcher.utils.NotificationUtils;

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

            String extras = sbn.toString();
            NotificationListenerExampleService.this.cancelAllNotifications();
            Log.d("ArvindVolla", extras);
            Bundle bundle = sbn.getNotification().extras;
            for (String key : bundle.keySet()) {
                Object value = bundle.get(key);
                Log.d("ArvindVolla sbn  key: ", key + "  :: value:" + (value == null ? "null" : value.toString()));
                //Log.d("ArvindVolla sbn value: ",value.toString());
            }
            Bundle extras_1 = NotificationCompat.getExtras(sbn.getNotification());
            String title = NotificationUtils.getTitle(extras_1);
            String msg = NotificationUtils.getMessage(extras_1);
            Icon bitmap = NotificationUtils.getLargeIcon(extras_1);

            message.uuid = UUID.randomUUID().toString();
            message.largeIcon = sbn.getNotification().getLargeIcon().toString();
            message.notification = notificationData.toJson();
            message.title = extras_1.getString(android.app.Notification.EXTRA_TITLE);
            message.selfDisplayName = extras_1.getString(android.app.Notification.EXTRA_SELF_DISPLAY_NAME);
            message.text = NotificationUtils.getMessage(extras_1);
            message.timeStamp = System.currentTimeMillis();
            repository.insertMessage(message);

            message = null;
            notification = null;
            notificationData = null;

            //Log.d("ArvindVolla", "Ignoring potential duplicate from " + sbn.getPackageName() + ":\n" + title + "\n" + msg);


//            Action action = NotificationUtils.getQuickReplyAction(sbn.getNotification(), getPackageName());
      /*
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
        */
            Log.d("ArvindVolla extra", String.valueOf(sbn.getNotification().extras));
            String channel_id;
//            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//                channel_id = sbn.getNotification().getChannelId();
//                Log.e("Krishna extra", channel_id);

                //if(notificationCode != InterceptedNotificationCode.OTHER_NOTIFICATIONS_CODE){
//                Intent intent = new Intent("com.volla.notificationlistenerexample");
//                Bundle bundle_1 = new Bundle();
//                sbn.getNotification().extras.putBundle("android.car.EXTENSIONS", bundle_1);
//                intent.putExtra("Notification Code", notificationCode);
//                intent.putExtra("channel_d", channel_id);
//                intent.setAction("com.volla.notificationlistenerexample");
                //intent.putExtra("my_noti",sbn.getNotification());
//                sendBroadcast(intent);
//            }
        }
        //}
    }

    @Override
    public void onNotificationRemoved(StatusBarNotification sbn){
        int notificationCode = matchNotificationCode(sbn);
        if(notificationCode != InterceptedNotificationCode.OTHER_NOTIFICATIONS_CODE) {
            StatusBarNotification[] activeNotifications = this.getActiveNotifications();
            if(activeNotifications != null && activeNotifications.length > 0) {
                for (int i = 0; i < activeNotifications.length; i++) {
                    if (notificationCode == matchNotificationCode(activeNotifications[i])) {
                        Intent intent = new  Intent("com.volla.notificationlistenerexample");
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
