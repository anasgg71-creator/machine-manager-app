import '../services/supabase_service.dart';
import '../services/machine_seed_service.dart';
import '../config/constants.dart';

/// Simple test utility to verify ticket creation works
class TestTicketCreation {
  static Future<void> runTest() async {
    try {
      print('🧪 TEST: Starting ticket creation test...');

      // Initialize Supabase
      await SupabaseService.initialize();
      print('✅ TEST: Supabase initialized');

      // Check authentication
      final user = SupabaseService.currentUser;
      if (user == null) {
        print('❌ TEST: User not authenticated');
        return;
      }
      print('✅ TEST: User authenticated: ${user.email}');

      // Seed machines if needed
      await MachineSeedService.seedMachinesIfEmpty();
      print('✅ TEST: Machine seeding completed');

      // Get available machines
      final machines = await SupabaseService.getMachines();
      print('✅ TEST: Found ${machines.length} machines');

      if (machines.isEmpty) {
        print('❌ TEST: No machines available');
        return;
      }

      // Use the first machine for testing
      final testMachine = machines.first;
      print('🧪 TEST: Using machine: ${testMachine.id} - ${testMachine.name}');

      // Create a test ticket
      final testTicket = await SupabaseService.createTicket(
        title: 'Test Ticket - ${DateTime.now().millisecondsSinceEpoch}',
        description: 'This is a test ticket to verify creation works',
        machineId: testMachine.id,
        problemType: 'mechanical',
        priority: 'medium',
      );

      print('✅ TEST: Ticket created successfully!');
      print('🎯 TEST: Ticket ID: ${testTicket.id}');
      print('🎯 TEST: Ticket Title: ${testTicket.title}');
      print('🎯 TEST: Machine: ${testTicket.machine?.name}');

    } catch (e, stackTrace) {
      print('❌ TEST: Error during test: $e');
      print('❌ TEST: Stack trace: $stackTrace');
    }
  }

  static Future<void> runMachineTest() async {
    try {
      print('🧪 MACHINE TEST: Starting machine test...');

      // Initialize Supabase
      await SupabaseService.initialize();
      print('✅ MACHINE TEST: Supabase initialized');

      // Seed machines
      await MachineSeedService.seedMachinesIfEmpty();
      print('✅ MACHINE TEST: Machine seeding completed');

      // Get machines from database
      final machines = await SupabaseService.getMachines();
      print('✅ MACHINE TEST: Retrieved ${machines.length} machines from database');

      for (final machine in machines) {
        print('🔧 MACHINE TEST: ${machine.id} - ${machine.name} (${machine.category})');
      }

      // Get machines from constants
      print('📋 MACHINE TEST: Machines defined in constants:');
      for (final category in AppConstants.machineCategories) {
        final categoryValue = category['value']!;
        final machines = AppConstants.machinesByCategory[categoryValue] ?? [];
        print('📂 MACHINE TEST: Category $categoryValue has ${machines.length} machines');
        for (final machine in machines) {
          print('   - ${machine['id']} - ${machine['name']}');
        }
      }

    } catch (e, stackTrace) {
      print('❌ MACHINE TEST: Error during test: $e');
      print('❌ MACHINE TEST: Stack trace: $stackTrace');
    }
  }
}