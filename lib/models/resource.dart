enum ResourceType { 
  shelter, 
  counseling, 
  legal, 
  medical, 
  financial, 
  employment, 
  education,
  hotline,
  emergency 
}

enum ResourceStatus { available, unavailable, limited }

class Resource {
  final String id;
  final String name;
  final String description;
  final ResourceType type;
  final ResourceStatus status;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final List<String> services;
  final Map<String, String> operatingHours;
  final bool requiresAppointment;
  final bool is24Hours;
  final double? latitude;
  final double? longitude;
  final List<String> eligibilityCriteria;
  final String? contactPerson;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int capacity;
  final int currentOccupancy;

  const Resource({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.status,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.services = const [],
    this.operatingHours = const {},
    this.requiresAppointment = false,
    this.is24Hours = false,
    this.latitude,
    this.longitude,
    this.eligibilityCriteria = const [],
    this.contactPerson,
    required this.createdAt,
    this.updatedAt,
    this.capacity = 0,
    this.currentOccupancy = 0,
  });

  // For backward compatibility with Firebase references
  factory Resource.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id; // Ensure ID is set from document ID
    return Resource.fromMap(data);
  }

  factory Resource.fromMap(Map<String, dynamic> data) {
    return Resource(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: ResourceType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => ResourceType.emergency,
      ),
      status: ResourceStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => ResourceStatus.available,
      ),
      address: data['address'],
      phone: data['phone'],
      email: data['email'],
      website: data['website'],
      services: data['services'] != null 
          ? List<String>.from(data['services']) 
          : [],
      operatingHours: data['operatingHours'] != null 
          ? Map<String, String>.from(data['operatingHours']) 
          : {},
      requiresAppointment: data['requiresAppointment'] ?? false,
      is24Hours: data['is24Hours'] ?? false,
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      eligibilityCriteria: data['eligibilityCriteria'] != null 
          ? List<String>.from(data['eligibilityCriteria']) 
          : [],
      contactPerson: data['contactPerson'],
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: data['updatedAt'] != null 
          ? DateTime.parse(data['updatedAt']) 
          : null,
      capacity: data['capacity'] ?? 0,
      currentOccupancy: data['currentOccupancy'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'services': services,
      'operatingHours': operatingHours,
      'requiresAppointment': requiresAppointment,
      'is24Hours': is24Hours,
      'latitude': latitude,
      'longitude': longitude,
      'eligibilityCriteria': eligibilityCriteria,
      'contactPerson': contactPerson,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'capacity': capacity,
      'currentOccupancy': currentOccupancy,
    };
  }

  bool get hasAvailableSpace => capacity > 0 && currentOccupancy < capacity;

  double get occupancyRate => capacity > 0 ? (currentOccupancy / capacity) : 0.0;

  String get typeDisplayName {
    switch (type) {
      case ResourceType.shelter:
        return 'Shelter';
      case ResourceType.counseling:
        return 'Counseling';
      case ResourceType.legal:
        return 'Legal Support';
      case ResourceType.medical:
        return 'Medical Care';
      case ResourceType.financial:
        return 'Financial Aid';
      case ResourceType.employment:
        return 'Employment';
      case ResourceType.education:
        return 'Education';
      case ResourceType.hotline:
        return 'Hotline';
      case ResourceType.emergency:
        return 'Emergency';
    }
  }
}