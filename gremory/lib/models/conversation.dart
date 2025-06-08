import 'message.dart';

class Conversation {
  final int? id;
  final int userId;
  final String title;
  final String? name;  // New field from API
  final String? type;  // New field from API
  final String? description;  // New field from API
  final int? createdBy;  // New field from API
  final String conversationState;  // New field from API
  final Map<String, dynamic>? contextData;  // New field from API
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;
  final bool isArchived;  // New field from API
  final int messageCount;  // New field from API
  final DateTime? lastMessageAt;  // New field from API
  final String? lastMessagePreview;  // New field from API
  final String? creatorUsername;  // New field from API
  final String? creatorDisplayName;  // New field from API
  final List<Message> messages;

  Conversation({
    this.id,
    required this.userId,
    required this.title,
    this.name,
    this.type,
    this.description,
    this.createdBy,
    this.conversationState = 'active',
    this.contextData,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'active',
    this.isArchived = false,
    this.messageCount = 0,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.creatorUsername,
    this.creatorDisplayName,
    this.messages = const [],
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as int?,
      userId: json['user_id'] as int? ?? json['created_by'] as int? ?? 0,
      title: json['title'] as String? ?? json['name'] as String? ?? 'Untitled Conversation',
      name: json['name'] as String?,
      type: json['type'] as String?,
      description: json['description'] as String?,
      createdBy: json['created_by'] as int?,
      conversationState: json['conversation_state'] as String? ?? 'active',
      contextData: json['context_data'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      status: json['status'] as String? ?? json['conversation_state'] as String? ?? 'active',
      isArchived: json['is_archived'] as bool? ?? false,
      messageCount: json['message_count'] as int? ?? 0,
      lastMessageAt: json['last_message_at'] != null 
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      lastMessagePreview: json['last_message_preview'] as String?,
      creatorUsername: json['creator_username'] as String?,
      creatorDisplayName: json['creator_display_name'] as String?,
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
      'name': name,
      'type': type,
      'description': description,
      'created_by': createdBy,
      'conversation_state': conversationState,
      'context_data': contextData,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'status': status,
      'is_archived': isArchived,
      'message_count': messageCount,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'last_message_preview': lastMessagePreview,
      'creator_username': creatorUsername,
      'creator_display_name': creatorDisplayName,
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  Conversation copyWith({
    int? id,
    int? userId,
    String? title,
    String? name,
    String? type,
    String? description,
    int? createdBy,
    String? conversationState,
    Map<String, dynamic>? contextData,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    bool? isArchived,
    int? messageCount,
    DateTime? lastMessageAt,
    String? lastMessagePreview,
    String? creatorUsername,
    String? creatorDisplayName,
    List<Message>? messages,
  }) {
    return Conversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      conversationState: conversationState ?? this.conversationState,
      contextData: contextData ?? this.contextData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      isArchived: isArchived ?? this.isArchived,
      messageCount: messageCount ?? this.messageCount,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      creatorUsername: creatorUsername ?? this.creatorUsername,
      creatorDisplayName: creatorDisplayName ?? this.creatorDisplayName,
      messages: messages ?? this.messages,
    );
  }

  String get preview {
    if (lastMessagePreview != null && lastMessagePreview!.isNotEmpty) {
      return lastMessagePreview!;
    }
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
    final timeToCheck = lastMessageAt ?? updatedAt;
    final now = DateTime.now();
    final difference = now.difference(timeToCheck);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timeToCheck.day}/${timeToCheck.month}/${timeToCheck.year}';
    }
  }

  bool get isArchivedStatus => isArchived || status == 'archived' || conversationState == 'archived';
  bool get isActive => conversationState == 'active' || (status == 'active' && !isArchived);
  bool get isDeleted => status == 'deleted';
  bool get isPaused => conversationState == 'paused';
  bool get isCompleted => conversationState == 'completed';
}
