package com.volla.launcher.util;

import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.app.Notification;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.drawable.Icon;
import android.os.Build;
import android.os.Bundle;
import android.service.notification.NotificationListenerService;
import android.service.notification.StatusBarNotification;
import android.text.TextUtils;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.RemoteViews;
import android.widget.TextView;


import androidx.annotation.RequiresApi;
import androidx.core.app.NotificationCompat;
import android.app.Person;
import androidx.core.app.RemoteInput;


import com.volla.launcher.models.Action;
import com.volla.launcher.models.NotificationIds;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.concurrent.TimeUnit;


public class NotificationUtils {

    private static final String[] REPLY_KEYWORDS = {"reply", "android.intent.extra.text"};
    private static final CharSequence REPLY_KEYWORD = "reply";
    private static final CharSequence INPUT_KEYWORD = "input";

    @RequiresApi(api = Build.VERSION_CODES.JELLY_BEAN_MR2)
    public static boolean isRecent(StatusBarNotification sbn, long recentTimeframeInSecs) {
        return sbn.getNotification().when > 0 &&  //Checks against real time to make sure its new
                System.currentTimeMillis() - sbn.getNotification().when <= TimeUnit.SECONDS.toMillis(recentTimeframeInSecs);
    }

    /**
     * http://stackoverflow.com/questions/9292032/extract-notification-text-from-parcelable-contentview-or-contentintent *
     */

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    public static boolean notificationMatchesFilter(StatusBarNotification sbn, NotificationListenerService.RankingMap rankingMap) {
        NotificationListenerService.Ranking ranking = new NotificationListenerService.Ranking();
        if (rankingMap.getRanking(sbn.getKey(), ranking))
            if (ranking.matchesInterruptionFilter())
                return true;
        return false;
    }

    @TargetApi(Build.VERSION_CODES.KITKAT)
    public static String getMessage(Bundle extras) {
        Log.d("NOTIFICATIONUTILS", "Getting message from extras..");
        Log.d("Text", "" + extras.getCharSequence(Notification.EXTRA_TEXT));
        Log.d("Big Text", "" + extras.getCharSequence(Notification.EXTRA_BIG_TEXT));
        Log.d("Title Big", "" + extras.getCharSequence(Notification.EXTRA_TITLE_BIG));
//        Log.d("Text lines", "" + extras.getCharSequence(Notification.EXTRA_TEXT_LINES));
        Log.d("Info text", "" + extras.getCharSequence(Notification.EXTRA_INFO_TEXT));
        Log.d("Info text", "" + extras.getCharSequence(Notification.EXTRA_INFO_TEXT));
        Log.d("Subtext", "" + extras.getCharSequence(Notification.EXTRA_SUB_TEXT));
		Log.d("Summary", "" + extras.getString(Notification.EXTRA_SUMMARY_TEXT));
        CharSequence chars = extras.getCharSequence(Notification.EXTRA_TEXT);
        if(!TextUtils.isEmpty(chars))
            return chars.toString();
        else if(!TextUtils.isEmpty((chars = extras.getString(Notification.EXTRA_SUMMARY_TEXT))))
            return chars.toString();
        else
            return null;
    }

