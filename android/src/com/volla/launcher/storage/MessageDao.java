package com.volla.launcher.storage;

import androidx.room.Dao;
import androidx.room.Query;

@Dao
public interface MessageDao {

    @Query("SELECT * FROM messages WHERE title = :title")
    public Message[] getAllMessageBySender(String title);
}
