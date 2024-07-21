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
import androidx.lifecycle.ViewModelProvider;
import com.volla.launcher.repository.MessageRepository;
import com.volla.launcher.repository.MainViewModel;
import com.volla.launcher.storage.Message;
import com.volla.launcher.storage.Users;
import com.volla.launcher.service.NotificationListenerExampleService;
import androidx.core.app.NotificationManagerCompat;
import com.volla.launcher.util.NotificationPlugin;
import android.content.pm.PackageManager;
import com.volla.launcher.storage.NotificationStorageManager;
public class SignalWorker {

   private static final String TAG = "SignalWorker";

    public static final String GET_SIGNAL_MESSAGES = "volla.launcher.signalMessagesAction";
    public static final String GOT_SIGNAL_MESSAGES = "volla.launcher.signalMessagesResponse";

    public static final String GET_SIGNAL_THREADS = "volla.launcher.signalThreadsAction";
    public static final String GOT_SIGNAL_THREADS = "volla.launcher.signalThreadsResponse";
    public static final String ENABLE_SIGNAL = "volla.launcher.signalEnable";
    public static final String SEND_SIGNAL_MESSAGES ="volla.launcher.signalSendMessageAction";
    public static final String SIGNAL_ERROR =  "volla.launcher.signalAppNotInstalled";
    public static NotificationPlugin np;
    static final Map<String , String> errorCodeMap = new HashMap<String , String>() {{
        put("403",    "Attached image not accessible");
        put("404", "Attached image not available");
    }};

    static {
        SystemDispatcher.addListener(new SystemDispatcher.Listener() {

            public void onDispatched(String type, Map dmessage) {
                final Activity activity = QtNative.activity();
                final Map message = dmessage;
                ViewModelProvider.AndroidViewModelFactory factory = ViewModelProvider.AndroidViewModelFactory.getInstance(QtNative.activity().getApplication());
                if (type.equals(GET_SIGNAL_MESSAGES)) {
                    Runnable runnable = new Runnable () {
                        public void run() {
                            checkPermission(activity);
                            retrieveMessageConversations(message, activity);
                        }
                    };
                    Thread thread = new Thread(runnable);
                    thread.start();
                } else if (type.equals(GET_SIGNAL_THREADS)) {
                    Runnable runnable = new Runnable () {
                        public void run() {
                            checkPermission(activity);
                            retriveMessageThreads(message, activity);
                        }
                    };
                    Thread thread = new Thread(runnable);
                    thread.start();
                } else if (type.equals(ENABLE_SIGNAL)) {
                    Runnable runnable = new Runnable () {
                        public void run() {
                            checkPermission(activity);
                            enableSignal(message, activity);
                        }
                    };
                    Thread thread = new Thread(runnable);
                    thread.start();
                }
            }
        });
    }

