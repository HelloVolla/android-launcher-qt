package com.volla.launcher.util;

import android.content.Context;
import android.os.IBinder;
import android.os.UserHandle;
import android.util.Log;

import java.lang.reflect.Method;
import java.util.List;

public final class OverlayReflect {

    private static final String TAG = "RRO";

    private OverlayReflect() {}

    public static Object getOverlayManager() {
        try {
            // ServiceManager.getService("overlay")
            Class<?> smClass = Class.forName("android.os.ServiceManager");
            Method getService = smClass.getDeclaredMethod("getService", String.class);
            IBinder binder = (IBinder) getService.invoke(null, "overlay"); // Context.OVERLAY_SERVICE);

            // IOverlayManager.Stub.asInterface(binder)
            Class<?> stubClass = Class.forName(
                    "android.content.om.IOverlayManager$Stub"
            );
            Method asInterface =
                    stubClass.getDeclaredMethod("asInterface", IBinder.class);

            return asInterface.invoke(null, binder);

        } catch (Throwable t) {
            Log.e(TAG, "Failed to get IOverlayManager", t);
            return null;
        }
    }

    public static void dumpSystemOverlays() {
        try {
            Object om = getOverlayManager();
            if (om == null) {
                Log.e(TAG, "OverlayManager is null");
                return;
            }

            Method getOverlayInfosForTarget =
                    om.getClass().getMethod(
                            "getOverlayInfosForTarget",
                            String.class,
                            int.class
                    );

            @SuppressWarnings("unchecked")
            List<Object> overlays =
                    (List<Object>) getOverlayInfosForTarget.invoke(
                            om,
                            "android",
                            0 // UserHandle.USER_SYSTEM
                    );

            for (Object info : overlays) {
                dumpOverlayInfo(info);
            }

        } catch (Throwable t) {
            Log.e(TAG, "Reflection call failed", t);
        }
    }

    private static void dumpOverlayInfo(Object info) {
        try {
            Class<?> c = info.getClass();

            String pkg = (String) c.getField("packageName").get(info);
            boolean enabled = c.getMethod("isEnabled").invoke(info).equals(Boolean.TRUE);
            int state = c.getField("state").getInt(info);

            Log.d(TAG,
                    pkg +
                    " enabled=" + enabled +
                    " state=" + state);

        } catch (Throwable t) {
            Log.e(TAG, "Failed to read OverlayInfo", t);
        }
    }

    public static String getEnabledFontOverlay() {
        try {
            Object om = getOverlayManager();
            if (om == null) {
                Log.e(TAG, "OverlayManager is null");
            }

            Method getOverlayInfosForTarget =
                    om.getClass().getMethod(
                            "getOverlayInfosForTarget",
                            String.class,
                            int.class
                    );

            @SuppressWarnings("unchecked")
            List<Object> overlays =
                    (List<Object>) getOverlayInfosForTarget.invoke(
                            om,
                            "android",
                            0 // UserHandle.USER_SYSTEM
                    );

            for (Object info : overlays) {
                try {
                    Class<?> c = info.getClass();

                    String pkg = (String) c.getField("packageName").get(info);
                    boolean enabled = c.getMethod("isEnabled").invoke(info).equals(Boolean.TRUE);
                    int state = c.getField("state").getInt(info);

                    if (pkg.contains("font") && enabled) {
                        return pkg;
                    }
                } catch (Throwable t) {
                    Log.e(TAG, "Failed to read OverlayInfo", t);
                }
            }
        } catch (Throwable t) {
            Log.e(TAG, "Reflection call failed", t);
        }

        return null;
    }
}
