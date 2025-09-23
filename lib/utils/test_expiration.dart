import '../services/ticket_expiration_service.dart';
import '../services/supabase_service.dart';

/// Test utility for ticket expiration functionality
class TestExpiration {

  /// Create a test ticket that expires in 1 minute for testing
  static Future<String?> createTestExpiringTicket() async {
    try {
      final now = DateTime.now();
      final expiresSoon = now.add(const Duration(minutes: 1));

      // Get a machine to use
      final machines = await SupabaseService.getMachines();
      if (machines.isEmpty) {
        print('❌ No machines available for test ticket');
        return null;
      }

      final ticket = await SupabaseService.createTicket(
        title: 'TEST: Expiring Ticket',
        description: 'This is a test ticket that will expire in 1 minute',
        machineId: machines.first.id,
        problemType: 'general',
        priority: 'low',
      );

      // Manually update expiration to 1 minute from now
      await SupabaseService.updateTicket(ticket.id, {
        'expires_at': expiresSoon.toIso8601String(),
      });

      print('✅ Created test ticket: ${ticket.id} (expires at ${expiresSoon})');
      return ticket.id;
    } catch (e) {
      print('❌ Failed to create test ticket: $e');
      return null;
    }
  }

  /// Create a test ticket that should get a warning (expires in 12 hours)
  static Future<String?> createTestWarningTicket() async {
    try {
      final now = DateTime.now();
      final warningTime = now.add(const Duration(hours: 12));

      // Get a machine to use
      final machines = await SupabaseService.getMachines();
      if (machines.isEmpty) {
        print('❌ No machines available for test ticket');
        return null;
      }

      final ticket = await SupabaseService.createTicket(
        title: 'TEST: Warning Ticket',
        description: 'This is a test ticket that should trigger a warning',
        machineId: machines.first.id,
        problemType: 'general',
        priority: 'medium',
      );

      // Manually update expiration to 12 hours from now
      await SupabaseService.updateTicket(ticket.id, {
        'expires_at': warningTime.toIso8601String(),
      });

      print('✅ Created warning test ticket: ${ticket.id} (expires at ${warningTime})');
      return ticket.id;
    } catch (e) {
      print('❌ Failed to create warning test ticket: $e');
      return null;
    }
  }

  /// Run a manual expiration check
  static Future<void> runManualCheck() async {
    try {
      print('🔄 Running manual expiration check...');
      await TicketExpirationService.manualCheck();
      print('✅ Manual expiration check completed');
    } catch (e) {
      print('❌ Manual expiration check failed: $e');
    }
  }

  /// Test the extension functionality
  static Future<void> testExtension(String ticketId) async {
    try {
      print('🔄 Testing ticket extension for: $ticketId');
      final success = await TicketExpirationService.extendTicketExpiration(ticketId);
      if (success) {
        print('✅ Ticket extension successful');
      } else {
        print('❌ Ticket extension failed');
      }
    } catch (e) {
      print('❌ Ticket extension error: $e');
    }
  }

  /// Check service status
  static void checkServiceStatus() {
    print('🔄 Checking Ticket Expiration Service status...');
    print('Service running: ${TicketExpirationService.isRunning}');
    print('Next check time: ${TicketExpirationService.nextCheckTime}');
  }

  /// Complete test suite
  static Future<void> runCompleteTest() async {
    print('🧪 Starting complete ticket expiration test...');

    checkServiceStatus();

    // Create test tickets
    final expiringTicketId = await createTestExpiringTicket();
    final warningTicketId = await createTestWarningTicket();

    // Wait a moment
    await Future.delayed(const Duration(seconds: 2));

    // Run manual check
    await runManualCheck();

    // Test extension if we have tickets
    if (expiringTicketId != null) {
      await testExtension(expiringTicketId);
    }

    if (warningTicketId != null) {
      await testExtension(warningTicketId);
    }

    print('🧪 Complete test finished!');
  }
}