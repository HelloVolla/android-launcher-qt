package com.volla.launcher.util;

import androidnative.SystemDispatcher;
import android.Manifest;
import android.os.Build;
import android.app.Activity;
import android.app.PendingIntent;
import android.util.Log;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.BroadcastReceiver;
import android.content.pm.PackageManager;
import android.telephony.gsm.SmsManager;
import android.widget.Toast;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.net.Uri;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;
import java.io.InputStream;
import java.io.IOException;
import java.net.URL;
import java.net.MalformedURLException;
import org.qtproject.qt5.android.QtNative;
import com.klinker.android.send_message.Settings;
import com.klinker.android.send_message.Transaction;
import com.klinker.android.send_message.Message;
import com.klinker.android.send_message.Utils;
import com.volla.launcher.util.MMSManager;

public class MessageUtil {

    private static final String TAG = "MessageUtil";

    public static final String SEND_SIGNAL_MESSAGE = "volla.launcher.signalIntentAction";
    public static final String DID_SENT_SIGNAL_MESSAGE = "volla.launcher.signalIntentResponse";

    public static final String SEND_MESSAGE = "volla.launcher.messageAction";
    public static final String DID_SENT_MESSAGE = "volla.launcher.messageResponse";

    private static final String SMS_SEND_ACTION = "CTS_SMS_SEND_ACTION";
    private static final String SMS_DELIVERY_ACTION = "CTS_SMS_DELIVERY_ACTION";
    public static final int PERMISSIONS_REQUEST_SEND_SMS = 123;

