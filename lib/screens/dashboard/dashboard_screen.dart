import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../config/colors.dart';
import '../../config/constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'Dashboard',
    'Active Tickets',
    'All Tickets',
    'Machines',
    'Team',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          // User Profile
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton<String>(
                icon: CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    authProvider.userInitials,
                    style: const TextStyle(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        const Icon(Icons.person),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              authProvider.userDisplayName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${authProvider.userPoints} points • ${authProvider.userRole}',
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
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings),
                        SizedBox(width: 8),
                        Text('Settings'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Sign Out', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  switch (value) {
                    case 'logout':
                      final confirmed = await _showLogoutDialog();
                      if (confirmed == true) {
                        await authProvider.signOut();
                      }
                      break;
                    case 'profile':
                      _showNotImplemented('Profile');
                      break;
                    case 'settings':
                      _showNotImplemented('Settings');
                      break;
                  }
                },
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          DashboardTab(),
          ActiveTicketsTab(),
          AllTicketsTab(),
          MachinesTab(),
          TeamTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Active',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'All Tickets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.precision_manufacturing),
            label: 'Machines',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Team',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex < 3 ? FloatingActionButton(
        onPressed: () => _showNotImplemented('Create Ticket'),
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  Future<bool?> _showLogoutDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showNotImplemented(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon! 🚀'),
        backgroundColor: AppColors.info,
      ),
    );
  }
}

// Dashboard Tab
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, TicketProvider>(
      builder: (context, authProvider, ticketProvider, child) {
        return RefreshIndicator(
          onRefresh: () async {
            await ticketProvider.refresh();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Message
                _buildWelcomeCard(authProvider),
                const SizedBox(height: 16),

                // Quick Stats
                _buildQuickStats(ticketProvider),
                const SizedBox(height: 16),

                // Recent Activity
                _buildRecentActivity(context, ticketProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard(AuthProvider authProvider) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, ${authProvider.currentUser?.firstName ?? 'User'}!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textOnPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have ${authProvider.userTicketsSolved} tickets solved with ${authProvider.userPoints} points earned',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textOnPrimary.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(TicketProvider ticketProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Open Tickets',
                '${ticketProvider.openTicketsCount}',
                Icons.assignment,
                AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'In Progress',
                '${ticketProvider.inProgressTicketsCount}',
                Icons.work,
                AppColors.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Resolved',
                '${ticketProvider.resolvedTicketsCount}',
                Icons.check_circle,
                AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Resolution Rate',
                '${ticketProvider.resolutionRate.toStringAsFixed(1)}%',
                Icons.trending_up,
                AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
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
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, TicketProvider ticketProvider) {
    final recentTickets = ticketProvider.tickets.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Tickets',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (recentTickets.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No tickets yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Create your first ticket to get started!',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...recentTickets.map((ticket) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.getPriorityColor(ticket.priority).withOpacity(0.2),
                child: Text(
                  ticket.priorityIcon,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              title: Text(
                ticket.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${ticket.machine?.name ?? 'Unknown Machine'} • ${ticket.ageDisplay}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.getTicketStatusColor(ticket.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ticket.statusDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTicketStatusColor(ticket.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ticket details coming soon! 🚀'),
                    backgroundColor: AppColors.info,
                  ),
                );
              },
            ),
          )),
      ],
    );
  }
}

// Placeholder tabs
class ActiveTicketsTab extends StatelessWidget {
  const ActiveTicketsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment, size: 64, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text(
            'Active Tickets',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Feature coming soon! 🚀',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class AllTicketsTab extends StatelessWidget {
  const AllTicketsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.list, size: 64, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text(
            'All Tickets',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Feature coming soon! 🚀',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class MachinesTab extends StatelessWidget {
  const MachinesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.precision_manufacturing, size: 64, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text(
            'Machines',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Feature coming soon! 🚀',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class TeamTab extends StatelessWidget {
  const TeamTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 64, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text(
            'Team & Leaderboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Feature coming soon! 🚀',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}