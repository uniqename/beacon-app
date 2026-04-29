enum CaseType { 
  shelter, 
  counseling, 
  legal, 
  medical, 
  financial, 
  employment, 
  education,
  emergency 
}

enum CasePriority { low, medium, high, critical }

enum CaseStatus { pending, active, inProgress, completed, closed }

class SupportCase {
  final String id;
  final String survivorId;
  final String? assignedCounselorId;
  final CaseType type;
  final CasePriority priority;
  final CaseStatus status;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final List<String> notes;
  final List<String> attachments;
  final Map<String, dynamic>? metadata;
  final bool isAnonymous;
  final String? location;
  final double? latitude;
  final double? longitude;

  const SupportCase({
    required this.id,
    required this.survivorId,
    this.assignedCounselorId,
    required this.type,
    required this.priority,
    required this.status,
    required this.title,
    required this.description,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.notes = const [],
    this.attachments = const [],
    this.metadata,
    this.isAnonymous = true,
    this.location,
    this.latitude,
    this.longitude,
  });

  factory SupportCase.fromMap(Map<String, dynamic> map) {
    return SupportCase(
      id: map['id'] ?? '',
      survivorId: map['survivor_id'] ?? map['user_id'] ?? '',
      assignedCounselorId: map['assigned_counselor_id'],
      type: CaseType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => CaseType.emergency,
      ),
      priority: CasePriority.values.firstWhere(
        (e) => e.toString().split('.').last == map['priority'],
        orElse: () => CasePriority.medium,
      ),
      status: CaseStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => CaseStatus.pending,
      ),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : null,
      completedAt: map['completed_at'] != null 
          ? DateTime.parse(map['completed_at']) 
          : null,
      notes: map['notes'] != null 
          ? List<String>.from(map['notes'].split('|||')) 
          : [],
      attachments: map['attachments'] != null 
          ? List<String>.from(map['attachments'].split('|||')) 
          : [],
      metadata: map['metadata'],
      isAnonymous: map['is_anonymous'] == 1 || map['is_anonymous'] == true,
      location: map['location'],
      latitude: map['location_lat']?.toDouble(),
      longitude: map['location_lng']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'survivor_id': survivorId,
      'assigned_counselor_id': assignedCounselorId,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'status': status.toString().split('.').last,
      'title': title,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'notes': notes.join('|||'),
      'attachments': attachments.join('|||'),
      'metadata': metadata,
      'is_anonymous': isAnonymous ? 1 : 0,
      'location': location,
      'location_lat': latitude,
      'location_lng': longitude,
    };
  }

  SupportCase copyWith({
    String? assignedCounselorId,
    CasePriority? priority,
    CaseStatus? status,
    String? title,
    String? description,
    DateTime? updatedAt,
    DateTime? completedAt,
    List<String>? notes,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
    bool? isAnonymous,
    String? location,
    double? latitude,
    double? longitude,
  }) {
    return SupportCase(
      id: id,
      survivorId: survivorId,
      assignedCounselorId: assignedCounselorId ?? this.assignedCounselorId,
      type: type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  String get priorityDisplayName {
    switch (priority) {
      case CasePriority.low:
        return 'Low';
      case CasePriority.medium:
        return 'Medium';
      case CasePriority.high:
        return 'High';
      case CasePriority.critical:
        return 'Critical';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case CaseType.shelter:
        return 'Shelter';
      case CaseType.counseling:
        return 'Counseling';
      case CaseType.legal:
        return 'Legal Support';
      case CaseType.medical:
        return 'Medical Care';
      case CaseType.financial:
        return 'Financial Aid';
      case CaseType.employment:
        return 'Employment';
      case CaseType.education:
        return 'Education';
      case CaseType.emergency:
        return 'Emergency';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case CaseStatus.pending:
        return 'Pending';
      case CaseStatus.active:
        return 'Active';
      case CaseStatus.inProgress:
        return 'In Progress';
      case CaseStatus.completed:
        return 'Completed';
      case CaseStatus.closed:
        return 'Closed';
    }
  }
}