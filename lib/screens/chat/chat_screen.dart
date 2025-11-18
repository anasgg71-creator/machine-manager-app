import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/ticket_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/supabase_service.dart';
import '../../services/file_upload_service.dart';
import '../../services/translation_service.dart';
import '../../config/colors.dart';
import '../../models/chat_message.dart';
import '../../models/user_profile.dart';
import '../../models/ticket_attachment.dart';

class ChatScreen extends StatefulWidget {
  final String ticketId;
  final String? ticketTitle;
  final VoidCallback? onBack;

  const ChatScreen({
    super.key,
    required this.ticketId,
    this.ticketTitle,
    this.onBack,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messageFocusNode = FocusNode();

  List<ChatMessage> _messages = [];
  List<TicketAttachment> _attachments = [];
  bool _isLoading = false;
  bool _isLoadingAttachments = false;
  bool _isSending = false;
  bool _showAttachments = false; // Hide attachments by default
  StreamSubscription? _messagesSubscription;
  RealtimeChannel? _presenceChannel;
  int _viewerCount = 0;
  Map<String, UserProfile> _viewers = {};
  String _chatTranslationLanguage = 'en'; // Language for translating received messages

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMessages();
    _loadAttachments();
    _subscribeToMessages();
    _setupPresence();

    // Add listener to scroll when focus changes
    _messageFocusNode.addListener(() {
      if (_messageFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollToBottom();
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _messagesSubscription?.cancel();
    _presenceChannel?.unsubscribe();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Called when keyboard opens/closes
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    if (bottomInset > 0) {
      // Keyboard is visible, scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
    }
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

  Future<void> _loadAttachments() async {
    setState(() => _isLoadingAttachments = true);

    try {
      final attachments = await FileUploadService.getTicketAttachments(widget.ticketId);
      setState(() {
        _attachments = attachments;
        _isLoadingAttachments = false;
      });
    } catch (e) {
      setState(() => _isLoadingAttachments = false);
      print('Failed to load attachments: ${e.toString()}');
    }
  }

  void _subscribeToMessages() {
    _messagesSubscription?.cancel();
    print('🔔 REALTIME: Setting up message subscription for ticket ${widget.ticketId}');
    _messagesSubscription = SupabaseService.subscribeToChatMessages(widget.ticketId)
        .listen((data) async {
      print('🔔 REALTIME: Stream event received! Data length: ${data.length}');
      // The stream only returns basic message data, so we need to fetch full messages
      // including sender profile information
      try {
        print('🔔 REALTIME: Fetching complete messages...');
        final messages = await SupabaseService.getChatMessages(widget.ticketId);
        print('🔔 REALTIME: Got ${messages.length} messages, updating UI');
        setState(() => _messages = messages);
        _scrollToBottom();
      } catch (e) {
        print('❌ REALTIME: Error refreshing messages: $e');
      }
    }, onError: (error) {
      print('❌ REALTIME: Stream error: ${error.toString()}');
      _showError('Real-time updates failed: ${error.toString()}');
    });
    print('🔔 REALTIME: Subscription setup complete');
  }

  void _setupPresence() async {
    final channelName = 'ticket:${widget.ticketId}';
    final currentUserId = SupabaseService.getCurrentUserId();

    if (currentUserId == null) return;

    try {
      // Get current user profile first
      final currentUserProfile = await SupabaseService.getUserProfile(currentUserId);

      _presenceChannel = SupabaseService.client.channel(channelName);

      _presenceChannel!
          .onPresenceSync((_) {
            _updateViewers();
          })
          .onPresenceJoin((payload) {
            _updateViewers();
          })
          .onPresenceLeave((payload) {
            _updateViewers();
          })
          .subscribe((status, error) async {
            if (status == RealtimeSubscribeStatus.subscribed) {
              // Send user profile data with presence
              await _presenceChannel!.track({
                'user_id': currentUserId,
                'full_name': currentUserProfile.fullName ?? currentUserProfile.email,
              });
            }
          });
    } catch (e) {
      print('Error setting up presence: $e');
    }
  }

  void _updateViewers() async {
    try {
      final state = _presenceChannel!.presenceState();
      print('=== DEBUG: Presence State ===');
      print('State length: ${state.length}');
      print('State type: ${state.runtimeType}');

      final viewers = <String, UserProfile>{};

      // Extract user info from presence state
      for (var i = 0; i < state.length; i++) {
        final presenceItem = state[i];
        print('--- Presence Item $i ---');
        print('Item type: ${presenceItem.runtimeType}');

        // Access the presences property using dynamic
        try {
          // Try to access presences property
          final presences = (presenceItem as dynamic).presences as List?;
          print('Presences list length: ${presences?.length}');

          if (presences != null && presences.isNotEmpty) {
            final presence = presences.first;
            print('Presence data type: ${presence.runtimeType}');
            print('Presence data: $presence');

            // Access the payload property from the Presence object
            final payload = (presence as dynamic).payload as Map<String, dynamic>?;
            print('Payload: $payload');

            final userId = payload?['user_id'] as String?;
            final fullName = payload?['full_name'] as String?;

            print('Extracted userId: $userId');
            print('Extracted fullName: $fullName');

            if (userId != null) {
              viewers[userId] = UserProfile(
                id: userId,
                email: '',
                fullName: fullName,
                role: 'member',
                avatarUrl: null,
                points: 0,
                ticketsSolved: 0,
                totalRatings: 0,
                averageRating: 0.0,
                isOnline: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              print('✓ Added viewer: $fullName ($userId)');
            }
          }
        } catch (e) {
          print('Error parsing presence item: $e');
          print('Stack trace: ${StackTrace.current}');
        }
      }

      print('Total viewers map size: ${viewers.length}');
      print('Viewer names: ${viewers.values.map((v) => v.fullName).join(", ")}');
      print('=== END DEBUG ===\n');

      setState(() {
        _viewerCount = state.length;
        _viewers = viewers;
      });
    } catch (e) {
      print('Error updating viewers: $e');
      print('Stack trace: ${StackTrace.current}');
      setState(() {
        _viewerCount = 0;
        _viewers = {};
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      print('💬 CHAT: Message is empty, not sending');
      return;
    }

    // Get current language from provider
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final selectedLanguageCode = languageProvider.selectedLanguageCode;

    print('💬 CHAT: Starting to send message...');
    print('💬 CHAT: Ticket ID: ${widget.ticketId}');
    print('💬 CHAT: Original message: $message');
    print('💬 CHAT: Selected language: $selectedLanguageCode');
    print('💬 CHAT: Current user: ${SupabaseService.getCurrentUserId()}');

    setState(() => _isSending = true);

    try {
      print('💬 CHAT: Sending message in original language: $selectedLanguageCode');

      print('💬 CHAT: Calling SupabaseService.sendMessage...');
      final sentMessage = await SupabaseService.sendMessage(
        ticketId: widget.ticketId,
        message: message, // Send original message (no translation)
        sourceLanguage: selectedLanguageCode,
      );
      print('✅ CHAT: Message sent successfully: ${sentMessage.id}');

      // Immediately add the message to the local list for instant display
      setState(() {
        _messages.add(sentMessage);
      });

      _messageController.clear();
      _scrollToBottom();
      print('✅ CHAT: Message added to list, cleared input, and scrolled to bottom');
    } catch (e, stackTrace) {
      print('❌ CHAT: Error sending message: $e');
      print('❌ CHAT: Stack trace: $stackTrace');
      _showError('Failed to send message: ${e.toString()}');
    } finally {
      setState(() => _isSending = false);
      print('💬 CHAT: Send operation completed, _isSending = false');
    }
  }

  Future<void> _capturePhoto() async {
    setState(() => _isSending = true);

    try {
      final attachment = await FileUploadService.capturePhoto(
        ticketId: widget.ticketId,
        onProgress: (progress) {
          // Progress tracking (optional: could show a progress indicator)
          print('Upload progress: ${(progress * 100).toStringAsFixed(0)}%');
        },
      );

      if (attachment != null) {
        // Send a message about the photo attachment
        await SupabaseService.sendMessage(
          ticketId: widget.ticketId,
          message: '📷 Photo attached: ${attachment.fileName}',
          sourceLanguage: 'en', // System message in English
        );

        _showSuccess('Photo uploaded successfully');
        _loadAttachments(); // Reload attachments list
        _scrollToBottom();
      }
    } catch (e) {
      _showError('Failed to capture/upload photo: ${e.toString()}');
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _uploadImage() async {
    setState(() => _isSending = true);

    try {
      final attachment = await FileUploadService.uploadImage(
        ticketId: widget.ticketId,
        onProgress: (progress) {
          print('Upload progress: ${(progress * 100).toStringAsFixed(0)}%');
        },
      );

      if (attachment != null) {
        await SupabaseService.sendMessage(
          ticketId: widget.ticketId,
          message: '🖼️ Image attached: ${attachment.fileName}',
          sourceLanguage: 'en', // System message in English
        );

        _showSuccess('Image uploaded successfully');
        _loadAttachments(); // Reload attachments list
        _scrollToBottom();
      }
    } catch (e) {
      _showError('Failed to upload image: ${e.toString()}');
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _uploadDocument() async {
    setState(() => _isSending = true);

    try {
      final attachment = await FileUploadService.uploadDocument(
        ticketId: widget.ticketId,
        onProgress: (progress) {
          print('Upload progress: ${(progress * 100).toStringAsFixed(0)}%');
        },
      );

      if (attachment != null) {
        await SupabaseService.sendMessage(
          ticketId: widget.ticketId,
          message: '📄 Document attached: ${attachment.fileName}',
          sourceLanguage: 'en', // System message in English
        );

        _showSuccess('Document uploaded successfully');
        _loadAttachments(); // Reload attachments list
        _scrollToBottom();
      }
    } catch (e) {
      _showError('Failed to upload document: ${e.toString()}');
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _uploadVideo() async {
    setState(() => _isSending = true);

    try {
      final attachment = await FileUploadService.uploadVideo(
        ticketId: widget.ticketId,
        onProgress: (progress) {
          print('Upload progress: ${(progress * 100).toStringAsFixed(0)}%');
        },
      );

      if (attachment != null) {
        await SupabaseService.sendMessage(
          ticketId: widget.ticketId,
          message: '🎥 Video attached: ${attachment.fileName}',
          sourceLanguage: 'en', // System message in English
        );

        _showSuccess('Video uploaded successfully');
        _loadAttachments(); // Reload attachments list
        _scrollToBottom();
      }
    } catch (e) {
      _showError('Failed to upload video: ${e.toString()}');
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showTicketDetails(dynamic ticket) {
    if (ticket == null) {
      _showError('Ticket details not available');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ticket Details',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Title', ticket.title ?? 'No title'),
              const SizedBox(height: 12),
              _buildDetailRow('Description', ticket.description ?? 'No description'),
              const SizedBox(height: 12),
              _buildDetailRow('Status', ticket.status.toString().split('.').last.toUpperCase()),
              const SizedBox(height: 12),
              _buildDetailRow('Priority', ticket.priority.toString().split('.').last.toUpperCase()),
              const SizedBox(height: 12),
              _buildDetailRow('Problem Type', ticket.problemType?.toString().split('.').last.toUpperCase() ?? 'N/A'),
              const SizedBox(height: 12),
              _buildDetailRow('Machine', ticket.machine?.name ?? 'N/A'),
              const SizedBox(height: 12),
              _buildDetailRow('Creator', ticket.creator?.fullName ?? 'Unknown'),
              const SizedBox(height: 12),
              _buildDetailRow('Created', _formatDateTime(ticket.createdAt)),
              if (ticket.assignee != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow('Assigned To', ticket.assignee?.fullName ?? 'Unassigned'),
              ],
              if (ticket.expiresAt != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow('Expires', _formatDateTime(ticket.expiresAt)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Clean up subscriptions when leaving chat
          _messagesSubscription?.cancel();
          _presenceChannel?.unsubscribe();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else {
                Navigator.of(context).pop();
              }
            },
            tooltip: 'Back',
          ),
          title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.ticketTitle ?? 'Chat',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_viewerCount > 0)
              Text(
                _viewers.isNotEmpty
                    ? '$_viewerCount ${_viewerCount == 1 ? 'person' : 'people'} viewing: ${_viewers.values.map((v) => v.fullName ?? 'Unknown').join(', ')}'
                    : '$_viewerCount ${_viewerCount == 1 ? 'person' : 'people'} viewing',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        actions: [
          // Translation Language Selector
          PopupMenuButton<String>(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.translate, size: 20),
                const SizedBox(width: 4),
                Text(
                  _chatTranslationLanguage.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            tooltip: 'Select translation language for received messages',
            onSelected: (String languageCode) {
              setState(() {
                _chatTranslationLanguage = languageCode;
              });
            },
            itemBuilder: (BuildContext context) {
              return TranslationService.supportedLanguages.entries.map((entry) {
                final langCode = entry.key;
                final langName = entry.value;
                final flag = TranslationService().getLanguageFlag(langCode);

                return PopupMenuItem<String>(
                  value: langCode,
                  child: Row(
                    children: [
                      Text(flag, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Text(langName),
                      if (langCode == _chatTranslationLanguage)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.check, size: 16, color: AppColors.success),
                        ),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          // Attachments button
          IconButton(
            onPressed: () {
              setState(() => _showAttachments = !_showAttachments);
            },
            icon: Badge(
              label: Text(_attachments.length.toString()),
              isLabelVisible: _attachments.isNotEmpty,
              child: Icon(_showAttachments ? Icons.attachment : Icons.attach_file),
            ),
            tooltip: 'View Attachments',
          ),
          Consumer<TicketProvider>(
            builder: (context, ticketProvider, child) {
              final ticket = ticketProvider.getTicketById(widget.ticketId);
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  switch (value) {
                    case 'details':
                      _showTicketDetails(ticket);
                      break;
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
                  const PopupMenuItem(
                    value: 'details',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16),
                        SizedBox(width: 8),
                        Text('View Details'),
                      ],
                    ),
                  ),
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
          // Attachments section
          if (_showAttachments)
            Container(
              height: 150,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
              ),
              child: _isLoadingAttachments
                  ? const Center(child: CircularProgressIndicator())
                  : _attachments.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.attach_file,
                                size: 48,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'No attachments yet',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.attachment,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Attachments (${_attachments.length})',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                itemCount: _attachments.length,
                                itemBuilder: (context, index) {
                                  final attachment = _attachments[index];
                                  return _buildAttachmentCard(attachment);
                                },
                              ),
                            ),
                          ],
                        ),
            ),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                // Attachment options button
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.add,
                      color: AppColors.textOnPrimary,
                      size: 28,
                    ),
                    tooltip: 'Attach',
                    enabled: !_isSending,
                    onSelected: (value) {
                      switch (value) {
                        case 'camera':
                          _capturePhoto();
                          break;
                        case 'image':
                          _uploadImage();
                          break;
                        case 'document':
                          _uploadDocument();
                          break;
                        case 'video':
                          _uploadVideo();
                          break;
                        case 'details':
                          final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
                          final ticket = ticketProvider.getTicketById(widget.ticketId);
                          _showTicketDetails(ticket);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'camera',
                        child: Row(
                          children: [
                            Icon(Icons.camera_alt, size: 20, color: AppColors.primary),
                            SizedBox(width: 12),
                            Text('Take Photo'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'image',
                        child: Row(
                          children: [
                            Icon(Icons.image, size: 20, color: AppColors.primary),
                            SizedBox(width: 12),
                            Text('Upload Image'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'document',
                        child: Row(
                          children: [
                            Icon(Icons.description, size: 20, color: AppColors.primary),
                            SizedBox(width: 12),
                            Text('Upload Document'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'video',
                        child: Row(
                          children: [
                            Icon(Icons.videocam, size: 20, color: AppColors.primary),
                            SizedBox(width: 12),
                            Text('Upload Video'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 20, color: AppColors.primary),
                            SizedBox(width: 12),
                            Text('View Ticket Details'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _messageFocusNode,
                    maxLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Type message...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: AppColors.textHint.withOpacity(0.7),
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
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
            child: _TranslatedMessageText(
              message: message,
              targetLanguageCode: _chatTranslationLanguage,
              isOwn: isOwn,
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

  Widget _buildAttachmentCard(TicketAttachment attachment) {
    return GestureDetector(
      onTap: () => _openAttachment(attachment),
      child: Container(
        width: 120,
        height: 120,
        margin: const EdgeInsets.only(right: 8, bottom: 0),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview/Icon section
            Flexible(
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Center(
                  child: attachment.isImage
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                          child: CachedNetworkImage(
                            imageUrl: attachment.fileUrl,
                            width: double.infinity,
                            height: 70,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.error,
                              color: AppColors.error,
                            ),
                          ),
                        )
                      : Icon(
                          attachment.isVideo ? Icons.videocam : Icons.description,
                          size: 40,
                          color: AppColors.primary,
                        ),
                ),
              ),
            ),
            // File info section
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      attachment.fileName,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    attachment.fileSizeFormatted,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAttachment(TicketAttachment attachment) async {
    try {
      final uri = Uri.parse(attachment.fileUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Try with default browser mode
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      print('❌ Error opening attachment: $e');
      _showError('Failed to open attachment. Please check your browser or file viewer.');
    }
  }
}

// Widget that displays a chat message with automatic translation
class _TranslatedMessageText extends StatelessWidget {
  final ChatMessage message;
  final String targetLanguageCode; // User's selected language code (like "en", "ar")
  final bool isOwn;

  const _TranslatedMessageText({
    required this.message,
    required this.targetLanguageCode,
    required this.isOwn,
  });

  @override
  Widget build(BuildContext context) {
    // Get source language code
    final sourceLangCode = message.sourceLanguage;

    // If message is already in target language, show directly
    if (sourceLangCode == targetLanguageCode) {
      return Text(
        message.message,
        style: TextStyle(
          color: isOwn ? AppColors.textOnPrimary : AppColors.textPrimary,
          fontSize: 14,
          height: 1.4,
        ),
      );
    }

    // Otherwise, translate the message
    return FutureBuilder<String>(
      future: TranslationService().translate(
        text: message.message,
        from: sourceLangCode,
        to: targetLanguageCode,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show original message while translating
          return Text(
            message.message,
            style: TextStyle(
              color: isOwn ? AppColors.textOnPrimary.withOpacity(0.7) : AppColors.textPrimary.withOpacity(0.7),
              fontSize: 14,
              height: 1.4,
              fontStyle: FontStyle.italic,
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          // Show original message if translation fails
          return Text(
            message.message,
            style: TextStyle(
              color: isOwn ? AppColors.textOnPrimary : AppColors.textPrimary,
              fontSize: 14,
              height: 1.4,
            ),
          );
        }

        // Show translated message
        return Text(
          snapshot.data!,
          style: TextStyle(
            color: isOwn ? AppColors.textOnPrimary : AppColors.textPrimary,
            fontSize: 14,
            height: 1.4,
          ),
        );
      },
    );
  }
}