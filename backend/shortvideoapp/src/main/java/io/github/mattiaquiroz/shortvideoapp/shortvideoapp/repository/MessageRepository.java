package io.github.mattiaquiroz.shortvideoapp.shortvideoapp.repository;

import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.entity.Message;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MessageRepository extends JpaRepository<Message, Long> {
    
    // Find all messages between two users (both directions)
    @Query("SELECT m FROM Message m WHERE (m.sender = :user1 AND m.receiver = :user2) OR (m.sender = :user2 AND m.receiver = :user1) ORDER BY m.createdAt ASC")
    List<Message> findConversationBetweenUsers(@Param("user1") User user1, @Param("user2") User user2);
    
    // Find all conversations for a user (get the latest message from each conversation)
    @Query("SELECT DISTINCT m FROM Message m WHERE m.id IN (" +
           "SELECT MAX(m2.id) FROM Message m2 WHERE " +
           "(m2.sender = :user OR m2.receiver = :user) " +
           "GROUP BY CASE WHEN m2.sender = :user THEN m2.receiver.id ELSE m2.sender.id END) " +
           "ORDER BY m.createdAt DESC")
    List<Message> findConversationsForUser(@Param("user") User user);
    
    // Count unread messages for a user
    @Query("SELECT COUNT(m) FROM Message m WHERE m.receiver = :user AND m.isRead = false")
    Long countUnreadMessagesForUser(@Param("user") User user);
    
    // Count unread messages from a specific sender
    @Query("SELECT COUNT(m) FROM Message m WHERE m.sender = :sender AND m.receiver = :receiver AND m.isRead = false")
    Long countUnreadMessagesFromSender(@Param("sender") User sender, @Param("receiver") User receiver);
    
    // Find messages sent by a user
    @Query("SELECT m FROM Message m WHERE m.sender = :user ORDER BY m.createdAt DESC")
    List<Message> findMessagesSentByUser(@Param("user") User user);
    
    // Find messages received by a user
    @Query("SELECT m FROM Message m WHERE m.receiver = :user ORDER BY m.createdAt DESC")
    List<Message> findMessagesReceivedByUser(@Param("user") User user);
    
    // Mark messages as read
    @Query("UPDATE Message m SET m.isRead = true WHERE m.sender = :sender AND m.receiver = :receiver AND m.isRead = false")
    @org.springframework.data.jpa.repository.Modifying
    @org.springframework.transaction.annotation.Transactional
    void markMessagesAsRead(@Param("sender") User sender, @Param("receiver") User receiver);
    
    // Find messages that reply to a specific message
    @Query("SELECT m FROM Message m WHERE m.replyTo = :message")
    List<Message> findMessagesReplyingTo(@Param("message") Message message);
} 