import 'dart:convert';

class ClientIntake {
  final String id;
  final String clientName;
  final String? clientPhone;
  final String? clientId; // linked app user id (nullable)
  final String caseManagerId;
  final String caseManagerName;
  final DateTime intakeDate;
  final String presentingSituation;
  final List<String> needsIdentified;
  final String? emergencySupportDesc;
  final double? emergencySupportAmount;
  final String currency;
  final String status; // active | closed
  final DateTime createdAt;
  final DateTime updatedAt;

  const ClientIntake({
    required this.id,
    required this.clientName,
    this.clientPhone,
    this.clientId,
    required this.caseManagerId,
    required this.caseManagerName,
    required this.intakeDate,
    required this.presentingSituation,
    required this.needsIdentified,
    this.emergencySupportDesc,
    this.emergencySupportAmount,
    this.currency = 'GHC',
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClientIntake.fromMap(Map<String, dynamic> map) {
    List<String> needs = [];
    if (map['needs_identified'] != null) {
      try {
        needs = List<String>.from(jsonDecode(map['needs_identified'] as String));
      } catch (_) {
        needs = [];
      }
    }
    return ClientIntake(
      id: map['id'] as String,
      clientName: map['client_name'] as String,
      clientPhone: map['client_phone'] as String?,
      clientId: map['client_id'] as String?,
      caseManagerId: map['case_manager_id'] as String,
      caseManagerName: map['case_manager_name'] as String,
      intakeDate: DateTime.parse(map['intake_date'] as String),
      presentingSituation: map['presenting_situation'] as String? ?? '',
      needsIdentified: needs,
      emergencySupportDesc: map['emergency_support_desc'] as String?,
      emergencySupportAmount: (map['emergency_support_amount'] as num?)?.toDouble(),
      currency: map['currency'] as String? ?? 'GHC',
      status: map['status'] as String? ?? 'active',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_name': clientName,
      'client_phone': clientPhone,
      'client_id': clientId,
      'case_manager_id': caseManagerId,
      'case_manager_name': caseManagerName,
      'intake_date': intakeDate.toIso8601String(),
      'presenting_situation': presentingSituation,
      'needs_identified': jsonEncode(needsIdentified),
      'emergency_support_desc': emergencySupportDesc,
      'emergency_support_amount': emergencySupportAmount,
      'currency': currency,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ClientIntake copyWith({
    String? clientName,
    String? clientPhone,
    String? clientId,
    String? caseManagerId,
    String? caseManagerName,
    DateTime? intakeDate,
    String? presentingSituation,
    List<String>? needsIdentified,
    String? emergencySupportDesc,
    double? emergencySupportAmount,
    String? currency,
    String? status,
    DateTime? updatedAt,
  }) {
    return ClientIntake(
      id: id,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientId: clientId ?? this.clientId,
      caseManagerId: caseManagerId ?? this.caseManagerId,
      caseManagerName: caseManagerName ?? this.caseManagerName,
      intakeDate: intakeDate ?? this.intakeDate,
      presentingSituation: presentingSituation ?? this.presentingSituation,
      needsIdentified: needsIdentified ?? this.needsIdentified,
      emergencySupportDesc: emergencySupportDesc ?? this.emergencySupportDesc,
      emergencySupportAmount: emergencySupportAmount ?? this.emergencySupportAmount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