    static void retrieveMessageConversations(Map message, Activity activity){
        Log.d(TAG, "Invoked JAVA retrieveMessageConversations: " + message.toString());
        MessageRepository repository = new MessageRepository(QtNative.activity().getApplication());
        NotificationStorageManager storageManager = new NotificationStorageManager(QtNative.activity().getApplication());
        ArrayList<Map> messageList = new ArrayList();
        String person = (String) message.get("person");
        String threadId = (String) message.get("threadId");
        int   age = (Integer) message.get("threadAge");
        long timeFrame = System.currentTimeMillis() - (age * 1000);
        if(person != null && person.length()>0){
        repository.getAllMessageByPersonName(person,timeFrame).subscribe(it -> {
            for (Message m : it) {
                Map reply = new HashMap();
                Map errorCode = new HashMap();
                reply.put("id", m.getId());
                reply.put("thread_id", m.getUuid());
                reply.put("body", m.getTitle());
                reply.put("person", m.getSelfDisplayName());
                reply.put("address", m.getAddress());
                reply.put("date", m.getTimeStamp());
                reply.put("read", true);
                if(m.getNotification().length() > 1) {
                    errorCode.put("code", m.getNotification());
                    errorCode.put("message", errorCodeMap.get(m.getNotification()));
                    reply.put("errorProperty", errorCode);
                } else {
                    reply.put("errorProperty", errorCode);
                }
                if(m.getSelfDisplayName() != null && m.getSelfDisplayName().length()>=1){
                    reply.put("isSent", false);
                } else {
                    reply.put("isSent", true);
                }
                reply.put("image", m.getLargeIcon());
                reply.put("attachments", "");
                messageList.add(reply);
            }
                Map result = new HashMap();
            result.put("messages", messageList );
            result.put("messagesCount", messageList.size());
            Log.d(TAG, "Will dispatch messages: " + result.toString());
            SystemDispatcher.dispatch(GOT_SIGNAL_MESSAGES, result);
            repository.updateReadStatusInUserTableUsingName(person);
            storageManager.clearNotificationCount("org.thoughtcrime.securesms");
        });
       } else {
           repository.getAllMessageByThreadId(threadId,timeFrame).subscribe(it -> {
            for (Message m : it) {
                Map reply = new HashMap();
                Map errorCode = new HashMap();
                reply.put("id", m.getId());
                reply.put("thread_id", m.getUuid());
                reply.put("body", m.getTitle());
                reply.put("person", m.getSelfDisplayName());
                reply.put("address", m.getAddress());
                reply.put("date", Long.toString(m.getTimeStamp()));
                reply.put("read", true);
                if(m.getNotification().length() > 1) {
                    errorCode.put("code", m.getNotification());
                    errorCode.put("message", errorCodeMap.get(m.getNotification()));
                    reply.put("errorProperty", errorCode);
                } else {
                    reply.put("errorProperty", errorCode);
                }
                if(m.getSelfDisplayName() != null && m.getSelfDisplayName().length()>=1){
                    reply.put("isSent", false);
                } else {
                    reply.put("isSent", true);
                }
                reply.put("image", m.getLargeIcon());
                reply.put("attachments", "");
                messageList.add(reply);
                }
             Map result = new HashMap();
            result.put("messages", messageList);
            result.put("messagesCount", messageList.size());
            Log.d(TAG, "Will dispatch messages: " + result.toString());
            SystemDispatcher.dispatch(GOT_SIGNAL_MESSAGES, result);
            repository.updateReadStatusInUserTableUsingThreadId(threadId);
            storageManager.clearNotificationCount("org.thoughtcrime.securesms");
            });

          }
    }

    static void retriveMessageThreads(Map message, Activity activity){
        Log.d(TAG, "Invoked JAVA retriveMessageThreads");
        MessageRepository repository = new MessageRepository(QtNative.activity().getApplication());
        ArrayList<Map> messageList = new ArrayList();
        int age = (Integer) message.get("age");
        long timeFrame = System.currentTimeMillis() - (age * 1000);
        repository.getAllUsers(timeFrame).subscribe(it -> {
            for (Users m : it) {
                Map reply = new HashMap();
                reply.put("id", m.getId());
                reply.put("thread_id", m.getUser_name());
                reply.put("body", m.getBody());
                reply.put("person",  m.getUuid());
                reply.put("address", "");
                reply.put("date", Long.toString(m.getTimeStamp()));
                reply.put("read", m.getRead());
                reply.put("isSent", m.getSent());
                reply.put("image", m.getLargeIcon());
                reply.put("attachments", "");

                //Log.e("VollaNotification ThreadMessage", "Sender Name: " + m);
                //Log.e("VollaNotification ThreadMessage JSON", reply.toString());
                messageList.add(reply);
            }
            Map result = new HashMap();
            result.put("messages", messageList );
            result.put("messagesCount", messageList.size());
            Log.d(TAG, "Will dispatch threads:" + result.toString());
            SystemDispatcher.dispatch(GOT_SIGNAL_THREADS, result);
            repository.deleteAllThreadsHavingTimeStampLessThen(timeFrame);
        });
    }

    static void checkPermission(Activity activity){
      if (!NotificationManagerCompat.getEnabledListenerPackages(activity).contains(activity.getPackageName())) {        //ask for permission
             Intent intent = new Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS");
             activity.startActivity(intent);
        }
   }

    public static boolean isSignalInstalled(Activity activity) {
           String packageName = "org.thoughtcrime.securesms";
           PackageManager packageManager = activity.getPackageManager();
        try {
            packageManager.getPackageInfo(packageName, PackageManager.GET_ACTIVITIES);
            return true;
        } catch (PackageManager.NameNotFoundException e) {
            return false;
        }
   }

    static void enableSignal(Map message, Activity activity) {
      boolean enable = (boolean) message.get("enableSignal");
      if(isSignalInstalled(activity)) {
          NotificationListenerExampleService.enableSignald(enable);
      } else {
          Map result = new HashMap();
          result.put("error", "Signal Application not Installed");
          SystemDispatcher.dispatch(SIGNAL_ERROR, result);
      }
   }
}
