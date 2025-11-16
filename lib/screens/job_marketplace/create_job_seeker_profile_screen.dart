import 'package:flutter/material.dart';
import 'package:machine_manager_app/config/colors.dart';

class CreateJobSeekerProfileScreen extends StatefulWidget {
  const CreateJobSeekerProfileScreen({super.key});

  @override
  State<CreateJobSeekerProfileScreen> createState() =>
      _CreateJobSeekerProfileScreenState();
}

class _CreateJobSeekerProfileScreenState
    extends State<CreateJobSeekerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _portfolioUrlController = TextEditingController();
  final _linkedinUrlController = TextEditingController();
  final _expectedSalaryController = TextEditingController();

  String? _selectedNationality;
  String? _selectedCurrentLocation;
  String _selectedExperienceLevel = 'entry';
  int _experienceYears = 0;
  String _salaryCurrency = 'USD';
  String _availability = 'immediate';
  bool _isAvailable = true;
  bool _willingToRelocate = false;

  final List<String> _skills = [];
  final List<String> _certifications = [];
  final List<String> _preferredJobTypes = [];
  final List<String> _preferredLocations = [];

  String? _cvFileName;
  bool _isLoading = false;

  final List<String> _countries = [
    'United States',
    'Canada',
    'United Kingdom',
    'Germany',
    'France',
    'Italy',
    'Spain',
    'Netherlands',
    'Belgium',
    'Switzerland',
    'Austria',
    'Poland',
    'Czech Republic',
    'Sweden',
    'Norway',
    'Denmark',
    'Finland',
    'Ireland',
    'Portugal',
    'Greece',
    'Romania',
    'Hungary',
    'Australia',
    'New Zealand',
    'Japan',
    'South Korea',
    'Singapore',
    'India',
    'China',
    'Brazil',
    'Mexico',
    'Argentina',
    'Chile',
    'Colombia',
    'United Arab Emirates',
    'Saudi Arabia',
    'Egypt',
    'South Africa',
  ];

  final List<String> _experienceLevels = [
    'entry',
    'mid',
    'senior',
    'expert',
  ];

  final List<String> _jobTypeOptions = [
    'engineer',
    'technician',
    'supervisor',
    'manager',
    'operator',
  ];

  final List<String> _availabilityOptions = [
    'immediate',
    '2_weeks',
    '1_month',
    'negotiable',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _jobTitleController.dispose();
    _summaryController.dispose();
    _portfolioUrlController.dispose();
    _linkedinUrlController.dispose();
    _expectedSalaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Job Seeker Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textOnPrimary,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Section: Basic Information
            _buildSectionTitle('Basic Information'),
            const SizedBox(height: 16),

            // Full Name
            TextFormField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email *',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone Number
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Nationality
            DropdownButtonFormField<String>(
              value: _selectedNationality,
              decoration: InputDecoration(
                labelText: 'Nationality *',
                prefixIcon: const Icon(Icons.flag),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _countries.map((country) {
                return DropdownMenuItem(
                  value: country,
                  child: Text(country),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedNationality = value);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select your nationality';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Current Location
            DropdownButtonFormField<String>(
              value: _selectedCurrentLocation,
              decoration: InputDecoration(
                labelText: 'Current Location',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _countries.map((country) {
                return DropdownMenuItem(
                  value: country,
                  child: Text(country),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCurrentLocation = value);
              },
            ),
            const SizedBox(height: 24),

            // Section: Professional Information
            _buildSectionTitle('Professional Information'),
            const SizedBox(height: 16),

            // Job Title
            TextFormField(
              controller: _jobTitleController,
              decoration: InputDecoration(
                labelText: 'Current Job Title *',
                prefixIcon: const Icon(Icons.work),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your job title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Professional Summary
            TextFormField(
              controller: _summaryController,
              decoration: InputDecoration(
                labelText: 'Professional Summary',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Brief description of your professional background...',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            // Experience Years Slider
            Row(
              children: [
                const Icon(Icons.work_history, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Years of Experience: $_experienceYears years',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Slider(
                        value: _experienceYears.toDouble(),
                        min: 0,
                        max: 30,
                        divisions: 30,
                        label: '$_experienceYears years',
                        activeColor: AppColors.primary,
                        onChanged: (value) {
                          setState(() => _experienceYears = value.toInt());
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Experience Level
            const Text(
              'Experience Level *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _experienceLevels.map((level) {
                final isSelected = _selectedExperienceLevel == level;
                return ChoiceChip(
                  label: Text(_getExperienceLevelDisplay(level)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedExperienceLevel = level);
                    }
                  },
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primaryLight,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Section: Skills & Certifications
            _buildSectionTitle('Skills & Certifications'),
            const SizedBox(height: 16),

            // Skills
            _buildChipInputField(
              'Skills',
              _skills,
              Icons.build,
              'Add a skill (e.g., Welding, Programming)',
            ),
            const SizedBox(height: 16),

            // Certifications
            _buildChipInputField(
              'Certifications',
              _certifications,
              Icons.verified,
              'Add a certification',
            ),
            const SizedBox(height: 24),

            // Section: Documents & Links
            _buildSectionTitle('Documents & Links'),
            const SizedBox(height: 16),

            // CV Upload
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    _cvFileName != null ? Icons.check_circle : Icons.upload_file,
                    size: 48,
                    color: _cvFileName != null ? AppColors.success : AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _cvFileName ?? 'Upload your CV/Resume',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _cvFileName != null ? AppColors.success : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _pickCV,
                    icon: const Icon(Icons.attach_file),
                    label: Text(_cvFileName != null ? 'Change CV' : 'Select CV File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PDF, DOC, or DOCX (max 10MB)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Portfolio URL
            TextFormField(
              controller: _portfolioUrlController,
              decoration: InputDecoration(
                labelText: 'Portfolio URL',
                prefixIcon: const Icon(Icons.web),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            // LinkedIn URL
            TextFormField(
              controller: _linkedinUrlController,
              decoration: InputDecoration(
                labelText: 'LinkedIn Profile URL',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),

            // Section: Salary & Availability
            _buildSectionTitle('Salary & Availability'),
            const SizedBox(height: 16),

            // Expected Salary
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _expectedSalaryController,
                    decoration: InputDecoration(
                      labelText: 'Expected Salary',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _salaryCurrency,
                    decoration: InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: ['USD', 'EUR', 'GBP', 'CAD', 'AUD', 'JPY', 'CNY', 'INR']
                        .map((currency) {
                      return DropdownMenuItem(
                        value: currency,
                        child: Text(currency),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _salaryCurrency = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Availability
            DropdownButtonFormField<String>(
              value: _availability,
              decoration: InputDecoration(
                labelText: 'Availability',
                prefixIcon: const Icon(Icons.schedule),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _availabilityOptions.map((avail) {
                return DropdownMenuItem(
                  value: avail,
                  child: Text(_getAvailabilityDisplay(avail)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _availability = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Status Switches
            SwitchListTile(
              title: const Text('Currently Available for Work'),
              subtitle: const Text('Show your profile to recruiters'),
              value: _isAvailable,
              onChanged: (value) {
                setState(() => _isAvailable = value);
              },
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: AppColors.surface,
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              title: const Text('Willing to Relocate'),
              subtitle: const Text('Open to opportunities in other locations'),
              value: _willingToRelocate,
              onChanged: (value) {
                setState(() => _willingToRelocate = value);
              },
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: AppColors.surface,
            ),
            const SizedBox(height: 24),

            // Section: Job Preferences
            _buildSectionTitle('Job Preferences'),
            const SizedBox(height: 16),

            // Preferred Job Types
            const Text(
              'Preferred Job Types',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _jobTypeOptions.map((type) {
                final isSelected = _preferredJobTypes.contains(type);
                return FilterChip(
                  label: Text(_getJobTypeDisplay(type)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _preferredJobTypes.add(type);
                      } else {
                        _preferredJobTypes.remove(type);
                      }
                    });
                  },
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.primaryLight,
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Preferred Locations
            _buildChipInputField(
              'Preferred Locations',
              _preferredLocations,
              Icons.location_city,
              'Add a preferred location',
            ),
            const SizedBox(height: 32),

            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _submitProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Create Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildChipInputField(
    String label,
    List<String> items,
    IconData icon,
    String hintText,
  ) {
    final controller = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.primary),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    items.add(controller.text);
                    controller.clear();
                  });
                }
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              setState(() {
                items.add(value);
                controller.clear();
              });
            }
          },
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              return Chip(
                label: Text(item),
                onDeleted: () {
                  setState(() => items.remove(item));
                },
                backgroundColor: AppColors.primaryLight,
                deleteIconColor: AppColors.primary,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  String _getExperienceLevelDisplay(String level) {
    switch (level) {
      case 'entry':
        return 'Entry Level';
      case 'mid':
        return 'Mid Level';
      case 'senior':
        return 'Senior Level';
      case 'expert':
        return 'Expert Level';
      default:
        return level;
    }
  }

  String _getJobTypeDisplay(String type) {
    switch (type) {
      case 'engineer':
        return 'Engineer';
      case 'technician':
        return 'Technician';
      case 'supervisor':
        return 'Supervisor';
      case 'manager':
        return 'Manager';
      case 'operator':
        return 'Machine Operator';
      default:
        return type;
    }
  }

  String _getAvailabilityDisplay(String avail) {
    switch (avail) {
      case 'immediate':
        return 'Immediately Available';
      case '2_weeks':
        return 'Available in 2 Weeks';
      case '1_month':
        return 'Available in 1 Month';
      case 'negotiable':
        return 'Negotiable';
      default:
        return avail;
    }
  }

  void _pickCV() {
    // TODO: Implement file picker for CV upload
    // For now, simulate file selection
    setState(() {
      _cvFileName = 'my_resume.pdf';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CV upload functionality will be implemented with file_picker package'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if CV is uploaded
    if (_cvFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your CV/Resume'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Implement Supabase integration to save profile
    // For now, simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile created successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Navigate back
      Navigator.pop(context);
    }
  }
}
