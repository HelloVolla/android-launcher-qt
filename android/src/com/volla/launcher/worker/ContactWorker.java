package com.volla.launcher.worker;

import androidnative.SystemDispatcher;
import android.Manifest;
import android.app.Activity;
import android.content.pm.PackageManager;
import android.content.ContentResolver;
import android.content.ContentUris;
import android.provider.ContactsContract;
import android.provider.ContactsContract.CommonDataKinds.Email;
import android.provider.ContactsContract.CommonDataKinds.Phone;
import android.provider.ContactsContract.CommonDataKinds.Organization;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.util.Base64;
import android.util.Log;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.LinkedList;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.IOException;
import org.qtproject.qt5.android.QtNative;

public class ContactWorker {

    private static final String TAG = "ContactWorker";

    private static final String[] mobilePreDialNumbers = new String[] {
        "+49152", "+49162", "+49172", "+49173", "+49174", "+49157", "+49159", "+49163", "+49176", "+49177", "+49178", "+49179", "+4915566",
        "+4915888", "+43699", "+43680", "+43688", "+43681", "+43699", "+43664", "+43681", "+43681", "+43681", "+43681", "+43667", "+43676",
        "+43650", "+43678", "+43650", "+43677", "+43677", "+43677", "+43676", "+43660", "+43699", "+43690", "+43678", "+43665", "+43686",
        "+43670", "+43670", "+43670", "+4176", "+4177", "+4178", "+4179", "+4175"};

    static {
        SystemDispatcher.addListener(new SystemDispatcher.Listener() {

            public void onDispatched(String type, Map dmessage) {

                final Activity activity = QtNative.activity();
                final Map message = dmessage;

                if (type.equals("volla.launcher.contactAction")) {
                    Runnable runnable = new Runnable () {
                        public void run() {
                            if (activity.checkSelfPermission(Manifest.permission.READ_CONTACTS) == PackageManager.PERMISSION_GRANTED) {
                                getContacts(message, activity);
                            }
                        }
                    };

                    Thread thread = new Thread(runnable);
                    thread.start();
                }
                else if (type.equals("volla.launcher.checkContactAction")) {
                    Runnable runnable = new Runnable () {
                        public void run() {
                            if (activity.checkSelfPermission(Manifest.permission.READ_CONTACTS) == PackageManager.PERMISSION_GRANTED) {
                                checkContacts(message, activity);
                            } else {
                                Log.d(TAG, "Permissions for contacts not granted");
                                Map responseMessage = new HashMap();
                                responseMessage.put("needsSync", false);
                                SystemDispatcher.dispatch("volla.launcher.checkContactResponse", responseMessage);
                            }
                        }
                    };

                    Thread thread = new Thread(runnable);
                    thread.start();
                } else if (type.equals("volla.launcher.contactImageAction")) {
                    Runnable runnable = new Runnable () {
                        public void run() {
                            if (activity.checkSelfPermission(Manifest.permission.READ_CONTACTS) == PackageManager.PERMISSION_GRANTED) {
                                getContactImage(message, activity);
                            }
                        }
                    };

                    Thread thread = new Thread(runnable);
                    thread.start();
                }

                return;
            }
        });
    }

    static void getContacts(Map message, Activity activity) {
        Log.d(TAG, "get Contacts");

        final ContentResolver contentResolver = activity.getContentResolver();

        String[] mainQueryProjection = {
            ContactsContract.Contacts._ID,
            ContactsContract.Contacts.DISPLAY_NAME_PRIMARY,
            ContactsContract.Contacts.STARRED
        };
        String mainQuerySelection = ContactsContract.Contacts.IN_VISIBLE_GROUP + " = ?";
        String[] mainQuerySelectionArgs = new String[]{"1"};
        String mainQuerySortOrder = String.format("%1$s COLLATE NOCASE", ContactsContract.Contacts.DISPLAY_NAME_PRIMARY);

        final Cursor mainQueryCursor = contentResolver.query(
                        ContactsContract.Contacts.CONTENT_URI,
                        mainQueryProjection,
                        mainQuerySelection,
                        mainQuerySelectionArgs,
                        mainQuerySortOrder);

        if (mainQueryCursor != null) {
            int currentBlock = 0;
            int contactsCount = mainQueryCursor.getCount();

            Log.d(TAG, contactsCount + " contacts found");

            class ContactRunnable implements Runnable {
                int blockStart;
                int contactsCount;
                ContactRunnable(int b, int c) {
                    blockStart = b;
                    contactsCount = c;
                }
                public void run() {
                    getSomeContacts(mainQueryCursor, blockStart, contactsCount, contentResolver);
                }
            }

            while (currentBlock < mainQueryCursor.getCount()) {
                Thread thread = new Thread(new ContactRunnable(currentBlock, contactsCount));
                thread.start();
                currentBlock = currentBlock + 100;
            }
        }
    }

