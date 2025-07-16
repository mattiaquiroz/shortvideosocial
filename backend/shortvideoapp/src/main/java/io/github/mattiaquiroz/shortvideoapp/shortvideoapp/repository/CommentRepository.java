package io.github.mattiaquiroz.shortvideoapp.shortvideoapp.repository;

import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.entity.Comment;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.entity.Video;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CommentRepository extends JpaRepository<Comment, Long> {
    
    // Get all comments for a video (including replies)
    Page<Comment> findByVideoOrderByCreatedAtDesc(Video video, Pageable pageable);
    
    // Get only parent comments (no replies) for a video
    Page<Comment> findByVideoAndParentCommentIsNullOrderByCreatedAtDesc(Video video, Pageable pageable);
    
    // Get replies for a specific comment
    List<Comment> findByParentCommentOrderByCreatedAtAsc(Comment parentComment);
    
    // Count total comments for a video (including replies)
    long countByVideo(Video video);
    
    // Count only parent comments for a video
    long countByVideoAndParentCommentIsNull(Video video);
} 