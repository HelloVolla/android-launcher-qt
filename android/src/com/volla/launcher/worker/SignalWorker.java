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

public class SignalWorker {

   private static final String TAG = "SignalWorker";

    public static final String GET_SIGNAL_MESSAGES = "volla.launcher.signalMessagesAction";
    public static final String GOT_SIGNAL_MESSAGES = "volla.launcher.signalMessagesResponse";

    public static final String GET_SIGNAL_THREADS = "volla.launcher.signalThreadsAction";
    public static final String GOT_SIGNAL_THREADS = "volla.launcher.signalThreadsResponse";
    public static final String ENABLE_SIGNAL = "volla.launcher.signalEnable";
    public static final String SEND_SIGNAL_MESSAGES ="volla.launcher.signalSendMessageAction";

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
        ArrayList<Map> messageList = new ArrayList();
        String person = (String) message.get("person");
        String threadId = (String) message.get("threadId");
        int   age = (Integer) message.get("threadAge");
        if(person != null && person.length()>0){
        repository.getAllMessageByPersonName(person,10).subscribe(it -> {
            for (Message m : it) {
                Map reply = new HashMap();
                reply.put("id", m.getId());
                reply.put("thread_id", m.getUuid());
                reply.put("body", m.getTitle());
                reply.put("person", m.getSelfDisplayName());
                reply.put("address", "");
                reply.put("date", m.getTimeStamp());
                reply.put("read", true);
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
	});
       } else {
           repository.getAllMessageByThreadId(threadId,10).subscribe(it -> {
            for (Message m : it) {
                Map reply = new HashMap();
                reply.put("id", m.getId());
                reply.put("thread_id", m.getUuid());
                reply.put("body", m.getTitle());
                reply.put("person", m.getSelfDisplayName());
                reply.put("address", "");
                reply.put("date", Long.toString(m.getTimeStamp()));
                reply.put("read", true);
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
            });

          }
    }

    static void retriveMessageThreads(Map message, Activity activity){
        Log.d(TAG, "Invoked JAVA retriveMessageThreads");
        MessageRepository repository = new MessageRepository(QtNative.activity().getApplication());
        ArrayList<Map> messageList = new ArrayList();
        String threadId = (String) message.get("threadAge");
        repository.getAllUsers().subscribe(it -> {
            for (Users m : it) {
                Map reply = new HashMap();
                reply.put("id", m.getId());
                reply.put("thread_id", m.getUuid());
                reply.put("body", m.getBody());
                reply.put("person", m.getUser_name());
                reply.put("address", "7653456789");
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
        });
    }

   static void checkPermission(Activity activity){
      if (!NotificationManagerCompat.getEnabledListenerPackages(activity).contains(activity.getPackageName())) {        //ask for permission
             Intent intent = new Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS");
             activity.startActivity(intent);
        }
   }

    static void enableSignal(Map message, Activity activity){
      boolean enable = (boolean) message.get("enableSignal");
      NotificationListenerExampleService.enableSignald(enable);
   }
}
