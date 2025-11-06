import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';
import '../models/ticket.dart';
import '../models/user_profile.dart';
import '../models/chat_message.dart';
import '../models/machine.dart';
import '../models/todo_item.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  // Current user
  static User? get currentUser => client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  // Auth Methods
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> resetPassword(String email) async {
    try {
      await client.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // Profile Methods
  static Future<UserProfile> getCurrentUserProfile() async {
    try {
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await client
          .from('profiles')
          .select('*')
          .eq('id', currentUser!.id)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  static Future<UserProfile> getUserProfile(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  static Future<UserProfile> createUserProfile({
    required String userId,
    required String email,
    required String fullName,
  }) async {
    try {
      final response = await client
          .from('profiles')
          .insert({
            'id': userId,
            'email': email,
            'full_name': fullName,
            'role': 'member',
            'points': 0,
            'tickets_solved': 0,
            'average_rating': 0.0,
          })
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<UserProfile>> getLeaderboard({int limit = 50}) async {
    try {
      final response = await client
          .from('profiles')
          .select('*')
          .order('points', ascending: false)
          .limit(limit);

      return response.map((json) => UserProfile.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> updateProfile(Map<String, dynamic> updates) async {
    try {
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await client.from('profiles').update(updates).eq('id', currentUser!.id);
    } catch (e) {
      rethrow;
    }
  }

  // Machine Methods
  static Future<List<Machine>> getMachines() async {
    try {
      final response = await client
          .from('machines')
          .select('*')
          .order('name', ascending: true);

      return response.map((json) => Machine.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  static Future<Machine> getMachine(String machineId) async {
    try {
      final response = await client
          .from('machines')
          .select('*')
          .eq('id', machineId)
          .single();

      return Machine.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // Ticket Methods
  static Future<List<Ticket>> getTickets({
    String? status,
    String? priority,
    String? problemType,
    String? machineId,
    String? creatorId,
    String? assigneeId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      print('🔍 DEBUG: Starting getTickets query...');

      // Simplified query without joins first
      var query = client.from('tickets').select('*').order('created_at', ascending: false);

      query = query.range(offset, offset + limit - 1);

      print('🔍 DEBUG: Executing query...');
      final response = await query;
      print('🔍 DEBUG: Got response with ${response.length} tickets');

      // Create simplified tickets without relations for now
      final tickets = response.map((json) {
        // Add default values for missing relations
        json['creator'] = null;
        json['assignee'] = null;
        json['resolver'] = null;
        json['machine'] = null;
        return Ticket.fromJson(json);
      }).toList();

      print('🔍 DEBUG: Returning ${tickets.length} tickets');
      return tickets;
    } catch (e) {
      print('🔍 DEBUG: Error in getTickets: $e');
      rethrow;
    }
  }

  static Future<Ticket> getTicket(String ticketId) async {
    try {
      final response = await client.from('tickets').select('''
        *,
        creator:profiles!fk_tickets_creator(*),
        assignee:profiles!fk_tickets_assignee(*),
        resolver:profiles!fk_tickets_resolver(*),
        machine:machines!fk_tickets_machine(*)
      ''').eq('id', ticketId).single();

      return Ticket.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Ticket> createTicket({
    required String title,
    required String description,
    required String machineId,
    required String problemType,
    required String priority,
    List<String>? fishboneAnalysis,
  }) async {
    try {
      print('🐛 SUPABASE: Starting ticket creation...');
      print('🐛 SUPABASE: Current user: ${currentUser?.id}');

      if (currentUser == null) {
        print('❌ SUPABASE: User not authenticated');
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: AppConstants.defaultTicketExpireDays));

      final ticketData = {
        'title': title,
        'description': description,
        'machine_id': machineId,
        'problem_type': problemType,
        'priority': priority,
        'creator_id': currentUser!.id,
        'expires_at': expiresAt.toIso8601String(),
      };

      print('🐛 SUPABASE: Ticket data to insert: $ticketData');

      // First, verify the machine exists
      final machineCheck = await client
          .from('machines')
          .select('id, name')
          .eq('id', machineId)
          .maybeSingle();

      if (machineCheck == null) {
        print('❌ SUPABASE: Machine not found with ID: $machineId');
        throw Exception('Machine with ID "$machineId" does not exist');
      }
      print('✅ SUPABASE: Machine exists: ${machineCheck['name']}');

      print('🐛 SUPABASE: Inserting ticket into database...');
      final response = await client
          .from('tickets')
          .insert(ticketData)
          .select('''
            *,
            creator:profiles!fk_tickets_creator(*),
            machine:machines!fk_tickets_machine(*)
          ''')
          .single();

      print('✅ SUPABASE: Ticket inserted successfully');
      print('🐛 SUPABASE: Response: $response');

      return Ticket.fromJson(response);
    } catch (e, stackTrace) {
      print('❌ SUPABASE: Error creating ticket: $e');
      print('❌ SUPABASE: Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<void> updateTicket(String ticketId, Map<String, dynamic> updates) async {
    try {
      await client.from('tickets').update(updates).eq('id', ticketId);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> assignTicket(String ticketId, String assigneeId) async {
    try {
      await updateTicket(ticketId, {
        'assignee_id': assigneeId,
        'status': 'in_progress',
      });
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> resolveTicket({
    required String ticketId,
    required String resolverId,
    required String resolution,
    int? rating,
  }) async {
    try {
      final updates = {
        'status': 'resolved',
        'resolution': resolution,
        'resolver_id': resolverId,
        'resolved_at': DateTime.now().toIso8601String(),
      };

      if (rating != null) {
        updates['rating'] = rating.toString();
      }

      await updateTicket(ticketId, updates);
    } catch (e) {
      rethrow;
    }
  }

  // Extension functionality - actually update the database
  static Future<bool> extendTicketExpiration(String ticketId) async {
    try {
      final now = DateTime.now();
      final newExpiresAt = now.add(const Duration(days: AppConstants.defaultTicketExpireDays));

      await updateTicket(ticketId, {
        'expires_at': newExpiresAt.toIso8601String(),
        'auto_close_warned': false, // Reset warning flag
      });

      return true;
    } catch (e) {
      rethrow;
    }
  }

  // Chat Methods
  static Future<List<ChatMessage>> getChatMessages(String ticketId) async {
    try {
      final response = await client
          .from('chat_messages')
          .select('''
            *,
            sender:profiles!chat_messages_sender_id_fkey(*)
          ''')
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true);

      return response.map((json) => ChatMessage.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  static Future<ChatMessage> sendMessage({
    required String ticketId,
    required String message,
    String messageType = 'text',
    String? attachmentUrl,
  }) async {
    try {
      print('🔷 SUPABASE: sendMessage called');
      print('🔷 SUPABASE: ticketId: $ticketId');
      print('🔷 SUPABASE: message: $message');
      print('🔷 SUPABASE: currentUser: ${currentUser?.id}');

      if (currentUser == null) {
        print('❌ SUPABASE: User not authenticated');
        throw Exception('User not authenticated');
      }

      // Only include fields that exist in the database schema
      final messageData = {
        'ticket_id': ticketId,
        'sender_id': currentUser!.id,
        'message': message,
      };

      print('🔷 SUPABASE: Message data to insert: $messageData');
      print('🔷 SUPABASE: Inserting into chat_messages table...');

      final response = await client
          .from('chat_messages')
          .insert(messageData)
          .select('''
            *,
            sender:profiles!chat_messages_sender_id_fkey(*)
          ''')
          .single();

      print('✅ SUPABASE: Message inserted successfully');
      print('✅ SUPABASE: Response: $response');

      return ChatMessage.fromJson(response);
    } catch (e, stackTrace) {
      print('❌ SUPABASE: Error sending message: $e');
      print('❌ SUPABASE: Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Get chat participants for ticket solver selection
  static Future<List<UserProfile>> getChatParticipants(String ticketId) async {
    try {
      final response = await client
          .from('chat_messages')
          .select('sender_id, sender:profiles!chat_messages_sender_id_fkey(*)')
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: false);

      // Get unique participants
      final Set<String> uniqueSenderIds = <String>{};
      final List<UserProfile> participants = [];

      for (final message in response) {
        final senderId = message['sender_id'] as String;
        if (!uniqueSenderIds.contains(senderId) && message['sender'] != null) {
          uniqueSenderIds.add(senderId);
          participants.add(UserProfile.fromJson(message['sender']));
        }
      }

      return participants;
    } catch (e) {
      rethrow;
    }
  }

  // Close ticket with optional resolution and rating
  static Future<void> closeTicket({
    required String ticketId,
    String? resolverId,
    String? resolution,
    int? rating,
    String closeReason = 'closed_by_user',
  }) async {
    try {
      final updates = {
        'status': 'closed',
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (resolverId != null) updates['resolver_id'] = resolverId;
      if (resolution != null) updates['resolution'] = resolution;
      if (rating != null) updates['rating'] = rating.toString();

      await updateTicket(ticketId, updates);
    } catch (e) {
      rethrow;
    }
  }

  // Todo Methods
  static Future<List<TodoItem>> getTicketTodos(String ticketId) async {
    try {
      final response = await client
          .from('ticket_todos')
          .select('''
            *,
            created_by_profile:profiles!created_by(*),
            completed_by_profile:profiles!completed_by(*)
          ''')
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true);

      return response.map((json) => TodoItem.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  static Future<TodoItem> createTodo({
    required String ticketId,
    required String description,
  }) async {
    try {
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final todoData = {
        'ticket_id': ticketId,
        'description': description,
        'created_by': currentUser!.id,
      };

      final response = await client
          .from('ticket_todos')
          .insert(todoData)
          .select('''
            *,
            created_by_profile:profiles!created_by(*)
          ''')
          .single();

      return TodoItem.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> toggleTodo(String todoId, bool isCompleted) async {
    try {
      // Simplified version - just update the completion status
      await client.from('ticket_todos').update({
        'is_completed': isCompleted,
      }).eq('id', todoId);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> deleteTodo(String todoId) async {
    try {
      await client.from('ticket_todos').delete().eq('id', todoId);
    } catch (e) {
      rethrow;
    }
  }

  // Real-time Subscriptions
  static Stream<List<Map<String, dynamic>>> subscribeToTickets() {
    return client.from('tickets').stream(primaryKey: ['id']);
  }

  static Stream<List<Map<String, dynamic>>> subscribeToChatMessages(String ticketId) {
    return client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('ticket_id', ticketId);
  }

  static Stream<List<Map<String, dynamic>>> subscribeToTicketTodos(String ticketId) {
    return client
        .from('ticket_todos')
        .stream(primaryKey: ['id'])
        .eq('ticket_id', ticketId);
  }

  static Stream<List<Map<String, dynamic>>> subscribeToProfiles() {
    return client.from('profiles').stream(primaryKey: ['id']);
  }

  // Utility Methods
  static Future<bool> isConnected() async {
    try {
      final response = await client.from('profiles').select('id').limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  static String? getCurrentUserId() {
    return currentUser?.id;
  }

  static String? getCurrentUserEmail() {
    return currentUser?.email;
  }
}