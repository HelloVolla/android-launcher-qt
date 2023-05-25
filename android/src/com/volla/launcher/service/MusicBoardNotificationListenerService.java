package com.volla.launcher.service;

import androidnative.SystemDispatcher;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.media.MediaMetadata;
import android.media.session.MediaController;
import android.media.session.MediaSessionManager;
import android.media.session.PlaybackState;
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
    public static final String SEND_PLAY_PAUSE_TRACK = "volla.launcher.playPauseTrack";
    public static final String GOT_TRACK_PLAYING_STATUS = "volla.launcher.gotPlayingStatus";
    public static final String GOT_TRACK_CHANGED = "volla.launcher.trackChanged";
    public static final String GOT_PLAYER_AVAILABLE = "volla.launcher.playerAvailable";
    public static final String SEND_NEXT_TRACK = "volla.launcher.nextTrack";
    public static final String SEND_PREV_TRACK = "volla.launcher.prevTrack";

    private final static String TAG = "MusicBoardNotificationListenerService";

    private MediaController.Callback mediaControllerCallback = new MediaController.Callback() {
        @Override
        public void onPlaybackStateChanged(PlaybackState state) {
            dispatchSessionData();
        }
        @Override
        public void onMetadataChanged(MediaMetadata metadata) {
            dispatchSessionData();
        }
    };

    public MusicBoardNotificationListenerService() {
    }

    MediaSessionManager mediaSessionManager;
    MediaController currentController;
    ComponentName componentName;

    @Override
    public void onNotificationPosted(StatusBarNotification sbn){
        dispatchSessionData();
    }

    @Override
    public void onNotificationRemoved(StatusBarNotification sbn){
      // Implement what you want here
    }

    void dispatchSessionData() {
        List<MediaController> controllers = mediaSessionManager.getActiveSessions(componentName);
        Map playerAvailableReply = new HashMap();
        boolean hasPlayer = !controllers.isEmpty();
        playerAvailableReply.put("hasPlayer", hasPlayer);
        SystemDispatcher.dispatch(GOT_PLAYER_AVAILABLE, playerAvailableReply);
        if (!hasPlayer) {
            return;
        }

        if (currentController != null) {
            currentController.unregisterCallback(mediaControllerCallback);
        }
        currentController = controllers.get(0);
        currentController.registerCallback(mediaControllerCallback);
        Log.d(TAG, "current player: " + currentController.getPackageName());
        MediaMetadata metadata = currentController.getMetadata();
        Map trackDataReply = new HashMap();
        trackDataReply.put("musicPackage", currentController.getPackageName());
        trackDataReply.put("trackName", getTrackTitle(metadata));
        trackDataReply.put("trackAuthor", getTrackAuthor(metadata));
        trackDataReply.put("albumPic", getAlbomPicture(metadata));
        SystemDispatcher.dispatch(GOT_TRACK_CHANGED, trackDataReply);
        dispatchPlayingStatus(currentController.getPlaybackState());
    }

    void dispatchPlayingStatus(PlaybackState state) {
        if (state == null) {
            return;
        }
        Map reply = new HashMap();
        reply.put("playingStatus", isPlaying(state));
        SystemDispatcher.dispatch(GOT_TRACK_PLAYING_STATUS, reply);
    }

    boolean isPlaying(PlaybackState state) {
        if (state == null) {
            return false;
        }
        return state.getState() == PlaybackState.STATE_PLAYING;
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

    void playPause(MediaController controller) {
        if (isPlaying(controller.getPlaybackState())) {
            controller.getTransportControls().pause();
        } else {
            controller.getTransportControls().play();
        }
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
                } else if (type.equals(SEND_PLAY_PAUSE_TRACK)) {
                    playPause(currentController);
                }
            }
        });

        dispatchSessionData();
    }
    @Override
    public IBinder onBind(Intent intent) {
        return super.onBind(intent);
    }
}