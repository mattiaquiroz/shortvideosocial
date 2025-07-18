package io.github.mattiaquiroz.shortvideoapp.shortvideoapp.controller;

import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.entity.Video;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.repository.VideoRepository;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.util.AuthUtil;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.InputStreamResource;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Optional;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.entity.User;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.repository.UserRepository;

@RestController
@RequestMapping("/api/stream")
@Tag(name = "Video Streaming", description = "Video streaming endpoints with range support")
public class VideoStreamingController {

    @Autowired
    private VideoRepository videoRepository;

    @Autowired
    private AuthUtil authUtil;

    @Autowired
    private UserRepository userRepository;

    @GetMapping("/video/{videoId}")
    @Operation(summary = "Stream video", description = "Stream video with range support for seeking")
    public ResponseEntity<Resource> streamVideo(
            @PathVariable Long videoId,
            @RequestHeader(value = "Range", required = false) String rangeHeader,
            HttpServletRequest request) throws IOException {

        // Check authentication from headers
        if (!authUtil.isAuthenticated(request)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        // Get video from database
        Optional<Video> videoOpt = videoRepository.findById(videoId);
        if (videoOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        Video video = videoOpt.get();
        
        // Check if video is public or user has access
        if (!video.getIsPublic()) {
            // Get current user from request
            Optional<User> currentUserOpt = authUtil.getCurrentUser(request);
            if (currentUserOpt.isEmpty() || !video.getUser().getId().equals(currentUserOpt.get().getId())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
            }
        }

        // Construct file path
        String videoPath = video.getVideoUrl();
        if (!videoPath.startsWith("assets/")) {
            videoPath = "assets/" + videoPath;
        }

        Path filePath = Paths.get(videoPath);
        
        if (!Files.exists(filePath)) {
            return ResponseEntity.notFound().build();
        }

        Resource resource = new UrlResource(filePath.toUri());
        if (!resource.exists() || !resource.isReadable()) {
            return ResponseEntity.notFound().build();
        }

        long fileSize = resource.contentLength();
        
        // Determine content type
        String contentType = Files.probeContentType(filePath);
        if (contentType == null) {
            contentType = "video/mp4"; // Default to MP4
        }

        // Handle range requests for video seeking
        if (rangeHeader != null && rangeHeader.startsWith("bytes=")) {
            return handleRangeRequest(resource, rangeHeader, fileSize, contentType);
        }

        // Increment view count
        video.setViewsCount(video.getViewsCount() + 1);
        videoRepository.save(video);

        // Return full file
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(contentType))
                .contentLength(fileSize)
                .header(HttpHeaders.ACCEPT_RANGES, "bytes")
                .body(resource);
    }

    @GetMapping("/thumbnail/{videoId}")
    @Operation(summary = "Get video thumbnail", description = "Get video thumbnail image")
    public ResponseEntity<Resource> getThumbnail(
            @PathVariable Long videoId,
            HttpServletRequest request) throws IOException {

        // Check authentication from headers
        if (!authUtil.isAuthenticated(request)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        Optional<Video> videoOpt = videoRepository.findById(videoId);
        if (videoOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        Video video = videoOpt.get();
        String thumbnailPath = video.getThumbnailUrl();
        
        if (thumbnailPath == null || thumbnailPath.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        if (!thumbnailPath.startsWith("assets/")) {
            thumbnailPath = "assets/" + thumbnailPath;
        }

        Path filePath = Paths.get(thumbnailPath);
        
        if (!Files.exists(filePath)) {
            return ResponseEntity.notFound().build();
        }

        Resource resource = new UrlResource(filePath.toUri());
        if (!resource.exists() || !resource.isReadable()) {
            return ResponseEntity.notFound().build();
        }

        String contentType = Files.probeContentType(filePath);
        if (contentType == null) {
            contentType = "image/jpeg"; // Default to JPEG
        }

        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(contentType))
                .body(resource);
    }

    @GetMapping("/profile-image/{userId}")
    @Operation(summary = "Get user profile image", description = "Get user profile image with authentication")
    public ResponseEntity<Resource> getProfileImage(
            @PathVariable Long userId,
            HttpServletRequest request) throws IOException {

        // Check authentication from headers
        if (!authUtil.isAuthenticated(request)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        // Get user from database
        Optional<User> userOpt = userRepository.findById(userId);
        if (userOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        User user = userOpt.get();
        String profileImagePath = user.getProfilePictureUrl();
        
        // If no profile image set, use default
        if (profileImagePath == null || profileImagePath.isEmpty()) {
            profileImagePath = "assets/users/default_picture.jpg";
        } else {
            // Ensure path starts with assets/
            if (!profileImagePath.startsWith("assets/")) {
                profileImagePath = "assets/users/" + profileImagePath;
            }
        }

        Path filePath = Paths.get(profileImagePath);
        
        // If file doesn't exist, fall back to default
        if (!Files.exists(filePath)) {
            filePath = Paths.get("assets/users/default_picture.jpg");
        }

        Resource resource = new UrlResource(filePath.toUri());
        if (!resource.exists() || !resource.isReadable()) {
            return ResponseEntity.notFound().build();
        }

        String contentType = Files.probeContentType(filePath);
        if (contentType == null) {
            contentType = "image/jpeg"; // Default to JPEG
        }

        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(contentType))
                .header("Cache-Control", "public, max-age=3600") // Cache for 1 hour
                .body(resource);
    }

    private ResponseEntity<Resource> handleRangeRequest(Resource resource, String rangeHeader, 
                                                       long fileSize, String contentType) throws IOException {
        // Parse range header (e.g., "bytes=0-1023")
        String range = rangeHeader.substring(6); // Remove "bytes="
        String[] ranges = range.split("-");
        
        long start = 0;
        long end = fileSize - 1;
        
        if (ranges.length >= 1 && !ranges[0].isEmpty()) {
            start = Long.parseLong(ranges[0]);
        }
        
        if (ranges.length >= 2 && !ranges[1].isEmpty()) {
            end = Long.parseLong(ranges[1]);
        }
        
        // Ensure valid range
        if (start > end || start >= fileSize) {
            return ResponseEntity.status(HttpStatus.REQUESTED_RANGE_NOT_SATISFIABLE)
                    .header(HttpHeaders.CONTENT_RANGE, "bytes */" + fileSize)
                    .build();
        }
        
        // Limit end to file size
        if (end >= fileSize) {
            end = fileSize - 1;
        }
        
        long contentLength = end - start + 1;
        
        // Create InputStreamResource for partial content
        InputStream inputStream = resource.getInputStream();
        inputStream.skip(start);
        InputStreamResource partialResource = new InputStreamResource(inputStream) {
            @Override
            public long contentLength() {
                return contentLength;
            }
        };
        
        return ResponseEntity.status(HttpStatus.PARTIAL_CONTENT)
                .contentType(MediaType.parseMediaType(contentType))
                .contentLength(contentLength)
                .header(HttpHeaders.ACCEPT_RANGES, "bytes")
                .header(HttpHeaders.CONTENT_RANGE, "bytes " + start + "-" + end + "/" + fileSize)
                .body(partialResource);
    }

} 