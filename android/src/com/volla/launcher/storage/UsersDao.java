package com.volla.launcher.storage;

import androidx.room.Dao;
import androidx.room.Insert;
import androidx.room.OnConflictStrategy;
import androidx.room.Query;

import java.util.List;

import io.reactivex.rxjava3.core.Completable;
import io.reactivex.rxjava3.core.Maybe;

@Dao
public interface UsersDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    Completable insertUser(Users user); // working

    @Query("SELECT * FROM users WHERE timeStamp > :age ORDER BY timeStamp DESC")
    Maybe<List<Users>> getAllUsers(long age);

    @Query("SELECT * FROM users WHERE uuid = :uuid")
    Maybe<Users> getReplyNotification(String uuid);

    @Query("DELETE FROM users WHERE timeStamp < :threadAge")
    void deleteAllThreadsHavingTimeStampLessThen(long threadAge);

     @Query("UPDATE users SET read = true WHERE user_name = :thread_id")
     void updateReadStatusInUserTableUsingThreadId(String thread_id);

     @Query("UPDATE users SET read = true WHERE uuid = :uuid")
     void updateReadStatusInUserTableUsingName(String uuid);


//    @Query("SELECT * FROM users WHERE title IN ('Thanos ', 'Arvind Yadav') GROUP BY title ORDER BY timeStamp ASC ")
//    Maybe<List<Message>> getMessageListBySender();
//
//    @Query("SELECT title FROM messages GROUP BY title ORDER BY title ASC")
//    Maybe<List<String>> getAllSendersName(); // working
}
