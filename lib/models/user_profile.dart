class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String role;
  final int points;
  final int ticketsSolved;
  final int totalRatings;
  final double averageRating;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String preferredReceiveLanguage;

  UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    required this.role,
    required this.points,
    required this.ticketsSolved,
    required this.totalRatings,
    required this.averageRating,
    required this.isOnline,
    this.lastSeen,
    required this.createdAt,
    required this.updatedAt,
    this.preferredReceiveLanguage = 'en',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String? ?? 'member',
      points: json['points'] as int? ?? 0,
      ticketsSolved: json['tickets_solved'] as int? ?? 0,
      totalRatings: json['total_ratings'] as int? ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      preferredReceiveLanguage: json['preferred_receive_language'] as String? ?? 'en',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'role': role,
      'points': points,
      'tickets_solved': ticketsSolved,
      'total_ratings': totalRatings,
      'average_rating': averageRating,
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'preferred_receive_language': preferredReceiveLanguage,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? role,
    int? points,
    int? ticketsSolved,
    int? totalRatings,
    double? averageRating,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? preferredReceiveLanguage,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      points: points ?? this.points,
      ticketsSolved: ticketsSolved ?? this.ticketsSolved,
      totalRatings: totalRatings ?? this.totalRatings,
      averageRating: averageRating ?? this.averageRating,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferredReceiveLanguage: preferredReceiveLanguage ?? this.preferredReceiveLanguage,
    );
  }

  // Helper methods
  String get initials {
    if (fullName == null || fullName!.isEmpty) {
      return email.isNotEmpty ? email[0].toUpperCase() : '?';
    }

    final names = fullName!.trim().split(' ');
    if (names.length == 1) {
      return names[0][0].toUpperCase();
    }

    return '${names[0][0]}${names[names.length - 1][0]}'.toUpperCase();
  }

  String get displayName {
    return fullName?.isNotEmpty == true ? fullName! : email;
  }

  String get firstName {
    if (fullName == null || fullName!.isEmpty) return '';
    return fullName!.split(' ').first;
  }

  String get lastName {
    if (fullName == null || fullName!.isEmpty) return '';
    final names = fullName!.split(' ');
    return names.length > 1 ? names.last : '';
  }

  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager' || role == 'admin';
  bool get isTechnician => role == 'technician' || role == 'manager' || role == 'admin';

  // Badge logic
  List<UserBadge> get badges {
    final badges = <UserBadge>[];

    // Performance badges
    if (averageRating >= 4.8) {
      badges.add(const UserBadge(
        id: 'expert_solver',
        name: 'Expert Solver',
        description: 'Maintains exceptional solving quality',
        icon: '⭐',
        color: '#FFD700',
      ));
    } else if (averageRating >= 4.5) {
      badges.add(const UserBadge(
        id: 'quality_solver',
        name: 'Quality Solver',
        description: 'Consistently high-quality solutions',
        icon: '🌟',
        color: '#C0C0C0',
      ));
    }

    // Volume badges
    if (ticketsSolved >= 50) {
      badges.add(const UserBadge(
        id: 'super_solver',
        name: 'Super Solver',
        description: 'Solved 50+ tickets',
        icon: '🚀',
        color: '#FF6B35',
      ));
    } else if (ticketsSolved >= 20) {
      badges.add(const UserBadge(
        id: 'prolific_solver',
        name: 'Prolific Solver',
        description: 'Solved 20+ tickets',
        icon: '⚡',
        color: '#4ECDC4',
      ));
    } else if (ticketsSolved >= 10) {
      badges.add(const UserBadge(
        id: 'active_solver',
        name: 'Active Solver',
        description: 'Solved 10+ tickets',
        icon: '🔧',
        color: '#45B7D1',
      ));
    }

    // Points badges
    if (points >= 500) {
      badges.add(const UserBadge(
        id: 'high_performer',
        name: 'High Performer',
        description: 'Earned 500+ points',
        icon: '🏆',
        color: '#FFD700',
      ));
    } else if (points >= 200) {
      badges.add(const UserBadge(
        id: 'top_contributor',
        name: 'Top Contributor',
        description: 'Earned 200+ points',
        icon: '🥉',
        color: '#CD7F32',
      ));
    }

    // Role badges
    if (isAdmin) {
      badges.add(const UserBadge(
        id: 'admin',
        name: 'Administrator',
        description: 'System administrator',
        icon: '👑',
        color: '#9B59B6',
      ));
    } else if (isManager) {
      badges.add(const UserBadge(
        id: 'manager',
        name: 'Manager',
        description: 'Team manager',
        icon: '👨‍💼',
        color: '#3498DB',
      ));
    } else if (isTechnician) {
      badges.add(const UserBadge(
        id: 'technician',
        name: 'Technician',
        description: 'Technical specialist',
        icon: '🔧',
        color: '#2ECC71',
      ));
    }

    // Special badges
    badges.add(const UserBadge(
      id: 'team_player',
      name: 'Team Player',
      description: 'Active team member',
      icon: '🤝',
      color: '#E74C3C',
    ));

    return badges;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserProfile{id: $id, email: $email, fullName: $fullName, role: $role, points: $points}';
  }
}

class UserBadge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String color;

  const UserBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserBadge && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}