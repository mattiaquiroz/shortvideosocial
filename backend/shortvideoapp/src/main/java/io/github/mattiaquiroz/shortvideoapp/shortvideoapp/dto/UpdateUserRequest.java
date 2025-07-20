package io.github.mattiaquiroz.shortvideoapp.shortvideoapp.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class UpdateUserRequest {
    
    private String username;

    private String email;

    private String fullName;
    private String bio;
    private String profilePictureUrl;
    private Boolean privateAccount;

    public UpdateUserRequest() {}

    public UpdateUserRequest(String username, String email, String fullName, String bio, String profilePictureUrl, Boolean privateAccount) {
        this.username = username;
        this.email = email;
        this.fullName = fullName;
        this.bio = bio;
        this.profilePictureUrl = profilePictureUrl;
        this.privateAccount = privateAccount;
    }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getBio() { return bio; }
    public void setBio(String bio) { this.bio = bio; }

    public String getProfilePictureUrl() { return profilePictureUrl; }
    public void setProfilePictureUrl(String profilePictureUrl) { this.profilePictureUrl = profilePictureUrl; }

    public Boolean getPrivateAccount() { return privateAccount; }
    public void setPrivateAccount(Boolean privateAccount) { this.privateAccount = privateAccount; }
} 