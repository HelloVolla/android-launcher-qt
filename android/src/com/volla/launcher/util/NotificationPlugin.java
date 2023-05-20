package com.volla.launcher.util;

import android.app.Notification;
import android.app.PendingIntent;
import android.app.RemoteInput;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.Icon;
import android.os.Build;
import android.os.Bundle;
import android.os.Parcelable;
import android.service.notification.StatusBarNotification;
import android.text.SpannableString;
import android.text.TextUtils;
import android.util.Log;
import android.util.Pair;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.core.app.NotificationCompat;
import com.volla.launcher.service.NotificationListenerExampleService;
import com.volla.launcher.util.SignalUtil;
import org.apache.commons.collections4.MultiValuedMap;
import org.apache.commons.collections4.multimap.ArrayListValuedHashMap;
import org.apache.commons.lang3.ArrayUtils;
import org.json.JSONArray;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import com.volla.launcher.storage.Message;

public class NotificationPlugin implements NotificationListenerExampleService.NotificationListener{

    private final static String TAG = "Volla/NotificationPlugin";
    private Set<String> currentNotifications;
    private Map<String, RepliableNotification> repliableNotificationMap;
    private Map<String, String> mappingNameWithThread_id;
    private MultiValuedMap<String, Notification.Action> actions;
    private boolean serviceReady;
    private SharedPreferences sharedPreferences;
    private final static String PREF_KEY = "prefKey";
    public Context context;
    private static NotificationPlugin instance;
    public static synchronized NotificationPlugin getInstance(Context context) {
        if (instance == null) {
            instance = new NotificationPlugin(context);
        }
        return instance;
    }
     public void registerListener(){
        NotificationListenerExampleService.RunCommand(context, service -> {
            Log.d(TAG, "NotificationPlugin Adding Listner");
            service.addListener(NotificationPlugin.this);

            serviceReady = service.isConnected();
            Log.d(TAG, "NotificationPlugin serviceReady "+ serviceReady);
        });
    }

    private NotificationPlugin(Context context){
        this.context = context;
        Log.d(TAG, "NotificationPlugin Condtructor0");
        repliableNotificationMap = new HashMap<>();
	mappingNameWithThread_id = new HashMap<>();
        currentNotifications = new HashSet<>();
        actions = new ArrayListValuedHashMap<>();
        sharedPreferences = context.getSharedPreferences(getSharedPreferencesName(), Context.MODE_PRIVATE);
        Log.d(TAG, "NotificationPlugin getSharedPref");
    }



    @Override
    public boolean onCreate() {

        return true;
    }
    public String getSharedPreferencesName() {
        return  "volla_preferences";
    }
    @Override
    public void onListenerConnected(NotificationListenerExampleService service) {
        serviceReady = true;
    }

    @Override
    public void onNotificationPosted(StatusBarNotification statusBarNotification) {
        sendNotification(statusBarNotification);
    }

    @Override
    public void onNotificationRemoved(StatusBarNotification statusBarNotification) {
        if (statusBarNotification == null) {
            Log.w(TAG, "onNotificationRemoved: notification is null");
            return;
        }
        String id = getNotificationKeyCompat(statusBarNotification);
        actions.remove(id);
        NetworkPacket np = new NetworkPacket(SignalUtil.PACKET_TYPE_NOTIFICATION);
        np.set("id", id);
        np.set("isCancel", true);
        currentNotifications.remove(id);
    }

