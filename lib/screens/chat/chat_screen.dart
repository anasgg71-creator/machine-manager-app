import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/ticket_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../services/file_upload_service.dart';
import '../../services/translation_service.dart';
import '../../config/colors.dart';
import '../../models/chat_message.dart';
import '../../models/user_profile.dart';
import '../../models/ticket_attachment.dart';
import '../../widgets/language_selector.dart';

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
  List<TicketAttachment> _attachments = [];
  bool _isLoading = false;
  bool _isLoadingAttachments = false;
  bool _isSending = false;
  bool _showAttachments = true; // Show attachments by default
  StreamSubscription? _messagesSubscription;
  RealtimeChannel? _presenceChannel;
  int _viewerCount = 0;
  Map<String, UserProfile> _viewers = {};
  String _selectedLanguage = 'English'; // Default language (kept for backward compatibility)
  String _userPreferredLanguage = 'en'; // ISO 639-1 language code for translation

  @override
  void initState() {
    super.initState();
    _loadUserLanguagePreference();
    _loadMessages();
    _loadAttachments();
    _subscribeToMessages();
    _setupPresence();
  }

  Future<void> _loadUserLanguagePreference() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    if (currentUser != null) {
      setState(() {
        _userPreferredLanguage = currentUser.preferredReceiveLanguage;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    _presenceChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;

      if (userId != null) {
        // Use translated messages
        final messages = await SupabaseService.getTranslatedMessages(
          ticketId: widget.ticketId,
          userId: userId,
        );
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
      } else {
        // Fallback to regular messages if no user ID
        final messages = await SupabaseService.getChatMessages(widget.ticketId);
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
      }
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
    _messagesSubscription = SupabaseService.subscribeToChatMessages(widget.ticketId)
        .listen((data) {
      final newMessages = data.map((json) => ChatMessage.fromJson(json)).toList();
      setState(() => _messages = newMessages);
      _scrollToBottom();
    }, onError: (error) {
      _showError('Real-time updates failed: ${error.toString()}');
    });
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

    print('💬 CHAT: Starting to send message...');
    print('💬 CHAT: Ticket ID: ${widget.ticketId}');
    print('💬 CHAT: Original message: $message');
    print('💬 CHAT: Selected language: $_selectedLanguage');
    print('💬 CHAT: Current user: ${SupabaseService.getCurrentUserId()}');

    setState(() => _isSending = true);

    try {
      // Get language code for the selected language
      final sourceLanguageCode = _getLanguageCode(_selectedLanguage);
      print('💬 CHAT: Sending message in original language: $_selectedLanguage ($sourceLanguageCode)');

      print('💬 CHAT: Calling SupabaseService.sendMessage...');
      final sentMessage = await SupabaseService.sendMessage(
        ticketId: widget.ticketId,
        message: message, // Send original message (no translation)
        sourceLanguage: sourceLanguageCode,
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

  String _getLanguageCode(String language) {
    final Map<String, String> languageCodes = {
      'English': 'en',
      'العربية': 'ar',
      'Español': 'es',
      'Français': 'fr',
      'Deutsch': 'de',
      '中文': 'zh',
      '日本語': 'ja',
      '한국어': 'ko',
      'Русский': 'ru',
      'Português': 'pt',
      'Italiano': 'it',
      'हिन्दी': 'hi',
    };
    return languageCodes[language] ?? 'auto';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.ticketTitle ?? 'Chat'),
            if (_viewerCount > 0)
              Text(
                _viewers.isNotEmpty
                    ? '$_viewerCount ${_viewerCount == 1 ? 'person' : 'people'} viewing: ${_viewers.values.map((v) => v.fullName ?? 'Unknown').join(', ')}'
                    : '$_viewerCount ${_viewerCount == 1 ? 'person' : 'people'} viewing',
                style: const TextStyle(
                  fontSize: 12,
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
          // Translation language selector
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: LanguageSelector(
              currentLanguage: _userPreferredLanguage,
              onLanguageChanged: (newLang) async {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final userId = authProvider.currentUser?.id;
                if (userId != null) {
                  await SupabaseService.updateUserLanguagePreference(userId, newLang);
                  setState(() {
                    _userPreferredLanguage = newLang;
                  });
                  _loadMessages(); // Reload with new language

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Text(TranslationService().getLanguageFlag(newLang)),
                          const SizedBox(width: 8),
                          Text('Translation language updated to ${TranslationService.supportedLanguages[newLang]}'),
                        ],
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
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
              height: 200,
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
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.attachment,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Ticket Attachments (${_attachments.length})',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Photos, Documents & Videos',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
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
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                // Camera button
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: IconButton(
                    onPressed: _isSending ? null : _capturePhoto,
                    icon: const Icon(
                      Icons.camera_alt,
                      color: AppColors.primary,
                    ),
                    tooltip: 'Take Photo',
                  ),
                ),
                const SizedBox(width: 8),
                // Upload Image button
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: IconButton(
                    onPressed: _isSending ? null : _uploadImage,
                    icon: const Icon(
                      Icons.image,
                      color: AppColors.primary,
                    ),
                    tooltip: 'Upload Image',
                  ),
                ),
                const SizedBox(width: 8),
                // Upload Document button
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: IconButton(
                    onPressed: _isSending ? null : _uploadDocument,
                    icon: const Icon(
                      Icons.description,
                      color: AppColors.primary,
                    ),
                    tooltip: 'Upload Document',
                  ),
                ),
                const SizedBox(width: 8),
                // Upload Video button
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: IconButton(
                    onPressed: _isSending ? null : _uploadVideo,
                    icon: const Icon(
                      Icons.videocam,
                      color: AppColors.primary,
                    ),
                    tooltip: 'Upload Video',
                  ),
                ),
                const SizedBox(width: 8),
                // View Details button
                Consumer<TicketProvider>(
                  builder: (context, ticketProvider, child) {
                    final ticket = ticketProvider.getTicketById(widget.ticketId);
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: IconButton(
                        onPressed: () => _showTicketDetails(ticket),
                        icon: const Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                        ),
                        tooltip: 'View Details',
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type in $_selectedLanguage (others will see it in their language)...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: AppColors.textHint.withOpacity(0.7),
                      ),
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
            child: _TranslatedMessageText(
              message: message,
              targetLanguage: _selectedLanguage,
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

  PopupMenuItem<String> _buildLanguageMenuItem(String language, String flag) {
    final isSelected = _selectedLanguage == language;
    return PopupMenuItem<String>(
      value: language,
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              language,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
          if (isSelected)
            const Icon(Icons.check, color: AppColors.primary, size: 20),
        ],
      ),
    );
  }

  String _getLanguageFlag(String language) {
    final Map<String, String> flagMap = {
      'English': '🇬🇧',
      'العربية': '🇸🇦',
      'Español': '🇪🇸',
      'Français': '🇫🇷',
      'Deutsch': '🇩🇪',
      '中文': '🇨🇳',
      '日本語': '🇯🇵',
      '한국어': '🇰🇷',
      'Русский': '🇷🇺',
      'Português': '🇵🇹',
      'Italiano': '🇮🇹',
      'हिन्दी': '🇮🇳',
    };
    return flagMap[language] ?? '🌐';
  }

  Widget _buildAttachmentCard(TicketAttachment attachment) {
    return GestureDetector(
      onTap: () => _openAttachment(attachment),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12, bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
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
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Center(
                child: attachment.isImage
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: CachedNetworkImage(
                          imageUrl: attachment.fileUrl,
                          width: double.infinity,
                          height: 100,
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
                        size: 48,
                        color: AppColors.primary,
                      ),
              ),
            ),
            // File info section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.fileName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      attachment.fileSizeFormatted,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
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
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showError('Could not open attachment');
      }
    } catch (e) {
      _showError('Failed to open attachment: ${e.toString()}');
    }
  }

  // Helper method to get language code from full language name
  String _getLanguageCodeFromName(String languageName) {
    final Map<String, String> languageCodes = {
      'English': 'en',
      'العربية': 'ar',
      'Español': 'es',
      'Français': 'fr',
      'Deutsch': 'de',
      '中文': 'zh',
      '日本語': 'ja',
      '한국어': 'ko',
      'Русский': 'ru',
      'Português': 'pt',
      'Italiano': 'it',
      'हिन्दी': 'hi',
    };
    return languageCodes[languageName] ?? 'en';
  }
}

// Widget that displays a chat message with automatic translation
class _TranslatedMessageText extends StatelessWidget {
  final ChatMessage message;
  final String targetLanguage; // User's selected language (full name like "English", "العربية")
  final bool isOwn;

  const _TranslatedMessageText({
    required this.message,
    required this.targetLanguage,
    required this.isOwn,
  });

  @override
  Widget build(BuildContext context) {
    // Get language codes
    final targetLangCode = _getLanguageCode(targetLanguage);
    final sourceLangCode = message.sourceLanguage;

    // If message is already in target language, show directly
    if (sourceLangCode == targetLangCode) {
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
        to: targetLangCode,
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

  String _getLanguageCode(String language) {
    final Map<String, String> languageCodes = {
      'English': 'en',
      'العربية': 'ar',
      'Español': 'es',
      'Français': 'fr',
      'Deutsch': 'de',
      '中文': 'zh',
      '日本語': 'ja',
      '한국어': 'ko',
      'Русский': 'ru',
      'Português': 'pt',
      'Italiano': 'it',
      'हिन्दी': 'hi',
    };
    return languageCodes[language] ?? 'en';
  }
}