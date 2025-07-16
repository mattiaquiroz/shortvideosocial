package io.github.mattiaquiroz.shortvideoapp.shortvideoapp.dto;

import java.time.LocalDateTime;
import java.util.List;

public class CommentDTO {
    private Long id;
    private String text;
    private Integer likesCount;
    private boolean isLiked; // Whether current user has liked this comment
    private LocalDateTime createdAt;
    private UserDTO user;
    private Long parentCommentId; // ID of parent comment if this is a reply
    private List<CommentDTO> replies; // List of replies to this comment

    public CommentDTO() {}

    public CommentDTO(Long id, String text, Integer likesCount, boolean isLiked, 
                      LocalDateTime createdAt, UserDTO user, Long parentCommentId, 
                      List<CommentDTO> replies) {
        this.id = id;
        this.text = text;
        this.likesCount = likesCount;
        this.isLiked = isLiked;
        this.createdAt = createdAt;
        this.user = user;
        this.parentCommentId = parentCommentId;
        this.replies = replies;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getText() {
        return text;
    }

    public void setText(String text) {
        this.text = text;
    }

    public Integer getLikesCount() {
        return likesCount;
    }

    public void setLikesCount(Integer likesCount) {
        this.likesCount = likesCount;
    }

    public boolean getIsLiked() {
        return isLiked;
    }

    public void setIsLiked(boolean isLiked) {
        this.isLiked = isLiked;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public UserDTO getUser() {
        return user;
    }

    public void setUser(UserDTO user) {
        this.user = user;
    }

    public Long getParentCommentId() {
        return parentCommentId;
    }

    public void setParentCommentId(Long parentCommentId) {
        this.parentCommentId = parentCommentId;
    }

    public List<CommentDTO> getReplies() {
        return replies;
    }

    public void setReplies(List<CommentDTO> replies) {
        this.replies = replies;
    }
} 