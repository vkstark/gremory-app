class Message {
  final int? id;
  final String role;
  final String content;
  final int? conversationId;
  final int? senderId;
  final String messageType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Message({
    this.id,
    required this.role,
    required this.content,
    this.conversationId,
    this.senderId,
    this.messageType = 'text',
    this.createdAt,
    this.updatedAt,
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
      messageType: 'text',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int?,
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      conversationId: json['conversation_id'] as int?,
      senderId: json['sender_id'] as int?,
      messageType: json['message_type'] as String? ?? 'text',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
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
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  bool get isSystem => role == 'system';
}
