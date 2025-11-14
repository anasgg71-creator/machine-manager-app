import 'package:flutter/material.dart';
import 'package:machine_manager_app/config/colors.dart';

class CreateJobPostingScreen extends StatefulWidget {
  const CreateJobPostingScreen({super.key});

  @override
  State<CreateJobPostingScreen> createState() =>
      _CreateJobPostingScreenState();
}

class _CreateJobPostingScreenState extends State<CreateJobPostingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jobTitleController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyDescriptionController = TextEditingController();
  final _jobDescriptionController = TextEditingController();
  final _responsibilitiesController = TextEditingController();
  final _locationController = TextEditingController();
  final _minSalaryController = TextEditingController();
  final _maxSalaryController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  String? _selectedCountry;
  String _selectedJobType = 'engineer';
  String _selectedEmploymentType = 'full_time';
  String _selectedExperienceLevel = 'mid';
  bool _remoteAllowed = false;
  int _openPositions = 1;
  DateTime _applicationDeadline = DateTime.now().add(const Duration(days: 30));

  final List<String> _requiredSkills = [];
  final List<String> _benefits = [];

  bool _isLoading = false;

  final List<String> _popularCountries = [
    'United States',
    'United Kingdom',
    'Germany',
    'Canada',
    'France',
    'Australia',
  ];

  final List<String> _allCountries = [
    'Argentina',
    'Australia',
    'Austria',
    'Belgium',
    'Brazil',
    'Canada',
    'Chile',
    'China',
    'Colombia',
    'Czech Republic',
    'Denmark',
    'Egypt',
    'Finland',
    'France',
    'Germany',
    'Greece',
    'Hungary',
    'India',
    'Ireland',
    'Italy',
    'Japan',
    'Mexico',
    'Netherlands',
    'New Zealand',
    'Norway',
    'Poland',
    'Portugal',
    'Romania',
    'Saudi Arabia',
    'Singapore',
    'South Africa',
    'South Korea',
    'Spain',
    'Sweden',
    'Switzerland',
    'United Arab Emirates',
    'United Kingdom',
    'United States',
  ];

  final List<String> _jobTypes = [
    'engineer',
    'technician',
    'supervisor',
    'manager',
    'operator',
  ];

  final List<String> _employmentTypes = [
    'full_time',
    'part_time',
    'contract',
    'temporary',
  ];

  final List<String> _experienceLevels = [
    'entry',
    'mid',
    'senior',
    'expert',
  ];

  @override
  void dispose() {
    _jobTitleController.dispose();
    _companyNameController.dispose();
    _companyDescriptionController.dispose();
    _jobDescriptionController.dispose();
    _responsibilitiesController.dispose();
    _locationController.dispose();
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Post a Job',
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
            // Section: Company Information
            _buildSectionTitle('Company Information'),
            const SizedBox(height: 16),

            TextFormField(
              controller: _companyNameController,
              decoration: InputDecoration(
                labelText: 'Company Name *',
                prefixIcon: const Icon(Icons.business),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter company name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _companyDescriptionController,
              decoration: InputDecoration(
                labelText: 'Company Description',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Brief description of your company...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Section: Job Details
            _buildSectionTitle('Job Details'),
            const SizedBox(height: 16),

            TextFormField(
              controller: _jobTitleController,
              decoration: InputDecoration(
                labelText: 'Job Title *',
                prefixIcon: const Icon(Icons.work),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter job title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Job Type - Easy Selection
            const Text(
              'Job Type *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _jobTypes.map((type) {
                final isSelected = _selectedJobType == type;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedJobType = type);
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
                      _getJobTypeDisplay(type),
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

            // Employment Type - Easy Selection
            const Text(
              'Employment Type *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _employmentTypes.map((type) {
                final isSelected = _selectedEmploymentType == type;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedEmploymentType = type);
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
                      _getEmploymentTypeDisplay(type),
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

            // Experience Level - Easy Selection
            const Text(
              'Experience Level Required *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _experienceLevels.map((level) {
                final isSelected = _selectedExperienceLevel == level;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedExperienceLevel = level);
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
                      _getExperienceLevelDisplay(level),
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

            TextFormField(
              controller: _jobDescriptionController,
              decoration: InputDecoration(
                labelText: 'Job Description *',
                prefixIcon: const Icon(Icons.article),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Describe the role and responsibilities...',
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter job description';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Section: Location
            _buildSectionTitle('Location'),
            const SizedBox(height: 16),

            // Country - Easy Selection with Popular + All
            const Text(
              'Country *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Popular Countries:',
              style: TextStyle(
                fontSize: 12,
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
                    setState(() => _selectedCountry = country);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
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
                        fontSize: 13,
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
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _selectedCountry,
              decoration: InputDecoration(
                labelText: 'Or select from all countries',
                prefixIcon: const Icon(Icons.public),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _allCountries.map((country) {
                return DropdownMenuItem(
                  value: country,
                  child: Text(country),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCountry = value);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a country';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'City / Location *',
                prefixIcon: const Icon(Icons.location_city),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter location';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Remote Work Allowed'),
              subtitle: const Text('Position can be done remotely'),
              value: _remoteAllowed,
              onChanged: (value) {
                setState(() => _remoteAllowed = value);
              },
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: AppColors.surface,
            ),
            const SizedBox(height: 24),

            // Section: Compensation
            _buildSectionTitle('Compensation'),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minSalaryController,
                    decoration: InputDecoration(
                      labelText: 'Min Salary',
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
                  child: TextFormField(
                    controller: _maxSalaryController,
                    decoration: InputDecoration(
                      labelText: 'Max Salary',
                      prefixIcon: const Icon(Icons.attach_money),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section: Requirements
            _buildSectionTitle('Requirements & Skills'),
            const SizedBox(height: 16),

            _buildChipInputField(
              'Required Skills',
              _requiredSkills,
              Icons.build,
              'Add a required skill',
            ),
            const SizedBox(height: 16),

            _buildChipInputField(
              'Benefits',
              _benefits,
              Icons.card_giftcard,
              'Add a benefit (e.g., Health Insurance)',
            ),
            const SizedBox(height: 24),

            // Section: Additional Details
            _buildSectionTitle('Additional Details'),
            const SizedBox(height: 16),

            Row(
              children: [
                const Icon(Icons.people, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Open Positions: $_openPositions',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Slider(
                        value: _openPositions.toDouble(),
                        min: 1,
                        max: 20,
                        divisions: 19,
                        label: '$_openPositions',
                        activeColor: AppColors.primary,
                        onChanged: (value) {
                          setState(() => _openPositions = value.toInt());
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ListTile(
              title: const Text('Application Deadline'),
              subtitle: Text(
                '${_applicationDeadline.day}/${_applicationDeadline.month}/${_applicationDeadline.year}',
              ),
              leading: const Icon(Icons.calendar_today, color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.border),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _applicationDeadline,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _applicationDeadline = date);
                }
              },
            ),
            const SizedBox(height: 24),

            // Section: Contact Information
            _buildSectionTitle('Contact Information'),
            const SizedBox(height: 16),

            TextFormField(
              controller: _contactEmailController,
              decoration: InputDecoration(
                labelText: 'Contact Email *',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter contact email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _contactPhoneController,
              decoration: InputDecoration(
                labelText: 'Contact Phone',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 32),

            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _submitJobPosting,
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
                      'Post Job',
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

  String _getEmploymentTypeDisplay(String type) {
    switch (type) {
      case 'full_time':
        return 'Full Time';
      case 'part_time':
        return 'Part Time';
      case 'contract':
        return 'Contract';
      case 'temporary':
        return 'Temporary';
      default:
        return type;
    }
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

  Future<void> _submitJobPosting() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Implement Supabase integration to save job posting
    // For now, simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job posted successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Navigate back
      Navigator.pop(context);
    }
  }
}
