class Message {
  final String role;
  final String content;

  Message({required this.role, required this.content});

  factory Message.user(String content) {
    return Message(role: 'user', content: content);
  }

  factory Message.assistant(String content) {
    return Message(role: 'assistant', content: content);
  }
}