    private void sendNotification(StatusBarNotification statusBarNotification) {
        Log.d(TAG, "sendNotification");
        Notification notification = statusBarNotification.getNotification();
        String key = getNotificationKeyCompat(statusBarNotification);
        String packageName = statusBarNotification.getPackageName();
        String appName = AppsHelper.appNameLookup(context, packageName);
        NetworkPacket np = new NetworkPacket(SignalUtil.PACKET_TYPE_NOTIFICATION);
        boolean isUpdate = currentNotifications.contains(key);
        //If it's an update, the other end should have the icon already: no need to extract it and create the payload again
        if (!isUpdate) {
            currentNotifications.add(key);
            Bitmap appIcon = extractIcon(statusBarNotification, notification);
        }

        np.set("actions", extractActions(notification, key));
        np.set("id", key);
        np.set("onlyOnce", (notification.flags & NotificationCompat.FLAG_ONLY_ALERT_ONCE) != 0);
        np.set("isClearable", statusBarNotification.isClearable());
        np.set("appName", appName);
        np.set("time", Long.toString(statusBarNotification.getPostTime()));
        Log.d(TAG, "RepliableNotification id "+ statusBarNotification.getId());
        RepliableNotification rn = extractRepliableNotification(statusBarNotification);
        if (rn != null) {
            np.set("requestReplyId", rn.id);
            repliableNotificationMap.put(String.valueOf(statusBarNotification.getId()), rn);
	    Log.d(TAG, "RepliableNotification id arvi");
	    Log.d(TAG, "RepliableNotification id to store repliableNotificationMap "+ statusBarNotification.getId()+" RepliableNotificationMap "+repliableNotificationMap);
        }
	mapNameWithId(statusBarNotification);
        np.set("ticker", getTickerText(notification));
        Pair<String, String> conversation = extractConversation(notification);
        if (conversation.first != null) {
            np.set("title", conversation.first);
        } else {
            np.set("title", extractStringFromExtra(getExtras(notification), NotificationCompat.EXTRA_TITLE));
        }
        np.set("text", extractText(notification, conversation));
       // Log.d(TAG, "RepliableNotification id "+ rn.id);
    }

    public void replyToNotification(String person, String id, String message) {
        Log.d(TAG, "pending Intent : " + repliableNotificationMap);
        if(person != null && person.length()>0 && mappingNameWithThread_id.containsKey(person)){
		id = mappingNameWithThread_id.get(person);
        }
        if (repliableNotificationMap == null || repliableNotificationMap.isEmpty() || id == null ||  !repliableNotificationMap.containsKey(id)) {
	    SignalUtil.errorMessageReply("No such Notification avaiable");
            Log.e(TAG, "No such notification, pending intent is null or does't contains id: " +id );
            return;
        }
        RepliableNotification repliableNotification = repliableNotificationMap.get(id);
        if (repliableNotification == null) {
	    SignalUtil.errorMessageReply("No such Notification avaiable");
            Log.e(TAG, "No such notification");
            return;
        }
        RemoteInput[] remoteInputs = new RemoteInput[repliableNotification.remoteInputs.size()];
        Intent localIntent = new Intent();
        localIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        Bundle localBundle = new Bundle();
        int i = 0;
        for (RemoteInput remoteIn : repliableNotification.remoteInputs) {
            remoteInputs[i] = remoteIn;
            localBundle.putCharSequence(remoteInputs[i].getResultKey(), message);
            i++;
        }
        RemoteInput.addResultsToIntent(remoteInputs, localIntent, localBundle);
        try {
            repliableNotification.pendingIntent.send(context, 0, localIntent);
	   // storeRepliedMessage(id,message);
        } catch (PendingIntent.CanceledException e) {
            Log.e(TAG, "replyToNotification error: " + e.getMessage());
        }
        repliableNotificationMap.remove(id);
    }
    private void storeRepliedMessage(String id, String text){
        NotificationListenerExampleService.RunCommand(context, service -> {
            service.addListener(NotificationPlugin.this);
            Message message = new Message();
            message.id = Integer.valueOf(id);
            message.text = text;
            service.storeMessage(message);
        });
    }