    static {
        SystemDispatcher.addListener(new SystemDispatcher.Listener() {

            public void onDispatched(String type, Map message) {
                final Activity activity = QtNative.activity();

                if (type.equals(SEND_MESSAGE)) {

                    final String number = (String) message.get("number");
                    final String text = (String) message.get("text");
                    final String attachmentUrl = (String) message.get("attachmentUrl");

                    Runnable runnable = new Runnable () {

                        public void run() {
                            if (activity.checkSelfPermission(Manifest.permission.SEND_SMS) == PackageManager.PERMISSION_GRANTED) {

                                //========= Exprimental ================

                                if (attachmentUrl != null && attachmentUrl.length() > 0) {

                                    Log.d(TAG, "Will send MMS to " + number);
                                    Log.d(TAG, "Build: " + getSystemProperty("ro.lineage.build.version"));

                                    if (getSystemProperty("ro.lineage.build.version").equals("10")) {
                                        Uri uri = Uri.parse(attachmentUrl);
                                        Intent intent = new Intent(Intent.ACTION_SENDTO);
                                        intent.setData(Uri.parse("smsto:" + number));
                                        intent.putExtra("sms_body", text);
                                        intent.putExtra(Intent.EXTRA_STREAM, uri);
                                        intent.setType("image/*");
                                        if (intent.resolveActivity(activity.getPackageManager()) != null) {
                                            activity.startActivity(intent);
                                        }

                                        return;
                                    }

                                    MMSManager mmsm = MMSManager.getInstance(activity);

                                    Message message = new Message(text, "01772448379");
                                    message.setFromAddress(Utils.getMyPhoneNumber(activity));
                                    message.setSave(false);
                                    Uri uri = Uri.parse("content://mms-sms/conversations/");
                                    message.setMessageUri(uri);
                                    try {
                                        InputStream input = new URL(attachmentUrl).openStream();
                                        Bitmap bitmap = BitmapFactory.decodeStream(input);
                                        Log.d(TAG, "Bitmap: " + bitmap.getHeight() + ", " + bitmap.getWidth());

                                        int bytes = bitmap.getAllocationByteCount();
                                        Log.d(TAG, "Bitmap: " + (bytes / 1024) );

                                        int maxHeight = 640;
                                        int maxWidth = 640;

                                        if (bitmap.getHeight() > maxHeight || bitmap.getWidth() > maxWidth) {
                                            float scale = Math.min(((float)maxHeight / bitmap.getWidth()), ((float)maxWidth / bitmap.getHeight()));

                                            Matrix matrix = new Matrix();
                                            matrix.postScale(scale, scale);

                                            bitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), matrix, true);
                                            bytes = bitmap.getAllocationByteCount();

                                            Log.d(TAG, "Scaled Bitmap: " + (bytes / 1024) );
                                        }

                                        message.setImage(bitmap);
                                        mmsm.sendMMS(number, text, bitmap);
                                    } catch (MalformedURLException ue) {
                                        Log.e(TAG, ue.getMessage());
                                    } catch (IOException ioe) {
                                        Log.e(TAG, ioe.getMessage());
                                    }
                                }

                                // =====================================

                                else if (text == null || text.length() < 1) {
                                    Map responseMessage = new HashMap();
                                    responseMessage.put("sent", false);
                                    responseMessage.put("text", "MissingText");
                                    SystemDispatcher.dispatch(DID_SENT_MESSAGE, responseMessage);
                                } else {
                                    SmsManager sm = SmsManager.getDefault();

                                    IntentFilter sendIntentFilter = new IntentFilter(SMS_SEND_ACTION);
                                    IntentFilter receiveIntentFilter = new IntentFilter(SMS_DELIVERY_ACTION);

                                    PendingIntent sentPI = PendingIntent.getBroadcast(activity.getApplicationContext(),0,new Intent(SMS_SEND_ACTION), 0);
                                    PendingIntent deliveredPI = PendingIntent.getBroadcast(activity.getApplicationContext(),0,new Intent(SMS_DELIVERY_ACTION), 0);

                                    BroadcastReceiver messageSentReceiver = new BroadcastReceiver()
                                    {
                                        @Override
                                        public void onReceive(Context context, Intent intent)
                                        {
                                            Map responseMessage = new HashMap();

                                            switch (getResultCode())
                                            {
                                                case Activity.RESULT_OK:
                                                    responseMessage.put("sent", true);
                                                    responseMessage.put("text", "MessageSent");
                                                    break;
                                                case SmsManager.RESULT_ERROR_GENERIC_FAILURE:
                                                    responseMessage.put("sent", false);
                                                    responseMessage.put("text", "GenericFailure");
                                                    break;
                                                case SmsManager.RESULT_ERROR_NO_SERVICE:
                                                    responseMessage.put("sent", false);
                                                    responseMessage.put("text", "NoService");
                                                    break;
                                                case SmsManager.RESULT_ERROR_NULL_PDU:
                                                    responseMessage.put("sent", false);
                                                    responseMessage.put("text", "NullPdu");
                                                    break;
                                                case SmsManager.RESULT_ERROR_RADIO_OFF:
                                                    responseMessage.put("sent", false);
                                                    responseMessage.put("text", "RadioOff");
                                                    break;
                                            }

                                            SystemDispatcher.dispatch(DID_SENT_MESSAGE, responseMessage);
                                        }
                                    };

                                    activity.registerReceiver(messageSentReceiver, sendIntentFilter);

                                    BroadcastReceiver messageReceiveReceiver = new BroadcastReceiver()
                                    {
                                        @Override
                                        public void onReceive(Context arg0, Intent arg1)
                                        {
                                            Map responseMessage = new HashMap();

                                            switch (getResultCode())
                                            {
                                                case Activity.RESULT_OK:
                                                    responseMessage.put("sent", true);
                                                    responseMessage.put("text", "MessageDelivered");
                                                    break;
                                                case Activity.RESULT_CANCELED:
                                                    responseMessage.put("sent", false);
                                                    responseMessage.put("text", "MessageNotDelivered");
                                                break;
                                            }

                                            SystemDispatcher.dispatch(DID_SENT_MESSAGE, responseMessage);

                                        }
                                    };

                                    activity.registerReceiver(messageReceiveReceiver, receiveIntentFilter);

                                    ArrayList<String> parts =sm.divideMessage(text);

                                    ArrayList<PendingIntent> sentIntents = new ArrayList<PendingIntent>();
                                    ArrayList<PendingIntent> deliveryIntents = new ArrayList<PendingIntent>();

                                    for (int i = 0; i < parts.size(); i++)
                                    {
                                        sentIntents.add(PendingIntent.getBroadcast(activity.getApplicationContext(), 0, new Intent(SMS_SEND_ACTION), 0));
                                        deliveryIntents.add(PendingIntent.getBroadcast(activity.getApplicationContext(), 0, new Intent(SMS_DELIVERY_ACTION), 0));
                                    }

                                    sm.sendMultipartTextMessage(number,null, parts, sentIntents, deliveryIntents);
                                }
                            } else {
                                activity.requestPermissions(new String[] { Manifest.permission.SEND_SMS },
                                                            PERMISSIONS_REQUEST_SEND_SMS);
                            }
                        }
                    };

                    Thread thread = new Thread(runnable);
                    thread.start();
                } else if (type.equals(SEND_SIGNAL_MESSAGE)) {

                    final String number = (String) message.get("number");
                    final String text = (String) message.get("text");

                    Runnable runnable = new Runnable () {

                        public void run() {

                            Log.d(TAG, "Will send Signal message to " + number);

                            Intent intent = new Intent(Intent.ACTION_SENDTO);
                            intent.setPackage("org.thoughtcrime.securesms");
                            intent.setData(Uri.parse("smsto:" + number));
                            intent.putExtra("sms_body", text);
                            if (intent.resolveActivity(activity.getPackageManager()) != null) {
                                activity.startActivity(intent);
                            }
                        }
                    };

                    Thread thread = new Thread(runnable);
                    thread.start();
                }
            }
        });
    }

    static String getSystemProperty(String key) {
        String value = null;

        try {
            value = (String) Class.forName("android.os.SystemProperties")
                    .getMethod("get", String.class).invoke(null, key);
        } catch (Exception e) {
          e.printStackTrace();
        }

        return value;
    }
}
