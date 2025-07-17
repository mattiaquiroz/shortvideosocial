import 'package:flutter/material.dart';
import 'package:shortvideoapp/models/public_user_model.dart';
import 'package:shortvideoapp/screens/settings/settings.dart';
import 'package:shortvideoapp/screens/main/single_video_player.dart';
import 'package:shortvideoapp/constants/strings.dart';
import 'package:shortvideoapp/services/api_service.dart';
import 'package:shortvideoapp/models/user_model.dart';

class Profile extends StatelessWidget {
  final int userId;
  final String username;
  final bool isPublicUser;
  const Profile(
      {super.key,
      required this.userId,
      required this.username,
      required this.isPublicUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.profile,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ProfilePage(
          userId: userId, username: username, isPublicUser: isPublicUser),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ProfilePage extends StatefulWidget {
  final int userId;
  final String username;
  final bool isPublicUser;
  const ProfilePage(
      {super.key,
      required this.userId,
      required this.username,
      required this.isPublicUser});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int selectedTab = 0;
  bool showNameInAppBar = false;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _nameKey = GlobalKey();
  final ApiService _apiService = ApiService();

  dynamic currentUser;
  bool isLoading = true;
  bool isOwnProfile = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Then refresh from API to get latest data
      if (widget.userId != -1) {
        final result = await _apiService.getUserById(widget.userId);
        final localUser = await _apiService.getCurrentUser();
        if (result['success']) {
          setState(() {
            currentUser = result['user'];
            if (localUser != null) {
              if (localUser.id == widget.userId) {
                isOwnProfile = true;
              }
            }
            isLoading = false;
          });
        } else {
          // If refresh fails but we have local data, just use that
          if (currentUser == null) {
            setState(() {
              errorMessage = result['message'] ?? 'Failed to load user profile';
              isLoading = false;
            });
          }
        }
      } else {
        final result = await _apiService.refreshCurrentUser();
        if (result['success']) {
          setState(() {
            currentUser = result['user'];
            isOwnProfile = true;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = result['message'] ?? 'Failed to load user profile';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading profile: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  void _onScroll() {
    if (_nameKey.currentContext != null) {
      final RenderBox nameBox =
          _nameKey.currentContext!.findRenderObject() as RenderBox;
      final namePosition = nameBox.localToGlobal(Offset.zero);

      final shouldShowName = namePosition.dy < 75;

      if (shouldShowName != showNameInAppBar) {
        setState(() {
          showNameInAppBar = shouldShowName;
        });
      }
    }
  }

  Future<String> _getProfileImageUrl() async {
    String? profileUrl = currentUser?.profilePictureUrl;
    final userId = currentUser?.id.toString();

    if (userId != null) {
      return await _apiService.getProfileImageUrl(profileUrl, userId: userId);
    }

    return _apiService.getProfileImageUrl(userId);
  }

  // Grid content per tab
  Future<List<Map<String, dynamic>>> _loadVideosForTab(int tabIndex) async {
    if (currentUser == null) return [];

    final userId = currentUser!.id;
    Map<String, dynamic> response;

    switch (tabIndex) {
      case 0:
        // Public videos
        response = await _apiService.getUserPublicVideos(
          userId: userId,
          page: 0,
          size: 50,
        );
        break;
      case 1:
        // Private videos
        response = await _apiService.getUserPrivateVideos(
          userId: userId,
          page: 0,
          size: 50,
        );
        break;
      case 2:
        // Liked videos
        response = await _apiService.getUserLikedVideos(
          userId: userId,
          page: 0,
          size: 50,
        );
        break;
      default:
        return [];
    }

    if (response['success'] && response['data'] != null) {
      final content = response['data']['content'] as List<dynamic>?;
      if (content != null) {
        return content
            .map((video) => Map<String, dynamic>.from(video))
            .toList();
      }
    }

    return [];
  }

  // Build grid items for sliver grid
  List<Widget> _buildGridItems(List<Map<String, dynamic>> videos) {
    return List.generate(videos.length, (index) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SingleVideoPlayerScreen(videoData: videos[index]),
            ),
          );
        },
        child: FutureBuilder<List<dynamic>>(
          future: Future.wait([
            _getThumbnailUrl(videos[index]),
            _apiService.getImageHeaders(),
          ]),
          builder: (context, thumbnailSnapshot) {
            if (thumbnailSnapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                width: 120,
                height: 120,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              );
            }

            if (thumbnailSnapshot.hasError) {
              return SizedBox(
                width: 120,
                height: 120,
                child: Icon(
                  Icons.error,
                  size: 60,
                  color: Colors.grey[600],
                ),
              );
            }

            final thumbnailUrl = thumbnailSnapshot.data?[0] as String? ??
                'https://via.placeholder.com/300x500.png?text=Error';
            final headers =
                thumbnailSnapshot.data?[1] as Map<String, String>? ?? {};
            final viewCount = videos[index]['viewsCount'] ?? 0;

            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    thumbnailUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    headers: headers,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
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
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.play_arrow,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          viewCount.toString(),
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
      );
    });
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

  // Tab Icon builder
  Widget _buildTabIcon(IconData icon, int index) {
    final isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: Column(
        children: [
          Icon(icon, size: 28, color: isSelected ? Colors.blue : Colors.grey),
          const SizedBox(height: 4),
          Container(
            height: 3,
            width: 24,
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: !widget.isPublicUser
            ? null
            : IconButton(
                icon: const Icon(Icons.keyboard_arrow_left, size: 30),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
        title: Text(
          widget.isPublicUser ? "" : AppStrings.profile,
          style:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        flexibleSpace: SafeArea(
          child: Center(
            child: AnimatedOpacity(
              opacity: showNameInAppBar ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                currentUser?.username ?? "null",
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ),
        actions: [
          if (!widget.isPublicUser)
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.black),
              onPressed: () {
                // Notifications functionality
              },
            ),
          if (!widget.isPublicUser)
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const SettingsPage(),
                    transitionDuration: const Duration(milliseconds: 300),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.ease;

                      var tween = Tween(
                        begin: begin,
                        end: end,
                      ).chain(CurveTween(curve: curve));

                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                  ),
                );
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(errorMessage!,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : FutureBuilder<List<Map<String, dynamic>>>(
                  future: _loadVideosForTab(selectedTab),
                  builder: (context, snapshot) {
                    final videos = snapshot.data ?? [];
                    return RefreshIndicator(
                      backgroundColor: Colors.white,
                      onRefresh: _loadUserProfile,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        controller: _scrollController,
                        slivers: [
                          SliverToBoxAdapter(
                            child: Column(
                              children: [
                                const SizedBox(height: 16),
                                FutureBuilder<List<dynamic>>(
                                  future: Future.wait([
                                    _getProfileImageUrl(),
                                    _apiService.getImageHeaders(),
                                  ]),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return CircleAvatar(
                                        radius: 60,
                                        backgroundColor: Colors.grey[300],
                                        child: const CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.blue),
                                        ),
                                      );
                                    }

                                    if (snapshot.hasError) {
                                      return CircleAvatar(
                                        radius: 60,
                                        backgroundColor: Colors.grey[300],
                                        child: Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.grey[600],
                                        ),
                                      );
                                    }

                                    final imageUrl =
                                        snapshot.data?[0] as String? ?? "null";
                                    final headers = snapshot.data?[1]
                                            as Map<String, String>? ??
                                        {};

                                    return CircleAvatar(
                                      radius: 60,
                                      backgroundColor: Colors.grey[300],
                                      child: ClipOval(
                                        child: Image.network(
                                          imageUrl!,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          headers: headers,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const SizedBox.shrink();
                                          },
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return const SizedBox(
                                              width: 120,
                                              height: 120,
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(Colors.blue),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  key: _nameKey,
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      currentUser?.fullName ??
                                          currentUser?.username ??
                                          "null",
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (isOwnProfile)
                                      IconButton(
                                        onPressed: () {},
                                        icon: const Icon(Icons.edit,
                                            color: Colors.white),
                                        style: ButtonStyle(
                                          backgroundColor:
                                              WidgetStateProperty.all<Color>(
                                            Colors.black,
                                          ),
                                          padding: WidgetStateProperty.all<
                                              EdgeInsets>(
                                            const EdgeInsets.all(8),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "${currentUser?.followersCount ?? 0} ${AppStrings.followersLabel} | ${currentUser?.followingCount ?? 0} ${AppStrings.followingLabel} | ${AppStrings.userTotalLikes} ${AppStrings.likesLabel}",
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 8),
                                Card(
                                  color:
                                      const Color.fromARGB(255, 248, 248, 248),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      currentUser?.bio ?? "",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Tab selector
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildTabIcon(Icons.grid_on, 0),
                                    const SizedBox(width: 50),
                                    _buildTabIcon(Icons.lock, 1),
                                    const SizedBox(width: 50),
                                    _buildTabIcon(Icons.favorite, 2),
                                  ],
                                ),

                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (snapshot.hasError)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Text(
                                  'Error loading videos: ${snapshot.error.toString()}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            )
                          else if (videos.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Center(
                                  child: Text(
                                    AppStrings.noVideosYet,
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 16),
                                  ),
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 0.0),
                              sliver: SliverGrid(
                                delegate: SliverChildListDelegate(
                                  _buildGridItems(videos),
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 2,
                                  mainAxisSpacing: 2,
                                  childAspectRatio: 9 / 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
