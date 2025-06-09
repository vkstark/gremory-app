import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

const String baseUrl = String.fromEnvironment('BASE_URL');
class ChatAPIService {

  Future<List<String>> getSupportedModels() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/models'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final List<dynamic> models = json['supported_models'] ?? [];
        return models.cast<String>();
      } else {
        throw Exception('Failed to load models: ${response.statusCode}');
      }
    } catch (e) {
      // Return fallback models that match your backend enum
      return [
        'ollama_qwen',
        'ollama_llama', 
        'gemini_2o_flash',
        'openai_gpt4',
      ];
    }
  }

  Future<Map<String, dynamic>> sendMessage({
    required String model,
    required String userQuery,
    required int userId,
    int? conversationId,
  }) async {
    try {
      // Match the exact payload structure expected by your backend
      final Map<String, dynamic> requestBody = {
        'lm_name': model,
        'user_query': userQuery,
        'user_id': userId,
        'conversation_id': conversationId, // Can be null for new conversations
      };

      if (kDebugMode) {
        print('Sending request to: $baseUrl/chat');
        print('Request body: ${jsonEncode(requestBody)}');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        // Parse response according to your backend structure
        String aiResponse = '';
        String modelUsed = model;
        int? returnedConversationId;
        int? returnedUserId;
        bool hasReasoning = false;
        int messageCount = 0;
        
        if (responseData['code'] == 0 && responseData['data'] != null) {
          final data = responseData['data'];
          
          // Extract the AI response based on your backend response structure
          if (data['answer'] != null) {
            final answerData = data['answer'];
            
            // Handle different response formats from your backend
            if (answerData is Map<String, dynamic>) {
              // If it's a structured response with thought, actions, etc.
              if (answerData.containsKey('response')) {
                aiResponse = answerData['response'] as String? ?? '';
              } else if (answerData.containsKey('structured_response')) {
                final structuredResponse = answerData['structured_response'];
                if (structuredResponse is Map<String, dynamic>) {
                  aiResponse = structuredResponse['response'] as String? ?? '';
                } else {
                  aiResponse = structuredResponse.toString();
                }
              }
              
              // Check for additional text
              if (aiResponse.isEmpty && answerData.containsKey('additional_text')) {
                aiResponse = answerData['additional_text'] as String? ?? '';
              }
            } else if (answerData is String) {
              // Direct string response
              aiResponse = answerData;
            } else {
              aiResponse = answerData.toString();
            }
          }
          
          // Extract metadata
          modelUsed = data['model_used'] as String? ?? model;
          returnedConversationId = data['conversation_id'] as int?;
          returnedUserId = data['user_id'] as int?;
          hasReasoning = data['has_reasoning'] as bool? ?? false;
          messageCount = data['message_count'] as int? ?? 0;
          
          if (kDebugMode) {
            print('Extracted AI response: "$aiResponse"');
            print('Conversation ID: $returnedConversationId');
            print('User ID: $returnedUserId');
            print('Has reasoning: $hasReasoning');
            print('Message count: $messageCount');
          }
        }
        
        return {
          'response': aiResponse,
          'model_used': modelUsed,
          'conversation_id': returnedConversationId,
          'user_id': returnedUserId,
          'has_reasoning': hasReasoning,
          'message_count': messageCount,
          'raw_data': responseData,
        };
      } else {
        final errorBody = response.body;
        if (kDebugMode) {
          print('API Error: $errorBody');
        }
        throw Exception('Failed to send message: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in sendMessage: $e');
      }
      throw Exception('Error sending message: $e');
    }
  }

  Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // User History API endpoints (updated for new consolidated API)
  Future<Map<String, dynamic>> getUserConversations({
    required int userId,
    int page = 1,
    int perPage = 20,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
    String? conversationType,
    String? conversationState,
    bool? isArchived,
    String? searchQuery,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
        'sort_by': sortBy,
        'sort_order': sortOrder,
      };
      
      if (conversationType != null) queryParams['conversation_type'] = conversationType;
      if (conversationState != null) queryParams['conversation_state'] = conversationState;
      if (isArchived != null) queryParams['is_archived'] = isArchived.toString();
      if (searchQuery != null) queryParams['search_query'] = searchQuery;

      final uri = Uri.parse('$baseUrl/user/$userId/history').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load conversations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading conversations: $e');
    }
  }

  Future<Map<String, dynamic>> getConversationDetails({
    required int conversationId,
    int? userId,
  }) async {
    try {
      final Map<String, String> queryParams = {};
      if (userId != null) queryParams['user_id'] = userId.toString();

      final uri = Uri.parse('$baseUrl/conversation/$conversationId').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load conversation details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading conversation details: $e');
    }
  }

  Future<Map<String, dynamic>> getConversationMessages({
    required int conversationId,
    int? userId,
    int page = 1,
    int perPage = 50,
    String sortBy = 'created_at',
    String sortOrder = 'asc',
    String? messageType,
    int? senderId,
    String? searchQuery,
    bool includeDeleted = false,
    bool includeConversationDetails = false,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
        'sort_by': sortBy,
        'sort_order': sortOrder,
        'include_deleted': includeDeleted.toString(),
        'include_conversation_details': includeConversationDetails.toString(),
      };
      
      if (userId != null) queryParams['user_id'] = userId.toString();
      if (messageType != null) queryParams['message_type'] = messageType;
      if (senderId != null) queryParams['sender_id'] = senderId.toString();
      if (searchQuery != null) queryParams['search_query'] = searchQuery;

      final uri = Uri.parse('$baseUrl/conversation/$conversationId/messages').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load conversation messages: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading conversation messages: $e');
    }
  }

  Future<Map<String, dynamic>> sendMessageToConversation({
    required int conversationId,
    required int senderId,
    required String content,
    String messageType = 'text',
    int? replyToId,
    Map<String, dynamic>? messageMetadata,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'sender_id': senderId,
        'content': content,
        'message_type': messageType,
      };

      if (replyToId != null) requestBody['reply_to_id'] = replyToId;
      if (messageMetadata != null) requestBody['message_metadata'] = messageMetadata;

      final response = await http.post(
        Uri.parse('$baseUrl/conversation/$conversationId/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  Future<Map<String, dynamic>> createNewConversation({
    required int userId,
    String? title,
    String? name,
    String conversationType = 'direct',
    String? description,
    Map<String, dynamic>? contextData,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'user_id': userId,
        'conversation_type': conversationType,
      };

      // Use 'name' field as per the new API schema, fallback to 'title' for backward compatibility
      if (name != null) {
        requestBody['name'] = name;
      } else if (title != null) {
        requestBody['name'] = title;
      }
      
      if (description != null) requestBody['description'] = description;
      if (contextData != null) requestBody['context_data'] = contextData;

      final response = await http.post(
        Uri.parse('$baseUrl/user/history'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create conversation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating conversation: $e');
    }
  }

  Future<Map<String, dynamic>> updateConversation({
    required int conversationId,
    int? userId,
    String? name,
    String? description,
    String? conversationState,
    Map<String, dynamic>? contextData,
  }) async {
    try {
      final Map<String, String> queryParams = {};
      if (userId != null) queryParams['user_id'] = userId.toString();

      final Map<String, dynamic> requestBody = {};
      if (name != null) requestBody['name'] = name;
      if (description != null) requestBody['description'] = description;
      if (conversationState != null) requestBody['conversation_state'] = conversationState;
      if (contextData != null) requestBody['context_data'] = contextData;

      final uri = Uri.parse('$baseUrl/conversation/$conversationId').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update conversation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating conversation: $e');
    }
  }

  // Archive conversation by updating conversation_state to 'archived'
  Future<Map<String, dynamic>> archiveConversation({
    required int conversationId,
    int? userId,
  }) async {
    return updateConversation(
      conversationId: conversationId,
      userId: userId,
      conversationState: 'archived',
      contextData: {'operation': 'archive', 'timestamp': DateTime.now().toIso8601String()},
    );
  }

  // Continue conversation by updating conversation_state to 'active'
  Future<Map<String, dynamic>> continueConversation({
    required int conversationId,
    int? userId,
  }) async {
    return updateConversation(
      conversationId: conversationId,
      userId: userId,
      conversationState: 'active',
      contextData: {'operation': 'continue', 'timestamp': DateTime.now().toIso8601String()},
    );
  }

  Future<void> deleteConversation({
    required int conversationId,
    int? userId,
  }) async {
    try {
      final Map<String, String> queryParams = {};
      if (userId != null) queryParams['user_id'] = userId.toString();

      final uri = Uri.parse('$baseUrl/conversation/$conversationId').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.delete(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete conversation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting conversation: $e');
    }
  }

  Future<bool> userHistoryHealthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user-history/health'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
