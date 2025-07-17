import 'package:video_player/video_player.dart';
import 'dart:async';

class EnhancedVideoService {
  static final EnhancedVideoService _instance =
      EnhancedVideoService._internal();
  factory EnhancedVideoService() => _instance;
  EnhancedVideoService._internal();

  // Optimized cache for video streaming with context support
  final Map<String, VideoPlayerController> _controllers = {};
  final Map<String, bool> _isInitialized = {};
  final Map<String, String> _controllerContexts = {};
  final int _maxCacheSize = 5; // Increased for better caching

  // Mutex for preventing concurrent modifications
  bool _isModifying = false;

  // Current and next video management
  String? _currentVideoId;
  String? _nextVideoId;
  String? _previousVideoId;

  // Helper method to safely modify the controllers map
  Future<T> _safeModify<T>(Future<T> Function() operation) async {
    while (_isModifying) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    _isModifying = true;
    try {
      return await operation();
    } finally {
      _isModifying = false;
    }
  }

  // Get or create video controller
  Future<VideoPlayerController?> getController(String videoId, String videoUrl,
      {String? authToken, String context = 'default'}) async {
    return await _safeModify(() async {
      // If controller already exists and is initialized, return it
      if (_controllers.containsKey(videoId) &&
          _isInitialized[videoId] == true) {
        // Update context if needed
        _controllerContexts[videoId] = context;
        return _controllers[videoId];
      }

      // Create headers with authentication if available
      final headers = <String, String>{
        'User-Agent': 'ShortVideoApp/1.0 (Mobile)',
        'Accept': 'video/mp4,video/*;q=0.9,*/*;q=0.8',
      };

      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        httpHeaders: headers,
      );
      _controllers[videoId] = controller;
      _isInitialized[videoId] = false;
      _controllerContexts[videoId] = context;

      try {
        await controller.initialize();
        _isInitialized[videoId] = true;

        controller.setLooping(true);

        return controller;
      } catch (e) {
        print('Error initializing video controller for $videoId: $e');
        _controllers.remove(videoId);
        _isInitialized.remove(videoId);
        _controllerContexts.remove(videoId);
        return null;
      }
    });
  }

  // Preload next and previous videos
  Future<void> preloadVideos(
      String currentVideoId,
      String currentVideoUrl,
      String? nextVideoId,
      String? nextVideoUrl,
      String? previousVideoId,
      String? previousVideoUrl,
      {String? authToken,
      String context = 'default'}) async {
    _currentVideoId = currentVideoId;
    _nextVideoId = nextVideoId;
    _previousVideoId = previousVideoId;

    // Preload next video
    if (nextVideoId != null && nextVideoUrl != null) {
      _preloadVideo(nextVideoId, nextVideoUrl,
          authToken: authToken, context: context);
    }

    // Preload previous video
    if (previousVideoId != null && previousVideoUrl != null) {
      _preloadVideo(previousVideoId, previousVideoUrl,
          authToken: authToken, context: context);
    }

    // Clean up old controllers
    _cleanupOldControllers();
  }

  // Preload a single video
  Future<void> _preloadVideo(String videoId, String videoUrl,
      {String? authToken, String context = 'default'}) async {
    await _safeModify(() async {
      if (_controllers.containsKey(videoId)) return;

      final headers = <String, String>{
        'User-Agent': 'ShortVideoApp/1.0 (Mobile)',
        'Accept': 'video/mp4,video/*;q=0.9,*/*;q=0.8',
      };

      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        httpHeaders: headers,
      );
      _controllers[videoId] = controller;
      _isInitialized[videoId] = false;
      _controllerContexts[videoId] = context;

      try {
        await controller.initialize();
        _isInitialized[videoId] = true;
        controller.setLooping(true);

        // Preload some content
        await controller.seekTo(Duration.zero);

        print('Preloaded video: $videoId for context: $context');
      } catch (e) {
        print('Error preloading video $videoId: $e');
        _controllers.remove(videoId);
        _isInitialized.remove(videoId);
        _controllerContexts.remove(videoId);
      }
    });
  }

  // Clean up old controllers to prevent memory issues
  void _cleanupOldControllers() {
    if (_controllers.length <= _maxCacheSize) return;

    final keysToRemove = <String>[];
    final currentVideos = {_currentVideoId, _nextVideoId, _previousVideoId};

    for (final key in _controllers.keys) {
      if (!currentVideos.contains(key)) {
        keysToRemove.add(key);
      }
    }

    // Remove oldest entries
    final excessCount = _controllers.length - _maxCacheSize;
    for (int i = 0; i < excessCount && i < keysToRemove.length; i++) {
      final key = keysToRemove[i];
      _controllers[key]?.dispose();
      _controllers.remove(key);
      _isInitialized.remove(key);
      _controllerContexts.remove(key);
    }
  }

  // Play video
  Future<void> playVideo(String videoId) async {
    // Pause all other videos
    for (final entry in _controllers.entries) {
      if (entry.key != videoId) {
        entry.value.pause();
      }
    }

    // Play current video
    final controller = _controllers[videoId];
    if (controller != null && _isInitialized[videoId] == true) {
      await controller.play();
    }
  }

  // Pause video
  Future<void> pauseVideo(String videoId) async {
    final controller = _controllers[videoId];
    if (controller != null && _isInitialized[videoId] == true) {
      await controller.pause();
    }
  }

  // Pause all videos
  Future<void> pauseAllVideos() async {
    for (final controller in _controllers.values) {
      await controller.pause();
    }
  }

  // Check if video is initialized
  bool isVideoInitialized(String videoId) {
    return _isInitialized[videoId] == true;
  }

  // Get controller directly (for UI binding)
  VideoPlayerController? getControllerSync(String videoId) {
    return _controllers[videoId];
  }

  // Dispose all controllers
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _isInitialized.clear();
    _controllerContexts.clear();
  }

  // Dispose controllers for a specific context
  void disposeContext(String context) {
    final keysToRemove = <String>[];
    for (final entry in _controllerContexts.entries) {
      if (entry.value == context) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _controllers[key]?.dispose();
      _controllers.remove(key);
      _isInitialized.remove(key);
      _controllerContexts.remove(key);
    }
  }

  // Dispose specific controller
  void disposeController(String videoId) {
    final controller = _controllers[videoId];
    if (controller != null) {
      controller.dispose();
      _controllers.remove(videoId);
      _isInitialized.remove(videoId);
      _controllerContexts.remove(videoId);
    }
  }

  // Get controllers for a specific context
  List<String> getControllersForContext(String context) {
    return _controllerContexts.entries
        .where((entry) => entry.value == context)
        .map((entry) => entry.key)
        .toList();
  }

  // Check if a video belongs to a specific context
  bool isVideoInContext(String videoId, String context) {
    return _controllerContexts[videoId] == context;
  }
}
