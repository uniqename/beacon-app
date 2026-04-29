class BeaconDivision {
  final String id;
  final String name;
  final String shortName;
  final String description;
  final String icon;
  final String color;
  final List<String> services;
  final List<String> resources;
  final bool isAvailable;
  final int capacity;
  final String contactEmail;
  final String contactPhone;
  final String donationUrl;
  final List<JobOpportunity> jobOpenings;

  BeaconDivision({
    required this.id,
    required this.name,
    required this.shortName,
    required this.description,
    required this.icon,
    required this.color,
    required this.services,
    required this.resources,
    required this.isAvailable,
    required this.capacity,
    required this.contactEmail,
    required this.contactPhone,
    required this.donationUrl,
    required this.jobOpenings,
  });

  factory BeaconDivision.fromJson(Map<String, dynamic> json) {
    return BeaconDivision(
      id: json['id'],
      name: json['name'],
      shortName: json['shortName'],
      description: json['description'],
      icon: json['icon'],
      color: json['color'],
      services: List<String>.from(json['services']),
      resources: List<String>.from(json['resources']),
      isAvailable: json['isAvailable'],
      capacity: json['capacity'],
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      donationUrl: json['donationUrl'],
      jobOpenings: (json['jobOpenings'] as List)
          .map((job) => JobOpportunity.fromJson(job))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'shortName': shortName,
      'description': description,
      'icon': icon,
      'color': color,
      'services': services,
      'resources': resources,
      'isAvailable': isAvailable,
      'capacity': capacity,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'donationUrl': donationUrl,
      'jobOpenings': jobOpenings.map((job) => job.toJson()).toList(),
    };
  }
}

class JobOpportunity {
  final String id;
  final String title;
  final String type; // volunteer, part-time, full-time
  final String description;
  final List<String> requirements;
  final String location;
  final bool isRemote;
  final String applicationEmail;
  final DateTime postedDate;
  final bool isUrgent;

  JobOpportunity({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.requirements,
    required this.location,
    required this.isRemote,
    required this.applicationEmail,
    required this.postedDate,
    required this.isUrgent,
  });

  factory JobOpportunity.fromJson(Map<String, dynamic> json) {
    return JobOpportunity(
      id: json['id'],
      title: json['title'],
      type: json['type'],
      description: json['description'],
      requirements: List<String>.from(json['requirements']),
      location: json['location'],
      isRemote: json['isRemote'],
      applicationEmail: json['applicationEmail'],
      postedDate: DateTime.parse(json['postedDate']),
      isUrgent: json['isUrgent'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'description': description,
      'requirements': requirements,
      'location': location,
      'isRemote': isRemote,
      'applicationEmail': applicationEmail,
      'postedDate': postedDate.toIso8601String(),
      'isUrgent': isUrgent,
    };
  }
}