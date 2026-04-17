enum EvidenceType { photo, audio, document, medical, message, other }
enum Severity { low, medium, high, critical }

class EvidenceLog {
  final String id;
  final String userId;
  final DateTime incidentDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  final String title;
  final String description;
  final Severity severity;
  final String location;

  final List<String> photoUrls;
  final List<String> audioUrls;
  final List<String> documentUrls;

  final List<String> witnesses;
  final bool policeInvolved;
  final String? policeReportNumber;
  final bool medicalAttention;
  final String? hospitalName;

  final Map<String, dynamic>? metadata;
  final bool isEncrypted;

  EvidenceLog({
    required this.id,
    required this.userId,
    required this.incidentDate,
    required this.createdAt,
    required this.updatedAt,
    required this.title,
    required this.description,
    required this.severity,
    required this.location,
    this.photoUrls = const [],
    this.audioUrls = const [],
    this.documentUrls = const [],
    this.witnesses = const [],
    this.policeInvolved = false,
    this.policeReportNumber,
    this.medicalAttention = false,
    this.hospitalName,
    this.metadata,
    this.isEncrypted = true,
  });

  EvidenceLog copyWith({
    String? id,
    String? userId,
    DateTime? incidentDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? title,
    String? description,
    Severity? severity,
    String? location,
    List<String>? photoUrls,
    List<String>? audioUrls,
    List<String>? documentUrls,
    List<String>? witnesses,
    bool? policeInvolved,
    String? policeReportNumber,
    bool? medicalAttention,
    String? hospitalName,
    Map<String, dynamic>? metadata,
    bool? isEncrypted,
  }) {
    return EvidenceLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      incidentDate: incidentDate ?? this.incidentDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      title: title ?? this.title,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      location: location ?? this.location,
      photoUrls: photoUrls ?? this.photoUrls,
      audioUrls: audioUrls ?? this.audioUrls,
      documentUrls: documentUrls ?? this.documentUrls,
      witnesses: witnesses ?? this.witnesses,
      policeInvolved: policeInvolved ?? this.policeInvolved,
      policeReportNumber: policeReportNumber ?? this.policeReportNumber,
      medicalAttention: medicalAttention ?? this.medicalAttention,
      hospitalName: hospitalName ?? this.hospitalName,
      metadata: metadata ?? this.metadata,
      isEncrypted: isEncrypted ?? this.isEncrypted,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'incidentDate': incidentDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'title': title,
    'description': description,
    'severity': severity.name,
    'location': location,
    'photoUrls': photoUrls,
    'audioUrls': audioUrls,
    'documentUrls': documentUrls,
    'witnesses': witnesses,
    'policeInvolved': policeInvolved,
    'policeReportNumber': policeReportNumber,
    'medicalAttention': medicalAttention,
    'hospitalName': hospitalName,
    'metadata': metadata,
    'isEncrypted': isEncrypted,
  };

  factory EvidenceLog.fromJson(Map<String, dynamic> json) {
    return EvidenceLog(
      id: json['id'] as String,
      userId: json['userId'] as String,
      incidentDate: DateTime.parse(json['incidentDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      title: json['title'] as String,
      description: json['description'] as String,
      severity: Severity.values.firstWhere((e) => e.name == json['severity']),
      location: json['location'] as String,
      photoUrls: (json['photoUrls'] as List?)?.cast<String>() ?? [],
      audioUrls: (json['audioUrls'] as List?)?.cast<String>() ?? [],
      documentUrls: (json['documentUrls'] as List?)?.cast<String>() ?? [],
      witnesses: (json['witnesses'] as List?)?.cast<String>() ?? [],
      policeInvolved: json['policeInvolved'] as bool? ?? false,
      policeReportNumber: json['policeReportNumber'] as String?,
      medicalAttention: json['medicalAttention'] as bool? ?? false,
      hospitalName: json['hospitalName'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isEncrypted: json['isEncrypted'] as bool? ?? true,
    );
  }
}

class MoodEntry {
  final String id;
  final String userId;
  final DateTime date;
  final int moodScore; // 1-10
  final List<String> triggers;
  final String? notes;

  MoodEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.moodScore,
    this.triggers = const [],
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'date': date.toIso8601String(),
    'moodScore': moodScore,
    'triggers': triggers,
    'notes': notes,
  };

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'] as String,
      userId: json['userId'] as String,
      date: DateTime.parse(json['date'] as String),
      moodScore: json['moodScore'] as int,
      triggers: (json['triggers'] as List?)?.cast<String>() ?? [],
      notes: json['notes'] as String?,
    );
  }
}

class BudgetTransaction {
  final String id;
  final String userId;
  final DateTime date;
  final double amount;
  final String category;
  final String description;
  final bool isIncome;
  final bool isHidden;

  BudgetTransaction({
    required this.id,
    required this.userId,
    required this.date,
    required this.amount,
    required this.category,
    required this.description,
    this.isIncome = false,
    this.isHidden = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'date': date.toIso8601String(),
    'amount': amount,
    'category': category,
    'description': description,
    'isIncome': isIncome,
    'isHidden': isHidden,
  };

  factory BudgetTransaction.fromJson(Map<String, dynamic> json) {
    return BudgetTransaction(
      id: json['id'] as String,
      userId: json['userId'] as String,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      description: json['description'] as String,
      isIncome: json['isIncome'] as bool? ?? false,
      isHidden: json['isHidden'] as bool? ?? false,
    );
  }
}

class SecureDocument {
  final String id;
  final String userId;
  final String title;
  final String category;
  final String filePath;
  final DateTime uploadedAt;
  final bool isEncrypted;

  SecureDocument({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.filePath,
    required this.uploadedAt,
    this.isEncrypted = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'category': category,
    'filePath': filePath,
    'uploadedAt': uploadedAt.toIso8601String(),
    'isEncrypted': isEncrypted,
  };

  factory SecureDocument.fromJson(Map<String, dynamic> json) {
    return SecureDocument(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      filePath: json['filePath'] as String,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      isEncrypted: json['isEncrypted'] as bool? ?? true,
    );
  }
}
