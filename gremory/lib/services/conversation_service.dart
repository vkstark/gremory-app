import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/conversation.dart';
import '../models/message.dart';
import '../services/chat_api_service.dart';

class ConversationService {
  final ChatAPIService _chatApiService = ChatAPIService();

  Future<List<Conversation>> getUserConversations(int userId) async {
    try {
      final response = await _chatApiService.getUserConversations(userId: userId);
      
      // Parse conversations from the response
      final List<dynamic> conversationsData = response['conversations'] ?? response['data'] ?? [];
      return conversationsData.map((json) => Conversation.fromJson(json)).toList();
    } catch (e) {
      print('Error loading conversations: $e');
      return [];
    }
  }

  Future<List<Message>> getConversationMessages(int conversationId) async {
    try {
      // For now, we'll use a placeholder since we need to know the userId
      // This method might need to be refactored to include userId
      return [];
    } catch (e) {
      print('Error loading messages: $e');
      return [];
    }
  }

  Future<List<Message>> getConversationDetails(int userId, int conversationId) async {
    try {
      final response = await _chatApiService.getConversationDetails(
        userId: userId,
        conversationId: conversationId,
      );
      
      // Extract messages from the conversation details
      final conversationData = response['data'] ?? response;
      final List<dynamic> messagesData = conversationData['messages'] ?? [];
      
      return messagesData.map((json) => Message.fromJson(json)).toList();
    } catch (e) {
      print('Error loading conversation details: $e');
      return [];
    }
  }

  Future<Conversation> createConversation({
    required int userId,
    required String title,
  }) async {
    try {
      final response = await _chatApiService.createNewConversation(
        userId: userId,
        title: title,
      );
      
      final conversationData = response['data'] ?? response;
      return Conversation.fromJson(conversationData);
    } catch (e) {
      throw Exception('Error creating conversation: $e');
    }
  }

  Future<void> updateConversationStatus(int conversationId, String status) async {
    try {
      // This functionality might need to be implemented in the backend
      // For now, we'll implement it as a placeholder
      print('Update conversation status not implemented in backend');
    } catch (e) {
      print('Error updating conversation status: $e');
    }
  }

  Future<void> updateConversationTitle(int conversationId, String title) async {
    try {
      // This functionality might need to be implemented in the backend
      print('Update conversation title not implemented in backend');
    } catch (e) {
      print('Error updating conversation title: $e');
    }
  }

  Future<void> deleteConversation(int userId, int conversationId) async {
    try {
      await _chatApiService.deleteConversation(
        userId: userId,
        conversationId: conversationId,
      );
    } catch (e) {
      print('Error deleting conversation: $e');
    }
  }

  Future<void> continueConversation(int userId, int conversationId) async {
    try {
      await _chatApiService.continueConversation(
        userId: userId,
        conversationId: conversationId,
      );
    } catch (e) {
      print('Error continuing conversation: $e');
    }
  }
}
