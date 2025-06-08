import 'message.dart';

class Conversation {
  final int? id;
  final int userId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;
  final List<Message> messages;

  Conversation({
    this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'active',
    this.messages = const [],
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as int?,
      userId: json['user_id'] as int? ?? 0,  // Provide default if null
      title: json['title'] as String? ?? 'Untitled Conversation',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      status: json['status'] as String? ?? 'active',
      messages: (json['messages'] as List<dynamic>?)
          ?.map((m) => Message.fromJson(m as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': status,
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  Conversation copyWith({
    int? id,
    int? userId,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    List<Message>? messages,
  }) {
    return Conversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      messages: messages ?? this.messages,
    );
  }

  String get preview {
    if (messages.isNotEmpty) {
      final lastMessage = messages.last;
      if (lastMessage.content.length > 50) {
        return '${lastMessage.content.substring(0, 50)}...';
      }
      return lastMessage.content;
    }
    return title;
  }

  String get displayTime {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${updatedAt.day}/${updatedAt.month}/${updatedAt.year}';
    }
  }

  bool get isArchived => status == 'archived';
  bool get isActive => status == 'active';
  bool get isDeleted => status == 'deleted';
}
