import 'package:flutter/material.dart';
import 'package:machine_manager_app/config/colors.dart';
import 'package:machine_manager_app/models/job_seeker_profile.dart';
import 'package:machine_manager_app/models/job_posting.dart';
import 'package:intl/intl.dart';

class JobMarketplaceScreen extends StatefulWidget {
  const JobMarketplaceScreen({super.key});

  @override
  State<JobMarketplaceScreen> createState() => _JobMarketplaceScreenState();
}

class _JobMarketplaceScreenState extends State<JobMarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sample data - replace with actual data from Supabase
  final List<JobSeekerProfile> _jobSeekers = [];
  final List<JobPosting> _jobPostings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Job Marketplace',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textOnPrimary,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Show filter dialog
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Show search
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.textOnPrimary,
          indicatorWeight: 3,
          labelColor: AppColors.textOnPrimary,
          unselectedLabelColor: AppColors.textOnPrimary.withOpacity(0.7),
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.work_outline),
              text: 'Find Jobs',
            ),
            Tab(
              icon: Icon(Icons.person_search),
              text: 'Find Talent',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildJobPostingsTab(),
          _buildJobSeekersTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            // Create job seeker profile
            _showCreateJobSeekerDialog();
          } else {
            // Create job posting
            _showCreateJobPostingDialog();
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: Text(
          _tabController.index == 0 ? 'Create Profile' : 'Post a Job',
        ),
      ),
    );
  }

  // Job Postings Tab (for job seekers looking for jobs)
  Widget _buildJobPostingsTab() {
    if (_jobPostings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.work_off,
        title: 'No Job Postings Yet',
        subtitle: 'Be the first company to post a job opportunity!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _jobPostings.length,
      itemBuilder: (context, index) {
        return _buildJobPostingCard(_jobPostings[index]);
      },
    );
  }

  // Job Seekers Tab (for companies looking for talent)
  Widget _buildJobSeekersTab() {
    if (_jobSeekers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_off,
        title: 'No Job Seekers Yet',
        subtitle: 'Be the first to create your professional profile!',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 900
            ? 3
            : MediaQuery.of(context).size.width > 600
                ? 2
                : 1,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _jobSeekers.length,
      itemBuilder: (context, index) {
        return _buildJobSeekerCard(_jobSeekers[index]);
      },
    );
  }

  Widget _buildJobPostingCard(JobPosting posting) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showJobPostingDetails(posting),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Header
              Row(
                children: [
                  // Company Logo
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.business,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Company Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          posting.companyName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${posting.location}, ${posting.country}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Bookmark button
                  IconButton(
                    icon: const Icon(Icons.bookmark_border),
                    onPressed: () {},
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Job Title
              Text(
                posting.jobTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Job Details
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChip(
                    Icons.work,
                    posting.jobTypeDisplay,
                    AppColors.primary,
                  ),
                  _buildChip(
                    Icons.schedule,
                    posting.employmentTypeDisplay,
                    AppColors.info,
                  ),
                  _buildChip(
                    Icons.trending_up,
                    posting.experienceLevelDisplay,
                    AppColors.warning,
                  ),
                  if (posting.remoteAllowed)
                    _buildChip(
                      Icons.home_work,
                      'Remote',
                      AppColors.success,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Salary Range
              if (posting.minSalary != null || posting.maxSalary != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.attach_money,
                        size: 18,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        posting.salaryRangeDisplay,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Required Skills
              if (posting.requiredSkills.isNotEmpty) ...[
                const Text(
                  'Required Skills:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: posting.requiredSkills.take(5).map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        skill,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),

              // Footer
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: posting.isExpiringSoon
                        ? AppColors.warning
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Deadline: ${DateFormat('MMM dd, yyyy').format(posting.applicationDeadline)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: posting.isExpiringSoon
                          ? AppColors.warning
                          : AppColors.textSecondary,
                      fontWeight: posting.isExpiringSoon
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${posting.openPositions} position${posting.openPositions > 1 ? 's' : ''}',
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
      ),
    );
  }

  Widget _buildJobSeekerCard(JobSeekerProfile seeker) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showJobSeekerDetails(seeker),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        seeker.fullName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                          seeker.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          seeker.jobTitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Experience and Level
              Row(
                children: [
                  Expanded(
                    child: _buildInfoTile(
                      Icons.work_history,
                      '${seeker.experienceYears} years',
                      'Experience',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoTile(
                      Icons.trending_up,
                      seeker.experienceLevelDisplay,
                      'Level',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Location and Nationality
              Row(
                children: [
                  const Icon(
                    Icons.flag,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    seeker.nationality,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (seeker.currentLocation != null) ...[
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        seeker.currentLocation!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // App Performance Metrics
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'App Performance',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetric(
                          Icons.stars,
                          '${seeker.appScore}',
                          'Points',
                        ),
                        _buildMetric(
                          Icons.check_circle,
                          '${seeker.ticketsSolved}',
                          'Solved',
                        ),
                        _buildMetric(
                          Icons.star,
                          seeker.averageRating.toStringAsFixed(1),
                          'Rating',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Skills
              if (seeker.skills.isNotEmpty) ...[
                const Text(
                  'Top Skills:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: seeker.skills.take(3).map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.border,
                        ),
                      ),
                      child: Text(
                        skill,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const Spacer(),

              // Availability Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: seeker.isAvailable
                      ? AppColors.successLight
                      : AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      seeker.isAvailable
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 14,
                      color: seeker.isAvailable
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      seeker.isAvailable
                          ? seeker.availabilityDisplay
                          : 'Not Available',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: seeker.isAvailable
                            ? AppColors.success
                            : AppColors.textSecondary,
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

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 100,
            color: AppColors.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showJobPostingDetails(JobPosting posting) {
    // TODO: Show detailed job posting dialog or navigate to details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View details for: ${posting.jobTitle}')),
    );
  }

  void _showJobSeekerDetails(JobSeekerProfile seeker) {
    // TODO: Show detailed job seeker profile dialog or navigate to details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View profile for: ${seeker.fullName}')),
    );
  }

  void _showCreateJobSeekerDialog() {
    // TODO: Navigate to job seeker profile creation screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create Job Seeker Profile (Coming Soon)')),
    );
  }

  void _showCreateJobPostingDialog() {
    // TODO: Navigate to job posting creation screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create Job Posting (Coming Soon)')),
    );
  }
}
