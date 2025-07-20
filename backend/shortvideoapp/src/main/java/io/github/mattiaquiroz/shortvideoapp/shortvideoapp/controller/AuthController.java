package io.github.mattiaquiroz.shortvideoapp.shortvideoapp.controller;

import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.dto.*;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.entity.User;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.repository.UserRepository;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.util.JwtUtil;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.Optional;
import jakarta.servlet.http.HttpServletRequest;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.util.AuthUtil;

@RestController
@RequestMapping("/api/auth")
@Tag(name = "Authentication", description = "APIs for user authentication")
public class AuthController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private AuthUtil authUtil;

    @PostMapping("/register")
    @Operation(summary = "Register new user", description = "Create a new user account")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        try {
            // Validate password confirmation
            if (!request.getPassword().equals(request.getConfirmPassword())) {
                return ResponseEntity.badRequest()
                    .body(new AuthResponse(false, "Passwords do not match"));
            }

            // Check if username already exists
            if (userRepository.existsByUsername(request.getUsername())) {
                return ResponseEntity.badRequest()
                    .body(new AuthResponse(false, "Username already exists"));
            }

            // Check if email already exists
            if (userRepository.existsByEmail(request.getEmail())) {
                return ResponseEntity.badRequest()
                    .body(new AuthResponse(false, "Email already exists"));
            }

            // Create new user
            User user = new User();
            user.setUsername(request.getUsername());
            user.setEmail(request.getEmail());
            user.setPassword(passwordEncoder.encode(request.getPassword())); // Hash password

            User savedUser = userRepository.save(user);

            // Generate JWT token for the new user
            String token = jwtUtil.generateToken(savedUser.getUsername(), savedUser.getId());
            LocalDateTime expiresAt = LocalDateTime.now().plusSeconds(jwtUtil.getExpirationTime() / 1000);

            // Convert to DTO (without password)
            UserDTO userDTO = convertToDTO(savedUser);

            return ResponseEntity.status(HttpStatus.CREATED)
                .body(new AuthResponse(true, "User registered successfully", userDTO, token, expiresAt));

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new AuthResponse(false, "Registration failed: " + e.getMessage()));
        }
    }

    @PostMapping("/login")
    @Operation(summary = "User login", description = "Authenticate user with username/email and password")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        try {
            // Find user by username or email
            Optional<User> userOptional = userRepository.findByUsername(request.getUsernameOrEmail());
            if (userOptional.isEmpty()) {
                userOptional = userRepository.findByEmail(request.getUsernameOrEmail());
            }

            if (userOptional.isEmpty()) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new AuthResponse(false, "Invalid username/email or password"));
            }

            User user = userOptional.get();

            // Check password
            if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new AuthResponse(false, "Invalid username/email or password"));
            }

            // Generate JWT token
            String token = jwtUtil.generateToken(user.getUsername(), user.getId());
            LocalDateTime expiresAt = LocalDateTime.now().plusSeconds(jwtUtil.getExpirationTime() / 1000);

            // Convert to DTO (without password)
            UserDTO userDTO = convertToDTO(user);

            return ResponseEntity.ok(new AuthResponse(true, "Login successful", userDTO, token, expiresAt));

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new AuthResponse(false, "Login failed: " + e.getMessage()));
        }
    }

    @PostMapping("/change-password")
    @Operation(summary = "Change password", description = "Change user password")
    public ResponseEntity<AuthResponse> changePassword(@RequestBody Map<String, String> payload, HttpServletRequest request) {
        try {
            String currentPassword = payload.get("currentPassword");
            String newPassword = payload.get("newPassword");
            var userOpt = authUtil.getCurrentUser(request);
            if (userOpt.isEmpty()) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new AuthResponse(false, "Authentication required"));
            }
            User user = userOpt.get();

            // Verify current password
            if (!passwordEncoder.matches(currentPassword, user.getPassword())) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new AuthResponse(false, "Current password is incorrect"));
            }

            // Validate new password
            if (newPassword.length() < 6) {
                return ResponseEntity.badRequest()
                    .body(new AuthResponse(false, "New password must be at least 6 characters"));
            }

            // Update password
            user.setPassword(passwordEncoder.encode(newPassword));
            userRepository.save(user);

            return ResponseEntity.ok(new AuthResponse(true, "Password changed successfully"));

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new AuthResponse(false, "Password change failed: " + e.getMessage()));
        }
    }

    @GetMapping("/verify-token")
    @Operation(summary = "Verify user token", description = "Verify if user is authenticated")
    public ResponseEntity<AuthResponse> verifyToken(@RequestHeader("Authorization") String authorizationHeader) {
        try {
            if (authorizationHeader == null || !authorizationHeader.startsWith("Bearer ")) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new AuthResponse(false, "Missing or invalid authorization header"));
            }

            String token = authorizationHeader.substring(7);
            
            if (!jwtUtil.validateToken(token)) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new AuthResponse(false, "Invalid or expired token"));
            }

            Long userId = jwtUtil.extractUserId(token);

            Optional<User> userOptional = userRepository.findById(userId);
            if (userOptional.isEmpty()) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(new AuthResponse(false, "User not found"));
            }

            UserDTO userDTO = convertToDTO(userOptional.get());
            return ResponseEntity.ok(new AuthResponse(true, "Token is valid", userDTO));

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new AuthResponse(false, "Token verification failed: " + e.getMessage()));
        }
    }

    @PostMapping("/logout")
    @Operation(summary = "User logout", description = "Logout user (client should discard the token)")
    public ResponseEntity<AuthResponse> logout() {
        return ResponseEntity.ok(new AuthResponse(true, "Logout successful"));
    }

    private UserDTO convertToDTO(User user) {
        return new UserDTO(
            user.getId(),
            user.getUsername(),
            user.getEmail(),
            user.getFullName(),
            user.getProfilePictureUrl(),
            user.getBio(),
            user.getFollowersCount(),
            user.getFollowingCount(),
            user.getCreatedAt(),
            user.isPrivateAccount()
        );
    }
} 