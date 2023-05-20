package com.volla.launcher.service;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.media.MediaMetadata;
import android.media.session.MediaController;
import android.media.session.MediaSessionManager;
import android.os.IBinder;
import android.service.notification.NotificationListenerService;
import android.service.notification.StatusBarNotification;
import android.util.Log;

import androidx.annotation.Nullable;

import java.util.List;

public class MusicBoardNotificationListenerService extends NotificationListenerService {
    private final static String TAG = "MusicBoardNotificationListenerService";
    public MusicBoardNotificationListenerService() {
    }


    MediaSessionManager mediaSessionManager;
    MediaController controller;
    ComponentName componentName;

    MediaSessionManager.OnActiveSessionsChangedListener sessionsChangedListener = new MediaSessionManager.OnActiveSessionsChangedListener() {
        @Override
        public void onActiveSessionsChanged(@Nullable List<MediaController> controllers) {
            Log.d(TAG, "sessionsChangedListener");
            for (MediaController controller : controllers) {
                Log.d(TAG, "current player: " + controller.getPackageName());
            }
        }
    };

    @Override
    public void onNotificationPosted(StatusBarNotification sbn){
        Log.d(TAG, "onNotificationPosted " + sbn.getPackageName());
        List<MediaController> controllers = mediaSessionManager.getActiveSessions(componentName);
        for (MediaController controller : controllers) {
            Log.d(TAG, "current player: " + controller.getPackageName());
            Intent intent = new Intent("com.volla.launcher.service");
            MediaMetadata metadata = controller.getMetadata();
            if (metadata != null) {
                intent.putExtra("Music package", controller.getPackageName());
                intent.putExtra("Song name", metadata.getString(MediaMetadata.METADATA_KEY_TITLE));
                intent.putExtra("Song author", metadata.getString(MediaMetadata.METADATA_KEY_ARTIST));
            }
            sendBroadcast(intent);
        }
    }

    @Override
    public void onNotificationRemoved(StatusBarNotification sbn){
      // Implement what you want here
    }

    @Override
    public void onCreate() {
        super.onCreate();

        componentName = new ComponentName(this, MusicBoardNotificationListenerService.class);
        mediaSessionManager = (MediaSessionManager) getSystemService(Context.MEDIA_SESSION_SERVICE);
    }
    @Override
    public IBinder onBind(Intent intent) {
        return super.onBind(intent);
    }
}