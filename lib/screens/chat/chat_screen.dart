import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ticket_provider.dart';
import '../../services/supabase_service.dart';
import '../../config/colors.dart';
import '../../models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  final String ticketId;
  final String? ticketTitle;

  const ChatScreen({
    super.key,
    required this.ticketId,
    this.ticketTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  StreamSubscription? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      final messages = await SupabaseService.getChatMessages(widget.ticketId);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load messages: ${e.toString()}');
    }
  }

  void _subscribeToMessages() {
    _messagesSubscription?.cancel();
    _messagesSubscription = SupabaseService.subscribeToChatMessages(widget.ticketId)
        .listen((data) {
      final newMessages = data.map((json) => ChatMessage.fromJson(json)).toList();
      setState(() => _messages = newMessages);
      _scrollToBottom();
    }, onError: (error) {
      _showError('Real-time updates failed: ${error.toString()}');
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() => _isSending = true);

    try {
      await SupabaseService.sendMessage(
        ticketId: widget.ticketId,
        message: message,
      );

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      _showError('Failed to send message: ${e.toString()}');
    } finally {
      setState(() => _isSending = false);
    }
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.ticketTitle ?? 'Chat'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        actions: [
          Consumer<TicketProvider>(
            builder: (context, ticketProvider, child) {
              final ticket = ticketProvider.getTicketById(widget.ticketId);
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  switch (value) {
                    case 'resolve':
                      await ticketProvider.resolveTicket(
                        ticketId: widget.ticketId,
                        resolverId: SupabaseService.getCurrentUserId() ?? '',
                        resolution: 'Resolved via chat',
                      );
                      break;
                    case 'close':
                      await ticketProvider.closeTicket(ticketId: widget.ticketId);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (ticket?.status.toString() != 'resolved')
                    const PopupMenuItem(
                      value: 'resolve',
                      child: Row(
                        children: [
                          Icon(Icons.check, size: 16),
                          SizedBox(width: 8),
                          Text('Mark as Resolved'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'close',
                    child: Row(
                      children: [
                        Icon(Icons.close, size: 16),
                        SizedBox(width: 8),
                        Text('Close Ticket'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Start the conversation!',
                              style: TextStyle(
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _buildMessage(message);
                        },
                      ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textOnPrimary,
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: AppColors.textOnPrimary,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final currentUserId = SupabaseService.getCurrentUserId();
    final isOwn = message.senderId == currentUserId;
    final senderName = message.sender?.fullName ?? 'Unknown User';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Sender name and timestamp
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isOwn) ...[
                  Text(
                    senderName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  _formatTime(message.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
                if (isOwn) ...[
                  const SizedBox(width: 8),
                  Text(
                    'You',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Message bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isOwn ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: isOwn ? null : Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              message.message,
              style: TextStyle(
                color: isOwn ? AppColors.textOnPrimary : AppColors.textPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}