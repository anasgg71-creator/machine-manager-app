import 'user_profile.dart';
import 'machine.dart';

class Ticket {
  final String id;
  final String title;
  final String description;
  final String? machineId;
  final String problemType;
  final String priority;
  final String status;
  final String? resolution;
  final String creatorId;
  final String? assigneeId;
  final String? resolverId;
  final int? rating;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final DateTime expiresAt;
  final bool autoCloseWarned;
  final List<String>? fishboneAnalysis;
  final List<Map<String, dynamic>>? updateHistory;
  final DateTime? lastUpdatedAt;

  // Related objects
  final UserProfile? creator;
  final UserProfile? assignee;
  final UserProfile? resolver;
  final Machine? machine;

  Ticket({
    required this.id,
    required this.title,
    required this.description,
    this.machineId,
    required this.problemType,
    required this.priority,
    required this.status,
    this.resolution,
    required this.creatorId,
    this.assigneeId,
    this.resolverId,
    this.rating,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    required this.expiresAt,
    this.autoCloseWarned = false,
    this.fishboneAnalysis,
    this.updateHistory,
    this.lastUpdatedAt,
    this.creator,
    this.assignee,
    this.resolver,
    this.machine,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      machineId: json['machine_id'] as String?,
      problemType: json['problem_type'] as String,
      priority: json['priority'] as String,
      status: json['status'] as String,
      resolution: json['resolution'] as String?,
      creatorId: json['creator_id'] as String,
      assigneeId: json['assignee_id'] as String?,
      resolverId: json['resolver_id'] as String?,
      rating: json['rating'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      autoCloseWarned: json['auto_close_warned'] as bool? ?? false,
      fishboneAnalysis: json['fishbone_analysis'] != null
          ? List<String>.from(json['fishbone_analysis'] as List)
          : null,
      updateHistory: json['update_history'] != null
          ? List<Map<String, dynamic>>.from(json['update_history'] as List)
          : null,
      lastUpdatedAt: json['last_updated_at'] != null
          ? DateTime.parse(json['last_updated_at'] as String)
          : null,
      creator: json['creator'] != null
          ? UserProfile.fromJson(json['creator'] as Map<String, dynamic>)
          : null,
      assignee: json['assignee'] != null
          ? UserProfile.fromJson(json['assignee'] as Map<String, dynamic>)
          : null,
      resolver: json['resolver'] != null
          ? UserProfile.fromJson(json['resolver'] as Map<String, dynamic>)
          : null,
      machine: json['machine'] != null
          ? Machine.fromJson(json['machine'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'machine_id': machineId,
      'problem_type': problemType,
      'priority': priority,
      'status': status,
      'resolution': resolution,
      'creator_id': creatorId,
      'assignee_id': assigneeId,
      'resolver_id': resolverId,
      'rating': rating,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'auto_close_warned': autoCloseWarned,
      'fishbone_analysis': fishboneAnalysis,
      'update_history': updateHistory,
      'last_updated_at': lastUpdatedAt?.toIso8601String(),
    };
  }

  Ticket copyWith({
    String? id,
    String? title,
    String? description,
    String? machineId,
    String? problemType,
    String? priority,
    String? status,
    String? resolution,
    String? creatorId,
    String? assigneeId,
    String? resolverId,
    int? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    DateTime? expiresAt,
    bool? autoCloseWarned,
    List<String>? fishboneAnalysis,
    List<Map<String, dynamic>>? updateHistory,
    DateTime? lastUpdatedAt,
    UserProfile? creator,
    UserProfile? assignee,
    UserProfile? resolver,
    Machine? machine,
  }) {
    return Ticket(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      machineId: machineId ?? this.machineId,
      problemType: problemType ?? this.problemType,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      resolution: resolution ?? this.resolution,
      creatorId: creatorId ?? this.creatorId,
      assigneeId: assigneeId ?? this.assigneeId,
      resolverId: resolverId ?? this.resolverId,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      autoCloseWarned: autoCloseWarned ?? this.autoCloseWarned,
      fishboneAnalysis: fishboneAnalysis ?? this.fishboneAnalysis,
      updateHistory: updateHistory ?? this.updateHistory,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      creator: creator ?? this.creator,
      assignee: assignee ?? this.assignee,
      resolver: resolver ?? this.resolver,
      machine: machine ?? this.machine,
    );
  }

  // Helper methods
  String get priorityIcon {
    switch (priority.toLowerCase()) {
      case 'critical':
        return '🔴';
      case 'high':
        return '🟠';
      case 'medium':
        return '🟡';
      case 'low':
        return '🟢';
      default:
        return '⚪';
    }
  }

  String get statusIcon {
    switch (status.toLowerCase()) {
      case 'open':
        return '🔵';
      case 'in_progress':
        return '🟡';
      case 'resolved':
        return '✅';
      case 'closed':
        return '🔒';
      default:
        return '⚪';
    }
  }

  String get problemTypeIcon {
    switch (problemType.toLowerCase()) {
      case 'mechanical':
        return '🔧';
      case 'electrical':
        return '⚡';
      case 'software':
        return '💻';
      case 'maintenance':
        return '🛠️';
      case 'general':
        return '❓';
      default:
        return '📋';
    }
  }

  String get statusDisplay {
    return status.replaceAll('_', ' ').split(' ').map((word) =>
        word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ');
  }

  String get priorityDisplay {
    return priority[0].toUpperCase() + priority.substring(1).toLowerCase();
  }

  String get problemTypeDisplay {
    return problemType[0].toUpperCase() + problemType.substring(1).toLowerCase();
  }

  bool get isOpen => status.toLowerCase() == 'open';
  bool get isInProgress => status.toLowerCase() == 'in_progress';
  bool get isResolved => status.toLowerCase() == 'resolved';
  bool get isClosed => status.toLowerCase() == 'closed';

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isExpiringSoon {
    final now = DateTime.now();
    final hoursUntilExpiry = expiresAt.difference(now).inHours;
    return hoursUntilExpiry <= 12 && hoursUntilExpiry > 0;
  }

  bool get isCritical => priority.toLowerCase() == 'critical';
  bool get isHigh => priority.toLowerCase() == 'high';

  Duration get timeToExpiry => expiresAt.difference(DateTime.now());
  Duration get age => DateTime.now().difference(createdAt);

  bool get hasBeenUpdated => lastUpdatedAt != null;
  bool get hasFishboneAnalysis => fishboneAnalysis != null && fishboneAnalysis!.isNotEmpty;

  String get timeToExpiryDisplay {
    if (isExpired) return 'Expired';

    final duration = timeToExpiry;
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return 'Expiring soon';
    }
  }

  String get ageDisplay {
    final duration = age;
    if (duration.inDays > 0) {
      return '${duration.inDays}d ago';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ago';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get resolutionTimeDisplay {
    if (resolvedAt == null) return '';

    final duration = resolvedAt!.difference(createdAt);
    if (duration.inDays > 0) {
      return 'Resolved in ${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return 'Resolved in ${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return 'Resolved in ${duration.inMinutes}m';
    } else {
      return 'Resolved immediately';
    }
  }

  // Calculate points this ticket would award
  int get potentialPoints {
    int basePoints = 10;

    // Priority bonus
    switch (priority.toLowerCase()) {
      case 'critical':
        basePoints += 15;
        break;
      case 'high':
        basePoints += 10;
        break;
      case 'medium':
        basePoints += 5;
        break;
      case 'low':
        basePoints += 0;
        break;
    }

    // Quick resolution bonus (resolved within 4 hours)
    if (resolvedAt != null && resolvedAt!.difference(createdAt).inHours <= 4) {
      basePoints += 5;
    }

    // Rating bonus
    if (rating != null) {
      basePoints += rating! * 2;
    }

    return basePoints;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ticket && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Ticket{id: $id, title: $title, status: $status, priority: $priority}';
  }
}