    static void getSomeContacts(Cursor c, int blockStart, int contactsCount, ContentResolver contentResolver) {
        Map responseMessage = new HashMap();
        responseMessage.put("contactsCount", contactsCount);

        List contacts = new LinkedList();
        int blockEnd = blockStart;

        for (int i = blockStart; i < (blockStart + 100) && (i < c.getCount()); i++) {
            c.moveToPosition(i);
            Map contact = new HashMap();

            // id, name, organization, starred, icon
            // email.home, email.work, email.mobile
            // phone.home, phone.work, phone.mobile

            String id = c.getString(c.getColumnIndex(ContactsContract.Contacts._ID));
            contact.put("id", id);
            String name = c.getString(c.getColumnIndex(ContactsContract.Contacts.DISPLAY_NAME_PRIMARY));
            contact.put("name", name);

            int starred = c.getInt(c.getColumnIndex(ContactsContract.Contacts.STARRED));
            boolean isStarred = starred == 1 ? true : false;
            contact.put("starred", isStarred);

            // get the user's email address
            Cursor ce = contentResolver.query(ContactsContract.CommonDataKinds.Email.CONTENT_URI,
                                              null,
                                              ContactsContract.CommonDataKinds.Email.CONTACT_ID + " = ?",
                                              new String[]{id},
                                              null);
            while (ce.moveToNext()) {
                String address = ce.getString(ce.getColumnIndex(ContactsContract.CommonDataKinds.Email.DATA));
                int addressType = ce.getInt(ce.getColumnIndex(Email.TYPE));
                switch (addressType) {
                    case Email.TYPE_HOME:
                        contact.put("email.home", address);
                        break;
                    case Email.TYPE_WORK:
                        contact.put("email.work", address);
                        break;
                    default:
                        contact.put("email.other", address);
                        break;
                }
            }
            ce.close();

            // get the user's phone number
            Cursor cp = contentResolver.query(ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                                              null,
                                              ContactsContract.CommonDataKinds.Phone.CONTACT_ID + " = ?",
                                              new String[]{id},
                                              null);
            while (cp.moveToNext()) {
                String number = cp.getString(cp.getColumnIndex(Phone.NUMBER)).replace(" ","");
                int numberType = cp.getInt(cp.getColumnIndex(Phone.TYPE));

                if (startsWithAny(number, mobilePreDialNumbers)) {
                    numberType = Phone.TYPE_MOBILE;
                }

                switch (numberType) {
                    case Phone.TYPE_HOME:
                        contact.put("phone.home", number);
                        break;
                    case Phone.TYPE_MOBILE:
                        contact.put("phone.mobile", number);
                        break;
                    case Phone.TYPE_WORK:
                        contact.put("phone.work", number);
                        break;
                    default:
                        contact.put("phone.other", number);
                        break;
                }
            }
            cp.close();

            // get the user's organization
            Cursor co = contentResolver.query(ContactsContract.Data.CONTENT_URI,
                                              null,
                                              ContactsContract.Data.CONTACT_ID + "=? AND " + ContactsContract.Data.MIMETYPE + "=?",
                                              new String[] { id, ContactsContract.CommonDataKinds.Organization.CONTENT_ITEM_TYPE },
                                              null);
            if (co.moveToFirst()) {
                String organization = co.getString(co.getColumnIndex(ContactsContract.CommonDataKinds.Organization.COMPANY));
                contact.put("organization", organization);
            }
            co.close();

            // get the user's signal number
            Cursor cs = contentResolver.query(
                    ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                    new String[]{ContactsContract.CommonDataKinds.Phone.CONTACT_ID,
                            ContactsContract.CommonDataKinds.Phone.NUMBER,
                            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME},
                    ContactsContract.CommonDataKinds.Phone.CONTACT_ID + " =? AND account_type=?",
                    new String[]{id, "org.thoughtcrime.securesms"}, null);

            if (cs.moveToFirst()) {
                String signal_number = cs.getString(cs.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER));
                contact.put("phone.signal", signal_number.replace(" ", ""));
            }
            cs.close();

            blockEnd = i;

            contacts.add(contact);
        }

//        if (blockEnd == c.getCount() - 1) {
//            c.close();
//        }

