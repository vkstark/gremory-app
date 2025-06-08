import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../models/message.dart';
import '../theme/fallback_theme.dart';
import '../widgets/conversation_sidebar.dart';
import '../screens/user_management_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showSidebar = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final chatProvider = context.read<ChatProvider>();
      
      authProvider.initialize();
      chatProvider.initialize(userId: authProvider.currentUser?.id);
      
      // Listen for auth changes and refresh chat data
      authProvider.addListener(() {
        if (mounted) {
          final userId = authProvider.currentUser?.id;
          if (userId != null) {
            chatProvider.initialize(userId: userId);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              if (_showSidebar) ...[
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return ConversationSidebar(
                      userId: authProvider.currentUser?.id ?? -1,
                      onClose: () => setState(() => _showSidebar = false),
                    );
                  },
                ),
                Container(width: 1, color: FallbackTheme.borderLight),
              ],
              Expanded(
                child: Column(
                  children: [
                    _buildAppBar(),
                    Expanded(child: _buildChatArea()),
                    _buildInputArea(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Consumer2<AuthProvider, ChatProvider>(
      builder: (context, authProvider, chatProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: FallbackTheme.backgroundCard,
            border: Border(bottom: BorderSide(color: FallbackTheme.borderLight)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _showSidebar = !_showSidebar),
                icon: const Icon(Icons.menu, color: FallbackTheme.textPrimary),
                tooltip: 'Conversations',
              ),
              const SizedBox(width: 12),
              const Icon(Icons.psychology, color: FallbackTheme.primaryPurple),
              const SizedBox(width: 8),
              const Text(
                'Gremory AI',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: FallbackTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (chatProvider.availableModels.isNotEmpty) ...[
                _buildModelSelector(chatProvider),
                const SizedBox(width: 12),
              ],
              IconButton(
                onPressed: () => chatProvider.createNewConversation(authProvider.currentUser?.id ?? -1),
                icon: const Icon(Icons.add_circle_outline, color: FallbackTheme.primaryPurple),
                tooltip: 'New Chat',
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserManagementScreen()),
                ),
                child: CircleAvatar(
                  backgroundColor: FallbackTheme.lightPurple,
                  child: Text(
                    authProvider.currentUser?.displayName.substring(0, 1).toUpperCase() ?? 'G',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModelSelector(ChatProvider chatProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: FallbackTheme.surfacePurple,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FallbackTheme.borderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: chatProvider.selectedModel,
          items: chatProvider.availableModels.map((model) {
            return DropdownMenuItem<String>(
              value: model,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getModelIcon(model), size: 16, color: FallbackTheme.primaryPurple),
                  const SizedBox(width: 8),
                  Text(
                    _getModelDisplayName(model),
                    style: const TextStyle(fontSize: 14, color: FallbackTheme.textPrimary),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              chatProvider.setSelectedModel(value);
            }
          },
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: const TextStyle(color: FallbackTheme.textPrimary, fontSize: 14),
        ),
      ),
    );
  }

  IconData _getModelIcon(String model) {
    switch (model.toLowerCase()) {
      case 'gemini_2o_flash':
        return Icons.auto_awesome;
      case 'ollama_qwen':
      case 'ollama_llama':
        return Icons.psychology;
      case 'openai_gpt4':
        return Icons.smart_toy;
      default:
        return Icons.memory;
    }
  }

  String _getModelDisplayName(String model) {
    switch (model) {
      case 'gemini_2o_flash':
        return 'Gemini 2.0 Flash';
      case 'ollama_qwen':
        return 'Ollama Qwen';
      case 'ollama_llama':
        return 'Ollama Llama';
      case 'openai_gpt4':
        return 'GPT-4';
      default:
        return model.replaceAll('_', ' ').split(' ').map((word) => 
          word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase()
        ).join(' ');
    }
  }

  Widget _buildChatArea() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (chatProvider.error != null) {
          return _buildErrorState(chatProvider);
        }

        if (chatProvider.messages.isEmpty) {
          return _buildEmptyState(chatProvider);
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: chatProvider.messages.length + (chatProvider.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < chatProvider.messages.length) {
                    return _buildMessageBubble(chatProvider.messages[index], index);
                  } else {
                    return _buildLoadingIndicator();
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorState(ChatProvider chatProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(fontSize: 18, color: Colors.red[300], fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            chatProvider.error!,
            style: const TextStyle(color: FallbackTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => chatProvider.clearError(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ChatProvider chatProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: FallbackTheme.palePurple,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.psychology, size: 64, color: FallbackTheme.primaryPurple),
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome to Gremory AI',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: FallbackTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start a conversation by typing a message below',
            style: TextStyle(color: FallbackTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildSuggestionCard('Help me write a story', Icons.auto_stories),
              _buildSuggestionCard('Explain quantum physics', Icons.school),
              _buildSuggestionCard('Plan a trip to Japan', Icons.flight),
              _buildSuggestionCard('Write Python code', Icons.code),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(String text, IconData icon) {
    return Consumer2<AuthProvider, ChatProvider>(
      builder: (context, authProvider, chatProvider, child) {
        return InkWell(
          onTap: () => _sendMessage(text, authProvider, chatProvider),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: FallbackTheme.backgroundCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FallbackTheme.borderLight),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: FallbackTheme.primaryPurple),
                const SizedBox(width: 8),
                Text(text, style: const TextStyle(color: FallbackTheme.textPrimary)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(Message message, int index) {
    final isUser = message.isUser;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              margin: EdgeInsets.only(
                bottom: 12,
                left: isUser ? 48 : 0,
                right: isUser ? 0 : 48,
              ),
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isUser
                          ? const LinearGradient(
                              colors: [FallbackTheme.primaryPurple, Color(0xFF8B5CF6)],
                            )
                          : null,
                      color: isUser ? null : FallbackTheme.backgroundCard,
                      borderRadius: BorderRadius.circular(16),
                      border: isUser ? null : Border.all(color: FallbackTheme.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isUser
                        ? Text(
                            message.content,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          )
                        : MarkdownBody(
                            data: message.content,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(
                                color: FallbackTheme.textPrimary,
                                fontSize: 15,
                                height: 1.4,
                              ),
                              code: TextStyle(
                                backgroundColor: FallbackTheme.surfacePurple,
                                color: FallbackTheme.primaryPurple,
                                fontSize: 14,
                                fontFamily: 'monospace',
                              ),
                              codeblockDecoration: BoxDecoration(
                                color: FallbackTheme.surfacePurple,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                  ),
                  if (message.createdAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatTime(message.createdAt!),
                        style: const TextStyle(
                          color: FallbackTheme.textLight,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: FallbackTheme.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FallbackTheme.borderLight),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpinKitThreeBounce(
              color: FallbackTheme.primaryPurple,
              size: 20,
            ),
            SizedBox(width: 12),
            Text(
              'Thinking...',
              style: TextStyle(
                color: FallbackTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Consumer2<AuthProvider, ChatProvider>(
      builder: (context, authProvider, chatProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: FallbackTheme.backgroundCard,
            border: Border(top: BorderSide(color: FallbackTheme.borderLight)),
          ),          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (text) {
                    if (text.trim().isNotEmpty && !chatProvider.isLoading) {
                      _sendMessage(text.trim(), authProvider, chatProvider);
                    }
                  },
                  decoration: const InputDecoration(
                    hintText: 'Type your message... (Enter to send, Shift+Enter for new line)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  enabled: !chatProvider.isLoading,
                ),
              ),
              const SizedBox(width: 12),
              FloatingActionButton(
                onPressed: chatProvider.isLoading
                    ? null
                    : () {
                        final text = _textController.text.trim();
                        if (text.isNotEmpty) {
                          _sendMessage(text, authProvider, chatProvider);
                        }
                      },
                backgroundColor: chatProvider.isLoading
                    ? FallbackTheme.textLight
                    : FallbackTheme.primaryPurple,
                child: chatProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendMessage(String text, AuthProvider authProvider, ChatProvider chatProvider) {
    _textController.clear();
    final userId = authProvider.currentUser?.id ?? -1;
    chatProvider.sendMessage(chatProvider.selectedModel, text, userId);
    _animationController.forward();
    _scrollToBottom();
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}