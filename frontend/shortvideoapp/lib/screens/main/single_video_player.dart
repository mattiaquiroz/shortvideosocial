import 'package:flutter/material.dart';
import 'package:shortvideoapp/screens/main/profile.dart';
import 'package:shortvideoapp/services/api_service.dart';
import 'package:shortvideoapp/services/video_player_service.dart';
import 'package:shortvideoapp/constants/strings.dart';
import 'package:video_player/video_player.dart';
import 'package:shortvideoapp/screens/main/comments_section.dart';
import 'package:shortvideoapp/screens/main/share_to_chat_modal.dart';

class SingleVideoPlayerScreen extends StatefulWidget {
  final Map<String, dynamic> videoData;

  const SingleVideoPlayerScreen({
    Key? key,
    required this.videoData,
  }) : super(key: key);

  @override
  State<SingleVideoPlayerScreen> createState() =>
      _SingleVideoPlayerScreenState();
}

class _SingleVideoPlayerScreenState extends State<SingleVideoPlayerScreen> {
  final ApiService _apiService = ApiService();
  final EnhancedVideoService _videoService = EnhancedVideoService();

  // Generate a unique context ID for this instance
  late final String _uniqueContextId;
  Map<String, dynamic>? _fullVideoData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _uniqueContextId =
        'single_ 2${DateTime.now().millisecondsSinceEpoch}_${widget.videoData['id'] ?? ''}';
    _loadFullVideoData();
  }

  Future<void> _loadFullVideoData() async {
    try {
      // If we only have an ID, fetch the full video data
      if (widget.videoData.length == 1 && widget.videoData.containsKey('id')) {
        final result =
            await _apiService.getVideoById(widget.videoData['id'].toString());
        if (result['success']) {
          setState(() {
            _fullVideoData = result['video'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = result['message'];
            _isLoading = false;
          });
        }
      } else {
        // We already have full video data
        setState(() {
          _fullVideoData = widget.videoData;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load video: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _videoService.disposeContext(_uniqueContextId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_left,
              color: Colors.white, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        color: Colors.black,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.white, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadFullVideoData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleEnhancedVideoPlayer(
                    videoId: _fullVideoData!['id']?.toString() ?? '',
                    videoData: _convertVideoData(_fullVideoData!),
                    apiService: _apiService,
                    autoPlay: true,
                    contextId: _uniqueContextId,
                  ),
      ),
    );
  }

  Map<String, String> _convertVideoData(Map<String, dynamic> videoData) {
    return {
      'id': (videoData['id'] ?? '').toString(),
      'userUsername': videoData['user']?['username'] ?? '',
      'userProfilePictureUrl': videoData['user']?['profilePictureUrl'] ?? '',
      'description': videoData['description'] ?? '',
      'videoUrl': videoData['videoUrl'] ?? '',
      'likesCount': (videoData['likesCount'] ?? 0).toString(),
      'commentsCount': (videoData['commentsCount'] ?? 0).toString(),
      'sharesCount': (videoData['sharesCount'] ?? 0).toString(),
      'viewsCount': (videoData['viewsCount'] ?? 0).toString(),
      'createdAt': videoData['createdAt'] ?? '',
      'userId': (videoData['user']?['id'] ?? '').toString(),
      'isPublic': (videoData['isPublic'] ?? '').toString(),
    };
  }
}

class SingleEnhancedVideoPlayer extends StatefulWidget {
  final String videoId;
  final Map<String, String> videoData;
  final ApiService apiService;
  final bool autoPlay;
  final String contextId; // new

  const SingleEnhancedVideoPlayer({
    Key? key,
    required this.videoId,
    required this.videoData,
    required this.apiService,
    required this.autoPlay,
    required this.contextId,
  }) : super(key: key);

  @override
  State<SingleEnhancedVideoPlayer> createState() =>
      _SingleEnhancedVideoPlayerState();
}

class _SingleEnhancedVideoPlayerState extends State<SingleEnhancedVideoPlayer> {
  final EnhancedVideoService _videoService = EnhancedVideoService();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  bool _isInitialized = false;
  bool _hasError = false;
  String? _videoUrl;
  String _errorMessage = '';
  Map<String, bool> isVideoLiked = {};
  bool _isDragging = false;
  bool _isDoubleSpeed = false;
  double _playbackSpeed = 1.0;
  bool _isCommentFocused = false;
  bool _isPostingComment = false;
  bool _isOwnVideo = false;

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
    _checkIfOwnVideo();

    // Add comment focus listener
    _commentFocusNode.addListener(() {
      setState(() {
        _isCommentFocused = _commentFocusNode.hasFocus;
      });
    });

    // Add comment text listener for send button animation
    _commentController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _checkIfOwnVideo() async {
    try {
      final currentUser = await widget.apiService.getCurrentUser();
      if (currentUser != null) {
        final videoUserId = int.tryParse(widget.videoData['userId'] ?? '') ?? 0;
        setState(() {
          _isOwnVideo = currentUser.id == videoUserId;
        });
      }
    } catch (e) {
      print('Error checking if own video: $e');
    }
  }

  Future<void> _loadProfileImageData() async {
    try {
      final results = await Future.wait([
        widget.apiService.getProfileImageUrl(
          widget.videoData['userProfilePictureUrl'],
          userId: widget.videoData['userId'],
          cacheBust: true,
        ),
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
    final controller = _videoService.getControllerSync(widget.contextId);
    if (controller != null) {
      controller.removeListener(() {});
    }
    _commentController.dispose();
    _commentFocusNode.dispose();
    // Only dispose the unique context
    _videoService.disposeContext(widget.contextId);
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoUrl = await widget.apiService.getVideoStreamingUrl(widget.videoId);
      final authToken = await widget.apiService.getAuthToken();
      final controller = await _videoService.getController(
        widget.contextId,
        _videoUrl!,
        authToken: authToken,
        context: widget.contextId,
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
          _videoService.playVideo(widget.contextId);
        }
      }
    } catch (e) {
      print('Error initializing video player: $e');
      setState(() {
        _hasError = true;
        _errorMessage = '${AppStrings.failedToLoadVideo}: $e';
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
              content:
                  Text(response['message'] ?? AppStrings.failedToLikeVideo),
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
            content: Text('${AppStrings.errorLikingVideo}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _togglePlayPause() {
    if (_isInitialized) {
      final controller = _videoService.getControllerSync(widget.contextId);
      if (controller != null) {
        if (controller.value.isPlaying) {
          _videoService.pauseVideo(widget.contextId);
        } else {
          _videoService.playVideo(widget.contextId);
        }
      }
    }
  }

  void _onLongPressStart() {
    if (_isInitialized) {
      final controller = _videoService.getControllerSync(widget.contextId);
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
      final controller = _videoService.getControllerSync(widget.contextId);
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
      final controller = _videoService.getControllerSync(widget.contextId);
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
                child: Text(AppStrings.retry),
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

    final controller = _videoService.getControllerSync(widget.contextId);
    return Column(
      children: [
        // Video Area
        Expanded(
          child: GestureDetector(
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
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
                                videoId:
                                    widget.videoId, // real video ID for API
                                playerContextId:
                                    widget.contextId, // for pausing
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
                          onTap: () async {
                            final result = await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) =>
                                  ShareToChatModal(video: widget.videoData),
                            );
                            if (result == true) {
                              setState(() {
                                final count = int.tryParse(
                                        widget.videoData['sharesCount'] ??
                                            '0') ??
                                    0;
                                widget.videoData['sharesCount'] =
                                    (count + 1).toString();
                              });
                            }
                          },
                        ),
                        if (_isOwnVideo) ...[
                          const SizedBox(height: 24),
                          _buildActionButton(
                            Icons.more_horiz,
                            Colors.white,
                            '',
                            onTap: _showVideoOptionsSheet,
                          ),
                        ],
                        const SizedBox(height: 24),
                        _buildProfileButton(),
                      ],
                    ),
                  ),

                  // Video Info Overlay
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 100, // Leave space for action buttons
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
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Comment Section
        Container(
          color: Colors.black,
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            top: false,
            child: _buildCommentTextField(),
          ),
        ),
      ],
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
        // Pause the current video before navigating
        await _videoService.pauseVideo(widget.contextId);

        // Navigate to other users profile
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(
              userId: int.tryParse(widget.videoData['userId'] ?? '') ?? 0,
              username: widget.videoData['userUsername'] ?? '',
              isPublicUser: true,
            ),
          ),
        );
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

  Widget _buildCommentTextField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: _isCommentFocused
            ? Colors.black.withOpacity(0.8)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: _isCommentFocused
            ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
            : null,
      ),
      child: TextField(
        controller: _commentController,
        focusNode: _commentFocusNode,
        enabled: !_isPostingComment,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        maxLines: 1,
        textInputAction: TextInputAction.send,
        onSubmitted: (value) {
          if (value.isNotEmpty && !_isPostingComment) {
            _postComment();
          }
        },
        decoration: InputDecoration(
          hintText: AppStrings.addComment,
          hintStyle:
              TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          suffixIcon: AnimatedOpacity(
            opacity: _commentController.text.isNotEmpty ? 1.0 : 0.5,
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              icon: _isPostingComment
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
              onPressed: _isPostingComment
                  ? null
                  : () {
                      if (_commentController.text.isNotEmpty) {
                        _postComment();
                      }
                    },
            ),
          ),
        ),
      ),
    );
  }

  void _postComment() async {
    if (_isPostingComment) return; // Prevent multiple submissions

    setState(() {
      _isPostingComment = true;
    });

    // Post comment to API
    final response = await widget.apiService.postComment(
      widget.videoId,
      _commentController.text,
    );

    setState(() {
      _isPostingComment = false;
    });

    if (response['success']) {
      // Update the comment count in the video data
      widget.videoData['commentsCount'] = response['commentsCount'].toString();

      // Clear the text field and unfocus
      _commentController.clear();
      _commentFocusNode.unfocus();

      // Trigger a rebuild to update the UI
      setState(() {});
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? AppStrings.failedToPostComment),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Stream<Duration> _getPositionStream(VideoPlayerController controller) async* {
    while (controller.value.isInitialized) {
      yield controller.value.position;
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void _showVideoOptionsSheet() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool isPublic = widget.videoData['isPublic'] == 'true';
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 20, left: 20, right: 20, bottom: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppStrings.videoPrivacy,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.public,
                        color: isPublic ? Colors.green : null),
                    title: Text(AppStrings.public),
                    trailing: isPublic
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: isPublic
                        ? null
                        : () async {
                            final response =
                                await widget.apiService.setVideoVisibility(
                              widget.videoId,
                              true,
                            );
                            if (response['success'] == true) {
                              setState(() {
                                widget.videoData['isPublic'] = 'true';
                              });
                              setModalState(() => isPublic = true);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(response['message'] ??
                                      AppStrings.failedToUpdateVisibility),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                  ),
                  ListTile(
                    leading:
                        Icon(Icons.lock, color: !isPublic ? Colors.red : null),
                    title: Text(AppStrings.private),
                    trailing: !isPublic
                        ? const Icon(Icons.check, color: Colors.red)
                        : null,
                    onTap: !isPublic
                        ? null
                        : () async {
                            final response =
                                await widget.apiService.setVideoVisibility(
                              widget.videoId,
                              false,
                            );
                            if (response['success'] == true) {
                              setState(() {
                                widget.videoData['isPublic'] = 'false';
                              });
                              setModalState(() => isPublic = false);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(response['message'] ??
                                      AppStrings.failedToUpdateVisibility),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                  ),
                  const SizedBox(height: 16),
                  // Video options section
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 20, right: 20, bottom: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppStrings.videoOptions,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Delete video button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.delete),
                        label: Text(AppStrings.deleteVideo),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(AppStrings.deleteVideo),
                              content: Text(AppStrings.deleteVideoConfirm),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: Text(AppStrings.cancel),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  style: TextButton.styleFrom(
                                      foregroundColor: Colors.red),
                                  child: Text(AppStrings.delete),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            // Call API to delete video
                            final response = await widget.apiService
                                .deleteVideo(widget.videoId);
                            if (response['success'] == true ||
                                response['status'] == 204) {
                              if (mounted) {
                                Navigator.of(context)
                                    .pop(); // Close bottom sheet
                                Navigator.of(context)
                                    .pop(); // Close video player
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          AppStrings.videoDeletedSuccessfully),
                                      backgroundColor: Colors.green),
                                );
                              }
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(response['message'] ??
                                          AppStrings.failedToDeleteVideo),
                                      backgroundColor: Colors.red),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
