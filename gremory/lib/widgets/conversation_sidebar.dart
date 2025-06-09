import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/conversation.dart';
import '../theme/fallback_theme.dart';

class ConversationSidebar extends StatefulWidget {
  final int userId;
  final VoidCallback onClose;

  const ConversationSidebar({
    super.key,
    required this.userId,
    required this.onClose,
  });

  @override
  State<ConversationSidebar> createState() => _ConversationSidebarState();
}

class _ConversationSidebarState extends State<ConversationSidebar> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void didUpdateWidget(ConversationSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if user changed and reload conversations
    if (oldWidget.userId != widget.userId) {
      _loadConversations();
    }
  }

  Future<void> _loadConversations() async {
    if (mounted && widget.userId > 0) {
      setState(() => _isLoading = true);
    }
    final chatProvider = context.read<ChatProvider>();
    await chatProvider.refreshConversations(widget.userId);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: FallbackTheme.backgroundCard,
        border: Border(right: BorderSide(color: FallbackTheme.borderLight)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildConversationList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: FallbackTheme.borderLight)),
      ),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble_outline, color: FallbackTheme.primaryPurple),
          const SizedBox(width: 12),
          const Text(
            'Conversations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: FallbackTheme.textPrimary,
            ),
          ),
          const Spacer(),
          // Add refresh button
          IconButton(
            onPressed: _isLoading ? null : _loadConversations,
            icon: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: FallbackTheme.primaryPurple,
                    ),
                  )
                : const Icon(Icons.refresh, color: FallbackTheme.textSecondary),
            tooltip: 'Refresh conversations',
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close, color: FallbackTheme.textSecondary),
            tooltip: 'Close sidebar',
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList() {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (_isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: FallbackTheme.primaryPurple,
            ),
          );
        }

        if (chatProvider.conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: FallbackTheme.textLight,
                ),
                const SizedBox(height: 16),
                Text(
                  'No conversations yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: FallbackTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start chatting to see your conversations here',
                  style: TextStyle(
                    fontSize: 14,
                    color: FallbackTheme.textLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: FallbackTheme.primaryPurple,
          onRefresh: _loadConversations,
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: chatProvider.conversations.length,
            itemBuilder: (context, index) {
              final conversation = chatProvider.conversations[index];
              return _buildConversationTile(conversation, chatProvider);
            },
          ),
        );
      },
    );
  }

  Widget _buildConversationTile(Conversation conversation, ChatProvider chatProvider) {
    final isSelected = chatProvider.currentConversation?.id == conversation.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected ? FallbackTheme.palePurple : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () async {
            // Updated to pass both conversation and userId
            await chatProvider.loadConversation(conversation, widget.userId);
            widget.onClose();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: FallbackTheme.borderFocus, width: 1)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        conversation.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? FallbackTheme.primaryPurple : FallbackTheme.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        size: 16,
                        color: FallbackTheme.textLight,
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Rename'),
                            ],
                          ),
                        ),
                        if (!conversation.isArchivedStatus)
                          const PopupMenuItem(
                            value: 'archive',
                            child: Row(
                              children: [
                                Icon(Icons.archive, size: 16),
                                SizedBox(width: 8),
                                Text('Archive'),
                              ],
                            ),
                          ),
                        if (conversation.isArchivedStatus)
                          const PopupMenuItem(
                            value: 'unarchive',
                            child: Row(
                              children: [
                                Icon(Icons.unarchive, size: 16),
                                SizedBox(width: 8),
                                Text('Unarchive'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        _handleConversationAction(value, conversation, chatProvider);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: FallbackTheme.textLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      conversation.displayTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: FallbackTheme.textLight,
                      ),
                    ),
                    const Spacer(),
                    if (conversation.isArchivedStatus) ...[
                      Icon(
                        Icons.archive,
                        size: 12,
                        color: FallbackTheme.textLight,
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (conversation.messageCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: FallbackTheme.surfacePurple,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${conversation.messageCount}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: FallbackTheme.primaryPurple,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                if (conversation.preview.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    conversation.preview,
                    style: TextStyle(
                      fontSize: 12,
                      color: FallbackTheme.textSecondary,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleConversationAction(String action, Conversation conversation, ChatProvider chatProvider) {
    switch (action) {
      case 'rename':
        _showRenameDialog(conversation, chatProvider);
        break;
      case 'archive':
        chatProvider.archiveConversation(conversation.id!, widget.userId);
        break;
      case 'unarchive':
        chatProvider.continueConversation(conversation.id!, widget.userId);
        break;
      case 'delete':
        _showDeleteConfirmation(conversation, chatProvider);
        break;
    }
  }

  void _showRenameDialog(Conversation conversation, ChatProvider chatProvider) {
    final controller = TextEditingController(text: conversation.title);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Conversation'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New title',
            border: OutlineInputBorder(),
          ),
          maxLength: 50,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty && newTitle != conversation.title) {
                chatProvider.updateConversationTitle(
                  conversation.id!,
                  newTitle,
                  widget.userId,
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Conversation conversation, ChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text(
          'Are you sure you want to delete "${conversation.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              chatProvider.deleteConversation(conversation.id!, widget.userId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
