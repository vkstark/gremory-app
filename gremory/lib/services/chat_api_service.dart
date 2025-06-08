import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ChatAPIService {
  final String baseUrl = "https://gremory-backend.onrender.com/api/v1";

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

  // New methods to match your backend conversation endpoints
  Future<Map<String, dynamic>> getUserConversations({
    required int userId,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/conversations/$userId').replace(
        queryParameters: {
          'page': page.toString(),
          'per_page': perPage.toString(),
        },
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
    required int userId,
    required int conversationId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/conversations/$userId/$conversationId'),
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

  Future<Map<String, dynamic>> createNewConversation({
    required int userId,
    String? title,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/conversations/$userId/new'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
        }),
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

  Future<Map<String, dynamic>> continueConversation({
    required int userId,
    required int conversationId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/conversations/$userId/$conversationId/continue'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to continue conversation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error continuing conversation: $e');
    }
  }

  Future<void> deleteConversation({
    required int userId,
    required int conversationId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/conversations/$userId/$conversationId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete conversation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting conversation: $e');
    }
  }
}
