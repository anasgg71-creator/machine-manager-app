import 'user_profile.dart';

class TodoItem {
  final String id;
  final String ticketId;
  final String description;
  final bool isCompleted;
  final String createdBy;
  final String? completedBy;
  final DateTime createdAt;
  final DateTime? completedAt;
  final UserProfile? createdByProfile;
  final UserProfile? completedByProfile;

  TodoItem({
    required this.id,
    required this.ticketId,
    required this.description,
    required this.isCompleted,
    required this.createdBy,
    this.completedBy,
    required this.createdAt,
    this.completedAt,
    this.createdByProfile,
    this.completedByProfile,
  });

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      description: json['description'] as String,
      isCompleted: json['is_completed'] as bool? ?? false,
      createdBy: json['created_by'] as String,
      completedBy: json['completed_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdByProfile: json['created_by_profile'] != null
          ? UserProfile.fromJson(json['created_by_profile'] as Map<String, dynamic>)
          : null,
      completedByProfile: json['completed_by_profile'] != null
          ? UserProfile.fromJson(json['completed_by_profile'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'description': description,
      'is_completed': isCompleted,
      'created_by': createdBy,
      'completed_by': completedBy,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  TodoItem copyWith({
    String? id,
    String? ticketId,
    String? description,
    bool? isCompleted,
    String? createdBy,
    String? completedBy,
    DateTime? createdAt,
    DateTime? completedAt,
    UserProfile? createdByProfile,
    UserProfile? completedByProfile,
  }) {
    return TodoItem(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdBy: createdBy ?? this.createdBy,
      completedBy: completedBy ?? this.completedBy,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      createdByProfile: createdByProfile ?? this.createdByProfile,
      completedByProfile: completedByProfile ?? this.completedByProfile,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}