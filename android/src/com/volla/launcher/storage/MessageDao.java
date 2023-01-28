package com.volla.launcher.storage;

import androidx.room.Dao;
import androidx.room.Insert;
import androidx.room.OnConflictStrategy;
import androidx.room.Query;

import java.util.List;
import io.reactivex.rxjava3.core.Completable;
import io.reactivex.rxjava3.core.Maybe;
@Dao
public interface MessageDao {

    @Query("SELECT * FROM messages WHERE uuid = :title ORDER BY timeStamp DESC LIMIT :pageSize")
    Maybe<List<Message>> getAllMessageBySender(String title, int pageSize); // working
    //@Query("SELECT * FROM messages")
    //DataSource.Factory<Integer, Message> getAllMessageBySender();
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    Completable insertMessage(Message message); // working
    @Query("SELECT * FROM messages ORDER BY timeStamp DESC")
    Maybe<List<Message>> getAllMessages(); //working
    @Query("SELECT * FROM messages WHERE title IN ('Thanos Gupta', 'Arvind Yadav') GROUP BY title ORDER BY timeStamp ASC ")
    Maybe<List<Message>> getMessageListBySender();
    @Query("SELECT * FROM messages GROUP BY title ORDER BY title ASC")
    Maybe<List<Message>> getAllSendersName(); // working
}
