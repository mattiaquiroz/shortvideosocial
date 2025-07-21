import 'package:flutter/material.dart';
import 'package:shortvideoapp/services/api_service.dart';
import 'package:shortvideoapp/models/user_model.dart';
import 'package:shortvideoapp/screens/main/chat_screen.dart';

class NewMessageScreen extends StatefulWidget {
  const NewMessageScreen({super.key});

  @override
  State<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoading = false;
  bool _isLoadingAllUsers = false;
  String? _errorMessage;
  bool _hasSearched = false;
  bool _showAllUsers = true;

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllUsers() async {
    setState(() {
      _isLoadingAllUsers = true;
      _errorMessage = null;
    });

    try {
      final results = await _apiService.getAllUsersForMessaging();
      print('Loaded ${results.length} users for messaging');
      if (results.isNotEmpty) {
        print('First user data: ${results.first}');
      }
      setState(() {
        _allUsers = results;
        _isLoadingAllUsers = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        _errorMessage = 'Failed to load users: $e';
        _isLoadingAllUsers = false;
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _showAllUsers = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showAllUsers = false;
    });

    try {
      final results = await _apiService.searchUsers(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
        _hasSearched = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to search users: $e';
        _isLoading = false;
        _hasSearched = true;
      });
    }
  }

  void _startConversation(Map<String, dynamic> userData) {
    try {
      final user = User.fromJson(userData);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChatScreen(otherUser: user),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start conversation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'New Message',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (value == _searchController.text) {
                    _searchUsers(value);
                  }
                });
              },
            ),
          ),

          // Search results
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_showAllUsers) {
      if (_isLoadingAllUsers) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_allUsers.isEmpty) {
        return _buildEmptyAllUsersState();
      }

      return ListView.builder(
        itemCount: _allUsers.length,
        itemBuilder: (context, index) {
          final userData = _allUsers[index];
          return _buildUserTile(userData);
        },
      );
    }

    if (!_hasSearched) {
      return _buildInitialState();
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final userData = _searchResults[index];
        return _buildUserTile(userData);
      },
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Search for users',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a username or full name to find users\nor browse all users below',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with a different term',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAllUsersState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No users available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no other users to message',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Search Error',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'An unknown error occurred',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _errorMessage = null;
              });
              if (_searchController.text.isNotEmpty) {
                _searchUsers(_searchController.text);
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> userData) {
    final username = userData['username']?.toString() ?? '';
    final fullName = userData['fullName']?.toString() ?? '';
    final profilePictureUrl = userData['profilePictureUrl']?.toString();
    final bio = userData['bio']?.toString() ?? '';
    final userId = userData['id']?.toString() ?? '';

    return ListTile(
      leading: FutureBuilder<String>(
        future: _apiService.getProfileImageUrl(
          profilePictureUrl,
          userId: userId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey[300],
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            );
          }

          if (snapshot.hasError ||
              snapshot.data == null ||
              snapshot.data == "null") {
            return CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey[300],
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          return FutureBuilder<Map<String, String>>(
            future: _apiService.getImageHeaders(),
            builder: (context, headersSnapshot) {
              return CircleAvatar(
                radius: 25,
                backgroundColor: Colors.grey[300],
                child: ClipOval(
                  child: Image.network(
                    snapshot.data!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    headers: headersSnapshot.data ?? {},
                    errorBuilder: (context, error, stackTrace) {
                      return CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.grey[300],
                        child: Text(
                          username.isNotEmpty ? username[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }
                      return CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.grey[300],
                        child: const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      title: Text(
        fullName.isNotEmpty ? fullName : username,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '@$username',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              bio,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Colors.grey[400],
        size: 16,
      ),
      onTap: () => _startConversation(userData),
    );
  }
}
