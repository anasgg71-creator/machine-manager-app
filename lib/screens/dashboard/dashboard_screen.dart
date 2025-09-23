import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../services/supabase_service.dart';
import '../../config/colors.dart';
import '../../config/constants.dart';
import '../chat/chat_screen.dart';
import '../../widgets/animated_button.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/animated_form_field.dart';
import '../../widgets/enhanced_ticket_card.dart';

// NEW DESIGN: Modern colors, enhanced tickets with time countdown, chat & close buttons

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _currentScreen = 'roomSelection';
  String? _selectedTicketId;
  String _searchQuery = '';
  String _currentFilter = 'all';
  String _selectedRoom = 'room1';

  final List<Map<String, String>> _rooms = [
    {'id': 'room1', 'name': 'Tetrapack Room 1', 'description': 'Main production line'},
    {'id': 'room2', 'name': 'Tetrapack Room 2', 'description': 'Secondary production line'},
    {'id': 'room3', 'name': 'Tetrapack Room 3', 'description': 'Quality control station'},
    {'id': 'room4', 'name': 'Tetrapack Room 4', 'description': 'Packaging and logistics'},
  ];

  // Form Controllers
  final _problemTitleController = TextEditingController();
  final _problemDescriptionController = TextEditingController();
  final _questionTitleController = TextEditingController();
  final _questionDescriptionController = TextEditingController();

  // Solver Selection State
  bool _showSolverModal = false;
  String? _selectedSolver;
  int _selectedRating = 0;
  final _feedbackController = TextEditingController();

  // Form State
  String? _selectedMachineId;
  String? _selectedMachineCategory;
  String? _selectedProblemType;
  String _selectedPriority = 'medium';
  int _urgencyRating = 0;
  List<Map<String, dynamic>> _uploadedFiles = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _problemTitleController.dispose();
    _problemDescriptionController.dispose();
    _questionTitleController.dispose();
    _questionDescriptionController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitProblem() async {
    print('🐛 DEBUG: Starting problem submission...');
    print('🐛 DEBUG: Title: "${_problemTitleController.text.trim()}"');
    print('🐛 DEBUG: Description: "${_problemDescriptionController.text.trim()}"');
    print('🐛 DEBUG: Selected Machine ID: $_selectedMachineId');
    print('🐛 DEBUG: Selected Priority: $_selectedPriority');

    if (_problemTitleController.text.trim().isEmpty ||
        _problemDescriptionController.text.trim().isEmpty) {
      print('❌ DEBUG: Validation failed - missing required fields');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields (title and description)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Auto-select first machine if none selected
    if (_selectedMachineId == null) {
      final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
      if (ticketProvider.machines.isNotEmpty) {
        _selectedMachineId = ticketProvider.machines.first.id;
        print('🔧 DEBUG: Auto-selected machine: ${ticketProvider.machines.first.name}');
      } else {
        print('❌ DEBUG: No machines available');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No machines available. Please try again later.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    try {
      print('🐛 DEBUG: Getting ticket provider...');
      final ticketProvider = Provider.of<TicketProvider>(context, listen: false);

      print('🐛 DEBUG: Available machines: ${ticketProvider.machines.length}');
      for (final machine in ticketProvider.machines) {
        print('🐛 DEBUG: Machine: ${machine.id} - ${machine.name}');
      }

      print('🐛 DEBUG: Calling createTicket...');
      final ticket = await ticketProvider.createTicket(
        title: _problemTitleController.text.trim(),
        description: _problemDescriptionController.text.trim(),
        machineId: _selectedMachineId!,
        problemType: 'mechanical',
        priority: _selectedPriority,
      );

      print('🐛 DEBUG: Create ticket result: ${ticket != null ? "SUCCESS" : "FAILED"}');
      if (ticket != null) {
        print('✅ DEBUG: Ticket created successfully with ID: ${ticket.id}');
      } else {
        print('❌ DEBUG: Ticket creation returned null');
        print('❌ DEBUG: Provider error: ${ticketProvider.errorMessage}');
      }

      if (ticket != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Problem reported successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form
        _problemTitleController.clear();
        _problemDescriptionController.clear();
        setState(() {
          _selectedMachineId = null;
          _selectedPriority = 'medium';
          _currentScreen = 'roomDetail';
        });
      } else {
        final errorMsg = ticketProvider.errorMessage ?? 'Unknown error occurred';
        print('❌ DEBUG: Showing error to user: $errorMsg');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit problem: $errorMsg'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ DEBUG: Exception during problem submission: $e');
      print('❌ DEBUG: Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting problem: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testTicketCreation() async {
    print('🧪 DEBUG BUTTON: Starting ticket creation test...');

    try {
      final ticketProvider = Provider.of<TicketProvider>(context, listen: false);

      print('🧪 DEBUG BUTTON: Available machines: ${ticketProvider.machines.length}');
      for (final machine in ticketProvider.machines) {
        print('🧪 DEBUG BUTTON: Machine: ${machine.id} - ${machine.name}');
      }

      if (ticketProvider.machines.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No machines available for testing'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Use the first available machine
      final testMachine = ticketProvider.machines.first;
      print('🧪 DEBUG BUTTON: Using test machine: ${testMachine.id} - ${testMachine.name}');

      final ticket = await ticketProvider.createTicket(
        title: 'TEST TICKET - ${DateTime.now().millisecondsSinceEpoch}',
        description: 'This is a test ticket created by the debug button to verify ticket creation works.',
        machineId: testMachine.id,
        problemType: 'mechanical',
        priority: 'medium',
      );

      if (ticket != null) {
        print('✅ DEBUG BUTTON: Test ticket created successfully!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('TEST TICKET CREATED: ${ticket.id}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('❌ DEBUG BUTTON: Test ticket creation failed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('TEST FAILED: ${ticketProvider.errorMessage ?? "Unknown error"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ DEBUG BUTTON: Exception during test: $e');
      print('❌ DEBUG BUTTON: Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('TEST ERROR: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitQuestion() async {
    if (_questionTitleController.text.trim().isEmpty ||
        _questionDescriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);

    // Use first available machine if none selected, with null safety
    if (ticketProvider.machines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No machines available. Please try again later.')),
      );
      return;
    }
    String machineId = _selectedMachineId ?? ticketProvider.machines.first.id;

    final ticket = await ticketProvider.createTicket(
      title: _questionTitleController.text.trim(),
      description: _questionDescriptionController.text.trim(),
      machineId: machineId,
      problemType: 'general',
      priority: 'low',
    );

    if (ticket != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      _questionTitleController.clear();
      _questionDescriptionController.clear();
      setState(() {
        _selectedMachineId = null;
        _currentScreen = 'roomDetail';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit question. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openTicketChat(String ticketId) {
    setState(() {
      _selectedTicketId = ticketId;
      _currentScreen = 'chat';
    });
  }

  void _showCloseTicketDialog(Map<String, dynamic> ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Ticket'),
        content: Text('Are you sure you want to close ticket "${ticket['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
              await ticketProvider.closeTicket(ticketId: ticket['id']);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ticket closed successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Close Ticket'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            _buildCurrentScreen(),
            if (_showSolverModal) _buildSolverModal(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentScreen) {
      case 'roomSelection':
        return _buildRoomSelectionScreen();
      case 'activeIssues':
        return _buildActiveIssuesScreen();
      case 'chat':
        return _buildChatScreen();
      case 'history':
        return _buildHistoryScreen();
      case 'team':
        return _buildTeamScreen();
      case 'machineCategories':
        return _buildMachineCategoriesScreen();
      case 'reportProblem':
        return _buildReportProblemScreen();
      case 'askQuestion':
        return _buildAskQuestionScreen();
      default:
        return _buildRoomDetailScreen();
    }
  }

  // Main Room Detail Screen
  Widget _buildRoomDetailScreen() {
    final currentRoom = _rooms.firstWhere((room) => room['id'] == _selectedRoom);
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          children: [
            _buildAppHeader(currentRoom['name']!, currentRoom['description']!, onBack: () {
              setState(() {
                _currentScreen = 'roomSelection';
              });
            }),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Quick Actions Grid
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          _buildActionCard(
                            'Active Issues',
                            'Current open tickets & discussions',
                            Icons.assignment,
                            AppColors.error,
                            () => setState(() => _currentScreen = 'activeIssues'),
                          ),
                          _buildActionCard(
                            'History',
                            'Past tickets and resolutions',
                            Icons.history,
                            AppColors.info,
                            () => setState(() => _currentScreen = 'history'),
                          ),
                          _buildActionCard(
                            'Team',
                            'Leaderboard & profiles',
                            Icons.people,
                            AppColors.success,
                            () => setState(() => _currentScreen = 'team'),
                          ),
                          _buildActionCard(
                            'Machine Categories',
                            'Browse by machine type',
                            Icons.category,
                            AppColors.warning,
                            () => setState(() => _currentScreen = 'machineCategories'),
                          ),
                          _buildActionCard(
                            'Report Problem',
                            'Submit machine issues',
                            Icons.report_problem,
                            AppColors.error,
                            () => setState(() => _currentScreen = 'reportProblem'),
                          ),
                          _buildActionCard(
                            'Ask Question',
                            'Get help from team',
                            Icons.help,
                            AppColors.primary,
                            () => setState(() => _currentScreen = 'askQuestion'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.border.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.1),
                      color.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Active Issues Screen with real ticket list and filtering
  Widget _buildActiveIssuesScreen() {
    print('🏗️ Building Active Issues Screen');
    return Consumer<TicketProvider>(
      builder: (context, ticketProvider, child) {
        print('🔄 Consumer builder called - isLoading: ${ticketProvider.isLoading}, tickets: ${ticketProvider.tickets.length}');
        return Column(
          children: [
            _buildAppHeader('Active Issues', 'Current open tickets', onBack: () {
              setState(() {
                _currentScreen = 'roomDetail';
              });
            }),
            // Search and Filter Section
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                children: [
                  // Search Bar
                  AnimatedFormField(
                    label: 'Search tickets',
                    hintText: 'Type to search...',
                    prefixIcon: Icons.search,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Quick Filter Buttons
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterButton('👤 My Tickets', _currentFilter == 'my', () => _applyMyTicketsFilter(ticketProvider)),
                        const SizedBox(width: 8),
                        _buildFilterButton('⏰ Expiring Soon', _currentFilter == 'expiring', () => _applyExpiringSoonFilter(ticketProvider)),
                        const SizedBox(width: 8),
                        _buildFilterButton('❗ High Priority', _currentFilter == 'priority', () => _applyHighPriorityFilter(ticketProvider)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ticketProvider.isLoading
                    ? Column(
                        children: List.generate(
                          5,
                          (index) => const TicketCardSkeleton(),
                        ),
                      )
                    : _buildTicketsList(ticketProvider),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTicketsList(TicketProvider ticketProvider) {
    List<dynamic> tickets = [];

    print('🎯 Building tickets list with filter: $_currentFilter');
    print('🔍 Search query: "$_searchQuery"');
    print('📊 Total tickets in provider: ${ticketProvider.tickets.length}');

    if (_searchQuery.isNotEmpty) {
      // Use search functionality
      tickets = ticketProvider.searchTickets(_searchQuery).map((ticket) => _convertToMap(ticket)).toList();
      print('🔎 Search results: ${tickets.length} tickets');
    } else {
      // Apply current filter
      switch (_currentFilter) {
        case 'my':
          tickets = ticketProvider.myTickets.map((ticket) => _convertToMap(ticket)).toList();
          print('👤 My tickets: ${tickets.length}');
          break;
        case 'expiring':
          tickets = ticketProvider.expiringTickets.map((ticket) => _convertToMap(ticket)).toList();
          print('⏰ Expiring tickets: ${tickets.length}');
          break;
        default:
          tickets = ticketProvider.filteredTickets.map((ticket) => _convertToMap(ticket)).toList();
          print('📋 Filtered tickets: ${tickets.length}');
          break;
      }
    }

    print('🎭 Final tickets to display: ${tickets.length}');

    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No tickets found'
                  : 'No Active Issues',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search or filters'
                  : 'Create one by reporting a problem or asking a question!',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            AnimatedButton(
              text: '🔧 Reload Tickets',
              icon: Icons.refresh,
              onPressed: () async {
                print('🔧 DEBUG: Manual ticket reload triggered');
                await ticketProvider.loadTickets();
                print('🔧 DEBUG: Manual reload completed');
              },
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return EnhancedTicketCard(
          ticket: ticket,
          onChatPressed: () => _openTicketChat(ticket['id']),
          onClosePressed: () => _showCloseTicketDialog(ticket),
          onExtendPressed: () => _extendTicket(ticket['id']),
        );
      },
    );
  }

  Map<String, dynamic> _convertToMap(ticket) {
    return {
      'id': ticket.id,
      'title': ticket.title,
      'description': ticket.description,
      'status': ticket.status,
      'priority': ticket.priority,
      'problemType': ticket.problemType,
      'createdAt': ticket.createdAt.toIso8601String(),
      'updatedAt': ticket.updatedAt.toIso8601String(),
      'expiresAt': ticket.expiresAt.toIso8601String(),
      'machineId': ticket.machineId,
      'creatorId': ticket.creatorId,
      'assigneeId': ticket.assigneeId,
      'resolverId': ticket.resolverId,
      'resolution': ticket.resolution,
      'rating': ticket.rating,
    };
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(ticket['priority']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ticket['priority'].toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getPriorityColor(ticket['priority']),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildExpirationTimer(ticket),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) async {
                    switch (value) {
                      case 'chat':
                        _openTicketChat(ticket['id']);
                        break;
                      case 'resolve':
                        _showSolverSelectionModal(ticket['id']);
                        break;
                      case 'extend':
                        await _extendTicket(ticket['id']);
                        break;
                      case 'close':
                        final ticketProvider = context.read<TicketProvider>();
        await ticketProvider.closeTicket(ticketId: ticket['id']);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'chat',
                      child: Row(
                        children: [
                          Icon(Icons.chat, size: 16),
                          SizedBox(width: 8),
                          Text('Open Chat'),
                        ],
                      ),
                    ),
                    if (ticket['status'] != 'resolved')
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
                    if (ticket['status'] == 'open')
                      const PopupMenuItem(
                        value: 'extend',
                        child: Row(
                          children: [
                            Icon(Icons.schedule, size: 16),
                            SizedBox(width: 8),
                            Text('Extend Deadline'),
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
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ticket['title'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ticket['description'],
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(ticket['status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ticket['status'].toString().replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(ticket['status']),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(ticket['createdAt']),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return AppColors.error;
      case 'high':
        return AppColors.warning;
      case 'medium':
        return AppColors.info;
      case 'low':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppColors.error;
      case 'in_progress':
        return AppColors.warning;
      case 'resolved':
        return AppColors.success;
      case 'closed':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  Widget _buildFilterButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  void _applyMyTicketsFilter(TicketProvider ticketProvider) {
    ticketProvider.clearFilters();
    setState(() {
      _currentFilter = 'my';
    });
  }

  void _applyExpiringSoonFilter(TicketProvider ticketProvider) {
    ticketProvider.clearFilters();
    setState(() {
      _currentFilter = 'expiring';
    });
  }

  void _applyHighPriorityFilter(TicketProvider ticketProvider) {
    ticketProvider.clearFilters();
    ticketProvider.setPriorityFilter('high');
    setState(() {
      _currentFilter = 'priority';
    });
  }

  Future<void> _updateTicketStatus(String ticketId, String newStatus) async {
    if (newStatus == 'Resolved') {
      // Show solver selection modal instead of directly resolving
      _showSolverSelectionModal(ticketId);
    } else {
      final ticketProvider = context.read<TicketProvider>();

      try {
        String status = newStatus.toLowerCase().replaceAll(' ', '_');
        await ticketProvider.updateTicket(ticketId, {'status': status});
        _showSuccessMessage('Ticket status updated successfully!');
      } catch (e) {
        _showSuccessMessage('Failed to update ticket status: ${e.toString()}');
      }
    }
  }

  Future<void> _extendTicket(String ticketId) async {
    final ticketProvider = context.read<TicketProvider>();

    try {
      final success = await ticketProvider.extendTicketExpiration(ticketId);
      if (success) {
        _showSuccessMessage('Ticket deadline extended by 3 days!');
      } else {
        _showSuccessMessage('Failed to extend ticket deadline');
      }
    } catch (e) {
      _showSuccessMessage('Error extending ticket: ${e.toString()}');
    }
  }

  void _showSolverSelectionModal(String ticketId) {
    setState(() {
      _selectedTicketId = ticketId;
      _showSolverModal = true;
      _selectedSolver = null;
      _selectedRating = 0;
      _feedbackController.clear();
    });
  }

  void _closeSolverModal() {
    setState(() {
      _showSolverModal = false;
      _selectedSolver = null;
      _selectedRating = 0;
      _feedbackController.clear();
    });
  }

  Widget _buildSolverModal() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.textOnPrimary),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Mark as Resolved',
                        style: TextStyle(
                          color: AppColors.textOnPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _closeSolverModal,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.textOnPrimary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.textOnPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Solver selection
                    const Text(
                      'Who solved this issue?',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Hardcoded team members for now
                    ...['Alice Johnson', 'Bob Smith', 'Charlie Brown', 'Diana Lee'].map((name) {
                      final isSelected = _selectedSolver == name;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => setState(() => _selectedSolver = name),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.primary,
                                  child: Text(
                                    name.substring(0, 1),
                                    style: const TextStyle(
                                      color: AppColors.textOnPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    // Rating section
                    if (_selectedSolver != null) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Rate the solution quality',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final rating = index + 1;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedRating = rating),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.star,
                                size: 32,
                                color: rating <= _selectedRating
                                    ? Colors.amber
                                    : Colors.grey.shade300,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Feedback
                    const Text(
                      'Additional feedback (optional):',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _feedbackController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Great work on diagnosing the issue quickly...',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _closeSolverModal,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: (_selectedSolver != null && _selectedRating > 0)
                            ? () async => await _submitSolverRating()
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Mark as Solved',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitSolverRating() async {
    final ticketId = _selectedTicketId!;
    final ticketProvider = context.read<TicketProvider>();

    try {
      final success = await ticketProvider.resolveTicket(
        ticketId: ticketId,
        resolverId: 'hardcoded-user-id', // TODO: Use actual user ID
        resolution: _feedbackController.text.trim(),
        rating: _selectedRating,
      );

      if (success) {
        _showSuccessMessage('Ticket marked as resolved! ${_selectedSolver} earned ${_selectedRating * 2} points!');
      }
    } catch (e) {
      _showSuccessMessage('Error resolving ticket: ${e.toString()}');
    }

    _closeSolverModal();
    setState(() => _currentScreen = 'activeIssues');
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildAppHeader(String title, String subtitle, {VoidCallback? onBack}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (onBack != null)
              GestureDetector(
                onTap: onBack,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.textOnPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios,
                    color: AppColors.textOnPrimary,
                    size: 20,
                  ),
                ),
              ),
            if (onBack != null) const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textOnPrimary.withOpacity(0.8),
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

  // Placeholder screens
  Widget _buildHistoryScreen() {
    return Consumer<TicketProvider>(
      builder: (context, ticketProvider, child) {
        return Column(
          children: [
            _buildAppHeader('History', 'Past tickets and resolutions', onBack: () {
              setState(() {
                _currentScreen = 'roomDetail';
              });
            }),
            // History Filter Section
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  _buildHistoryFilter('All History', _currentFilter == 'all_history', () {
                    setState(() => _currentFilter = 'all_history');
                  }),
                  const SizedBox(width: 8),
                  _buildHistoryFilter('Resolved', _currentFilter == 'resolved', () {
                    setState(() => _currentFilter = 'resolved');
                  }),
                  const SizedBox(width: 8),
                  _buildHistoryFilter('Closed', _currentFilter == 'closed', () {
                    setState(() => _currentFilter = 'closed');
                  }),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ticketProvider.isLoading
                    ? Column(
                        children: List.generate(
                          4,
                          (index) => const TicketCardSkeleton(),
                        ),
                      )
                    : _buildHistoryList(ticketProvider),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryFilter(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(TicketProvider ticketProvider) {
    List<dynamic> historyTickets = [];

    switch (_currentFilter) {
      case 'resolved':
        historyTickets = ticketProvider.resolvedTickets.map((ticket) => _convertToMap(ticket)).toList();
        break;
      case 'closed':
        historyTickets = ticketProvider.tickets
            .where((ticket) => ticket.isClosed)
            .map((ticket) => _convertToMap(ticket))
            .toList();
        break;
      default:
        historyTickets = ticketProvider.tickets
            .where((ticket) => ticket.isResolved || ticket.isClosed)
            .map((ticket) => _convertToMap(ticket))
            .toList();
        break;
    }

    // Sort by resolution/update date (newest first)
    historyTickets.sort((a, b) {
      final aDate = DateTime.parse(a['updatedAt']);
      final bDate = DateTime.parse(b['updatedAt']);
      return bDate.compareTo(aDate);
    });

    if (historyTickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No history found',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Resolved and closed tickets will appear here',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: historyTickets.length,
      itemBuilder: (context, index) {
        final ticket = historyTickets[index];
        return _buildHistoryTicketCard(ticket);
      },
    );
  }

  Widget _buildHistoryTicketCard(Map<String, dynamic> ticket) {
    final updatedAt = DateTime.parse(ticket['updatedAt']);
    final age = DateTime.now().difference(updatedAt);

    String ageDisplay;
    if (age.inDays > 0) {
      ageDisplay = '${age.inDays}d ago';
    } else if (age.inHours > 0) {
      ageDisplay = '${age.inHours}h ago';
    } else {
      ageDisplay = '${age.inMinutes}m ago';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ticket['status'] == 'resolved'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ticket['status'].toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: ticket['status'] == 'resolved' ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(ticket['priority']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ticket['priority'].toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getPriorityColor(ticket['priority']),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  ageDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              ticket['title'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ticket['description'],
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (ticket['resolution'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resolution:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket['resolution'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeamScreen() {
    return Column(
      children: [
        _buildAppHeader('Team', 'Leaderboard & profiles', onBack: () {
          setState(() {
            _currentScreen = 'roomDetail';
          });
        }),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTeamStats(),
                const SizedBox(height: 24),
                _buildLeaderboard(),
                const SizedBox(height: 24),
                _buildActiveMembers(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamStats() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Team Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Total Members', '24', Icons.people, Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Active Today', '18', Icons.person_outline, Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Tickets Solved', '142', Icons.check_circle, Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Avg Response', '2.5h', Icons.timer, Colors.purple),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    final leaders = [
      {'name': 'Alice Johnson', 'solved': 28, 'rating': 4.9},
      {'name': 'Bob Smith', 'solved': 24, 'rating': 4.8},
      {'name': 'Charlie Brown', 'solved': 22, 'rating': 4.7},
      {'name': 'Diana Lee', 'solved': 20, 'rating': 4.6},
      {'name': 'Eva Chen', 'solved': 18, 'rating': 4.5},
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Performers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...leaders.asMap().entries.map((entry) {
              final index = entry.key;
              final leader = entry.value;
              return _buildLeaderboardItem(index + 1, leader);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardItem(int rank, Map<String, dynamic> leader) {
    final rankColors = [Colors.amber, Colors.grey, Colors.brown];
    final rankColor = rank <= 3 ? rankColors[rank - 1] : AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: rank <= 3 ? rankColor.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: rank <= 3 ? rankColor.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rankColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leader['name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${leader['solved']} tickets solved',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                leader['rating'].toString(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveMembers() {
    final activeMembers = [
      {'name': 'John Doe', 'status': 'Online', 'working': 'Machine A-101'},
      {'name': 'Sarah Wilson', 'status': 'Busy', 'working': 'Machine B-205'},
      {'name': 'Mike Taylor', 'status': 'Online', 'working': 'Available'},
      {'name': 'Lisa Garcia', 'status': 'Away', 'working': 'Machine C-308'},
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Team Members',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...activeMembers.map((member) => _buildActiveMemberItem(member)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveMemberItem(Map<String, dynamic> member) {
    final statusColor = member['status'] == 'Online'
        ? Colors.green
        : member['status'] == 'Busy'
            ? Colors.orange
            : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, color: Colors.white),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  member['working'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(
              member['status'],
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMachineCategoriesScreen() {
    return Consumer<TicketProvider>(
      builder: (context, ticketProvider, child) {
        return Column(
          children: [
            _buildAppHeader('Machine Categories', 'Browse by machine type', onBack: () {
              setState(() {
                _currentScreen = 'roomDetail';
              });
            }),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProblemAnalytics(ticketProvider),
                    const SizedBox(height: 24),
                    _buildMachineCategories(ticketProvider),
                    const SizedBox(height: 24),
                    _buildRecentProblems(ticketProvider),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProblemAnalytics(TicketProvider ticketProvider) {
    final totalTickets = ticketProvider.tickets.length;
    final openTickets = ticketProvider.tickets.where((t) => t.status == 'open').length;
    final solvedTickets = ticketProvider.tickets.where((t) => t.status == 'closed').length;
    final avgResolutionTime = solvedTickets > 0 ? '4.2h' : 'N/A';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Problem Analytics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsCard('Total Issues', totalTickets.toString(), Icons.bug_report, Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAnalyticsCard('Open Issues', openTickets.toString(), Icons.warning, Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAnalyticsCard('Resolved', solvedTickets.toString(), Icons.check_circle, Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAnalyticsCard('Avg Time', avgResolutionTime, Icons.timer, Colors.purple),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMachineCategories(TicketProvider ticketProvider) {
    final categories = AppConstants.machineCategories.map((category) {
      final machines = AppConstants.machinesByCategory[category['value']] ?? [];
      return {
        'name': category['name'],
        'count': machines.length,
        'icon': _getCategoryIcon(category['value']!),
        'color': _getCategoryColor(category['value']!),
        'value': category['value'],
      };
    }).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Machine Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return _buildCategoryCard(category);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: category['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: category['color'].withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            category['icon'],
            color: category['color'],
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            category['name'],
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${category['count']} machines',
            style: TextStyle(
              fontSize: 12,
              color: category['color'],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentProblems(TicketProvider ticketProvider) {
    final recentTickets = ticketProvider.tickets
        .where((ticket) => ticket.status == 'open')
        .take(3)
        .toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Problems',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _currentScreen = 'reportProblem';
                    });
                  },
                  child: const Text('Report New'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentTickets.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No recent problems reported',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              ...recentTickets.map((ticket) => _buildRecentProblemItem(ticket)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentProblemItem(dynamic ticket) {
    final priority = ticket is Map ? ticket['priority'] : ticket.priority;
    final title = ticket is Map ? ticket['title'] : ticket.title;
    final status = ticket is Map ? ticket['status'] : ticket.status;
    final createdAt = ticket is Map ? ticket['created_at'] : ticket.createdAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getPriorityColor(priority).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getPriorityColor(priority).withOpacity(0.3)),
            ),
            child: Text(
              priority.toString().toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _getPriorityColor(priority),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatDate(createdAt.toString()),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            status == 'open' ? Icons.circle : Icons.check_circle,
            color: status == 'open' ? Colors.orange : Colors.green,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildReportProblemScreen() {
    return Consumer<TicketProvider>(
      builder: (context, ticketProvider, child) {
        return Column(
          children: [
            _buildAppHeader('Report Problem', 'Submit machine issues', onBack: () {
              setState(() {
                _currentScreen = 'roomDetail';
              });
            }),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Field
                    const Text(
                      'Problem Title',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _problemTitleController,
                      decoration: InputDecoration(
                        hintText: 'Brief description of the problem',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description Field
                    const Text(
                      'Problem Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _problemDescriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Detailed description of the problem...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // File Upload Section
                    const Text(
                      'Attachments (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFileUploadSection(),
                    const SizedBox(height: 20),

                    // Machine Category Selection
                    const Text(
                      'Machine Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedMachineCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                      hint: const Text('Select machine category'),
                      items: AppConstants.machineCategories.map((category) {
                        return DropdownMenuItem(
                          value: category['value'],
                          child: Text(category['label']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMachineCategory = value;
                          _selectedMachineId = null; // Reset machine selection
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Machine Selection (filtered by category) - Using Database Machines
                    const Text(
                      'Specific Machine',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedMachineId,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                      hint: Text(_selectedMachineCategory == null
                          ? 'Please select a category first'
                          : 'Select specific machine'),
                      items: _selectedMachineCategory == null
                          ? []
                          : ticketProvider.machines
                              .where((machine) => machine.category == _selectedMachineCategory)
                              .map((machine) {
                              return DropdownMenuItem(
                                value: machine.id,
                                child: Text(machine.name),
                              );
                            }).toList(),
                      onChanged: _selectedMachineCategory == null
                          ? null
                          : (value) {
                              setState(() {
                                _selectedMachineId = value;
                              });
                            },
                    ),
                    const SizedBox(height: 20),

                    // Problem Type Selection
                    const Text(
                      'Problem Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedProblemType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                      hint: const Text('Select problem type'),
                      items: const [
                        DropdownMenuItem(value: 'mechanical', child: Text('🔧 Mechanical Issue')),
                        DropdownMenuItem(value: 'electrical', child: Text('⚡ Electrical Problem')),
                        DropdownMenuItem(value: 'software', child: Text('💻 Software/Programming')),
                        DropdownMenuItem(value: 'maintenance', child: Text('🛠️ Routine Maintenance')),
                        DropdownMenuItem(value: 'calibration', child: Text('📏 Calibration Required')),
                        DropdownMenuItem(value: 'safety', child: Text('⚠️ Safety Concern')),
                        DropdownMenuItem(value: 'quality', child: Text('🎯 Quality Issue')),
                        DropdownMenuItem(value: 'training', child: Text('📚 Training/Help Needed')),
                        DropdownMenuItem(value: 'other', child: Text('❓ Other')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedProblemType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Priority Selection
                    const Text(
                      'Priority Level',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        _buildPriorityOption('low', '🟢 Low Priority', 'Can wait, non-urgent issue'),
                        const SizedBox(height: 8),
                        _buildPriorityOption('medium', '🟡 Medium Priority', 'Should be addressed within a day'),
                        const SizedBox(height: 8),
                        _buildPriorityOption('high', '🟠 High Priority', 'Needs attention within hours'),
                        const SizedBox(height: 8),
                        _buildPriorityOption('critical', '🔴 Critical', 'Immediate attention required - safety risk'),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Debug Test Button (temporary)
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _testTicketCreation,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'DEBUG: Test Ticket Creation',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),

                    // Submit Button
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: ticketProvider.isLoading ? null : _submitProblem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: ticketProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
                                ),
                              )
                            : const Text(
                                'Submit Problem Report',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAskQuestionScreen() {
    return Consumer<TicketProvider>(
      builder: (context, ticketProvider, child) {
        return Column(
          children: [
            _buildAppHeader('Ask Question', 'Get help from team', onBack: () {
              setState(() {
                _currentScreen = 'roomDetail';
              });
            }),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Field
                    const Text(
                      'Question Title',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _questionTitleController,
                      decoration: InputDecoration(
                        hintText: 'What do you need help with?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description Field
                    const Text(
                      'Question Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _questionDescriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Provide more details about your question...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Question Category
                    const Text(
                      'Question Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedProblemType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                      hint: const Text('Select question type'),
                      items: const [
                        DropdownMenuItem(value: 'setup', child: Text('🔧 Machine Setup/Operation')),
                        DropdownMenuItem(value: 'programming', child: Text('💻 Programming/Software')),
                        DropdownMenuItem(value: 'maintenance', child: Text('🛠️ Maintenance Procedures')),
                        DropdownMenuItem(value: 'troubleshooting', child: Text('🔍 Troubleshooting Help')),
                        DropdownMenuItem(value: 'safety', child: Text('⚠️ Safety Guidelines')),
                        DropdownMenuItem(value: 'training', child: Text('📚 Training/Learning')),
                        DropdownMenuItem(value: 'best_practices', child: Text('✨ Best Practices')),
                        DropdownMenuItem(value: 'general', child: Text('❓ General Question')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedProblemType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // File Upload Section
                    const Text(
                      'Attachments (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFileUploadSection(),
                    const SizedBox(height: 20),

                    // Machine Category Selection
                    const Text(
                      'Related Machine Category (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedMachineCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                      hint: const Text('Select machine category (optional)'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('No specific category'),
                        ),
                        ...AppConstants.machineCategories.map((category) {
                          return DropdownMenuItem(
                            value: category['value'],
                            child: Text(category['label']!),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedMachineCategory = value;
                          _selectedMachineId = null; // Reset machine selection
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Specific Machine Selection (conditional) - Using Database Machines
                    if (_selectedMachineCategory != null) ...[
                      const Text(
                        'Specific Machine (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedMachineId,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                        hint: const Text('Select specific machine (optional)'),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('No specific machine'),
                          ),
                          ...ticketProvider.machines
                              .where((machine) => machine.category == _selectedMachineCategory)
                              .map((machine) {
                            return DropdownMenuItem(
                              value: machine.id,
                              child: Text(machine.name),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedMachineId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                    const SizedBox(height: 20),

                    // Urgency Rating
                    const Text(
                      'Urgency Level',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildUrgencyRating(),
                    const SizedBox(height: 30),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: ticketProvider.isLoading ? null : _submitQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: ticketProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
                                ),
                              )
                            : const Text(
                                'Submit Question',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Chat Screen
  Widget _buildChatScreen() {
    if (_selectedTicketId == null) {
      return Column(
        children: [
          _buildAppHeader('Chat', 'No ticket selected', onBack: () {
            setState(() {
              _currentScreen = 'activeIssues';
            });
          }),
          const Expanded(
            child: Center(
              child: Text(
                'No ticket selected for chat',
                style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      );
    }

    return ChatScreen(
      ticketId: _selectedTicketId!,
      ticketTitle: 'Ticket Chat',
    );
  }

  // Expiration Timer Widget
  Widget _buildExpirationTimer(Map<String, dynamic> ticket) {
    final expiresAt = DateTime.parse(ticket['expiresAt']);
    final now = DateTime.now();
    final timeToExpiry = expiresAt.difference(now);

    bool isExpired = now.isAfter(expiresAt);
    bool isExpiringSoon = timeToExpiry.inHours <= 12 && timeToExpiry.inHours > 0;

    if (isExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.timer_off, size: 12, color: Colors.red),
            SizedBox(width: 4),
            Text(
              'EXPIRED',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
      );
    }

    if (isExpiringSoon) {
      String timeDisplay;
      if (timeToExpiry.inHours > 0) {
        timeDisplay = '${timeToExpiry.inHours}h ${timeToExpiry.inMinutes % 60}m';
      } else if (timeToExpiry.inMinutes > 0) {
        timeDisplay = '${timeToExpiry.inMinutes}m';
      } else {
        timeDisplay = 'Soon';
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer, size: 12, color: Colors.orange),
            const SizedBox(width: 4),
            Text(
              timeDisplay,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      );
    }

    // For tickets with more than 12 hours left, show a simple timer
    String timeDisplay;
    if (timeToExpiry.inDays > 0) {
      timeDisplay = '${timeToExpiry.inDays}d';
    } else {
      timeDisplay = '${timeToExpiry.inHours}h';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, size: 12, color: Colors.green),
          const SizedBox(width: 4),
          Text(
            timeDisplay,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityOption(String value, String title, String description) {
    final isSelected = _selectedPriority == value;
    final priorityColor = _getPriorityColor(value);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPriority = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? priorityColor.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? priorityColor : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? priorityColor : AppColors.border,
                  width: 2,
                ),
                color: isSelected ? priorityColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? priorityColor : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? priorityColor.withOpacity(0.8)
                          : AppColors.textSecondary,
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

  Widget _buildFileUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              const Text(
                'Upload Photos, Videos, or Documents',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Help us understand the problem better',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildUploadButton('📷 Photo', Icons.camera_alt, () => _pickFile('photo')),
                  _buildUploadButton('🎥 Video', Icons.videocam, () => _pickFile('video')),
                  _buildUploadButton('📄 Document', Icons.description, () => _pickFile('document')),
                ],
              ),
            ],
          ),
        ),
        if (_uploadedFiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Uploaded Files:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                ..._uploadedFiles.map((file) => _buildUploadedFileItem(file)).toList(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUploadButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadedFileItem(Map<String, dynamic> file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(
            _getFileIcon(file['type']),
            size: 16,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              file['name'],
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => _removeFile(file),
            child: const Icon(Icons.close, size: 16, color: Colors.red),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String type) {
    switch (type) {
      case 'photo':
        return Icons.image;
      case 'video':
        return Icons.video_file;
      case 'document':
        return Icons.description;
      default:
        return Icons.attachment;
    }
  }

  void _pickFile(String type) {
    // For now, simulate file upload
    setState(() {
      _uploadedFiles.add({
        'name': '${type}_${DateTime.now().millisecondsSinceEpoch}.${type == 'photo' ? 'jpg' : type == 'video' ? 'mp4' : 'pdf'}',
        'type': type,
        'size': '2.3 MB',
        'url': 'simulated_url',
      });
    });

    _showSuccessMessage('$type uploaded successfully!');
  }

  void _removeFile(Map<String, dynamic> file) {
    setState(() {
      _uploadedFiles.remove(file);
    });
  }

  Widget _buildUrgencyRating() {
    const urgencyLabels = [
      'Low',
      'Normal',
      'High',
      'Urgent',
      'Critical'
    ];

    const urgencyDescriptions = [
      'Can wait',
      'Normal pace',
      'Important',
      'Need help soon',
      'Immediate attention'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _urgencyRating = index + 1;
                      });
                    },
                    child: Column(
                      children: [
                        Icon(
                          Icons.star,
                          size: 32,
                          color: index < _urgencyRating
                              ? _getUrgencyColor(index + 1)
                              : Colors.grey.withOpacity(0.3),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          urgencyLabels[index],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: index < _urgencyRating
                                ? _getUrgencyColor(index + 1)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              if (_urgencyRating > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getUrgencyColor(_urgencyRating).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    urgencyDescriptions[_urgencyRating - 1],
                    style: TextStyle(
                      fontSize: 12,
                      color: _getUrgencyColor(_urgencyRating),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Color _getUrgencyColor(int rating) {
    switch (rating) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'alpha_machine':
        return Icons.precision_manufacturing;
      case 'beta_machine':
        return Icons.build_circle;
      case 'gamma_machine':
        return Icons.settings;
      case 'delta_machine':
        return Icons.engineering;
      case 'packaging_line_a':
      case 'packaging_line_b':
        return Icons.inventory_2;
      case 'quality_control':
        return Icons.verified;
      default:
        return Icons.factory;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'alpha_machine':
        return Colors.blue;
      case 'beta_machine':
        return Colors.green;
      case 'gamma_machine':
        return Colors.orange;
      case 'delta_machine':
        return Colors.purple;
      case 'packaging_line_a':
        return Colors.red;
      case 'packaging_line_b':
        return Colors.pink;
      case 'quality_control':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  // Room Selection Screen
  Widget _buildRoomSelectionScreen() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          children: [
            _buildAppHeader('Select Room', 'Choose your working location'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _rooms.length,
                  itemBuilder: (context, index) {
                    final room = _rooms[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRoom = room['id']!;
                          _currentScreen = 'roomDetail';
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedRoom == room['id']
                                ? AppColors.primary
                                : AppColors.border,
                            width: _selectedRoom == room['id'] ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowLight,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.factory,
                                  size: 32,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                room['name']!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                room['description']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}