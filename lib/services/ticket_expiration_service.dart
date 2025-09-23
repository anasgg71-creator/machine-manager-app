import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'supabase_service.dart';
import '../models/ticket.dart';

class TicketExpirationService {
  static Timer? _timer;
  static FlutterLocalNotificationsPlugin? _notificationsPlugin;
  static bool _isInitialized = false;

  // Initialize the service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    await _initializeNotifications();
    _startExpirationTimer();
    _isInitialized = true;
  }

  // Initialize local notifications
  static Future<void> _initializeNotifications() async {
    _notificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin?.initialize(initializationSettings);
  }

  // Start the background timer that checks every minute
  static void _startExpirationTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkTicketExpirations();
    });
  }

  // Check for ticket expirations and warnings
  static Future<void> _checkTicketExpirations() async {
    try {
      // Get all open and in-progress tickets
      final tickets = await SupabaseService.getTickets(limit: 1000);
      final activeTickets = tickets.where((ticket) =>
        ticket.status == 'open' || ticket.status == 'in_progress'
      ).toList();

      final now = DateTime.now();

      for (final ticket in activeTickets) {
        final timeUntilExpiry = ticket.expiresAt.difference(now);

        // Auto-close tickets that have expired
        if (timeUntilExpiry.isNegative) {
          await _autoCloseExpiredTicket(ticket);
        }
        // Send warning 24 hours before expiry (if not already warned)
        else if (timeUntilExpiry.inHours <= 24 && !ticket.autoCloseWarned) {
          await _sendExpiryWarning(ticket);
          await _markTicketAsWarned(ticket.id);
        }
      }
    } catch (e) {
      debugPrint('Error checking ticket expirations: $e');
    }
  }

  // Auto-close an expired ticket
  static Future<void> _autoCloseExpiredTicket(Ticket ticket) async {
    try {
      await SupabaseService.updateTicket(ticket.id, {
        'status': 'closed',
        'resolution': 'Automatically closed due to expiration (3 days without activity)',
        'resolved_at': DateTime.now().toIso8601String(),
      });

      // Send notification about auto-closure
      await _showNotification(
        id: ticket.id.hashCode,
        title: 'Ticket Auto-Closed',
        body: 'Ticket "${ticket.title}" was automatically closed due to expiration.',
      );

      debugPrint('Auto-closed expired ticket: ${ticket.id}');
    } catch (e) {
      debugPrint('Error auto-closing ticket ${ticket.id}: $e');
    }
  }

  // Send expiry warning notification
  static Future<void> _sendExpiryWarning(Ticket ticket) async {
    try {
      final timeUntilExpiry = ticket.expiresAt.difference(DateTime.now());
      final hoursLeft = timeUntilExpiry.inHours;

      await _showNotification(
        id: ticket.id.hashCode + 1000, // Offset to avoid ID conflicts
        title: 'Ticket Expiring Soon',
        body: 'Ticket "${ticket.title}" will expire in ${hoursLeft}h. Tap to extend.',
      );

      debugPrint('Sent expiry warning for ticket: ${ticket.id}');
    } catch (e) {
      debugPrint('Error sending expiry warning for ticket ${ticket.id}: $e');
    }
  }

  // Mark ticket as warned to avoid duplicate warnings
  static Future<void> _markTicketAsWarned(String ticketId) async {
    try {
      await SupabaseService.updateTicket(ticketId, {
        'auto_close_warned': true,
      });
    } catch (e) {
      debugPrint('Error marking ticket as warned ${ticketId}: $e');
    }
  }

  // Show local notification
  static Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (_notificationsPlugin == null) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'ticket_expiration',
      'Ticket Expiration',
      channelDescription: 'Notifications for ticket expiration warnings and auto-closures',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notificationsPlugin?.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  // Manual check for testing purposes
  static Future<void> manualCheck() async {
    await _checkTicketExpirations();
  }

  // Extend ticket expiration (fixes the extension functionality)
  static Future<bool> extendTicketExpiration(String ticketId) async {
    try {
      final now = DateTime.now();
      final newExpiresAt = now.add(const Duration(days: 3));

      await SupabaseService.updateTicket(ticketId, {
        'expires_at': newExpiresAt.toIso8601String(),
        'auto_close_warned': false, // Reset warning flag
      });

      // Show success notification
      await _showNotification(
        id: ticketId.hashCode + 2000,
        title: 'Ticket Extended',
        body: 'Ticket expiration extended by 3 days.',
      );

      debugPrint('Extended ticket expiration: $ticketId');
      return true;
    } catch (e) {
      debugPrint('Error extending ticket expiration ${ticketId}: $e');
      return false;
    }
  }

  // Stop the service
  static void stop() {
    _timer?.cancel();
    _timer = null;
    _isInitialized = false;
  }

  // Check if service is running
  static bool get isRunning => _timer?.isActive ?? false;

  // Get next check time
  static DateTime? get nextCheckTime {
    if (_timer == null || !_timer!.isActive) return null;
    return DateTime.now().add(const Duration(minutes: 1));
  }
}