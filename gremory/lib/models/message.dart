class Message {
  final int? id;
  final String role;
  final String content;
  final int? conversationId;
  final int? senderId;
  final String messageType;
  final int? replyToId;  // New field from API
  final int? threadId;  // New field from API
  final int threadLevel;  // New field from API
  final Map<String, dynamic>? messageMetadata;  // New field from API
  final String processingStatus;  // New field from API
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;  // New field from API
  final DateTime? deletedAt;  // New field from API
  final String? senderUsername;  // New field from API
  final String? senderDisplayName;  // New field from API

  Message({
    this.id,
    required this.role,
    required this.content,
    this.conversationId,
    this.senderId,
    this.messageType = 'text',
    this.replyToId,
    this.threadId,
    this.threadLevel = 0,
    this.messageMetadata,
    this.processingStatus = 'processed',
    this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
    this.deletedAt,
    this.senderUsername,
    this.senderDisplayName,
  });

  factory Message.user(String content, {int? senderId, int? conversationId}) {
    return Message(
      role: 'user',
      content: content,
      senderId: senderId,
      conversationId: conversationId,
      messageType: 'text',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory Message.assistant(String content, {int? conversationId}) {
    return Message(
      role: 'assistant',
      content: content,
      conversationId: conversationId,
      messageType: 'ai_response',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    // Determine role from message_type or existing role field
    String role = 'user';
    final messageType = json['message_type'] as String? ?? 'text';
    if (messageType == 'ai_response' || messageType == 'system') {
      role = 'assistant';
    } else if (json['role'] != null) {
      role = json['role'] as String;
    }

    return Message(
      id: json['id'] as int?,
      role: role,
      content: json['content'] as String? ?? '',
      conversationId: json['conversation_id'] as int?,
      senderId: json['sender_id'] as int?,
      messageType: messageType,
      replyToId: json['reply_to_id'] as int?,
      threadId: json['thread_id'] as int?,
      threadLevel: json['thread_level'] as int? ?? 0,
      messageMetadata: json['message_metadata'] as Map<String, dynamic>?,
      processingStatus: json['processing_status'] as String? ?? 'processed',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isDeleted: json['is_deleted'] as bool? ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      senderUsername: json['sender_username'] as String?,
      senderDisplayName: json['sender_display_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'message_type': messageType,
      'reply_to_id': replyToId,
      'thread_id': threadId,
      'thread_level': threadLevel,
      'message_metadata': messageMetadata,
      'processing_status': processingStatus,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_deleted': isDeleted,
      'deleted_at': deletedAt?.toIso8601String(),
      'sender_username': senderUsername,
      'sender_display_name': senderDisplayName,
    };
  }

  bool get isUser => role == 'user' || messageType == 'text';
  bool get isAssistant => role == 'assistant' || messageType == 'ai_response' || messageType == 'system';
  bool get isSystem => messageType == 'system';
  bool get isProcessing => processingStatus == 'processing';
  bool get isProcessed => processingStatus == 'processed';
  bool get isError => processingStatus == 'error';
}