        responseMessage.put("contacts", contacts);
        responseMessage.put("blockStart", blockStart);
        responseMessage.put("blockEnd", blockEnd);

        SystemDispatcher.dispatch("volla.launcher.contactResponse", responseMessage);
    }

    static void getContactImage(Map message, Activity activity) {
        Log.d(TAG, "getContactImage called");

        Map responseMessage = new HashMap();

        String contactId = (String) message.get("contactId");
        responseMessage.put("contactId", contactId);

        Uri contactUri = Uri.withAppendedPath(ContactsContract.Contacts.CONTENT_URI, contactId);
        ContentResolver contentResolver = activity.getContentResolver();
        InputStream input = ContactsContract.Contacts.openContactPhotoInputStream(contentResolver, contactUri);
        Bitmap bitmap = BitmapFactory.decodeStream(input);
        if (bitmap != null) {
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, baos);
            byte[] imageBytes = baos.toByteArray();
            String icon = Base64.encodeToString(imageBytes, Base64.NO_WRAP);
            responseMessage.put("icon", icon);
            responseMessage.put("hasIcon", true);
        } else {
            responseMessage.put("hasIcon", false);
        }

        SystemDispatcher.dispatch("volla.launcher.contactImageResponse", responseMessage);
    }

    static void checkContacts(Map message, Activity activity) {
        Log.d(TAG, "Check contacts since " + (double)message.get("timestamp"));

        Map responseMessage = new HashMap();

        ContentResolver contentResolver = activity.getContentResolver();
        String[] mainQueryProjection = {
            ContactsContract.Contacts._ID,
            ContactsContract.Contacts.DISPLAY_NAME_PRIMARY,
            ContactsContract.Contacts.STARRED
        };
        String mainQuerySelection = ContactsContract.Contacts.IN_VISIBLE_GROUP + " = ? and "
                                    + ContactsContract.Contacts.CONTACT_LAST_UPDATED_TIMESTAMP + " > ? ";
        String[] mainQuerySelectionArgs = new String[]{"1", String.valueOf((double) message.get("timestamp"))};
        String mainQuerySortOrder = String.format("%1$s COLLATE NOCASE", ContactsContract.Contacts.DISPLAY_NAME_PRIMARY);

        Cursor mainQueryCursor = contentResolver.query(
                        ContactsContract.Contacts.CONTENT_URI,
                        mainQueryProjection,
                        mainQuerySelection,
                        mainQuerySelectionArgs,
                        mainQuerySortOrder);

        boolean needsSync = false;

        if (mainQueryCursor != null) {
            Log.d("ContactWorker", "Number of contacts: " + mainQueryCursor.getCount());
            needsSync = mainQueryCursor.getCount() > 0;
        }

        responseMessage.put("needsSync", needsSync);
        responseMessage.put("newContactsCount", mainQueryCursor.getCount());

        SystemDispatcher.dispatch("volla.launcher.checkContactResponse", responseMessage);
    }

    static boolean startsWithAny(String number, String... preDialNumbers) {
        if (number != null && number.length() > 0) {
            int length = preDialNumbers.length;

            for (int i = 0; i < length; ++i) {
                String preDialNumber = preDialNumbers[i];
                if (number.startsWith(preDialNumber)) {
                    return true;
                }
            }
        }
        return false;
    }

}
