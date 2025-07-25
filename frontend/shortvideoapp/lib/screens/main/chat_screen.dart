import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shortvideoapp/constants/strings.dart';
import 'package:shortvideoapp/services/api_service.dart';
import 'package:shortvideoapp/models/message_model.dart';
import 'package:shortvideoapp/models/user_model.dart';
import 'package:shortvideoapp/screens/main/new_message_screen.dart';
import 'package:shortvideoapp/screens/main/profile.dart';
import 'package:shortvideoapp/screens/main/single_video_player.dart';
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  final User otherUser;

  const ChatScreen({super.key, required this.otherUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _SwipeableMessage extends StatefulWidget {
  final bool isMyMessage;
  final VoidCallback onReply;
  final VoidCallback onLongPress;
  final Widget child;

  const _SwipeableMessage({
    required this.isMyMessage,
    required this.onReply,
    required this.onLongPress,
    required this.child,
  });

  @override
  State<_SwipeableMessage> createState() => _SwipeableMessageState();
}

class _SwipeableMessageState extends State<_SwipeableMessage> {
  double _dragOffset = 0.0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: widget.onLongPress,
      onTap: () {
        HapticFeedback.lightImpact();
      },
      onHorizontalDragStart: (details) {
        setState(() {
          _isDragging = true;
        });
      },
      onHorizontalDragUpdate: (details) {
        setState(() {
          if (widget.isMyMessage) {
            // For my messages, only allow left swipe (negative offset)
            _dragOffset =
                details.delta.dx < 0 ? _dragOffset + details.delta.dx : 0;
          } else {
            // For other messages, only allow right swipe (positive offset)
            _dragOffset =
                details.delta.dx > 0 ? _dragOffset + details.delta.dx : 0;
          }
          _dragOffset = _dragOffset.clamp(-100, 100);
        });
      },
      onHorizontalDragEnd: (details) {
        setState(() {
          _isDragging = false;
        });

        // Check if swipe was sufficient to trigger reply
        if ((widget.isMyMessage && _dragOffset < -50) ||
            (!widget.isMyMessage && _dragOffset > 50)) {
          HapticFeedback.lightImpact();
          widget.onReply();
        }

        // Animate back to original position
        _animateBack();
      },
      child: Stack(
        children: [
          // Background reply indicator
          if (_isDragging && _dragOffset.abs() > 20)
            Positioned(
              left: widget.isMyMessage ? null : 0,
              right: widget.isMyMessage ? 0 : null,
              top: 0,
              bottom: 0,
              child: Container(
                width: 80, // Fixed width for the indicator
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.reply,
                        color: Color(0xFF007AFF),
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Reply',
                        style: TextStyle(
                          color: Color(0xFF007AFF),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Main message content
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(_dragOffset, 0, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }

  void _animateBack() {
    setState(() {
      _dragOffset = 0.0;
    });
  }
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Message> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;
  Message? _replyToMessage;
  User? _currentUser;
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final int _pageSize = 15;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadMessages();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() async {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        _hasMore &&
        !_isLoadingMore &&
        !_isLoading) {
      await _loadMessages(page: _currentPage + 1, append: true);
    }
  }

  Future<void> _loadCurrentUser() async {
    final user = await _apiService.getCurrentUser();
    setState(() {
      _currentUser = user;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({int page = 0, bool append = false}) async {
    if (_isLoadingMore) return;
    if (page == 0) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final result = await _apiService.getConversationWithUser(
          widget.otherUser.id,
          page: page,
          size: _pageSize);
      if (result['success']) {
        setState(() {
          if (append) {
            _messages.addAll(result['messages']);
          } else {
            _messages = result['messages'];
          }
          _hasMore = result['hasMore'] ?? false;
          _currentPage = result['page'] ?? page;
          _isLoading = false;
          _isLoadingMore = false;
        });
        // Only jump to bottom on initial load (not after loading more)
        if (!append && _messages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(0.0);
            }
          });
        }
        // Do NOT call _scrollToBottom after loading more
      } else {
        setState(() {
          _errorMessage = result['message'];
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load messages: $e';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final currentUser = await _apiService.getCurrentUser();
    if (currentUser == null) return;

    final optimisticMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
      content: content,
      sender: currentUser,
      receiver: widget.otherUser,
      replyTo: _replyToMessage,
      reaction: null,
      isRead: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() {
      // Optimistically add message to UI at the start (for reverse: true)
      _messages.insert(0, optimisticMessage);
    });

    _messageController.clear();
    // Only scroll to bottom after sending a message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0.0);
      }
    });

    try {
      final result = await _apiService.sendMessage(
        receiverId: widget.otherUser.id,
        content: content,
        replyToId: _replyToMessage?.id,
        messageType: 'chat',
      );

      // Clear reply after successful API call
      _clearReplyTo();

      if (result['success']) {
        // Update the optimistic message with the real message from server
        final realMessage = result['message'] as Message;
        setState(() {
          // Replace the optimistic message with the real one at the start
          final index = _messages.indexOf(optimisticMessage);
          if (index != -1) {
            _messages[index] = realMessage;
          }
        });
      } else {
        // Remove the optimistic message and show error
        setState(() {
          _messages.remove(optimisticMessage);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Remove the optimistic message and show error
      setState(() {
        _messages.remove(optimisticMessage);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _setReplyTo(Message message) {
    setState(() {
      _replyToMessage = message;
    });
  }

  void _clearReplyTo() {
    setState(() {
      _replyToMessage = null;
    });
  }

  void _showMessageOptions(Message message) {
    final isMyMessage =
        _currentUser != null && message.sender.id == _currentUser!.id;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Message preview
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.message,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message.content,
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Emoji reactions row
              if (!isMyMessage) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildReactionEmoji('❤️', message),
                      _buildReactionEmoji('😂', message),
                      _buildReactionEmoji('😍', message),
                      _buildReactionEmoji('😢', message),
                      _buildReactionEmoji('👍', message),
                      _buildReactionEmoji('👏', message),
                      _buildReactionEmoji('😮', message),
                      _buildReactionEmoji('😡', message),
                      _buildReactionEmoji('🙏', message),
                      _buildReactionEmoji('🎉', message),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Options
              ...(isMyMessage
                  ? [
                      _buildOptionTile(
                        icon: Icons.copy,
                        title: 'Copy',
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: message.content));
                          Navigator.pop(context);
                        },
                      ),
                      _buildOptionTile(
                        icon: Icons.reply,
                        title: 'Reply',
                        onTap: () {
                          Navigator.pop(context);
                          _setReplyTo(message);
                        },
                      ),
                      _buildOptionTile(
                        icon: Icons.delete,
                        title: 'Delete',
                        isDestructive: true,
                        onTap: () {
                          Navigator.pop(context);
                          _deleteMessage(message);
                        },
                      ),
                    ]
                  : [
                      _buildOptionTile(
                        icon: Icons.copy,
                        title: 'Copy',
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: message.content));
                          Navigator.pop(context);
                        },
                      ),
                      _buildOptionTile(
                        icon: Icons.reply,
                        title: 'Reply',
                        onTap: () {
                          Navigator.pop(context);
                          _setReplyTo(message);
                        },
                      ),
                    ]),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReactionEmoji(String emoji, Message message) {
    final isSelected = message.reaction == emoji;
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context); // Close the modal
        // If the same reaction is tapped, remove it
        if (isSelected) {
          await _addReactionToMessage(message, null);
        } else {
          await _addReactionToMessage(message, emoji);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[100] : Colors.grey[200],
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
        ),
        child: Text(
          emoji,
          style: TextStyle(
            fontSize: 24,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.blue[800] : Colors.black,
          ),
        ),
      ),
    );
  }

  Future<void> _addReactionToMessage(Message message, String? emoji) async {
    try {
      final result = await _apiService.addReactionToMessage(
        messageId: message.id,
        reaction: emoji ?? '',
      );
      if (result['success'] == true && result['message'] is Message) {
        final updatedMessage = result['message'] as Message;
        setState(() {
          final index = _messages.indexWhere((m) => m.id == message.id);
          if (index != -1) {
            _messages[index] = updatedMessage;
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to add reaction'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add reaction: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.grey[700],
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.grey[800],
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => Profile(
                      userId: widget.otherUser.id,
                      username: widget.otherUser.username,
                      isPublicUser: true,
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  FutureBuilder<String>(
                    future: _apiService.getProfileImageUrl(
                      widget.otherUser.profilePictureUrl,
                      userId: widget.otherUser.id.toString(),
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey[300],
                          child: const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        );
                      }
                      if (snapshot.hasError ||
                          snapshot.data == null ||
                          snapshot.data == "null") {
                        return CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey[300],
                          child: Text(
                            widget.otherUser.username[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      return FutureBuilder<Map<String, String>>(
                        future: _apiService.getImageHeaders(),
                        builder: (context, headersSnapshot) {
                          return CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.grey[300],
                            child: ClipOval(
                              child: Image.network(
                                snapshot.data!,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                headers: headersSnapshot.data ?? {},
                                errorBuilder: (context, error, stackTrace) {
                                  return CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.grey[300],
                                    child: Text(
                                      widget.otherUser.username[0]
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) {
                                    return child;
                                  }
                                  return CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.grey[300],
                                    child: const CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.blue),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.otherUser.fullName ?? widget.otherUser.username,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        widget.otherUser.username,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: const [],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorState()
                    : _messages.isEmpty
                        ? _buildEmptyState()
                        : _buildMessagesList(),
          ),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Messages',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'An unknown error occurred',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadMessages,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 60,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with ${widget.otherUser.username}',
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

  Widget _buildMessagesList() {
    return ListView.builder(
      key: const PageStorageKey('chat-messages-list'),
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      reverse: true,
      itemCount: _messages.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isLoadingMore && index == _messages.length) {
          return const Center(
              child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: CircularProgressIndicator(),
          ));
        }
        if (index >= _messages.length) return const SizedBox.shrink();
        final message = _messages[index];
        return KeyedSubtree(
          key: ValueKey(message.id),
          child: _buildMessageBubble(message),
        );
      },
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isMyMessage =
        _currentUser != null && message.sender.id == _currentUser!.id;

    // Only show video preview if messageType == 'video'
    String? videoIdForPreview;
    if (message.messageType == 'video') {
      final reg = RegExp(r'^\[videoid:(\d+)\]');
      final match = reg.firstMatch(message.content.trim());
      if (match != null) {
        videoIdForPreview = match.group(1);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _SwipeableMessage(
        isMyMessage: isMyMessage,
        onReply: () => _setReplyTo(message),
        onLongPress: () => _showMessageOptions(message),
        child: Row(
          mainAxisAlignment:
              isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMyMessage) ...[
              FutureBuilder<String>(
                future: _apiService.getProfileImageUrl(
                  message.sender.profilePictureUrl,
                  userId: message.sender.id.toString(),
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey[300],
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    );
                  }

                  if (snapshot.hasError ||
                      snapshot.data == null ||
                      snapshot.data == "null") {
                    return CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey[300],
                      child: Text(
                        message.sender.username[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }

                  return FutureBuilder<Map<String, String>>(
                    future: _apiService.getImageHeaders(),
                    builder: (context, headersSnapshot) {
                      return CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey[300],
                        child: ClipOval(
                          child: Image.network(
                            snapshot.data!,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            headers: headersSnapshot.data ?? {},
                            errorBuilder: (context, error, stackTrace) {
                              return CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.grey[300],
                                child: Text(
                                  message.sender.username[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              }
                              return CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.grey[300],
                                child: const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.blue),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isMyMessage
                      ? const Color(0xFF007AFF)
                      : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isMyMessage ? 20 : 4),
                    bottomRight: Radius.circular(isMyMessage ? 4 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Video preview card
                        if (videoIdForPreview != null) ...[
                          _VideoPreviewCard(
                            videoId: videoIdForPreview,
                            sender: message.sender,
                          ),
                        ] else ...[
                          // Reply preview
                          if (message.replyTo != null) ...[
                            _buildReplyPreview(message.replyTo!, isMyMessage),
                          ],
                          // Message content
                          Text(
                            message.content,
                            style: TextStyle(
                              color: isMyMessage ? Colors.white : Colors.black,
                              fontSize: 16,
                              height: 1.3,
                            ),
                          ),
                        ],

                        // Timestamp and reply indicator
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTimestamp(message.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: isMyMessage
                                    ? Colors.white.withOpacity(0.7)
                                    : Colors.grey[500],
                              ),
                            ),
                            if (message.replyTo != null) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Icons.reply,
                                size: 11,
                                color: isMyMessage
                                    ? Colors.white.withOpacity(0.7)
                                    : Colors.grey[500],
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    // Reaction emoji at bottom right, slightly outside the bubble
                    if (message.reaction != null)
                      Positioned(
                        bottom: -25,
                        right: -25,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            message.reaction!,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey[200]!),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Reply preview
            if (_replyToMessage != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Replying to ${_replyToMessage!.sender.username}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF007AFF),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _replyToMessage!.content,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _clearReplyTo,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Message input
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: _replyToMessage != null
                              ? 'Reply to ${_replyToMessage!.sender.username}...'
                              : 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),
                        maxLines: 4,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF007AFF),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF007AFF),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                      iconSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMessage(Message message) async {
    try {
      final result = await _apiService.deleteMessage(message.id);
      if (result['success']) {
        setState(() {
          _messages.remove(message);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String? _extractVideoId(String content) {
    final reg = RegExp(r'^\[videoid:(\d+)\]');
    final match = reg.firstMatch(content.trim());
    return match?.group(1);
  }

  Widget _buildReplyPreview(Message replyToMessage, bool isMyMessage) {
    // Check if the replied message is a video
    final videoId = _extractVideoId(replyToMessage.content);

    if (videoId != null) {
      // Show video preview for replied video
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: _ReplyVideoPreviewCard(
          videoId: videoId,
          isMyMessage: isMyMessage,
        ),
      );
    } else {
      // Show text preview for regular messages
      return Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isMyMessage
              ? Colors.white.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMyMessage
                ? Colors.white.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          replyToMessage.content,
          style: TextStyle(
            fontSize: 13,
            color:
                isMyMessage ? Colors.white.withOpacity(0.9) : Colors.grey[700],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
  }
}

class _VideoPreviewCard extends StatelessWidget {
  final String videoId;
  final User sender;
  const _VideoPreviewCard({required this.videoId, required this.sender});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        apiService.getThumbnailUrl(videoId),
        apiService.getImageHeaders(),
        apiService.getVideoById(videoId),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: 120,
            height: 180,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Container(
            width: 120,
            height: 180,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: const Center(child: Icon(Icons.videocam, size: 48)),
          );
        }
        final thumbnailUrl = snapshot.data![0] as String? ?? '';
        final headers = snapshot.data![1] as Map<String, String>? ?? {};
        final videoDataResult = snapshot.data![2] as Map<String, dynamic>?;
        String? creatorUsername;
        String? creatorProfilePictureUrl;
        int? creatorId;
        if (videoDataResult != null &&
            videoDataResult['success'] == true &&
            videoDataResult['video'] != null) {
          final video = videoDataResult['video'];
          // Try common field names for creator info
          if (video['creator'] != null) {
            creatorUsername = video['creator']['username'];
            creatorProfilePictureUrl = video['creator']['profilePictureUrl'];
            creatorId = video['creator']['id'];
          } else if (video['user'] != null) {
            creatorUsername = video['user']['username'];
            creatorProfilePictureUrl = video['user']['profilePictureUrl'];
            creatorId = video['user']['id'];
          }
        }
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    SingleVideoPlayerScreen(videoData: {'id': videoId}),
              ),
            );
          },
          child: Container(
            width: 120,
            height: 180,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    thumbnailUrl,
                    width: 120,
                    height: 180,
                    fit: BoxFit.cover,
                    headers: headers,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 120,
                      height: 180,
                      color: Colors.grey[300],
                      child: const Icon(Icons.videocam, size: 48),
                    ),
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow,
                      color: Colors.white, size: 32),
                ),
                // Profile picture and username of video creator at bottom left
                if (creatorId != null && creatorUsername != null)
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Row(
                      children: [
                        FutureBuilder<String>(
                          future: apiService.getProfileImageUrl(
                            creatorProfilePictureUrl,
                            userId: creatorId.toString(),
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.grey[300],
                                child: const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            }
                            if (snapshot.hasError ||
                                snapshot.data == null ||
                                snapshot.data == "null") {
                              return CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.grey[300],
                                child: Text(
                                  creatorUsername![0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }
                            return FutureBuilder<Map<String, String>>(
                              future: apiService.getImageHeaders(),
                              builder: (context, headersSnapshot) {
                                return CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.grey[300],
                                  child: ClipOval(
                                    child: Image.network(
                                      snapshot.data!,
                                      width: 28,
                                      height: 28,
                                      fit: BoxFit.cover,
                                      headers: headersSnapshot.data ?? {},
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Colors.grey[300],
                                          child: Text(
                                            creatorUsername![0].toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      },
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Colors.grey[300],
                                          child: const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 50),
                            child: Text(
                              creatorUsername,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReplyVideoPreviewCard extends StatelessWidget {
  final String videoId;
  final bool isMyMessage;

  const _ReplyVideoPreviewCard({
    required this.videoId,
    required this.isMyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        apiService.getThumbnailUrl(videoId),
        apiService.getImageHeaders(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              color: isMyMessage
                  ? Colors.white.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isMyMessage
                    ? Colors.white.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              color: isMyMessage
                  ? Colors.white.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isMyMessage
                    ? Colors.white.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.videocam,
              size: 20,
              color: isMyMessage
                  ? Colors.white.withOpacity(0.7)
                  : Colors.grey[600],
            ),
          );
        }

        final thumbnailUrl = snapshot.data![0] as String? ?? '';
        final headers = snapshot.data![1] as Map<String, String>? ?? {};

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    SingleVideoPlayerScreen(videoData: {'id': videoId}),
              ),
            );
          },
          child: Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isMyMessage
                    ? Colors.white.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    thumbnailUrl,
                    width: 60,
                    height: 80,
                    fit: BoxFit.cover,
                    headers: headers,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 60,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isMyMessage
                            ? Colors.white.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.videocam,
                        size: 20,
                        color: isMyMessage
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
