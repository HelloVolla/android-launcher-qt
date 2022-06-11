package com.volla.launcher.util;

import androidnative.SystemDispatcher;
import android.app.Activity;
import android.content.Intent;
import android.provider.CalendarContract;
import android.provider.CalendarContract.Events;
import android.util.Log;
import org.qtproject.qt5.android.QtNative;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;
import java.util.Calendar;

public class CalendarUtil {

    private static final String TAG = "CalendarUtil";

    public static final String CREATE_EVENT = "volla.launcher.createEventAction";

    static {
        SystemDispatcher.addListener(new SystemDispatcher.Listener() {

            public void onDispatched(String type, Map dmessage) {

                final Activity activity = QtNative.activity();

                if (type.equals(CREATE_EVENT)) {

                    final Map message = dmessage;

                    Runnable runnable = new Runnable () {

                        public void run() {
                            createEvent(message, activity);
                        }
                    };

                    Thread thread = new Thread(runnable);
                    thread.start();
                }
            }
        });
    }

    static void createEvent(Map message, Activity a) {
        Log.d(TAG, "Invoked JAVA createEvent" );

        Calendar calendarEvent = Calendar.getInstance();
        Intent intent = new Intent(Intent.ACTION_INSERT);
        intent.setData(Events.CONTENT_URI);

        if ( message.containsKey("beginTime") ) {
            intent.putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, ((Double)message.get("beginTime")).longValue());
        }

        if ( message.containsKey("endTime") ) {
            intent.putExtra(CalendarContract.EXTRA_EVENT_END_TIME, ((Double)message.get("endTime")).longValue());
        }

        if ( message.containsKey("allDay") ) {
            intent.putExtra(CalendarContract.EXTRA_EVENT_ALL_DAY, (boolean)message.get("allDay"));
        } else {
            intent.putExtra(CalendarContract.EXTRA_EVENT_ALL_DAY, false);
        }

        if ( message.containsKey("title") ) {
            intent.putExtra(Events.TITLE, (String)message.get("title"));
        }

        if ( message.containsKey("description") ) {
            intent.putExtra(Events.DESCRIPTION, (String)message.get("description")); // e.g. FREQ=YEARLY
        }

        a.startActivity(intent);
    }
}
