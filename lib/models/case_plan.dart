import 'dart:convert';

// ─── CasePlan ───────────────────────────────────────────────────────────────

class CasePlan {
  final String id;
  final String intakeId;
  final String clientName;
  final String? clientId; // linked app user id (nullable)
  final String caseManagerId;
  final String caseManagerName;
  final String planStatus; // active | under_review | closed
  final DateTime? nextReviewDate;
  final String reviewFrequency; // monthly | quarterly
  final DateTime createdAt;
  final DateTime updatedAt;

  const CasePlan({
    required this.id,
    required this.intakeId,
    required this.clientName,
    this.clientId,
    required this.caseManagerId,
    required this.caseManagerName,
    this.planStatus = 'active',
    this.nextReviewDate,
    this.reviewFrequency = 'quarterly',
    required this.createdAt,
    required this.updatedAt,
  });

  factory CasePlan.fromMap(Map<String, dynamic> map) {
    return CasePlan(
      id: map['id'] as String,
      intakeId: map['intake_id'] as String,
      clientName: map['client_name'] as String,
      clientId: map['client_id'] as String?,
      caseManagerId: map['case_manager_id'] as String,
      caseManagerName: map['case_manager_name'] as String,
      planStatus: map['plan_status'] as String? ?? 'active',
      nextReviewDate: map['next_review_date'] != null
          ? DateTime.tryParse(map['next_review_date'] as String)
          : null,
      reviewFrequency: map['review_frequency'] as String? ?? 'quarterly',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'intake_id': intakeId,
      'client_name': clientName,
      'client_id': clientId,
      'case_manager_id': caseManagerId,
      'case_manager_name': caseManagerName,
      'plan_status': planStatus,
      'next_review_date': nextReviewDate?.toIso8601String(),
      'review_frequency': reviewFrequency,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CasePlan copyWith({
    String? planStatus,
    DateTime? nextReviewDate,
    String? reviewFrequency,
    String? caseManagerId,
    String? caseManagerName,
    DateTime? updatedAt,
  }) {
    return CasePlan(
      id: id,
      intakeId: intakeId,
      clientName: clientName,
      clientId: clientId,
      caseManagerId: caseManagerId ?? this.caseManagerId,
      caseManagerName: caseManagerName ?? this.caseManagerName,
      planStatus: planStatus ?? this.planStatus,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      reviewFrequency: reviewFrequency ?? this.reviewFrequency,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isReviewDueSoon {
    if (nextReviewDate == null) return false;
    final daysUntil = nextReviewDate!.difference(DateTime.now()).inDays;
    return daysUntil >= 0 && daysUntil <= 14;
  }

  bool get isReviewOverdue {
    if (nextReviewDate == null) return false;
    return nextReviewDate!.isBefore(DateTime.now());
  }
}

// ─── ProgramAction ───────────────────────────────────────────────────────────

class ProgramAction {
  final String text;
  final bool completed;
  final DateTime? completedAt;

  const ProgramAction({
    required this.text,
    this.completed = false,
    this.completedAt,
  });

  factory ProgramAction.fromMap(Map<String, dynamic> map) {
    return ProgramAction(
      text: map['text'] as String,
      completed: map['completed'] == true || map['completed'] == 1,
      completedAt: map['completedAt'] != null
          ? DateTime.tryParse(map['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'completed': completed,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  ProgramAction copyWith({bool? completed, DateTime? completedAt}) {
    return ProgramAction(
      text: text,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

// ─── CaseProgram ─────────────────────────────────────────────────────────────

class CaseProgram {
  final String id;
  final String casePlanId;
  final int programNumber;
  final String programName;
  final String goal;
  final String currentStatusNotes;
  final String priority; // urgent | high | medium | monitor | ongoing
  final String? deadlineLabel; // e.g. "Within 30 days"
  final DateTime? deadlineDate;
  final List<ProgramAction> actions;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CaseProgram({
    required this.id,
    required this.casePlanId,
    required this.programNumber,
    required this.programName,
    required this.goal,
    this.currentStatusNotes = '',
    this.priority = 'medium',
    this.deadlineLabel,
    this.deadlineDate,
    this.actions = const [],
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CaseProgram.fromMap(Map<String, dynamic> map) {
    List<ProgramAction> actions = [];
    if (map['actions'] != null) {
      try {
        final decoded = jsonDecode(map['actions'] as String) as List;
        actions = decoded
            .map((a) => ProgramAction.fromMap(a as Map<String, dynamic>))
            .toList();
      } catch (_) {
        actions = [];
      }
    }
    return CaseProgram(
      id: map['id'] as String,
      casePlanId: map['case_plan_id'] as String,
      programNumber: (map['program_number'] as int?) ?? 0,
      programName: map['program_name'] as String,
      goal: map['goal'] as String? ?? '',
      currentStatusNotes: map['current_status_notes'] as String? ?? '',
      priority: map['priority'] as String? ?? 'medium',
      deadlineLabel: map['deadline_label'] as String?,
      deadlineDate: map['deadline_date'] != null
          ? DateTime.tryParse(map['deadline_date'] as String)
          : null,
      actions: actions,
      isCompleted: (map['is_completed'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'case_plan_id': casePlanId,
      'program_number': programNumber,
      'program_name': programName,
      'goal': goal,
      'current_status_notes': currentStatusNotes,
      'priority': priority,
      'deadline_label': deadlineLabel,
      'deadline_date': deadlineDate?.toIso8601String(),
      'actions': jsonEncode(actions.map((a) => a.toMap()).toList()),
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CaseProgram copyWith({
    String? programName,
    String? goal,
    String? currentStatusNotes,
    String? priority,
    String? deadlineLabel,
    DateTime? deadlineDate,
    List<ProgramAction>? actions,
    bool? isCompleted,
    DateTime? updatedAt,
  }) {
    return CaseProgram(
      id: id,
      casePlanId: casePlanId,
      programNumber: programNumber,
      programName: programName ?? this.programName,
      goal: goal ?? this.goal,
      currentStatusNotes: currentStatusNotes ?? this.currentStatusNotes,
      priority: priority ?? this.priority,
      deadlineLabel: deadlineLabel ?? this.deadlineLabel,
      deadlineDate: deadlineDate ?? this.deadlineDate,
      actions: actions ?? this.actions,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get completedActionCount => actions.where((a) => a.completed).length;
  int get totalActionCount => actions.length;
  double get completionPercent =>
      totalActionCount == 0 ? 0.0 : completedActionCount / totalActionCount;
}

// ─── CaseNote ────────────────────────────────────────────────────────────────

class CaseNote {
  final String id;
  final String casePlanId;
  final String? caseProgramId; // null = general case note
  final String noteText;
  final String createdBy;
  final DateTime createdAt;

  const CaseNote({
    required this.id,
    required this.casePlanId,
    this.caseProgramId,
    required this.noteText,
    required this.createdBy,
    required this.createdAt,
  });

  factory CaseNote.fromMap(Map<String, dynamic> map) {
    return CaseNote(
      id: map['id'] as String,
      casePlanId: map['case_plan_id'] as String,
      caseProgramId: map['case_program_id'] as String?,
      noteText: map['note_text'] as String,
      createdBy: map['created_by'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'case_plan_id': casePlanId,
      'case_program_id': caseProgramId,
      'note_text': noteText,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// ─── Program Templates ───────────────────────────────────────────────────────

class ProgramTemplate {
  final int number;
  final String name;
  final String goal;
  final String priority;

  const ProgramTemplate({
    required this.number,
    required this.name,
    required this.goal,
    required this.priority,
  });
}

const kProgramTemplates = [
  ProgramTemplate(
    number: 1,
    name: 'Case Management',
    goal: 'Maintain complete coordinated case file and serve as primary BNB contact',
    priority: 'ongoing',
  ),
  ProgramTemplate(
    number: 2,
    name: 'Education Support & Continuity',
    goal: 'Ensure client completes their academic programme without financial interruption',
    priority: 'high',
  ),
  ProgramTemplate(
    number: 3,
    name: 'Housing Stability & Safety Planning',
    goal: 'Ensure safe, stable housing during and after the support period',
    priority: 'high',
  ),
  ProgramTemplate(
    number: 4,
    name: 'Psychosocial Support & Counselling',
    goal: 'Support emotional wellbeing — grief, trauma, rejection, and counselling referral',
    priority: 'urgent',
  ),
  ProgramTemplate(
    number: 5,
    name: 'Community & Social Reintegration',
    goal: 'Rebuild sense of community and belonging; establish a new safe support network',
    priority: 'medium',
  ),
  ProgramTemplate(
    number: 6,
    name: 'Skills Training & Economic Empowerment',
    goal: 'Build practical skills and economic independence',
    priority: 'medium',
  ),
  ProgramTemplate(
    number: 7,
    name: 'Legal Resource Navigation',
    goal: 'Ensure client knows their rights; referral pathway ready if coercion escalates',
    priority: 'monitor',
  ),
];
