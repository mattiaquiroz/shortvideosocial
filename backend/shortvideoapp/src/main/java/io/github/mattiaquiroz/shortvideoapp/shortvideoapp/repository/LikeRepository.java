package io.github.mattiaquiroz.shortvideoapp.shortvideoapp.repository;

import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.entity.Like;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.entity.User;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.entity.Video;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Repository
public interface LikeRepository extends JpaRepository<Like, Long> {
    
    Optional<Like> findByUserAndVideo(User user, Video video);
    
    boolean existsByUserAndVideo(User user, Video video);
    
    long countByVideo(Video video);
    
    @Transactional
    void deleteByUserAndVideo(User user, Video video);
} 