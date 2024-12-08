package com.volla.launcher.activity;

import android.app.Activity;
import android.app.PendingIntent;
import android.app.AlarmManager ;
import android.content.pm.PackageManager;
import android.content.pm.LauncherApps;
import android.content.pm.LauncherApps.PinItemRequest;
import android.content.pm.ShortcutInfo;
import android.content.Intent;
import android.view.Window;
import android.view.View;
import android.view.WindowManager;
import android.app.UiModeManager;
import android.graphics.Color;
import android.graphics.drawable.Drawable;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.util.Log;
import android.os.Bundle;
import android.os.Build;
import android.os.Handler;
import android.content.Context;
import android.content.IntentFilter;
import android.content.res.Configuration;
import android.util.Base64;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.Arrays;
import java.io.ByteArrayOutputStream;
import androidnative.SystemDispatcher;
import androidnative.AndroidNativeActivity;
import android.widget.Toast;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.BroadcastReceiver;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.NotificationCompat;
import com.volla.launcher.R;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import com.volla.launcher.util.NotificationPlugin;
import android.content.ServiceConnection;
import android.content.ComponentName;
import android.os.IBinder;
import android.os.RemoteException;
import android.util.Log;
import com.volla.smssdk.SMSUpdateManager;
import android.os.Looper;
import android.content.pm.ActivityInfo;

public class ReceiveTextActivity extends AndroidNativeActivity implements SMSUpdateManager.ServiceConnectionListener
{
    private static final String TAG = "ReceiveTextActivity";

    public static final String GOT_TEXT = "volla.launcher.receiveTextResponse";
    public static final String CHECK_SHORTCUT = "volla.launcher.checkNewShortcut";
    public static final String GOT_SHORTCUT = "volla.launcher.receivedShortcut";
    public static final String UIMODE_CHANGED = "volla.launcher.uiModeChanged";
    public List<String> smsPid;
    private Handler handler;

    private NotificationBroadcastReceiver notificationBroadcastReceiver;
    public static ReceiveTextActivity instance;
    private String channel_d;
    SMSUpdateManager smsUpdateManager;

    private static Map pendingShortcutMessage;
    static {
        SystemDispatcher.addListener(new SystemDispatcher.Listener() {

            public void onDispatched(String type, Map dmessage) {
                if (type.equals(CHECK_SHORTCUT)) {
                    Runnable runnable = new Runnable () {
                        public void run() {
                            if (pendingShortcutMessage != null) {
                                SystemDispatcher.dispatch(GOT_SHORTCUT, pendingShortcutMessage);
                                pendingShortcutMessage = null;
                            }
                        }
                    };

                    Thread thread = new Thread(runnable);
                    thread.start();
                }
            }
        });
    }

