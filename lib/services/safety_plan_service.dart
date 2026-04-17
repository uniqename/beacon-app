import '../models/safety_plan.dart';
import '../services/local_database_service.dart';

class SafetyPlanService {
  Future<SafetyPlan> createSafetyPlan(String userId) async {
    final now = DateTime.now();
    final plan = SafetyPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      createdAt: now,
      updatedAt: now,
    );

    await LocalDatabaseService.saveSafetyPlan(userId, {
      'emergency_contacts': plan.emergencyContacts,
      'safe_places': plan.safePlaces,
      'escape_plan': plan.escapePlan != null ? plan.escapePlan!.toMap() : {},
      'essential_items': plan.essentialItems,
      'code_words': {
        'danger': plan.dangerCodeWord,
        'help': plan.helpCodeWord,
      },
      'children_safety': plan.children.map((c) => c.toMap()).toList(),
      'pet_safety': plan.pets.map((p) => p.toMap()).toList(),
      'financial_safety': plan.hiddenSavings.map((h) => h.toMap()).toList(),
      'digital_safety': plan.digitalSafety?.toMap() ?? {},
    });

    return plan;
  }

  Future<SafetyPlan?> getSafetyPlan(String userId) async {
    final data = await LocalDatabaseService.getSafetyPlan(userId);
    if (data == null) return null;

    return SafetyPlan(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
      emergencyContacts: ((data['emergency_contacts'] as List?) ?? [])
          .map((c) => EmergencyContact.fromMap(c as Map<String, dynamic>))
          .toList(),
      safePlaces: ((data['safe_places'] as List?) ?? [])
          .map((p) => SafePlace.fromMap(p as Map<String, dynamic>))
          .toList(),
      escapePlan: data['escape_plan'] != null && (data['escape_plan'] as Map).isNotEmpty
          ? EscapePlan.fromMap(data['escape_plan'] as Map<String, dynamic>)
          : null,
      essentialItems: ((data['essential_items'] as List?) ?? []).cast<String>(),
      dangerCodeWord: (data['code_words'] as Map?)?['danger'] as String?,
      helpCodeWord: (data['code_words'] as Map?)?['help'] as String?,
      children: ((data['children_safety'] as List?) ?? [])
          .map((c) => Child.fromMap(c as Map<String, dynamic>))
          .toList(),
      pets: ((data['pet_safety'] as List?) ?? [])
          .map((p) => Pet.fromMap(p as Map<String, dynamic>))
          .toList(),
      hiddenSavings: ((data['financial_safety'] as List?) ?? [])
          .map((h) => HiddenSaving.fromMap(h as Map<String, dynamic>))
          .toList(),
      digitalSafety: data['digital_safety'] != null && (data['digital_safety'] as Map).isNotEmpty
          ? DigitalSafetyPlan.fromMap(data['digital_safety'] as Map<String, dynamic>)
          : null,
    );
  }

  Future<void> updateSafetyPlan(SafetyPlan plan) async {
    await LocalDatabaseService.saveSafetyPlan(plan.userId, {
      'emergency_contacts': plan.emergencyContacts,
      'safe_places': plan.safePlaces,
      'escape_plan': plan.escapePlan != null ? plan.escapePlan!.toMap() : {},
      'essential_items': plan.essentialItems,
      'code_words': {
        'danger': plan.dangerCodeWord,
        'help': plan.helpCodeWord,
      },
      'children_safety': plan.children.map((c) => c.toMap()).toList(),
      'pet_safety': plan.pets.map((p) => p.toMap()).toList(),
      'financial_safety': plan.hiddenSavings.map((h) => h.toMap()).toList(),
      'digital_safety': plan.digitalSafety?.toMap() ?? {},
    });
  }

  Future<void> deleteSafetyPlan(String planId) async {
    // Safety plans are user-specific, so we'd need to delete by user_id
    // For now, this is a placeholder - you may want to add a delete method to LocalDatabaseService
  }

  Future<double> calculateCompletionPercentage(SafetyPlan plan) async {
    int completed = 0;
    int total = 10;

    if (plan.emergencyContacts.isNotEmpty) completed++;
    if (plan.safePlaces.isNotEmpty) completed++;
    if (plan.escapePlan != null) completed++;
    if (plan.essentialItems.isNotEmpty) completed++;
    if (plan.dangerCodeWord != null && plan.helpCodeWord != null) completed++;
    if (plan.children.isNotEmpty) completed++;
    if (plan.pets.isNotEmpty) completed++;
    if (plan.hiddenSavings.isNotEmpty) completed++;
    if (plan.digitalSafety != null) completed++;

    return (completed / total) * 100;
  }

  List<String> getDefaultEssentialItems() {
    return [
      'ID/Passport',
      'Birth certificates',
      'Social security cards',
      'Bank account information',
      'Credit cards',
      'Keys (house, car)',
      'Medications',
      'Important phone numbers',
      'Clothing',
      'Toiletries',
      'Children\'s items',
      'Pet supplies',
      'Cash',
      'Important documents',
    ];
  }
}
