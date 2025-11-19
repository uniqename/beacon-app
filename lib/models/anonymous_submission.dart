class AnonymousSubmission {
  final String id;
  final String type; // 'help_request', 'resource_need', 'emergency_info'
  final String description;
  final String? location;
  final String? contactMethod; // 'phone', 'email', 'in_person', 'none'
  final String? contactInfo;
  final String urgencyLevel; // 'low', 'medium', 'high', 'critical'
  final Map<String, dynamic> additionalData;
  final DateTime submittedAt;
  final String status; // 'pending', 'in_progress', 'completed'

  AnonymousSubmission({
    required this.id,
    required this.type,
    required this.description,
    this.location,
    this.contactMethod,
    this.contactInfo,
    required this.urgencyLevel,
    required this.additionalData,
    required this.submittedAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'location': location,
      'contactMethod': contactMethod,
      'contactInfo': contactInfo,
      'urgencyLevel': urgencyLevel,
      'additionalData': additionalData,
      'submittedAt': submittedAt.toIso8601String(),
      'status': status,
    };
  }

  factory AnonymousSubmission.fromMap(Map<String, dynamic> map) {
    return AnonymousSubmission(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      description: map['description'] ?? '',
      location: map['location'],
      contactMethod: map['contactMethod'],
      contactInfo: map['contactInfo'],
      urgencyLevel: map['urgencyLevel'] ?? 'medium',
      additionalData: Map<String, dynamic>.from(map['additionalData'] ?? {}),
      submittedAt: DateTime.parse(map['submittedAt']),
      status: map['status'] ?? 'pending',
    );
  }

  AnonymousSubmission copyWith({
    String? id,
    String? type,
    String? description,
    String? location,
    String? contactMethod,
    String? contactInfo,
    String? urgencyLevel,
    Map<String, dynamic>? additionalData,
    DateTime? submittedAt,
    String? status,
  }) {
    return AnonymousSubmission(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      location: location ?? this.location,
      contactMethod: contactMethod ?? this.contactMethod,
      contactInfo: contactInfo ?? this.contactInfo,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      additionalData: additionalData ?? this.additionalData,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
    );
  }

  String get urgencyColor {
    switch (urgencyLevel) {
      case 'critical':
        return '#E53935'; // Red
      case 'high':
        return '#FF9800'; // Orange
      case 'medium':
        return '#FFC107'; // Amber
      case 'low':
        return '#4CAF50'; // Green
      default:
        return '#9E9E9E'; // Grey
    }
  }

  String get typeDisplayName {
    switch (type) {
      case 'help_request':
        return 'Help Request';
      case 'resource_need':
        return 'Resource Need';
      case 'emergency_info':
        return 'Emergency Information';
      default:
        return 'Submission';
    }
  }
}