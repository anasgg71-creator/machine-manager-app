import 'package:flutter/material.dart';
import '../config/colors.dart';
import '../models/ticket.dart';

class EnhancedTicketCard extends StatefulWidget {
  final Map<String, dynamic> ticket;
  final VoidCallback? onChatPressed;
  final VoidCallback? onClosePressed;
  final VoidCallback? onExtendPressed;
  final VoidCallback? onEditPressed;
  final String? currentUserId;

  const EnhancedTicketCard({
    super.key,
    required this.ticket,
    this.onChatPressed,
    this.onClosePressed,
    this.onExtendPressed,
    this.onEditPressed,
    this.currentUserId,
  });

  @override
  State<EnhancedTicketCard> createState() => _EnhancedTicketCardState();
}

class _EnhancedTicketCardState extends State<EnhancedTicketCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getTimeRemaining() {
    final expiresAt = DateTime.parse(widget.ticket['expires_at'] ?? DateTime.now().add(const Duration(days: 3)).toIso8601String());
    final now = DateTime.now();
    final difference = expiresAt.difference(now);

    if (difference.isNegative) {
      return 'EXPIRED';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return '${difference.inMinutes}m';
    }
  }

  Color _getTimeRemainingColor() {
    final expiresAt = DateTime.parse(widget.ticket['expires_at'] ?? DateTime.now().add(const Duration(days: 3)).toIso8601String());
    final now = DateTime.now();
    final difference = expiresAt.difference(now);

    if (difference.isNegative) {
      return AppColors.error;
    } else if (difference.inHours <= 6) {
      return AppColors.error;
    } else if (difference.inHours <= 24) {
      return AppColors.warning;
    } else {
      return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.ticket['status'] ?? 'open';
    final priority = widget.ticket['priority'] ?? 'medium';
    final timeRemaining = _getTimeRemaining();
    final timeColor = _getTimeRemainingColor();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.getPriorityColor(priority).withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowMedium,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header with status and time remaining
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.getPriorityColor(priority).withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.getTicketStatusColor(status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.textOnPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Updated badge (if ticket has been updated)
                      if (widget.ticket['last_updated_at'] != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'UPDATED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Time remaining with icon
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: timeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: timeColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              timeRemaining == 'EXPIRED' ? Icons.timer_off : Icons.timer,
                              size: 16,
                              color: timeColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeRemaining,
                              style: TextStyle(
                                color: timeColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        widget.ticket['title'] ?? 'No Title',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Description
                      Text(
                        widget.ticket['description'] ?? 'No description available',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),

                      // Machine and priority info
                      Row(
                        children: [
                          Icon(
                            Icons.precision_manufacturing,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.ticket['machine_id'] ?? 'Unknown Machine',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.getPriorityColor(priority).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              priority.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.getPriorityColor(priority),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Join (Chat) button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: widget.onChatPressed,
                          icon: const Icon(Icons.chat_bubble_outline, size: 16),
                          label: const Text('Join'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textOnPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Edit button (only for creator)
                      if (widget.currentUserId != null &&
                          widget.ticket['creator_id'] == widget.currentUserId &&
                          widget.onEditPressed != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: widget.onEditPressed,
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Edit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      if (widget.currentUserId != null &&
                          widget.ticket['creator_id'] == widget.currentUserId &&
                          widget.onEditPressed != null)
                        const SizedBox(width: 8),

                      // Close button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (status == 'open' || status == 'in_progress')
                              ? widget.onClosePressed
                              : null,
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Close'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (status == 'open' || status == 'in_progress')
                                ? AppColors.error
                                : AppColors.textSecondary,
                            foregroundColor: AppColors.textOnPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Extend button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: widget.onExtendPressed,
                          icon: const Icon(Icons.schedule, size: 16),
                          label: const Text('Extend'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                            foregroundColor: AppColors.textOnPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
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
      },
    );
  }
}