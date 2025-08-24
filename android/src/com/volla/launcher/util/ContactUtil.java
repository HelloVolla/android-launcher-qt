package com.volla.launcher.util;

import androidnative.SystemDispatcher;
import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.provider.ContactsContract;
import android.provider.ContactsContract.Intents.Insert.*;
import android.util.Log;
import java.util.Map;
import java.util.HashMap;
import org.qtproject.qt5.android.QtNative;

public class ContactUtil {
    private static final String TAG = "ContactUtil";

    public static final String CREATE_CONTACT = "volla.launcher.createContactAction";

    static {
        SystemDispatcher.addListener(new SystemDispatcher.Listener() {

            public void onDispatched(String type, Map dmessage) {
                final Activity activity = QtNative.activity();
                final Map message = dmessage;

                if (type.equals(CREATE_CONTACT)) {
                    Runnable runnable = new Runnable () {
                        public void run() {
                            if (activity.checkSelfPermission(Manifest.permission.WRITE_CONTACTS) == PackageManager.PERMISSION_GRANTED) {
                                Intent intent = new Intent(ContactsContract.Intents.Insert.ACTION);
                                intent.setType(ContactsContract.RawContacts.CONTENT_TYPE);

                                if ( message.containsKey("name") ) {
                                    intent.putExtra(ContactsContract.Intents.Insert.NAME, ((String)message.get("name")));
                                }

                                if ( message.containsKey("phoneNumber") ) {
                                    intent.putExtra(ContactsContract.Intents.Insert.PHONE, ((String)message.get("phoneNumber")));
                                }

                                if ( message.containsKey("isMobile") ) {
                                    intent.putExtra(ContactsContract.Intents.Insert.PHONE_TYPE, ContactsContract.CommonDataKinds.Phone.TYPE_MOBILE);
                                }

                                if ( message.containsKey("email") ) {
                                    intent.putExtra(ContactsContract.Intents.Insert.EMAIL, ((String)message.get("email")));
                                }

                                activity.startActivityForResult(intent, 1);
                            }
                        }
                    };

                    Thread thread = new Thread(runnable);
                    thread.start();
                }
            }
        });
    }
}
