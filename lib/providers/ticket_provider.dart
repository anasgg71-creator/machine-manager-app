import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/ticket_expiration_service.dart';
import '../models/ticket.dart';
import '../models/machine.dart';
import '../models/user_profile.dart';

class TicketProvider extends ChangeNotifier {
  List<Ticket> _tickets = [];
  List<Machine> _machines = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Ticket> get tickets => _tickets;
  List<Machine> get machines => _machines;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Filter properties
  String? _statusFilter;
  String? _priorityFilter;
  String? _problemTypeFilter;
  String? _machineFilter;

  String? get statusFilter => _statusFilter;
  String? get priorityFilter => _priorityFilter;
  String? get problemTypeFilter => _problemTypeFilter;
  String? get machineFilter => _machineFilter;

  // Filtered tickets
  List<Ticket> get filteredTickets {
    var filtered = _tickets.where((ticket) {
      if (_statusFilter != null && ticket.status != _statusFilter) return false;
      if (_priorityFilter != null && ticket.priority != _priorityFilter) return false;
      if (_problemTypeFilter != null && ticket.problemType != _problemTypeFilter) return false;
      if (_machineFilter != null && ticket.machineId != _machineFilter) return false;
      return true;
    }).toList();

    // Sort by priority and created date
    filtered.sort((a, b) {
      final priorityOrder = {'critical': 0, 'high': 1, 'medium': 2, 'low': 3};
      final aPriority = priorityOrder[a.priority] ?? 4;
      final bPriority = priorityOrder[b.priority] ?? 4;

      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }

      return b.createdAt.compareTo(a.createdAt);
    });