    private void mapNameWithId(StatusBarNotification sbn){
        Bundle extras = NotificationCompat.getExtras(sbn.getNotification());
        if(!extras.containsKey(NotificationCompat.EXTRA_MESSAGES)){
            return ;
        }
        Parcelable[] messageArray =extras.getParcelableArray(NotificationCompat.EXTRA_MESSAGES);
        Log.d(TAG, "message array length" +messageArray.length);
        Parcelable parcel = (Parcelable) messageArray[messageArray.length-1];
        Bundle latestMessageBundle = (Bundle) parcel;
        if(latestMessageBundle.containsKey("sender")){
            mappingNameWithThread_id.put(latestMessageBundle.getString("sender"), String.valueOf(sbn.getId()));
        }
    }
    private String extractText(Notification notification, Pair<String, String> conversation) {

        if (conversation.second != null) {
            return conversation.second;
        }

        Bundle extras = getExtras(notification);

        if (extras.containsKey(NotificationCompat.EXTRA_BIG_TEXT)) {
            return extractStringFromExtra(extras, NotificationCompat.EXTRA_BIG_TEXT);
        }

        return extractStringFromExtra(extras, NotificationCompat.EXTRA_TEXT);
    }

    private String getTickerText(Notification notification) {
        String ticker = "";

        try {
            Bundle extras = getExtras(notification);
            String extraTitle = extractStringFromExtra(extras, NotificationCompat.EXTRA_TITLE);
            String extraText = extractStringFromExtra(extras, NotificationCompat.EXTRA_TEXT);

            if (extraTitle != null && !TextUtils.isEmpty(extraText)) {
                ticker = extraTitle + ": " + extraText;
            } else if (extraTitle != null) {
                ticker = extraTitle;
            } else if (extraText != null) {
                ticker = extraText;
            }
        } catch (Exception e) {
            Log.e(TAG, "problem parsing notification extras for " + notification.tickerText, e);
        }

        if (ticker.isEmpty()) {
            ticker = (notification.tickerText != null) ? notification.tickerText.toString() : "";
        }

        return ticker;
    }
    @NonNull
    @RequiresApi(api = Build.VERSION_CODES.JELLY_BEAN)
    private static Bundle getExtras(Notification notification) {
        // NotificationCompat.getExtras() is expected to return non-null values for JELLY_BEAN+
        return Objects.requireNonNull(NotificationCompat.getExtras(notification));
    }

    private void sendCurrentNotifications(NotificationListenerExampleService service) {
        StatusBarNotification[] notifications = service.getActiveNotifications();
        if (notifications != null) { //Can happen only on API 23 and lower
            for (StatusBarNotification notification : notifications) {
                sendNotification(notification);
            }
        }
    }
    private static String getNotificationKeyCompat(StatusBarNotification statusBarNotification) {
        String result;
        // first check if it's one of our remoteIds
        String tag = statusBarNotification.getTag();
        String packageName = statusBarNotification.getPackageName();
        int id = statusBarNotification.getId();
        result = packageName + ":" + tag + ":" + id;
        return result;
    }

    @Nullable
    private RepliableNotification extractRepliableNotification(StatusBarNotification statusBarNotification) {

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            return null;
        }

        if (statusBarNotification.getNotification().actions == null) {
            return null;
        }

        for (Notification.Action act : statusBarNotification.getNotification().actions) {
            if (act != null && act.getRemoteInputs() != null) {
                // Is a reply
                RepliableNotification repliableNotification = new RepliableNotification();
                repliableNotification.remoteInputs.addAll(Arrays.asList(act.getRemoteInputs()));
                repliableNotification.pendingIntent = act.actionIntent;
                repliableNotification.packageName = statusBarNotification.getPackageName();
                repliableNotification.tag = statusBarNotification.getTag(); //TODO find how to pass Tag with sending PendingIntent, might fix Hangout problem

                return repliableNotification;
            }
        }

