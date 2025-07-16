package io.github.mattiaquiroz.shortvideoapp.shortvideoapp.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class CreateCommentRequest {
    @NotBlank(message = "Comment text is required")
    @Size(max = 500, message = "Comment must not exceed 500 characters")
    private String text;
    
    private Long parentCommentId; // Optional: ID of parent comment if this is a reply

    public CreateCommentRequest() {}

    public CreateCommentRequest(String text) {
        this.text = text;
    }

    public CreateCommentRequest(String text, Long parentCommentId) {
        this.text = text;
        this.parentCommentId = parentCommentId;
    }

    public String getText() {
        return text;
    }

    public void setText(String text) {
        this.text = text;
    }

    public Long getParentCommentId() {
        return parentCommentId;
    }

    public void setParentCommentId(Long parentCommentId) {
        this.parentCommentId = parentCommentId;
    }
} 