package io.github.mattiaquiroz.shortvideoapp.shortvideoapp.repository;

import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.entity.CommentLike;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.entity.Comment;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Repository
public interface CommentLikeRepository extends JpaRepository<CommentLike, Long> {
    
    Optional<CommentLike> findByUserAndComment(User user, Comment comment);
    
    boolean existsByUserAndComment(User user, Comment comment);
    
    long countByComment(Comment comment);
    
    @Transactional
    void deleteByUserAndComment(User user, Comment comment);
} 