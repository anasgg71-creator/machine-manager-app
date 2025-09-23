import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';
import 'supabase_service.dart';

class MachineSeedService {
  static SupabaseClient get client => Supabase.instance.client;

  /// Seeds the database with machines from the constants if they don't exist
  static Future<void> seedMachinesIfEmpty() async {
    try {
      print('🌱 Checking if machines need to be seeded...');

      // Check if any machines exist
      final existingMachines = await client
          .from('machines')
          .select('id, name')
          .limit(10);

      print('🐛 SEED: Found ${existingMachines.length} existing machines');
      for (final machine in existingMachines) {
        print('🐛 SEED: Existing machine: ${machine['id']} - ${machine['name']}');
      }

      if (existingMachines.isNotEmpty) {
        print('✅ Machines already exist in database, skipping seeding');
        return;
      }

      print('🌱 Seeding machines from constants...');

      final List<Map<String, dynamic>> machinesToInsert = [];

      // Convert constants to machine records
      for (final category in AppConstants.machineCategories) {
        final categoryValue = category['value']!;
        final categoryName = category['name']!;
        final machines = AppConstants.machinesByCategory[categoryValue] ?? [];

        print('🐛 SEED: Processing category: $categoryValue with ${machines.length} machines');

        for (final machine in machines) {
          final machineRecord = {
            'id': machine['id']!,
            'name': machine['name']!,
            'category': categoryValue,
            'status': 'operational',
            'location': _getLocationForCategory(categoryValue),
            'created_at': DateTime.now().toIso8601String(),
          };
          machinesToInsert.add(machineRecord);
          print('🐛 SEED: Prepared machine: ${machineRecord['id']} - ${machineRecord['name']}');
        }
      }

      if (machinesToInsert.isNotEmpty) {
        print('🌱 Inserting ${machinesToInsert.length} machines into database...');
        await client
            .from('machines')
            .insert(machinesToInsert);

        print('✅ Successfully seeded ${machinesToInsert.length} machines');

        // Verify the insertion
        final verifyMachines = await client
            .from('machines')
            .select('id, name')
            .limit(20);
        print('🔍 VERIFICATION: Database now contains ${verifyMachines.length} machines');
      } else {
        print('⚠️ No machines to seed from constants');
      }
    } catch (e, stackTrace) {
      print('❌ Error seeding machines: $e');
      print('❌ Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get a logical location for machine category
  static String _getLocationForCategory(String category) {
    switch (category) {
      case 'alpha_machine':
      case 'beta_machine':
        return 'Production Floor A';
      case 'gamma_machine':
      case 'delta_machine':
        return 'Production Floor B';
      case 'packaging_line_a':
      case 'packaging_line_b':
        return 'Packaging Area';
      case 'quality_control':
        return 'Quality Control Lab';
      default:
        return 'Main Floor';
    }
  }

  /// Force re-seed machines (useful for development/testing)
  static Future<void> forceSeedMachines() async {
    try {
      print('🗑️ Clearing existing machines...');
      await client.from('machines').delete().neq('id', '');

      print('🌱 Force seeding machines...');
      await seedMachinesIfEmpty();
    } catch (e) {
      print('❌ Error force seeding machines: $e');
      rethrow;
    }
  }
}