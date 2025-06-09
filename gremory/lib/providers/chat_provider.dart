import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../services/chat_api_service.dart';
import '../services/conversation_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatAPIService _api = ChatAPIService();
  final ConversationService _conversationService = ConversationService();
  
  final List<Message> _messages = [];
  List<String> _availableModels = [];
  List<Conversation> _conversations = [];
  Conversation? _currentConversation;
  bool _isLoading = false;
  bool _isLoadingConversation = false;
  String? _error;
  String _selectedModel = 'gemini_2o_flash';

  // Getters
  List<Message> get messages => _messages;
  List<String> get availableModels => _availableModels;
  List<Conversation> get conversations => _conversations;
  Conversation? get currentConversation => _currentConversation;
  bool get isLoading => _isLoading;
  bool get isLoadingConversation => _isLoadingConversation;
  String? get error => _error;
  String get selectedModel => _selectedModel;

  Future<void> initialize({int? userId}) async {
    await loadSupportedModels();
    if (userId != null && userId > 0) {
      await loadUserConversations(userId);
    }
  }

  Future<void> loadSupportedModels() async {
    try {
      _availableModels = await _api.getSupportedModels();
      
      if (_availableModels.isNotEmpty && !_availableModels.contains(_selectedModel)) {
        _selectedModel = _availableModels.first;
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load models: $e';
      if (kDebugMode) {
        print('Error loading models: $e');
      }
      notifyListeners();
    }
  }

  Future<void> loadUserConversations(int userId) async {
    try {
      _conversations = await _conversationService.getUserConversations(userId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load conversations: $e';
      if (kDebugMode) {
        print('Error loading conversations: $e');
      }
      notifyListeners();
    }
  }

  Future<void> sendMessage(String model, String content, int userId) async {
    if (content.trim().isEmpty) return;

    _error = null;
    
    // Add user message immediately
    final userMessage = Message.user(content, senderId: userId, conversationId: _currentConversation?.id);
    _messages.add(userMessage);
    _isLoading = true;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('Sending message with userId: $userId, conversationId: ${_currentConversation?.id}');
      }
      
      final response = await _api.sendMessage(
        model: model,
        userQuery: content,
        userId: userId,
        conversationId: _currentConversation?.id,
      );

      final aiResponse = response['response'] as String? ?? 'No response received';
      final conversationId = response['conversation_id'] as int?;
      final hasReasoning = response['has_reasoning'] as bool? ?? false;
      final messageCount = response['message_count'] as int? ?? 0;
      
      if (kDebugMode) {
        print('Received AI response: "$aiResponse"');
        print('Conversation ID from response: $conversationId');
        print('Has reasoning: $hasReasoning');
        print('Message count: $messageCount');
      }

      // Ensure we have a valid response before proceeding
      if (aiResponse.isNotEmpty && aiResponse != 'No response received') {
        // Update conversation if we got a new conversation ID
        if (conversationId != null && conversationId != 0) {
          if (_currentConversation == null) {
            // Create a new conversation object
            _currentConversation = Conversation(
              id: conversationId,
              userId: userId,
              title: _generateConversationTitle(content),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              status: 'active',
            );
          } else if (_currentConversation!.id != conversationId) {
            _currentConversation = _currentConversation!.copyWith(id: conversationId);
          }
        }

        // Add AI response message
        final assistantMessage = Message.assistant(
          aiResponse,
          conversationId: conversationId,
        );
        _messages.add(assistantMessage);

        if (kDebugMode) {
          print('Added assistant message. Total messages: ${_messages.length}');
        }

        // Update conversation list if needed
        if (_currentConversation != null) {
          await _updateConversationInList(_currentConversation!);
        }
      } else {
        // Handle case where response is empty
        final errorMessage = Message.assistant(
          'I received an empty response. Please try again.',
          conversationId: conversationId,
        );
        _messages.add(errorMessage);
      }

    } catch (e) {
      _error = 'Failed to send message: $e';
      if (kDebugMode) {
        print('Error in sendMessage: $e');
      }
      
      final errorMessage = Message.assistant(
        'Sorry, I encountered an error while processing your message. Please try again.',
        conversationId: _currentConversation?.id,
      );
      _messages.add(errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
      
      if (kDebugMode) {
        print('Final message count: ${_messages.length}');
        print('Loading state: $_isLoading');
      }
    }
  }

  void setSelectedModel(String model) {
    if (_availableModels.contains(model)) {
      _selectedModel = model;
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages.clear();
    _currentConversation = null;
    _error = null;
    notifyListeners();
  }

  Future<void> createNewConversation(int userId) async {
    clearMessages();
    _currentConversation = null;
    notifyListeners();
  }

  Future<void> loadConversation(Conversation conversation, int userId) async {
    _currentConversation = conversation;
    _isLoadingConversation = true;
    _error = null;
    notifyListeners(); // Notify that we're starting to load
    
    if (kDebugMode) {
      print('Loading conversation: ${conversation.id} with ${conversation.messageCount} messages');
    }
    
    try {
      final messages = await _conversationService.getConversationDetails(userId, conversation.id!);
      
      if (kDebugMode) {
        print('Loaded ${messages.length} messages from conversation ${conversation.id}');
        for (int i = 0; i < messages.length; i++) {
          final msg = messages[i];
          print('Message $i: role=${msg.role}, type=${msg.messageType}, content="${msg.content.substring(0, msg.content.length.clamp(0, 50))}..."');
        }
      }
      
      // Clear messages and add new ones only after successful load
      _messages.clear();
      _messages.addAll(messages);
    } catch (e) {
      _error = 'Failed to load conversation: $e';
      if (kDebugMode) {
        print('Error loading conversation: $e');
      }
    } finally {
      _isLoadingConversation = false;
      notifyListeners(); // Notify that loading is complete
    }
  }

  Future<void> archiveConversation(int conversationId, int userId) async {
    try {
      await _conversationService.archiveConversation(conversationId, userId: userId);
      final index = _conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        _conversations[index] = _conversations[index].copyWith(
          conversationState: 'archived',
          isArchived: true,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to archive conversation: $e';
      if (kDebugMode) {
        print('Error archiving conversation: $e');
      }
      notifyListeners();
    }
  }

  Future<void> deleteConversation(int conversationId, int userId) async {
    try {
      await _conversationService.deleteConversation(userId, conversationId);
      _conversations.removeWhere((c) => c.id == conversationId);
      
      if (_currentConversation?.id == conversationId) {
        clearMessages();
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete conversation: $e';
      if (kDebugMode) {
        print('Error deleting conversation: $e');
      }
      notifyListeners();
    }
  }

  Future<void> updateConversationTitle(int conversationId, String newTitle, int userId) async {
    try {
      await _conversationService.updateConversationTitle(conversationId, newTitle, userId: userId);
      final index = _conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        _conversations[index] = _conversations[index].copyWith(
          title: newTitle,
          name: newTitle, // Update both title and name fields
        );
        
        if (_currentConversation?.id == conversationId) {
          _currentConversation = _currentConversation!.copyWith(
            title: newTitle,
            name: newTitle,
          );
        }
        
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update conversation title: $e';
      if (kDebugMode) {
        print('Error updating conversation title: $e');
      }
      notifyListeners();
    }
  }

  Future<void> continueConversation(int conversationId, int userId) async {
    try {
      await _conversationService.continueConversation(userId, conversationId);
      final index = _conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        _conversations[index] = _conversations[index].copyWith(
          conversationState: 'active',
          isArchived: false,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to continue conversation: $e';
      if (kDebugMode) {
        print('Error continuing conversation: $e');
      }
      notifyListeners();
    }
  }

  String _generateConversationTitle(String firstMessage) {
    if (firstMessage.length <= 30) {
      return firstMessage;
    }
    return '${firstMessage.substring(0, 30)}...';
  }

  Future<void> _updateConversationInList(Conversation conversation) async {
    final index = _conversations.indexWhere((c) => c.id == conversation.id);
    if (index != -1) {
      _conversations[index] = conversation.copyWith(updatedAt: DateTime.now());
    } else {
      _conversations.insert(0, conversation);
    }
    notifyListeners();
  }

  // Helper method to get conversations with filtering
  List<Conversation> getFilteredConversations({
    bool includeArchived = true,
    String? searchQuery,
  }) {
    var filtered = _conversations.where((conv) {
      if (!includeArchived && conv.isArchivedStatus) return false;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        return conv.title.toLowerCase().contains(query) ||
               conv.preview.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    // Sort by most recent activity
    filtered.sort((a, b) {
      final aTime = a.lastMessageAt ?? a.updatedAt;
      final bTime = b.lastMessageAt ?? b.updatedAt;
      return bTime.compareTo(aTime);
    });

    return filtered;
  }

  // Helper method to get conversation count by state
  Map<String, int> getConversationStats() {
    final stats = <String, int>{
      'total': _conversations.length,
      'active': 0,
      'archived': 0,
      'paused': 0,
    };

    for (final conv in _conversations) {
      if (conv.isArchivedStatus) {
        stats['archived'] = stats['archived']! + 1;
      } else if (conv.isPaused) {
        stats['paused'] = stats['paused']! + 1;
      } else if (conv.isActive) {
        stats['active'] = stats['active']! + 1;
      }
    }

    return stats;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Helper method to refresh conversations
  Future<void> refreshConversations(int userId) async {
    try {
      await loadUserConversations(userId);
    } catch (e) {
      _error = 'Failed to refresh conversations: $e';
      if (kDebugMode) {
        print('Error refreshing conversations: $e');
      }
      notifyListeners();
    }
  }

  // Method to reset chat state when switching users
  Future<void> resetForUser(int userId) async {
    // Clear current state
    _messages.clear();
    _currentConversation = null;
    _conversations.clear();
    _error = null;
    _isLoadingConversation = false;
    
    // Load new user's data if valid user ID
    if (userId > 0) {
      await loadUserConversations(userId);
    }
    notifyListeners();
  }
}
