import 'package:machine_manager_app/models/user_profile.dart';

class JobSeekerProfile {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String nationality;
  final String? currentLocation;
  final String jobTitle;
  final String? summary;
  final int experienceYears;
  final String experienceLevel; // 'entry', 'mid', 'senior', 'expert'
  final List<String> skills;
  final List<String> certifications;
  final String? cvUrl;
  final String? portfolioUrl;
  final String? linkedinUrl;
  final double? expectedSalary;
  final String? salaryCurrency;
  final bool isAvailable;
  final String? availability; // 'immediate', '2_weeks', '1_month', 'negotiable'

  // App-specific data
  final int appScore;
  final int ticketsSolved;
  final double averageRating;

  // Preferences
  final List<String> preferredJobTypes; // 'engineer', 'technician', 'supervisor', 'manager'
  final List<String> preferredLocations;
  final bool willingToRelocate;

  final DateTime createdAt;
  final DateTime updatedAt;

  // Relationships
  final UserProfile? userProfile;

  JobSeekerProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.nationality,
    this.currentLocation,
    required this.jobTitle,
    this.summary,
    required this.experienceYears,
    required this.experienceLevel,
    this.skills = const [],
    this.certifications = const [],
    this.cvUrl,
    this.portfolioUrl,
    this.linkedinUrl,
    this.expectedSalary,
    this.salaryCurrency,
    required this.isAvailable,
    this.availability,
    required this.appScore,
    required this.ticketsSolved,
    required this.averageRating,
    this.preferredJobTypes = const [],
    this.preferredLocations = const [],
    required this.willingToRelocate,
    required this.createdAt,
    required this.updatedAt,
    this.userProfile,
  });

  factory JobSeekerProfile.fromJson(Map<String, dynamic> json) {
    return JobSeekerProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String?,
      nationality: json['nationality'] as String,
      currentLocation: json['current_location'] as String?,
      jobTitle: json['job_title'] as String,
      summary: json['summary'] as String?,
      experienceYears: json['experience_years'] as int,
      experienceLevel: json['experience_level'] as String,
      skills: json['skills'] != null
          ? List<String>.from(json['skills'] as List)
          : [],
      certifications: json['certifications'] != null
          ? List<String>.from(json['certifications'] as List)
          : [],
      cvUrl: json['cv_url'] as String?,
      portfolioUrl: json['portfolio_url'] as String?,
      linkedinUrl: json['linkedin_url'] as String?,
      expectedSalary: json['expected_salary'] != null
          ? (json['expected_salary'] as num).toDouble()
          : null,
      salaryCurrency: json['salary_currency'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      availability: json['availability'] as String?,
      appScore: json['app_score'] as int? ?? 0,
      ticketsSolved: json['tickets_solved'] as int? ?? 0,
      averageRating: json['average_rating'] != null
          ? (json['average_rating'] as num).toDouble()
          : 0.0,
      preferredJobTypes: json['preferred_job_types'] != null
          ? List<String>.from(json['preferred_job_types'] as List)
          : [],
      preferredLocations: json['preferred_locations'] != null
          ? List<String>.from(json['preferred_locations'] as List)
          : [],
      willingToRelocate: json['willing_to_relocate'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userProfile: json['user_profile'] != null
          ? UserProfile.fromJson(json['user_profile'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'nationality': nationality,
      'current_location': currentLocation,
      'job_title': jobTitle,
      'summary': summary,
      'experience_years': experienceYears,
      'experience_level': experienceLevel,
      'skills': skills,
      'certifications': certifications,
      'cv_url': cvUrl,
      'portfolio_url': portfolioUrl,
      'linkedin_url': linkedinUrl,
      'expected_salary': expectedSalary,
      'salary_currency': salaryCurrency,
      'is_available': isAvailable,
      'availability': availability,
      'app_score': appScore,
      'tickets_solved': ticketsSolved,
      'average_rating': averageRating,
      'preferred_job_types': preferredJobTypes,
      'preferred_locations': preferredLocations,
      'willing_to_relocate': willingToRelocate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  JobSeekerProfile copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? nationality,
    String? currentLocation,
    String? jobTitle,
    String? summary,
    int? experienceYears,
    String? experienceLevel,
    List<String>? skills,
    List<String>? certifications,
    String? cvUrl,
    String? portfolioUrl,
    String? linkedinUrl,
    double? expectedSalary,
    String? salaryCurrency,
    bool? isAvailable,
    String? availability,
    int? appScore,
    int? ticketsSolved,
    double? averageRating,
    List<String>? preferredJobTypes,
    List<String>? preferredLocations,
    bool? willingToRelocate,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserProfile? userProfile,
  }) {
    return JobSeekerProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      nationality: nationality ?? this.nationality,
      currentLocation: currentLocation ?? this.currentLocation,
      jobTitle: jobTitle ?? this.jobTitle,
      summary: summary ?? this.summary,
      experienceYears: experienceYears ?? this.experienceYears,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      skills: skills ?? this.skills,
      certifications: certifications ?? this.certifications,
      cvUrl: cvUrl ?? this.cvUrl,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      expectedSalary: expectedSalary ?? this.expectedSalary,
      salaryCurrency: salaryCurrency ?? this.salaryCurrency,
      isAvailable: isAvailable ?? this.isAvailable,
      availability: availability ?? this.availability,
      appScore: appScore ?? this.appScore,
      ticketsSolved: ticketsSolved ?? this.ticketsSolved,
      averageRating: averageRating ?? this.averageRating,
      preferredJobTypes: preferredJobTypes ?? this.preferredJobTypes,
      preferredLocations: preferredLocations ?? this.preferredLocations,
      willingToRelocate: willingToRelocate ?? this.willingToRelocate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userProfile: userProfile ?? this.userProfile,
    );
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

  String get availabilityDisplay {
    switch (availability?.toLowerCase()) {
      case 'immediate':
        return 'Immediately Available';
      case '2_weeks':
        return 'Available in 2 Weeks';
      case '1_month':
        return 'Available in 1 Month';
      case 'negotiable':
        return 'Negotiable';
      default:
        return 'Not Specified';
    }
  }
}
