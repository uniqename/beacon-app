class Partner {
  final String id;
  final String name;
  final String type; // 'church' | 'police' | 'hospital' | 'counselor' | 'shelter' | 'legal' | 'ngo' | 'other'
  final String description;
  final String address;
  final String region;
  final String phone;
  final String? phone2;
  final String? whatsapp;
  final String? email;
  final String? website;
  final List<String> services;
  final String? hours;
  final String? imageUrl;
  final bool isVerified;
  final bool isBeaconPartner;
  final double? latitude;
  final double? longitude;

  const Partner({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.address,
    required this.region,
    required this.phone,
    this.phone2,
    this.whatsapp,
    this.email,
    this.website,
    required this.services,
    this.hours,
    this.imageUrl,
    this.isVerified = false,
    this.isBeaconPartner = false,
    this.latitude,
    this.longitude,
  });

  static const _typeLabels = {
    'church': 'Church',
    'police': 'Police / DOVVSU',
    'hospital': 'Hospital / Medical',
    'counselor': 'Counselor / Therapist',
    'shelter': 'Shelter / Safe House',
    'legal': 'Legal Aid',
    'ngo': 'NGO / Charity',
    'other': 'Other',
  };

  String get typeLabel => _typeLabels[type] ?? type;

  factory Partner.fromMap(Map<String, dynamic> map) => Partner(
        id: map['id'] as String,
        name: map['name'] as String,
        type: map['type'] as String,
        description: map['description'] as String? ?? '',
        address: map['address'] as String? ?? '',
        region: map['region'] as String? ?? 'Ghana',
        phone: map['phone'] as String,
        phone2: map['phone2'] as String?,
        whatsapp: map['whatsapp'] as String?,
        email: map['email'] as String?,
        website: map['website'] as String?,
        services: List<String>.from(map['services'] as List? ?? []),
        hours: map['hours'] as String?,
        imageUrl: map['image_url'] as String?,
        isVerified: map['is_verified'] as bool? ?? false,
        isBeaconPartner: map['is_beacon_partner'] as bool? ?? false,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'description': description,
        'address': address,
        'region': region,
        'phone': phone,
        'phone2': phone2,
        'whatsapp': whatsapp,
        'email': email,
        'website': website,
        'services': services,
        'hours': hours,
        'image_url': imageUrl,
        'is_verified': isVerified,
        'is_beacon_partner': isBeaconPartner,
        'latitude': latitude,
        'longitude': longitude,
      };
}
