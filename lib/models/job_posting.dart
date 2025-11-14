import 'package:machine_manager_app/models/user_profile.dart';

class JobPosting {
  final String id;
  final String companyId; // User ID of the company poster
  final String companyName;
  final String? companyLogo;
  final String? companyWebsite;
  final String? companyDescription;

  final String jobTitle;
  final String jobDescription;
  final String jobType; // 'engineer', 'technician', 'supervisor', 'manager', 'operator'
  final String employmentType; // 'full_time', 'part_time', 'contract', 'temporary'
  final String experienceLevel; // 'entry', 'mid', 'senior', 'expert'
  final int minExperienceYears;
  final int? maxExperienceYears;

  final String location;
  final String country;
  final bool remoteAllowed;
  final bool relocationAssistance;

  final List<String> requiredSkills;
  final List<String> preferredSkills;
  final List<String> certifications;
  final String? educationRequirement;

  final double? minSalary;
  final double? maxSalary;
  final String? salaryCurrency;
  final String? salaryPeriod; // 'hourly', 'monthly', 'yearly'
  final List<String> benefits;

  final int openPositions;
  final DateTime applicationDeadline;
  final bool isActive;
  final String status; // 'open', 'closed', 'filled'

  final int viewCount;
  final int applicationCount;

  final DateTime createdAt;
  final DateTime updatedAt;

  // Relationships
  final UserProfile? companyProfile;

  JobPosting({
    required this.id,
    required this.companyId,
    required this.companyName,
    this.companyLogo,
    this.companyWebsite,
    this.companyDescription,
    required this.jobTitle,
    required this.jobDescription,
    required this.jobType,
    required this.employmentType,
    required this.experienceLevel,
    required this.minExperienceYears,
    this.maxExperienceYears,
    required this.location,
    required this.country,
    required this.remoteAllowed,
    required this.relocationAssistance,
    this.requiredSkills = const [],
    this.preferredSkills = const [],
    this.certifications = const [],
    this.educationRequirement,
    this.minSalary,
    this.maxSalary,
    this.salaryCurrency,
    this.salaryPeriod,
    this.benefits = const [],
    required this.openPositions,
    required this.applicationDeadline,
    required this.isActive,
    required this.status,
    this.viewCount = 0,
    this.applicationCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.companyProfile,
  });

