class Machine {
  final String id;
  final String name;
  final String category;
  final String? model;
  final String? location;
  final String status;
  final DateTime? lastMaintenance;
  final DateTime? nextMaintenance;
  final DateTime createdAt;

  Machine({
    required this.id,
    required this.name,
    required this.category,
    this.model,
    this.location,
    required this.status,
    this.lastMaintenance,
    this.nextMaintenance,
    required this.createdAt,
  });

  factory Machine.fromJson(Map<String, dynamic> json) {
    return Machine(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Machine',
      category: json['category'] as String? ?? 'unknown',
      model: json['model'] as String?,
      location: json['location'] as String?,
      status: json['status'] as String? ?? 'operational',
      lastMaintenance: json['last_maintenance'] != null
          ? DateTime.parse(json['last_maintenance'] as String)
          : null,
      nextMaintenance: json['next_maintenance'] != null
          ? DateTime.parse(json['next_maintenance'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'model': model,
      'location': location,
      'status': status,
      'last_maintenance': lastMaintenance?.toIso8601String(),
      'next_maintenance': nextMaintenance?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Machine copyWith({
    String? id,
    String? name,
    String? category,
    String? model,
    String? location,
    String? status,
    DateTime? lastMaintenance,
    DateTime? nextMaintenance,
    DateTime? createdAt,
  }) {
    return Machine(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      model: model ?? this.model,
      location: location ?? this.location,
      status: status ?? this.status,
      lastMaintenance: lastMaintenance ?? this.lastMaintenance,
      nextMaintenance: nextMaintenance ?? this.nextMaintenance,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper methods
  String get statusIcon {
    switch (status.toLowerCase()) {
      case 'operational':
        return '✅';
      case 'maintenance':
        return '🔧';
      case 'down':
        return '❌';
      case 'retired':
        return '🚫';
      default:
        return '❓';
    }
  }

  String get statusDisplay {
    return status.replaceAll('_', ' ').split(' ').map((word) =>
        word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ');
  }

  bool get isOperational => status.toLowerCase() == 'operational';
  bool get isDown => status.toLowerCase() == 'down';
  bool get inMaintenance => status.toLowerCase() == 'maintenance';
  bool get isRetired => status.toLowerCase() == 'retired';

  bool get isMaintenanceDue {
    if (nextMaintenance == null) return false;
    return DateTime.now().isAfter(nextMaintenance!);
  }

  bool get isMaintenanceSoon {
    if (nextMaintenance == null) return false;
    final now = DateTime.now();
    final daysUntilMaintenance = nextMaintenance!.difference(now).inDays;
    return daysUntilMaintenance <= 7 && daysUntilMaintenance > 0;
  }

  String get maintenanceStatus {
    if (isMaintenanceDue) return 'Overdue';
    if (isMaintenanceSoon) return 'Due Soon';
    if (nextMaintenance != null) {
      final days = nextMaintenance!.difference(DateTime.now()).inDays;
      return 'Due in $days days';
    }
    return 'Not scheduled';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Machine && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Machine{id: $id, name: $name, category: $category, status: $status}';
  }
}