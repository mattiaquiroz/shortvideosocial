import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shortvideoapp/services/storage_service.dart';
import 'package:shortvideoapp/models/user_model.dart';

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
            'Authorization': 'Bearer $token',
          },
        );

        final data = jsonDecode(response.body);
        return data;
      }
      return {'success': false, 'message': 'Token not found'};
    } catch (e) {
      print('getVideos error: $e');
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
  Future<void> likeVideo(String videoId) async {
    try {
      final token = await _storageService.getToken();
      if (token != null) {
        await http.post(
          Uri.parse('$baseUrl/videos/$videoId/like'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
    } catch (e) {
      print('Like video error: $e');
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
}
