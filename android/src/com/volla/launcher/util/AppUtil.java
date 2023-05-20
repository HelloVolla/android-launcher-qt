package com.volla.launcher.util;

import androidnative.SystemDispatcher;
import android.app.Activity;
import android.app.ActivityManager;
import android.app.AlarmManager;
import android.app.PendingIntent;
import android.util.Log;
import android.content.pm.PackageManager;
import android.content.pm.ApplicationInfo;
import android.content.pm.ResolveInfo;
import android.content.pm.PackageInfo;
import android.content.Intent;
import android.content.ComponentName;
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
import lineageos.childmode.ChildModeManager;
import com.volla.launcher.activity.ReceiveTextActivity;

public class AppUtil {

    private static final String TAG = "AppUtil";

    public static final String GET_APP_COUNT = "volla.launcher.appCountAction";
    public static final String GOT_APP_COUNT = "volla.launcher.appCountResponse";
    public static final String OPEN_CAM = "volla.launcher.camAction";
    public static final String OPEN_DIALER = "volla.launcher.dialerAction";    
    public static final String RUN_APP = "volla.launcher.runAppAction";
    public static final String OPEN_NOTES = "volla.launcher.notesAction";
    public static final String OPEN_CONTACT = "volla.launcher.showContactAction";
    public static final String RESET_LAUNCHER = "volla.launcher.resetAction";
    public static final String TOGGLE_SECURITY_MODE = "volla.launcher.securityModeAction";
    public static final String SECURITY_MODE_RESULT = "volla.launcher.securityModeResponse";
    public static final String GET_SECURITY_STATE = "volla.launcher.securityStateAction";
    public static final String GOT_SECURITY_STATE = "volla.launcher.securityStateResponse";
    public static final String GET_IS_SECURITY_PW_SET = "volla.launcher.checkSecurityPasswordAction";
    public static final String GOT_IS_SECURITY_PW_SET = "volla.launcher.checkSecurityPasswordResponse";

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
                            String packageName = (String) message.get("appId");
                            try {
                                Intent app = pm.getLaunchIntentForPackage(packageName);
                                activity.startActivity(app);
                            } catch (SecurityException e){
                                PackageInfo pi;
                                try {
                                    pi = activity.getPackageManager().getPackageInfo(packageName, 0);
                                    Intent resolveIntent = new Intent(Intent.ACTION_MAIN, null);
                                    resolveIntent.setPackage(pi.packageName);
                                    List<ResolveInfo> apps = pm.queryIntentActivities(resolveIntent, 0);
                                    for (ResolveInfo app: apps){
                                        Log.d(TAG,String.format("%s %s",app.activityInfo.packageName,app.activityInfo.name));
                                        packageName = app.activityInfo.packageName;
                                        String className = app.activityInfo.name;
                                        Intent intent = new Intent(Intent.ACTION_MAIN);
                                        intent.addCategory(Intent.CATEGORY_LAUNCHER);
                                        ComponentName cn = new ComponentName(packageName, className);
                                        intent.setComponent(cn);
                                        try {
                                            activity.startActivity(intent);
                                        } catch (SecurityException se){
                                            Log.e(TAG, "Security exception: " + se.getMessage());
                                        }
                                    }
                                } catch (PackageManager.NameNotFoundException nnfe) {
                                    Log.e(TAG, "Package Name not found: " + nnfe.getMessage() + ", App is not installed.");
                                }
                            }
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

                            TelecomManager manager = (TelecomManager) activity.getSystemService(Context.TELECOM_SERVICE);
                            app = manager.getDefaultDialerPackage();

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
                        } else if (type.equals(RESET_LAUNCHER)) {
                            // https://stackoverflow.com/questions/4856955/how-to-programmatically-clear-application-data

                            Log.d(TAG, "Will restart launcher");
                            Intent mStartActivity = new Intent(activity, ReceiveTextActivity.class);
                            int mPendingIntentId = 234567;
                            PendingIntent mPendingIntent = PendingIntent.getActivity(
                                activity, mPendingIntentId, mStartActivity, PendingIntent.FLAG_CANCEL_CURRENT);
                            AlarmManager mgr = (AlarmManager)activity.getSystemService(Context.ALARM_SERVICE);
                            mgr.set(AlarmManager.RTC, System.currentTimeMillis() + 500, mPendingIntent);
                            Log.d(TAG, "Will reset launcher");
                            ((ActivityManager) activity.getSystemService(Context.ACTIVITY_SERVICE)).clearApplicationUserData();
                        } else if (type.equals(TOGGLE_SECURITY_MODE)) {
                            boolean activate = (boolean) message.get("activate");
                            boolean keepPassword = (boolean) message.get("keepPassword");

                            ChildModeManager childModeManager = ChildModeManager.getInstance(activity);
                            Map reply = new HashMap();

                            if (activate) {
                                if (!childModeManager.isPasswortSet() || !keepPassword) {
                                    String password = (String) message.get("password");
                                    childModeManager.setPassword(password);
                                }
                                childModeManager.activate(activate);
                                reply.put("succeeded", true);
                                reply.put("activate", activate);
                            } else {
                                String password = (String) message.get("password");
                                if (childModeManager.validatePassword(password)) {
                                    childModeManager.activate(activate);
                                    reply.put("succeeded", true );
                                    reply.put("activate", activate );
                                } else {
                                    reply.put("succeeded", false );
                                    reply.put("error", "Wrong password" );
                                }
                            }

                            SystemDispatcher.dispatch(SECURITY_MODE_RESULT, reply);
                        } else if (type.equals(GET_SECURITY_STATE)) {
                            try {
                                Intent childModeSettings = pm.getLaunchIntentForPackage("com.volla.childmodesettings");
                                boolean available = true;
                                try {
                                    // check if available
                                    pm.getPackageInfo("com.volla.childmodesettings", 0);
                                } catch (PackageManager.NameNotFoundException e) {
                                    // if not available set available as false
                                    available = false;
                                }
                                ChildModeManager childModeManager = ChildModeManager.getInstance(activity);
                                Map reply = new HashMap();
                                reply.put("isActive", childModeManager.isActivate() );
                                reply.put("isInstalled", available);
                                SystemDispatcher.dispatch(GOT_SECURITY_STATE, reply);
                            } catch (Exception e) {
                                Map reply = new HashMap();
                                reply.put("isActive", "false" );
                                reply.put("error", "Not installed" );
                                Log.d(TAG, e.toString());
                                SystemDispatcher.dispatch(GOT_SECURITY_STATE, reply);
                            }
                        } else if (type.equals(GET_IS_SECURITY_PW_SET)) {
                            ChildModeManager childModeManager = ChildModeManager.getInstance(activity);

                            Map reply = new HashMap();
                            reply.put("isPasswordSet", childModeManager.isPasswortSet() );
                            SystemDispatcher.dispatch(GOT_IS_SECURITY_PW_SET, reply);
                        }
                    }
                };

                Thread thread = new Thread(runnable);
                thread.start();
            }
        });
    }
}
