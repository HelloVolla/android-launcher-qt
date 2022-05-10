package com.volla.launcher.storage;

import android.os.AsyncTask;

import androidx.lifecycle.MutableLiveData;

import java.util.List;

public class MessageRepository {

    private MutableLiveData<List<Message>> messages = new MutableLiveData<>();

    private void asyncFinished(List<Message> results) {
        messages.setValue(results);
    }

    private static class QueryAsyncTask extends AsyncTask<String, Void, List<Message>> {

        private MessageDao messageDao;
        public MessageRepository delegate = null;

        public QueryAsyncTask(MessageDao messageDao) {
            this.messageDao = messageDao;
        }

        @Override
        protected List<Message> doInBackground(String... strings) {
            //return messageDao.getAllMessages();
            return null;
        }
    }
}
