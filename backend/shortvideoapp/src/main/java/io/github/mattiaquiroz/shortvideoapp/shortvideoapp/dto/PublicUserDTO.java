package io.github.mattiaquiroz.shortvideoapp.shortvideoapp.dto;

import java.time.LocalDateTime;

public class PublicUserDTO {
    private Long id;
    private String username;
    private String fullName;
    private String profilePictureUrl;
    private String bio;
    private Integer followersCount;
    private Integer followingCount;
    private LocalDateTime createdAt;

    public PublicUserDTO() {}

    public PublicUserDTO(Long id, String username, String fullName, 
                         String profilePictureUrl, String bio, Integer followersCount, 
                         Integer followingCount, LocalDateTime createdAt) {
        this.id = id;
        this.username = username;
        this.fullName = fullName;
        this.profilePictureUrl = profilePictureUrl;
        this.bio = bio;
        this.followersCount = followersCount;
        this.followingCount = followingCount;
        this.createdAt = createdAt;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getProfilePictureUrl() { return profilePictureUrl; }
    public void setProfilePictureUrl(String profilePictureUrl) { this.profilePictureUrl = profilePictureUrl; }

    public String getBio() { return bio; }
    public void setBio(String bio) { this.bio = bio; }

    public Integer getFollowersCount() { return followersCount; }
    public void setFollowersCount(Integer followersCount) { this.followersCount = followersCount; }

    public Integer getFollowingCount() { return followingCount; }
    public void setFollowingCount(Integer followingCount) { this.followingCount = followingCount; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
} 