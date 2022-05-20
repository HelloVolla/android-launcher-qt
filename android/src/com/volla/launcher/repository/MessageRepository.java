package com.volla.launcher.repository;

import android.app.Application;
import android.os.AsyncTask;

import androidx.lifecycle.MutableLiveData;

import com.volla.launcher.storage.Message;
import com.volla.launcher.storage.MessageDao;
import com.volla.launcher.storage.MessageDatabase;

import java.util.List;

import io.reactivex.rxjava3.core.Maybe;
import io.reactivex.rxjava3.schedulers.Schedulers;

public class MessageRepository {

    private MessageDao messageDao;

    public MessageRepository(Application application) {
        messageDao = MessageDatabase.getInstance(application).messageDao();
    }

    public Maybe<List<Message>> getAllMessages() {
        return messageDao.getAllMessages().observeOn(Schedulers.io()).subscribeOn(Schedulers.io());
    }

    public Maybe<List<Message>> getMessageListBySender() {
        return messageDao.getMessageListBySender().observeOn(Schedulers.io()).subscribeOn(Schedulers.io());
    }

    public Maybe<List<Message>> getAllMessageBySender(String title, int pageSize) {
        return messageDao.getAllMessageBySender(title, pageSize).observeOn(Schedulers.io()).subscribeOn(Schedulers.io());
    }

    public Maybe<List<String>> getAllSendersName() {
        return messageDao.getAllSendersName().observeOn(Schedulers.io()).subscribeOn(Schedulers.io());
    }

//    public DataSource.Factory<Integer, Message> getAllMessageBySender() {
//        DataSource.Factory<Integer, Message> factory=
//                messageDao.getAllMessageBySender();
//        LivePagedListBuilder<Integer, Message> pagedListBuilder=
//                new LivePagedListBuilder<>(factory, 50);
//
//
//        //return messageDao.getAllMessageBySender().observeOn(Schedulers.io()).subscribeOn(Schedulers.io());
//    }

    public void insertMessage(Message message) {
        messageDao.insertMessage(message).observeOn(Schedulers.io()).subscribeOn(Schedulers.io()).subscribe();
    }

}
