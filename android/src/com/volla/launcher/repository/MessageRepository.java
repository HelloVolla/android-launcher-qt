package com.volla.launcher.repository;

import android.app.Application;
import android.os.AsyncTask;
import android.util.Log;
import androidx.lifecycle.MutableLiveData;

import com.volla.launcher.storage.Message;
import com.volla.launcher.storage.MessageDao;
import com.volla.launcher.storage.MessageDatabase;
import com.volla.launcher.storage.Users;
import com.volla.launcher.storage.UsersDao;

import java.util.List;

import io.reactivex.rxjava3.core.Maybe;
import io.reactivex.rxjava3.core.Scheduler;
import io.reactivex.rxjava3.schedulers.Schedulers;

public class MessageRepository {

    private MessageDao messageDao;
    private UsersDao usersDao;

    public MessageRepository(Application application) {
        MessageDatabase database = MessageDatabase.getInstance(application);
        messageDao = database.messageDao();
        usersDao = database.usersDao();
    }

    public Maybe<List<Message>> getAllMessages() {
        return messageDao.getAllMessages().observeOn(Schedulers.io()).subscribeOn(Schedulers.io());
    }

    public Maybe<List<Message>> getMessageListBySender() {
        return messageDao.getMessageListBySender().observeOn(Schedulers.io()).subscribeOn(Schedulers.io());
    }

    public Maybe<List<Message>> getAllMessageByThreadId(String threadId, long pageSize) {
        return messageDao.getAllMessageByThreadId(threadId, pageSize).observeOn(Schedulers.io()).subscribeOn(Schedulers.io());
    }

    public Maybe<List<Message>> getAllMessageByPersonName(String personName, long pageSize) {
        return messageDao.getAllMessageByPersonName(personName, pageSize).observeOn(Schedulers.io()).subscribeOn(Schedulers.io());
    }

    public void deleteAllMessagesHavingTimeStampLessThen(long age) {
        messageDao.deleteAllMessagesHavingTimeStampLessThen(age);
    }

    public Maybe<List<Message>> getAllSendersName() {
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
        Log.d("VollaNotification Inserting repository data","");
        messageDao.insertMessage(message).observeOn(Schedulers.io()).subscribeOn(Schedulers.io()).subscribe();
        Log.d("VollaNotification repository data inserted","");
    }
	public void insertUser(Users users) {
        usersDao.insertUser(users).observeOn(Schedulers.io()).subscribeOn(Schedulers.io()).subscribe();
		Log.d("VollaNotification Inserted Users","");
    }

    public void deleteAllThreadsHavingTimeStampLessThen(long threadAge) {
            Log.d("VollaNotification Calling deleteAllThreadsHavingTimeStampLessThen","");
            usersDao.deleteAllThreadsHavingTimeStampLessThen(threadAge);
    }

    public void updateReadStatusInUserTableUsingThreadId(String threadId) {
        usersDao.updateReadStatusInUserTableUsingThreadId(threadId);
    }

    public void updateReadStatusInUserTableUsingName(String uuid) { 
        usersDao.updateReadStatusInUserTableUsingName(uuid);
    }

public Maybe<List<Users>> getAllUsers(long age) {
        Log.d("VollaNotification Calling getAllUsers","");
    return usersDao.getAllUsers(age).observeOn(Schedulers.io()).subscribeOn(Schedulers.io());
}

    public Maybe<Users> getReplyNotification(String uuid) {
	    Log.d("VollaNotification Calling getReplyNotification","");   
        return usersDao.getReplyNotification(uuid).observeOn(Schedulers.io()).subscribeOn(Schedulers.io());
    }

}
