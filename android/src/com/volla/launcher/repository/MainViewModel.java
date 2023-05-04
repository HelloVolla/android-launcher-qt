package com.volla.launcher.repository;

import android.app.Application;

import androidx.annotation.NonNull;
import androidx.lifecycle.AndroidViewModel;

import com.volla.launcher.storage.Message;
import com.volla.launcher.storage.Users;

import java.util.List;

import io.reactivex.rxjava3.core.Maybe;

public class MainViewModel extends AndroidViewModel {

    private MessageRepository repository;

    public MainViewModel(@NonNull Application application) {
        super(application);
        repository = new MessageRepository(application);
    }

    public Maybe<List<Message>> getMessages() {
        return repository.getAllMessages();
    }

    public Maybe<List<Message>> getMessageListBySender() {
        return repository.getMessageListBySender();
    }

    public Maybe<List<Message>> getAllMessageByThreadId(String threadId, int pageSize) {
        return repository.getAllMessageByThreadId(threadId, pageSize);
    }

    public Maybe<List<Message>> getAllMessageByPersonName(String name, int pageSize) {
        return repository.getAllMessageByPersonName(name, pageSize);
    }

    public Maybe<List<Message>> getAllSendersName() {
        return repository.getAllSendersName();
    }

    public Maybe<List<Users>> getAllUsers() {
        return repository.getAllUsers();
    }
    public Maybe<Users> getReplyNotification(String uuid) {
        return repository.getReplyNotification(uuid);
    }
//    public DataSource.Factory<Integer, Message>  getAllMessageBySender() {
//        return repository.getAllMessageBySender();
//    }
}