    @TargetApi(Build.VERSION_CODES.KITKAT)
    public static String getExtended(Bundle extras, ViewGroup v) {
        Log.d("NOTIFICATIONUTILS", "Getting message from extras..");

        CharSequence[] lines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES);
        if(lines != null && lines.length > 0) {
            StringBuilder sb = new StringBuilder();
            for (CharSequence msg : lines)
//                msg = msg.toString();//.replaceAll("(\\s+$|^\\s+)", "").replaceAll("\n+", "\n");
                if (!TextUtils.isEmpty(msg)) {
                    sb.append(msg.toString());
                    sb.append('\n');
                }
            return sb.toString().trim();
        }
        CharSequence chars = extras.getCharSequence(Notification.EXTRA_BIG_TEXT);
        if(!TextUtils.isEmpty(chars))
            return chars.toString();
        else if(!VersionUtils.isJellyBeanMR2())
            return getExtended(v);
        else
            return getMessage(extras);
    }

    @SuppressLint("NewApi")
    public static ViewGroup getMessageView(Context context, Notification n) {
        Log.d("NOTIFICATIONUTILS", "Getting message view..");
        RemoteViews views = null;
        if (Build.VERSION.SDK_INT >= 16)
            views = n.bigContentView;
        if (views == null)
            views = n.contentView;
        if (views == null)
            return null;
        LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        ViewGroup localView = (ViewGroup) inflater.inflate(views.getLayoutId(), null);
        views.reapply(context.getApplicationContext(), localView);
        return localView;

    }
    @RequiresApi(api = Build.VERSION_CODES.M)
    public static Icon getLargeIcon(Bundle extras) {
       return  (Icon) extras.get(Notification.EXTRA_LARGE_ICON);
    }
    public static Person getMessagingUser(Bundle extras) {
        return  (Person) extras.get(Notification.EXTRA_MESSAGING_PERSON);
    }
    public static ArrayList<Person> getPeopleList(Bundle extras) {
        Log.e("Arvind Test", "Test " + extras.getParcelableArrayList(Notification.EXTRA_PEOPLE_LIST).size());
        Person p = (Person) extras.getParcelableArrayList(Notification.EXTRA_PEOPLE_LIST).get(0);
        Log.e("Arvind", "Person " + p.getName() + " " + p.getUri() + " " + p.getKey());
        ArrayList<Person> persons = extras.getParcelableArrayList(Notification.EXTRA_PEOPLE_LIST);
        return persons;
    }

    public static String getTitle(ViewGroup localView) {
        Log.d("NOTIFICATIONUTILS", "Getting title..");
        String msg = null;
        Context context = localView.getContext();
        TextView tv = (TextView) localView.findViewById(NotificationIds.getInstance(context).TITLE);
        if (tv != null)
            msg = tv.getText().toString();
        return msg;
    }

    public static String getMessage(ViewGroup localView) {
        Log.d("NOTIFICATIONUTILS", "Getting message..");
        String msg = null;
        Context context = localView.getContext();
        TextView tv = (TextView) localView.findViewById(NotificationIds.getInstance(context).BIG_TEXT);
        if (tv != null && !TextUtils.isEmpty(tv.getText()))
            msg = tv.getText().toString();
        if (TextUtils.isEmpty(msg)) {
            tv = (TextView) localView.findViewById(NotificationIds.getInstance(context).TEXT);
            if (tv != null)
                msg = tv.getText().toString();
        }
        return msg;
    }

    public static String getExtended(ViewGroup localView) {
        Log.d("NOTIFICATIONUTILS", "Getting extended message..");
        String msg = "";
        Context context = localView.getContext();
        TextView tv = (TextView) localView.findViewById(NotificationIds.getInstance(context).EMAIL_0);
        if (tv != null && !TextUtils.isEmpty(tv.getText()))
            msg += tv.getText().toString() + '\n';
        tv = (TextView) localView.findViewById(NotificationIds.getInstance(context).EMAIL_1);
        if (tv != null && !TextUtils.isEmpty(tv.getText()))
            msg += tv.getText().toString() + '\n';
        tv = (TextView) localView.findViewById(NotificationIds.getInstance(context).EMAIL_2);
        if (tv != null && !TextUtils.isEmpty(tv.getText()))
            msg += tv.getText().toString() + '\n';
        tv = (TextView) localView.findViewById(NotificationIds.getInstance(context).EMAIL_3);
        if (tv != null && !TextUtils.isEmpty(tv.getText()))
            msg += tv.getText().toString() + '\n';
        tv = (TextView) localView.findViewById(NotificationIds.getInstance(context).EMAIL_4);
        if (tv != null && !TextUtils.isEmpty(tv.getText()))
            msg += tv.getText().toString() + '\n';
        tv = (TextView) localView.findViewById(NotificationIds.getInstance(context).EMAIL_5);
        if (tv != null && !TextUtils.isEmpty(tv.getText()))
            msg += tv.getText().toString() + '\n';
        tv = (TextView) localView.findViewById(NotificationIds.getInstance(context).EMAIL_6);
        if (tv != null && !TextUtils.isEmpty(tv.getText()))
            msg += tv.getText().toString() + '\n';
//        tv = (TextView) localView.findViewById(NotificationIds.getInstance().INBOX_MORE);
//        if (tv != null && !TextUtils.isEmpty(tv.getText()))
//            msg += tv.getText().toString() + '\n';
        if (msg.isEmpty())
            msg = getExpandedText(localView);
        if (msg.isEmpty())
            msg = getMessage(localView);
        return msg.trim();
    }

    @TargetApi(Build.VERSION_CODES.KITKAT)
    public static String getTitle(Bundle extras) {
        Log.d("NOTIFICATIONUTILS", "Getting title from extras..");
        String msg = extras.getString(Notification.EXTRA_TITLE);
        Log.d("Title Big", "" + extras.getString(Notification.EXTRA_TITLE_BIG));
        return msg;
    }

    /** OLD/CURRENT METHODS **/

    public static ViewGroup getView(Context context, RemoteViews view)
    {
        ViewGroup localView = null;
        try
        {
            LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
            localView = (ViewGroup) inflater.inflate(view.getLayoutId(), null);
            view.reapply(context, localView);
        }
        catch (Exception exp)
        {
        }
        return localView;
    }

    @SuppressLint("NewApi")
    public static ViewGroup getLocalView(Context context, Notification n)
    {
        RemoteViews view = null;
        if(Build.VERSION.SDK_INT >= 16) { view = n.bigContentView; }

        if (view == null)
        {
            view = n.contentView;
        }
        ViewGroup localView = null;
        try
        {
            LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
            localView = (ViewGroup) inflater.inflate(view.getLayoutId(), null);
            view.reapply(context, localView);
        } catch (Exception exp) { }
        return localView;
    }

    public static ArrayList<Action> getActions(Notification n, String packageName, ArrayList<Action> actions) {
        NotificationCompat.WearableExtender wearableExtender = new NotificationCompat.WearableExtender(n);
        if (wearableExtender.getActions().size() > 0) {
            for (NotificationCompat.Action action : wearableExtender.getActions())
                actions.add(new Action(action, packageName, action.title.toString().toLowerCase().contains(REPLY_KEYWORD)));
        }
        return actions;
    }

    public static Action getQuickReplyAction(Notification n, String packageName) {
        NotificationCompat.Action action = null;
        if(Build.VERSION.SDK_INT >= 24)
            action = getQuickReplyAction(n);
        if(action == null)
            action = getWearReplyAction(n);
        if(action == null)
            return null;
        return new Action(action, packageName, true);
    }

    private static NotificationCompat.Action getQuickReplyAction(Notification n) {
        for(int i = 0; i < NotificationCompat.getActionCount(n); i++) {
            NotificationCompat.Action action = NotificationCompat.getAction(n, i);
            if(action.getRemoteInputs() != null) {
                for (int x = 0; x < action.getRemoteInputs().length; x++) {
                    RemoteInput remoteInput = action.getRemoteInputs()[x];
                    if (isKnownReplyKey(remoteInput.getResultKey()))
                        return action;
                }
            }
        }
        return null;
    }

    private static NotificationCompat.Action getWearReplyAction(Notification n) {
        NotificationCompat.WearableExtender wearableExtender = new NotificationCompat.WearableExtender(n);
        for (NotificationCompat.Action action : wearableExtender.getActions()) {
            if(action.getRemoteInputs() != null) {
                for (int x = 0; x < action.getRemoteInputs().length; x++) {
                    RemoteInput remoteInput = action.getRemoteInputs()[x];
                    if (isKnownReplyKey(remoteInput.getResultKey()))
                        return action;
                    else if (remoteInput.getResultKey().toLowerCase().contains(INPUT_KEYWORD))
                        return action;
                }
            }
        }
        return null;
    }

    private static boolean isKnownReplyKey(String resultKey) {
        if(TextUtils.isEmpty(resultKey))
            return false;

        resultKey = resultKey.toLowerCase();
        for(String keyword : REPLY_KEYWORDS)
            if(resultKey.contains(keyword))
                return true;

        return false;
    }

    //OLD METHOD
        public static String getExpandedText(ViewGroup localView)
    {
    	String text = "";
        if (localView != null)
        {
            Context context = localView.getContext();
                View v;
                // try to get big text
                v = localView.findViewById(NotificationIds.getInstance(context).big_notification_content_text);
                if (v != null && v instanceof TextView)
                {
                        String s = ((TextView)v).getText().toString();
                        if (!s.equals(""))
                        {
                                // add title string if available
                                View titleView = localView.findViewById(android.R.id.title);
                                if (v != null && v instanceof TextView)
                                {
                                        String title = ((TextView)titleView).getText().toString();
                                        if (!title.equals(""))
                                                text = title + " " + s;
                                        else
                                                text = s;
                                }
                                else
                                        text = s;
                        }
                }

             // try to extract details lines
    			v = localView.findViewById(NotificationIds.getInstance(context).inbox_notification_event_10_id);
    			if (v != null && v instanceof TextView)
    			{
    				CharSequence s = ((TextView)v).getText();
    				if (!s.equals(""))
    					if (!s.equals(""))
    						text += s.toString();
    			}

    				v = localView.findViewById(NotificationIds.getInstance(context).inbox_notification_event_9_id);
    				if (v != null && v instanceof TextView)
    				{
    					CharSequence s = ((TextView)v).getText();
    					if (!s.equals(""))
    						text += "\n" + s.toString();
    				}

    				v = localView.findViewById(NotificationIds.getInstance(context).inbox_notification_event_8_id);
    				if (v != null && v instanceof TextView)
    				{
    					CharSequence s = ((TextView)v).getText();
    					if (!s.equals(""))
    						text += "\n" + s.toString();
    				}

    				v = localView.findViewById(NotificationIds.getInstance(context).inbox_notification_event_7_id);
    				if (v != null && v instanceof TextView)
    				{
    					CharSequence s = ((TextView)v).getText();
    					if (!s.equals(""))
    						text += "\n" + s.toString();
    				}

    				v = localView.findViewById(NotificationIds.getInstance(context).inbox_notification_event_6_id);
    				if (v != null && v instanceof TextView)
    				{
    					CharSequence s = ((TextView)v).getText();
    					if (!s.equals(""))
    						text += "\n" + s.toString();
    				}

    				v = localView.findViewById(NotificationIds.getInstance(context).inbox_notification_event_5_id);
    				if (v != null && v instanceof TextView)
    				{
    					CharSequence s = ((TextView)v).getText();
    					if (!s.equals(""))
    						text += "\n" + s.toString();
    				}

    				v = localView.findViewById(NotificationIds.getInstance(context).inbox_notification_event_4_id);
    				if (v != null && v instanceof TextView)
    				{
    					CharSequence s = ((TextView)v).getText();
    					if (!s.equals(""))
    						text += "\n" + s.toString();
    				}

    				v = localView.findViewById(NotificationIds.getInstance(context).inbox_notification_event_3_id);
    				if (v != null && v instanceof TextView)
    				{
    					CharSequence s = ((TextView)v).getText();
    					if (!s.equals(""))
    						text += "\n" + s.toString();
    				}

    				v = localView.findViewById(NotificationIds.getInstance(context).inbox_notification_event_2_id);
    				if (v != null && v instanceof TextView)
    				{
    					CharSequence s = ((TextView)v).getText();
    					if (!s.equals(""))
    						text += "\n" + s.toString();
    				}

    				v = localView.findViewById(NotificationIds.getInstance(context).inbox_notification_event_1_id);
    				if (v != null && v instanceof TextView)
    				{
    					CharSequence s = ((TextView)v).getText();
    					if (!s.equals(""))
    						text += "\n" + s.toString();
    				}

    				if (text.equals("")) //Last resort for Kik
                    {
    					// get title string if available
                        View titleView = localView.findViewById(NotificationIds.getInstance(context).notification_title_id );
                        View bigTitleView = localView.findViewById(NotificationIds.getInstance(context).big_notification_title_id );
                        View inboxTitleView = localView.findViewById(NotificationIds.getInstance(context).inbox_notification_title_id );
                        if (titleView  != null && titleView  instanceof TextView)
                        {
                                text += ((TextView)titleView).getText() + " - ";
                        } else if (bigTitleView != null && bigTitleView instanceof TextView)
                        {
                        	text += ((TextView)titleView).getText();
                        } else if  (inboxTitleView != null && inboxTitleView instanceof TextView)
                        {
                        	text += ((TextView)titleView).getText();
                        }

                            v = localView.findViewById(NotificationIds.getInstance(context).notification_subtext_id);
                            if (v != null && v instanceof TextView)
                            {
                                    CharSequence s = ((TextView)v).getText();
                                    if (!s.equals(""))
                                    {
                                            text += s.toString();
                                    }
                            }
                    }

        }
        return text.trim();
    }

    public static boolean isAPriorityMode(int interruptionFilter) {
        if(interruptionFilter == NotificationListenerService.INTERRUPTION_FILTER_NONE ||
                interruptionFilter == NotificationListenerService.INTERRUPTION_FILTER_UNKNOWN)
            return false;
        return true;
    }

}
