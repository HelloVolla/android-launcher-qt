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

public class SignalUtil {

    private static final String TAG = "SignalUtil";

    public static final String SEND_SIGNAL_MESSAGES = "volla.launcher.signalSendMessageAction";
    public static final String DID_SEND_SIGNAL_MESSAGES = "volla.launcher.signalSendMessagesResponse";
    public final static String PACKET_TYPE_NOTIFICATION_REQUEST = "volla.notification.request";
    public final static String PACKET_TYPE_NOTIFICATION_REPLY = "volla.notification.reply";
    public final static String PACKET_TYPE_NOTIFICATION_ACTION = "volla.notification.action";
    public final static String PACKET_TYPE_NOTIFICATION = "volla.notification";
    public final static String SEND_SIGNAL_ATTACHMENT = "volla.notification.attachment";
    //public static NotificationPlugin np;
    static {
        SystemDispatcher.addListener(new SystemDispatcher.Listener() {

            public void onDispatched(String type, Map dmessage) {
                final Activity activity = QtNative.activity();
                final Map message = dmessage;

                if (type.equals(SEND_SIGNAL_MESSAGES)) {
                    // todo: implement (use a separate thread)
		    Runnable runnable = new Runnable () {
                        public void run() {
                           if(!isInternetAccessible(activity)){
                              errorMessageReply("No Internet Access"); 
			   } else {
                              sendSignalmessage(message);
			   }
                        }
                    };
                    Thread thread = new Thread(runnable);
                    thread.start();
                } else if(type.equals(SEND_SIGNAL_ATTACHMENT)){
                   launchComponent(activity,"org.thoughtcrime.securesms","org.thoughtcrime.securesms.RoutingActivity");
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
        //np = new NotificationPlugin();
        NotificationPlugin.getInstance(QtNative.activity()).replyToNotification(person,thread_id,text);
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
    private static void launchComponent(Activity act,String packageName, String name)
    {
        Intent intent = new Intent("android.intent.action.MAIN");
        intent.addCategory("android.intent.category.LAUNCHER");
        intent.setComponent(new ComponentName(packageName, name));
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        act.startActivity(intent);
    }
}
