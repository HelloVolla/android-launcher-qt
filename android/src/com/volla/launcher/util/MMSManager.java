package com.volla.launcher.util;

import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;
import java.lang.Runtime;
import android.content.Context;
import android.content.Intent;
import android.text.TextUtils;
import android.os.Build;
import android.graphics.Bitmap;
import android.util.Log;
import android.net.Uri;
import com.klinker.android.send_message.BroadcastUtils;
import com.klinker.android.send_message.ApnUtils;
import com.klinker.android.send_message.Message;
import com.klinker.android.send_message.Transaction;
import com.klinker.android.send_message.Utils;
import com.klinker.android.logger.OnLogListener;
import com.volla.launcher.util.Settings;

public class MMSManager {
    private static final String TAG = "MMSManager";
    private static ThreadPoolExecutor mThreadManager;
    private static MMSManager INSTANCE;
    private static BlockingQueue<Runnable> decodeWorkQueue;
    private static int NUMBER_OF_CORES =
            Runtime.getRuntime().availableProcessors();
    private Settings mSettings;
    private Context mContext;

    private MMSManager(Context c) {
        mContext = c;
        initSettings();
        initLogging();
        // A queue of Runnables
        decodeWorkQueue = new LinkedBlockingQueue<Runnable>();
        // setting the thread factory
        mThreadManager = new ThreadPoolExecutor(NUMBER_OF_CORES, NUMBER_OF_CORES,
                50, TimeUnit.MILLISECONDS, decodeWorkQueue);

        BroadcastUtils.sendExplicitBroadcast(c, new Intent(), "test action");
    }

    //See https://stackoverflow.com/questions/14057273/android-singleton-with-global-context
    private static synchronized MMSManager getSync(Context c) {
        if (INSTANCE == null) INSTANCE = new MMSManager(c);
        return INSTANCE;
    }

    public static MMSManager getInstance(Context c) {
        if (INSTANCE == null) {
            INSTANCE = getSync(c);
        }
        return INSTANCE;
    }

    private void initSettings() {
        mSettings = Settings.get(mContext);

        if (TextUtils.isEmpty(mSettings.getMmsc()) &&
                Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
            initApns();
        }
    }

    private void initApns() {
        ApnUtils.initDefaultApns(mContext, new ApnUtils.OnApnFinishedListener() {
            @Override
            public void onFinished() {
                mSettings = Settings.get(mContext, true);
            }
        });
    }

    private void initLogging() {
        com.klinker.android.logger.Log.setDebug(true);
        com.klinker.android.logger.Log.setPath("messenger_log.txt");
        com.klinker.android.logger.Log.setLogListener(new OnLogListener() {
            @Override
            public void onLogged(String tag, String message) {
                //logAdapter.addItem(tag + ": " + message);
                android.util.Log.d("MMS_Manager " + tag, "onLogged: " + message);
            }
        });
    }

    //Not sure what exception might pop up but it's being handled anyway...
    public void sendMMS(String phoneNumber, String text, Bitmap bm) {
        final String t = text;
        final String p = phoneNumber;
        final Bitmap b = bm;
        mThreadManager.execute(new Runnable() {
            @Override
            public void run() {
                Log.d("ThreadPool/MMSManager", "Trying to send MMS.");
                com.klinker.android.send_message.Settings sendSettings = new com.klinker.android.send_message.Settings();
                sendSettings.setMmsc(mSettings.getMmsc());
                sendSettings.setProxy(mSettings.getMmsProxy());
                sendSettings.setPort(mSettings.getMmsPort());
                sendSettings.setUseSystemSending(true);

                Transaction transaction = new Transaction(mContext, sendSettings);

                Message message = new Message(t, p);

                if (b != null)
                    message.setImage(b);

                message.setFromAddress(Utils.getMyPhoneNumber(mContext));
                message.setSave(false);
                Uri uri = Uri.parse("content://mms-sms/conversations/");
                message.setMessageUri(uri);

                transaction.sendNewMessage(message, Transaction.NO_THREAD_ID);
            }
        });
    }
}
