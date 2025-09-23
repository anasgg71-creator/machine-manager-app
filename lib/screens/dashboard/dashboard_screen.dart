import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../services/supabase_service.dart';
import '../../config/colors.dart';
import '../../config/constants.dart';
import '../chat/chat_screen.dart';

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
  String _selectedPriority = 'medium';

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
    if (_problemTitleController.text.trim().isEmpty ||
        _problemDescriptionController.text.trim().isEmpty ||
        _selectedMachineId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    final ticket = await ticketProvider.createTicket(
      title: _problemTitleController.text.trim(),
      description: _problemDescriptionController.text.trim(),
      machineId: _selectedMachineId!,
      problemType: 'mechanical',
      priority: _selectedPriority,
    );

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit problem. Please try again.'),
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

    // Use first available machine if none selected
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
          boxShadow: [
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
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
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: color,
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
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search tickets...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.cardBackground,
                    ),
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
                    ? const Center(child: CircularProgressIndicator())
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
            ElevatedButton(
              onPressed: () async {
                print('🔧 DEBUG: Manual ticket reload triggered');
                await ticketProvider.loadTickets();
                print('🔧 DEBUG: Manual reload completed');
              },
              child: const Text('🔧 DEBUG: Reload Tickets'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return _buildTicketCard(ticket, false);
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
                      case 'close':
                        await _updateTicketStatus(ticket['id'], 'Closed');
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
                    ? const Center(child: CircularProgressIndicator())
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
        const Expanded(
          child: Center(
            child: Text(
              'Team screen coming soon!',
              style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMachineCategoriesScreen() {
    return Column(
      children: [
        _buildAppHeader('Machine Categories', 'Browse by machine type', onBack: () {
          setState(() {
            _currentScreen = 'roomDetail';
          });
        }),
        const Expanded(
          child: Center(
            child: Text(
              'Machine categories coming soon!',
              style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
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

                    // Machine Selection
                    const Text(
                      'Machine',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                      hint: const Text('Select machine'),
                      items: ticketProvider.machines.map((machine) {
                        return DropdownMenuItem(
                          value: machine.id,
                          child: Text(machine.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMachineId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Priority Selection
                    const Text(
                      'Priority',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('🟢 Low')),
                        DropdownMenuItem(value: 'medium', child: Text('🟡 Medium')),
                        DropdownMenuItem(value: 'high', child: Text('🟠 High')),
                        DropdownMenuItem(value: 'critical', child: Text('🔴 Critical')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedPriority = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 30),

                    // Submit Button
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

                    // Machine Selection
                    const Text(
                      'Related Machine (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                      hint: const Text('Select machine (optional)'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('No specific machine'),
                        ),
                        ...ticketProvider.machines.map((machine) {
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