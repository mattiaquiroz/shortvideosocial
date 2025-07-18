package io.github.mattiaquiroz.shortvideoapp.shortvideoapp.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class CreateVideoRequest {
    @Size(max = 100, message = "Description must not exceed 100 characters")
    private String description;

    @NotBlank(message = "Video URL is required")
    private String videoUrl;

    private String thumbnailUrl;
    private Integer durationSeconds;
    private Boolean isPublic = true;

    public CreateVideoRequest() {}

    public CreateVideoRequest(String description, String videoUrl, String thumbnailUrl, 
                              Integer durationSeconds, Boolean isPublic) {
        this.description = description;
        this.videoUrl = videoUrl;
        this.thumbnailUrl = thumbnailUrl;
        this.durationSeconds = durationSeconds;
        this.isPublic = isPublic;
    }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getVideoUrl() { return videoUrl; }
    public void setVideoUrl(String videoUrl) { this.videoUrl = videoUrl; }

    public String getThumbnailUrl() { return thumbnailUrl; }
    public void setThumbnailUrl(String thumbnailUrl) { this.thumbnailUrl = thumbnailUrl; }

    public Integer getDurationSeconds() { return durationSeconds; }
    public void setDurationSeconds(Integer durationSeconds) { this.durationSeconds = durationSeconds; }

    public Boolean getIsPublic() { return isPublic; }
    public void setIsPublic(Boolean isPublic) { this.isPublic = isPublic; }
} 