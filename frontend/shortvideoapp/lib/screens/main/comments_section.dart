import 'package:flutter/material.dart';
import 'package:shortvideoapp/constants/strings.dart';
import 'package:shortvideoapp/models/user_model.dart';
import 'package:shortvideoapp/screens/main/profile.dart';
import 'package:shortvideoapp/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:shortvideoapp/services/video_player_service.dart';

class CommentsSection extends StatefulWidget {
  final String videoId;
  final String? playerContextId; // new
  final ApiService apiService;
  final Function(int)? onCommentCountChanged;
  final bool isBottomSheet;

  const CommentsSection({
    Key? key,
    required this.videoId,
    this.playerContextId,
    required this.apiService,
    this.onCommentCountChanged,
    this.isBottomSheet = false,
  }) : super(key: key);

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  List<Map<String, dynamic>> comments = [];
  bool isLoading = true;
  bool isPostingComment = false;
  String? replyToCommentId;
  String? replyToUsername;
  String? selectedCommentId;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  _loadCurrentUser() async {
    final localUser = await widget.apiService.getCurrentUser();
    if (localUser != null) {
      setState(() {
        currentUser = localUser;
      });
    }
  }

  Future<void> _loadComments() async {
    setState(() {
      isLoading = true;
    });

    final response = await widget.apiService.getVideoComments(widget.videoId);

    if (response['success']) {
      setState(() {
        comments = List<Map<String, dynamic>>.from(response['comments']);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to load comments'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _postComment() async {
    if (isPostingComment || _commentController.text.isEmpty) return;

    setState(() {
      isPostingComment = true;
    });

    final response = await widget.apiService.postComment(
      widget.videoId,
      _commentController.text,
      parentCommentId: replyToCommentId,
    );

    setState(() {
      isPostingComment = false;
    });

    if (response['success']) {
      // Refresh comments to show new comment
      _loadComments();

      // Update comment count
      if (widget.onCommentCountChanged != null) {
        widget.onCommentCountChanged!(response['commentsCount']);
      }

      // Clear the text field and reply state
      _commentController.clear();
      _commentFocusNode.unfocus();
      _cancelReply();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Failed to post comment'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleCommentLike(String commentId, int commentIndex,
      {int? replyIndex}) async {
    final response = await widget.apiService.toggleCommentLike(commentId);

    if (response['success']) {
      setState(() {
        if (replyIndex != null) {
          // Update reply like status
          comments[commentIndex]['replies'][replyIndex]['isLiked'] =
              response['isLiked'];
          comments[commentIndex]['replies'][replyIndex]['likesCount'] =
              response['likesCount'];
        } else {
          // Update comment like status
          comments[commentIndex]['isLiked'] = response['isLiked'];
          comments[commentIndex]['likesCount'] = response['likesCount'];
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Failed to like comment'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _replyToComment(String commentId, String username,
      {String? topLevelId}) {
    setState(() {
      selectedCommentId = commentId;
      // If topLevelId is provided, use it; otherwise, use commentId
      replyToCommentId = topLevelId ?? commentId;
      replyToUsername = username;
    });
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      replyToCommentId = null;
      replyToUsername = null;
      selectedCommentId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.isBottomSheet
          ? MediaQuery.of(context).size.height * 0.8
          : null,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: widget.isBottomSheet
            ? const BorderRadius.vertical(top: Radius.circular(24))
            : null,
        boxShadow: [
          if (widget.isBottomSheet)
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
        ],
      ),
      child: Column(
        children: [
          // Header
          if (widget.isBottomSheet)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Text(
                    AppStrings.comments,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          // Comments List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : comments.isEmpty
                    ? Center(
                        child: Text(
                          AppStrings.noCommentsYet,
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 15),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          return _buildCommentItem(comments[index], index);
                        },
                      ),
          ),
          // Comment Input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Reply indicator
                if (replyToCommentId != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.reply, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          'Replying to @$replyToUsername',
                          style:
                              const TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _cancelReply,
                          child: const Icon(Icons.close,
                              size: 16, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                // Comment text field
                Row(
                  children: [
                    // Profile picture
                    FutureBuilder<String>(
                      future: ApiService().getProfileImageUrl(
                          currentUser?.profilePictureUrl,
                          userId: currentUser?.id.toString()),
                      builder: (context, snapshot) {
                        final imageUrl = snapshot.data ?? "null";
                        return FutureBuilder<Map<String, String>>(
                          future: ApiService().getImageHeaders(),
                          builder: (context, headerSnap) {
                            final headers = headerSnap.data ?? {};
                            return CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.grey[300],
                              child: ClipOval(
                                child: Image.network(
                                  imageUrl,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  headers: headers,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.person,
                                        size: 18, color: Colors.grey[600]);
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: TextField(
                          controller: _commentController,
                          focusNode: _commentFocusNode,
                          enabled: !isPostingComment,
                          decoration: InputDecoration(
                            hintText: replyToCommentId != null
                                ? 'Add a reply...'
                                : AppStrings.addComment,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(color: Colors.black),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                          maxLines: 1,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _postComment(),
                          style: const TextStyle(fontSize: 15),
                          onChanged: (text) {
                            setState(
                                () {}); // Trigger rebuild when text changes
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                        icon: isPostingComment
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(Icons.send_rounded,
                                color: _commentController.text.trim().isEmpty
                                    ? Colors.grey
                                    : Colors.red),
                        onPressed: isPostingComment ||
                                _commentController.text.trim().isEmpty
                            ? null
                            : _postComment),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment, int index) {
    final replies = comment['replies'] as List<dynamic>? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildComment(comment, index, isTopLevel: true),
        // Replies
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              children: replies.asMap().entries.map((entry) {
                final replyIndex = entry.key;
                final reply = entry.value;
                return _buildComment(reply, index,
                    replyIndex: replyIndex,
                    topLevelId: comment['id'].toString());
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildComment(Map<String, dynamic> comment, int index,
      {int? replyIndex, bool isTopLevel = false, String? topLevelId}) {
    final user = comment['user'];
    final isLiked = comment['isLiked'] ?? false;
    final likesCount = comment['likesCount'] ?? 0;
    final profileUrl = user?['profilePictureUrl'] as String?;
    final userId = user?['id']?.toString();

    bool isOwnComment = false;
    if (currentUser != null) {
      isOwnComment = userId == currentUser?.id.toString();
    }

    return GestureDetector(
      onLongPress: isOwnComment
          ? () async {
              final action = await showMenu<String>(
                context: context,
                position: const RelativeRect.fromLTRB(100, 100, 100, 100),
                items: [
                  const PopupMenuItem<String>(
                    value: 'copy',
                    child: Text('Copy'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              );
              if (action == 'copy') {
                Clipboard.setData(ClipboardData(text: comment['text'] ?? ''));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              } else if (action == 'delete') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Comment'),
                    content: const Text(
                        'Are you sure you want to delete this comment?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await _deleteComment(comment['id'].toString());
                }
              }
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile picture with navigation
            GestureDetector(
              onTap: userId != null && user?['username'] != null
                  ? () async {
                      await EnhancedVideoService()
                          .pauseVideo(widget.playerContextId ?? widget.videoId);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfilePage(
                            userId: int.tryParse(userId) ?? 0,
                            username: user['username'],
                            isPublicUser: true,
                          ),
                        ),
                      );
                    }
                  : null,
              child: FutureBuilder<String>(
                future:
                    ApiService().getProfileImageUrl(profileUrl, userId: userId),
                builder: (context, snapshot) {
                  final imageUrl = snapshot.data ?? "null";
                  return FutureBuilder<Map<String, String>>(
                    future: ApiService().getImageHeaders(),
                    builder: (context, headerSnap) {
                      final headers = headerSnap.data ?? {};
                      return CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey[300],
                        child: ClipOval(
                          child: Image.network(
                            imageUrl,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            headers: headers,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.person,
                                  size: 18, color: Colors.grey[600]);
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            // Comment content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username and time
                  Row(
                    children: [
                      GestureDetector(
                        onTap: userId != null && user?['username'] != null
                            ? () async {
                                await EnhancedVideoService().pauseVideo(
                                    widget.playerContextId ?? widget.videoId);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfilePage(
                                      userId: int.tryParse(userId) ?? 0,
                                      username: user['username'],
                                      isPublicUser: true,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        child: Text(
                          user?['username'] ?? 'Anonymous',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(comment['createdAt']),
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Comment text
                  Text(
                    comment['text'] ?? '',
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  // Action buttons
                  Row(
                    children: [
                      // Like button
                      GestureDetector(
                        onTap: () => _toggleCommentLike(
                          comment['id'].toString(),
                          index,
                          replyIndex: replyIndex,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              size: 17,
                              color: isLiked ? Colors.red : Colors.grey[500],
                            ),
                            if (likesCount > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                likesCount.toString(),
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      // Reply button (for both comments and replies)
                      GestureDetector(
                        onTap: () => _replyToComment(
                          comment['id'].toString(),
                          user?['username'] ?? 'Anonymous',
                          topLevelId: isTopLevel ? null : topLevelId,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.reply,
                                size: 16, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              AppStrings.reply,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      final token = await widget.apiService.getAuthToken();
      final response = await widget.apiService.deleteComment(commentId, token!);
      if (response['success']) {
        // Refresh comments to show updated list
        _loadComments();

        // Update comment count in parent components
        if (widget.onCommentCountChanged != null &&
            response['commentsCount'] != null) {
          widget.onCommentCountChanged!(response['commentsCount']);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response['message'] ?? 'Failed to delete comment'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _formatTime(String? dateTime) {
    if (dateTime == null) return '';
    try {
      DateTime date;
      // Try ISO 8601 first
      try {
        date = DateTime.parse(dateTime);
      } catch (_) {
        // Try replacing space with T
        try {
          String normalized = dateTime.contains(' ') && !dateTime.contains('T')
              ? dateTime.replaceFirst(' ', 'T')
              : dateTime;
          date = DateTime.parse(normalized);
        } catch (_) {
          return dateTime; // fallback: show raw string
        }
      }
      // No offset, just use local time
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inSeconds < 5 || diff.isNegative) return 'just now';
      if (diff.inSeconds < 60) return '${diff.inSeconds}s';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      if (now.year == date.year) {
        return DateFormat('d-M').format(date);
      } else {
        return DateFormat('d-M-yyyy').format(date);
      }
    } catch (e) {
      return dateTime;
    }
  }
}