        return null;
    }

    @Nullable
    private Bitmap extractIcon(StatusBarNotification statusBarNotification, Notification notification) {
        try {
            Context foreignContext = context.createPackageContext(statusBarNotification.getPackageName(), 0);

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && notification.getLargeIcon() != null) {
                return iconToBitmap(foreignContext, notification.getLargeIcon());
            } else if (notification.largeIcon != null) {
                return notification.largeIcon;
            }

            PackageManager pm = context.getPackageManager();
            Resources foreignResources = pm.getResourcesForApplication(statusBarNotification.getPackageName());
            Drawable foreignIcon = foreignResources.getDrawable(notification.icon); //Might throw Resources.NotFoundException
            return drawableToBitmap(foreignIcon);

        } catch (PackageManager.NameNotFoundException | Resources.NotFoundException e) {
            Log.e(TAG, "Package not found: " + e.getMessage());
        }

        return null;
    }

    @Nullable
    private JSONArray extractActions(Notification notification, String key) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.KITKAT || ArrayUtils.isEmpty(notification.actions)) {
            return null;
        }

        JSONArray jsonArray = new JSONArray();

        for (Notification.Action action : notification.actions) {

            if (null == action.title)
                continue;

            // Check whether it is a reply action. We have special treatment for them
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT_WATCH &&
                    ArrayUtils.isNotEmpty(action.getRemoteInputs()))
                continue;

            jsonArray.put(action.title.toString());

            // A list is automatically created if it doesn't already exist.
            actions.put(key, action);
        }

        return jsonArray;
    }

    private Pair<String, String> extractConversation(Notification notification) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N)
            return new Pair<>(null, null);

        if (!notification.extras.containsKey(Notification.EXTRA_MESSAGES))
            return new Pair<>(null, null);

        Parcelable[] ms = notification.extras.getParcelableArray(Notification.EXTRA_MESSAGES);

        if (ms == null)
            return new Pair<>(null, null);

        String title = notification.extras.getString(Notification.EXTRA_CONVERSATION_TITLE);

        boolean isGroupConversation = notification.extras.getBoolean(NotificationCompat.EXTRA_IS_GROUP_CONVERSATION);

        StringBuilder messagesBuilder = new StringBuilder();

        for (Parcelable p : ms) {
            Bundle m = (Bundle) p;

            if (isGroupConversation && m.containsKey("sender")) {
                messagesBuilder.append(m.get("sender"));
                messagesBuilder.append(": ");
            }

            messagesBuilder.append(extractStringFromExtra(m, "text"));
            messagesBuilder.append("\n");
        }

        return new Pair<>(title, messagesBuilder.toString());
    }

    private static String extractStringFromExtra(Bundle extras, String key) {
        Object extra = extras.get(key);
        if (extra == null) {
            return null;
        } else if (extra instanceof String) {
            return (String) extra;
        } else if (extra instanceof SpannableString) {
            return extra.toString();
        } else {
            Log.e(TAG, "Don't know how to extract text from extra of type: " + extra.getClass().getCanonicalName());
            return null;
        }
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private Bitmap iconToBitmap(Context foreignContext, Icon icon) {
        if (icon == null) return null;

        return drawableToBitmap(icon.loadDrawable(foreignContext));
    }
    private Bitmap drawableToBitmap(Drawable drawable) {
        if (drawable == null) return null;

        Bitmap res;
        if (drawable.getIntrinsicWidth() > 128 || drawable.getIntrinsicHeight() > 128) {
            res = Bitmap.createBitmap(96, 96, Bitmap.Config.ARGB_8888);
        } else if (drawable.getIntrinsicWidth() <= 64 || drawable.getIntrinsicHeight() <= 64) {
            res = Bitmap.createBitmap(96, 96, Bitmap.Config.ARGB_8888);
        } else {
            res = Bitmap.createBitmap(drawable.getIntrinsicWidth(), drawable.getIntrinsicHeight(), Bitmap.Config.ARGB_8888);
        }

        Canvas canvas = new Canvas(res);
        drawable.setBounds(0, 0, res.getWidth(), res.getHeight());
        drawable.draw(canvas);
        return res;
    }



}
