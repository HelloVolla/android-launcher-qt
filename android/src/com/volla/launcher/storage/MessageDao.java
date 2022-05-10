package com.volla.launcher.storage;

import androidx.lifecycle.LiveData;
import androidx.room.Dao;
import androidx.room.Insert;
import androidx.room.OnConflictStrategy;
import androidx.room.Query;

import java.util.List;
@Dao
public interface MessageDao {

    @Query("SELECT * FROM messages WHERE title = :title LIMIT 10")
    public Message[] getAllMessageBySender(String title);
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    public void insertMessage(Message message);
    @Query("SELECT * FROM messages")
    List<Message> getAllMessages();
}
