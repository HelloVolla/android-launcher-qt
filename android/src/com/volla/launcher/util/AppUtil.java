package com.volla.launcher.util;

import androidnative.SystemDispatcher;
import android.app.Activity;
import android.util.Log;
import android.content.pm.PackageManager;
import android.content.pm.ApplicationInfo;
import android.content.pm.ResolveInfo;
import android.content.Intent;
import android.provider.ContactsContract;
import android.provider.ContactsContract.Contacts;
import android.provider.MediaStore;
import android.provider.CallLog;
import android.telecom.TelecomManager;
import android.content.Context;
import android.net.Uri;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import org.qtproject.qt5.android.QtNative;

public class AppUtil {

    private static final String TAG = "AppUtil";

    public static final String GET_APP_COUNT = "volla.launcher.appCountAction";
    public static final String GOT_APP_COUNT = "volla.launcher.appCountResponse";
    public static final String OPEN_CAM = "volla.launcher.camAction";
    public static final String OPEN_DIALER = "volla.launcher.dialerAction";    
    public static final String RUN_APP = "volla.launcher.runAppAction";
    public static final String OPEN_NOTES = "volla.launcher.notesAction";
    public static final String OPEN_CONTACT = "volla.launcher.showContactAction";

    static {
        SystemDispatcher.addListener(new SystemDispatcher.Listener() {

            public void onDispatched(String dtype, Map dmessage) {
                final Activity activity = QtNative.activity();
                final PackageManager pm = activity.getPackageManager();
                final Map message = dmessage;
                final String type = dtype;

                Runnable runnable = new Runnable () {

                    public void run() {
                        if (type.equals(GET_APP_COUNT)) {
                            Intent i = new Intent(Intent.ACTION_MAIN, null);
                            i.addCategory(Intent.CATEGORY_LAUNCHER);
                            List<ResolveInfo> availableActivities = pm.queryIntentActivities(i, 0);

                            Map responseMessage = new HashMap();
                            responseMessage.put("appCount", availableActivities.size());

                            SystemDispatcher.dispatch(GOT_APP_COUNT, responseMessage);
                        } else if (type.equals(OPEN_CAM)) {
                            Intent intent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
                            ResolveInfo cameraInfo  = null;
                            List<ResolveInfo> pkgList = pm.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY);

                            if (pkgList != null && pkgList.size() > 0) {
                                cameraInfo = pkgList.get(0);
                                Intent cameraApp = pm.getLaunchIntentForPackage(cameraInfo.activityInfo.packageName);
                                activity.startActivity(cameraApp);
                            } else {

                            }
                        } else if (type.equals(RUN_APP)) {
                            String appId = (String) message.get("appId");
                            Intent app = pm.getLaunchIntentForPackage(appId);
                            activity.startActivity(app);
                        } else if (type.equals(OPEN_NOTES)) {
                            String text = (String) message.get("text");
                            Intent sendIntent = new Intent();
                            sendIntent.setAction(Intent.ACTION_SEND);
                            sendIntent.putExtra(Intent.EXTRA_TEXT, text);
                            sendIntent.setType("text/plain");
                            sendIntent.setPackage("com.simplemobiletools.notes.pro");
                            activity.startActivity(sendIntent);
                        } else if (type.equals(OPEN_DIALER)) {
                            String app = (String) message.get("app");

//                            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q || app == null) {
                                TelecomManager manger = (TelecomManager) activity.getSystemService(Context.TELECOM_SERVICE);
                                app = manger.getDefaultDialerPackage();
//                            }

                            Log.d(TAG, "Dialer package is " + app);

                            Intent i;

                            String action = (String) message.get("action");
                            String number = (String) message.get("number");

                            if (action != null && action.equals("dial")) {                              
                                Log.d(TAG, "Will dial");
                                i = new Intent();
                                i.setPackage(app);
                                i.setAction(Intent.ACTION_DIAL);
                                if (number != null) {
                                    i.setData(Uri.parse("tel:" + number));
                                } else {
                                    i.setData(Uri.parse("tel:"));
                                }
                            } else if (action != null && action.equals("log")) {
                                i = new Intent();
                                i.setPackage(app);
                                i.setAction(Intent.ACTION_VIEW);
                                i.setType(CallLog.Calls.CONTENT_TYPE);
                            } else {
                                i = pm.getLaunchIntentForPackage(app);
                            }
                            activity.startActivity(i);
                        } else if (type.equals(OPEN_CONTACT)) {
                            Log.d(TAG, "Will open contact app");
                            String contact_id = (String) message.get("contact_id");
                            Intent i = new Intent(Intent.ACTION_VIEW);
                            Uri uri = Uri.withAppendedPath(ContactsContract.Contacts.CONTENT_URI, contact_id);
                            i.setData(uri);
                            activity.startActivity(i);
                        }
                    }
                };

                Thread thread = new Thread(runnable);
                thread.start();
            }
        });
    }
}
