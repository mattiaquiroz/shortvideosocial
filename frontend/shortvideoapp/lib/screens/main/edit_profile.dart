import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shortvideoapp/services/api_service.dart';
import 'package:shortvideoapp/constants/strings.dart';

class EditProfilePage extends StatefulWidget {
  final int userId;
  final String initialUsername;
  final String? initialBio;
  final String? initialProfilePictureUrl;

  const EditProfilePage({
    super.key,
    required this.userId,
    required this.initialUsername,
    this.initialBio,
    this.initialProfilePictureUrl,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  File? _imageFile;
  bool _isLoading = false;
  String? _errorMessage;
  late String? _profilePictureUrl;
  final ApiService _apiService = ApiService();
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.initialUsername);
    _bioController = TextEditingController(text: widget.initialBio ?? '');
    _profilePictureUrl = widget.initialProfilePictureUrl;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    _isPickingImage = true;
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } finally {
      _isPickingImage = false;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final username = _usernameController.text.trim();
      final bio = _bioController.text.trim();
      String? uploadedImageUrl = _profilePictureUrl;
      if (_imageFile != null) {
        final uploadResult =
            await _apiService.uploadProfilePicture(_imageFile!);
        if (uploadResult['success']) {
          uploadedImageUrl = uploadResult['url'];
        } else {
          setState(() {
            _errorMessage =
                uploadResult['message'] ?? 'Failed to upload image.';
            _isLoading = false;
          });
          return;
        }
      }
      final updateResult = await _apiService.updateUserProfile(
        userId: widget.userId,
        username: username,
        bio: bio,
        profilePictureUrl: uploadedImageUrl,
      );
      if (updateResult['success']) {
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage =
              updateResult['message'] ?? 'Failed to update profile.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Widget _buildProfileImage() {
    // If a new image is picked, show it immediately
    if (_imageFile != null) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: FileImage(_imageFile!),
      );
    }
    // Otherwise, use the same logic as the profile page
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        _apiService.getProfileImageUrl(widget.initialProfilePictureUrl,
            userId: widget.userId.toString(), cacheBust: true),
        _apiService.getImageHeaders(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[300],
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          );
        }
        if (snapshot.hasError) {
          return const CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 60, color: Colors.white),
          );
        }
        final imageUrl = snapshot.data?[0] as String? ?? "null";
        final headers = snapshot.data?[1] as Map<String, String>? ?? {};
        return CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[300],
          child: ClipOval(
            child: Image.network(
              imageUrl,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              headers: headers,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox.shrink();
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return const SizedBox(
                  width: 120,
                  height: 120,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.editProfile),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.keyboard_arrow_left, size: 30),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        _buildProfileImage(),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: InkWell(
                            onTap: _pickImage,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: const Icon(Icons.edit,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username cannot be empty';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info_outline),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
