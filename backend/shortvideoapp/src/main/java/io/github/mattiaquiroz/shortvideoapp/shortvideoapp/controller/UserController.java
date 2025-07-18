package io.github.mattiaquiroz.shortvideoapp.shortvideoapp.controller;

import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.dto.PublicUserDTO;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.dto.UpdateUserRequest;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.dto.UserDTO;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.entity.User;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.repository.UserRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.http.HttpStatus;
import org.springframework.util.StringUtils;
import jakarta.servlet.http.HttpServletRequest;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.util.AuthUtil;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.io.IOException;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/users")
@Tag(name = "User Management", description = "APIs for managing users")
public class UserController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AuthUtil authUtil;

    @GetMapping
    @Operation(summary = "Get all users", description = "Retrieve a list of all users")
    public ResponseEntity<List<UserDTO>> getAllUsers() {
        List<User> users = userRepository.findAll();
        List<UserDTO> userDTOs = users.stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
        return ResponseEntity.ok(userDTOs);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get user by ID", description = "Retrieve a user by their ID")
    public ResponseEntity<PublicUserDTO> getUserById(@PathVariable Long id) {
        Optional<User> user = userRepository.findById(id);
        if (user.isPresent()) {
            return ResponseEntity.ok(convertToPublicDTO(user.get()));
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/username/{username}")
    @Operation(summary = "Get user by username", description = "Retrieve a user by their username")
    public ResponseEntity<PublicUserDTO> getUserByUsername(@PathVariable String username) {
        Optional<User> user = userRepository.findByUsername(username);
        if (user.isPresent()) {
            return ResponseEntity.ok(convertToPublicDTO(user.get()));
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update user", description = "Update an existing user's information")
    public ResponseEntity<?> updateUser(@PathVariable Long id, @Valid @RequestBody UpdateUserRequest request, HttpServletRequest httpRequest) {
        // Check if user is authenticated
        var currentUserOpt = authUtil.getCurrentUser(httpRequest);
        if (currentUserOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Authentication required");
        }
        
        User currentUser = currentUserOpt.get();
        
        // Check if user is trying to update their own profile
        if (!currentUser.getId().equals(id)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("You can only update your own profile");
        }
        
        Optional<User> existingUser = userRepository.findById(id);
        if (!existingUser.isPresent()) {
            return ResponseEntity.notFound().build();
        }

        User user = existingUser.get();

        // Check if username is being changed and already exists
        if (!user.getUsername().equals(request.getUsername()) && 
            userRepository.existsByUsername(request.getUsername())) {
            return ResponseEntity.badRequest().body("Username already exists");
        }

        // Check if email is being changed and already exists
        if (!user.getEmail().equals(request.getEmail()) && 
            userRepository.existsByEmail(request.getEmail())) {
            return ResponseEntity.badRequest().body("Email already exists");
        }

        user.setUsername(request.getUsername());
        user.setEmail(request.getEmail());
        user.setFullName(request.getFullName());
        user.setBio(request.getBio());
        user.setProfilePictureUrl(request.getProfilePictureUrl());

        User updatedUser = userRepository.save(user);
        return ResponseEntity.ok(convertToDTO(updatedUser));
    }

    @PatchMapping("/{id}")
    @Operation(summary = "Partially update user", description = "Update only provided fields for a user")
    public ResponseEntity<?> patchUser(@PathVariable Long id, @RequestBody UpdateUserRequest request, HttpServletRequest httpRequest) {
        // Check if user is authenticated
        var currentUserOpt = authUtil.getCurrentUser(httpRequest);
        if (currentUserOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Authentication required");
        }
        
        User currentUser = currentUserOpt.get();
        
        // Check if user is trying to update their own profile
        if (!currentUser.getId().equals(id)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("You can only update your own profile");
        }
        
        Optional<User> existingUser = userRepository.findById(id);
        if (!existingUser.isPresent()) {
            return ResponseEntity.notFound().build();
        }
        User user = existingUser.get();
        // Only update fields that are non-null
        if (request.getUsername() != null && !request.getUsername().equals(user.getUsername())) {
            if (userRepository.existsByUsername(request.getUsername())) {
                return ResponseEntity.badRequest().body("Username already exists");
            }
            user.setUsername(request.getUsername());
        }
        if (request.getEmail() != null && !request.getEmail().equals(user.getEmail())) {
            if (userRepository.existsByEmail(request.getEmail())) {
                return ResponseEntity.badRequest().body("Email already exists");
            }
            user.setEmail(request.getEmail());
        }
        if (request.getFullName() != null) {
            user.setFullName(request.getFullName());
        }
        if (request.getBio() != null) {
            user.setBio(request.getBio());
        }
        if (request.getProfilePictureUrl() != null) {
            user.setProfilePictureUrl(request.getProfilePictureUrl());
        }
        User updatedUser = userRepository.save(user);
        return ResponseEntity.ok(convertToDTO(updatedUser));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete user", description = "Delete a user account")
    public ResponseEntity<?> deleteUser(@PathVariable Long id, HttpServletRequest httpRequest) {
        // Check if user is authenticated
        var currentUserOpt = authUtil.getCurrentUser(httpRequest);
        if (currentUserOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Authentication required");
        }
        
        User currentUser = currentUserOpt.get();
        
        // Check if user is trying to delete their own account
        if (!currentUser.getId().equals(id)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("You can only delete your own account");
        }
        
        if (!userRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        userRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/search")
    @Operation(summary = "Search users", description = "Search users by username or full name")
    public ResponseEntity<List<PublicUserDTO>> searchUsers(@RequestParam String query) {
        List<User> users = userRepository.searchUsers(query);
        List<PublicUserDTO> userDTOs = users.stream()
                .map(this::convertToPublicDTO)
                .collect(Collectors.toList());
        return ResponseEntity.ok(userDTOs);
    }

    @GetMapping("/top")
    @Operation(summary = "Get top users", description = "Get users with most followers")
    public ResponseEntity<List<PublicUserDTO>> getTopUsers() {
        List<User> users = userRepository.findTopUsers();
        List<PublicUserDTO> userDTOs = users.stream()
                .map(this::convertToPublicDTO)
                .collect(Collectors.toList());
        return ResponseEntity.ok(userDTOs);
    }

    @PostMapping("/me/profile-picture")
    @Operation(summary = "Upload profile picture", description = "Upload a new profile picture for the authenticated user")
    public ResponseEntity<?> uploadProfilePicture(@RequestParam("file") MultipartFile file, HttpServletRequest request) {
        try {
            // Authenticate user
            var userOpt = authUtil.getCurrentUser(request);
            if (userOpt.isEmpty()) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Authentication required");
            }
            User user = userOpt.get();

            // Validate file
            if (file.isEmpty()) {
                return ResponseEntity.badRequest().body("No file uploaded");
            }
            String filename = StringUtils.cleanPath(file.getOriginalFilename());
            String ext = filename.contains(".") ? filename.substring(filename.lastIndexOf('.')) : "";
            String newFilename = "user_" + user.getId() + "_" + System.currentTimeMillis() + ext;
            Path uploadDir = Paths.get("assets/users/user_" + user.getId());
            if (!Files.exists(uploadDir)) {
                Files.createDirectories(uploadDir);
            }
            Path filePath = uploadDir.resolve(newFilename);
            file.transferTo(filePath);

            // Update user profile picture URL
            user.setProfilePictureUrl("assets/users/user_" + user.getId() + "/" + System.currentTimeMillis() + ext);
            userRepository.save(user);

            // Return the new URL (relative path)
            return ResponseEntity.ok().body(new java.util.HashMap<String, Object>() {{
                put("success", true);
                put("url", "assets/users/user_" + user.getId() + "/" + newFilename);
            }});
        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Failed to upload image: " + e.getMessage());
        }
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
            user.getCreatedAt()
        );
    }

    private PublicUserDTO convertToPublicDTO(User user) {
        return new PublicUserDTO(
            user.getId(),
            user.getUsername(),
            user.getFullName(),
            user.getProfilePictureUrl(),
            user.getBio(),
            user.getFollowersCount(),
            user.getFollowingCount(),
            user.getCreatedAt()
        );
    }
} 