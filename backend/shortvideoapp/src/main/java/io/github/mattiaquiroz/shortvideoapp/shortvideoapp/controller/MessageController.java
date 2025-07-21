package io.github.mattiaquiroz.shortvideoapp.shortvideoapp.controller;

import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.dto.*;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.entity.Message;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.entity.User;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.repository.MessageRepository;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.repository.UserRepository;
import io.github.mattiaquiroz.shortvideoapp.shortvideoapp.util.AuthUtil;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;
import java.util.Map;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import java.util.HashMap;

@RestController
@RequestMapping("/api/messages")
@Tag(name = "Message Management", description = "APIs for managing messages and conversations")
public class MessageController {

    @Autowired
    private MessageRepository messageRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AuthUtil authUtil;

    @PostMapping
    @Operation(summary = "Send a message", description = "Send a new message to another user")
    public ResponseEntity<?> sendMessage(@Valid @RequestBody CreateMessageRequest request, 
                                       HttpServletRequest httpRequest) {
        // Check if user is authenticated
        var currentUserOpt = authUtil.getCurrentUser(httpRequest);
        if (currentUserOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Authentication required");
        }

        User currentUser = currentUserOpt.get();
        
        // Check if receiver exists
        Optional<User> receiverOpt = userRepository.findById(request.getReceiverId());
        if (receiverOpt.isEmpty()) {
            return ResponseEntity.badRequest().body("Receiver not found");
        }

        User receiver = receiverOpt.get();
        
        // Check if user is trying to send message to themselves
        if (currentUser.getId().equals(receiver.getId())) {
            return ResponseEntity.badRequest().body("Cannot send message to yourself");
        }

        Message message = new Message();
        message.setSender(currentUser);
        message.setReceiver(receiver);
        message.setContent(request.getContent());
        message.setReaction(request.getReaction());
        message.setMessageType(request.getMessageType());

        // Handle reply
        if (request.getReplyToId() != null) {
            Optional<Message> replyToOpt = messageRepository.findById(request.getReplyToId());
            if (replyToOpt.isPresent()) {
                Message replyTo = replyToOpt.get();
                // Verify the reply is from the same conversation
                if ((replyTo.getSender().equals(currentUser) && replyTo.getReceiver().equals(receiver)) ||
                    (replyTo.getSender().equals(receiver) && replyTo.getReceiver().equals(currentUser))) {
                    message.setReplyTo(replyTo);
                }
            }
        }

        Message savedMessage = messageRepository.save(message);
        return ResponseEntity.status(HttpStatus.CREATED).body(convertToDTO(savedMessage));
    }

    @GetMapping("/conversations")
    @Operation(summary = "Get conversations", description = "Get all conversations for the current user")
    public ResponseEntity<?> getConversations(HttpServletRequest httpRequest) {
        // Check if user is authenticated
        var currentUserOpt = authUtil.getCurrentUser(httpRequest);
        if (currentUserOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Authentication required");
        }

        User currentUser = currentUserOpt.get();
        List<Message> conversations = messageRepository.findConversationsForUser(currentUser);
        
        List<ConversationDTO> conversationDTOs = conversations.stream()
                .map(message -> convertToConversationDTO(message, currentUser))
                .collect(Collectors.toList());

        return ResponseEntity.ok(conversationDTOs);
    }

