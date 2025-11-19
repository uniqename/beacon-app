enum UserType { survivor, counselor, admin, volunteer }

class AppUser {
  final String uid;
  final String email;
  final String name;
  final String? phone;
  final UserType userType;
  final String? profilePictureUrl;
  final List<String> emergencyContacts;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final String? location;
  final List<String> preferredLanguages;
  final Map<String, dynamic> preferences;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    required this.userType,
    this.profilePictureUrl,
    this.emergencyContacts = const [],
    this.isAnonymous = false,
    required this.createdAt,
    this.lastLoginAt,
    this.isActive = true,
    this.location,
    this.preferredLanguages = const ['en'],
    this.preferences = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'userType': userType.toString().split('.').last,
      'profilePictureUrl': profilePictureUrl,
      'emergencyContacts': emergencyContacts,
      'isAnonymous': isAnonymous,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isActive': isActive,
      'location': location,
      'preferredLanguages': preferredLanguages,
      'preferences': preferences,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'],
      userType: UserType.values.firstWhere(
        (e) => e.toString().split('.').last == data['userType'],
        orElse: () => UserType.survivor,
      ),
      profilePictureUrl: data['profilePictureUrl'],
      emergencyContacts: List<String>.from(data['emergencyContacts'] ?? []),
      isAnonymous: data['isAnonymous'] ?? false,
      createdAt: DateTime.parse(data['createdAt']),
      lastLoginAt: data['lastLoginAt'] != null 
          ? DateTime.parse(data['lastLoginAt']) 
          : null,
      isActive: data['isActive'] ?? true,
      location: data['location'],
      preferredLanguages: List<String>.from(data['preferredLanguages'] ?? ['en']),
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
    );
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? name,
    String? phone,
    UserType? userType,
    String? profilePictureUrl,
    List<String>? emergencyContacts,
    bool? isAnonymous,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    String? location,
    List<String>? preferredLanguages,
    Map<String, dynamic>? preferences,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      location: location ?? this.location,
      preferredLanguages: preferredLanguages ?? this.preferredLanguages,
      preferences: preferences ?? this.preferences,
    );
  }
}