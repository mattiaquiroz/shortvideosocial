package io.github.mattiaquiroz.shortvideoapp.shortvideoapp.controller;

import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.dto.CreateVideoRequest;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.dto.CreateCommentRequest;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.dto.CommentDTO;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.dto.UserDTO;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.dto.VideoDTO;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.entity.Comment;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.entity.CommentLike;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.entity.Like;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.entity.User;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.entity.Video;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.repository.CommentRepository;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.repository.CommentLikeRepository;
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
import org.springframework.transaction.annotation.Transactional;

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
    private CommentRepository commentRepository;

    @Autowired
    private CommentLikeRepository commentLikeRepository;

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

    @GetMapping("/user/{userId}/public")
    @Operation(summary = "Get user's public videos", description = "Get all public videos uploaded by a specific user")
    public ResponseEntity<Page<VideoDTO>> getUserPublicVideos(
            @PathVariable Long userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        Pageable pageable = PageRequest.of(page, size);
        Page<Video> videos = videoRepository.findByUserIdAndIsPublicOrderByCreatedAtDesc(userId, true, pageable);
        Page<VideoDTO> videoDTOs = videos.map(this::convertToDTO);
        return ResponseEntity.ok(videoDTOs);
    }

    @GetMapping("/user/{userId}/private")
    @Operation(summary = "Get user's private videos", description = "Get all private videos uploaded by a specific user (requires authentication)")
    @SecurityRequirement(name = "bearerAuth")
    public ResponseEntity<Page<VideoDTO>> getUserPrivateVideos(
            @PathVariable Long userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            HttpServletRequest request) {
        
        // Check authentication and verify user can access private videos
        Optional<User> currentUser = authUtil.getCurrentUser(request);
        if (currentUser.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        
        // Users can only see their own private videos
        if (!currentUser.get().getId().equals(userId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        
        Pageable pageable = PageRequest.of(page, size);
        Page<Video> videos = videoRepository.findByUserIdAndIsPublicOrderByCreatedAtDesc(userId, false, pageable);
        Page<VideoDTO> videoDTOs = videos.map(this::convertToDTO);
        return ResponseEntity.ok(videoDTOs);
    }

    @GetMapping("/user/{userId}/liked")
    @Operation(summary = "Get user's liked videos", description = "Get all videos liked by a specific user (requires authentication)")
    @SecurityRequirement(name = "bearerAuth")
    public ResponseEntity<Page<VideoDTO>> getUserLikedVideos(
            @PathVariable Long userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            HttpServletRequest request) {
        
        // Check authentication and verify user can access liked videos
        Optional<User> currentUser = authUtil.getCurrentUser(request);
        if (currentUser.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        
        // Users can only see their own liked videos
        if (!currentUser.get().getId().equals(userId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        
        Pageable pageable = PageRequest.of(page, size);
        Page<Video> videos = videoRepository.findLikedVideosByUserId(userId, pageable);
        Page<VideoDTO> videoDTOs = videos.map(this::convertToDTO);
        return ResponseEntity.ok(videoDTOs);
    }

    @PostMapping("/{id}/like")
    @Operation(summary = "Like video", description = "Like or unlike a video (requires authentication)")
    @SecurityRequirement(name = "bearerAuth")
    public ResponseEntity<?> toggleLike(@PathVariable Long id, HttpServletRequest request) {
        Optional<User> currentUser = authUtil.getCurrentUser(request);
        if (currentUser.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new java.util.HashMap<String, Object>() {{
                        put("success", false);
                        put("message", "Authentication required");
                    }});
        }

        Optional<Video> videoOpt = videoRepository.findById(id);
        if (!videoOpt.isPresent()) {
            return ResponseEntity.badRequest()
                    .body(new java.util.HashMap<String, Object>() {{
                        put("success", false);
                        put("message", "Video not found");
                    }});
        }
        
        User user = currentUser.get();
        Video video = videoOpt.get();
        
        // Check if user already liked this video
        Optional<Like> existingLike = likeRepository.findByUserAndVideo(user, video);
        
        if (existingLike.isPresent()) {
            likeRepository.delete(existingLike.get());
            video.setLikesCount(Math.max(0, video.getLikesCount() - 1)); // Ensure count doesn't go negative
            videoRepository.save(video);
            
            return ResponseEntity.ok(new java.util.HashMap<String, Object>() {{
                put("success", true);
                put("message", "Video unliked successfully");
                put("isLiked", false);
                put("likesCount", video.getLikesCount());
            }});
        } else {
            Like newLike = new Like(user, video);
            likeRepository.save(newLike);
            video.setLikesCount(video.getLikesCount() + 1);
            videoRepository.save(video);
            
            return ResponseEntity.ok(new java.util.HashMap<String, Object>() {{
                put("success", true);
                put("message", "Video liked successfully");
                put("isLiked", true);
                put("likesCount", video.getLikesCount());
            }});
        }
    }

    @GetMapping("/{id}/liked")
    @Operation(summary = "Check if video is liked", description = "Check if current user has liked this video")
    @SecurityRequirement(name = "bearerAuth")
    public ResponseEntity<?> isVideoLiked(@PathVariable Long id, HttpServletRequest request) {
        Optional<User> currentUser = authUtil.getCurrentUser(request);
        if (currentUser.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new java.util.HashMap<String, Object>() {{
                        put("success", false);
                        put("message", "Authentication required");
                    }});
        }

        Optional<Video> videoOpt = videoRepository.findById(id);
        if (!videoOpt.isPresent()) {
            return ResponseEntity.badRequest()
                    .body(new java.util.HashMap<String, Object>() {{
                        put("success", false);
                        put("message", "Video not found");
                    }});
        }

        User user = currentUser.get();
        Video video = videoOpt.get();
        
        boolean isLiked = likeRepository.existsByUserAndVideo(user, video);
        
        return ResponseEntity.ok(new java.util.HashMap<String, Object>() {{
            put("success", true);
            put("isLiked", isLiked);
            put("likesCount", video.getLikesCount());
        }});
    }

    @PostMapping("/{id}/comments")
    @Operation(summary = "Add comment to video", description = "Add a comment to a video (requires authentication)")
    @SecurityRequirement(name = "bearerAuth")
    public ResponseEntity<?> addComment(@PathVariable Long id, @Valid @RequestBody CreateCommentRequest request, HttpServletRequest httpRequest) {
        Optional<User> currentUser = authUtil.getCurrentUser(httpRequest);
        if (currentUser.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new java.util.HashMap<String, Object>() {{
                        put("success", false);
                        put("message", "Authentication required");
                    }});
        }

        Optional<Video> videoOpt = videoRepository.findById(id);
        if (!videoOpt.isPresent()) {
            return ResponseEntity.badRequest()
                    .body(new java.util.HashMap<String, Object>() {{
                        put("success", false);
                        put("message", "Video not found");
                    }});
        }

        User user = currentUser.get();
        Video video = videoOpt.get();

        Comment comment;
        Comment parentComment = null;
        
        // Check if this is a reply
        if (request.getParentCommentId() != null) {
            Optional<Comment> parentCommentOpt = commentRepository.findById(request.getParentCommentId());
            if (!parentCommentOpt.isPresent()) {
                return ResponseEntity.badRequest()
                        .body(new java.util.HashMap<String, Object>() {{
                            put("success", false);
                            put("message", "Parent comment not found");
                        }});
            }
            parentComment = parentCommentOpt.get();
            comment = new Comment(request.getText(), user, video, parentComment);
        } else {
            comment = new Comment(request.getText(), user, video);
        }

        Comment savedComment = commentRepository.save(comment);
        
        // Update video comments count
        video.setCommentsCount(video.getCommentsCount() + 1);
        videoRepository.save(video);

        CommentDTO commentDTO = convertToCommentDTO(savedComment, user);

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(new java.util.HashMap<String, Object>() {{
                    put("success", true);
                    put("message", "Comment added successfully");
                    put("comment", commentDTO);
                    put("commentsCount", video.getCommentsCount());
                }});
    }

    @GetMapping("/{id}/comments")
    @Operation(summary = "Get video comments", description = "Get all comments for a video")
    public ResponseEntity<Page<CommentDTO>> getVideoComments(
            @PathVariable Long id,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            HttpServletRequest request) {
        
        Optional<Video> videoOpt = videoRepository.findById(id);
        if (!videoOpt.isPresent()) {
            return ResponseEntity.notFound().build();
        }

        Video video = videoOpt.get();
        Pageable pageable = PageRequest.of(page, size);
        
        // Get only parent comments (replies will be loaded as part of parent comments)
        Page<Comment> comments = commentRepository.findByVideoAndParentCommentIsNullOrderByCreatedAtDesc(video, pageable);
        
        // Get current user for like status
        Optional<User> currentUser = authUtil.getCurrentUser(request);
        User user = currentUser.orElse(null);
        
        Page<CommentDTO> commentDTOs = comments.map(comment -> convertToCommentDTO(comment, user));
        
        return ResponseEntity.ok(commentDTOs);
    }

    @PostMapping("/comments/{commentId}/like")
    @Operation(summary = "Like comment", description = "Like or unlike a comment (requires authentication)")
    @SecurityRequirement(name = "bearerAuth")
    public ResponseEntity<?> toggleCommentLike(@PathVariable Long commentId, HttpServletRequest request) {
        Optional<User> currentUser = authUtil.getCurrentUser(request);
        if (currentUser.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new java.util.HashMap<String, Object>() {{
                        put("success", false);
                        put("message", "Authentication required");
                    }});
        }

        Optional<Comment> commentOpt = commentRepository.findById(commentId);
        if (!commentOpt.isPresent()) {
            return ResponseEntity.badRequest()
                    .body(new java.util.HashMap<String, Object>() {{
                        put("success", false);
                        put("message", "Comment not found");
                    }});
        }
        
        User user = currentUser.get();
        Comment comment = commentOpt.get();
        
        // Check if user already liked this comment
        Optional<CommentLike> existingLike = commentLikeRepository.findByUserAndComment(user, comment);
        
        if (existingLike.isPresent()) {
            commentLikeRepository.delete(existingLike.get());
            comment.setLikesCount(Math.max(0, comment.getLikesCount() - 1));
            commentRepository.save(comment);
            
            return ResponseEntity.ok(new java.util.HashMap<String, Object>() {{
                put("success", true);
                put("message", "Comment unliked successfully");
                put("isLiked", false);
                put("likesCount", comment.getLikesCount());
            }});
        } else {
            CommentLike newLike = new CommentLike(user, comment);
            commentLikeRepository.save(newLike);
            comment.setLikesCount(comment.getLikesCount() + 1);
            commentRepository.save(comment);
            
            return ResponseEntity.ok(new java.util.HashMap<String, Object>() {{
                put("success", true);
                put("message", "Comment liked successfully");
                put("isLiked", true);
                put("likesCount", comment.getLikesCount());
            }});
        }
    }

    @DeleteMapping("/comments/{commentId}")
    @Operation(summary = "Delete comment", description = "Delete a comment (only by the author)")
    @SecurityRequirement(name = "bearerAuth")
    @Transactional
    public ResponseEntity<?> deleteComment(@PathVariable Long commentId, HttpServletRequest request) {
        Optional<User> currentUser = authUtil.getCurrentUser(request);
        if (currentUser.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new java.util.HashMap<String, Object>() {{
                        put("success", false);
                        put("message", "Authentication required");
                    }});
        }
        Optional<Comment> commentOpt = commentRepository.findById(commentId);
        if (commentOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(new java.util.HashMap<String, Object>() {{
                        put("success", false);
                        put("message", "Comment not found");
                    }});
        }
        Comment comment = commentOpt.get();
        if (!comment.getUser().getId().equals(currentUser.get().getId())) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(new java.util.HashMap<String, Object>() {{
                        put("success", false);
                        put("message", "You can only delete your own comments");
                    }});
        }
        
        // Get the video to update its comment count
        Video video = comment.getVideo();
        video.setCommentsCount(Math.max(0, video.getCommentsCount() - 1));
        videoRepository.save(video);
        
        // Delete all replies recursively
        deleteReplies(comment);
        commentRepository.delete(comment);
        return ResponseEntity.ok(new java.util.HashMap<String, Object>() {{
            put("success", true);
            put("message", "Comment deleted successfully");
            put("commentsCount", video.getCommentsCount());
        }});
    }

    private void deleteReplies(Comment comment) {
        if (comment.getReplies() != null) {
            for (Comment reply : comment.getReplies()) {
                deleteReplies(reply);
                commentRepository.delete(reply);
            }
        }
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

    private CommentDTO convertToCommentDTO(Comment comment) {
        return convertToCommentDTO(comment, null);
    }

    private CommentDTO convertToCommentDTO(Comment comment, User currentUser) {
        UserDTO userDTO = new UserDTO(
            comment.getUser().getId(),
            comment.getUser().getUsername(),
            comment.getUser().getEmail(),
            comment.getUser().getFullName(),
            comment.getUser().getProfilePictureUrl(),
            comment.getUser().getBio(),
            comment.getUser().getFollowersCount(),
            comment.getUser().getFollowingCount(),
            comment.getUser().getCreatedAt()
        );

        // Check if current user has liked this comment
        boolean isLiked = false;
        if (currentUser != null) {
            isLiked = commentLikeRepository.existsByUserAndComment(currentUser, comment);
        }

        // Get replies for this comment
        List<Comment> replyEntities = commentRepository.findByParentCommentOrderByCreatedAtAsc(comment);
        List<CommentDTO> replies = replyEntities.stream()
                .map(reply -> convertToCommentDTO(reply, currentUser))
                .collect(Collectors.toList());

        return new CommentDTO(
            comment.getId(),
            comment.getText(),
            comment.getLikesCount(),
            isLiked,
            comment.getCreatedAt(),
            userDTO,
            comment.getParentComment() != null ? comment.getParentComment().getId() : null,
            replies
        );
    }
}