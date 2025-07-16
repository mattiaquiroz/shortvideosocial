import 'package:flutter/material.dart';
import 'package:shortvideoapp/services/api_service.dart';
import 'package:video_player/video_player.dart';
import 'dart:math';
import 'package:shortvideoapp/constants/strings.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.homePage,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  int selectedTab = 1;
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, bool> isVideoLiked = {};

  List<Map<String, String>> videosData = [];

  // Current video for each tab
  late Map<String, String> currentFollowingVideo;
  late Map<String, String> currentForYouVideo;

  // Temporary empty video data for initialization
  final Map<String, String> _emptyVideoData = {
    'title': '',
    'description': '',
    'videoUrl': '',
    'likesCount': '0',
    'commentsCount': '0',
    'sharesCount': '0',
    'viewsCount': '0',
    'createdAt': '',
    'userId': '',
  };

  // Random number generator
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    currentFollowingVideo = _emptyVideoData;
    currentForYouVideo = _emptyVideoData;
    _loadVideosAndInitialize();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Map<String, String> _getRandomVideoExcluding(
    Map<String, String> excludeVideo,
  ) {
    final availableVideos = videosData
        .where((video) => video != excludeVideo)
        .toList();
    if (availableVideos.isEmpty) return videosData[0];
    return availableVideos[_random.nextInt(availableVideos.length)];
  }

  void _loadNewRandomVideo() {
    Map<String, String> currentVideo = selectedTab == 0
        ? currentFollowingVideo
        : currentForYouVideo;
    Map<String, String> newVideo = _getRandomVideoExcluding(currentVideo);

    if (selectedTab == 0) {
      currentFollowingVideo = newVideo;
    } else {
      currentForYouVideo = newVideo;
    }

    _controller?.dispose();
    _controller = null;
    _initializeVideo();
  }

  void _retryVideo() {
    _controller?.dispose();
    _controller = null;
    _loadVideosAndInitialize();
  }

  void _switchTab(int index) {
    setState(() {
      selectedTab = index;
    });
    _controller?.dispose();
    _controller = null;
    _initializeVideo();
  }

  String _getCurrentVideoDescription() {
    Map<String, String> currentVideo = selectedTab == 0
        ? currentFollowingVideo
        : currentForYouVideo;

    return currentVideo['description']!;
  }

  String _getCurrentVideoUser() {
    Map<String, String> currentVideo = selectedTab == 0
        ? currentFollowingVideo
        : currentForYouVideo;

    return currentVideo['userUsername']!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTabButton(AppStrings.following, 0),
            SizedBox(width: 40),
            _buildTabButton(AppStrings.forYou, 1),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white, size: 28),
            onPressed: () {
              print("Search pressed");
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () => _switchTab(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          SizedBox(height: 4),
          Container(
            height: 2,
            width: 40,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return GestureDetector(
      onTap: () {
        if (_isInitialized && !_hasError && _controller != null) {
          setState(() {
            if (_controller!.value.isPlaying) {
              _controller!.pause();
            } else {
              _controller!.play();
            }
          });
        }
      },
      onVerticalDragEnd: (DragEndDetails details) {
        if (details.primaryVelocity! < -200) {
          _loadNewRandomVideo();
        }
      },
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            // Video Player
            _isInitialized && _controller != null
                ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller!.value.size.width,
                        height: _controller!.value.size.height,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
                  )
                : Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.purple.withOpacity(0.3),
                          Colors.black,
                          Colors.blue.withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: Center(
                      child: _hasError
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.white,
                                  size: 64,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  _errorMessage,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _retryVideo,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                  ),
                                  child: Text(AppStrings.retry),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(height: 16),
                                Text(
                                  AppStrings.loadingVideo,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

            Center(
              child: _isInitialized && _controller != null
                  ? _controller!.value.isPlaying
                        ? null
                        : Icon(
                            Icons.play_arrow,
                            color: const Color.fromARGB(125, 255, 255, 255),
                            size: 64,
                          )
                  : null,
            ),

            // Video Controls Overlay
            Positioned(
              bottom: 20,
              right: 20,
              child: Column(
                children: [
                  _buildActionButton(
                    isVideoLiked[selectedTab == 0
                                ? (currentFollowingVideo['id'] ?? '')
                                : (currentForYouVideo['id'] ?? '')] ==
                            true
                        ? Icons.favorite
                        : Icons.favorite_border,
                    selectedTab == 0
                        ? currentFollowingVideo['likesCount']!
                        : currentForYouVideo['likesCount']!,
                    onTap: () {
                      final videoId = selectedTab == 0
                          ? currentFollowingVideo['id']
                          : currentForYouVideo['id'];
                      if (videoId != null && videoId.isNotEmpty) {
                        _likeVideo(videoId);
                      }
                    },
                  ),
                  SizedBox(height: 24),
                  _buildActionButton(
                    Icons.comment,
                    selectedTab == 0
                        ? currentFollowingVideo['commentsCount']!
                        : currentForYouVideo['commentsCount']!,
                  ),
                  SizedBox(height: 24),
                  _buildActionButton(
                    Icons.share,
                    selectedTab == 0
                        ? currentFollowingVideo['sharesCount']!
                        : currentForYouVideo['sharesCount']!,
                  ),
                  SizedBox(height: 24),
                  _buildProfileButton(),
                ],
              ),
            ),

            // Video Info Overlay
            Positioned(
              bottom: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hasError
                        ? AppStrings.videoFailedToLoad
                        : _isInitialized
                        ? _getCurrentVideoUser()
                        : AppStrings.loadingVideo,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _hasError
                        ? AppStrings.videoFailedToLoad
                        : _isInitialized
                        ? _getCurrentVideoDescription()
                        : AppStrings.loadingVideo,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          if (label.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileButton() {
    return GestureDetector(
      onTap: () {
        // TODO: Implement profile navigation
        print("Profile button pressed");
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          shape: BoxShape.circle,
        ),
        child: CircleAvatar(
          radius: 22,
          backgroundImage: NetworkImage(AppStrings.userAvatarUrl),
        ),
      ),
    );
  }

  Future<void> _loadVideosAndInitialize() async {
    try {
      await _getVideos();

      if (!mounted) return;

      if (videosData.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = AppStrings.noVideosAvailable;
        });
        return;
      }

      setState(() {
        currentFollowingVideo = videosData[0];
        currentForYouVideo = videosData[0];
        _hasError = false;
        _errorMessage = '';
      });

      await _loadLikeStatusForVideos();

      _initializeVideo();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hasError = true;
        _errorMessage = '${AppStrings.failedToLoadVideos}: ${e.toString()}';
      });
    }
  }

  Future<void> _loadLikeStatusForVideos() async {
    for (var video in videosData) {
      final videoId = video['id'];
      if (videoId != null && videoId.isNotEmpty) {
        try {
          final response = await _apiService.isVideoLiked(videoId);
          if (response['success'] == true) {
            setState(() {
              isVideoLiked[videoId] = response['isLiked'] ?? false;
            });
          }
        } catch (e) {
          print('Error loading like status for video $videoId: $e');
        }
      }
    }
  }

  void _initializeVideo() {
    _controller?.dispose();
    _controller = null;

    setState(() {
      _isInitialized = false;
      _hasError = false;
      _errorMessage = '';
    });

    Map<String, String> videoToPlay = selectedTab == 0
        ? currentFollowingVideo
        : currentForYouVideo;

    try {
      _controller = VideoPlayerController.asset(videoToPlay['videoUrl']!);

      _controller
          ?.initialize()
          .then((_) {
            if (!mounted) return;
            setState(() {
              _isInitialized = true;
              _hasError = false;
            });
            _controller?.play();
            _controller?.setLooping(true);
          })
          .catchError((error) {
            if (!mounted) return;
            setState(() {
              _isInitialized = false;
              _hasError = true;
              _errorMessage = AppStrings.videoFailedToLoad;
            });
          });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitialized = false;
        _hasError = true;
        _errorMessage = '${AppStrings.videoFailedToLoad}: ${e.toString()}';
      });
    }
  }

  Future<void> _getVideos() async {
    try {
      final response = await _apiService.getVideos(
        page: 0,
        size: 10,
        sortBy: 'popular',
      );

      if (response['content'] != null) {
        setState(() {
          videosData.clear();
          isVideoLiked.clear();
          for (var video in response['content']) {
            final videoId = (video['id'] ?? '').toString();
            if (videoId.isNotEmpty) {
              videosData.add({
                'id': videoId,
                'userUsername': video['user']?['username'] ?? '',
                'description': video['description'] ?? '',
                'videoUrl': video['videoUrl'] ?? '',
                'likesCount': (video['likesCount'] ?? 0).toString(),
                'commentsCount': (video['commentsCount'] ?? 0).toString(),
                'sharesCount': (video['sharesCount'] ?? 0).toString(),
                'viewsCount': (video['viewsCount'] ?? 0).toString(),
                'createdAt': video['createdAt'] ?? '',
                'userId': (video['user']?['id'] ?? '').toString(),
              });
              isVideoLiked[videoId] = false;
            }
          }
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch videos');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Couldn't fetch videos: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> _likeVideo(String videoId) async {
    try {
      await _apiService.likeVideo(videoId);

      setState(() {
        final bool currentLikeState = isVideoLiked[videoId] ?? false;
        if (!currentLikeState) {
          selectedTab == 0
              ? currentFollowingVideo['likesCount'] =
                    (int.parse(currentFollowingVideo['likesCount']!) + 1)
                        .toString()
              : currentForYouVideo['likesCount'] =
                    (int.parse(currentForYouVideo['likesCount']!) + 1)
                        .toString();
        } else {
          selectedTab == 0
              ? currentFollowingVideo['likesCount'] =
                    (int.parse(currentFollowingVideo['likesCount']!) - 1)
                        .toString()
              : currentForYouVideo['likesCount'] =
                    (int.parse(currentForYouVideo['likesCount']!) - 1)
                        .toString();
        }
        isVideoLiked[videoId] = !currentLikeState;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Couldn't like video: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }
}
