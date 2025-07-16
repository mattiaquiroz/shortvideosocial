package io.github.mattiaquiroz.shortvideoapp.shortvideoapp.util;

import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.entity.User;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.repository.UserRepository;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.Optional;

@Component
public class AuthUtil {

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private UserRepository userRepository;

    public Long getCurrentUserId(HttpServletRequest request) {
        String token = extractTokenFromRequest(request);
        if (token != null && jwtUtil.validateToken(token)) {
            return jwtUtil.extractUserId(token);
        }
        return null;
    }

    public String getCurrentUsername(HttpServletRequest request) {
        String token = extractTokenFromRequest(request);
        if (token != null && jwtUtil.validateToken(token)) {
            return jwtUtil.extractUsername(token);
        }
        return null;
    }

    public Optional<User> getCurrentUser(HttpServletRequest request) {
        Long userId = getCurrentUserId(request);
        if (userId != null) {
            return userRepository.findById(userId);
        }
        return Optional.empty();
    }

    private String extractTokenFromRequest(HttpServletRequest request) {
        String authorizationHeader = request.getHeader("Authorization");
        if (authorizationHeader != null && authorizationHeader.startsWith("Bearer ")) {
            return authorizationHeader.substring(7);
        }
        return null;
    }

    public boolean isAuthenticated(HttpServletRequest request) {
        String token = extractTokenFromRequest(request);
        return token != null && jwtUtil.validateToken(token);
    }
} 