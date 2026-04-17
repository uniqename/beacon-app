class SafetyPlan {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Emergency Contacts
  final List<EmergencyContact> emergencyContacts;

  // Safe Places
  final List<SafePlace> safePlaces;

  // Escape Plan
  final EscapePlan? escapePlan;

  // Essential Items
  final List<String> essentialItems;
  final List<String> checkedItems;

  // Code Words
  final String? dangerCodeWord;
  final String? helpCodeWord;

  // Children Safety
  final List<Child> children;

  // Pet Safety
  final List<Pet> pets;

  // Financial Safety
  final List<HiddenSaving> hiddenSavings;

  // Digital Safety
  final DigitalSafetyPlan? digitalSafety;

  // Progress tracking
  final double completionPercentage;

  SafetyPlan({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.emergencyContacts = const [],
    this.safePlaces = const [],
    this.escapePlan,
    this.essentialItems = const [],
    this.checkedItems = const [],
    this.dangerCodeWord,
    this.helpCodeWord,
    this.children = const [],
    this.pets = const [],
    this.hiddenSavings = const [],
    this.digitalSafety,
    this.completionPercentage = 0.0,
  });

  SafetyPlan copyWith({
    String? id,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<EmergencyContact>? emergencyContacts,
    List<SafePlace>? safePlaces,
    EscapePlan? escapePlan,
    List<String>? essentialItems,
    List<String>? checkedItems,
    String? dangerCodeWord,
    String? helpCodeWord,
    List<Child>? children,
    List<Pet>? pets,
    List<HiddenSaving>? hiddenSavings,
    DigitalSafetyPlan? digitalSafety,
    double? completionPercentage,
  }) {
    return SafetyPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      safePlaces: safePlaces ?? this.safePlaces,
      escapePlan: escapePlan ?? this.escapePlan,
      essentialItems: essentialItems ?? this.essentialItems,
      checkedItems: checkedItems ?? this.checkedItems,
      dangerCodeWord: dangerCodeWord ?? this.dangerCodeWord,
      helpCodeWord: helpCodeWord ?? this.helpCodeWord,
      children: children ?? this.children,
      pets: pets ?? this.pets,
      hiddenSavings: hiddenSavings ?? this.hiddenSavings,
      digitalSafety: digitalSafety ?? this.digitalSafety,
      completionPercentage: completionPercentage ?? this.completionPercentage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'emergencyContacts': emergencyContacts.map((c) => c.toJson()).toList(),
      'safePlaces': safePlaces.map((p) => p.toJson()).toList(),
      'escapePlan': escapePlan?.toJson(),
      'essentialItems': essentialItems,
      'checkedItems': checkedItems,
      'dangerCodeWord': dangerCodeWord,
      'helpCodeWord': helpCodeWord,
      'children': children.map((c) => c.toJson()).toList(),
      'pets': pets.map((p) => p.toJson()).toList(),
      'hiddenSavings': hiddenSavings.map((h) => h.toJson()).toList(),
      'digitalSafety': digitalSafety?.toJson(),
      'completionPercentage': completionPercentage,
    };
  }

  Map<String, dynamic> toMap() => toJson();

  factory SafetyPlan.fromJson(Map<String, dynamic> json) {
    return SafetyPlan(
      id: json['id'] as String,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      emergencyContacts: (json['emergencyContacts'] as List?)
          ?.map((c) => EmergencyContact.fromJson(c as Map<String, dynamic>))
          .toList() ?? [],
      safePlaces: (json['safePlaces'] as List?)
          ?.map((p) => SafePlace.fromJson(p as Map<String, dynamic>))
          .toList() ?? [],
      escapePlan: json['escapePlan'] != null
          ? EscapePlan.fromJson(json['escapePlan'] as Map<String, dynamic>)
          : null,
      essentialItems: (json['essentialItems'] as List?)?.cast<String>() ?? [],
      checkedItems: (json['checkedItems'] as List?)?.cast<String>() ?? [],
      dangerCodeWord: json['dangerCodeWord'] as String?,
      helpCodeWord: json['helpCodeWord'] as String?,
      children: (json['children'] as List?)
          ?.map((c) => Child.fromJson(c as Map<String, dynamic>))
          .toList() ?? [],
      pets: (json['pets'] as List?)
          ?.map((p) => Pet.fromJson(p as Map<String, dynamic>))
          .toList() ?? [],
      hiddenSavings: (json['hiddenSavings'] as List?)
          ?.map((h) => HiddenSaving.fromJson(h as Map<String, dynamic>))
          .toList() ?? [],
      digitalSafety: json['digitalSafety'] != null
          ? DigitalSafetyPlan.fromJson(json['digitalSafety'] as Map<String, dynamic>)
          : null,
      completionPercentage: (json['completionPercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String relationship;
  final bool isTrusted;
  final bool canProvideShelter;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
    this.isTrusted = false,
    this.canProvideShelter = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'relationship': relationship,
    'isTrusted': isTrusted,
    'canProvideShelter': canProvideShelter,
  };

  Map<String, dynamic> toMap() => toJson();

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      relationship: json['relationship'] as String,
      isTrusted: json['isTrusted'] as bool? ?? false,
      canProvideShelter: json['canProvideShelter'] as bool? ?? false,
    );
  }

  factory EmergencyContact.fromMap(Map<String, dynamic> map) => EmergencyContact.fromJson(map);
}

class SafePlace {
  final String id;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? operatingHours;
  final String? notes;