    @Override
    public void onCreate (Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        Log.d(TAG, "onCreated() called");

        // Workaround for blank activity
        // https://forum.qt.io/topic/90189/android-e-qt-java-surface-1-not-found/2
        if (instance != null) {
            Log.d(TAG, "App is already running... this won't work");
            Intent mStartActivity = new Intent(this, ReceiveTextActivity.class);
            if (getIntent().hasExtra(LauncherApps.EXTRA_PIN_ITEM_REQUEST)) {
                mStartActivity.putExtra(LauncherApps.EXTRA_PIN_ITEM_REQUEST,
                    (LauncherApps.PinItemRequest)getIntent().getParcelableExtra(LauncherApps.EXTRA_PIN_ITEM_REQUEST));
                mStartActivity.setAction(LauncherApps.ACTION_CONFIRM_PIN_SHORTCUT);
            }
            int mPendingIntentId = 123456;
            PendingIntent mPendingIntent = PendingIntent.getActivity(
                this, mPendingIntentId, mStartActivity, PendingIntent.FLAG_CANCEL_CURRENT);
            AlarmManager mgr = (AlarmManager)getSystemService(Context.ALARM_SERVICE);
            mgr.set(AlarmManager.RTC, System.currentTimeMillis() + 100, mPendingIntent);
            System.exit(0);
        } else if (getIntent().hasExtra(LauncherApps.EXTRA_PIN_ITEM_REQUEST)) {
            LauncherApps.PinItemRequest pinItemRequest = getIntent().getParcelableExtra(LauncherApps.EXTRA_PIN_ITEM_REQUEST);
            if (pinItemRequest.getRequestType() == PinItemRequest.REQUEST_TYPE_SHORTCUT) {
                boolean success = pinItemRequest.accept();
                Log.d(TAG, "Shortcut is accepted: " + success);
                ShortcutInfo shortcutInfo = pinItemRequest.getShortcutInfo();

                Log.d(TAG, "New shortcut: " + shortcutInfo.getId());
                LauncherApps launcher = (LauncherApps) getSystemService(Context.LAUNCHER_APPS_SERVICE);
                Drawable shortcutIcon = launcher.getShortcutIconDrawable(shortcutInfo,0);

                Map reply = new HashMap();
                reply.put("shortcutId", shortcutInfo.getId() );
                reply.put("package", shortcutInfo.getPackage() );
                reply.put("label", shortcutInfo.getShortLabel().toString() );
                reply.put("icon", drawableToBase64(shortcutIcon) );

                pendingShortcutMessage = reply;
            } else {
                Log.w(TAG, "Not valid pin item request");
            }
        }

        instance = this;

        Window window = getWindow();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setNavigationBarColor(Color.TRANSPARENT);
            window.setStatusBarColor(Color.TRANSPARENT ) ;
            window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
            window.setDecorFitsSystemWindows(false);
            window.setStatusBarContrastEnforced(false);
            window.setNavigationBarContrastEnforced(false);
        } else {
            window.setFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS, WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS);
            window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
        }

        notificationBroadcastReceiver = new NotificationBroadcastReceiver();
        IntentFilter intentFilter = new IntentFilter();
        intentFilter.addAction("com.volla.launcher.notification");
        registerReceiver(notificationBroadcastReceiver, intentFilter);
        NotificationPlugin.getInstance(ReceiveTextActivity.this).registerListener();
        Log.d(TAG, "Android activity created");
        handler = new Handler(Looper.getMainLooper());

        if (isTablet(this)) {
            Log.d(TAG, "Runnning on tablet");
            // Allow both portrait and landscape on tablets
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED);
        } else {
            Log.d(TAG, "Runnning on phone");
            // Force portrait mode on phones
            setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
        }
    }

    private boolean isTablet(Context context) {
        Log.d(TAG, "isTablet() called");
        return (ReceiveTextActivity.this.getResources().getConfiguration().screenLayout
                & Configuration.SCREENLAYOUT_SIZE_MASK)
                >= Configuration.SCREENLAYOUT_SIZE_LARGE;
    }

public void connectSmsUpdateManager(Context ctx, List<String> smsItems) {
    this.smsPid = smsItems;
    smsUpdateManager = new SMSUpdateManager(ctx, this);
    smsUpdateManager.start();
    }

