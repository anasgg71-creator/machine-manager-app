import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/supabase_service.dart';
import '../../config/colors.dart';
import '../../config/constants.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';
import '../job_marketplace/job_marketplace_screen.dart';
import '../../widgets/animated_button.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/animated_form_field.dart';
import '../../widgets/enhanced_ticket_card.dart';
import '../../widgets/app_navigation_bar.dart';
import '../../widgets/fishbone_diagram.dart';

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

  // Double-press-to-exit variables
  DateTime? _lastBackPressTime;
  static const _exitTimeLimit = Duration(seconds: 2);

  // Language translation helper - simplified for now
  String _translate(String key) {
    // For now, return English text. Future: implement full translation
    final translations = {
      'tetra_support': 'Tetra Support',
      'status_running': 'Running',
      'tetra_support_desc': 'Technical support for Tetra machines',
      'supplier_parts': 'Supplier Parts',
      'status_active': 'Active',
      'supplier_parts_desc': 'Manage supplier parts and orders',
      'quality_lab': 'Quality Lab',
      'quality_lab_desc': 'Quality control and lab analysis',
      'optirva_support': 'Optirva Support',
      'status_available': 'Available',
      'optirva_support_desc': 'Support for Optirva systems',
      'machine_market': 'Machine Market',
      'status_open': 'Open',
      'machine_market_desc': 'Buy and sell machines',
      'ask_question': 'Ask Question',
      'ask_question_desc': 'Get help from experts',
      'report_problem': 'Report Problem',
      'report_problem_desc': 'Report machine issues',
      'active_issues': 'Active Issues',
      'active_issues_desc': 'View ongoing problems',
      'history': 'History',
      'history_desc': 'View past tickets',
      'team': 'Team',
      'team_desc': 'View team leaderboard',
      'machine_categories': 'Machine Categories',
      'machine_categories_desc': 'Browse machines by category',
    };
    return translations[key] ?? key;
  }

  List<Map<String, String>> _getRooms() {
    return [
      {'id': 'room1', 'name': _translate('tetra_support'), 'icon': '🏭', 'status': _translate('status_running'), 'description': _translate('tetra_support_desc')},
      {'id': 'room2', 'name': _translate('supplier_parts'), 'icon': '📦', 'status': _translate('status_active'), 'description': _translate('supplier_parts_desc')},
      {'id': 'room3', 'name': _translate('quality_lab'), 'icon': '🔬', 'status': '✓ ${_translate('status_active')}', 'description': _translate('quality_lab_desc')},
      {'id': 'room4', 'name': _translate('optirva_support'), 'icon': '🛠️', 'status': '✓ ${_translate('status_available')}', 'description': _translate('optirva_support_desc')},
      {'id': 'room5', 'name': _translate('machine_market'), 'icon': '🏪', 'status': '✓ ${_translate('status_open')}', 'description': _translate('machine_market_desc')},
      {'id': 'job_marketplace', 'name': 'Job Marketplace', 'icon': '💼', 'status': '✓ Active', 'description': 'Find jobs or hire talented professionals'},
    ];
  }

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
  List<String> _fishboneAnalysis = [];

  // Edit ticket tracking
  String? _editingTicketId;

  // Quality LAB form state
  String? _labMachineType;
  String? _labDefectType;
  String? _labBacteriaType;
  final _labBatchNumberController = TextEditingController();
  final _labDefectPacksController = TextEditingController();
  final _labTotalPacksController = TextEditingController();
  final _labDescriptionController = TextEditingController();
  String _labDefectRate = '0.00';
  List<Map<String, dynamic>> _labAttachedFiles = [];
  bool _showDiagnosticResults = false;
  String _diagnosticContent = '';

  // Supplier Parts state
  final _partSearchController = TextEditingController();
  List<Map<String, dynamic>> _bulkParts = [];
  final _supplierNameController = TextEditingController();
  final _supplierContactController = TextEditingController();
  final _supplierEmailController = TextEditingController();

  // Machine Marketplace state
  String _marketplaceRole = 'supplier'; // 'supplier' or 'customer'
  String? _marketplaceMachineType;
  String? _marketplacePackageVolume;
  final _marketplaceYearController = TextEditingController();
  final _marketplaceRunningHoursController = TextEditingController();
  String? _marketplaceCondition;
  String? _marketplaceServiceStatus;
  String? _marketplaceTetrapakService;
  final _marketplacePriceController = TextEditingController();
  final _marketplaceDescriptionController = TextEditingController();
  final _marketplaceLocationController = TextEditingController();
  final _marketplaceContactController = TextEditingController();
  List<Map<String, dynamic>> _marketplaceFiles = [];
  // Customer search filters
  String? _searchMachineType;
  String? _searchPackageVolume;
  String? _searchPriceRange;
  String? _searchCondition;

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
    _labBatchNumberController.dispose();
    _labDefectPacksController.dispose();
    _labTotalPacksController.dispose();
    _labDescriptionController.dispose();
    _partSearchController.dispose();
    _supplierNameController.dispose();
    _supplierContactController.dispose();
    _supplierEmailController.dispose();
    _marketplaceYearController.dispose();
    _marketplaceRunningHoursController.dispose();
    _marketplacePriceController.dispose();
    _marketplaceDescriptionController.dispose();
    _marketplaceLocationController.dispose();
    _marketplaceContactController.dispose();
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

      bool success = false;

      // Check if we're editing or creating
      if (_editingTicketId != null) {
        print('🐛 DEBUG: Updating existing ticket: $_editingTicketId');

        // Build update map
        final updates = {
          'title': _problemTitleController.text.trim(),
          'description': _problemDescriptionController.text.trim(),
          'machine_id': _selectedMachineId!,
          'priority': _selectedPriority,
          'fishbone_analysis': _fishboneAnalysis.isNotEmpty ? _fishboneAnalysis : null,
          'last_updated_at': DateTime.now().toIso8601String(),
        };

        success = await ticketProvider.updateTicket(_editingTicketId!, updates);

        if (success) {
          print('✅ DEBUG: Ticket updated successfully');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ticket updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('🐛 DEBUG: Creating new ticket...');
        final ticket = await ticketProvider.createTicket(
          title: _problemTitleController.text.trim(),
          description: _problemDescriptionController.text.trim(),
          machineId: _selectedMachineId!,
          problemType: 'mechanical',
          priority: _selectedPriority,
          fishboneAnalysis: _fishboneAnalysis.isNotEmpty ? _fishboneAnalysis : null,
        );

        success = ticket != null;

        if (success) {
          print('✅ DEBUG: Ticket created successfully with ID: ${ticket!.id}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Problem reported successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (success) {
        // Clear form
        _problemTitleController.clear();
        _problemDescriptionController.clear();
        setState(() {
          _selectedMachineId = null;
          _selectedPriority = 'medium';
          _fishboneAnalysis = [];
          _editingTicketId = null;
          _currentScreen = 'roomDetail';
        });
      } else {
        final errorMsg = ticketProvider.errorMessage ?? 'Unknown error occurred';
        print('❌ DEBUG: Showing error to user: $errorMsg');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${_editingTicketId != null ? "update" : "submit"} problem: $errorMsg'),
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
      fishboneAnalysis: _fishboneAnalysis.isNotEmpty ? _fishboneAnalysis : null,
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
        _fishboneAnalysis = [];
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

  // Quality LAB defect rate calculation
  void _calculateDefectRate() {
    final defectPacks = int.tryParse(_labDefectPacksController.text) ?? 0;
    final totalPacks = int.tryParse(_labTotalPacksController.text) ?? 0;

    if (totalPacks > 0) {
      final rate = (defectPacks / totalPacks) * 100;
      setState(() {
        _labDefectRate = rate.toStringAsFixed(2);
      });
    } else {
      setState(() {
        _labDefectRate = '0.00';
      });
    }
  }

  // Submit Quality LAB report
  Future<void> _submitLabReport() async {
    if (_labMachineType == null || _labDefectType == null || _labBacteriaType == null ||
        _labDefectPacksController.text.trim().isEmpty || _labTotalPacksController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show diagnostic results
    setState(() {
      _showDiagnosticResults = true;
      _diagnosticContent = _generateDiagnosticContent();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lab report submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _generateDiagnosticContent() {
    final bacteria = _labBacteriaType ?? 'Unknown';
    final defectType = _labDefectType ?? 'Unknown';

    // Generate diagnostic content based on bacteria type
    String diagnosis = '';
    switch (bacteria) {
      case 'Clostridium':
        diagnosis = '⚠️ Anaerobic spore-former detected. Likely cause: Insufficient heat treatment or post-process contamination. Recommended actions: Check pasteurization temperature and time, inspect seal integrity.';
        break;
      case 'Bacillus':
        diagnosis = '⚠️ Aerobic spore-former detected. Likely cause: Raw material contamination or inadequate cleaning. Recommended actions: Review CIP procedures, check milk quality at intake.';
        break;
      case 'Coliform':
        diagnosis = '⚠️ Coliform bacteria detected. Likely cause: Post-pasteurization contamination. Recommended actions: Inspect equipment sanitation, check water quality, review personnel hygiene.';
        break;
      case 'Lactobacillus':
        diagnosis = '⚠️ Lactic acid bacteria detected. Likely cause: Inadequate pasteurization or slow cooling. Recommended actions: Verify heat treatment effectiveness, check cooling system.';
        break;
      case 'Yeast':
        diagnosis = '⚠️ Yeast contamination detected. Likely cause: Environmental contamination or packaging issues. Recommended actions: Review air quality, check packaging integrity.';
        break;
      case 'Mold':
        diagnosis = '⚠️ Mold contamination detected. Likely cause: Extended exposure to air or moisture. Recommended actions: Check storage conditions, review packaging process.';
        break;
      default:
        diagnosis = 'ℹ️ Bacteria type unknown. Recommended: Conduct microbiological testing to identify contamination source.';
    }

    return diagnosis;
  }

  // Supplier Parts - Add new part row to bulk list
  void _addPartRowToBulk() {
    setState(() {
      _bulkParts.add({
        'partNumber': '',
        'partName': '',
        'quantity': '',
        'price': '',
        'category': 'Bearings',
        'photos': [],
      });
    });
  }

  // Supplier Parts - Remove part row from bulk list
  void _removePartRowFromBulk(int index) {
    setState(() {
      _bulkParts.removeAt(index);
    });
  }

  // Supplier Parts - Submit bulk parts
  Future<void> _submitBulkParts() async {
    if (_bulkParts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one part')),
      );
      return;
    }

    // Validate all parts have required fields
    for (var i = 0; i < _bulkParts.length; i++) {
      final part = _bulkParts[i];
      if (part['partNumber'].toString().isEmpty ||
          part['partName'].toString().isEmpty ||
          part['quantity'].toString().isEmpty ||
          part['price'].toString().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Part ${i + 1}: Please fill in all required fields')),
        );
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_bulkParts.length} parts added successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    // Clear the bulk parts list after successful submission
    setState(() {
      _bulkParts.clear();
    });
  }

  void _editTicket(String ticketId) {
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    final ticket = ticketProvider.getTicketById(ticketId);

    if (ticket == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Pre-fill form with ticket data
    setState(() {
      _editingTicketId = ticketId;
      _problemTitleController.text = ticket.title;
      _problemDescriptionController.text = ticket.description;
      _selectedMachineId = ticket.machineId;
      _selectedPriority = ticket.priority;
      _fishboneAnalysis = ticket.fishboneAnalysis ?? [];
      _currentScreen = 'submitProblem';
    });
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Handle back navigation based on current screen
        final mainScreens = ['roomSelection', 'activeIssues', 'history', 'team'];

        if (!mainScreens.contains(_currentScreen)) {
          // If not on a main screen, navigate back to previous screen
          setState(() {
            if (_currentScreen == 'roomDetail') {
              _currentScreen = 'roomSelection';
            } else if (_currentScreen == 'chat') {
              _currentScreen = 'activeIssues';
            } else {
              _currentScreen = 'roomSelection';
            }
          });
        } else {
          // On main screen - implement double-press-to-exit
          final now = DateTime.now();
          if (_lastBackPressTime == null ||
              now.difference(_lastBackPressTime!) > _exitTimeLimit) {
            // First press or timeout - show warning
            _lastBackPressTime = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Press back again to exit'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.warning,
              ),
            );
          } else {
            // Second press within time limit - exit app
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Stack(
            children: [
              _buildCurrentScreen(),
              if (_showSolverModal) _buildSolverModal(),
            ],
          ),
        ),
        bottomNavigationBar: AppNavigationBar(
          currentScreen: _currentScreen,
          onScreenChanged: (screen) {
            setState(() {
              _currentScreen = screen;
            });
          },
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
      case 'profile':
        return const ProfileScreen();
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
    final currentRoom = _getRooms().firstWhere((room) => room['id'] == _selectedRoom);

    // Route to different screens based on room ID (matching HTML demo)
    switch (_selectedRoom) {
      case 'room1':
        // Room 1: Show standard menu (Active Issues, History, Team, etc.)
        return _buildRoom1Screen(currentRoom);
      case 'room2':
        // Supplier Parts: Show supplier management screen
        return _buildSupplierPartsScreen(currentRoom);
      case 'room3':
        // Quality LAB: Show quality control screen
        return _buildQualityLabScreen(currentRoom);
      case 'room4':
        // Optirva Support: Show support services screen
        return _buildOptirvaSupportScreen(currentRoom);
      case 'room5':
        // Machine Marketplace: Show marketplace screen
        return _buildMachineMarketplaceScreen(currentRoom);
      default:
        // Fallback to Room 1 style menu
        return _buildRoom1Screen(currentRoom);
    }
  }

  Widget _buildRoom1Screen(Map<String, String> currentRoom) {
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
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildNavItemWithColorIcon(
                    _translate('ask_question'),
                    _translate('ask_question_desc'),
                    Icons.help,
                    const Color(0xFF4CAF50),
                    const Color(0xFFE8F5E9),
                    () => setState(() => _currentScreen = 'askQuestion'),
                  ),
                  _buildNavItemWithColorIcon(
                    _translate('report_problem'),
                    _translate('report_problem_desc'),
                    Icons.warning_amber_rounded,
                    const Color(0xFFF44336),
                    const Color(0xFFFFEBEE),
                    () => setState(() => _currentScreen = 'reportProblem'),
                  ),
                  _buildNavItemWithColorIcon(
                    _translate('active_issues'),
                    _translate('active_issues_desc'),
                    Icons.local_fire_department,
                    const Color(0xFFFF5252),
                    const Color(0xFFFFEBEE),
                    () => setState(() => _currentScreen = 'activeIssues'),
                  ),
                  _buildNavItemWithColorIcon(
                    _translate('history'),
                    _translate('history_desc'),
                    Icons.history,
                    const Color(0xFF9C27B0),
                    const Color(0xFFF3E5F5),
                    () => setState(() => _currentScreen = 'history'),
                  ),
                  _buildNavItemWithColorIcon(
                    _translate('team'),
                    _translate('team_desc'),
                    Icons.people,
                    const Color(0xFF2196F3),
                    const Color(0xFFE3F2FD),
                    () => setState(() => _currentScreen = 'team'),
                  ),
                  _buildNavItemWithColorIcon(
                    _translate('machine_categories'),
                    _translate('machine_categories_desc'),
                    Icons.settings,
                    const Color(0xFFFF9800),
                    const Color(0xFFFFF3E0),
                    () => setState(() => _currentScreen = 'machineCategories'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSupplierPartsScreen(Map<String, String> currentRoom) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          _buildAppHeader('Supplier Management', 'Manage suppliers and search parts', onBack: () {
            setState(() {
              _currentScreen = 'roomSelection';
            });
          }),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Search Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Text('🔍', style: TextStyle(fontSize: 24)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Search Parts Across All Suppliers',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _partSearchController,
                              decoration: InputDecoration(
                                hintText: 'Enter part number (e.g., P-1001)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: AppColors.inputBackground,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Search feature coming soon!')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(100, 56),
                            ),
                            child: const Text('Search'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Bulk Upload Parts Section - NEW FEATURE!
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: const [
                                Text('⚡', style: TextStyle(fontSize: 24)),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Bulk Upload Parts (One Shot)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _addPartRowToBulk,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Row', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add multiple parts with quantities and photos all at once',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 20),

                      // Bulk parts table
                      if (_bulkParts.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.cardBorder, style: BorderStyle.solid),
                          ),
                          child: Center(
                            child: Column(
                              children: const [
                                Icon(Icons.inventory_2, size: 48, color: AppColors.textSecondary),
                                SizedBox(height: 12),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'Click "Add Part Row" to start adding parts',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Column(
                          children: [
                            ...List.generate(_bulkParts.length, (index) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.inputBackground,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Part ${index + 1}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => _removePartRowFromBulk(index),
                                          icon: const Icon(Icons.delete, color: AppColors.error),
                                          tooltip: 'Remove this part',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            decoration: const InputDecoration(
                                              labelText: 'Part Number *',
                                              hintText: 'e.g., P-1001',
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                _bulkParts[index]['partNumber'] = value;
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextField(
                                            decoration: const InputDecoration(
                                              labelText: 'Part Name *',
                                              hintText: 'e.g., Bearing 6205',
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                _bulkParts[index]['partName'] = value;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            decoration: const InputDecoration(
                                              labelText: 'Quantity *',
                                              hintText: '0',
                                              border: OutlineInputBorder(),
                                            ),
                                            keyboardType: TextInputType.number,
                                            onChanged: (value) {
                                              setState(() {
                                                _bulkParts[index]['quantity'] = value;
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextField(
                                            decoration: const InputDecoration(
                                              labelText: 'Price (USD) *',
                                              hintText: '0.00',
                                              border: OutlineInputBorder(),
                                            ),
                                            keyboardType: TextInputType.number,
                                            onChanged: (value) {
                                              setState(() {
                                                _bulkParts[index]['price'] = value;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      value: _bulkParts[index]['category'],
                                      decoration: const InputDecoration(
                                        labelText: 'Category',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'Bearings', child: Text('Bearings')),
                                        DropdownMenuItem(value: 'Motors', child: Text('Motors')),
                                        DropdownMenuItem(value: 'Hydraulics', child: Text('Hydraulics')),
                                        DropdownMenuItem(value: 'Electrical', child: Text('Electrical')),
                                        DropdownMenuItem(value: 'Mechanical', child: Text('Mechanical')),
                                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _bulkParts[index]['category'] = value ?? 'Bearings';
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    InkWell(
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Photo upload feature coming soon!')),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.cardBorder, width: 2, style: BorderStyle.solid),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            Icon(Icons.photo_camera, size: 20, color: AppColors.textSecondary),
                                            SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                'Click to upload photos',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors.textSecondary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _submitBulkParts,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Submit All ${_bulkParts.length} Parts',
                                style: const TextStyle(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Suppliers Overview
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              '📦 Registered Suppliers (0)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Add Supplier feature coming soon!')),
                              );
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Click a supplier to view their inventory',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Center(
                          child: Column(
                            children: const [
                              Icon(Icons.business, size: 64, color: AppColors.textSecondary),
                              SizedBox(height: 16),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'No suppliers registered yet',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(height: 8),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Click "Add Supplier" to get started',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textDisabled,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
      ],
      ),
    );
  }

  Widget _buildQualityLabScreen(Map<String, String> currentRoom) {
    return Column(
      children: [
        _buildAppHeader('Quality Control LAB', 'Bacteria diagnostics & defect analysis', onBack: () {
          setState(() {
            _currentScreen = 'roomSelection';
          });
        }),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🧪 New Quality Report',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Report product defects and get diagnostic advice',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Quality report form
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 500;

                      return Column(
                        children: [
                          // Row 1: Machine Type & Defect Type
                          if (isNarrow) ...[
                            DropdownButtonFormField<String>(
                              value: _labMachineType,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Machine Type *',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: '', child: Text('Select machine')),
                                DropdownMenuItem(value: 'Filling Machine A', child: Text('Filling Machine A')),
                                DropdownMenuItem(value: 'Filling Machine B', child: Text('Filling Machine B')),
                                DropdownMenuItem(value: 'Pasteurizer Unit 1', child: Text('Pasteurizer Unit 1')),
                                DropdownMenuItem(value: 'Pasteurizer Unit 2', child: Text('Pasteurizer Unit 2')),
                                DropdownMenuItem(value: 'Packaging Line 1', child: Text('Packaging Line 1')),
                                DropdownMenuItem(value: 'Packaging Line 2', child: Text('Packaging Line 2')),
                                DropdownMenuItem(value: 'Storage Tank A', child: Text('Storage Tank A')),
                                DropdownMenuItem(value: 'Storage Tank B', child: Text('Storage Tank B')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _labMachineType = value == '' ? null : value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _labDefectType,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Defect Type *',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: '', child: Text('Select defect type')),
                                DropdownMenuItem(value: 'Blow', child: Text('Blow (Gas production)')),
                                DropdownMenuItem(value: 'Curdle', child: Text('Curdle (Coagulation)')),
                                DropdownMenuItem(value: 'Both', child: Text('Both (Blow & Curdle)')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _labDefectType = value == '' ? null : value;
                                });
                              },
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _labMachineType,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Machine Type *',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: '', child: Text('Select machine')),
                                      DropdownMenuItem(value: 'Filling Machine A', child: Text('Filling Machine A')),
                                      DropdownMenuItem(value: 'Filling Machine B', child: Text('Filling Machine B')),
                                      DropdownMenuItem(value: 'Pasteurizer Unit 1', child: Text('Pasteurizer Unit 1')),
                                      DropdownMenuItem(value: 'Pasteurizer Unit 2', child: Text('Pasteurizer Unit 2')),
                                      DropdownMenuItem(value: 'Packaging Line 1', child: Text('Packaging Line 1')),
                                      DropdownMenuItem(value: 'Packaging Line 2', child: Text('Packaging Line 2')),
                                      DropdownMenuItem(value: 'Storage Tank A', child: Text('Storage Tank A')),
                                      DropdownMenuItem(value: 'Storage Tank B', child: Text('Storage Tank B')),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _labMachineType = value == '' ? null : value;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _labDefectType,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Defect Type *',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: '', child: Text('Select defect type')),
                                      DropdownMenuItem(value: 'Blow', child: Text('Blow (Gas production)')),
                                      DropdownMenuItem(value: 'Curdle', child: Text('Curdle (Coagulation)')),
                                      DropdownMenuItem(value: 'Both', child: Text('Both (Blow & Curdle)')),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _labDefectType = value == '' ? null : value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Row 2: Bacteria Type & Batch Number
                          if (isNarrow) ...[
                            DropdownButtonFormField<String>(
                              value: _labBacteriaType,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Bacteria Type *',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: '',
                                  child: Text(
                                    'Select bacteria type',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    softWrap: false,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Clostridium',
                                  child: Text(
                                    'Clostridium (Anaerobic spore-former)',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    softWrap: false,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Bacillus',
                                  child: Text(
                                    'Bacillus (Aerobic spore-former)',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    softWrap: false,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Coliform',
                                  child: Text(
                                    'Coliform bacteria',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    softWrap: false,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Lactobacillus',
                                  child: Text(
                                    'Lactobacillus (Lactic acid bacteria)',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    softWrap: false,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Yeast',
                                  child: Text(
                                    'Yeast contamination',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    softWrap: false,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Mold',
                                  child: Text(
                                    'Mold contamination',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    softWrap: false,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Unknown',
                                  child: Text(
                                    'Unknown / Not tested yet',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    softWrap: false,
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _labBacteriaType = value == '' ? null : value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _labBatchNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Batch Number',
                                hintText: 'e.g., BATCH-2024-001',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _labBacteriaType,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Bacteria Type *',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: '',
                                        child: Text(
                                          'Select bacteria type',
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          softWrap: false,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Clostridium',
                                        child: Text(
                                          'Clostridium (Anaerobic spore-former)',
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          softWrap: false,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Bacillus',
                                        child: Text(
                                          'Bacillus (Aerobic spore-former)',
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          softWrap: false,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Coliform',
                                        child: Text(
                                          'Coliform bacteria',
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          softWrap: false,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Lactobacillus',
                                        child: Text(
                                          'Lactobacillus (Lactic acid bacteria)',
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          softWrap: false,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Yeast',
                                        child: Text(
                                          'Yeast contamination',
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          softWrap: false,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Mold',
                                        child: Text(
                                          'Mold contamination',
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          softWrap: false,
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Unknown',
                                        child: Text(
                                          'Unknown / Not tested yet',
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          softWrap: false,
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _labBacteriaType = value == '' ? null : value;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: _labBatchNumberController,
                                    decoration: const InputDecoration(
                                      labelText: 'Batch Number',
                                      hintText: 'e.g., BATCH-2024-001',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Row 3: Defect Packs, Total Packs, Defect Rate
                          if (isNarrow) ...[
                            TextField(
                              controller: _labDefectPacksController,
                              decoration: const InputDecoration(
                                labelText: 'Defect Packs *',
                                hintText: '0',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) => _calculateDefectRate(),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _labTotalPacksController,
                              decoration: const InputDecoration(
                                labelText: 'Total Packs *',
                                hintText: '0',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) => _calculateDefectRate(),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              decoration: InputDecoration(
                                labelText: 'Defect Rate (%)',
                                hintText: '0.00%',
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: AppColors.inputBackground,
                              ),
                              readOnly: true,
                              controller: TextEditingController(text: '$_labDefectRate%'),
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _labDefectPacksController,
                                    decoration: const InputDecoration(
                                      labelText: 'Defect Packs *',
                                      hintText: '0',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) => _calculateDefectRate(),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: _labTotalPacksController,
                                    decoration: const InputDecoration(
                                      labelText: 'Total Packs *',
                                      hintText: '0',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) => _calculateDefectRate(),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: 'Defect Rate (%)',
                                      hintText: '0.00%',
                                      border: const OutlineInputBorder(),
                                      filled: true,
                                      fillColor: AppColors.inputBackground,
                                    ),
                                    readOnly: true,
                                    controller: TextEditingController(text: '$_labDefectRate%'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Detailed Description
                          TextField(
                            controller: _labDescriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Detailed Description',
                              hintText: 'Describe the defect symptoms, appearance, timing, etc...',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),

                          // File Upload Area
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Attach Photos/Documents',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('File upload feature coming soon!')),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.inputBackground,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.cardBorder, width: 2, style: BorderStyle.solid),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text('📎', style: TextStyle(fontSize: 24)),
                                      SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Click to attach photos or documents',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'JPG, PNG, PDF (Max 10MB each)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Submit Button
                          ElevatedButton(
                            onPressed: _submitLabReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Submit for Diagnosis'),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Diagnostic Results (shown after submission)
                if (_showDiagnosticResults) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '🔬 Diagnostic Analysis',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showDiagnosticResults = false;
                                  _diagnosticContent = '';
                                });
                              },
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _diagnosticContent,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Previous Lab Reports
                Text(
                  '📋 Previous Lab Reports (0)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Center(
                    child: Column(
                      children: const [
                        Icon(Icons.science, size: 64, color: AppColors.textSecondary),
                        SizedBox(height: 16),
                        Text(
                          'No lab reports yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptirvaSupportScreen(Map<String, String> currentRoom) {
    return Column(
      children: [
        _buildAppHeader('Optirva Support Services', 'Remote support, on-site service & TPMS maintenance', onBack: () {
          setState(() {
            _currentScreen = 'roomSelection';
          });
        }),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🛠️ New Service Request',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Request technical support for your machines',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Support type selection
                Text(
                  'Support Type *',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSupportTypeCard('🌐', 'Remote Support', 'Online troubleshooting'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSupportTypeCard('👨‍🔧', 'On-Site Support', 'Engineer visit'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSupportTypeCard('⚙️', 'TPMS Service', 'Machine maintenance'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Machine type dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Tetra Pak Machine Type *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'a1', child: Text('Tetra Pak A1')),
                    DropdownMenuItem(value: 'a3_speed', child: Text('Tetra Pak A3/Speed')),
                    DropdownMenuItem(value: 'a3_flex', child: Text('Tetra Pak A3/Flex')),
                    DropdownMenuItem(value: 'pasteurizer', child: Text('Tetra Pak Pasteurizer')),
                    DropdownMenuItem(value: 'uht', child: Text('Tetra Pak UHT System')),
                  ],
                  onChanged: (value) {},
                ),
                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Submit Service Request feature coming soon!')),
                    );
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Submit Service Request'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSupportTypeCard(String emoji, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Static constant for Tetra Pak machine types with optgroups
  static const List<Map<String, dynamic>> _tetraPakMachineTypes = [
    {
      'group': '🏭 Aseptic Filling Machines',
      'options': [
        'Tetra Pak A1',
        'Tetra Pak A3/Speed',
        'Tetra Pak A3/Flex',
        'Tetra Pak A3/Compact Flex',
        'Tetra Pak A6',
        'Tetra Pak D/Flex',
        'Tetra Pak E3/Speed',
        'Tetra Pak E/Flex',
      ],
    },
    {
      'group': '📦 Aseptic Carton Packages',
      'options': [
        'Tetra Brik Aseptic',
        'Tetra Classic Aseptic',
        'Tetra Evero Aseptic',
        'Tetra Fino Aseptic',
        'Tetra Gemina Aseptic',
        'Tetra Prisma Aseptic',
        'Tetra Wedge Aseptic',
      ],
    },
    {
      'group': '🥛 Chilled Products',
      'options': [
        'Tetra Brik (Chilled)',
        'Tetra Rex (Gable Top)',
        'Tetra Stelo Aseptic',
        'Tetra Top',
      ],
    },
    {
      'group': '🍨 Specialty Packaging',
      'options': [
        'Tetra Recart (Retort)',
        'Tetra Therm Aseptic (Ice Cream)',
      ],
    },
    {
      'group': '🔥 Processing - Heat Treatment',
      'options': [
        'Tetra Pak Pasteurizer',
        'Tetra Pak UHT System (Direct)',
        'Tetra Pak UHT (Indirect)',
        'Tetra Therm Aseptic VTIS',
        'Tetra Spiraflo (Tubular Heat Exchanger)',
        'Tetra Pak Plate Heat Exchanger',
      ],
    },
    {
      'group': '⚙️ Processing - Separation & Mixing',
      'options': [
        'Tetra Pak Homogenizer',
        'Tetra Pak Separator',
        'Tetra Pak Mixer (Static)',
        'Tetra Pak Blender',
        'Tetra Almix (Powder Mixing)',
        'Tetra Lactenso (Evaporator)',
      ],
    },
    {
      'group': '🧼 Cleaning & Sterilization',
      'options': [
        'Tetra Pak CIP System',
        'Tetra Pak SIP System',
        'Tetra Pak CIP/SIP Combined',
      ],
    },
    {
      'group': '🗄️ Storage & Tanks',
      'options': [
        'Tetra Pak Buffer Tank',
        'Tetra Pak Storage Tank (Aseptic)',
        'Tetra Pak Balance Tank',
        'Tetra Pak Surge Tank',
      ],
    },
    {
      'group': '🚚 Material Handling',
      'options': [
        'Tetra Pak Conveyor System',
        'Tetra Pak Accumulator',
        'Tetra Pak Distribution Unit',
        'Tetra Pak Case Loader',
        'Tetra Pak Palletizer',
      ],
    },
    {
      'group': '🔬 Quality Control',
      'options': [
        'Laboratory Equipment',
        'Leak Detector',
      ],
    },
    {
      'group': '💡 Utilities & Support',
      'options': [
        'Boiler/Steam Generator',
        'Chiller/Cooling System',
        'Air Compressor',
        'Water Treatment System',
      ],
    },
  ];

  // Helper method to build machine type dropdown items with optgroups
  List<DropdownMenuItem<String>> _buildMachineTypeDropdown({bool includeAllOption = false}) {
    final List<DropdownMenuItem<String>> items = [];

    // Add "All Machine Types" or "Select..." option
    if (includeAllOption) {
      items.add(
        const DropdownMenuItem(
          value: '',
          child: Text('All Machine Types'),
        ),
      );
    } else {
      items.add(
        const DropdownMenuItem(
          value: '',
          child: Text('Select Tetra Pak machine type'),
        ),
      );
    }

    // Add grouped options
    for (var group in _tetraPakMachineTypes) {
      // Add a disabled group header
      items.add(
        DropdownMenuItem(
          enabled: false,
          value: null,
          child: Padding(
            padding: const EdgeInsets.only(left: 0),
            child: Text(
              group['group'] as String,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );

      // Add options in this group
      final options = group['options'] as List<String>;
      for (var option in options) {
        items.add(
          DropdownMenuItem(
            value: option,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(option),
            ),
          ),
        );
      }
    }

    // Add "Other Tetra Pak Equipment" at the end
    items.add(
      const DropdownMenuItem(
        value: 'Other Tetra Pak Equipment',
        child: Text('Other Tetra Pak Equipment'),
      ),
    );

    return items;
  }

  // Submit handler for marketplace listing
  void _submitMarketplaceListing() {
    // Validate required fields
    if (_marketplaceMachineType == null || _marketplaceMachineType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a machine type'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_marketplaceRunningHoursController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter running hours'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_marketplaceCondition == null || _marketplaceCondition!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select machine condition'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_marketplaceServiceStatus == null || _marketplaceServiceStatus!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select service status'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_marketplaceTetrapakService == null || _marketplaceTetrapakService!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Tetrapak service contract status'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_marketplacePriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a price'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_marketplaceDescriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a machine description'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Machine listing submitted successfully!'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 3),
      ),
    );

    // Clear the form
    setState(() {
      _marketplaceMachineType = null;
      _marketplacePackageVolume = null;
      _marketplaceYearController.clear();
      _marketplaceRunningHoursController.clear();
      _marketplaceCondition = null;
      _marketplaceServiceStatus = null;
      _marketplaceTetrapakService = null;
      _marketplacePriceController.clear();
      _marketplaceDescriptionController.clear();
      _marketplaceLocationController.clear();
      _marketplaceContactController.clear();
      _marketplaceFiles = [];
    });
  }

  Widget _buildMachineMarketplaceScreen(Map<String, String> currentRoom) {
    return Column(
      children: [
        // Header
        _buildAppHeader('Machine Marketplace', 'Buy & sell industrial equipment', onBack: () {
          setState(() {
            _currentScreen = 'roomSelection';
          });
        }),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Role Selector Section
                Text(
                  '👤 I am a:',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Supplier Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _marketplaceRole = 'supplier';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _marketplaceRole == 'supplier'
                                ? AppColors.primary.withOpacity(0.1)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _marketplaceRole == 'supplier'
                                  ? AppColors.primary
                                  : AppColors.cardBorder,
                              width: _marketplaceRole == 'supplier' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: const [
                              Text('🏭', style: TextStyle(fontSize: 48)),
                              SizedBox(height: 8),
                              Text(
                                'Supplier',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'List machines for sale',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Customer Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _marketplaceRole = 'customer';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _marketplaceRole == 'customer'
                                ? AppColors.primary.withOpacity(0.1)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _marketplaceRole == 'customer'
                                  ? AppColors.primary
                                  : AppColors.cardBorder,
                              width: _marketplaceRole == 'customer' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: const [
                              Text('🛒', style: TextStyle(fontSize: 48)),
                              SizedBox(height: 8),
                              Text(
                                'Customer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Search & buy machines',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Customer Search Section
                if (_marketplaceRole == 'customer') ...[
                  Text(
                    '🔍 Find Your Perfect Machine',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Search through available industrial equipment',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search Filters Grid (2x2)
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Machine Type',
                            border: OutlineInputBorder(),
                          ),
                          value: _searchMachineType,
                          items: _buildMachineTypeDropdown(includeAllOption: true),
                          onChanged: (value) {
                            setState(() {
                              _searchMachineType = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Package Volume',
                            border: OutlineInputBorder(),
                          ),
                          value: _searchPackageVolume,
                          items: const [
                            DropdownMenuItem(value: '', child: Text('All Volumes')),
                            DropdownMenuItem(value: '200ml', child: Text('200 ml')),
                            DropdownMenuItem(value: '250ml', child: Text('250 ml')),
                            DropdownMenuItem(value: '330ml', child: Text('330 ml')),
                            DropdownMenuItem(value: '500ml', child: Text('500 ml')),
                            DropdownMenuItem(value: '1000ml', child: Text('1000 ml (1 Liter)')),
                            DropdownMenuItem(value: '1500ml', child: Text('1500 ml (1.5 Liter)')),
                            DropdownMenuItem(value: '2000ml', child: Text('2000 ml (2 Liter)')),
                            DropdownMenuItem(value: 'Multiple', child: Text('Multiple Volumes')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _searchPackageVolume = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Price Range (USD)',
                            border: OutlineInputBorder(),
                          ),
                          value: _searchPriceRange,
                          items: const [
                            DropdownMenuItem(value: '', child: Text('Any Price')),
                            DropdownMenuItem(value: '0-50000', child: Text('\$0 - \$50,000')),
                            DropdownMenuItem(value: '50000-100000', child: Text('\$50,000 - \$100,000')),
                            DropdownMenuItem(value: '100000-250000', child: Text('\$100,000 - \$250,000')),
                            DropdownMenuItem(value: '250000-500000', child: Text('\$250,000 - \$500,000')),
                            DropdownMenuItem(value: '500000+', child: Text('\$500,000+')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _searchPriceRange = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Condition',
                            border: OutlineInputBorder(),
                          ),
                          value: _searchCondition,
                          items: const [
                            DropdownMenuItem(value: '', child: Text('Any Condition')),
                            DropdownMenuItem(value: 'Excellent', child: Text('Excellent')),
                            DropdownMenuItem(value: 'Very Good', child: Text('Very Good')),
                            DropdownMenuItem(value: 'Good', child: Text('Good')),
                            DropdownMenuItem(value: 'Fair', child: Text('Fair')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _searchCondition = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Search Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Searching for machines...'),
                            backgroundColor: AppColors.info,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '🔍 Search Machines',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],

                // Supplier Listing Form Section
                if (_marketplaceRole == 'supplier') ...[
                  Text(
                    '🏪 List Your Machine',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sell your industrial equipment to verified buyers',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Machine Details Row 1
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Tetra Pak Machine Type *',
                            border: OutlineInputBorder(),
                            hintText: 'Select machine type',
                          ),
                          value: _marketplaceMachineType,
                          items: _buildMachineTypeDropdown(includeAllOption: false),
                          onChanged: (value) {
                            setState(() {
                              _marketplaceMachineType = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Package Volume',
                            border: OutlineInputBorder(),
                          ),
                          value: _marketplacePackageVolume,
                          items: const [
                            DropdownMenuItem(value: 'Not Applicable', child: Text('Not Applicable')),
                            DropdownMenuItem(value: '200ml', child: Text('200 ml')),
                            DropdownMenuItem(value: '250ml', child: Text('250 ml')),
                            DropdownMenuItem(value: '330ml', child: Text('330 ml')),
                            DropdownMenuItem(value: '500ml', child: Text('500 ml')),
                            DropdownMenuItem(value: '1000ml', child: Text('1000 ml (1 Liter)')),
                            DropdownMenuItem(value: '1500ml', child: Text('1500 ml (1.5 Liter)')),
                            DropdownMenuItem(value: '2000ml', child: Text('2000 ml (2 Liter)')),
                            DropdownMenuItem(value: 'Multiple', child: Text('Multiple Volumes')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _marketplacePackageVolume = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Machine Details Row 2
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _marketplaceYearController,
                          decoration: const InputDecoration(
                            labelText: 'Year of Manufacture',
                            border: OutlineInputBorder(),
                            hintText: 'e.g., 2018',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _marketplaceRunningHoursController,
                          decoration: const InputDecoration(
                            labelText: 'Running Hours *',
                            border: OutlineInputBorder(),
                            hintText: 'e.g., 15000',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Condition & Service Row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Machine Condition *',
                            border: OutlineInputBorder(),
                          ),
                          value: _marketplaceCondition,
                          items: const [
                            DropdownMenuItem(value: '', child: Text('Select condition')),
                            DropdownMenuItem(
                              value: 'Excellent',
                              child: Text('⭐ Excellent - Like new, minimal wear'),
                            ),
                            DropdownMenuItem(
                              value: 'Very Good',
                              child: Text('✅ Very Good - Well maintained'),
                            ),
                            DropdownMenuItem(
                              value: 'Good',
                              child: Text('👍 Good - Normal wear, fully functional'),
                            ),
                            DropdownMenuItem(
                              value: 'Fair',
                              child: Text('⚠️ Fair - Needs minor repairs'),
                            ),
                            DropdownMenuItem(
                              value: 'Needs Repair',
                              child: Text('🔧 Needs Repair - Not operational'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _marketplaceCondition = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Service Status *',
                            border: OutlineInputBorder(),
                          ),
                          value: _marketplaceServiceStatus,
                          items: const [
                            DropdownMenuItem(value: '', child: Text('Select service status')),
                            DropdownMenuItem(
                              value: 'Up to Date',
                              child: Text('✅ Up to Date - Recently serviced'),
                            ),
                            DropdownMenuItem(
                              value: 'Overdue',
                              child: Text('⚠️ Overdue - Service needed'),
                            ),
                            DropdownMenuItem(
                              value: 'Never Serviced',
                              child: Text('❌ Never Serviced'),
                            ),
                            DropdownMenuItem(
                              value: 'Unknown',
                              child: Text('❓ Unknown'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _marketplaceServiceStatus = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tetrapak Service Contract & Price Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tetrapak Service Contract? *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  RadioListTile<String>(
                                    title: const Text('✅ Yes - Tetrapak servicing'),
                                    value: 'Yes',
                                    groupValue: _marketplaceTetrapakService,
                                    onChanged: (value) {
                                      setState(() {
                                        _marketplaceTetrapakService = value;
                                      });
                                    },
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                  ),
                                  RadioListTile<String>(
                                    title: const Text('❌ No - Third-party or self-serviced'),
                                    value: 'No',
                                    groupValue: _marketplaceTetrapakService,
                                    onChanged: (value) {
                                      setState(() {
                                        _marketplaceTetrapakService = value;
                                      });
                                    },
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _marketplacePriceController,
                              decoration: const InputDecoration(
                                labelText: 'Price (USD) *',
                                border: OutlineInputBorder(),
                                hintText: 'e.g., 50000',
                                helperText: 'Enter your asking price or "Negotiable"',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Machine Description
                  TextFormField(
                    controller: _marketplaceDescriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Machine Description *',
                      border: OutlineInputBorder(),
                      hintText: 'Describe the machine: features, specifications, reason for selling, any additional information...',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),

                  // Location & Contact Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _marketplaceLocationController,
                          decoration: const InputDecoration(
                            labelText: 'Location (Country/City)',
                            border: OutlineInputBorder(),
                            hintText: 'e.g., Germany, Munich',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _marketplaceContactController,
                          decoration: const InputDecoration(
                            labelText: 'Supplier Contact',
                            border: OutlineInputBorder(),
                            hintText: 'Your company name',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Photos & Videos Upload
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attach Photos & Videos *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('File upload functionality will be implemented'),
                              backgroundColor: AppColors.info,
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.cardBorder,
                              style: BorderStyle.solid,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: const [
                              Text(
                                '📸',
                                style: TextStyle(fontSize: 48),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Click to upload machine photos & videos',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'JPG, PNG, MP4, MOV (Max 50MB per file)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitMarketplaceListing,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '🏪 List Machine for Sale',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.cardBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.info,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            const Text(
              '→',
              style: TextStyle(
                fontSize: 20,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Nav item with emoji (matching HTML demo exactly)
  Widget _buildNavItemWithEmoji(String title, String subtitle, String emoji, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.cardBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Emoji container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            const Text(
              '→',
              style: TextStyle(
                fontSize: 20,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Nav item with colored icon (professional design matching demo)
  Widget _buildNavItemWithColorIcon(String title, String subtitle, IconData icon, Color iconColor, Color backgroundColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor.withOpacity(0.2),
              backgroundColor.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: iconColor.withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: iconColor.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Vibrant gradient icon container
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    iconColor,
                    iconColor.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: iconColor.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Colored arrow
            Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: iconColor.withOpacity(0.6),
            ),
          ],
        ),
      ),
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
        return Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: true,
          body: Column(
            children: [
              _buildAppHeader('Active Issues', 'Current open tickets', onBack: () {
                setState(() {
                  _currentScreen = 'roomDetail';
                });
              }),
              // Search and Filter Section
              Flexible(
                flex: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                      const SizedBox(height: 10),

                      // Quick Filter Buttons
                      SizedBox(
                        height: 36,
                        child: SingleChildScrollView(
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
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ticketProvider.isLoading
                      ? ListView.builder(
                          itemCount: 5,
                          itemBuilder: (context, index) => const TicketCardSkeleton(),
                        )
                      : _buildTicketsList(ticketProvider),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              setState(() {
                _currentScreen = 'roomDetail';
              });
            },
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Create Ticket',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
          onEditPressed: () => _editTicket(ticket['id']),
          currentUserId: Provider.of<AuthProvider>(context, listen: false).currentUser?.id,
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
      'creator_id': ticket.creatorId,
      'assigneeId': ticket.assigneeId,
      'resolverId': ticket.resolverId,
      'resolution': ticket.resolution,
      'rating': ticket.rating,
      'fishbone_analysis': ticket.fishboneAnalysis,
      'update_history': ticket.updateHistory,
      'last_updated_at': ticket.lastUpdatedAt?.toIso8601String(),
      'expires_at': ticket.expiresAt.toIso8601String(),
      'machine_id': ticket.machineId,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
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
                    size: 18,
                  ),
                ),
              ),
            if (onBack != null) const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textOnPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textOnPrimary.withOpacity(0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Profile Avatar Button
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.currentUser;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentScreen = 'profile';
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFFF0F0F0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.textOnPrimary,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: user.avatarUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: Text(
                                  user.initials,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Text(
                                  user.initials,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                user?.initials ?? '?',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            // Animated OPTIRVA logo
            const SizedBox(
              width: 50,
              height: 50,
              child: _OptirvaHeaderLogo(),
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

    return GestureDetector(
      onTap: () => _openTicketChat(ticket['id']),
      child: Container(
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
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.touch_app,
                  size: 16,
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  'Tap to view full details & attachments',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
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
            _buildAppHeader(
              _editingTicketId != null ? 'Edit Problem Report' : 'Report Problem',
              _editingTicketId != null ? 'Update ticket information' : 'Submit machine issues',
              onBack: () {
                setState(() {
                  _editingTicketId = null;
                  _currentScreen = 'roomDetail';
                });
              },
            ),
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

                    // Fishbone Diagram - Root Cause Analysis
                    FishboneDiagram(
                      initialAnalysis: _fishboneAnalysis,
                      onAnalysisChanged: (analysis) {
                        setState(() {
                          _fishboneAnalysis = analysis;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

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
                            : Text(
                                _editingTicketId != null ? 'Update Problem Report' : 'Submit Problem Report',
                                style: const TextStyle(
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
      onBack: () {
        setState(() {
          _currentScreen = 'activeIssues';
          _selectedTicketId = null;
        });
      },
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
                          color: index == _urgencyRating - 1
                              ? _getUrgencyColor(index + 1)
                              : Colors.grey.withOpacity(0.3),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          urgencyLabels[index],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: index == _urgencyRating - 1
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

  Color _getRoomColor(String roomId) {
    switch (roomId) {
      case 'room1':
        return const Color(0xFF2196F3); // Vibrant Blue
      case 'room2':
        return const Color(0xFF4CAF50); // Vibrant Green
      case 'room3':
        return const Color(0xFFFF9800); // Vibrant Orange
      case 'room4':
        return const Color(0xFF9C27B0); // Vibrant Purple
      case 'room5':
        return const Color(0xFFE91E63); // Vibrant Pink/Magenta
      default:
        return const Color(0xFF607D8B); // Blue Grey
    }
  }

  IconData _getRoomIcon(String roomId) {
    switch (roomId) {
      case 'room1':
        return Icons.factory;
      case 'room2':
        return Icons.warehouse;
      case 'room3':
        return Icons.precision_manufacturing;
      case 'room4':
        return Icons.settings_suggest;
      default:
        return Icons.business;
    }
  }

  Widget _getRoomLogo(String roomId) {
    switch (roomId) {
      case 'room1':
        return const _Room1Logo();
      case 'room2':
        return const _Room2Logo();
      case 'room3':
        return const _Room3Logo();
      case 'room4':
        return const _Room4Logo();
      case 'room5':
        return const _Room5Logo();
      default:
        return const _Room1Logo();
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive grid columns based on screen width
                    final width = constraints.maxWidth;
                    final crossAxisCount = width > 600 ? 3 : 2;
                    final itemWidth = (width - (16 * (crossAxisCount + 1))) / crossAxisCount;
                    final itemHeight = itemWidth * 1.15;

                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: itemWidth / itemHeight,
                      ),
                  itemCount: _getRooms().length,
                  itemBuilder: (context, index) {
                    final room = _getRooms()[index];
                    final roomColor = _getRoomColor(room['id']!);
                    final roomIcon = _getRoomIcon(room['id']!);

                    return GestureDetector(
                      onTap: () {
                        // Special handling for Job Marketplace
                        if (room['id'] == 'job_marketplace') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const JobMarketplaceScreen(),
                            ),
                          );
                        } else {
                          setState(() {
                            _selectedRoom = room['id']!;
                            _currentScreen = 'roomDetail';
                          });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              roomColor.withOpacity(0.08),
                              roomColor.withOpacity(0.02),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: roomColor.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: roomColor.withOpacity(0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Vibrant icon container with gradient
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      roomColor,
                                      roomColor.withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: roomColor.withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: _getRoomLogo(room['id']!),
                              ),
                              const SizedBox(height: 10),
                              // Room name with gradient text effect
                              Text(
                                room['name']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: roomColor.withOpacity(0.9),
                                  letterSpacing: 0.3,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Room description/subtitle
                              Text(
                                room['description'] ?? 'Machine Management',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              // Status badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: roomColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: roomColor.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 12,
                                      color: roomColor,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Active',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: roomColor,
                                        fontWeight: FontWeight.bold,
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
                  },
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

// Animated OPTIRVA logo for header
class _OptirvaHeaderLogo extends StatefulWidget {
  const _OptirvaHeaderLogo();

  @override
  State<_OptirvaHeaderLogo> createState() => _OptirvaHeaderLogoState();
}

class _OptirvaHeaderLogoState extends State<_OptirvaHeaderLogo> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _lineController;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _lineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _pulseController, _lineController]),
      builder: (context, child) {
        return CustomPaint(
          painter: _OptirvaHeaderLogoPainter(
            rotation: _rotationController.value,
            pulse: _pulseController.value,
            linePhase: _lineController.value,
          ),
        );
      },
    );
  }
}

class _OptirvaHeaderLogoPainter extends CustomPainter {
  final double rotation;
  final double pulse;
  final double linePhase;

  _OptirvaHeaderLogoPainter({
    required this.rotation,
    required this.pulse,
    required this.linePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final earthRadius = size.width * 0.28;

    // Vibrant Earth gradient (cyan to deep blue)
    final earthGradient = RadialGradient(
      center: const Alignment(-0.35, -0.35),
      colors: [
        const Color(0xFF00E5FF), // Vibrant cyan highlight
        const Color(0xFF00B8D4), // Light cyan-blue
        const Color(0xFF0091EA), // Medium blue
        const Color(0xFF01579B), // Deep blue shadow
      ],
      stops: const [0.0, 0.25, 0.6, 1.0],
    );

    final earthPaint = Paint()
      ..shader = earthGradient.createShader(Rect.fromCircle(center: center, radius: earthRadius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, earthRadius, earthPaint);

    // Emerald continents
    final continentPaint = Paint()
      ..color = const Color(0xFF00E676)
      ..style = PaintingStyle.fill;

    _drawContinents(canvas, center, earthRadius, continentPaint);

    // Network nodes with vibrant multi-colors
    final goldGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [const Color(0xFFFFEB3B), const Color(0xFFFFC107), const Color(0xFFFF6F00)],
      stops: const [0.0, 0.5, 1.0],
    );

    final emeraldGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [const Color(0xFF69F0AE), const Color(0xFF00E676), const Color(0xFF00C853)],
      stops: const [0.0, 0.5, 1.0],
    );

    final purpleGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [const Color(0xFFE040FB), const Color(0xFFD500F9), const Color(0xFFAA00FF)],
      stops: const [0.0, 0.5, 1.0],
    );

    final orangeGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [const Color(0xFFFFB74D), const Color(0xFFFF9800), const Color(0xFFE65100)],
      stops: const [0.0, 0.5, 1.0],
    );

    final nodeGradients = [goldGradient, emeraldGradient, purpleGradient, orangeGradient, goldGradient, emeraldGradient, purpleGradient, orangeGradient];
    final nodeColors = [
      const Color(0xFFFFC107),
      const Color(0xFF00E676),
      const Color(0xFFE040FB),
      const Color(0xFFFF9800),
      const Color(0xFFFFC107),
      const Color(0xFF00E676),
      const Color(0xFFE040FB),
      const Color(0xFFFF9800)
    ];
    final lineColors = [
      const Color(0xFFFF9800),
      const Color(0xFF00E676),
      const Color(0xFFE040FB),
      const Color(0xFFFF9800),
      const Color(0xFFFFC107),
      const Color(0xFF00E676),
      const Color(0xFFE040FB),
      const Color(0xFFFFC107)
    ];

    final nodeRadius = earthRadius * 1.4;
    final nodePositions = [
      Offset(math.cos(0 * math.pi / 4), math.sin(0 * math.pi / 4)),
      Offset(math.cos(1 * math.pi / 4), math.sin(1 * math.pi / 4)),
      Offset(math.cos(2 * math.pi / 4), math.sin(2 * math.pi / 4)),
      Offset(math.cos(3 * math.pi / 4), math.sin(3 * math.pi / 4)),
      Offset(math.cos(4 * math.pi / 4), math.sin(4 * math.pi / 4)),
      Offset(math.cos(5 * math.pi / 4), math.sin(5 * math.pi / 4)),
      Offset(math.cos(6 * math.pi / 4), math.sin(6 * math.pi / 4)),
      Offset(math.cos(7 * math.pi / 4), math.sin(7 * math.pi / 4)),
    ];

    // Draw connection lines with node-specific colors
    for (int i = 0; i < nodePositions.length; i++) {
      final pos = nodePositions[i];
      final nodePos = center.translate(pos.dx * nodeRadius, pos.dy * nodeRadius);

      final linePaint = Paint()
        ..color = lineColors[i].withOpacity(0.5 + (linePhase * 0.4))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawLine(center, nodePos, linePaint);
    }

    // Draw nodes with multi-color gradients
    for (int i = 0; i < nodePositions.length; i++) {
      final pos = nodePositions[i];
      final nodePos = center.translate(pos.dx * nodeRadius, pos.dy * nodeRadius);

      final node3DPaint = Paint()
        ..shader = nodeGradients[i].createShader(Rect.fromCircle(center: nodePos, radius: 3.5))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(nodePos, 3.5, node3DPaint);

      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.9)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(nodePos.translate(-1, -1), 1.5, highlightPaint);
    }

    // Rainbow pulse waves
    final pulseRadius1 = earthRadius * (1.0 + (pulse * 0.5));
    final pulseOpacity1 = 1.0 - pulse;

    final wavePaint1 = Paint()
      ..color = const Color(0xFFFFC107).withOpacity(pulseOpacity1 * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, pulseRadius1, wavePaint1);

    final pulsePhase2 = (pulse + 0.33) % 1.0;
    final pulseRadius2 = earthRadius * (1.0 + (pulsePhase2 * 0.5));
    final pulseOpacity2 = 1.0 - pulsePhase2;

    final wavePaint2 = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(pulseOpacity2 * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, pulseRadius2, wavePaint2);

    final purpleOpacity = linePhase > 0.5 ? (1 - linePhase) : linePhase;
    final wavePaint3 = Paint()
      ..color = const Color(0xFFE040FB).withOpacity(purpleOpacity * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, earthRadius * (1.0 + (linePhase * 0.35)), wavePaint3);

    // Cyan orbital ring
    final ringPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final ringRadius = earthRadius * 1.8;
    final ringRect = Rect.fromCircle(center: center, radius: ringRadius);
    canvas.drawArc(ringRect, -math.pi / 4, math.pi, false, ringPaint);
  }

  void _drawContinents(Canvas canvas, Offset center, double radius, Paint paint) {
    final northAmerica = Path()
      ..moveTo(center.dx - radius * 0.4, center.dy - radius * 0.3)
      ..quadraticBezierTo(center.dx - radius * 0.3, center.dy - radius * 0.5, center.dx - radius * 0.1, center.dy - radius * 0.4)
      ..quadraticBezierTo(center.dx, center.dy - radius * 0.2, center.dx - radius * 0.2, center.dy)
      ..quadraticBezierTo(center.dx - radius * 0.5, center.dy + radius * 0.1, center.dx - radius * 0.4, center.dy - radius * 0.3);

    canvas.drawPath(northAmerica, paint);

    final africa = Path()
      ..moveTo(center.dx + radius * 0.1, center.dy - radius * 0.1)
      ..quadraticBezierTo(center.dx + radius * 0.3, center.dy - radius * 0.2, center.dx + radius * 0.35, center.dy)
      ..quadraticBezierTo(center.dx + radius * 0.3, center.dy + radius * 0.4, center.dx + radius * 0.15, center.dy + radius * 0.3)
      ..quadraticBezierTo(center.dx, center.dy + radius * 0.2, center.dx + radius * 0.1, center.dy - radius * 0.1);

    canvas.drawPath(africa, paint);
  }

  @override
  bool shouldRepaint(_OptirvaHeaderLogoPainter oldDelegate) {
    return oldDelegate.rotation != rotation || oldDelegate.pulse != pulse || oldDelegate.linePhase != linePhase;
  }
}

// Professional animated logo for Room 1
class _Room1Logo extends StatefulWidget {
  const _Room1Logo();

  @override
  State<_Room1Logo> createState() => _Room1LogoState();
}

class _Room1LogoState extends State<_Room1Logo> with TickerProviderStateMixin {
  late AnimationController _gearController;
  late AnimationController _pulseController;
  late AnimationController _smokeController;

  @override
  void initState() {
    super.initState();

    // Gear rotation animation
    _gearController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Pulsing lights animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Smoke animation
    _smokeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _gearController.dispose();
    _pulseController.dispose();
    _smokeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_gearController, _pulseController, _smokeController]),
      builder: (context, child) {
        return CustomPaint(
          size: const Size(48, 48),
          painter: _Room1LogoPainter(
            gearRotation: _gearController.value,
            pulsePhase: _pulseController.value,
            smokePhase: _smokeController.value,
          ),
        );
      },
    );
  }
}

class _Room1LogoPainter extends CustomPainter {
  final double gearRotation;
  final double pulsePhase;
  final double smokePhase;

  _Room1LogoPainter({
    required this.gearRotation,
    required this.pulsePhase,
    required this.smokePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Background circle with vibrant gradient (support theme)
    final bgGradient = RadialGradient(
      colors: [
        const Color(0xFF0091EA), // Bright cyan blue
        const Color(0xFF0277BD), // Medium blue
        const Color(0xFF01579B), // Deep blue
      ],
    );
    final bgPaint = Paint()
      ..shader = bgGradient.createShader(Rect.fromCircle(center: center, radius: size.width * 0.45));
    canvas.drawCircle(center, size.width * 0.38, bgPaint);

    // Animated pulse rings (showing active support)
    for (int i = 0; i < 3; i++) {
      final phase = (pulsePhase + (i * 0.33)) % 1.0;
      final pulseRadius = size.width * 0.3 + (phase * size.width * 0.15);
      final pulseOpacity = (1.0 - phase) * 0.4;

      final pulsePaint = Paint()
        ..color = const Color(0xFF00E5FF).withOpacity(pulseOpacity)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(center, pulseRadius, pulsePaint);
    }

    // Draw headset (customer support icon)
    _drawHeadset(canvas, center, size);

    // Support message bubbles floating around
    _drawSupportBubble(canvas, size, 0.2, 0.3, smokePhase, const Color(0xFF00E676));
    _drawSupportBubble(canvas, size, 0.75, 0.35, (smokePhase + 0.33) % 1.0, const Color(0xFFFFC107));
    _drawSupportBubble(canvas, size, 0.85, 0.65, (smokePhase + 0.66) % 1.0, const Color(0xFFFF6D00));
  }

  void _drawHeadset(Canvas canvas, Offset center, Size size) {
    final headsetPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * 0.05
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Headband arc
    final headbandRect = Rect.fromCenter(
      center: center,
      width: size.width * 0.45,
      height: size.height * 0.45,
    );
    canvas.drawArc(headbandRect, -math.pi * 0.8, math.pi * 1.6, false, headsetPaint);

    // Left earpiece
    final leftEarCenter = Offset(center.dx - size.width * 0.2, center.dy + size.height * 0.05);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: leftEarCenter, width: size.width * 0.12, height: size.height * 0.18),
        Radius.circular(size.width * 0.03),
      ),
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFFFFFFFF), const Color(0xFFE0E0E0)],
        ).createShader(Rect.fromCenter(center: leftEarCenter, width: size.width * 0.12, height: size.height * 0.18)),
    );

    // Right earpiece
    final rightEarCenter = Offset(center.dx + size.width * 0.2, center.dy + size.height * 0.05);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: rightEarCenter, width: size.width * 0.12, height: size.height * 0.18),
        Radius.circular(size.width * 0.03),
      ),
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFFFFFFFF), const Color(0xFFE0E0E0)],
        ).createShader(Rect.fromCenter(center: rightEarCenter, width: size.width * 0.12, height: size.height * 0.18)),
    );

    // Microphone boom
    final micPath = Path()
      ..moveTo(leftEarCenter.dx + size.width * 0.04, leftEarCenter.dy + size.height * 0.08)
      ..quadraticBezierTo(
        leftEarCenter.dx + size.width * 0.1,
        leftEarCenter.dy + size.height * 0.2,
        leftEarCenter.dx + size.width * 0.15,
        leftEarCenter.dy + size.height * 0.22,
      );

    canvas.drawPath(
      micPath,
      Paint()
        ..color = Colors.white
        ..strokeWidth = size.width * 0.04
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Microphone
    canvas.drawCircle(
      Offset(leftEarCenter.dx + size.width * 0.15, leftEarCenter.dy + size.height * 0.22),
      size.width * 0.04,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFF00E676), const Color(0xFF00C853)],
        ).createShader(Rect.fromCircle(
          center: Offset(leftEarCenter.dx + size.width * 0.15, leftEarCenter.dy + size.height * 0.22),
          radius: size.width * 0.04,
        )),
    );
  }

  void _drawSupportBubble(Canvas canvas, Size size, double xRatio, double yRatio, double phase, Color color) {
    final floatOffset = math.sin(phase * 2 * math.pi) * size.height * 0.05;
    final bubbleCenter = Offset(size.width * xRatio, (size.height * yRatio) + floatOffset);
    final bubbleSize = size.width * 0.08 + (math.sin(phase * 2 * math.pi) * size.width * 0.02);

    // Bubble glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(bubbleCenter, bubbleSize + 2, glowPaint);

    // Bubble
    final bubblePaint = Paint()
      ..shader = RadialGradient(
        colors: [color.withOpacity(0.9), color.withOpacity(0.6)],
      ).createShader(Rect.fromCircle(center: bubbleCenter, radius: bubbleSize));
    canvas.drawCircle(bubbleCenter, bubbleSize, bubblePaint);

    // Check mark inside bubble
    final checkPath = Path()
      ..moveTo(bubbleCenter.dx - bubbleSize * 0.3, bubbleCenter.dy)
      ..lineTo(bubbleCenter.dx - bubbleSize * 0.1, bubbleCenter.dy + bubbleSize * 0.3)
      ..lineTo(bubbleCenter.dx + bubbleSize * 0.4, bubbleCenter.dy - bubbleSize * 0.3);

    canvas.drawPath(
      checkPath,
      Paint()
        ..color = Colors.white
        ..strokeWidth = size.width * 0.015
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_Room1LogoPainter oldDelegate) {
    return oldDelegate.gearRotation != gearRotation ||
        oldDelegate.pulsePhase != pulsePhase ||
        oldDelegate.smokePhase != smokePhase;
  }
}
// Professional animated logo for Room 2 - Warehouse/Logistics
class _Room2Logo extends StatefulWidget {
  const _Room2Logo();

  @override
  State<_Room2Logo> createState() => _Room2LogoState();
}

class _Room2LogoState extends State<_Room2Logo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(70, 70),
          painter: _Room2LogoPainter(_controller.value),
        );
      },
    );
  }
}

class _Room2LogoPainter extends CustomPainter {
  final double animationValue;

  _Room2LogoPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Background gradient circle
    final bgGradient = RadialGradient(
      colors: [
        const Color(0xFF4CAF50).withOpacity(0.2),
        const Color(0xFF4CAF50).withOpacity(0.05),
      ],
    );
    canvas.drawCircle(
      center,
      size.width * 0.4,
      Paint()..shader = bgGradient.createShader(Rect.fromCircle(center: center, radius: size.width * 0.4)),
    );

    // Draw stacked supply boxes (3D isometric style)
    _drawSupplyBox(canvas, size, center.dx - size.width * 0.15, center.dy + size.height * 0.1, 0.2, const Color(0xFF00E676), const Color(0xFF00C853));
    _drawSupplyBox(canvas, size, center.dx + size.width * 0.05, center.dy + size.height * 0.15, 0.18, const Color(0xFF00C853), const Color(0xFF00BFA5));
    _drawSupplyBox(canvas, size, center.dx - size.width * 0.05, center.dy - size.height * 0.05, 0.22, const Color(0xFF00E676), const Color(0xFF4CAF50));

    // Draw gear/cog icon for parts
    _drawPartsGear(canvas, size, center.dx + size.width * 0.18, center.dy - size.height * 0.15, size.width * 0.12);

    // Animated inventory scan line
    final scanY = center.dy - size.height * 0.3 + (animationValue * size.height * 0.7);
    final scanPaint = Paint()
      ..color = const Color(0xFF00E676).withOpacity(0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width * 0.2, scanY),
      Offset(size.width * 0.8, scanY),
      scanPaint,
    );
  }

  void _drawSupplyBox(Canvas canvas, Size size, double x, double y, double boxSize, Color topColor, Color sideColor) {
    final boxWidth = size.width * boxSize;
    final boxHeight = size.height * boxSize * 0.6;
    final depth = boxWidth * 0.3;

    // Front face
    final frontRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, boxWidth, boxHeight),
      Radius.circular(size.width * 0.02),
    );
    canvas.drawRRect(
      frontRect,
      Paint()
        ..shader = LinearGradient(
          colors: [topColor, sideColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(frontRect.outerRect),
    );

    // Top face (isometric)
    final topPath = Path()
      ..moveTo(x, y)
      ..lineTo(x + boxWidth, y)
      ..lineTo(x + boxWidth + depth * 0.5, y - depth * 0.5)
      ..lineTo(x + depth * 0.5, y - depth * 0.5)
      ..close();
    canvas.drawPath(
      topPath,
      Paint()..color = topColor.withOpacity(0.9),
    );

    // Side face (isometric)
    final sidePath = Path()
      ..moveTo(x + boxWidth, y)
      ..lineTo(x + boxWidth, y + boxHeight)
      ..lineTo(x + boxWidth + depth * 0.5, y + boxHeight - depth * 0.5)
      ..lineTo(x + boxWidth + depth * 0.5, y - depth * 0.5)
      ..close();
    canvas.drawPath(
      sidePath,
      Paint()..color = sideColor.withOpacity(0.7),
    );

    // Box lines/tape
    canvas.drawLine(
      Offset(x + boxWidth * 0.2, y),
      Offset(x + boxWidth * 0.2, y + boxHeight),
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(x, y + boxHeight * 0.5),
      Offset(x + boxWidth, y + boxHeight * 0.5),
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..strokeWidth = 2,
    );
  }

  void _drawPartsGear(Canvas canvas, Size size, double x, double y, double radius) {
    final gearPath = Path();
    final teeth = 8;
    final toothDepth = radius * 0.2;

    for (int i = 0; i < teeth; i++) {
      final angle1 = (i * 2 * math.pi / teeth);
      final angle2 = ((i + 0.3) * 2 * math.pi / teeth);
      final angle3 = ((i + 0.7) * 2 * math.pi / teeth);
      final angle4 = ((i + 1) * 2 * math.pi / teeth);

      if (i == 0) {
        gearPath.moveTo(x + radius * math.cos(angle1), y + radius * math.sin(angle1));
      }
      gearPath.lineTo(x + radius * math.cos(angle1), y + radius * math.sin(angle1));
      gearPath.lineTo(x + (radius + toothDepth) * math.cos(angle2), y + (radius + toothDepth) * math.sin(angle2));
      gearPath.lineTo(x + (radius + toothDepth) * math.cos(angle3), y + (radius + toothDepth) * math.sin(angle3));
      gearPath.lineTo(x + radius * math.cos(angle4), y + radius * math.sin(angle4));
    }
    gearPath.close();

    canvas.drawPath(
      gearPath,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFFFFC107), const Color(0xFFFF9800)],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: radius + toothDepth)),
    );

    // Center hole
    canvas.drawCircle(
      Offset(x, y),
      radius * 0.4,
      Paint()..color = const Color(0xFF757575),
    );
  }

  @override
  bool shouldRepaint(_Room2LogoPainter oldDelegate) => oldDelegate.animationValue != animationValue;
}

class _Room3Logo extends StatefulWidget {
  const _Room3Logo();
  @override
  State<_Room3Logo> createState() => _Room3LogoState();
}

class _Room3LogoState extends State<_Room3Logo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _controller, builder: (context, child) {
      return CustomPaint(size: const Size(70, 70), painter: _Room3LogoPainter(_controller.value));
    });
  }
}

class _Room3LogoPainter extends CustomPainter {
  final double animationValue;
  _Room3LogoPainter(this.animationValue);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Modern square with rounded corners (like modern tech logo)
    final squareRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: size.width * 0.7, height: size.height * 0.7),
      Radius.circular(size.width * 0.15),
    );

    // Vibrant orange/amber gradient
    final squareGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [const Color(0xFFFF9100), const Color(0xFFFF6D00), const Color(0xFFDD2C00)],
    );

    final squarePaint = Paint()
      ..shader = squareGradient.createShader(squareRect.outerRect);

    canvas.drawRRect(squareRect, squarePaint);

    // Modern "P" for Precision
    final pPath = Path();
    final pLeft = center.dx - size.width * 0.15;
    final pTop = center.dy - size.height * 0.25;
    final pBottom = center.dy + size.height * 0.25;
    final pMid = center.dy - size.height * 0.05;

    // Vertical line of P
    pPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(pLeft, pTop, pLeft + size.width * 0.08, pBottom),
      Radius.circular(size.width * 0.04),
    ));

    // Circular part of P
    final pCircle = Path();
    pCircle.addOval(Rect.fromCenter(
      center: Offset(pLeft + size.width * 0.04, center.dy - size.height * 0.12),
      width: size.width * 0.28,
      height: size.height * 0.26,
    ));

    final pCircleInner = Path();
    pCircleInner.addOval(Rect.fromCenter(
      center: Offset(pLeft + size.width * 0.04, center.dy - size.height * 0.12),
      width: size.width * 0.18,
      height: size.height * 0.16,
    ));

    pPath.addPath(pCircle, Offset.zero);
    pPath.addPath(pCircleInner, Offset.zero);
    pPath.fillType = PathFillType.evenOdd;

    final pPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawPath(pPath, pPaint);

    // Animated rotating arc
    final arcPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final arcRect = Rect.fromCircle(center: center, radius: size.width * 0.42);
    canvas.drawArc(
      arcRect,
      animationValue * 2 * math.pi,
      math.pi / 2,
      false,
      arcPaint,
    );
  }
  @override
  bool shouldRepaint(_Room3LogoPainter oldDelegate) => oldDelegate.animationValue != animationValue;
}

class _Room4Logo extends StatefulWidget {
  const _Room4Logo();
  @override
  State<_Room4Logo> createState() => _Room4LogoState();
}

class _Room4LogoState extends State<_Room4Logo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _controller, builder: (context, child) {
      return CustomPaint(size: const Size(70, 70), painter: _Room4LogoPainter(_controller.value));
    });
  }
}

class _Room4LogoPainter extends CustomPainter {
  final double animationValue;
  _Room4LogoPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Modern circle with vibrant purple gradient
    final circlePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFAB47BC), // Vibrant Purple
          const Color(0xFF9C27B0), // Deep Purple
          const Color(0xFF8E24AA), // Darker Purple
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.4));
    canvas.drawCircle(center, size.width * 0.35, circlePaint);

    // Modern "A" for Automation
    final aPath = Path();

    // Left leg of A
    final leftTop = Offset(center.dx - size.width * 0.15, center.dy - size.height * 0.2);
    final leftBottom = Offset(center.dx - size.width * 0.22, center.dy + size.height * 0.22);
    final leftInnerBottom = Offset(center.dx - size.width * 0.15, center.dy + size.height * 0.22);
    final leftInnerTop = Offset(center.dx - size.width * 0.1, center.dy - size.height * 0.08);

    aPath.moveTo(leftTop.dx, leftTop.dy);
    aPath.lineTo(leftBottom.dx, leftBottom.dy);
    aPath.lineTo(leftInnerBottom.dx, leftInnerBottom.dy);
    aPath.lineTo(leftInnerTop.dx, leftInnerTop.dy);
    aPath.close();

    // Right leg of A
    final rightTop = Offset(center.dx + size.width * 0.15, center.dy - size.height * 0.2);
    final rightBottom = Offset(center.dx + size.width * 0.22, center.dy + size.height * 0.22);
    final rightInnerBottom = Offset(center.dx + size.width * 0.15, center.dy + size.height * 0.22);
    final rightInnerTop = Offset(center.dx + size.width * 0.1, center.dy - size.height * 0.08);

    aPath.moveTo(rightTop.dx, rightTop.dy);
    aPath.lineTo(rightInnerTop.dx, rightInnerTop.dy);
    aPath.lineTo(rightInnerBottom.dx, rightInnerBottom.dy);
    aPath.lineTo(rightBottom.dx, rightBottom.dy);
    aPath.close();

    // Crossbar of A
    final crossbarPath = Path();
    crossbarPath.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          center.dx - size.width * 0.15,
          center.dy + size.height * 0.02,
          center.dx + size.width * 0.15,
          center.dy + size.height * 0.1,
        ),
        Radius.circular(size.width * 0.02),
      ),
    );

    final aPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(aPath, aPaint);
    canvas.drawPath(crossbarPath, aPaint);

    // Animated orbiting dots
    for (int i = 0; i < 3; i++) {
      final angle = (animationValue * 2 * math.pi) + (i * 2 * math.pi / 3);
      final orbitRadius = size.width * 0.42;
      final dotX = center.dx + math.cos(angle) * orbitRadius;
      final dotY = center.dy + math.sin(angle) * orbitRadius;

      final dotPaint = Paint()
        ..color = Colors.white.withOpacity(0.9)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dotX, dotY), size.width * 0.04, dotPaint);

      // Glow effect on dots
      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(dotX, dotY), size.width * 0.06, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_Room4LogoPainter oldDelegate) => oldDelegate.animationValue != animationValue;
}

// Professional animated logo for Room 5 - Machine Market (Tetra Pak Equipment)
class _Room5Logo extends StatefulWidget {
  const _Room5Logo();
  @override
  State<_Room5Logo> createState() => _Room5LogoState();
}

class _Room5LogoState extends State<_Room5Logo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _controller, builder: (context, child) {
      return CustomPaint(size: const Size(70, 70), painter: _Room5LogoPainter(_controller.value));
    });
  }
}

class _Room5LogoPainter extends CustomPainter {
  final double animationValue;
  _Room5LogoPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Background gradient (pink/magenta)
    final bgGradient = RadialGradient(
      colors: [
        const Color(0xFFE91E63).withOpacity(0.15),
        const Color(0xFFE91E63).withOpacity(0.05),
      ],
    );
    final bgPaint = Paint()..shader = bgGradient.createShader(Rect.fromCircle(center: center, radius: size.width * 0.45));
    canvas.drawCircle(center, size.width * 0.4, bgPaint);

    // Draw marketplace storefront
    _drawStorefront(canvas, size);

    // Draw product grid cards
    _drawProductGrid(canvas, size);

    // Draw shopping cart icon
    _drawShoppingCart(canvas, size);

    // Draw price tags
    _drawPriceTags(canvas, size);
  }

  void _drawStorefront(Canvas canvas, Size size) {
    // Storefront awning with gradient
    final awningGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFE91E63), // Vibrant Pink
        const Color(0xFFC2185B), // Darker Pink
      ],
    );

    final awningPath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.2)
      ..lineTo(size.width * 0.85, size.height * 0.2)
      ..lineTo(size.width * 0.8, size.height * 0.3)
      ..lineTo(size.width * 0.2, size.height * 0.3)
      ..close();

    final awningPaint = Paint()
      ..shader = awningGradient.createShader(awningPath.getBounds());
    canvas.drawPath(awningPath, awningPaint);

    // Awning stripes (classic shop design)
    for (int i = 0; i < 3; i++) {
      final stripeX = size.width * (0.3 + i * 0.2);
      canvas.drawLine(
        Offset(stripeX, size.height * 0.2),
        Offset(stripeX - size.width * 0.03, size.height * 0.3),
        Paint()
          ..color = Colors.white.withOpacity(0.4)
          ..strokeWidth = size.width * 0.04,
      );
    }

    // Store sign with text-like representation
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.3,
          size.height * 0.08,
          size.width * 0.4,
          size.height * 0.09,
        ),
        Radius.circular(size.width * 0.02),
      ),
      Paint()..color = const Color(0xFFFFFFFF),
    );

    // Store sign details (simulating "MARKET" text)
    final signDetailPaint = Paint()
      ..color = const Color(0xFFE91E63)
      ..strokeWidth = size.width * 0.01
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(size.width * (0.35 + i * 0.1), size.height * 0.12),
        Offset(size.width * (0.4 + i * 0.1), size.height * 0.12),
        signDetailPaint,
      );
    }
  }

  void _drawProductGrid(Canvas canvas, Size size) {
    // 2x2 product card grid representing marketplace catalog
    final cardPositions = [
      Offset(size.width * 0.22, size.height * 0.4),
      Offset(size.width * 0.52, size.height * 0.4),
      Offset(size.width * 0.22, size.height * 0.6),
      Offset(size.width * 0.52, size.height * 0.6),
    ];

    for (int i = 0; i < cardPositions.length; i++) {
      _drawProductCard(canvas, size, cardPositions[i], i);
    }
  }

  void _drawProductCard(Canvas canvas, Size size, Offset position, int index) {
    // Product card background with subtle shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: position.translate(size.width * 0.01, size.height * 0.01),
          width: size.width * 0.22,
          height: size.height * 0.16,
        ),
        Radius.circular(size.width * 0.015),
      ),
      shadowPaint,
    );

    // Card background
    final cardGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white,
        const Color(0xFFF5F5F5),
      ],
    );

    final cardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: position,
        width: size.width * 0.22,
        height: size.height * 0.16,
      ),
      Radius.circular(size.width * 0.015),
    );

    canvas.drawRRect(
      cardRect,
      Paint()..shader = cardGradient.createShader(cardRect.outerRect),
    );

    // Product icon (simple machine silhouette)
    final iconSize = size.width * 0.08;
    final iconRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: position.translate(0, -size.height * 0.03),
        width: iconSize,
        height: iconSize,
      ),
      Radius.circular(iconSize * 0.2),
    );

    canvas.drawRRect(
      iconRect,
      Paint()..color = const Color(0xFFE91E63).withOpacity(0.3),
    );

    // Product detail lines (simulating description)
    for (int i = 0; i < 2; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            position.dx - size.width * 0.08,
            position.dy + size.height * (0.02 + i * 0.025),
            size.width * 0.16,
            size.height * 0.008,
          ),
          Radius.circular(size.width * 0.002),
        ),
        Paint()..color = const Color(0xFFBDBDBD),
      );
    }

    // Animated highlight on active card
    final highlightIndex = (animationValue * 4).floor() % 4;
    if (index == highlightIndex) {
      canvas.drawRRect(
        cardRect,
        Paint()
          ..color = const Color(0xFFE91E63).withOpacity(0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _drawShoppingCart(Canvas canvas, Size size) {
    final cartCenter = Offset(size.width * 0.78, size.height * 0.78);

    // Cart body (trapezoid shape)
    final cartPath = Path()
      ..moveTo(cartCenter.dx - size.width * 0.06, cartCenter.dy - size.height * 0.06)
      ..lineTo(cartCenter.dx + size.width * 0.06, cartCenter.dy - size.height * 0.06)
      ..lineTo(cartCenter.dx + size.width * 0.04, cartCenter.dy)
      ..lineTo(cartCenter.dx - size.width * 0.04, cartCenter.dy)
      ..close();

    final cartGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFE91E63),
        const Color(0xFFC2185B),
      ],
    );

    canvas.drawPath(
      cartPath,
      Paint()..shader = cartGradient.createShader(cartPath.getBounds()),
    );

    // Cart wheels
    for (int i = 0; i < 2; i++) {
      canvas.drawCircle(
        Offset(cartCenter.dx - size.width * 0.02 + i * size.width * 0.04, cartCenter.dy + size.height * 0.04),
        size.width * 0.015,
        Paint()..color = const Color(0xFF616161),
      );
    }

    // Cart handle
    canvas.drawLine(
      cartCenter.translate(-size.width * 0.06, -size.height * 0.06),
      cartCenter.translate(-size.width * 0.09, -size.height * 0.09),
      Paint()
        ..color = const Color(0xFFE91E63)
        ..strokeWidth = size.width * 0.015
        ..strokeCap = StrokeCap.round,
    );

    // Animated shopping badge (item count)
    final badgePulse = 0.8 + (math.sin(animationValue * 4 * math.pi) * 0.2);
    canvas.drawCircle(
      cartCenter.translate(size.width * 0.05, -size.height * 0.08),
      size.width * 0.025 * badgePulse,
      Paint()..color = const Color(0xFF4CAF50),
    );
  }

  void _drawPriceTags(Canvas canvas, Size size) {
    // Animated floating price tags
    final tagYOffset = math.sin(animationValue * 2 * math.pi) * size.height * 0.02;

    _drawPriceTag(canvas, size, Offset(size.width * 0.15, size.height * 0.35 + tagYOffset), const Color(0xFFFFC107));
    _drawPriceTag(canvas, size, Offset(size.width * 0.82, size.height * 0.5 - tagYOffset), const Color(0xFF4CAF50));
  }

  void _drawPriceTag(Canvas canvas, Size size, Offset position, Color color) {
    // Tag body
    final tagPath = Path()
      ..moveTo(position.dx, position.dy)
      ..lineTo(position.dx + size.width * 0.08, position.dy)
      ..lineTo(position.dx + size.width * 0.1, position.dy + size.height * 0.03)
      ..lineTo(position.dx + size.width * 0.08, position.dy + size.height * 0.06)
      ..lineTo(position.dx, position.dy + size.height * 0.06)
      ..lineTo(position.dx + size.width * 0.015, position.dy + size.height * 0.03)
      ..close();

    canvas.drawPath(
      tagPath,
      Paint()..color = color,
    );

    // Tag hole
    canvas.drawCircle(
      position.translate(size.width * 0.02, size.height * 0.03),
      size.width * 0.008,
      Paint()..color = Colors.white,
    );

    // Price symbol ($)
    final dollarPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * 0.004
      ..style = PaintingStyle.stroke;

    final dollarPath = Path()
      ..moveTo(position.dx + size.width * 0.05, position.dy + size.height * 0.02)
      ..lineTo(position.dx + size.width * 0.07, position.dy + size.height * 0.02)
      ..moveTo(position.dx + size.width * 0.06, position.dy + size.height * 0.015)
      ..lineTo(position.dx + size.width * 0.06, position.dy + size.height * 0.045);

    canvas.drawPath(dollarPath, dollarPaint);
  }

  @override
  bool shouldRepaint(_Room5LogoPainter oldDelegate) => oldDelegate.animationValue != animationValue;
}
