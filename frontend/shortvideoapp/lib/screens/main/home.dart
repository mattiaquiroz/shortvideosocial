import 'package:flutter/material.dart';
import 'package:shortvideoapp/screens/main/profile.dart';
import 'package:shortvideoapp/services/api_service.dart';
import 'package:shortvideoapp/services/video_player_service.dart';
import 'package:shortvideoapp/screens/main/comments_section.dart';
import 'package:shortvideoapp/constants/strings.dart';
import 'package:video_player/video_player.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  final ApiService _apiService = ApiService();
  final EnhancedVideoService _videoService = EnhancedVideoService();
  final PageController _pageController = PageController();

  int selectedTab = 1;
  List<Map<String, String>> videosData = [];
  int currentVideoIndex = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoService.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  // Method to pause current video when switching tabs
  void pauseCurrentVideo() {
    if (videosData.isNotEmpty && currentVideoIndex < videosData.length) {
      final videoId = videosData[currentVideoIndex]['id'];
      _videoService.pauseVideo(videoId!);
    }
  }

  // Method to resume current video when returning to home tab
  void resumeCurrentVideo() {
    if (videosData.isNotEmpty && currentVideoIndex < videosData.length) {
      final videoId = videosData[currentVideoIndex]['id'];
      _videoService.playVideo(videoId!);
    }
  }

  Future<void> _loadVideos() async {
    try {
      final response = await _apiService.getVideos(
        page: 0,
        size: 20, // Load more videos for better preloading
        sortBy: selectedTab == 0 ? 'following' : 'popular',
      );

      if (response['content'] != null) {
        setState(() {
          videosData.clear();
          for (var video in response['content']) {
            final videoId = (video['id'] ?? '').toString();
            if (videoId.isNotEmpty) {
              videosData.add({
                'id': videoId,
                'userUsername': video['user']?['username'] ?? '',
                'userProfilePictureUrl':
                    video['user']?['profilePictureUrl'] ?? '',
                'description': video['description'] ?? '',
                'videoUrl': video['videoUrl'] ?? '',
                'likesCount': (video['likesCount'] ?? 0).toString(),
                'commentsCount': (video['commentsCount'] ?? 0).toString(),
                'sharesCount': (video['sharesCount'] ?? 0).toString(),
                'viewsCount': (video['viewsCount'] ?? 0).toString(),
                'createdAt': video['createdAt'] ?? '',
                'userId': (video['user']?['id'] ?? '').toString(),
              });
            }
          }
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading videos: $e")),
      );
    }
  }

  Future<void> _onPageChanged(int index) async {
    if (index != currentVideoIndex) {
      // Pause all videos first
      await _videoService.pauseAllVideos();

      setState(() {
        currentVideoIndex = index;
      });

      // Get URLs for preloading
      final currentVideo = videosData[index];
      final currentVideoId = currentVideo['id']!;
      final currentVideoUrl =
          await _apiService.getVideoStreamingUrl(currentVideoId);

      // Preload next and previous videos
      String? nextVideoId;
      String? nextVideoUrl;
      String? previousVideoId;
      String? previousVideoUrl;

      if (index + 1 < videosData.length) {
        nextVideoId = videosData[index + 1]['id'];
        nextVideoUrl = await _apiService.getVideoStreamingUrl(nextVideoId!);
      }

      if (index - 1 >= 0) {
        previousVideoId = videosData[index - 1]['id'];
        previousVideoUrl =
            await _apiService.getVideoStreamingUrl(previousVideoId!);
      }

      // Get auth token for video requests
      final authToken = await _apiService.getAuthToken();

      // Preload videos for smooth scrolling
      await _videoService.preloadVideos(
        currentVideoId,
        currentVideoUrl,
        nextVideoId,
        nextVideoUrl,
        previousVideoId,
        previousVideoUrl,
        authToken: authToken,
        context: 'home',
      );

      // Auto-play current video after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && currentVideoIndex == index) {
          _videoService.playVideo(currentVideoId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTabButton(AppStrings.following, 0),
            const SizedBox(width: 40),
            _buildTabButton(AppStrings.forYou, 1),
          ],
        ),
      ),
      body: Container(
        color: Colors.black,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: videosData.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final video = videosData[index];
                  return EnhancedVideoPlayer(
                    videoId: video['id']!,
                    videoData: video,
                    apiService: _apiService,
                    autoPlay: index == currentVideoIndex,
                  );
                },
              ),
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
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
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 40,
            color: isSelected ? Colors.white : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

class EnhancedVideoPlayer extends StatefulWidget {
  final String videoId;
  final Map<String, String> videoData;
  final ApiService apiService;
  final bool autoPlay;

  const EnhancedVideoPlayer({
    Key? key,
    required this.videoId,
    required this.videoData,
    required this.apiService,
    required this.autoPlay,
  }) : super(key: key);

  @override
  State<EnhancedVideoPlayer> createState() => _EnhancedVideoPlayerState();
}

class _EnhancedVideoPlayerState extends State<EnhancedVideoPlayer> {
  final EnhancedVideoService _videoService = EnhancedVideoService();
  bool _isInitialized = false;
  bool _hasError = false;
  String? _videoUrl;
  String _errorMessage = '';
  Map<String, bool> isVideoLiked = {};
  bool _isDragging = false;
  bool _isDoubleSpeed = false;
  double _playbackSpeed = 1.0;

  // Cache profile image data to prevent loading loop
  String? _profileImageUrl;
  Map<String, String>? _profileImageHeaders;
  bool _profileImageLoading = true;
  bool _profileImageError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _loadLikeStatus();
    _loadProfileImageData();
  }

  Future<void> _loadProfileImageData() async {
    try {
      final results = await Future.wait([
        widget.apiService.getProfileImageUrl(
            widget.videoData['userProfilePictureUrl'],
            userId: widget.videoData['userId'],
            cacheBust: true),
        widget.apiService.getImageHeaders(),
      ]);

      if (mounted) {
        setState(() {
          _profileImageUrl = results[0] as String;
          _profileImageHeaders = results[1] as Map<String, String>;
          _profileImageLoading = false;
          _profileImageError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _profileImageUrl = "null";
          _profileImageHeaders = {};
          _profileImageLoading = false;
          _profileImageError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    final controller = _videoService.getControllerSync(widget.videoId);
    if (controller != null) {
      controller.removeListener(() {});
    }
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoUrl = await widget.apiService.getVideoStreamingUrl(widget.videoId);
      final authToken = await widget.apiService.getAuthToken();
      final controller = await _videoService.getController(
        widget.videoId,
        _videoUrl!,
        authToken: authToken,
      );

      if (controller != null && mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });

        // Add listener for video state changes
        controller.addListener(() {
          if (mounted) {
            setState(() {});
          }
        });

        if (widget.autoPlay) {
          _videoService.playVideo(widget.videoId);
        }
      }
    } catch (e) {
      print('Error initializing video player: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load video: $e';
      });
    }
  }

  Future<void> _loadLikeStatus() async {
    try {
      final response = await widget.apiService.isVideoLiked(widget.videoId);
      if (response['success'] == true) {
        setState(() {
          isVideoLiked[widget.videoId] = response['isLiked'] ?? false;
        });
      }
    } catch (e) {
      print('Error loading like status: $e');
    }
  }

  Future<void> _likeVideo() async {
    try {
      final response = await widget.apiService.likeVideo(widget.videoId);

      if (response['success'] == true) {
        setState(() {
          isVideoLiked[widget.videoId] = response['isLiked'];
          // Update the like count in the video data
          widget.videoData['likesCount'] = response['likesCount'].toString();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to like video'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error liking video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error liking video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _togglePlayPause() {
    if (_isInitialized) {
      final controller = _videoService.getControllerSync(widget.videoId);
      if (controller != null) {
        if (controller.value.isPlaying) {
          _videoService.pauseVideo(widget.videoId);
        } else {
          _videoService.playVideo(widget.videoId);
        }
      }
    }
  }

  void _onLongPressStart() {
    if (_isInitialized) {
      final controller = _videoService.getControllerSync(widget.videoId);
      if (controller != null) {
        setState(() {
          _isDoubleSpeed = true;
          _playbackSpeed = 2.0;
        });
        if (!controller.value.isPlaying) {
          controller.play();
        }
        controller.setPlaybackSpeed(_playbackSpeed);
      }
    }
  }

  void _onLongPressEnd() {
    if (_isInitialized) {
      final controller = _videoService.getControllerSync(widget.videoId);
      if (controller != null) {
        setState(() {
          _isDoubleSpeed = false;
          _playbackSpeed = 1.0;
        });
        controller.setPlaybackSpeed(_playbackSpeed);
      }
    }
  }

  void _onProgressBarDrag(double value) {
    if (_isInitialized) {
      final controller = _videoService.getControllerSync(widget.videoId);
      if (controller != null) {
        final duration = controller.value.duration;
        final newPosition = duration * value;
        controller.seekTo(newPosition);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              Text(_errorMessage, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializePlayer,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final controller = _videoService.getControllerSync(widget.videoId);
    return GestureDetector(
      onTap: _togglePlayPause,
      onDoubleTap: _likeVideo,
      onLongPressStart: (_) => _onLongPressStart(),
      onLongPressEnd: (_) => _onLongPressEnd(),
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            // Video Player
            if (controller != null)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),

            // Play/Pause indicator
            if (controller != null &&
                !controller.value.isPlaying &&
                !_isDragging)
              Center(
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.white.withOpacity(0.7),
                  size: 80,
                ),
              ),

            // 2x Speed indicator
            if (_isDoubleSpeed)
              Positioned(
                top: MediaQuery.of(context).size.height * 0.15,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      '2x',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

            // Progress Bar
            if (controller != null && controller.value.isInitialized)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildProgressBar(controller),
              ),

            // Video Controls Overlay
            Positioned(
              bottom: 20,
              right: 20,
              child: Column(
                children: [
                  _buildActionButton(
                    isVideoLiked[widget.videoId] == true
                        ? Icons.favorite
                        : Icons.favorite_border,
                    isVideoLiked[widget.videoId] == true
                        ? Colors.red
                        : Colors.white,
                    widget.videoData['likesCount']!,
                    onTap: _likeVideo,
                  ),
                  const SizedBox(height: 24),
                  _buildActionButton(
                    Icons.comment,
                    Colors.white,
                    widget.videoData['commentsCount']!,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => CommentsSection(
                          videoId: widget.videoId,
                          apiService: widget.apiService,
                          isBottomSheet: true,
                          onCommentCountChanged: (count) {
                            setState(() {
                              widget.videoData['commentsCount'] =
                                  count.toString();
                            });
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildActionButton(
                    Icons.share,
                    Colors.white,
                    widget.videoData['sharesCount']!,
                  ),
                  const SizedBox(height: 24),
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
                    widget.videoData['userUsername']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.videoData['description']!,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
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
    Color color,
    String label, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
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
      onTap: () async {
        await _videoService
            .pauseVideo(widget.videoId); // Pause the current video
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(
              userId: int.tryParse(widget.videoData['userId'] ?? '0') ?? 0,
              username: widget.videoData['userUsername'] ?? '',
              isPublicUser: true,
            ),
          ),
        ).then((_) {
          // Check if the video controller still exists and resume it
          final controller = _videoService.getControllerSync(widget.videoId);
          if (controller != null && controller.value.isInitialized) {
            // Video controller exists, just resume it
            _videoService.playVideo(widget.videoId);
          } else {
            // Video controller was disposed, re-initialize
            _initializePlayer();
          }
        });
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
          backgroundColor: Colors.grey[300],
          child: ClipOval(
            child: _profileImageLoading
                ? SizedBox(
                    width: 44,
                    height: 44,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : _profileImageError
                    ? Icon(
                        Icons.person,
                        size: 24,
                        color: Colors.grey[600],
                      )
                    : Image.network(
                        _profileImageUrl!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        headers: _profileImageHeaders ?? {},
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading profile image: $error');
                          return Icon(
                            Icons.person,
                            size: 24,
                            color: Colors.grey[600],
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }
                          return SizedBox(
                            width: 44,
                            height: 44,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(VideoPlayerController controller) {
    return SizedBox(
      height: 5,
      child: StreamBuilder<Duration>(
        stream: _getPositionStream(controller),
        builder: (context, snapshot) {
          final position = snapshot.data ?? Duration.zero;
          final duration = controller.value.duration;
          final progress = duration.inMilliseconds > 0
              ? position.inMilliseconds / duration.inMilliseconds
              : 0.0;

          return GestureDetector(
            onPanStart: (_) {
              setState(() {
                _isDragging = true;
              });
            },
            onPanUpdate: (details) {
              final RenderBox renderBox =
                  context.findRenderObject() as RenderBox;
              final localPosition =
                  renderBox.globalToLocal(details.globalPosition);
              final progress =
                  (localPosition.dx / renderBox.size.width).clamp(0.0, 1.0);
              _onProgressBarDrag(progress);
            },
            onPanEnd: (_) {
              setState(() {
                _isDragging = false;
              });
            },
            child: Stack(
              children: [
                // Background line
                Container(
                  width: double.infinity,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                // Progress line
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                // Draggable handle
                if (_isDragging)
                  Positioned(
                    left: (MediaQuery.of(context).size.width * progress) - 6,
                    top: -6,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
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

  Stream<Duration> _getPositionStream(VideoPlayerController controller) async* {
    while (controller.value.isInitialized) {
      yield controller.value.position;
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}
