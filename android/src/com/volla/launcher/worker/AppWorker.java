package com.volla.launcher.worker;

import android.app.Activity;
import android.app.usage.UsageStatsManager;
import android.app.usage.UsageStats;
import android.app.AppOpsManager;
import android.provider.Settings;
import android.os.Bundle;
import android.content.pm.PackageManager;
import android.content.pm.ApplicationInfo;
import android.content.pm.ResolveInfo;
import android.content.Intent;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.BitmapDrawable;
import android.util.Log;
import android.util.Base64;
import java.util.Map;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.GregorianCalendar;
import java.io.ByteArrayOutputStream;
import org.qtproject.qt5.android.QtNative;
import androidnative.SystemDispatcher;
import com.volla.launcher.storage.NotificationStorageManager;

public class AppWorker
{
    private static final String TAG = "AppWorker";

    public static final String GET_APPS = "volla.launcher.appAction";
    public static final String GOT_APPS = "volla.launcher.appResponse";
    public static final String GET_Notification = "volla.launcher.otherAppNotificationAction";
    public static final String GOT_Notification = "volla.launcher.otherAppNotificationResponce";
    public static final String CLEAR_RED_DOT = "volla.launcher.clearRedDot";

    static {
        SystemDispatcher.addListener(new SystemDispatcher.Listener() {

            final Activity activity = QtNative.activity();

            public void onDispatched(String type, Map message) {
                if (type.equals(GET_APPS)) {
                    Log.d(TAG, "Get apps action called");

                    Runnable runnable = new Runnable () {

                        public void run() {
                            ArrayList<Map> appList = new ArrayList();

                            final PackageManager pm = activity.getPackageManager();
                            final List<String> packages = Arrays.asList("com.android.browser",
                                "com.android.gallery3d", "com.android.music", "com.android.inputmethod.latin", "com.android.stk",
                                "com.mediatek.filemanager", "com.android.calendar", "com.android.documentsui", "com.google.android.gms",
                                "com.mediatek.cellbroadcastreceiver", "com.conena.navigation.gesture.control", "rkr.simplekeyboard.inputmethod",
                                "com.android.quicksearchbox", "org.fossify.phone", "com.android.deskclock", "com.pri.pressure",
                                "com.mediatek.gnss.nonframeworklbs", "system.volla.startup", "com.volla.startup", "com.aurora.services",
                                "com.android.soundrecorder", "com.google.android.dialer", "com.simplemobiletools.thankyou",
                                "com.elishaazaria.sayboard", "com.jzhk.chlidmode", "com.jzhk.gamemode", "com.jzhk.tool",
                                "com.google.android.apps.adm", "com.android.soundrecorder", "com.jzhk.easylauncher", "com.simplemobiletools.dialer");

                            final List<String> mostUsed = Arrays.asList("com.android.dialer", "com.mediatek.camera",
                                "com.simplemobiletools.dialer", "com.simplemobiletools.gallery.pro", "com.android.messaging",
                                "org.mozilla.fennec_fdroid", "com.simplemobiletools.gallery.pro", "com.simplemobiletools.calendar.pro");

                            List<UsageStats> queryUsageStats = new LinkedList();

                            if (checkUsagePermission(activity)) {
                                long startTime = System.currentTimeMillis() - (7 * 86400000);
                                long endTime = System.currentTimeMillis();

                                UsageStatsManager usageStatsManager = (UsageStatsManager)activity.getSystemService(Context.USAGE_STATS_SERVICE);
                                queryUsageStats = usageStatsManager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime);

                                Log.d(TAG, "Usage stats entries: " + queryUsageStats.size());
                            }

                            Intent i = new Intent(Intent.ACTION_MAIN, null);
                            i.addCategory(Intent.CATEGORY_LAUNCHER);
                            List<ResolveInfo> availableActivities = pm.queryIntentActivities(i, 0);
                            appList.ensureCapacity(availableActivities.size());

                            for (ResolveInfo ri:availableActivities) {
                                Log.d(TAG, "Found package " + ri.activityInfo.packageName);

                                if (!packages.contains(ri.activityInfo.packageName)) {
                                    Map appInfo = new HashMap();
                                    appInfo.put("package", ri.activityInfo.packageName);
                                    appInfo.put("label", String.valueOf(ri.loadLabel(pm)));
                                    appInfo.put("icon", AppWorker.drawableToBase64(ri.loadIcon(pm)));

                                    try {
                                        ApplicationInfo applicationInfo = pm.getApplicationInfo(ri.activityInfo.packageName, 0);
                                        int appCategory = applicationInfo.category;
                                        if (appCategory > -1) {
                                            appInfo.put("category", (String) ApplicationInfo.getCategoryTitle(activity, appCategory));
                                        } else {
                                            appInfo.put("category", "");
                                        }
                                    } catch (Exception e) {
                                        Log.w(TAG, "Unknown package name: " + e.toString());
                                    }

                                    long timeInForeground = 0;

                                    for (UsageStats us : queryUsageStats) {
                                        if (us.getPackageName().equalsIgnoreCase(ri.activityInfo.packageName)) {
                                            timeInForeground = us.getTotalTimeInForeground();
                                            break;
                                        }
                                    }
                                    if (mostUsed.contains(ri.activityInfo.packageName)) {
                                        timeInForeground = timeInForeground + 10; // fall back for missing stats
                                    }

                                    appInfo.put("statistic", (int)timeInForeground);
                                    appList.add(appInfo);
                                }
                            }

                            Map reply = new HashMap();
                            reply.put("apps", appList );
                            reply.put("appsCount", appList.size() );
                            SystemDispatcher.dispatch(GOT_APPS,reply);
                        }
                    };

                    Thread thread = new Thread(runnable);
                    thread.start();
                } else if(type.equals(GET_Notification)) {
                  NotificationStorageManager storageManager = new NotificationStorageManager(activity);
                  Map<String, Integer> allCounts = storageManager.getAllNotificationCounts();
                  Map<String, Map> reply = new HashMap<String, Map>();
                  reply.put("Notification", allCounts );
                  SystemDispatcher.dispatch(GOT_Notification,reply);
                } else if (type.equals(CLEAR_RED_DOT)) {
                     NotificationStorageManager storageManager = new NotificationStorageManager(activity);
                     storageManager.clearNotificationCount((String) message.get("package"));
                }
            }
        });
    }

    public static boolean checkUsagePermission(Activity activity) {
        AppOpsManager appOps = (AppOpsManager)activity.getSystemService(Context.APP_OPS_SERVICE);
        int mode = appOps.checkOpNoThrow("android:get_usage_stats", android.os.Process.myUid(), activity.getPackageName());
        boolean granted;
        if (mode == AppOpsManager.MODE_DEFAULT) {
            Log.d(TAG, "App usage statistic access in default mode");
            granted = (activity.checkCallingOrSelfPermission(android.Manifest.permission.PACKAGE_USAGE_STATS) == PackageManager.PERMISSION_GRANTED);
            if (!granted) {
                Log.w(TAG, "App usage statistic access is not granted");
                Intent intent = new Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS);
                activity.startActivityForResult(intent, 2);
            }
        } else {
            Log.d(TAG, "App usage statistic access check mode");
            granted = (mode == AppOpsManager.MODE_ALLOWED);
            if (!granted) {
                Log.w(TAG, "App usage statistic access is not granted");
            }
        }
        return granted;
    }

    public static Intent getAppIntent(Activity a, String ID){
        final PackageManager pm = a.getPackageManager();
        Intent app=pm.getLaunchIntentForPackage(ID);
        return app;
    }

    public static String getApplist(Activity a){
        String list="<?xml version=\"1.0\" encoding=\"UTF-8\"?><root>";
        final PackageManager pm = a.getPackageManager();
        Intent i = new Intent(Intent.ACTION_MAIN, null);
        i.addCategory(Intent.CATEGORY_LAUNCHER);
        List<ResolveInfo> availableActivities = pm.queryIntentActivities(i, 0);
        for (ResolveInfo ri:availableActivities) {
            list+="<item>";
            list+="<package>"+ri.activityInfo.packageName+"</package>";
            list+="<label>"+String.valueOf(ri.loadLabel(pm))+"</label>";
            Log.d("Icon", ri.activityInfo.packageName);
            list+="<icon>"+AppWorker.drawableToBase64(ri.loadIcon(pm))+"</icon>";
            list+="</item>";
        }
        list+="</root>";
        return list;
    }

    public static String getApplistAsJSON(Activity a){
        String json="[\n";
        final PackageManager pm = a.getPackageManager();
        final List<String> packages = Arrays.asList("com.android.browser", "com.android.gallery3d",
            "com.android.music", "com.android.fmradio", "com.android.inputmethod.latin", "com.android.stk",
            "com.android.calendar", "com.mediatek.filemanager", "com.mediatek.cellbroadcastreceiver",
            "com.conena.navigation.gesture.control", "com.android.quicksearchbox");
        Intent i = new Intent(Intent.ACTION_MAIN, null);
        i.addCategory(Intent.CATEGORY_LAUNCHER);
        List<ResolveInfo> availableActivities = pm.queryIntentActivities(i, 0);
        for (ResolveInfo ri:availableActivities) {
            Log.d("Found package", ri.activityInfo.packageName);

            // todo: Remove. Workaround for beta demo purpose
            if (!packages.contains(ri.activityInfo.packageName)) {
                Log.d("Added package", ri.activityInfo.packageName);
                json+="{\n";
                json+="\"package\": \"" + ri.activityInfo.packageName + "\",\n";
                json+="\"label\": \"" + String.valueOf(ri.loadLabel(pm)) + "\",\n";
                json+="\"icon\": \"" + AppWorker.drawableToBase64(ri.loadIcon(pm)) + "\"\n";
                json+="},\n";
            }
        }
        json=json.substring(0,json.length()-2);
        json+="\n]";
        return json;
    }

    public static String drawableToBase64 (Drawable drawable) {
//        Log.d("Class", drawable.getClass().toString());

        Bitmap bitmap = null;

        if (drawable instanceof BitmapDrawable) {
            BitmapDrawable bitmapDrawable = (BitmapDrawable) drawable;
            if (bitmapDrawable.getBitmap() != null) {
                bitmap = bitmapDrawable.getBitmap();
            }
        }

        if (bitmap == null) {
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
}
