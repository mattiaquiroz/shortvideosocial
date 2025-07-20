package io.github.mattiaquiroz.shortvideoapp.shortvideoapp.dto;

import java.time.LocalDateTime;

public class MessageDTO {
    private Long id;
    private String content;
    private UserDTO sender;
    private UserDTO receiver;
    private MessageDTO replyTo;
    private String reaction;
    private String messageType; // Message type: chat or video
    private boolean isRead;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public MessageDTO() {}

    public MessageDTO(Long id, String content, UserDTO sender, UserDTO receiver, 
                     MessageDTO replyTo, String reaction, String messageType, boolean isRead, 
                     LocalDateTime createdAt, LocalDateTime updatedAt) {
        this.id = id;
        this.content = content;
        this.sender = sender;
        this.receiver = receiver;
        this.replyTo = replyTo;
        this.reaction = reaction;
        this.messageType = messageType;
        this.isRead = isRead;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public UserDTO getSender() {
        return sender;
    }

    public void setSender(UserDTO sender) {
        this.sender = sender;
    }

    public UserDTO getReceiver() {
        return receiver;
    }

    public void setReceiver(UserDTO receiver) {
        this.receiver = receiver;
    }

    public MessageDTO getReplyTo() {
        return replyTo;
    }

    public void setReplyTo(MessageDTO replyTo) {
        this.replyTo = replyTo;
    }

    public String getReaction() {
        return reaction;
    }

    public void setReaction(String reaction) {
        this.reaction = reaction;
    }

    public String getMessageType() {
        return messageType;
    }

    public void setMessageType(String messageType) {
        this.messageType = messageType;
    }

    public boolean isRead() {
        return isRead;
    }

    public void setRead(boolean read) {
        isRead = read;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
} 