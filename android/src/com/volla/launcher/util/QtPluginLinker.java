package com.volla.launcher.util;

import android.app.Activity;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.system.Os;
import android.util.Log;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * Prepares qt-reserved-files before QtLoader gets to it.
 *
 * Qt 5.13 copies every bundled plugin (libqtforandroid.so, imageformats, qml
 * plugins, ...) from the native lib dir into the app data dir and dlopen()s the
 * copies from there. Starting with Android 17 platform apps are not allowed to
 * execute app_data_file anymore, so loading libqtforandroid.so fails and the
 * launcher crashes right on start.
 *
 * We do the same extraction Qt does, but symlink the .so files back to the
 * native lib dir instead of copying them. Then we write cache.version, so
 * QtLoader thinks the cache is up to date and skips its own extraction.
 * If anything goes wrong we wipe the directory and let Qt do its usual thing.
 */
public class QtPluginLinker {

    private static final String TAG = "QtPluginLinker";

    private static final String SYSTEM_LIB_PATH = "/system/lib/";
    private static final String[] SYSTEM_APP_PATHS = {"/system/priv-app/", "/system/app/"};

    public static void prepare(Activity activity) {
        File pluginsDir = null;
        try {
            Bundle metaData = activity.getPackageManager()
                    .getActivityInfo(activity.getComponentName(), PackageManager.GET_META_DATA).metaData;
            if (metaData == null
                    || metaData.getInt("android.app.bundle_local_qt_libs", 0) != 1
                    || !metaData.containsKey("android.app.bundled_in_lib_resource_id")) {
                return;
            }

            String libsDir = libsDir(activity, metaData);
            if (libsDir == null) {
                return;
            }

            String pluginsPrefix = new File(activity.getApplicationInfo().dataDir).getCanonicalPath()
                    + "/qt-reserved-files/";
            pluginsDir = new File(pluginsPrefix);
            long packageVersion = activity.getPackageManager()
                    .getPackageInfo(activity.getPackageName(), 0).lastUpdateTime;

            String[] libs = activity.getResources()
                    .getStringArray(metaData.getInt("android.app.bundled_in_lib_resource_id"));

            if (readCacheVersion(pluginsPrefix) == packageVersion && isLinked(pluginsPrefix, libs)) {
                return;
            }

            Log.d(TAG, "Linking Qt plugins into " + pluginsPrefix);
            deleteRecursively(pluginsDir);
            pluginsDir.mkdirs();

            for (String entry : libs) {
                String[] split = entry.split(":");
                File source = new File(libsDir + split[0]);
                if (!source.exists()) {
                    continue;
                }
                File destination = new File(pluginsPrefix + split[1]);
                destination.getParentFile().mkdirs();
                Os.symlink(source.getAbsolutePath(), destination.getAbsolutePath());
            }

            if (metaData.containsKey("android.app.bundled_in_assets_resource_id")) {
                String[] assets = activity.getResources()
                        .getStringArray(metaData.getInt("android.app.bundled_in_assets_resource_id"));
                for (String entry : assets) {
                    String[] split = entry.split(":");
                    copyAsset(activity, split[0], new File(pluginsPrefix + split[1]));
                }
            }

            // Has to be the last step, QtLoader only trusts the cache when this matches
            DataOutputStream out = new DataOutputStream(new FileOutputStream(pluginsPrefix + "cache.version"));
            try {
                out.writeLong(packageVersion);
            } finally {
                out.close();
            }
        } catch (Exception e) {
            Log.e(TAG, "Could not link Qt plugins, falling back to Qt extraction", e);
            if (pluginsDir != null) {
                deleteRecursively(pluginsDir);
            }
        }
    }

    // Same lookup QtLoader does, so we link against the same files it would copy
    private static String libsDir(Activity activity, Bundle metaData) {
        File apk = new File(activity.getApplicationInfo().publicSourceDir);
        String apkParent = apk.getParentFile().getAbsolutePath() + "/";
        boolean fromSystem = false;
        for (String path : SYSTEM_APP_PATHS) {
            if (path.equals(apkParent)) {
                fromSystem = true;
            }
        }

        String dir = fromSystem
                ? metaData.getString("android.app.system_libs_prefix", SYSTEM_LIB_PATH)
                : activity.getApplicationInfo().nativeLibraryDir + "/";
        String[] files = new File(dir).list();
        return files != null && files.length > 0 ? dir : null;
    }

    // False if any plugin is still a plain copy or a link that doesn't resolve anymore
    private static boolean isLinked(String pluginsPrefix, String[] libs) {
        for (String entry : libs) {
            String[] split = entry.split(":");
            Path path = Paths.get(pluginsPrefix + split[1]);
            if (!Files.exists(path, LinkOption.NOFOLLOW_LINKS)) {
                continue; // source wasn't there when we linked, nothing to load either
            }
            if (!Files.isSymbolicLink(path) || !Files.exists(path)) {
                return false;
            }
        }
        return true;
    }

    private static long readCacheVersion(String pluginsPrefix) {
        File versionFile = new File(pluginsPrefix + "cache.version");
        if (!versionFile.canRead()) {
            return 0;
        }
        try {
            DataInputStream in = new DataInputStream(new FileInputStream(versionFile));
            try {
                return in.readLong();
            } finally {
                in.close();
            }
        } catch (Exception e) {
            return 0;
        }
    }

    private static void copyAsset(Activity activity, String source, File destination) throws Exception {
        destination.getParentFile().mkdirs();
        InputStream in = activity.getAssets().open(source);
        try {
            OutputStream out = new FileOutputStream(destination);
            try {
                byte[] buffer = new byte[8192];
                int count;
                while ((count = in.read(buffer)) > 0) {
                    out.write(buffer, 0, count);
                }
            } finally {
                out.close();
            }
        } finally {
            in.close();
        }
    }

    private static void deleteRecursively(File file) {
        // don't follow symlinks, they point into the apk's lib dir
        if (!Files.isSymbolicLink(file.toPath()) && file.isDirectory()) {
            File[] children = file.listFiles();
            if (children != null) {
                for (File child : children) {
                    deleteRecursively(child);
                }
            }
        }
        file.delete();
    }
}
