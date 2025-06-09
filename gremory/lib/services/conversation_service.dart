import '../models/conversation.dart';
import '../models/message.dart';
import '../services/chat_api_service.dart';
import '../utils/logger.dart';

class ConversationService {
  final ChatAPIService _chatApiService = ChatAPIService();

  Future<List<Conversation>> getUserConversations(int userId) async {
    try {
      final response = await _chatApiService.getUserConversations(userId: userId);
      
      // Parse conversations from the new response structure
      final List<dynamic> conversationsData = response['conversations'] ?? response['data'] ?? [];
      final conversations = conversationsData.map((json) => Conversation.fromJson(json)).toList();
      
      // Sort conversations by last activity (last_message_at or updated_at), most recent first
      conversations.sort((a, b) {
        final aTime = a.lastMessageAt ?? a.updatedAt;
        final bTime = b.lastMessageAt ?? b.updatedAt;
        return bTime.compareTo(aTime); // Descending order (most recent first)
      });
      
      return conversations;
    } catch (e) {
      Logger.error('Error loading conversations', 'ConversationService', e);
      return [];
    }
  }

  Future<List<Message>> getConversationMessages(int conversationId, {int? userId}) async {
    try {
      final response = await _chatApiService.getConversationMessages(
        conversationId: conversationId,
        userId: userId,
      );
      
      // Extract messages from the new response structure
      final List<dynamic> messagesData = response['messages'] ?? response['data'] ?? [];
      return messagesData.map((json) => Message.fromJson(json)).toList();
    } catch (e) {
      Logger.error('Error loading messages', 'ConversationService', e);
      return [];
    }
  }

  Future<List<Message>> getConversationDetails(int userId, int conversationId) async {
    try {
      final response = await _chatApiService.getConversationDetails(
        conversationId: conversationId,
        userId: userId,
      );
      
      // Extract messages from the conversation details
      final conversationData = response['data'] ?? response['conversation'] ?? response;
      final List<dynamic> messagesData = conversationData['messages'] ?? [];
      
      return messagesData.map((json) => Message.fromJson(json)).toList();
    } catch (e) {
      Logger.error('Error loading conversation details', 'ConversationService', e);
      return [];
    }
  }

  Future<Conversation> createConversation({
    required int userId,
    required String title,
    String conversationType = 'direct',
    String? description,
    Map<String, dynamic>? contextData,
  }) async {
    try {
      final response = await _chatApiService.createNewConversation(
        userId: userId,
        name: title, // Use 'name' field as per new API
        conversationType: conversationType,
        description: description,
        contextData: contextData,
      );
      
      final conversationData = response['data'] ?? response['conversation'] ?? response;
      return Conversation.fromJson(conversationData);
    } catch (e) {
      throw Exception('Error creating conversation: $e');
    }
  }

  Future<void> updateConversationStatus(int conversationId, String status, {int? userId}) async {
    try {
      await _chatApiService.updateConversation(
        conversationId: conversationId,
        userId: userId,
        conversationState: status,
      );
    } catch (e) {
      Logger.error('Error updating conversation status', 'ConversationService', e);
    }
  }

  Future<void> updateConversationTitle(int conversationId, String title, {int? userId}) async {
    try {
      await _chatApiService.updateConversation(
        conversationId: conversationId,
        userId: userId,
        name: title,
      );
    } catch (e) {
      Logger.error('Error updating conversation title', 'ConversationService', e);
    }
  }

  Future<void> archiveConversation(int conversationId, {int? userId}) async {
    try {
      await _chatApiService.archiveConversation(
        conversationId: conversationId,
        userId: userId,
      );
    } catch (e) {
      Logger.error('Error archiving conversation', 'ConversationService', e);
    }
  }

  Future<void> deleteConversation(int userId, int conversationId) async {
    try {
      await _chatApiService.deleteConversation(
        conversationId: conversationId,
        userId: userId,
      );
    } catch (e) {
      Logger.error('Error deleting conversation', 'ConversationService', e);
    }
  }

  Future<void> continueConversation(int userId, int conversationId) async {
    try {
      await _chatApiService.continueConversation(
        conversationId: conversationId,
        userId: userId,
      );
    } catch (e) {
      Logger.error('Error continuing conversation', 'ConversationService', e);
    }
  }

  Future<Message> sendMessageToConversation({
    required int conversationId,
    required int senderId,
    required String content,
    String messageType = 'text',
    int? replyToId,
    Map<String, dynamic>? messageMetadata,
  }) async {
    try {
      final response = await _chatApiService.sendMessageToConversation(
        conversationId: conversationId,
        senderId: senderId,
        content: content,
        messageType: messageType,
        replyToId: replyToId,
        messageMetadata: messageMetadata,
      );
      
      final messageData = response['data'] ?? response['message'] ?? response;
      return Message.fromJson(messageData);
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }
}