    @GetMapping("/conversation/{userId}")
    @Operation(summary = "Get conversation with user", description = "Get all messages in a conversation with a specific user")
    public ResponseEntity<?> getConversationWithUser(
        @PathVariable Long userId,
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "15") int size,
        HttpServletRequest httpRequest) {
        var currentUserOpt = authUtil.getCurrentUser(httpRequest);
        if (currentUserOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Authentication required");
        }

        User currentUser = currentUserOpt.get();
        
        // Check if other user exists
        Optional<User> otherUserOpt = userRepository.findById(userId);
        if (otherUserOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        User otherUser = otherUserOpt.get();
        
        // Check if user is trying to get conversation with themselves
        if (currentUser.getId().equals(otherUser.getId())) {
            return ResponseEntity.badRequest().body("Cannot get conversation with yourself");
        }

        Pageable pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
        Page<Message> messagePage = messageRepository.findConversation(currentUser.getId(), otherUser.getId(), pageable);

        List<MessageDTO> messages = messagePage.getContent().stream()
            .map(this::convertToDTO)
            .collect(Collectors.toList());

        Map<String, Object> response = new HashMap<>();
        response.put("messages", messages);
        response.put("totalPages", messagePage.getTotalPages());
        response.put("totalElements", messagePage.getTotalElements());
        response.put("hasMore", messagePage.hasNext());
        response.put("page", page);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/unread-count")
    @Operation(summary = "Get unread count", description = "Get the total number of unread messages")
    public ResponseEntity<?> getUnreadCount(HttpServletRequest httpRequest) {
        // Check if user is authenticated
        var currentUserOpt = authUtil.getCurrentUser(httpRequest);
        if (currentUserOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Authentication required");
        }

        User currentUser = currentUserOpt.get();
        Long unreadCount = messageRepository.countUnreadMessagesForUser(currentUser);
        
        return ResponseEntity.ok(Map.of("unreadCount", unreadCount));
    }

    @PutMapping("/{messageId}/reaction")
    @Operation(summary = "Add reaction to message", description = "Add or update reaction to a message")
    public ResponseEntity<?> addReaction(@PathVariable Long messageId, 
                                       @RequestParam String reaction,
                                       HttpServletRequest httpRequest) {
        // Check if user is authenticated
        var currentUserOpt = authUtil.getCurrentUser(httpRequest);
        if (currentUserOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Authentication required");
        }

        User currentUser = currentUserOpt.get();
        
        // Check if message exists
        Optional<Message> messageOpt = messageRepository.findById(messageId);
        if (messageOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        Message message = messageOpt.get();
        
        // Check if user is the sender or receiver of the message
        if (!message.getSender().equals(currentUser) && !message.getReceiver().equals(currentUser)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Not authorized to react to this message");
        }

        message.setReaction(reaction);
        Message updatedMessage = messageRepository.save(message);
        
        return ResponseEntity.ok(convertToDTO(updatedMessage));
    }

    @DeleteMapping("/{messageId}")
    @Operation(summary = "Delete message", description = "Delete a message (only sender can delete)")
    public ResponseEntity<?> deleteMessage(@PathVariable Long messageId, 
                                         HttpServletRequest httpRequest) {
        // Check if user is authenticated
        var currentUserOpt = authUtil.getCurrentUser(httpRequest);
        if (currentUserOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Authentication required");
        }

        User currentUser = currentUserOpt.get();
        
        // Check if message exists
        Optional<Message> messageOpt = messageRepository.findById(messageId);
        if (messageOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        Message message = messageOpt.get();
        
        // Check if user is the sender of the message
        if (!message.getSender().equals(currentUser)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Only sender can delete message");
        }

        // If this message has replies, set their replyTo to null before deleting
        List<Message> replies = messageRepository.findMessagesReplyingTo(message);
        for (Message reply : replies) {
            reply.setReplyTo(null);
            messageRepository.save(reply);
        }

        messageRepository.delete(message);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/conversation/{userId}/mark-read")
    @Operation(summary = "Mark conversation as read", description = "Mark all messages from a user as read")
    public ResponseEntity<?> markConversationAsRead(@PathVariable Long userId, 
                                                  HttpServletRequest httpRequest) {
        // Check if user is authenticated
        var currentUserOpt = authUtil.getCurrentUser(httpRequest);
        if (currentUserOpt.isEmpty()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Authentication required");
        }

        User currentUser = currentUserOpt.get();
        
        // Check if other user exists
        Optional<User> otherUserOpt = userRepository.findById(userId);
        if (otherUserOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        User otherUser = otherUserOpt.get();
        
        messageRepository.markMessagesAsRead(otherUser, currentUser);
        return ResponseEntity.ok().build();
    }

    // Helper methods
    private MessageDTO convertToDTO(Message message) {
        MessageDTO dto = new MessageDTO();
        dto.setId(message.getId());
        dto.setContent(message.getContent());
        dto.setSender(convertToUserDTO(message.getSender()));
        dto.setReceiver(convertToUserDTO(message.getReceiver()));
        dto.setReaction(message.getReaction());
        dto.setMessageType(message.getMessageType());
        dto.setRead(message.isRead());
        dto.setCreatedAt(message.getCreatedAt());
        dto.setUpdatedAt(message.getUpdatedAt());
        
        // Handle reply
        if (message.getReplyTo() != null) {
            dto.setReplyTo(convertToDTO(message.getReplyTo()));
        }
        
        return dto;
    }

    private UserDTO convertToUserDTO(User user) {
        UserDTO dto = new UserDTO();
        dto.setId(user.getId());
        dto.setUsername(user.getUsername());
        dto.setFullName(user.getFullName());
        dto.setProfilePictureUrl(user.getProfilePictureUrl());
        dto.setBio(user.getBio());
        dto.setFollowersCount(user.getFollowersCount());
        dto.setFollowingCount(user.getFollowingCount());
        dto.setPrivateAccount(user.isPrivateAccount());
        dto.setCreatedAt(user.getCreatedAt());
        return dto;
    }

    private ConversationDTO convertToConversationDTO(Message message, User currentUser) {
        User otherUser = message.getSender().equals(currentUser) ? message.getReceiver() : message.getSender();
        
        // Get unread count for this conversation
        Long unreadCount = messageRepository.countUnreadMessagesFromSender(otherUser, currentUser);
        
        return new ConversationDTO(
            otherUser.getId(),
            convertToUserDTO(otherUser),
            message.getContent(),
            message.getCreatedAt(),
            unreadCount.intValue(),
            false // TODO: Implement online status tracking
        );
    }
} 