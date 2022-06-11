package com.volla.launcher.worker;

import androidnative.SystemDispatcher;
import android.app.Activity;
import android.util.Log;
import java.util.Map;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;
import android.content.Intent;
import java.util.LinkedList;
import org.qtproject.qt5.android.QtNative;

public class SignalWorker {

   private static final String TAG = "SignalWorkerl";

    public static final String GET_SIGNAL_MESSAGES = "volla.launcher.signalMessagesAction";
    public static final String GOT_SIGNAL_MESSAGES = "volla.launcher.signalMessagesResponse";

    public static final String GET_SIGNAL_THREADS = "volla.launcher.signalThreadsAction";
    public static final String GOT_SIGNAL_THREADS = "volla.launcher.signalThreadsResponse";

    static {
        SystemDispatcher.addListener(new SystemDispatcher.Listener() {

            public void onDispatched(String type, Map dmessage) {

                final Activity activity = QtNative.activity();
                final Map message = dmessage;

                if (type.equals(GET_SIGNAL_MESSAGES)) {
                    // todo: implement (use a separate thread)
                    Log.d(TAG, "Rerieve Signal conversaion called");
                    Map reply = new HashMap();
                    ArrayList<Map> conversation = new ArrayList();
                    reply.put("messages", conversation );
                    SystemDispatcher.dispatch(GOT_SIGNAL_MESSAGES, reply);
                } else if (type.equals(GET_SIGNAL_THREADS)) {
                    // todo: implement (use a separate thread)
                    Log.d(TAG, "Retrieve Signal threads called");
                    Map reply = new HashMap();
                    ArrayList<Map> threads = new ArrayList();
                    reply.put("messages", threads );
                    SystemDispatcher.dispatch(GOT_SIGNAL_THREADS, reply);
                }
            }
        });
    }
}