    return filtered;
  }

  // Get tickets by status
  List<Ticket> get openTickets => _tickets.where((t) => t.isOpen).toList();
  List<Ticket> get inProgressTickets => _tickets.where((t) => t.isInProgress).toList();
  List<Ticket> get resolvedTickets => _tickets.where((t) => t.isResolved).toList();
  List<Ticket> get myTickets {
    final currentUserId = SupabaseService.getCurrentUserId();
    return _tickets.where((t) =>
        t.creatorId == currentUserId ||
        t.assigneeId == currentUserId
    ).toList();
  }

  // Statistics
  int get totalTickets => _tickets.length;
  int get openTicketsCount => openTickets.length;
  int get inProgressTicketsCount => inProgressTickets.length;
  int get resolvedTicketsCount => resolvedTickets.length;
  int get myTicketsCount => myTickets.length;

  double get resolutionRate {
    if (totalTickets == 0) return 0.0;
    return (resolvedTicketsCount / totalTickets) * 100;
  }

  TicketProvider() {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await Future.wait([
      loadTickets(),
      loadMachines(),
    ]);
  }

  Future<void> loadTickets() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      print('🔄 Loading tickets...');
      final tickets = await SupabaseService.getTickets(limit: 100);
      _tickets = tickets;
      print('✅ Loaded ${tickets.length} tickets');
      print('📊 Tickets by status:');
      print('   - Open: ${openTickets.length}');
      print('   - In Progress: ${inProgressTickets.length}');
      print('   - Resolved: ${resolvedTickets.length}');
    } catch (e) {
      print('❌ ERROR loading tickets: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      _errorMessage = 'Failed to load tickets: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMachines() async {
    try {
      final machines = await SupabaseService.getMachines();
      _machines = machines;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load machines: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<Ticket?> createTicket({
    required String title,
    required String description,
    required String machineId,
    required String problemType,
    required String priority,
  }) async {
    try {
      print('🐛 PROVIDER: Starting ticket creation...');
      print('🐛 PROVIDER: Title: "$title"');
      print('🐛 PROVIDER: Description: "$description"');
      print('🐛 PROVIDER: Machine ID: "$machineId"');
      print('🐛 PROVIDER: Problem Type: "$problemType"');
      print('🐛 PROVIDER: Priority: "$priority"');

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Validate machine exists
      final machine = getMachineById(machineId);
      if (machine == null) {
        throw Exception('Machine with ID "$machineId" not found. Available machines: ${_machines.map((m) => '${m.id}:${m.name}').join(', ')}');
      }
      print('✅ PROVIDER: Machine validation passed - ${machine.name}');

      print('🐛 PROVIDER: Calling SupabaseService.createTicket...');
      final ticket = await SupabaseService.createTicket(
        title: title,
        description: description,
        machineId: machineId,
        problemType: problemType,
        priority: priority,
      );

      print('✅ PROVIDER: Ticket created successfully with ID: ${ticket.id}');
      _tickets.insert(0, ticket);
      notifyListeners();
      return ticket;
    } catch (e, stackTrace) {
      print('❌ PROVIDER: Error creating ticket: $e');
      print('❌ PROVIDER: Stack trace: $stackTrace');
      _errorMessage = 'Failed to create ticket: ${e.toString()}';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTicket(String ticketId, Map<String, dynamic> updates) async {
    try {
      await SupabaseService.updateTicket(ticketId, updates);

      // Update local ticket
      final index = _tickets.indexWhere((t) => t.id == ticketId);
      if (index != -1) {
        // Reload the specific ticket to get updated relations
        final updatedTicket = await SupabaseService.getTicket(ticketId);
        _tickets[index] = updatedTicket;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _errorMessage = 'Failed to update ticket: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> assignTicket(String ticketId, String assigneeId) async {
    return await updateTicket(ticketId, {
      'assignee_id': assigneeId,
      'status': 'in_progress',
    });
  }

  Future<bool> resolveTicket({
    required String ticketId,
    required String resolverId,
    required String resolution,
    int? rating,
  }) async {
    try {
      await SupabaseService.resolveTicket(
        ticketId: ticketId,
        resolverId: resolverId,
        resolution: resolution,
        rating: rating,
      );

      // Reload tickets to get updated data with points calculation
      await loadTickets();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to resolve ticket: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<List<UserProfile>> getChatParticipants(String ticketId) async {
    try {
      return await SupabaseService.getChatParticipants(ticketId);
    } catch (e) {
      _errorMessage = 'Failed to load chat participants: ${e.toString()}';
      notifyListeners();
      return [];
    }
  }

  Future<bool> closeTicket({
    required String ticketId,
    String? resolverId,
    String? resolution,
    int? rating,
    String closeReason = 'closed_by_user',
  }) async {
    try {
      await SupabaseService.closeTicket(
        ticketId: ticketId,
        resolverId: resolverId,
        resolution: resolution,
        rating: rating,
        closeReason: closeReason,
      );

      // Reload tickets to get updated data
      await loadTickets();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to close ticket: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Filter methods
  void setStatusFilter(String? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setPriorityFilter(String? priority) {
    _priorityFilter = priority;
    notifyListeners();
  }

  void setProblemTypeFilter(String? problemType) {
    _problemTypeFilter = problemType;
    notifyListeners();
  }

  void setMachineFilter(String? machineId) {
    _machineFilter = machineId;
    notifyListeners();
  }

  void clearFilters() {
    _statusFilter = null;
    _priorityFilter = null;
    _problemTypeFilter = null;
    _machineFilter = null;
    notifyListeners();
  }

  // Search
  List<Ticket> searchTickets(String query) {
    if (query.isEmpty) return filteredTickets;

    return filteredTickets.where((ticket) {
      return ticket.title.toLowerCase().contains(query.toLowerCase()) ||
             ticket.description.toLowerCase().contains(query.toLowerCase()) ||
             ticket.machine?.name.toLowerCase().contains(query.toLowerCase()) == true ||
             ticket.creator?.fullName?.toLowerCase().contains(query.toLowerCase()) == true;
    }).toList();
  }

  // Get ticket by ID
  Ticket? getTicketById(String ticketId) {
    try {
      return _tickets.firstWhere((ticket) => ticket.id == ticketId);
    } catch (e) {
      return null;
    }
  }

  // Get machine by ID
  Machine? getMachineById(String machineId) {
    try {
      return _machines.firstWhere((machine) => machine.id == machineId);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadInitialData();
  }

  // Extension functionality - properly updates the database
  Future<bool> extendTicketExpiration(String ticketId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final success = await TicketExpirationService.extendTicketExpiration(ticketId);

      if (success) {
        // Reload the specific ticket to get updated expiration
        final updatedTicket = await SupabaseService.getTicket(ticketId);
        final index = _tickets.indexWhere((t) => t.id == ticketId);
        if (index != -1) {
          _tickets[index] = updatedTicket;
          notifyListeners();
        }
      }

      return success;
    } catch (e) {
      _errorMessage = 'Failed to extend ticket: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Manual check for expiring tickets (for testing/admin purposes)
  Future<void> checkExpirations() async {
    try {
      await TicketExpirationService.manualCheck();
      await loadTickets(); // Refresh tickets after check
    } catch (e) {
      _errorMessage = 'Failed to check expirations: ${e.toString()}';
      notifyListeners();
    }
  }

  // Get expiring tickets (within 24 hours)
  List<Ticket> get expiringTickets {
    final now = DateTime.now();
    return _tickets.where((ticket) {
      if (ticket.isClosed || ticket.isResolved) return false;
      final timeUntilExpiry = ticket.expiresAt.difference(now);
      return timeUntilExpiry.inHours <= 24 && timeUntilExpiry.inHours > 0;
    }).toList();
  }

  // Get expired tickets
  List<Ticket> get expiredTickets {
    return _tickets.where((ticket) => ticket.isExpired && !ticket.isClosed).toList();
  }

  // Statistics for expired/expiring tickets
  int get expiringTicketsCount => expiringTickets.length;
  int get expiredTicketsCount => expiredTickets.length;
}