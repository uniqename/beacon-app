class CaseReferral {
  final String id;
  final String intakeId;
  final String? casePlanId;

  /// 'inbound'  — someone referred this client TO Beacon
  /// 'outbound' — Beacon referred this client TO another organisation
  final String direction;

  final DateTime referralDate;
  final String partnerOrganization;
  final String? partnerContactName;
  final String? partnerContactPhone;
  final String reason;

  /// e.g. Mental Health, Housing, Legal, Medical, Skills Training, etc.
  final String? serviceType;

  /// 'routine' | 'urgent' | 'emergency'
  final String urgency;

  /// 'cat1' | 'cat2' | 'cat3'  (only meaningful for outbound referrals)
  final String? paymentCategory;
  final double? paymentAmount;
  final String? paymentNotes;

  /// 'pending' | 'active' | 'completed' | 'declined'
  final String status;
  final String? outcomeNotes;
  final String recordedBy;
  final String? countryCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CaseReferral({
    required this.id,
    required this.intakeId,
    this.casePlanId,
    required this.direction,
    required this.referralDate,
    required this.partnerOrganization,
    this.partnerContactName,
    this.partnerContactPhone,
    required this.reason,
    this.serviceType,
    this.urgency = 'routine',
    this.paymentCategory,
    this.paymentAmount,
    this.paymentNotes,
    this.status = 'pending',
    this.outcomeNotes,
    required this.recordedBy,
    this.countryCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CaseReferral.fromMap(Map<String, dynamic> m) => CaseReferral(
        id: m['id'] as String,
        intakeId: m['intake_id'] as String,
        casePlanId: m['case_plan_id'] as String?,
        direction: m['direction'] as String? ?? 'outbound',
        referralDate: DateTime.parse(m['referral_date'] as String),
        partnerOrganization: m['partner_organization'] as String? ?? '',
        partnerContactName: m['partner_contact_name'] as String?,
        partnerContactPhone: m['partner_contact_phone'] as String?,
        reason: m['reason'] as String? ?? '',
        serviceType: m['service_type'] as String?,
        urgency: m['urgency'] as String? ?? 'routine',
        paymentCategory: m['payment_category'] as String?,
        paymentAmount: (m['payment_amount'] as num?)?.toDouble(),
        paymentNotes: m['payment_notes'] as String?,
        status: m['status'] as String? ?? 'pending',
        outcomeNotes: m['outcome_notes'] as String?,
        recordedBy: m['recorded_by'] as String? ?? '',
        countryCode: m['country_code'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'intake_id': intakeId,
        'case_plan_id': casePlanId,
        'direction': direction,
        'referral_date': referralDate.toIso8601String(),
        'partner_organization': partnerOrganization,
        'partner_contact_name': partnerContactName,
        'partner_contact_phone': partnerContactPhone,
        'reason': reason,
        'service_type': serviceType,
        'urgency': urgency,
        'payment_category': paymentCategory,
        'payment_amount': paymentAmount,
        'payment_notes': paymentNotes,
        'status': status,
        'outcome_notes': outcomeNotes,
        'recorded_by': recordedBy,
        'country_code': countryCode,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  CaseReferral copyWith({
    String? direction,
    DateTime? referralDate,
    String? partnerOrganization,
    String? partnerContactName,
    String? partnerContactPhone,
    String? reason,
    String? serviceType,
    String? urgency,
    String? paymentCategory,
    double? paymentAmount,
    String? paymentNotes,
    String? status,
    String? outcomeNotes,
    DateTime? updatedAt,
  }) =>
      CaseReferral(
        id: id,
        intakeId: intakeId,
        casePlanId: casePlanId,
        direction: direction ?? this.direction,
        referralDate: referralDate ?? this.referralDate,
        partnerOrganization: partnerOrganization ?? this.partnerOrganization,
        partnerContactName: partnerContactName ?? this.partnerContactName,
        partnerContactPhone: partnerContactPhone ?? this.partnerContactPhone,
        reason: reason ?? this.reason,
        serviceType: serviceType ?? this.serviceType,
        urgency: urgency ?? this.urgency,
        paymentCategory: paymentCategory ?? this.paymentCategory,
        paymentAmount: paymentAmount ?? this.paymentAmount,
        paymentNotes: paymentNotes ?? this.paymentNotes,
        status: status ?? this.status,
        outcomeNotes: outcomeNotes ?? this.outcomeNotes,
        recordedBy: recordedBy,
        countryCode: countryCode,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  bool get isInbound => direction == 'inbound';
  bool get isOutbound => direction == 'outbound';
}

/// Pre-defined partner organisations drawn from Beacon's existing MOUs
/// and referral pathway documents.
const kKnownPartners = [
  'Brain & Sleep Medical Centre',
  'LEKMA Polyclinic',
  'Tema General Hospital',
  'DOVVSU (Domestic Violence Unit)',
  'WILDAF Ghana',
  'Agape House Church',
  'Clubhouse Ghana',
  'PsyPro Ghana',
  'Psychomatters',
  'ICGC Shalom Temple',
  'Police – Victim Support Unit',
  'Legal Aid Commission',
  'Department of Social Welfare',
  'Other',
];

const kServiceTypes = [
  'Mental Health Assessment',
  'Sleep Medicine Evaluation',
  'Psychiatric Consultation',
  'Housing / Shelter',
  'Legal Aid',
  'Medical Care',
  'Skills Training',
  'Employment Support',
  'Child Protection',
  'Substance Use Support',
  'Spiritual / Pastoral Care',
  'Community Reintegration',
  'Other',
];
