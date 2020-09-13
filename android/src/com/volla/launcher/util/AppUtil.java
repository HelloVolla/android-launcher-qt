package com.volla.launcher.util;

import androidnative.SystemDispatcher;
import android.app.Activity;
import android.util.Log;
import android.content.pm.PackageManager;
import android.content.pm.ApplicationInfo;
import android.content.pm.ResolveInfo;
import android.content.Intent;
import android.provider.MediaStore;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import org.qtproject.qt5.android.QtNative;

public class AppUtil {

    private static final String TAG = "LayoutUtil";

    public static final String GET_APP_COUNT = "volla.launcher.appCountAction";
    public static final String GOT_APP_COUNT = "volla.launcher.appCountResponse";
    public static final String OPEN_CAM = "volla.launcher.camAction";

    static {
        SystemDispatcher.addListener(new SystemDispatcher.Listener() {

            public void onDispatched(String type, Map message) {
                final Activity activity = QtNative.activity();
                final PackageManager pm = activity.getPackageManager();

                if (type.equals(GET_APP_COUNT)) {                    

                    Runnable runnable = new Runnable () {

                        public void run() {
                            Intent i = new Intent(Intent.ACTION_MAIN, null);
                            i.addCategory(Intent.CATEGORY_LAUNCHER);
                            List<ResolveInfo> availableActivities = pm.queryIntentActivities(i, 0);

                            Map responseMessage = new HashMap();
                            responseMessage.put("appCount", availableActivities.size());

                            SystemDispatcher.dispatch(GOT_APP_COUNT, responseMessage);
                        }
                    };

                    Thread thread = new Thread(runnable);
                    thread.start();
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
                }
            }
        });
    }
}
