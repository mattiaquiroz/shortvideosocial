import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:math';
import 'constants/strings.dart';

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
  int selectedTab = 1;
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  // All available videos
  final List<String> allVideos = [
    'assets/videos/Video_YTShorts_3.mp4',
    'assets/videos/Video_YTShorts_4.mp4',
    'assets/videos/Video_YTShorts_5.mp4',
  ];

  // Current video for each tab
  late String currentFollowingVideo;
  late String currentForYouVideo;

  // Random number generator
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Initialize with random videos
    currentFollowingVideo = _getRandomVideo();
    currentForYouVideo = _getRandomVideo();

    _initializeVideo();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getRandomVideo() {
    return allVideos[_random.nextInt(allVideos.length)];
  }

  String _getRandomVideoExcluding(String excludeVideo) {
    final availableVideos = allVideos
        .where((video) => video != excludeVideo)
        .toList();
    if (availableVideos.isEmpty) return allVideos[0];
    return availableVideos[_random.nextInt(availableVideos.length)];
  }

  void _loadNewRandomVideo() {
    String currentVideo = selectedTab == 0
        ? currentFollowingVideo
        : currentForYouVideo;
    String newVideo = _getRandomVideoExcluding(currentVideo);

    if (selectedTab == 0) {
      currentFollowingVideo = newVideo;
    } else {
      currentForYouVideo = newVideo;
    }

    _controller.dispose();
    _initializeVideo();
  }

  void _initializeVideo() {
    setState(() {
      _isInitialized = false;
      _hasError = false;
      _errorMessage = '';
    });

    String videoToPlay = selectedTab == 0
        ? currentFollowingVideo
        : currentForYouVideo;

    _controller = VideoPlayerController.asset(videoToPlay);

    _controller
        .initialize()
        .then((_) {
          setState(() {
            _isInitialized = true;
            _hasError = false;
          });
          _controller.play();
          _controller.setLooping(true);
        })
        .catchError((error) {
          // Handle video initialization error
          setState(() {
            _isInitialized = false;
            _hasError = true;
            _errorMessage = AppStrings.videoFailedToLoad;
          });
        });
  }

  void _retryVideo() {
    _controller.dispose();
    _initializeVideo();
  }

  void _switchTab(int index) {
    setState(() {
      selectedTab = index;
    });
    _controller.dispose();
    _initializeVideo();
  }

  String _getCurrentVideoName() {
    String currentVideo = selectedTab == 0
        ? currentFollowingVideo
        : currentForYouVideo;
    // Extract filename from path and remove extension
    String fileName = currentVideo.split('/').last;
    return fileName.replaceAll('.mp4', '').replaceAll('_', ' ');
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
        if (_isInitialized && !_hasError) {
          setState(() {
            _controller.value.isPlaying
                ? _controller.pause()
                : _controller.play();
          });
        }
      },
      onVerticalDragEnd: (DragEndDetails details) {
        // Check if swipe was upward (next video) - reduced sensitivity for easier triggering
        print('Swipe detected: ${details.primaryVelocity}');
        if (details.primaryVelocity! < -200) {
          print('Loading new video!');
          _loadNewRandomVideo();
        }
      },
      child: Container(
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            // Video Player
            _isInitialized
                ? SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
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
                          Colors.purple.withValues(alpha: 0.3),
                          Colors.black,
                          Colors.blue.withValues(alpha: 0.3),
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
              child: _isInitialized
                  ? _controller.value.isPlaying
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
                  _buildActionButton(Icons.favorite, AppStrings.likes),
                  SizedBox(height: 24),
                  _buildActionButton(Icons.comment, AppStrings.comments),
                  SizedBox(height: 24),
                  _buildActionButton(Icons.share, AppStrings.share),
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
                    selectedTab == 0
                        ? AppStrings.followingFeed
                        : AppStrings.forYouFeed,
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
                        ? _getCurrentVideoName()
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
}
