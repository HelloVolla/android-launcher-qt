package com.volla.launcher.service;

import androidnative.SystemDispatcher;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.media.MediaMetadata;
import android.media.session.MediaController;
import android.media.session.MediaSessionManager;
import android.os.IBinder;
import android.service.notification.NotificationListenerService;
import android.service.notification.StatusBarNotification;
import android.util.Base64;
import android.util.Log;
import java.io.ByteArrayOutputStream;

import androidx.annotation.Nullable;

import java.util.Map;
import java.util.HashMap;
import java.util.List;

public class MusicBoardNotificationListenerService extends NotificationListenerService {
    public static final String GOT_TRACK_CHANGED = "volla.launcher.trackChanged";
    public static final String GOT_PLAYER_AVAIBLE = "volla.launcher.playerAvaible";
    public static final String SEND_NEXT_TRACK = "volla.launcher.nextTrack";
    public static final String SEND_PREV_TRACK = "volla.launcher.prevTrack";

    private final static String TAG = "MusicBoardNotificationListenerService";

    public MusicBoardNotificationListenerService() {
    }

    MediaSessionManager mediaSessionManager;
    MediaController currentController;
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
        Map playerAvaibleReply = new HashMap();
        boolean hasPlayer = !controllers.isEmpty();
        playerAvaibleReply.put("hasPlayer", hasPlayer);
        SystemDispatcher.dispatch(GOT_PLAYER_AVAIBLE, playerAvaibleReply);
        if (!hasPlayer) {
            return;
        }

        Map trackDataReply = new HashMap();
        currentController = controllers.get(0);
        Log.d(TAG, "current player: " + currentController.getPackageName());
        MediaMetadata metadata = currentController.getMetadata();
        trackDataReply.put("musicPackage", currentController.getPackageName());
        trackDataReply.put("trackName", getTrackTitle(metadata));
        trackDataReply.put("trackAuthor", getTrackAuthor(metadata));
        trackDataReply.put("albumPic", getAlbomPicture(metadata));
        SystemDispatcher.dispatch(GOT_TRACK_CHANGED, trackDataReply);
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

    String getAlbomPicture(MediaMetadata metadata) {
        if (metadata == null) {
            return "";
        }
        Bitmap bitmap = metadata.getBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART);
        if (bitmap != null) {
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, baos);
            byte[] imageBytes = baos.toByteArray();
            String icon = Base64.encodeToString(imageBytes, Base64.NO_WRAP);
            return icon;
        }
        Log.d(TAG, "No album art");
        return "";
    }

    @Override
    public void onCreate() {
        super.onCreate();

        componentName = new ComponentName(this, MusicBoardNotificationListenerService.class);
        mediaSessionManager = (MediaSessionManager) getSystemService(Context.MEDIA_SESSION_SERVICE);

        SystemDispatcher.addListener(new SystemDispatcher.Listener() {

            public void onDispatched(String type, Map message) {
                if (currentController == null) {
                    return;
                }

                MediaController.TransportControls transportControls = currentController.getTransportControls();
                if (type.equals(SEND_NEXT_TRACK)) {
                    transportControls.skipToNext();
                } else if (type.equals(SEND_PREV_TRACK)) {
                    transportControls.skipToPrevious();
                }
            }
        });
    }
    @Override
    public IBinder onBind(Intent intent) {
        return super.onBind(intent);
    }
}