  factory JobPosting.fromJson(Map<String, dynamic> json) {
    return JobPosting(
      id: json['id'] as String,
      companyId: json['company_id'] as String,
      companyName: json['company_name'] as String,
      companyLogo: json['company_logo'] as String?,
      companyWebsite: json['company_website'] as String?,
      companyDescription: json['company_description'] as String?,
      jobTitle: json['job_title'] as String,
      jobDescription: json['job_description'] as String,
      jobType: json['job_type'] as String,
      employmentType: json['employment_type'] as String,
      experienceLevel: json['experience_level'] as String,
      minExperienceYears: json['min_experience_years'] as int,
      maxExperienceYears: json['max_experience_years'] as int?,
      location: json['location'] as String,
      country: json['country'] as String,
      remoteAllowed: json['remote_allowed'] as bool? ?? false,
      relocationAssistance: json['relocation_assistance'] as bool? ?? false,
      requiredSkills: json['required_skills'] != null
          ? List<String>.from(json['required_skills'] as List)
          : [],
      preferredSkills: json['preferred_skills'] != null
          ? List<String>.from(json['preferred_skills'] as List)
          : [],
      certifications: json['certifications'] != null
          ? List<String>.from(json['certifications'] as List)
          : [],
      educationRequirement: json['education_requirement'] as String?,
      minSalary: json['min_salary'] != null
          ? (json['min_salary'] as num).toDouble()
          : null,
      maxSalary: json['max_salary'] != null
          ? (json['max_salary'] as num).toDouble()
          : null,
      salaryCurrency: json['salary_currency'] as String?,
      salaryPeriod: json['salary_period'] as String?,
      benefits: json['benefits'] != null
          ? List<String>.from(json['benefits'] as List)
          : [],
      openPositions: json['open_positions'] as int? ?? 1,
      applicationDeadline:
          DateTime.parse(json['application_deadline'] as String),
      isActive: json['is_active'] as bool? ?? true,
      status: json['status'] as String? ?? 'open',
      viewCount: json['view_count'] as int? ?? 0,
      applicationCount: json['application_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      companyProfile: json['company_profile'] != null
          ? UserProfile.fromJson(json['company_profile'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_id': companyId,
      'company_name': companyName,
      'company_logo': companyLogo,
      'company_website': companyWebsite,
      'company_description': companyDescription,
      'job_title': jobTitle,
      'job_description': jobDescription,
      'job_type': jobType,
      'employment_type': employmentType,
      'experience_level': experienceLevel,
      'min_experience_years': minExperienceYears,
      'max_experience_years': maxExperienceYears,
      'location': location,
      'country': country,
      'remote_allowed': remoteAllowed,
      'relocation_assistance': relocationAssistance,
      'required_skills': requiredSkills,
      'preferred_skills': preferredSkills,
      'certifications': certifications,
      'education_requirement': educationRequirement,
      'min_salary': minSalary,
      'max_salary': maxSalary,
      'salary_currency': salaryCurrency,
      'salary_period': salaryPeriod,
      'benefits': benefits,
      'open_positions': openPositions,
      'application_deadline': applicationDeadline.toIso8601String(),
      'is_active': isActive,
      'status': status,
      'view_count': viewCount,
      'application_count': applicationCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  JobPosting copyWith({
    String? id,
    String? companyId,
    String? companyName,
    String? companyLogo,
    String? companyWebsite,
    String? companyDescription,
    String? jobTitle,
    String? jobDescription,
    String? jobType,
    String? employmentType,
    String? experienceLevel,
    int? minExperienceYears,
    int? maxExperienceYears,
    String? location,
    String? country,
    bool? remoteAllowed,
    bool? relocationAssistance,
    List<String>? requiredSkills,
    List<String>? preferredSkills,
    List<String>? certifications,
    String? educationRequirement,
    double? minSalary,
    double? maxSalary,
    String? salaryCurrency,
    String? salaryPeriod,
    List<String>? benefits,
    int? openPositions,
    DateTime? applicationDeadline,
    bool? isActive,
    String? status,
    int? viewCount,
    int? applicationCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserProfile? companyProfile,
  }) {
    return JobPosting(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      companyLogo: companyLogo ?? this.companyLogo,
      companyWebsite: companyWebsite ?? this.companyWebsite,
      companyDescription: companyDescription ?? this.companyDescription,
      jobTitle: jobTitle ?? this.jobTitle,
      jobDescription: jobDescription ?? this.jobDescription,
      jobType: jobType ?? this.jobType,
      employmentType: employmentType ?? this.employmentType,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      minExperienceYears: minExperienceYears ?? this.minExperienceYears,
      maxExperienceYears: maxExperienceYears ?? this.maxExperienceYears,
      location: location ?? this.location,
      country: country ?? this.country,
      remoteAllowed: remoteAllowed ?? this.remoteAllowed,
      relocationAssistance: relocationAssistance ?? this.relocationAssistance,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      preferredSkills: preferredSkills ?? this.preferredSkills,
      certifications: certifications ?? this.certifications,
      educationRequirement: educationRequirement ?? this.educationRequirement,
      minSalary: minSalary ?? this.minSalary,
      maxSalary: maxSalary ?? this.maxSalary,
      salaryCurrency: salaryCurrency ?? this.salaryCurrency,
      salaryPeriod: salaryPeriod ?? this.salaryPeriod,
      benefits: benefits ?? this.benefits,
      openPositions: openPositions ?? this.openPositions,
      applicationDeadline: applicationDeadline ?? this.applicationDeadline,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      viewCount: viewCount ?? this.viewCount,
      applicationCount: applicationCount ?? this.applicationCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      companyProfile: companyProfile ?? this.companyProfile,
    );
  }

  String get jobTypeDisplay {
    switch (jobType.toLowerCase()) {
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
        return jobType;
    }
  }

  String get employmentTypeDisplay {
    switch (employmentType.toLowerCase()) {
      case 'full_time':
        return 'Full Time';
      case 'part_time':
        return 'Part Time';
      case 'contract':
        return 'Contract';
      case 'temporary':
        return 'Temporary';
      default:
        return employmentType;
    }
  }

  String get experienceLevelDisplay {
    switch (experienceLevel.toLowerCase()) {
      case 'entry':
        return 'Entry Level';
      case 'mid':
        return 'Mid Level';
      case 'senior':
        return 'Senior Level';
      case 'expert':
        return 'Expert Level';
      default:
        return experienceLevel;
    }
  }

  String get salaryRangeDisplay {
    if (minSalary == null && maxSalary == null) {
      return 'Competitive Salary';
    }

    final currency = salaryCurrency ?? 'USD';
    final period = salaryPeriod ?? 'yearly';

    if (minSalary != null && maxSalary != null) {
      return '$currency ${minSalary!.toStringAsFixed(0)} - ${maxSalary!.toStringAsFixed(0)} / $period';
    } else if (minSalary != null) {
      return 'From $currency ${minSalary!.toStringAsFixed(0)} / $period';
    } else {
      return 'Up to $currency ${maxSalary!.toStringAsFixed(0)} / $period';
    }
  }

  bool get isExpiringSoon {
    final daysUntilDeadline = applicationDeadline.difference(DateTime.now()).inDays;
    return daysUntilDeadline <= 7 && daysUntilDeadline > 0;
  }

  bool get isExpired {
    return DateTime.now().isAfter(applicationDeadline);
  }
}
