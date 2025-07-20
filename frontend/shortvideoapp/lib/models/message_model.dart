import 'user_model.dart';

class Message {
  final int id;
  final String content;
  final User sender;
  final User receiver;
  final Message? replyTo;
  final String? reaction;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? messageType;

  Message({
    required this.id,
    required this.content,
    required this.sender,
    required this.receiver,
    this.replyTo,
    this.reaction,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
    this.messageType,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      content: json['content'],
      sender: User.fromJson(json['sender']),
      receiver: User.fromJson(json['receiver']),
      replyTo:
          json['replyTo'] != null ? Message.fromJson(json['replyTo']) : null,
      reaction: json['reaction'],
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      messageType: json['message_type'] ?? json['messageType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender': sender.toJson(),
      'receiver': receiver.toJson(),
      'replyTo': replyTo?.toJson(),
      'reaction': reaction,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'message_type': messageType,
    };
  }

  Message copyWith({
    int? id,
    String? content,
    User? sender,
    User? receiver,
    Message? replyTo,
    String? reaction,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? messageType,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      replyTo: replyTo ?? this.replyTo,
      reaction: reaction ?? this.reaction,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageType: messageType ?? this.messageType,
    );
  }
}