@Override
   public void onServiceConnected() {
       if(smsPid != null && smsPid.size() > 0){
           Log.d(TAG, "SMS database update called ");
           int item = smsUpdateManager.smsUpdate(smsPid);
           Log.d(TAG, "SMS database updated "+ item + "for sms id "+smsPid);
        }

        Log.d(TAG, "SMS database updated ");
   }

   @Override
   public void onServiceDisconnected() {

   }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        unregisterReceiver(notificationBroadcastReceiver);
    }

    @Override
    public void onNewIntent(Intent intent) {
        Log.d(TAG, "onNewIntend() called");

        super.onNewIntent(intent);

        String action = intent.getAction();
        String type = intent.getType();

        Log.d(TAG, "Intend: " + intent + ", Action: " + action + ", type: " + type);

        if (Intent.ACTION_SEND.equals(action) && type != null && "text/plain".equals(type)) {
            String sharedText = intent.getStringExtra(Intent.EXTRA_TEXT);
            if (sharedText != null) {
                Map reply = new HashMap();
                reply.put("sharedText", sharedText );
                SystemDispatcher.dispatch(GOT_TEXT, reply);
            }
            Log.d(TAG, "Shared text: " +  sharedText);
        } else if (LauncherApps.ACTION_CONFIRM_PIN_SHORTCUT.equals(action)) {
            LauncherApps.PinItemRequest pinItemRequest = intent.getParcelableExtra(LauncherApps.EXTRA_PIN_ITEM_REQUEST);
            if (pinItemRequest.getRequestType() == PinItemRequest.REQUEST_TYPE_SHORTCUT) {
                Log.d(TAG, "Will accept shortcut");
                boolean success = pinItemRequest.accept();
                Log.d(TAG, "Shortcut is accepted: " + success);
                ShortcutInfo shortcutInfo = pinItemRequest.getShortcutInfo();

                Log.d(TAG, "New shortcut: " + shortcutInfo.getId());
                LauncherApps launcher = (LauncherApps) getSystemService(Context.LAUNCHER_APPS_SERVICE);
                Drawable shortcutIcon = launcher.getShortcutIconDrawable(shortcutInfo,0);

                Map reply = new HashMap();
                reply.put("shortcutId", shortcutInfo.getId() );
                reply.put("package", shortcutInfo.getPackage() );
                reply.put("label", shortcutInfo.getShortLabel().toString() );
                reply.put("icon", drawableToBase64(shortcutIcon) );

                pendingShortcutMessage = reply;
            } else {
                Log.w(TAG, "Not valid pin item request");
            }
        }
    }

    @Override
    public void onResume() {
        super.onResume();
        Log.d(TAG, "On Resume called");
	NotificationPlugin.getInstance(ReceiveTextActivity.this).registerListener();
        // todo: Adopt ui mode
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String permissions[], int[] grantResults) {
        Log.d(TAG, "Received permission result " + grantResults[0] + " for permission " + String.join(",", permissions));
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == 2) {
            // TODO: Re-check statistic permission
            Log.d(TAG, "Result for permission request: " + resultCode);
        }
    }

    @Override
    public void onConfigurationChanged(Configuration newConfig) {
        super.onConfigurationChanged(newConfig);

        Log.d(TAG, "Config changed");

        int currentNightMode = newConfig.uiMode & Configuration.UI_MODE_NIGHT_MASK;
        Map message = new HashMap();
        switch (currentNightMode) {
            case Configuration.UI_MODE_NIGHT_NO:
                // Night mode is not active, we're using the light theme
                Log.d(TAG, "Night mode enabled");
                message.put("uiMode", 0 );
                SystemDispatcher.dispatch(UIMODE_CHANGED, message);
                break;
            case Configuration.UI_MODE_NIGHT_YES:
                // Night mode is active, we're using dark theme
                Log.d(TAG, "Light mode enabled");
                message.put("uiMode", 1 );
                SystemDispatcher.dispatch(UIMODE_CHANGED, message);
                break;
        }
    }

    @Override
    public void onBackPressed() {
        Log.d(TAG, "Prevent closing app");
    }

    private String drawableToBase64 (Drawable drawable) {
         Bitmap bitmap = null;

         if (drawable instanceof BitmapDrawable) {
             BitmapDrawable bitmapDrawable = (BitmapDrawable) drawable;
             if(bitmapDrawable.getBitmap() != null) {
                 bitmap = bitmapDrawable.getBitmap();
             }
         } else {
             if (drawable.getIntrinsicWidth() <= 0 || drawable.getIntrinsicHeight() <= 0) {
                 bitmap = Bitmap.createBitmap(1, 1, Bitmap.Config.ARGB_8888); // Single color bitmap will be created of 1x1 pixel
             } else {
                 bitmap = Bitmap.createBitmap(drawable.getIntrinsicWidth(), drawable.getIntrinsicHeight(), Bitmap.Config.ARGB_8888);
             }

             Canvas canvas = new Canvas(bitmap);
             drawable.setBounds(0, 0, canvas.getWidth(), canvas.getHeight());
             drawable.draw(canvas);
         }

         ByteArrayOutputStream baos = new ByteArrayOutputStream();
         bitmap.compress(Bitmap.CompressFormat.PNG, 100, baos);
         byte[] imageBytes = baos.toByteArray();
         return Base64.encodeToString(imageBytes, Base64.NO_WRAP);
    }

    private void createNotification(Intent intent){
        Log.d("Arvindvolla", "Creating Notification");
        Bitmap largeIcon = null;
        byte [] bitMapByte = intent.getByteArrayExtra("largeIcon");
        if(bitMapByte != null){
          largeIcon = BitmapFactory.decodeByteArray(bitMapByte, 0,bitMapByte.length);
        }
        NotificationManager notificationManager = (NotificationManager)
                this.getSystemService(Context.NOTIFICATION_SERVICE);
        Notification notification = new NotificationCompat.Builder(this,channel_d)
                .setSmallIcon(R.drawable.icon)
                .setAutoCancel(true)
                .setContentTitle(intent.getStringExtra("title"))
                .setContentText(intent.getStringExtra("body"))
                .setLargeIcon(largeIcon)
                .setDefaults(Notification.DEFAULT_LIGHTS| Notification.DEFAULT_SOUND)
                .setTicker("Message")
                .setPriority(Notification.PRIORITY_HIGH)
                .build();
        notificationManager.notify("VollaOS", 1, notification);
    }


    public class NotificationBroadcastReceiver extends BroadcastReceiver {
        @Override
        public void onReceive(Context context, Intent intent) {
            Log.d("Arvindvolla", "Received Notification Broadcast");
            int receivedNotificationCode = intent.getIntExtra("Notification Code",-1);
             channel_d = intent.getStringExtra("channel_d");
    /*
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
               NotificationChannel channel = new NotificationChannel(channel_d,"VollaLauncher",
                        NotificationManager.IMPORTANCE_HIGH);
                NotificationManager manager = (NotificationManager)
                        context.getSystemService(Context.NOTIFICATION_SERVICE);
                if(manager != null){
                    manager.createNotificationChannel(channel);
                }

            } */
            createNotification(intent);
        }
    }
}
