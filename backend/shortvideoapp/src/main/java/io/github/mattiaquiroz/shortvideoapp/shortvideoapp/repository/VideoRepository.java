package io.github.mattiaquiroz.shortvideoapp.shortvideoapp.repository;

import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.entity.Video;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface VideoRepository extends JpaRepository<Video, Long> {
    
    List<Video> findByUserOrderByCreatedAtDesc(User user);
    
    Page<Video> findByIsPublicTrueOrderByCreatedAtDesc(Pageable pageable);
    
    Page<Video> findByIsPublicTrueOrderByViewsCountDesc(Pageable pageable);
    
    Page<Video> findByIsPublicTrueOrderByLikesCountDesc(Pageable pageable);
    
    @Query("SELECT v FROM Video v WHERE v.isPublic = true AND (v.description LIKE %:query% OR v.description LIKE %:query%)")
    Page<Video> searchPublicVideos(@Param("query") String query, Pageable pageable);
    
    @Query("SELECT v FROM Video v WHERE v.user.id = :userId ORDER BY v.createdAt DESC")
    Page<Video> findByUserIdOrderByCreatedAtDesc(@Param("userId") Long userId, Pageable pageable);
    
    @Query("SELECT v FROM Video v WHERE v.user.id = :userId AND v.isPublic = :isPublic ORDER BY v.createdAt DESC")
    Page<Video> findByUserIdAndIsPublicOrderByCreatedAtDesc(@Param("userId") Long userId, @Param("isPublic") Boolean isPublic, Pageable pageable);
    
    @Query("SELECT v FROM Video v INNER JOIN Like l ON v.id = l.video.id WHERE l.user.id = :userId ORDER BY l.createdAt DESC")
    Page<Video> findLikedVideosByUserId(@Param("userId") Long userId, Pageable pageable);
    
    long countByUser(User user);
} 