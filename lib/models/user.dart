enum UserType { survivor, counselor, admin, volunteer }

enum CaseStatus { active, closed, pending }

class AppUser {
  final String id;
  final String? email;
  final String? displayName;
  final String? phoneNumber;
  final UserType userType;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  
  // Survivor-specific fields
  final String? emergencyContact;
  final String? emergencyContactPhone;
  final List<String>? supportNeeds;
  final String? currentLocation;
  final bool hasActiveCases;
  
  // Staff-specific fields
  final String? specialization;
  final List<String>? qualifications;
  final bool isAvailable;

  const AppUser({
    required this.id,
    this.email,
    this.displayName,
    this.phoneNumber,
    this.userType = UserType.survivor,
    this.isAnonymous = true,
    required this.createdAt,
    this.lastLoginAt,
    this.emergencyContact,
    this.emergencyContactPhone,
    this.supportNeeds,
    this.currentLocation,
    this.hasActiveCases = false,
    this.specialization,
    this.qualifications,
    this.isAvailable = true,
  });

  factory AppUser.anonymous() {
    return AppUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      isAnonymous: true,
      userType: UserType.survivor,
    );
  }

  // User ID for local storage and backend API references
  factory AppUser.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser.fromMap(data);
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      email: map['email'],
      displayName: map['display_name'],
      phoneNumber: map['phone_number'],
      userType: UserType.values.firstWhere(
        (e) => e.toString().split('.').last == map['user_type'],
        orElse: () => UserType.survivor,
      ),
      isAnonymous: map['is_anonymous'] == 1 || map['is_anonymous'] == true,
      createdAt: DateTime.parse(map['created_at']),
      lastLoginAt: map['last_login_at'] != null 
          ? DateTime.parse(map['last_login_at']) 
          : null,
      emergencyContact: map['emergency_contact'],
      emergencyContactPhone: map['emergency_contact_phone'],
      supportNeeds: map['support_needs'] != null 
          ? List<String>.from(map['support_needs'].split(',')) 
          : null,
      currentLocation: map['current_location'],
      hasActiveCases: map['has_active_cases'] == 1 || map['has_active_cases'] == true,
      specialization: map['specialization'],
      qualifications: map['qualifications'] != null 
          ? List<String>.from(map['qualifications'].split(',')) 
          : null,
      isAvailable: map['is_available'] == 1 || map['is_available'] == true,
    );
  }

  // User ID for local storage and backend API references
  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'phone_number': phoneNumber,
      'user_type': userType.toString().split('.').last,
      'is_anonymous': isAnonymous ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'emergency_contact': emergencyContact,
      'emergency_contact_phone': emergencyContactPhone,
      'support_needs': supportNeeds?.join(','),
      'current_location': currentLocation,
      'has_active_cases': hasActiveCases ? 1 : 0,
      'specialization': specialization,
      'qualifications': qualifications?.join(','),
      'is_available': isAvailable ? 1 : 0,
    };
  }

  AppUser copyWith({
    String? displayName,
    String? phoneNumber,
    UserType? userType,
    bool? isAnonymous,
    DateTime? lastLoginAt,
    String? emergencyContact,
    String? emergencyContactPhone,
    List<String>? supportNeeds,
    String? currentLocation,
    bool? hasActiveCases,
    String? specialization,
    List<String>? qualifications,
    bool? isAvailable,
  }) {
    return AppUser(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userType: userType ?? this.userType,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      supportNeeds: supportNeeds ?? this.supportNeeds,
      currentLocation: currentLocation ?? this.currentLocation,
      hasActiveCases: hasActiveCases ?? this.hasActiveCases,
      specialization: specialization ?? this.specialization,
      qualifications: qualifications ?? this.qualifications,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  String get name {
    if (isAnonymous) return 'Anonymous User';
    if (displayName != null) return displayName!;
    if (email != null) return email!;
    return 'User';
  }

  bool get hasContactInfo {
    return email != null || phoneNumber != null;
  }
}