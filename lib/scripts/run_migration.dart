import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';

Future<void> main() async {
  print('🔧 Starting database migration...');

  try {
    // Initialize Supabase
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );

    final client = Supabase.instance.client;

    print('✅ Connected to Supabase');
    print('🔄 Adding source_language column...');

    // Execute the migration using RPC or direct SQL
    // Since we can't execute raw DDL through the REST API easily,
    // we'll use the SQL Editor approach

    print('');
    print('⚠️  IMPORTANT: This migration needs to be run through Supabase SQL Editor');
    print('');
    print('Please run this SQL in your Supabase dashboard:');
    print('https://supabase.com/dashboard/project/xsrvoyjdrylusvmdwppl/sql/new');
    print('');
    print('Copy and paste this SQL:');
    print('─' * 80);
    print('ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS source_language TEXT NOT NULL DEFAULT \'en\';');
    print('CREATE INDEX IF NOT EXISTS idx_chat_messages_source_language ON chat_messages(source_language);');
    print('UPDATE chat_messages SET source_language = \'en\' WHERE source_language IS NULL OR source_language = \'\';');
    print('─' * 80);
    print('');
    print('After running the SQL, your translation feature will work!');

  } catch (e) {
    print('❌ Error: $e');
  }
}
