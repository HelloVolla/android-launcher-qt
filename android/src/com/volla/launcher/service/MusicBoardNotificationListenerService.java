package com.volla.launcher.service;

import androidnative.SystemDispatcher;
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

import java.util.Map;
import java.util.HashMap;
import java.util.List;

public class MusicBoardNotificationListenerService extends NotificationListenerService {
    public static final String GOT_TRACK_CHANGED = "volla.launcher.trackChanged";

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
            MediaMetadata metadata = controller.getMetadata();
            Map reply = new HashMap();
            reply.put("musicPackage", controller.getPackageName());
            reply.put("trackName", getTrackTitle(metadata));
            reply.put("trackAuthor", getTrackAuthor(metadata));
            SystemDispatcher.dispatch(GOT_TRACK_CHANGED, reply);
        }
    }

    @Override
    public void onNotificationRemoved(StatusBarNotification sbn){
      // Implement what you want here
    }

    String getTrackTitle(MediaMetadata metadata) {
        if (metadata == null) {
            return "";
        }
        String title = metadata.getString(MediaMetadata.METADATA_KEY_TITLE);
        if (!title.isEmpty()) {
            return title;
        }
        String display_title = metadata.getString(MediaMetadata.METADATA_KEY_DISPLAY_TITLE);
        if (!display_title.isEmpty()) {
            return display_title;
        }
        return "";
    }

    String getTrackAuthor(MediaMetadata metadata) {
        if (metadata == null) {
            return "";
        }
        String artist = metadata.getString(MediaMetadata.METADATA_KEY_ARTIST);
        if (!artist.isEmpty()) {
            return artist;
        }
        String author = metadata.getString(MediaMetadata.METADATA_KEY_AUTHOR);
        if (!author.isEmpty()) {
            return author;
        }
        String writer = metadata.getString(MediaMetadata.METADATA_KEY_WRITER);
        if (!writer.isEmpty()) {
            return writer;
        }
        return "";
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