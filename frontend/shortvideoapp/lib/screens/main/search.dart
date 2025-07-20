import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shortvideoapp/services/api_service.dart';
import 'package:shortvideoapp/constants/strings.dart';
import 'package:shortvideoapp/screens/main/single_video_player.dart';
import 'package:shortvideoapp/screens/main/profile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  List<Map<String, dynamic>> _videos = [];
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _videos = [];
        _users = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      // Search for videos and users in parallel
      final results = await Future.wait([
        _apiService.searchVideos(query),
        _apiService.searchUsers(query),
      ]);

      setState(() {
        _videos = List<Map<String, dynamic>>.from(results[0]);
        _users = List<Map<String, dynamic>>.from(results[1]);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    Future<String> _getThumbnailUrl(Map<String, dynamic> video) async {
      final videoId = video['id']?.toString() ?? '';
      if (videoId.isEmpty) {
        return 'https://via.placeholder.com/300x500.png?text=No+Thumbnail';
      }

      try {
        return await _apiService.getThumbnailUrl(videoId);
      } catch (e) {
        return 'https://via.placeholder.com/300x500.png?text=Error';
      }
    }

    Future<String> _getUserProfileImageUrl(Map<String, dynamic>? user) async {
      if (user == null) {
        return 'https://via.placeholder.com/300x500.png?text=No+Profile';
      }

      final userId = user['id']?.toString() ?? '';
      if (userId.isEmpty) {
        return 'https://via.placeholder.com/300x500.png?text=No+Profile';
      }

      try {
        return await _apiService.getProfileImageUrl(null, userId: userId);
      } catch (e) {
        return 'https://via.placeholder.com/300x500.png?text=Error';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Container(
          width: double.infinity,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: AppStrings.search,
              hintStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              isDense: true,
            ),
            onSubmitted: _performSearch,
            textInputAction: TextInputAction.search,
          ),
        ),
        centerTitle: true,
        toolbarHeight: 60,
      ),
      body: Column(
        children: [
          if (_hasSearched)
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: Colors.red,
                tabs: [
                  Tab(text: AppStrings.videos),
                  Tab(text: AppStrings.users),
                ],
              ),
            ),
          Expanded(
            child: _hasSearched
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _buildVideosTab(),
                      _buildUsersTab(),
                    ],
                  )
                : _buildInitialState(),
          ),
        ],
      ),
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
            AppStrings.searchForVideosAndUsers,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.searchDescription,
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

  Widget _buildVideosTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              AppStrings.noVideosFound,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 2,
        childAspectRatio: 0.5, // Adjust ratio to fill card dynamically
      ),
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        return _buildVideoCard(video);
      },
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SingleVideoPlayerScreen(videoData: video),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 10 /
                    16, // Vertical rectangle thumbnail (like TikTok/Instagram Reels)
                child: FutureBuilder<List<dynamic>>(
                  future: Future.wait([
                    _getThumbnailUrl(video),
                    _apiService.getImageHeaders(),
                  ]),
                  builder: (context, thumbnailSnapshot) {
                    if (thumbnailSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ),
                      );
                    }

                    if (thumbnailSnapshot.hasError) {
                      return Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.video_library,
                          size: 60,
                          color: Colors.grey[600],
                        ),
                      );
                    }

                    final thumbnailUrl = thumbnailSnapshot.data?[0]
                            as String? ??
                        'https://via.placeholder.com/300x500.png?text=Error';
                    final headers =
                        thumbnailSnapshot.data?[1] as Map<String, String>? ??
                            {};

                    return Stack(
                      children: [
                        Image.network(
                          thumbnailUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          headers: headers,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.video_library,
                                size: 60,
                                color: Colors.grey[600],
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.blue),
                                ),
                              ),
                            );
                          },
                        ),
                        // Date in bottom left
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _formatDate(video['createdAt']),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        // Views in bottom right
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.play_arrow,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '${video['viewsCount'] ?? 0}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video['description'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      FutureBuilder<List<dynamic>>(
                        future: Future.wait([
                          _getUserProfileImageUrl(video['user']),
                          _apiService.getImageHeaders(),
                        ]),
                        builder: (context, profileSnapshot) {
                          if (profileSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.grey[300],
                              child: const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.blue),
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }

                          final profileImageUrl =
                              profileSnapshot.data?[0] as String?;
                          final headers = profileSnapshot.data?[1]
                                  as Map<String, String>? ??
                              {};

                          if (profileImageUrl != null &&
                              profileImageUrl != "null") {
                            return CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.grey[300],
                              child: ClipOval(
                                child: Image.network(
                                  profileImageUrl,
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.cover,
                                  headers: headers,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Text(
                                      (video['user']?['username'] ?? 'U')[0]
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          }

                          return CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.grey[300],
                            child: Text(
                              (video['user']?['username'] ?? 'U')[0]
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        video['user']?['username'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.favorite,
                              size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            '${video['likesCount'] ?? 0}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              AppStrings.noUsersFound,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(
                userId: user['id'],
                username: user['username'],
                isPublicUser: true,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              FutureBuilder<List<dynamic>>(
                future: Future.wait([
                  _getUserProfileImageUrl(user),
                  _apiService.getImageHeaders(),
                ]),
                builder: (context, profileSnapshot) {
                  if (profileSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey[300],
                      child: const SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue),
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }

                  final profileImageUrl = profileSnapshot.data?[0] as String?;
                  final headers =
                      profileSnapshot.data?[1] as Map<String, String>? ?? {};

                  if (profileImageUrl != null && profileImageUrl != "null") {
                    return CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey[300],
                      child: ClipOval(
                        child: Image.network(
                          profileImageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          headers: headers,
                          errorBuilder: (context, error, stackTrace) {
                            return Text(
                              (user['username'] ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }

                  return CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.grey[300],
                    child: Text(
                      (user['username'] ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['username'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (user['bio'] != null && user['bio'].isNotEmpty)
                      Text(
                        user['bio'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${user['followersCount'] ?? 0} ${AppStrings.followers}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${user['videosCount'] ?? 0} ${AppStrings.videos}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _getThumbnailUrl(Map<String, dynamic> video) async {
    final videoId = video['id']?.toString() ?? '';

    try {
      return await _apiService.getThumbnailUrl(videoId);
    } catch (e) {
      return 'https://via.placeholder.com/300x500.png?text=Error';
    }
  }

  Future<String> _getUserProfileImageUrl(Map<String, dynamic>? user) async {
    final userId = user['id']?.toString() ?? '';

    try {
      return await _apiService.getProfileImageUrl(null, userId: userId);
    } catch (e) {
      return 'https://via.placeholder.com/300x500.png?text=Error';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';

    try {
      DateTime date;
      try {
        date = DateTime.parse(dateString);
      } catch (_) {
        try {
          String normalized =
              dateString.contains(' ') && !dateString.contains('T')
                  ? dateString.replaceFirst(' ', 'T')
                  : dateString;
          date = DateTime.parse(normalized);
        } catch (_) {
          return dateString; // fallback: show raw string
        }
      }

      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 30) {
        // For dates older than 30 days, show month and year
        if (now.year == date.year) {
          return DateFormat('d MMM').format(date); // e.g., "15 Jan"
        } else {
          return DateFormat('d MMM yyyy').format(date); // e.g., "15 Jan 2023"
        }
      } else if (difference.inDays > 0) {
        return '${difference.inDays}${AppStrings.day} ${AppStrings.ago}';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}${AppStrings.hour} ${AppStrings.ago}';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}${AppStrings.minute} ${AppStrings.ago}';
      } else {
        return AppStrings.now;
      }
    } catch (e) {
      return '';
    }
  }
}
