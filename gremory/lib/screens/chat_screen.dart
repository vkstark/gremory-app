import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _textFieldFocus = FocusNode();

  String _selectedModel = 'ollama_qwen';
  bool _isLoading = false;

  // Purple color scheme
  static const Color primaryPurple = Color(0xFF6B46C1);
  static const Color lightPurple = Color(0xFF8B5CF6);
  static const Color palePurple = Color(0xFFF3F4F6);
  static const Color deepPurple = Color(0xFF553C9A);

  final List<DropdownMenuItem<String>> _modelOptions = const [
    DropdownMenuItem(
      value: 'ollama_qwen',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.psychology, size: 16, color: primaryPurple),
          SizedBox(width: 8),
          Text('Qwen'),
        ],
      ),
    ),
    DropdownMenuItem(
      value: 'gemini_2o_flash',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flash_on, size: 16, color: primaryPurple),
          SizedBox(width: 8),
          Text('Gemini 2.0 Flash'),
        ],
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.addListener(_onMessagesChanged);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _textFieldFocus.dispose();
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.removeListener(_onMessagesChanged);
    super.dispose();
  }

  void _onMessagesChanged() {
    if (_scrollController.hasClients && _scrollController.position.hasContentDimensions) {
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
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.red.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.red.shade200, width: 1),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text(
                'Error',
                style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Text(
            error,
            style: TextStyle(color: Colors.red.shade800),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showNewChatConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.chat_bubble_outline, color: primaryPurple),
              SizedBox(width: 8),
              Text('New Chat', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          content: const Text('Are you sure you want to start a new chat? This will clear the current conversation.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startNewChat();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('New Chat'),
            ),
          ],
        );
      },
    );
  }

  void _startNewChat() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.clearMessages();
    _controller.clear();
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Started new chat', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    _controller.clear();

    try {
      await chatProvider.sendMessage(_selectedModel, text);
    } catch (error) {
      _showErrorDialog('Failed to send message: ${error.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Updated keyboard event handler using Focus widget approach
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // Only handle key down events to avoid duplicate triggers
    if (event is KeyDownEvent) {
      final isShiftPressed = HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shift) ||
                             HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
                             HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.shiftRight);
      
      final isEnterPressed = event.logicalKey == LogicalKeyboardKey.enter ||
                            event.logicalKey == LogicalKeyboardKey.numpadEnter;
      
      if (isEnterPressed) {
        if (isShiftPressed) {
          // Shift+Enter: Allow new line (return KeyEventResult.ignored to let TextField handle it)
          return KeyEventResult.ignored;
        } else {
          // Enter without Shift: Send message
          if (_controller.text.trim().isNotEmpty && !_isLoading) {
            _sendMessage();
          }
          return KeyEventResult.handled;
        }
      }
    }
    
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          "AI Chat",
          style: TextStyle(
            color: primaryPurple,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          // Model selection dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: primaryPurple.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: DropdownButton<String>(
                value: _selectedModel,
                underline: const SizedBox(),
                items: _modelOptions,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedModel = value);
                  }
                },
                dropdownColor: Colors.white,
              ),
            ),
          ),
          // New chat button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: chatProvider.messages.isNotEmpty ? _showNewChatConfirmation : null,
              icon: const Icon(Icons.add_comment_outlined),
              tooltip: 'New Chat',
              style: IconButton.styleFrom(
                foregroundColor: primaryPurple,
                backgroundColor: primaryPurple.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          // Menu with additional options
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'new_chat':
                  _showNewChatConfirmation();
                  break;
                case 'clear_history':
                  _showNewChatConfirmation();
                  break;
              }
            },
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new_chat',
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: primaryPurple),
                    SizedBox(width: 8),
                    Text('New Chat'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_history',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: primaryPurple),
                    SizedBox(width: 8),
                    Text('Clear History'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: chatProvider.messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatProvider.messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isLoading && index == chatProvider.messages.length) {
                        return _buildLoadingMessage();
                      }

                      final Message msg = chatProvider.messages[index];
                      return _buildMessageBubble(msg);
                    },
                  ),
          ),
          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: primaryPurple,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Start a conversation",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: primaryPurple,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Ask me anything and I'll help you out!",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: primaryPurple.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(primaryPurple),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Thinking...",
                style: TextStyle(
                  color: primaryPurple,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message msg) {
    final isUser = msg.role == "user";
    final time = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            gradient: isUser
                ? const LinearGradient(
                    colors: [primaryPurple, lightPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isUser ? null : Colors.white,
            borderRadius: BorderRadius.circular(18).copyWith(
              bottomRight: isUser ? const Radius.circular(6) : const Radius.circular(18),
              bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(6),
            ),
            boxShadow: [
              BoxShadow(
                color: isUser 
                    ? primaryPurple.withOpacity(0.3)
                    : Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                msg.content,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
                style: TextStyle(
                  color: isUser ? Colors.white.withOpacity(0.8) : Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F7FF),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: primaryPurple.withValues(alpha: 0.2)),
                ),
                child: Focus(
                  onKeyEvent: _handleKeyEvent,
                  child: TextField(
                    controller: _controller,
                    focusNode: _textFieldFocus,
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.newline,
                    maxLines: null,
                    minLines: 1,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(fontSize: 16),
                    onChanged: (value) {
                      setState(() {}); // Rebuild to update send button state
                    },
                    decoration: const InputDecoration(
                      hintText: "Type your message... (Shift+Enter for new line)",
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: _controller.text.trim().isNotEmpty && !_isLoading
                    ? const LinearGradient(
                        colors: [primaryPurple, lightPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: _controller.text.trim().isEmpty || _isLoading
                    ? Colors.grey.shade300
                    : null,
                shape: BoxShape.circle,
                boxShadow: _controller.text.trim().isNotEmpty && !_isLoading
                    ? [
                        BoxShadow(
                          color: primaryPurple.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _controller.text.trim().isNotEmpty && !_isLoading
                      ? _sendMessage
                      : null,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: _controller.text.trim().isNotEmpty && !_isLoading
                          ? const LinearGradient(
                              colors: [primaryPurple, lightPurple],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: _controller.text.trim().isEmpty || _isLoading
                          ? Colors.grey.shade300
                          : null,
                      shape: BoxShape.circle,
                      boxShadow: _controller.text.trim().isNotEmpty && !_isLoading
                          ? [
                              BoxShadow(
                                color: primaryPurple.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}