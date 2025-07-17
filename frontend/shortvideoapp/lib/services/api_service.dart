import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shortvideoapp/services/storage_service.dart';
import 'package:shortvideoapp/models/user_model.dart';
import 'package:shortvideoapp/models/public_user_model.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8080/api';
  final StorageService _storageService = StorageService();

  // Register user
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success']) {
        // Save token and user data
        await _storageService.saveToken(data['accessToken']);
        await _storageService.saveUser(User.fromJson(data['user']));
        return {
          'success': true,
          'message': data['message'],
          'user': User.fromJson(data['user']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Login user
  Future<Map<String, dynamic>> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usernameOrEmail': usernameOrEmail,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        // Save token and user data
        await _storageService.saveToken(data['accessToken']);
        await _storageService.saveUser(User.fromJson(data['user']));
        return {
          'success': true,
          'message': data['message'],
          'user': User.fromJson(data['user']),
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get current user profile from local storage
  Future<User?> getCurrentUser() async {
    try {
      return await _storageService.getUser();
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  // Refresh current user profile from API and update local storage
  Future<Map<String, dynamic>> refreshCurrentUser() async {
    try {
      final currentUser = await _storageService.getUser();
      if (currentUser == null) {
        return {'success': false, 'message': 'No user logged in'};
      }

      final token = await _storageService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token not found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/users/${currentUser.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final publicUserData = jsonDecode(response.body);

        // Convert public user data back to User model (keeping email from local storage)
        final updatedUser = User(
          id: publicUserData['id'],
          username: publicUserData['username'],
          email: currentUser.email, // Keep email from local storage
          fullName: publicUserData['fullName'],
          profilePictureUrl: publicUserData['profilePictureUrl'],
          bio: publicUserData['bio'],
          followersCount: publicUserData['followersCount'] ?? 0,
          followingCount: publicUserData['followingCount'] ?? 0,
          createdAt: DateTime.parse(publicUserData['createdAt']),
        );

        // Update local storage with fresh data
        await _storageService.saveUser(updatedUser);

        return {'success': true, 'user': updatedUser};
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'User not found'};
      } else {
        return {'success': false, 'message': 'Failed to refresh user profile'};
      }
    } catch (e) {
      print('Refresh current user error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get user by ID (returns public profile without email)
  Future<Map<String, dynamic>> getUserById(int userId) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token not found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'user': PublicUser.fromJson(data)};
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'User not found'};
      } else {
        return {'success': false, 'message': 'Failed to load user profile'};
      }
    } catch (e) {
      print('Get user by ID error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get user by username (returns public profile without email)
  Future<Map<String, dynamic>> getUserByUsername(String username) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token not found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/users/username/$username'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'user': PublicUser.fromJson(data)};
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'User not found'};
      } else {
        return {'success': false, 'message': 'Failed to load user profile'};
      }
    } catch (e) {
      print('Get user by username error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      final token = await _storageService.getToken();
      if (token != null) {
        await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
    } catch (e) {
      print('Logout error: $e');
    } finally {
      // Clear local storage
      await _storageService.clearAll();
    }
  }

  // Get videos
  Future<Map<String, dynamic>> getVideos({
    required int page,
    required int size,
    required String sortBy,
  }) async {
    try {
      final token = await _storageService.getToken();
      if (token != null) {
        final response = await http.get(
          Uri.parse('$baseUrl/videos?page=$page&size=$size&sortBy=$sortBy'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          },
        );

        // Decode response body as UTF-8 to make accents work
        final String utf8Body = utf8.decode(response.bodyBytes);

        final data = jsonDecode(utf8Body);
        return data;
      }
      return {'success': false, 'message': 'Token not found'};
    } catch (e) {
      print('getVideos error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get user's public videos
  Future<Map<String, dynamic>> getUserPublicVideos({
    required int userId,
    required int page,
    required int size,
  }) async {
    try {
      final token = await _storageService.getToken();
      if (token != null) {
        final response = await http.get(
          Uri.parse(
              '$baseUrl/videos/user/$userId/public?page=$page&size=$size'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          // Decode response body as UTF-8 to make accents work
          final String utf8Body = utf8.decode(response.bodyBytes);

          final data = jsonDecode(utf8Body);
          return {'success': true, 'data': data};
        } else {
          return {'success': false, 'message': 'Failed to load videos'};
        }
      }
      return {'success': false, 'message': 'Token not found'};
    } catch (e) {
      print('getUserPublicVideos error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get user's private videos
  Future<Map<String, dynamic>> getUserPrivateVideos({
    required int userId,
    required int page,
    required int size,
  }) async {
    try {
      final token = await _storageService.getToken();
      if (token != null) {
        final response = await http.get(
          Uri.parse(
              '$baseUrl/videos/user/$userId/private?page=$page&size=$size'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return {'success': true, 'data': data};
        } else {
          return {'success': false, 'message': 'Failed to load videos'};
        }
      }
      return {'success': false, 'message': 'Token not found'};
    } catch (e) {
      print('getUserPrivateVideos error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get user's liked videos
  Future<Map<String, dynamic>> getUserLikedVideos({
    required int userId,
    required int page,
    required int size,
  }) async {
    try {
      final token = await _storageService.getToken();
      if (token != null) {
        final response = await http.get(
          Uri.parse('$baseUrl/videos/user/$userId/liked?page=$page&size=$size'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return {'success': true, 'data': data};
        } else {
          return {'success': false, 'message': 'Failed to load videos'};
        }
      }
      return {'success': false, 'message': 'Token not found'};
    } catch (e) {
      print('getUserLikedVideos error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Post comment to video
  Future<Map<String, dynamic>> postComment(String videoId, String text,
      {String? parentCommentId}) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token not found'};
      }

      final body = {'text': text};
      if (parentCommentId != null) {
        body['parentCommentId'] = parentCommentId;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/videos/$videoId/comments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'comment': data['comment'],
          'commentsCount': data['commentsCount'],
          'message': data['message'] ?? 'Comment posted successfully',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to post comment',
        };
      }
    } catch (e) {
      print('Post comment error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get video comments
  Future<Map<String, dynamic>> getVideoComments(String videoId,
      {int page = 0, int size = 20}) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token not found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/videos/$videoId/comments?page=$page&size=$size'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'comments': data['content'] ?? [],
          'totalPages': data['totalPages'] ?? 0,
          'totalElements': data['totalElements'] ?? 0,
        };
      } else {
        return {'success': false, 'message': 'Failed to load comments'};
      }
    } catch (e) {
      print('Get comments error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Like/unlike comment
  Future<Map<String, dynamic>> toggleCommentLike(String commentId) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token not found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/videos/comments/$commentId/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'isLiked': data['isLiked'] ?? false,
          'likesCount': data['likesCount'] ?? 0,
          'message': data['message'] ?? 'Success',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to like comment',
        };
      }
    } catch (e) {
      print('Toggle comment like error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Delete comment
  Future<Map<String, dynamic>> deleteComment(
      String commentId, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/videos/comments/$commentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'commentsCount': data['commentsCount'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete comment'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Check if video is liked
  Future<Map<String, dynamic>> isVideoLiked(String videoId) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token not found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/videos/$videoId/liked'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'isLiked': data['isLiked'] ?? false,
          'likesCount': data['likesCount'] ?? 0,
        };
      } else {
        return {'success': false, 'message': 'Failed to check like status'};
      }
    } catch (e) {
      print('Check like status error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Likes the video
  Future<Map<String, dynamic>> likeVideo(String videoId) async {
    try {
      final token = await _storageService.getToken();
      if (token == null) {
        return {'success': false, 'message': 'Token not found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/videos/$videoId/like'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'isLiked': data['isLiked'] ?? false,
          'likesCount': data['likesCount'] ?? 0,
          'message': data['message'] ?? 'Success',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to like video',
        };
      }
    } catch (e) {
      print('Like video error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Verify token
  Future<bool> verifyToken() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/auth/verify-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'];
    } catch (e) {
      return false;
    }
  }

  // Get authenticated request headers
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await _storageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get auth token for video requests
  Future<String?> getAuthToken() async {
    return await _storageService.getToken();
  }

  // Get video streaming URL with authentication
  Future<String> getVideoStreamingUrl(String videoId) async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('Authentication required');
    }
    return '$baseUrl/stream/video/$videoId';
  }

  // Get thumbnail URL with authentication
  Future<String> getThumbnailUrl(String videoId) async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('Authentication required');
    }
    return '$baseUrl/stream/thumbnail/$videoId';
  }

  // Get profile image URL with authentication
  Future<String> getProfileImageUrl(String? profilePictureUrl,
      {String? userId}) async {
    if (userId != null && userId.isNotEmpty) {
      final token = await _storageService.getToken();
      if (token != null) {
        return '$baseUrl/stream/profile-image/$userId';
      }
    }

    return "null";
  }

  // Get profile image URL for a specific user ID
  Future<String> getProfileImageUrlForUser(String userId) async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('Authentication required');
    }
    return '$baseUrl/stream/profile-image/$userId';
  }

  // Get static asset URL
  String getStaticAssetUrl(String assetPath) {
    return 'http://10.0.2.2:8080/$assetPath';
  }

  // Get thumbnail image provider for a video
  Future<ImageProvider> getThumbnailImageProvider(String videoId) async {
    final url = await getThumbnailUrl(videoId);
    return NetworkImage(url);
  }

  // Get authenticated headers for image requests
  Future<Map<String, String>> getImageHeaders() async {
    final token = await _storageService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'User-Agent': 'ShortVideoApp/1.0 (Mobile)',
      'Accept': 'image/*,*/*;q=0.9',
    };
  }
}
