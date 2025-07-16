package io.github.mattiaquiroz.shortvideoapp.shortvideoapp.controller;

import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.dto.CreateVideoRequest;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.dto.UserDTO;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.dto.VideoDTO;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.entity.Like;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.entity.User;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.entity.Video;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.repository.LikeRepository;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.repository.UserRepository;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.repository.VideoRepository;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.util.AuthUtil;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/videos")
@Tag(name = "Video Management", description = "APIs for managing videos")
public class VideoController {

    @Autowired
    private VideoRepository videoRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private LikeRepository likeRepository;

    @Autowired
    private AuthUtil authUtil;

    @GetMapping
    @Operation(summary = "Get all public videos", description = "Retrieve paginated list of public videos")
    public ResponseEntity<Page<VideoDTO>> getAllVideos(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "recent") String sortBy) {
        
        Pageable pageable = PageRequest.of(page, size);
        Page<Video> videos;
        
        switch (sortBy.toLowerCase()) {
            case "popular":
                videos = videoRepository.findByIsPublicTrueOrderByViewsCountDesc(pageable);
                break;
            case "liked":
                videos = videoRepository.findByIsPublicTrueOrderByLikesCountDesc(pageable);
                break;
            case "recent":
            default:
                videos = videoRepository.findByIsPublicTrueOrderByCreatedAtDesc(pageable);
                break;
        }
        
        Page<VideoDTO> videoDTOs = videos.map(this::convertToDTO);
        return ResponseEntity.ok(videoDTOs);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get video by ID", description = "Retrieve a video by its ID")
    public ResponseEntity<VideoDTO> getVideoById(@PathVariable Long id) {
        Optional<Video> video = videoRepository.findById(id);
        if (video.isPresent()) {
            // Increment view count
            Video v = video.get();
            v.setViewsCount(v.getViewsCount() + 1);
            videoRepository.save(v);
            
            return ResponseEntity.ok(convertToDTO(v));
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @PostMapping
    @Operation(summary = "Create new video", description = "Upload a new video (requires authentication)")
    @SecurityRequirement(name = "bearerAuth")
    public ResponseEntity<?> createVideo(@Valid @RequestBody CreateVideoRequest request, 
                                       HttpServletRequest httpRequest) {
        Optional<User> currentUser = authUtil.getCurrentUser(httpRequest);
        if (currentUser.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Authentication required");
        }

        Video video = new Video();
        video.setDescription(request.getDescription());
        video.setVideoUrl(request.getVideoUrl());
        video.setThumbnailUrl(request.getThumbnailUrl());
        video.setDurationSeconds(request.getDurationSeconds());
        video.setIsPublic(request.getIsPublic());
        video.setUser(currentUser.get());

        Video savedVideo = videoRepository.save(video);
        return ResponseEntity.status(HttpStatus.CREATED).body(convertToDTO(savedVideo));
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update video", description = "Update an existing video")
    public ResponseEntity<?> updateVideo(@PathVariable Long id, @Valid @RequestBody CreateVideoRequest request) {
        Optional<Video> existingVideo = videoRepository.findById(id);
        if (!existingVideo.isPresent()) {
            return ResponseEntity.notFound().build();
        }

        Video video = existingVideo.get();
        video.setDescription(request.getDescription());
        video.setVideoUrl(request.getVideoUrl());
        video.setThumbnailUrl(request.getThumbnailUrl());
        video.setDurationSeconds(request.getDurationSeconds());
        video.setIsPublic(request.getIsPublic());

        Video updatedVideo = videoRepository.save(video);
        return ResponseEntity.ok(convertToDTO(updatedVideo));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete video", description = "Delete a video")
    public ResponseEntity<Void> deleteVideo(@PathVariable Long id) {
        if (!videoRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        videoRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/search")
    @Operation(summary = "Search videos", description = "Search videos by title or description")
    public ResponseEntity<Page<VideoDTO>> searchVideos(
            @RequestParam String query,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        Pageable pageable = PageRequest.of(page, size);
        Page<Video> videos = videoRepository.searchPublicVideos(query, pageable);
        Page<VideoDTO> videoDTOs = videos.map(this::convertToDTO);
        return ResponseEntity.ok(videoDTOs);
    }

    @GetMapping("/user/{userId}")
    @Operation(summary = "Get user's videos", description = "Get all videos uploaded by a specific user")
    public ResponseEntity<Page<VideoDTO>> getUserVideos(
            @PathVariable Long userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        Pageable pageable = PageRequest.of(page, size);
        Page<Video> videos = videoRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable);
        Page<VideoDTO> videoDTOs = videos.map(this::convertToDTO);
        return ResponseEntity.ok(videoDTOs);
    }

    @PostMapping("/{id}/like")
    @Operation(summary = "Like video", description = "Like or unlike a video (requires authentication)")
    @SecurityRequirement(name = "bearerAuth")
    public ResponseEntity<?> toggleLike(@PathVariable Long id, HttpServletRequest request) {
        Optional<User> currentUser = authUtil.getCurrentUser(request);
        if (currentUser.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Authentication required");
        }

        Optional<Video> videoOpt = videoRepository.findById(id);
        if (!videoOpt.isPresent()) {
            return ResponseEntity.badRequest().body("Video not found");
        }
        
        User user = currentUser.get();
        Video video = videoOpt.get();
        
        // Check if user already liked this video
        Optional<Like> existingLike = likeRepository.findByUserAndVideo(user, video);
        
        if (existingLike.isPresent()) {
            likeRepository.delete(existingLike.get());
            video.setLikesCount(Math.max(0, video.getLikesCount() - 1)); // Ensure count doesn't go negative
            videoRepository.save(video);
            
            return ResponseEntity.ok("Video unliked successfully");
        } else {
            Like newLike = new Like(user, video);
            likeRepository.save(newLike);
            video.setLikesCount(video.getLikesCount() + 1);
            videoRepository.save(video);
            
            return ResponseEntity.ok("Video liked successfully");
        }
    }

    @GetMapping("/{id}/liked")
    @Operation(summary = "Check if video is liked", description = "Check if current user has liked this video")
    @SecurityRequirement(name = "bearerAuth")
    public ResponseEntity<?> isVideoLiked(@PathVariable Long id, HttpServletRequest request) {
        Optional<User> currentUser = authUtil.getCurrentUser(request);
        if (currentUser.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Authentication required");
        }

        Optional<Video> videoOpt = videoRepository.findById(id);
        if (!videoOpt.isPresent()) {
            return ResponseEntity.badRequest().body("Video not found");
        }

        User user = currentUser.get();
        Video video = videoOpt.get();
        
        boolean isLiked = likeRepository.existsByUserAndVideo(user, video);
        
        return ResponseEntity.ok(new java.util.HashMap<String, Object>() {{
            put("isLiked", isLiked);
            put("likesCount", video.getLikesCount());
        }});
    }

    private VideoDTO convertToDTO(Video video) {
        UserDTO userDTO = new UserDTO(
            video.getUser().getId(),
            video.getUser().getUsername(),
            video.getUser().getEmail(),
            video.getUser().getFullName(),
            video.getUser().getProfilePictureUrl(),
            video.getUser().getBio(),
            video.getUser().getFollowersCount(),
            video.getUser().getFollowingCount(),
            video.getUser().getCreatedAt()
        );

        return new VideoDTO(
            video.getId(),
            video.getDescription(),
            video.getVideoUrl(),
            video.getThumbnailUrl(),
            video.getDurationSeconds(),
            video.getViewsCount(),
            video.getLikesCount(),
            video.getCommentsCount(),
            video.getSharesCount(),
            video.getIsPublic(),
            video.getCreatedAt(),
            userDTO
        );
    }
}