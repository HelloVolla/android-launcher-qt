package com.volla.launcher.worker;

import androidnative.SystemDispatcher;
import android.app.Activity;
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

    static {
        SystemDispatcher.addListener(new SystemDispatcher.Listener() {

            public void onDispatched(String type, Map message) {

                Log.d("ContactWorker | onDispatched", type);

                final Activity activity = QtNative.activity();

                if (type.equals("volla.launcher.contactAction")) {

                    Log.d("ContactWorker | onDispatched", "Go");

                    // Process then dispatch a response back to C++/QML
                    Map responseMessage = new HashMap();
                    List contacts = new LinkedList();

                    ContentResolver contentResolver = activity.getContentResolver();
                    String[] mainQueryProjection = {
                        ContactsContract.Contacts._ID,
                        ContactsContract.Contacts.DISPLAY_NAME_PRIMARY,
                        ContactsContract.Contacts.STARRED
                    };
                    String mainQuerySelection = ContactsContract.Contacts.IN_VISIBLE_GROUP + " = ?";
                    String[] mainQuerySelectionArgs = new String[]{"1"};
                    String mainQuerySortOrder = String.format("%1$s COLLATE NOCASE", ContactsContract.Contacts.DISPLAY_NAME_PRIMARY);

                    Cursor mainQueryCursor = contentResolver.query(
                                    ContactsContract.Contacts.CONTENT_URI,
                                    mainQueryProjection,
                                    mainQuerySelection,
                                    mainQuerySelectionArgs,
                                    mainQuerySortOrder);

                    if (mainQueryCursor != null) {
                        while (mainQueryCursor.moveToNext()) {
                            Map contact = new HashMap();

                            // id, name, organization, starred, icon
                            // email.home, email.work, email.mobile
                            // phone.home, phone.work, email.mobile

                            String id = mainQueryCursor.getString(mainQueryCursor.getColumnIndex(ContactsContract.Contacts._ID));
                            contact.put("id", id);
                            String name = mainQueryCursor.getString(mainQueryCursor.getColumnIndex(ContactsContract.Contacts.DISPLAY_NAME_PRIMARY));
                            contact.put("name", name);

                            int starred = mainQueryCursor.getInt(mainQueryCursor.getColumnIndex(ContactsContract.Contacts.STARRED));
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
                                    case Email.TYPE_OTHER:
                                        contact.put("email.mobile", address);
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
                                String number = cp.getString(cp.getColumnIndex(Phone.NUMBER));
                                int numberType = cp.getInt(cp.getColumnIndex(Phone.TYPE));
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

                            // get the user's icon
                            Uri contactUri = Uri.withAppendedPath(ContactsContract.Contacts.CONTENT_URI, id);
                            InputStream input = ContactsContract.Contacts.openContactPhotoInputStream(contentResolver, contactUri);
                            Bitmap bitmap = BitmapFactory.decodeStream(input);
                            if (bitmap != null) {
                                ByteArrayOutputStream baos = new ByteArrayOutputStream();
                                bitmap.compress(Bitmap.CompressFormat.PNG, 100, baos);
                                byte[] imageBytes = baos.toByteArray();
                                String icon = Base64.encodeToString(imageBytes, Base64.NO_WRAP);
                                contact.put("icon", icon);
                            }

                            contacts.add(contact);
                        }

                        mainQueryCursor.close();
                    }

                    responseMessage.put("contacts", contacts);

                    SystemDispatcher.dispatch("volla.launcher.contactResponse", responseMessage);
                }
                else if (type.equals("volla.launcher.checkContactAction")) {

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

                    SystemDispatcher.dispatch("volla.launcher.checkContactResponse", responseMessage);
                }

                return;
            }
        });
    }

}
