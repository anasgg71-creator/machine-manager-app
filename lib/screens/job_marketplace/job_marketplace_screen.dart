import 'package:flutter/material.dart';
import 'package:machine_manager_app/config/colors.dart';
import 'package:machine_manager_app/models/job_seeker_profile.dart';
import 'package:machine_manager_app/models/job_posting.dart';
import 'package:machine_manager_app/screens/job_marketplace/create_job_seeker_profile_screen.dart';
import 'package:machine_manager_app/screens/job_marketplace/create_job_posting_screen.dart';
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

  // Filter states for Find Jobs
  String? _selectedCountry;
  String? _selectedExperienceLevel;
  String? _selectedJobType;
  String? _selectedEmploymentType;
  bool _remoteOnly = false;
  double _minSalary = 0;
  double _maxSalary = 200000;
  String _searchQuery = '';
  String _sortBy = 'newest'; // newest, salary_high, salary_low, deadline
  final Set<String> _savedJobIds = {};

  // Filter states for Find Talent
  String? _selectedSeekerCountry;
  String? _selectedSeekerExperienceLevel;
  int _minExperienceYears = 0;
  int _maxExperienceYears = 30;
  String _seekerSearchQuery = '';
  bool _availableOnly = true;

  // Filter options
  final List<String> _popularCountries = [
    'United States',
    'United Kingdom',
    'Germany',
    'Canada',
    'France',
    'Australia',
  ];

  final List<String> _allCountries = [
    'Afghanistan',
    'Albania',
    'Algeria',
    'Andorra',
    'Angola',
    'Argentina',
    'Armenia',
    'Australia',
    'Austria',
    'Azerbaijan',
    'Bahamas',
    'Bahrain',
    'Bangladesh',
    'Barbados',
    'Belarus',
    'Belgium',
    'Belize',
    'Benin',
    'Bhutan',
    'Bolivia',
    'Bosnia and Herzegovina',
    'Botswana',
    'Brazil',
    'Brunei',
    'Bulgaria',
    'Burkina Faso',
    'Burundi',
    'Cambodia',
    'Cameroon',
    'Canada',
    'Cape Verde',
    'Central African Republic',
    'Chad',
    'Chile',
    'China',
    'Colombia',
    'Comoros',
    'Congo',
    'Costa Rica',
    'Croatia',
    'Cuba',
    'Cyprus',
    'Czech Republic',
    'Denmark',
    'Djibouti',
    'Dominica',
    'Dominican Republic',
    'East Timor',
    'Ecuador',
    'Egypt',
    'El Salvador',
    'Equatorial Guinea',
    'Eritrea',
    'Estonia',
    'Ethiopia',
    'Fiji',
    'Finland',
    'France',
    'Gabon',
    'Gambia',
    'Georgia',
    'Germany',
    'Ghana',
    'Greece',
    'Grenada',
    'Guatemala',
    'Guinea',
    'Guinea-Bissau',
    'Guyana',
    'Haiti',
    'Honduras',
    'Hungary',
    'Iceland',
    'India',
    'Indonesia',
    'Iran',
    'Iraq',
    'Ireland',
    'Israel',
    'Italy',
    'Ivory Coast',
    'Jamaica',
    'Japan',
    'Jordan',
    'Kazakhstan',
    'Kenya',
    'Kiribati',
    'Kuwait',
    'Kyrgyzstan',
    'Laos',
    'Latvia',
    'Lebanon',
    'Lesotho',
    'Liberia',
    'Libya',
    'Liechtenstein',
    'Lithuania',
    'Luxembourg',
    'Madagascar',
    'Malawi',
    'Malaysia',
    'Maldives',
    'Mali',
    'Malta',
    'Marshall Islands',
    'Mauritania',
    'Mauritius',
    'Mexico',
    'Micronesia',
    'Moldova',
    'Monaco',
    'Mongolia',
    'Montenegro',
    'Morocco',
    'Mozambique',
    'Myanmar',
    'Namibia',
    'Nauru',
    'Nepal',
    'Netherlands',
    'New Zealand',
    'Nicaragua',
    'Niger',
    'Nigeria',
    'North Korea',
    'North Macedonia',
    'Norway',
    'Oman',
    'Pakistan',
    'Palau',
    'Palestine',
    'Panama',
    'Papua New Guinea',
    'Paraguay',
    'Peru',
    'Philippines',
    'Poland',
    'Portugal',
    'Qatar',
    'Romania',
    'Russia',
    'Rwanda',
    'Saint Kitts and Nevis',
    'Saint Lucia',
    'Saint Vincent and the Grenadines',
    'Samoa',
    'San Marino',
    'Sao Tome and Principe',
    'Saudi Arabia',
    'Senegal',
    'Serbia',
    'Seychelles',
    'Sierra Leone',
    'Singapore',
    'Slovakia',
    'Slovenia',
    'Solomon Islands',
    'Somalia',
    'South Africa',
    'South Korea',
    'South Sudan',
    'Spain',
    'Sri Lanka',
    'Sudan',
    'Suriname',
    'Sweden',
    'Switzerland',
    'Syria',
    'Taiwan',
    'Tajikistan',
    'Tanzania',
    'Thailand',
    'Togo',
    'Tonga',
    'Trinidad and Tobago',
    'Tunisia',
    'Turkey',
    'Turkmenistan',
    'Tuvalu',
    'Uganda',
    'Ukraine',
    'United Arab Emirates',
    'United Kingdom',
    'United States',
    'Uruguay',
    'Uzbekistan',
    'Vanuatu',
    'Vatican City',
    'Venezuela',
    'Vietnam',
    'Yemen',
    'Zambia',
    'Zimbabwe',
  ];

  final List<String> _experienceLevels = [
    'Entry Level',
    'Mid Level',
    'Senior Level',
    'Expert Level',
  ];

  final List<String> _jobTypes = [
    'Engineer',
    'Technician',
    'Supervisor',
    'Manager',
    'Machine Operator',
  ];

  final List<String> _employmentTypes = [
    'Full Time',
    'Part Time',
    'Contract',
    'Temporary',
  ];

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
    // Dynamic colors based on active tab
    final talentGreen = Color(0xFF10B981); // Emerald green
    final isOnTalentTab = _tabController.index == 1;
    final activeColor = isOnTalentTab ? talentGreen : AppColors.primary;

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
        backgroundColor: activeColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              if (_tabController.index == 0) {
                _showJobFilters();
              } else {
                _showTalentFilters();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              if (_tabController.index == 0) {
                _showJobSearch();
              } else {
                _showTalentSearch();
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            setState(() {}); // Refresh to update colors
          },
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
        backgroundColor: activeColor,
        icon: const Icon(Icons.add),
        label: Text(
          _tabController.index == 0 ? 'Create Profile' : 'Post a Job',
        ),
      ),
    );
  }

  // Job Postings Tab (for job seekers looking for jobs)
  Widget _buildJobPostingsTab() {
    // Apply filters
    List<JobPosting> filteredJobs = _jobPostings.where((job) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!job.jobTitle.toLowerCase().contains(query) &&
            !job.companyName.toLowerCase().contains(query) &&
            !job.jobDescription.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Country filter
      if (_selectedCountry != null && job.country != _selectedCountry) {
        return false;
      }

      // Experience level filter
      if (_selectedExperienceLevel != null) {
        final levelMap = {
          'Entry Level': 'entry',
          'Mid Level': 'mid',
          'Senior Level': 'senior',
          'Expert Level': 'expert',
        };
        if (job.experienceLevel != levelMap[_selectedExperienceLevel]) {
          return false;
        }
      }

      // Job type filter
      if (_selectedJobType != null) {
        if (job.jobTypeDisplay != _selectedJobType) {
          return false;
        }
      }

      // Employment type filter
      if (_selectedEmploymentType != null) {
        if (job.employmentTypeDisplay != _selectedEmploymentType) {
          return false;
        }
      }

      // Remote filter
      if (_remoteOnly && !job.remoteAllowed) {
        return false;
      }

      // Salary filter
      if (job.minSalary != null) {
        if (job.minSalary! < _minSalary || job.minSalary! > _maxSalary) {
          return false;
        }
      }

      return true;
    }).toList();

    // Apply sorting
    filteredJobs.sort((a, b) {
      switch (_sortBy) {
        case 'salary_high':
          return (b.minSalary ?? 0).compareTo(a.minSalary ?? 0);
        case 'salary_low':
          return (a.minSalary ?? 0).compareTo(b.minSalary ?? 0);
        case 'deadline':
          return a.applicationDeadline.compareTo(b.applicationDeadline);
        case 'newest':
        default:
          return b.createdAt.compareTo(a.createdAt);
      }
    });

    if (_jobPostings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.work_off,
        title: 'No Job Postings Yet',
        subtitle: 'Be the first company to post a job opportunity!',
      );
    }

    if (filteredJobs.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        title: 'No Jobs Found',
        subtitle:
            'Try adjusting your filters or search criteria to find more jobs.',
      );
    }

    return Column(
      children: [
        // Active Filters and Sort
        if (_hasActiveFilters()) _buildActiveFiltersBar(),

        // Job List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredJobs.length,
            itemBuilder: (context, index) {
              return _buildJobPostingCard(filteredJobs[index]);
            },
          ),
        ),
      ],
    );
  }

  bool _hasActiveFilters() {
    return _searchQuery.isNotEmpty ||
        _selectedCountry != null ||
        _selectedExperienceLevel != null ||
        _selectedJobType != null ||
        _selectedEmploymentType != null ||
        _remoteOnly ||
        _minSalary > 0 ||
        _maxSalary < 200000;
  }

  Widget _buildActiveFiltersBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Active Filters',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_searchQuery.isNotEmpty)
                _buildFilterChip('Search: "$_searchQuery"', () {
                  setState(() => _searchQuery = '');
                }),
              if (_selectedCountry != null)
                _buildFilterChip(_selectedCountry!, () {
                  setState(() => _selectedCountry = null);
                }),
              if (_selectedExperienceLevel != null)
                _buildFilterChip(_selectedExperienceLevel!, () {
                  setState(() => _selectedExperienceLevel = null);
                }),
              if (_selectedJobType != null)
                _buildFilterChip(_selectedJobType!, () {
                  setState(() => _selectedJobType = null);
                }),
              if (_selectedEmploymentType != null)
                _buildFilterChip(_selectedEmploymentType!, () {
                  setState(() => _selectedEmploymentType = null);
                }),
              if (_remoteOnly)
                _buildFilterChip('Remote Only', () {
                  setState(() => _remoteOnly = false);
                }),
              if (_minSalary > 0 || _maxSalary < 200000)
                _buildFilterChip(
                  'Salary: \$${_minSalary.toInt()}k - \$${_maxSalary.toInt()}k',
                  () {
                    setState(() {
                      _minSalary = 0;
                      _maxSalary = 200000;
                    });
                  },
                ),
              // Sort indicator
              _buildFilterChip(
                'Sort: ${_getSortLabel()}',
                () {},
                isRemovable: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove,
      {bool isRemovable = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
          ),
          if (isRemovable) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onRemove,
              child: const Icon(
                Icons.close,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'salary_high':
        return 'Highest Salary';
      case 'salary_low':
        return 'Lowest Salary';
      case 'deadline':
        return 'Closing Soon';
      case 'newest':
      default:
        return 'Newest First';
    }
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCountry = null;
      _selectedExperienceLevel = null;
      _selectedJobType = null;
      _selectedEmploymentType = null;
      _remoteOnly = false;
      _minSalary = 0;
      _maxSalary = 200000;
    });
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
                    icon: Icon(
                      _savedJobIds.contains(posting.id)
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_savedJobIds.contains(posting.id)) {
                          _savedJobIds.remove(posting.id);
                        } else {
                          _savedJobIds.add(posting.id);
                        }
                      });
                    },
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
    // Professional green gradient for Find Talent section
    const talentGradient = LinearGradient(
      colors: [Color(0xFF10B981), Color(0xFF34D399)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    const talentColor = Color(0xFF10B981); // Emerald green
    const talentLightColor = Color(0xFFD1FAE5); // Light green

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
                      gradient: talentGradient,
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
                      talentColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoTile(
                      Icons.trending_up,
                      seeker.experienceLevelDisplay,
                      'Level',
                      talentColor,
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
                  color: talentLightColor,
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
                        color: talentColor,
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
                          talentColor,
                        ),
                        _buildMetric(
                          Icons.check_circle,
                          '${seeker.ticketsSolved}',
                          'Solved',
                          talentColor,
                        ),
                        _buildMetric(
                          Icons.star,
                          seeker.averageRating.toStringAsFixed(1),
                          'Rating',
                          talentColor,
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
                    color: talentColor,
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
                        color: talentLightColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: talentColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        skill,
                        style: const TextStyle(
                          fontSize: 11,
                          color: talentColor,
                          fontWeight: FontWeight.w500,
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

  Widget _buildInfoTile(IconData icon, String value, String label, [Color? iconColor]) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: iconColor ?? AppColors.primary),
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

  Widget _buildMetric(IconData icon, String value, String label, [Color? iconColor]) {
    final color = iconColor ?? AppColors.primary;
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateJobSeekerProfileScreen(),
      ),
    );
  }

  void _showCreateJobPostingDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateJobPostingScreen(),
      ),
    );
  }

  // Job Filters Dialog
  void _showJobFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Row(
                        children: [
                          const Text(
                            'Filter Jobs',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _selectedCountry = null;
                                _selectedExperienceLevel = null;
                                _selectedJobType = null;
                                _selectedEmploymentType = null;
                                _remoteOnly = false;
                                _minSalary = 0;
                                _maxSalary = 200000;
                              });
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Filter Content
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        children: [
                          // Country Filter
                          const Text(
                            'Country / Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Popular Countries
                          const Text(
                            'Popular:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _popularCountries.map((country) {
                              final isSelected = _selectedCountry == country;
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    _selectedCountry = isSelected ? null : country;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.border,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    country,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // All Countries
                          const Text(
                            'All Countries:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _allCountries.length,
                              itemBuilder: (context, index) {
                                final country = _allCountries[index];
                                final isSelected = _selectedCountry == country;
                                return InkWell(
                                  onTap: () {
                                    setModalState(() {
                                      _selectedCountry = isSelected ? null : country;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primaryLight
                                          : null,
                                      border: Border(
                                        bottom: index < _allCountries.length - 1
                                            ? BorderSide(
                                                color: AppColors.border.withOpacity(0.3))
                                            : BorderSide.none,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            country,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(
                                            Icons.check_circle,
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Experience Level
                          const Text(
                            'Experience Level',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _experienceLevels.map((level) {
                              final isSelected = _selectedExperienceLevel == level;
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    _selectedExperienceLevel = isSelected ? null : level;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.border,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    level,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),

                          // Job Type
                          const Text(
                            'Job Type',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _jobTypes.map((type) {
                              final isSelected = _selectedJobType == type;
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    _selectedJobType = isSelected ? null : type;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.border,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    type,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),

                          // Employment Type
                          const Text(
                            'Employment Type',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _employmentTypes.map((type) {
                              final isSelected = _selectedEmploymentType == type;
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    _selectedEmploymentType = isSelected ? null : type;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.border,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    type,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),

                          // Remote Work Option
                          CheckboxListTile(
                            title: const Text('Remote Work Only'),
                            subtitle: const Text(
                                'Show only jobs that allow remote work'),
                            value: _remoteOnly,
                            onChanged: (value) {
                              setModalState(() => _remoteOnly = value ?? false);
                            },
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            tileColor: AppColors.surface,
                          ),
                          const SizedBox(height: 24),

                          // Salary Range
                          const Text(
                            'Salary Range (yearly)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                '\$${(_minSalary / 1000).toStringAsFixed(0)}k',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '\$${(_maxSalary / 1000).toStringAsFixed(0)}k',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          RangeSlider(
                            values: RangeValues(_minSalary, _maxSalary),
                            min: 0,
                            max: 200000,
                            divisions: 40,
                            activeColor: AppColors.primary,
                            labels: RangeLabels(
                              '\$${(_minSalary / 1000).toStringAsFixed(0)}k',
                              '\$${(_maxSalary / 1000).toStringAsFixed(0)}k',
                            ),
                            onChanged: (values) {
                              setModalState(() {
                                _minSalary = values.start;
                                _maxSalary = values.end;
                              });
                            },
                          ),
                          const SizedBox(height: 24),

                          // Sort By
                          const Text(
                            'Sort By',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...['newest', 'salary_high', 'salary_low', 'deadline']
                              .map((sortOption) {
                            String label;
                            IconData icon;
                            switch (sortOption) {
                              case 'salary_high':
                                label = 'Highest Salary First';
                                icon = Icons.arrow_upward;
                                break;
                              case 'salary_low':
                                label = 'Lowest Salary First';
                                icon = Icons.arrow_downward;
                                break;
                              case 'deadline':
                                label = 'Closing Soon';
                                icon = Icons.schedule;
                                break;
                              case 'newest':
                              default:
                                label = 'Newest First';
                                icon = Icons.new_releases;
                            }

                            return RadioListTile<String>(
                              title: Text(label),
                              secondary: Icon(icon, color: AppColors.primary),
                              value: sortOption,
                              groupValue: _sortBy,
                              onChanged: (value) {
                                setModalState(() => _sortBy = value!);
                              },
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              tileColor: _sortBy == sortOption
                                  ? AppColors.primaryLight
                                  : null,
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    // Apply Button
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border(
                          top: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {}); // Apply filters
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // Job Search Dialog
  void _showJobSearch() {
    showDialog(
      context: context,
      builder: (context) {
        String tempQuery = _searchQuery;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.search, color: AppColors.primary),
              SizedBox(width: 12),
              Text('Search Jobs'),
            ],
          ),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Job title, company, or keywords...',
              prefixIcon: const Icon(Icons.work_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.inputBackground,
            ),
            onChanged: (value) => tempQuery = value,
            onSubmitted: (value) {
              setState(() => _searchQuery = value);
              Navigator.pop(context);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _searchQuery = tempQuery);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  // Talent Filters Dialog (for companies searching for job seekers)
  void _showTalentFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Row(
                        children: [
                          const Text(
                            'Filter Talent',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _selectedSeekerCountry = null;
                                _selectedSeekerExperienceLevel = null;
                                _minExperienceYears = 0;
                                _maxExperienceYears = 30;
                                _availableOnly = true;
                              });
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Filter Content
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        children: [
                          // Country Filter
                          const Text(
                            'Nationality / Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Popular Countries
                          const Text(
                            'Popular:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _popularCountries.map((country) {
                              final isSelected = _selectedSeekerCountry == country;
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    _selectedSeekerCountry = isSelected ? null : country;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.border,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    country,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // All Countries
                          const Text(
                            'All Countries:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _allCountries.length,
                              itemBuilder: (context, index) {
                                final country = _allCountries[index];
                                final isSelected = _selectedSeekerCountry == country;
                                return InkWell(
                                  onTap: () {
                                    setModalState(() {
                                      _selectedSeekerCountry = isSelected ? null : country;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primaryLight
                                          : null,
                                      border: Border(
                                        bottom: index < _allCountries.length - 1
                                            ? BorderSide(
                                                color: AppColors.border.withOpacity(0.3))
                                            : BorderSide.none,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            country,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(
                                            Icons.check_circle,
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Experience Level
                          const Text(
                            'Experience Level',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _experienceLevels.map((level) {
                              final isSelected = _selectedSeekerExperienceLevel == level;
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    _selectedSeekerExperienceLevel = isSelected ? null : level;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.border,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    level,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),

                          // Experience Years Range
                          const Text(
                            'Years of Experience',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                '$_minExperienceYears years',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$_maxExperienceYears years',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          RangeSlider(
                            values: RangeValues(_minExperienceYears.toDouble(),
                                _maxExperienceYears.toDouble()),
                            min: 0,
                            max: 30,
                            divisions: 30,
                            activeColor: AppColors.primary,
                            labels: RangeLabels(
                              '$_minExperienceYears years',
                              '$_maxExperienceYears years',
                            ),
                            onChanged: (values) {
                              setModalState(() {
                                _minExperienceYears = values.start.toInt();
                                _maxExperienceYears = values.end.toInt();
                              });
                            },
                          ),
                          const SizedBox(height: 24),

                          // Availability Filter
                          CheckboxListTile(
                            title: const Text('Available Only'),
                            subtitle:
                                const Text('Show only available candidates'),
                            value: _availableOnly,
                            onChanged: (value) {
                              setModalState(() => _availableOnly = value ?? true);
                            },
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            tileColor: AppColors.surface,
                          ),
                        ],
                      ),
                    ),
                    // Apply Button
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border(
                          top: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {}); // Apply filters
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // Talent Search Dialog
  void _showTalentSearch() {
    showDialog(
      context: context,
      builder: (context) {
        String tempQuery = _seekerSearchQuery;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.search, color: AppColors.primary),
              SizedBox(width: 12),
              Text('Search Talent'),
            ],
          ),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Name, job title, or skills...',
              prefixIcon: const Icon(Icons.person_search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.inputBackground,
            ),
            onChanged: (value) => tempQuery = value,
            onSubmitted: (value) {
              setState(() => _seekerSearchQuery = value);
              Navigator.pop(context);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _seekerSearchQuery = tempQuery);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }
}
