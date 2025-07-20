import 'package:flutter/material.dart';
import 'package:shortvideoapp/services/api_service.dart';
import 'package:shortvideoapp/models/conversation_model.dart';
import 'package:shortvideoapp/models/user_model.dart';

class ShareToChatModal extends StatefulWidget {
  final Map<String, dynamic> video;
  const ShareToChatModal({super.key, required this.video});

  @override
  State<ShareToChatModal> createState() => _ShareToChatModalState();
}

class _ShareToChatModalState extends State<ShareToChatModal> {
  final ApiService _apiService = ApiService();
  List<Conversation> _recentChats = [];
  int? _selectedUserId;
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecentChats();
  }

  Future<void> _loadRecentChats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _apiService.getConversations();
      if (result['success']) {
        setState(() {
          _recentChats = result['conversations'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load chats: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendVideo() async {
    if (_selectedUserId == null) return;
    setState(() {
      _isSending = true;
    });
    try {
      final videoId = widget.video['id'];
      await _apiService.sendMessage(
        receiverId: _selectedUserId!,
        content: '[videoid:$videoId]',
        messageType: 'video',
      );
      // Increment share count
      await _apiService.incrementVideoShareCount(widget.video['id']);
      setState(() {
        _isSending = false;
      });
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.share, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Share to chat',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (_error != null)
              Center(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            if (!_isLoading && _error == null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recent chats:',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recentChats.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final chat = _recentChats[index];
                        final user = chat.otherUser;
                        final isSelected = _selectedUserId == user.id;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedUserId = user.id;
                            });
                          },
                          child: Column(
                            children: [
                              FutureBuilder<String>(
                                future: _apiService.getProfileImageUrl(
                                  user.profilePictureUrl,
                                  userId: user.id.toString(),
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CircleAvatar(
                                      radius: isSelected ? 32 : 28,
                                      backgroundColor: isSelected
                                          ? Colors.red[100]
                                          : Colors.grey[200],
                                      child: const CircularProgressIndicator(
                                          strokeWidth: 2),
                                    );
                                  }
                                  if (snapshot.hasError ||
                                      snapshot.data == null ||
                                      snapshot.data == "null") {
                                    return CircleAvatar(
                                      radius: isSelected ? 32 : 28,
                                      backgroundColor: isSelected
                                          ? Colors.red[100]
                                          : Colors.grey[200],
                                      child: Text(
                                        user.username.isNotEmpty
                                            ? user.username[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    );
                                  }
                                  return FutureBuilder<Map<String, String>>(
                                    future: _apiService.getImageHeaders(),
                                    builder: (context, headersSnapshot) {
                                      return CircleAvatar(
                                        radius: isSelected ? 32 : 28,
                                        backgroundColor: isSelected
                                            ? Colors.red[100]
                                            : Colors.grey[200],
                                        child: ClipOval(
                                          child: Image.network(
                                            snapshot.data!,
                                            width: (isSelected ? 56 : 48),
                                            height: (isSelected ? 56 : 48),
                                            fit: BoxFit.cover,
                                            headers: headersSnapshot.data ?? {},
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Text(
                                                user.username.isNotEmpty
                                                    ? user.username[0]
                                                        .toUpperCase()
                                                    : 'U',
                                                style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              );
                                            },
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2));
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: 64,
                                child: Text(
                                  user.username,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color:
                                        isSelected ? Colors.red : Colors.black,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _selectedUserId == null || _isSending
                          ? null
                          : _sendVideo,
                      icon: const Icon(Icons.send),
                      label: _isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Send'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
