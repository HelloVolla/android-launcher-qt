package com.volla.launcher.util;

import androidnative.SystemDispatcher;
import android.app.Activity;
import android.util.Log;
import java.util.Map;
import java.util.List;
import java.util.LinkedList;
import org.qtproject.qt5.android.QtNative;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import com.volla.launcher.util.NotificationPlugin;
import java.util.HashMap;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.content.Context;
import android.content.ComponentName;
import android.content.Intent;
import android.net.Uri;
import android.content.ClipData;
import java.io.File;
import com.volla.launcher.worker.SignalWorker;

import java.net.URL;
import android.media.MediaScannerConnection;

public class SignalUtil {

    private static final String TAG = "SignalUtil";

    public static final String SEND_SIGNAL_MESSAGES = "volla.launcher.signalSendMessageAction";
    public static final String DID_SEND_SIGNAL_MESSAGES = "volla.launcher.signalSendMessagesResponse";
    public final static String PACKET_TYPE_NOTIFICATION_REQUEST = "volla.notification.request";
    public final static String PACKET_TYPE_NOTIFICATION_REPLY = "volla.notification.reply";
    public final static String PACKET_TYPE_NOTIFICATION_ACTION = "volla.notification.action";
    public final static String PACKET_TYPE_NOTIFICATION = "volla.notification";

    static {
        SystemDispatcher.addListener(new SystemDispatcher.Listener() {

            public void onDispatched(String type, Map dmessage) {
                final Activity activity = QtNative.activity();
                final Map message = dmessage;

                if (type.equals(SEND_SIGNAL_MESSAGES)) {
		    Runnable runnable = new Runnable () {
                        public void run() {

                           if (message.get("attachmentUrl") != null && ((String)message.get("attachmentUrl")).length() > 0) {
                              launchShareActivity(activity, message);
                           } else if (message.get("number") != null) {
                              launchComponent(activity, message);
                           } else if (!isInternetAccessible(activity)){
                              errorMessageReply("No Internet Access");
			   } else {
                              sendSignalmessage(message);
			   }
                        }
                    };
                    Thread thread = new Thread(runnable);
                    thread.start();
                }
             }
        });
    }

    public static Bitmap drawableToBitmap (Drawable drawable) {
        if (drawable instanceof BitmapDrawable) {
            return ((BitmapDrawable)drawable).getBitmap();
        }

        Bitmap bitmap = Bitmap.createBitmap(drawable.getIntrinsicWidth(), drawable.getIntrinsicHeight(), Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);
        drawable.setBounds(0, 0, canvas.getWidth(), canvas.getHeight());
        drawable.draw(canvas);

        return bitmap;
    }

    public static void sendSignalmessage(Map message){ 
        String text = (String) message.get("text");
        String thread_id = (String) message.get("thread_id");
	String person = (String) message.get("person");
	String phone_number = (String) message.get("number");
        if(SignalWorker.isSignalInstalled(QtNative.activity())) {
            NotificationPlugin.getInstance(QtNative.activity()).replyToNotification(person,thread_id,text,phone_number);
        } else {
            Map result = new HashMap();
            result.put("error", "Signal Application not Installed");
            SystemDispatcher.dispatch(SignalWorker.SIGNAL_ERROR, result);
        }
    }

    public static void errorMessageReply(String msg){
         Map reply = new HashMap();
	 reply.put("isSent", false);
	 reply.put("message",msg);
	 Log.d(TAG, "Dispatch DID_SEND_SIGNAL_MESSAGES "+msg);
	 SystemDispatcher.dispatch(DID_SEND_SIGNAL_MESSAGES,reply);
    }

    public static boolean isInternetAccessible(Context ctx) {
        if (ctx == null)
            return false;

        ConnectivityManager cm =
                (ConnectivityManager) ctx.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo netInfo = cm.getActiveNetworkInfo();
        if (netInfo != null && netInfo.isConnectedOrConnecting()) {
            return true;
        }
        return false;
    }

    private static void launchComponent(Activity activity,Map message)
    {
        String packageName = "org.thoughtcrime.securesms";
        String phone_number = (String) message.get("number");
        String text = (String) message.get("text");
	Intent intent = new Intent();
        if (phone_number != null) {
            intent.setAction("android.intent.action.SENDTO");
            intent.setPackage("org.thoughtcrime.securesms");
            intent.setData(Uri.parse("smsto:" + phone_number));
            intent.putExtra("sms_body", text);
	} else {
            intent.setAction(Intent.ACTION_SEND);
            intent.setPackage(packageName);
            intent.putExtra(Intent.EXTRA_TEXT, text);
            intent.setType("text/plain");
        }
        if (intent.resolveActivity(activity.getPackageManager()) != null) {
            activity.startActivity(intent);
        }
    }
    
    private static void launchShareActivity(Activity activity, Map message){
        Log.d(TAG, "Will share text and url");

        String attachmentUrl = (String) message.get("attachmentUrl");
        String phone_number = (String) message.get("number"); // Can't be used for this intend
        String text = (String) message.get("text");

        Log.d(TAG, "Text: " + text);
        Log.d(TAG, "Attachment: " + attachmentUrl);

        URL url;

        try {
            url = new URL(attachmentUrl);

            MediaScannerConnection.scanFile(activity, new String[] { url.getPath() }, null, (path, uri) -> {
                String packageName = "org.thoughtcrime.securesms";

                Intent intent = new Intent();
                intent.setAction(Intent.ACTION_SEND);
                intent.setPackage(packageName);
                if (text != null) {
                    intent.putExtra(Intent.EXTRA_TITLE, text);
                }
                intent.putExtra(Intent.EXTRA_STREAM, uri);
                intent.setType("image/*");

                if (intent.resolveActivity(activity.getPackageManager()) != null) {
                    activity.startActivity(intent);
                } else {
                    Log.d(TAG, "Intent not found");
                }
            });
        } catch (Exception e) {
            Log.e(TAG, e.getMessage());
        }
    }
}
