import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/chat_api_service.dart';

class ChatProvider extends ChangeNotifier {
  final List<Message> _messages = [];
  final ChatAPIService _api = ChatAPIService();

  List<Message> get messages => _messages;
  void clearMessages() {
  messages.clear();
  notifyListeners();
}

  Future<void> sendMessage(String model, String content) async {
    _messages.add(Message.user(content));
    notifyListeners();

    try {
      final reply = await _api.sendMessage(model, content);
      _messages.add(reply);
    } catch (e) {
      _messages.add(Message(role: 'system', content: 'Error: ${e.toString()}'));
    }

    notifyListeners();
  }
}
