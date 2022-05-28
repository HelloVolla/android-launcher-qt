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
import java.util.LinkedList;
import org.qtproject.qt5.android.QtNative;
import androidx.lifecycle.ViewModelProvider;
import com.volla.launcher.repository.MessageRepository;
import com.volla.launcher.repository.MainViewModel;
import com.volla.launcher.storage.Message;
import com.volla.launcher.storage.Users;

public class SignalWorker {

   private static final String TAG = "SignalWorkerl";

    public static final String GET_SIGNAL_MESSAGES = "volla.launcher.signalMessagesAction";
    public static final String GOT_SIGNAL_MESSAGES = "volla.launcher.signalMessagesResponse";

    public static final String GET_SIGNAL_THREADS = "volla.launcher.signalThreadsAction";
    public static final String GOT_SIGNAL_THREADS = "volla.launcher.signalThreadsResponse";

    static {
        SystemDispatcher.addListener(new SystemDispatcher.Listener() {

            public void onDispatched(String type, Map dmessage) {
                Log.d("VollaNotification on Dispatcher",type);
                final Activity activity = QtNative.activity();
                final Map message = dmessage;
                ViewModelProvider.AndroidViewModelFactory factory = ViewModelProvider.AndroidViewModelFactory.getInstance(QtNative.activity().getApplication());
                

                if (type.equals(GET_SIGNAL_MESSAGES)) {
                     Log.d("VollaNotification calling RetrieveMessageConversations","");
                    retrieveMessageConversations(message, activity);
                } else if (type.equals(GET_SIGNAL_THREADS)) {
                    // todo: implement (use a separate thread)
                    Log.d("VollaNotification called retriveMessageThreads","");
                    retriveMessageThreads(message, activity);
                }
            }
        });
    }


    static void retrieveMessageConversations(Map message, Activity activity){
        Log.d("VollaNotification  retriving message conversation","");
        MessageRepository repository = new MessageRepository(QtNative.activity().getApplication());
        ArrayList<Map> messageList = new ArrayList();
        String personId = (String) message.get("personId");
        String threadId = (String) message.get("threadId");
        List numbers = (List) message.get("numbers");
        int   age = (Integer) message.get("threadAge");


        
        repository.getAllMessageBySender(personId,1).subscribe(it -> {
            for (Message m : it) {
                Map reply = new HashMap();
                reply.put("id", m.getId());
                //reply.put("thread_id", m.getUuid());
                reply.put("body", m.getTitle());
                reply.put("person", m.getSelfDisplayName());
                reply.put("address", "7653456789");
                reply.put("date", m.getTimeStamp());
                reply.put("read", "false");
                reply.put("isSent", "false");
                reply.put("image", m.getLargeIcon());
                reply.put("attachments", "");

                Log.e("VollaNotification retriving message conversation", "Sender Name: " + m);
                Log.e("VollaNotification retriving message conversation JSON", m.getNotificationData().toJson());
                messageList.add(reply);
            }
            Map result = new HashMap();
            result.put("messages", messageList );
            result.put("messagesCount", messageList.size());
            SystemDispatcher.dispatch(GOT_SIGNAL_MESSAGES, result);
            Log.d("VollaNotification Threads dispatched",result.toString());
        });
    }
    static void retriveMessageThreads(Map message, Activity activity){
        MessageRepository repository = new MessageRepository(QtNative.activity().getApplication());
        ArrayList<Map> messageList = new ArrayList();
        String threadId = (String) message.get("threadAge");
        Log.d("VollaNotification  retriving Message Threads","");
        repository.getAllUsers().subscribe(it -> {
            for (Users m : it) {
                Map reply = new HashMap();
                reply.put("id", m.getId());
                reply.put("thread_id", m.getUuid());
                reply.put("body", m.getBody());
                reply.put("person", m.getUser_name());
                reply.put("address", "7653456789");
                reply.put("date", m.getTimeStamp());
                reply.put("read", m.getRead());
                reply.put("isSent", m.getSent());
                reply.put("image", m.getLargeIcon());
                reply.put("attachments", "");

                Log.e("VollaNotification ThreadMessage", "Sender Name: " + m);
                Log.e("VollaNotification ThreadMessage JSON", m.getNotificationData().toJson());
                messageList.add(reply);
            }
            Map result = new HashMap();
            result.put("messages", messageList );
            result.put("messagesCount", messageList.size());
            SystemDispatcher.dispatch(GOT_SIGNAL_THREADS, result);
            Log.d("VollaNotification Threads dispatched",result.toString());
        });
    }
}
