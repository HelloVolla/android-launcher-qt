package com.volla.launcher.worker;

import android.app.Activity;
import android.content.pm.PackageManager;
import android.content.pm.ApplicationInfo;
import android.content.Intent;
import java.util.List;

public class AppWorker extends org.qtproject.qt5.android.bindings.QtActivity
{

    public AppWorker()
    {
    }

    public static Intent getAppIntent(Activity a, String ID){
        final PackageManager pm = a.getPackageManager();
        Intent app=pm.getLaunchIntentForPackage(ID);
        return app;
    }

    public static String getApplist(Activity a){
    String list="<root>";
    final PackageManager pm = a.getPackageManager();

        List<ApplicationInfo> packages = pm.getInstalledApplications(PackageManager.GET_META_DATA);
        for (ApplicationInfo packageInfo : packages) {
            list+="<item><name>"+packageInfo.packageName+"</name><path>"+packageInfo.sourceDir+"</path></item>";
        }
        list+="</root>";

    return list;
    }


}
