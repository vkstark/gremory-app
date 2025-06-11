import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:markdown_widget/markdown_widget.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../models/message.dart';
import '../theme/fallback_theme.dart';
import '../widgets/conversation_sidebar.dart';
import '../screens/user_management_screen.dart';
import '../utils/responsive_helper.dart';

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
  int? _currentUserId; // Track current user ID to detect changes
  bool _wasLoadingConversation = false; // Track previous loading state

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

      // Listen to chatProvider changes for animation trigger
      // Initialize _wasLoadingConversation with the initial state from provider
      _wasLoadingConversation = chatProvider.isLoadingConversation;
      chatProvider.addListener(_handleChatProviderChanges);
    });
  }

  @override
  void dispose() {
    // It's good practice to try-catch removeListener if provider might be disposed before screen
    try {
      context.read<ChatProvider>().removeListener(_handleChatProviderChanges);
    } catch (e) {
      // Handle or log error if necessary, e.g. if provider is already disposed
      if (kDebugMode) {
        print("Error removing listener from ChatProvider: $e");
      }
    }
    _animationController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleChatProviderChanges() {
    // Ensure the widget is still mounted before accessing context or setState
    if (!mounted) return;

    final chatProvider = context.read<ChatProvider>();
    // If conversation was loading and now it's not, and there are messages
    if (_wasLoadingConversation && !chatProvider.isLoadingConversation && chatProvider.messages.isNotEmpty) {
      if (mounted) { // Check mounted again before animation calls
        _animationController.reset();
        _animationController.forward();
        _scrollToBottom();
      }
    }
    // Update the tracked loading state
    _wasLoadingConversation = chatProvider.isLoadingConversation;
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
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Handle user switching
        final currentUserId = authProvider.currentUser?.id;
        if (_currentUserId != currentUserId && currentUserId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final chatProvider = context.read<ChatProvider>();
            chatProvider.resetForUser(currentUserId);
          });
          _currentUserId = currentUserId;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final shouldShowPersistentSidebar = ResponsiveHelper.shouldShowSidebarPersistent(context);
            
            return Scaffold(
              body: Row(
                children: [
                  // Persistent sidebar for desktop
                  if (shouldShowPersistentSidebar && _showSidebar) ...[
                    SizedBox(
                      width: ResponsiveHelper.getSidebarWidth(context),
                      child: ConversationSidebar(
                        userId: authProvider.currentUser?.id ?? -1,
                        onClose: () => setState(() => _showSidebar = false),
                      ),
                    ),
                    Container(width: 1, color: FallbackTheme.borderLight),
                  ],
                  // Main chat area
                  Expanded(
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            _buildAppBar(),
                            Expanded(child: _buildChatArea()),
                            _buildInputArea(),
                          ],
                        ),
                        // Overlay sidebar for mobile/tablet
                        if (!shouldShowPersistentSidebar && _showSidebar)
                          _buildOverlaySidebar(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAppBar() {
    return Consumer2<AuthProvider, ChatProvider>(
      builder: (context, authProvider, chatProvider, child) {
        final isMobile = ResponsiveHelper.isMobile(context);
        final screenWidth = MediaQuery.of(context).size.width;
        final showModelSelector = chatProvider.availableModels.isNotEmpty && screenWidth >= 516;
        
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12.0 : 16.0, // Reduced padding for desktop
            vertical: isMobile ? 8.0 : 12.0,
          ),
          decoration: const BoxDecoration(
            color: FallbackTheme.backgroundCard,
            border: Border(bottom: BorderSide(color: FallbackTheme.borderLight)),
          ),
          child: Row(
            children: [
              // Left section - Menu button and title
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => setState(() => _showSidebar = !_showSidebar),
                    icon: const Icon(Icons.menu, color: FallbackTheme.textPrimary),
                    tooltip: 'Conversations',
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.psychology, color: FallbackTheme.primaryPurple),
                    const SizedBox(width: 8),
                    Text(
                      'Gremory AI',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                        fontWeight: FontWeight.w600,
                        color: FallbackTheme.textPrimary,
                      ),
                    ),
                  ],
                ],
              ),
              
              // Spacer to push right section to the end
              const Spacer(),
              
              // Right section - Model selector, new chat, and user avatar
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showModelSelector) ...[
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
                      radius: isMobile ? 16 : 20,
                      backgroundColor: FallbackTheme.lightPurple,
                      child: Text(
                        authProvider.currentUser?.displayName.substring(0, 1).toUpperCase() ?? 'G',
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 14 : 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModelSelector(ChatProvider chatProvider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 700; // Make it more compact on smaller screens
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 4 : 6, 
        vertical: 4,
      ),
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
                  Icon(
                    _getModelIcon(model), 
                    size: isCompact ? 14 : 16, 
                    color: FallbackTheme.primaryPurple,
                  ),
                  SizedBox(width: isCompact ? 3 : 4),
                  Text(
                    _getModelDisplayName(model),
                    style: TextStyle(
                      fontSize: isCompact ? 13 : 14, 
                      color: FallbackTheme.textPrimary,
                    ),
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
          icon: Icon(
            Icons.keyboard_arrow_down, 
            size: isCompact ? 16 : 18,
          ),
          style: TextStyle(
            color: FallbackTheme.textPrimary, 
            fontSize: isCompact ? 13 : 14,
          ),
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

        // Show loading state when loading a conversation
        if (chatProvider.isLoadingConversation) {
          return _buildConversationLoadingState();
        }

        if (chatProvider.messages.isEmpty) {
          return _buildEmptyState(chatProvider);
        }

        return Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ListView.builder(
                    controller: _scrollController,
                    padding: ResponsiveHelper.getResponsivePaddingInsets(context),
                    itemCount: chatProvider.messages.length + (chatProvider.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < chatProvider.messages.length) {
                        return _buildMessageBubble(chatProvider.messages[index], index);
                      } else {
                        return _buildLoadingIndicator();
                      }
                    },
                  );
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
      child: SingleChildScrollView(
        padding: ResponsiveHelper.getResponsivePaddingInsets(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline, 
              size: ResponsiveHelper.isMobile(context) ? 48 : 64, 
              color: Colors.red[300],
            ),
            SizedBox(height: ResponsiveHelper.isMobile(context) ? 12 : 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18), 
                color: Colors.red[300], 
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveHelper.isMobile(context) ? 6 : 8),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.getResponsivePadding(context),
              ),
              child: Text(
                chatProvider.error!,
                style: TextStyle(
                  color: FallbackTheme.textSecondary,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: ResponsiveHelper.isMobile(context) ? 12 : 16),
            ElevatedButton(
              onPressed: () => chatProvider.clearError(),
              child: Text(
                'Try Again',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ChatProvider chatProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = ResponsiveHelper.isMobile(context);
        final padding = ResponsiveHelper.getResponsivePadding(context);
        
        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  decoration: BoxDecoration(
                    color: FallbackTheme.palePurple,
                    borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
                  ),
                  child: Icon(
                    Icons.psychology, 
                    size: isMobile ? 48 : 64, 
                    color: FallbackTheme.primaryPurple,
                  ),
                ),
                SizedBox(height: isMobile ? 16 : 24),
                Text(
                  'Welcome to Gremory AI',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 24),
                    fontWeight: FontWeight.w600,
                    color: FallbackTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isMobile ? 4 : 8),
                Text(
                  'Start a conversation by typing a message below',
                  style: TextStyle(
                    color: FallbackTheme.textSecondary, 
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isMobile ? 24 : 32),
                _buildSuggestionGrid(isMobile),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionGrid(bool isMobile) {
    final suggestions = [
      ('Help me write a story', Icons.auto_stories),
      ('Explain quantum physics', Icons.school),
      ('Plan a trip to Japan', Icons.flight),
      ('Write Python code', Icons.code),
    ];

    if (isMobile) {
      return Column(
        children: suggestions.map((suggestion) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildSuggestionCard(suggestion.$1, suggestion.$2),
          ),
        ).toList(),
      );
    } else {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: suggestions.map((suggestion) => 
          _buildSuggestionCard(suggestion.$1, suggestion.$2),
        ).toList(),
      );
    }
  }

  Widget _buildSuggestionCard(String text, IconData icon) {
    return Consumer2<AuthProvider, ChatProvider>(
      builder: (context, authProvider, chatProvider, child) {
        final isMobile = ResponsiveHelper.isMobile(context);
        
        return InkWell(
          onTap: () => _sendMessage(text, authProvider, chatProvider),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: isMobile ? double.infinity : null,
            constraints: isMobile ? null : const BoxConstraints(minWidth: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 16, 
              vertical: isMobile ? 16 : 12,
            ),
            decoration: BoxDecoration(
              color: FallbackTheme.backgroundCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FallbackTheme.borderLight),
            ),
            child: Row(
              mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: isMobile ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(
                  icon, 
                  size: isMobile ? 20 : 18, 
                  color: FallbackTheme.primaryPurple,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    text, 
                    style: TextStyle(
                      color: FallbackTheme.textPrimary,
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConversationLoadingState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = ResponsiveHelper.isMobile(context);
        final padding = ResponsiveHelper.getResponsivePadding(context);
        
        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SpinKitThreeBounce(
                  color: FallbackTheme.primaryPurple,
                  size: isMobile ? 30 : 40,
                ),
                SizedBox(height: isMobile ? 16 : 24),
                Text(
                  'Loading conversation...',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                    color: FallbackTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
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
                maxWidth: ResponsiveHelper.getMessageMaxWidth(context),
              ),
              margin: ResponsiveHelper.getResponsiveMargin(context).copyWith(
                left: isUser ? ResponsiveHelper.getResponsivePadding(context) * 2 : 0,
                right: isUser ? 0 : ResponsiveHelper.getResponsivePadding(context) * 2,
              ),
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.getResponsivePadding(context),
                      vertical: ResponsiveHelper.getResponsivePadding(context) * 0.75,
                    ),
                    decoration: BoxDecoration(
                      gradient: isUser
                          ? const LinearGradient(
                              colors: [FallbackTheme.primaryPurple, Color(0xFF8B5CF6)],
                            )
                          : null,
                      color: isUser ? null : FallbackTheme.backgroundCard,
                      borderRadius: BorderRadius.circular(ResponsiveHelper.isMobile(context) ? 12 : 16),
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
                        ? SelectableText(
                            message.content,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                              height: 1.4,
                            ),
                          )
                        : MarkdownWidget(
                            data: message.content,
                            selectable: true,
                            shrinkWrap: true,
                            config: MarkdownConfig(
                              configs: [
                                CodeConfig(
                                  style: TextStyle(
                                    backgroundColor: FallbackTheme.surfacePurple,
                                    color: FallbackTheme.primaryPurple,
                                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                PreConfig(
                                  decoration: BoxDecoration(
                                    color: FallbackTheme.surfacePurple,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: FallbackTheme.borderLight),
                                  ),
                                  wrapper: (child, code, language) => _buildCodeBlock(child, code, language),
                                ),
                                PConfig(
                                  textStyle: TextStyle(
                                    color: FallbackTheme.textPrimary,
                                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 15),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  if (message.createdAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatTime(message.createdAt!),
                        style: TextStyle(
                          color: FallbackTheme.textLight,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
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
        margin: ResponsiveHelper.getResponsiveMargin(context).copyWith(
          right: ResponsiveHelper.getResponsivePadding(context) * 2,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getResponsivePadding(context),
          vertical: ResponsiveHelper.getResponsivePadding(context) * 0.75,
        ),
        decoration: BoxDecoration(
          color: FallbackTheme.backgroundCard,
          borderRadius: BorderRadius.circular(ResponsiveHelper.isMobile(context) ? 12 : 16),
          border: Border.all(color: FallbackTheme.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpinKitThreeBounce(
              color: FallbackTheme.primaryPurple,
              size: ResponsiveHelper.isMobile(context) ? 16 : 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Thinking...',
              style: TextStyle(
                color: FallbackTheme.textSecondary,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
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
        final isMobile = ResponsiveHelper.isMobile(context);
        
        return Container(
          padding: ResponsiveHelper.getResponsivePaddingInsets(context),
          decoration: const BoxDecoration(
            color: FallbackTheme.backgroundCard,
            border: Border(top: BorderSide(color: FallbackTheme.borderLight)),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (isMobile && constraints.maxWidth < 500) {
                  // Stack layout for very small screens
                  return Column(
                    children: [
                      if (chatProvider.availableModels.isNotEmpty) ...[
                        _buildModelSelector(chatProvider),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(chatProvider, authProvider),
                          ),
                          const SizedBox(width: 8),
                          _buildSendButton(chatProvider, authProvider),
                        ],
                      ),
                    ],
                  );
                } else {
                  // Row layout for larger screens
                  return Row(
                    children: [
                      Expanded(
                        child: _buildTextField(chatProvider, authProvider),
                      ),
                      const SizedBox(width: 12),
                      _buildSendButton(chatProvider, authProvider),
                    ],
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(ChatProvider chatProvider, AuthProvider authProvider) {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return TextField(
      controller: _textController,
      maxLines: isMobile ? 3 : 5,
      minLines: 1,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.send,
      onSubmitted: (text) {
        if (text.trim().isNotEmpty && !chatProvider.isLoading) {
          _sendMessage(text.trim(), authProvider, chatProvider);
        }
      },
      style: TextStyle(
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
      ),
      decoration: InputDecoration(
        hintText: isMobile 
          ? 'Type your message...' 
          : 'Type your message... (Enter to send, Shift+Enter for new line)',
        hintStyle: TextStyle(
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
        ),
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveHelper.getResponsivePadding(context),
          vertical: ResponsiveHelper.getResponsivePadding(context) * 0.75,
        ),
      ),
      enabled: !chatProvider.isLoading,
    );
  }

  Widget _buildSendButton(ChatProvider chatProvider, AuthProvider authProvider) {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return SizedBox(
      width: isMobile ? 48 : 56,
      height: isMobile ? 48 : 56,
      child: FloatingActionButton(
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
            ? SizedBox(
                width: isMobile ? 16 : 20,
                height: isMobile ? 16 : 20,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(
                Icons.send, 
                color: Colors.white,
                size: isMobile ? 20 : 24,
              ),
      ),
    );
  }

  void _sendMessage(String text, AuthProvider authProvider, ChatProvider chatProvider) {
    _textController.clear();
    final userId = authProvider.currentUser?.id ?? -1;
    chatProvider.sendMessage(chatProvider.selectedModel, text, userId);
    _animationController.forward();
    _scrollToBottom();
  }

  Widget _buildCodeBlock(Widget child, String code, String? language) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: FallbackTheme.surfacePurple,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: FallbackTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with copy button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: FallbackTheme.backgroundCard,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(bottom: BorderSide(color: FallbackTheme.borderLight)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language ?? 'code',
                  style: const TextStyle(
                    fontSize: 12,
                    color: FallbackTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                InkWell(
                  onTap: () => _copyToClipboard(context, code),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: FallbackTheme.primaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: FallbackTheme.primaryPurple.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.copy,
                          size: 14,
                          color: FallbackTheme.primaryPurple,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: TextStyle(
                            fontSize: 12,
                            color: FallbackTheme.primaryPurple,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Code content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Code copied to clipboard'),
        duration: const Duration(seconds: 2),
        backgroundColor: FallbackTheme.primaryPurple,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
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

  Widget _buildOverlaySidebar() {
    return Positioned.fill(
      child: Row(
        children: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return Container(
                width: ResponsiveHelper.getSidebarWidth(context),
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(2, 0),
                    ),
                  ],
                ),
                child: ConversationSidebar(
                  userId: authProvider.currentUser?.id ?? -1,
                  onClose: () => setState(() => _showSidebar = false),
                ),
              );
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showSidebar = false),
              child: Container(
                color: Colors.black26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}