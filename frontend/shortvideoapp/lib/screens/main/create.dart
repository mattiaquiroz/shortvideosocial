import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/api_service.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_compress/video_compress.dart';

class Create extends StatelessWidget {
  const Create({super.key});

  @override
  Widget build(BuildContext context) {
    return const CreateVideoPage();
  }
}

class CreateVideoPage extends StatefulWidget {
  const CreateVideoPage({super.key});

  @override
  State<CreateVideoPage> createState() => _CreateVideoPageState();
}

class _CreateVideoPageState extends State<CreateVideoPage> {
  File? _videoFile;
  File? _thumbnailFile;
  final ImagePicker _picker = ImagePicker();
  VideoPlayerController? _videoPlayerController;
  bool _isVideoInitialized = false;
  bool _isPicking = false;

  Future<void> _pickVideo() async {
    if (_isPicking) return;
    setState(() {
      _isPicking = true;
    });
    try {
      final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        final video = File(pickedFile.path);
        setState(() {
          _videoFile = video;
        });
        await _extractThumbnail(video);
        _initializeVideoPlayer(video);
      }
    } finally {
      setState(() {
        _isPicking = false;
      });
    }
  }

  Future<void> _extractThumbnail(File video) async {
    final thumbPath = await VideoThumbnail.thumbnailFile(
      video: video.path,
      thumbnailPath: (await VideoThumbnail.thumbnailFile(
            video: video.path,
            imageFormat: ImageFormat.JPEG,
            quality: 90,
          )) ??
          '',
      imageFormat: ImageFormat.JPEG,
      quality: 90,
    );
    if (thumbPath != null && thumbPath.isNotEmpty) {
      setState(() {
        _thumbnailFile = File(thumbPath);
      });
    }
  }

  Future<void> _initializeVideoPlayer(File file) async {
    _videoPlayerController?.dispose();
    _videoPlayerController = VideoPlayerController.file(file);
    await _videoPlayerController!.initialize();
    setState(() {
      _isVideoInitialized = true;
    });
    _videoPlayerController!.setLooping(true);
    _videoPlayerController!.play();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  void _goToInfoPage() async {
    if (_videoFile != null && _thumbnailFile != null) {
      _videoPlayerController?.pause();
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoInfoPage(
              videoFile: _videoFile!, thumbnailFile: _thumbnailFile!),
        ),
      );
      setState(() {}); // Refresh the play/pause icon after returning
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove the AppBar title for a cleaner look
      appBar: null,
      body: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            if (_videoFile == null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_library,
                          size: 80, color: Colors.blue[200]),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _isPicking ? null : _pickVideo,
                        icon: const Icon(Icons.add_circle_outline),
                        label: _isPicking
                            ? const Text('Picking...')
                            : const Text('Pick a Video'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              const SizedBox(height: 40),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _isVideoInitialized &&
                              _videoPlayerController != null
                          ? Stack(
                              children: [
                                AspectRatio(
                                  aspectRatio:
                                      _videoPlayerController!.value.aspectRatio,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(0),
                                    child: VideoPlayer(_videoPlayerController!),
                                  ),
                                ),
                                Positioned(
                                  right: 16,
                                  top: 15, // More padding from the top
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _videoFile = null;
                                        _thumbnailFile = null;
                                        _isVideoInitialized = false;
                                        _videoPlayerController?.dispose();
                                        _videoPlayerController = null;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(6),
                                      child: const Icon(Icons.close,
                                          color: Colors.white, size: 24),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 16,
                                  bottom: 16,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black54,
                                    child: IconButton(
                                      icon: Icon(
                                        _videoPlayerController!.value.isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          if (_videoPlayerController!
                                              .value.isPlaying) {
                                            _videoPlayerController!.pause();
                                          } else {
                                            _videoPlayerController!.play();
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const Center(child: CircularProgressIndicator()),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 6),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _goToInfoPage,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Next',
                              style: TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class VideoInfoPage extends StatefulWidget {
  final File videoFile;
  final File thumbnailFile;
  const VideoInfoPage(
      {super.key, required this.videoFile, required this.thumbnailFile});

  @override
  State<VideoInfoPage> createState() => _VideoInfoPageState();
}

class _VideoInfoPageState extends State<VideoInfoPage> {
  final _formKey = GlobalKey<FormState>();
  String _description = '';
  bool _isPublic = true;
  bool _isLoading = false;
  bool _isCompressing = false;
  double _uploadProgress = 0.0;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
      _isCompressing = true;
      _uploadProgress = 0.0;
    });
    _formKey.currentState!.save();

    // Compress the video before uploading
    File fileToUpload = widget.videoFile;
    try {
      // Show compression progress
      setState(() {
        _uploadProgress = 0.0;
      });

      final info = await VideoCompress.compressVideo(
        widget.videoFile.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
        frameRate: 30,
      );
      if (info != null && info.file != null) {
        fileToUpload = info.file!;
      }
    } catch (e) {
      // If compression fails, fallback to original
      print('Video compression failed: $e');
    }

    // Switch to upload phase
    setState(() {
      _isCompressing = false;
    });

    final success = await ApiService.uploadVideoWithThumbnail(
      fileToUpload,
      widget.thumbnailFile,
      _description,
      _isPublic,
      onProgress: (progress) {
        setState(() {
          _uploadProgress = progress;
        });
      },
    );
    // Clean up compressed file if different from original
    if (fileToUpload.path != widget.videoFile.path) {
      try {
        await fileToUpload.delete();
      } catch (_) {}
    }
    setState(() {
      _isLoading = false;
      _isCompressing = false;
      _uploadProgress = 0.0;
    });
    if (success) {
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video uploaded successfully!')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload video.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Info')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Description',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                maxLines: 2,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  hintText: 'Enter a description...',
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a description'
                    : null,
                onSaved: (value) => _description = value ?? '',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Public',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  Switch(
                    value: _isPublic,
                    onChanged: (val) => setState(() => _isPublic = val),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                Column(
                  children: [
                    LinearProgressIndicator(value: _uploadProgress),
                    const SizedBox(height: 12),
                    Text(_isCompressing
                        ? 'Compressing video...'
                        : 'Uploading... ${(100 * _uploadProgress).toStringAsFixed(0)}%'),
                  ],
                ),
              if (!_isLoading)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _submit,
                    child: const Text('Submit', style: TextStyle(fontSize: 16)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
