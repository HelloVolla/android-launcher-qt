package com.volla.launcher.util;

import androidnative.SystemDispatcher;
import android.app.Activity;
import android.content.Intent;
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

            final Activity activity = QtNative.activity();

            public void onDispatched(String type, Map message) {
                if (type.equals(CREATE_EVENT)) {
                    createEvent(message, activity);
                }
            }
        });
    }

    static void createEvent(Map message, Activity a) {
        Log.d(TAG, "Invoked JAVA createEvent" );

        Calendar calendarEvent = Calendar.getInstance();
        Intent intent = new Intent(Intent.ACTION_EDIT);
        intent.setType("vnd.android.cursor.item/event");

        if ( message.containsKey("beginTime") ) {
            intent.putExtra(Events.DTSTART, (Integer)message.get("beginTime") * 1000);
        }

        if ( message.containsKey("endTime") ) {
            intent.putExtra(Events.DTEND, (Integer)message.get("endTime") * 1000);
        }

        if ( message.containsKey("allDay") ) {
            intent.putExtra("allDay", (boolean)message.get("allDay"));
        } else {
            intent.putExtra(Events.ALL_DAY, false);
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