  SafePlace({
    required this.id,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    this.operatingHours,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'operatingHours': operatingHours,
    'notes': notes,
  };

  Map<String, dynamic> toMap() => toJson();

  factory SafePlace.fromJson(Map<String, dynamic> json) {
    return SafePlace(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      operatingHours: json['operatingHours'] as String?,
      notes: json['notes'] as String?,
    );
  }

  factory SafePlace.fromMap(Map<String, dynamic> map) => SafePlace.fromJson(map);
}

class EscapePlan {
  final String primaryRoute;
  final String backupRoute;
  final List<String> hidingPlaces;
  final String transportation;
  final String? notes;

  EscapePlan({
    required this.primaryRoute,
    required this.backupRoute,
    this.hidingPlaces = const [],
    required this.transportation,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'primaryRoute': primaryRoute,
    'backupRoute': backupRoute,
    'hidingPlaces': hidingPlaces,
    'transportation': transportation,
    'notes': notes,
  };

  Map<String, dynamic> toMap() => toJson();

  factory EscapePlan.fromJson(Map<String, dynamic> json) {
    return EscapePlan(
      primaryRoute: json['primaryRoute'] as String,
      backupRoute: json['backupRoute'] as String,
      hidingPlaces: (json['hidingPlaces'] as List?)?.cast<String>() ?? [],
      transportation: json['transportation'] as String,
      notes: json['notes'] as String?,
    );
  }

  factory EscapePlan.fromMap(Map<String, dynamic> map) => EscapePlan.fromJson(map);
}

class Child {
  final String id;
  final String name;
  final int age;
  final String school;
  final String schoolAddress;
  final String specialNeeds;
  final String medicationsAndAllergies;

  Child({
    required this.id,
    required this.name,
    required this.age,
    this.school = '',
    this.schoolAddress = '',
    this.specialNeeds = '',
    this.medicationsAndAllergies = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'age': age,
    'school': school,
    'schoolAddress': schoolAddress,
    'specialNeeds': specialNeeds,
    'medicationsAndAllergies': medicationsAndAllergies,
  };

  Map<String, dynamic> toMap() => toJson();

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      school: json['school'] as String? ?? '',
      schoolAddress: json['schoolAddress'] as String? ?? '',
      specialNeeds: json['specialNeeds'] as String? ?? '',
      medicationsAndAllergies: json['medicationsAndAllergies'] as String? ?? '',
    );
  }

  factory Child.fromMap(Map<String, dynamic> map) => Child.fromJson(map);
}

class Pet {
  final String id;
  final String name;
  final String type;
  final String breed;
  final String specialNeeds;

  Pet({
    required this.id,
    required this.name,
    required this.type,
    this.breed = '',
    this.specialNeeds = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'breed': breed,
    'specialNeeds': specialNeeds,
  };

  Map<String, dynamic> toMap() => toJson();

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      breed: json['breed'] as String? ?? '',
      specialNeeds: json['specialNeeds'] as String? ?? '',
    );
  }

  factory Pet.fromMap(Map<String, dynamic> map) => Pet.fromJson(map);
}

class HiddenSaving {
  final String id;
  final String location;
  final double amount;
  final String? notes;

  HiddenSaving({
    required this.id,
    required this.location,
    required this.amount,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'location': location,
    'amount': amount,
    'notes': notes,
  };

  Map<String, dynamic> toMap() => toJson();

  factory HiddenSaving.fromJson(Map<String, dynamic> json) {
    return HiddenSaving(
      id: json['id'] as String,
      location: json['location'] as String,
      amount: (json['amount'] as num).toDouble(),
      notes: json['notes'] as String?,
    );
  }

  factory HiddenSaving.fromMap(Map<String, dynamic> map) => HiddenSaving.fromJson(map);
}

class DigitalSafetyPlan {
  final bool hasChangedPasswords;
  final bool hasSecuredDevices;
  final bool hasDisabledLocationSharing;
  final bool hasReviewedPrivacySettings;
  final bool hasBackedUpImportantData;
  final String notes;

  DigitalSafetyPlan({
    this.hasChangedPasswords = false,
    this.hasSecuredDevices = false,
    this.hasDisabledLocationSharing = false,
    this.hasReviewedPrivacySettings = false,
    this.hasBackedUpImportantData = false,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
    'hasChangedPasswords': hasChangedPasswords,
    'hasSecuredDevices': hasSecuredDevices,
    'hasDisabledLocationSharing': hasDisabledLocationSharing,
    'hasReviewedPrivacySettings': hasReviewedPrivacySettings,
    'hasBackedUpImportantData': hasBackedUpImportantData,
    'notes': notes,
  };

  Map<String, dynamic> toMap() => toJson();

  factory DigitalSafetyPlan.fromJson(Map<String, dynamic> json) {
    return DigitalSafetyPlan(
      hasChangedPasswords: json['hasChangedPasswords'] as bool? ?? false,
      hasSecuredDevices: json['hasSecuredDevices'] as bool? ?? false,
      hasDisabledLocationSharing: json['hasDisabledLocationSharing'] as bool? ?? false,
      hasReviewedPrivacySettings: json['hasReviewedPrivacySettings'] as bool? ?? false,
      hasBackedUpImportantData: json['hasBackedUpImportantData'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
    );
  }

  factory DigitalSafetyPlan.fromMap(Map<String, dynamic> map) => DigitalSafetyPlan.fromJson(map);
}
