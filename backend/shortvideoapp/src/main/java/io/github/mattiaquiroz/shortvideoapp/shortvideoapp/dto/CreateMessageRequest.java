package io.github.mattiaquiroz.shortvideoapp.shortvideoapp.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public class CreateMessageRequest {
    
    @NotNull(message = "Receiver ID is required")
    private Long receiverId;
    
    @NotBlank(message = "Message content is required")
    private String content;
    
    private Long replyToId; // ID of the message being replied to
    
    private String reaction; // Emoji reaction
    private String messageType; // Message type: chat or video

    public CreateMessageRequest() {}

    public CreateMessageRequest(Long receiverId, String content) {
        this.receiverId = receiverId;
        this.content = content;
    }

    public CreateMessageRequest(Long receiverId, String content, Long replyToId) {
        this.receiverId = receiverId;
        this.content = content;
        this.replyToId = replyToId;
    }

    // Getters and Setters
    public Long getReceiverId() {
        return receiverId;
    }

    public void setReceiverId(Long receiverId) {
        this.receiverId = receiverId;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public Long getReplyToId() {
        return replyToId;
    }

    public void setReplyToId(Long replyToId) {
        this.replyToId = replyToId;
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
} 