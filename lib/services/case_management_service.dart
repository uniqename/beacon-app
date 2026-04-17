import 'dart:developer' as developer;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/client_intake.dart';
import '../models/case_plan.dart';
import 'app_config_service.dart';
import 'local_database_service.dart';
import 'supabase_sync_service.dart';

class CaseManagementService {
  static const _uuid = Uuid();
  static final _sync = SupabaseSyncService();

  // ─── Client Intake ─────────────────────────────────────────────────────────

  static Future<String> createIntake(ClientIntake intake) async {
    try {
      final data = intake.toMap()
        ..['country_code'] = AppConfigService.instance.config.countryCode;
      await _sync.upsert(
        table: 'client_intakes',
        data: data,
        localWrite: (data) async {
          final db = await LocalDatabaseService.database;
          await db.insert('client_intakes', data,
              conflictAlgorithm: ConflictAlgorithm.replace);
        },
      );
      developer.log('✅ [CaseManagement] Intake created: ${intake.id}');
      return intake.id;
    } catch (e) {
      developer.log('❌ [CaseManagement] Error creating intake: $e');
      rethrow;
    }
  }

  static Future<ClientIntake?> getIntake(String id) async {
    try {
      final row = await _sync.fetchOne(
        table: 'client_intakes',
        id: id,
        localRead: (id) async {
          final db = await LocalDatabaseService.database;
          final r = await db.query('client_intakes',
              where: 'id = ?', whereArgs: [id], limit: 1);
          return r.isEmpty ? null : r.first;
        },
      );
      return row == null ? null : ClientIntake.fromMap(row);
    } catch (e) {
      developer.log('❌ [CaseManagement] Error getting intake: $e');
      return null;
    }
  }

  static Future<void> updateIntake(ClientIntake intake) async {
    try {
      final updated = intake.copyWith(updatedAt: DateTime.now());
      await _sync.upsert(
        table: 'client_intakes',
        data: updated.toMap(),
        localWrite: (data) async {
          final db = await LocalDatabaseService.database;
          await db.update('client_intakes', data,
              where: 'id = ?', whereArgs: [intake.id]);
        },
      );
    } catch (e) {
      developer.log('❌ [CaseManagement] Error updating intake: $e');
      rethrow;
    }
  }

  // ─── Case Plans ────────────────────────────────────────────────────────────

  static Future<String> createCasePlan(CasePlan plan) async {
    try {
      final data = plan.toMap()
        ..['country_code'] = AppConfigService.instance.config.countryCode;
      await _sync.upsert(
        table: 'case_plans',
        data: data,
        localWrite: (data) async {
          final db = await LocalDatabaseService.database;
          await db.insert('case_plans', data,
              conflictAlgorithm: ConflictAlgorithm.replace);
        },
      );
      developer.log('✅ [CaseManagement] Case plan created: ${plan.id}');
      return plan.id;
    } catch (e) {
      developer.log('❌ [CaseManagement] Error creating case plan: $e');
      rethrow;
    }
  }

  static Future<List<CasePlan>> getAllCasePlans() async {
    try {
      final countryCode = AppConfigService.instance.config.countryCode;
      final rows = await _sync.fetchAll(
        table: 'case_plans',
        filters: {'country_code': countryCode},
        orderBy: 'created_at',
        ascending: false,
        localRead: () async {
          final db = await LocalDatabaseService.database;
          // Include plans with no country_code (legacy/seeded data) or matching
          return db.query('case_plans',
              where: 'country_code = ? OR country_code IS NULL',
              whereArgs: [countryCode],
              orderBy: 'created_at DESC');
        },
      );
      return rows.map((r) => CasePlan.fromMap(r)).toList();
    } catch (e) {
      developer.log('❌ [CaseManagement] Error getting case plans: $e');
      return [];
    }
  }

  static Future<CasePlan?> getCasePlan(String id) async {
    try {
      final row = await _sync.fetchOne(
        table: 'case_plans',
        id: id,
        localRead: (id) async {
          final db = await LocalDatabaseService.database;
          final r = await db.query('case_plans',
              where: 'id = ?', whereArgs: [id], limit: 1);
          return r.isEmpty ? null : r.first;
        },
      );
      return row == null ? null : CasePlan.fromMap(row);
    } catch (e) {
      developer.log('❌ [CaseManagement] Error getting case plan: $e');
      return null;
    }
  }

  /// Returns the active case plan for a registered app user (client-facing view).
  static Future<CasePlan?> getCasePlanForUser(String userId) async {
    try {
      // Complex WHERE (client_id + status != closed) — SQLite only
      final db = await LocalDatabaseService.database;
      final results = await db.query(
        'case_plans',
        where: 'client_id = ? AND plan_status != ?',
        whereArgs: [userId, 'closed'],
        orderBy: 'created_at DESC',
        limit: 1,
      );
      return results.isEmpty ? null : CasePlan.fromMap(results.first);
    } catch (e) {
      developer.log('❌ [CaseManagement] Error getting plan for user: $e');
      return null;
    }
  }

  /// Like [getCasePlanForUser] but also attempts auto-linking before returning
  /// null. Use this on the home screen so a plan created by the admin after
  /// the user registered is surfaced automatically without requiring re-login.
  static Future<CasePlan?> getCasePlanOrAutoLink(
    String userId, {
    String? phone,
    String? email,
  }) async {
    // First try — plan may already be linked
    final existing = await getCasePlanForUser(userId);
    if (existing != null) return existing;

    // Try to link by phone then by name
    bool linked = false;
    if (phone != null && phone.isNotEmpty) {
      linked = await tryAutoLinkByPhone(userId, phone);
    }
    if (!linked && email != null && email.isNotEmpty) {
      linked = await tryAutoLinkByEmail(userId, email);
    }

    if (!linked) return null;

    // Second try — link just succeeded
    return getCasePlanForUser(userId);
  }

  static Future<List<CasePlan>> getCasePlansForManager(
      String caseManagerId) async {
    try {
      final rows = await _sync.fetchAll(
        table: 'case_plans',
        filters: {'case_manager_id': caseManagerId},
        orderBy: 'created_at',
        ascending: false,
        localRead: () async {
          final db = await LocalDatabaseService.database;
          return db.query('case_plans',
              where: 'case_manager_id = ?',
              whereArgs: [caseManagerId],
              orderBy: 'created_at DESC');
        },
      );
      return rows.map((r) => CasePlan.fromMap(r)).toList();
    } catch (e) {
      developer.log('❌ [CaseManagement] Error getting plans for manager: $e');
      return [];
    }
  }

  static Future<void> updateCasePlan(CasePlan plan) async {
    try {
      final updated = plan.copyWith(updatedAt: DateTime.now());
      await _sync.upsert(
        table: 'case_plans',
        data: updated.toMap(),
        localWrite: (data) async {
          final db = await LocalDatabaseService.database;
          await db.update('case_plans', data,
              where: 'id = ?', whereArgs: [plan.id]);
        },
      );
    } catch (e) {
      developer.log('❌ [CaseManagement] Error updating case plan: $e');
      rethrow;
    }
  }

  /// Links an existing intake + case plan to a registered app user.
  /// Called either on registration (auto-match by phone) or manually by admin.
  static Future<void> linkClientToUser({
    required String intakeId,
    required String planId,
    required String userId,
  }) async {
    final now = DateTime.now().toIso8601String();
    final db = await LocalDatabaseService.database;

    // Update intake
    await db.update('client_intakes', {'client_id': userId, 'updated_at': now},
        where: 'id = ?', whereArgs: [intakeId]);
    final intakeRows = await db.query('client_intakes',
        where: 'id = ?', whereArgs: [intakeId], limit: 1);
    if (intakeRows.isNotEmpty) {
      await _sync.upsert(
        table: 'client_intakes',
        data: Map<String, dynamic>.from(intakeRows.first),
        localWrite: (_) async {},
      );
    }

    // Update case plan
    await db.update('case_plans', {'client_id': userId, 'updated_at': now},
        where: 'id = ?', whereArgs: [planId]);
    final planRows = await db.query('case_plans',
        where: 'id = ?', whereArgs: [planId], limit: 1);
    if (planRows.isNotEmpty) {
      await _sync.upsert(
        table: 'case_plans',
        data: Map<String, dynamic>.from(planRows.first),
        localWrite: (_) async {},
      );
    }

    developer.log('✅ [CaseManagement] Linked intake $intakeId + plan $planId → user $userId');
  }

  /// Tries to auto-link any unlinked intake whose phone matches [phone].
  /// Returns true if a link was made.
  static Future<bool> tryAutoLinkByPhone(String userId, String phone) async {
    if (phone.isEmpty) return false;
    try {
      final db = await LocalDatabaseService.database;
      // Find unlinked intake with matching phone
      final intakes = await db.query(
        'client_intakes',
        where: 'client_phone = ? AND (client_id IS NULL OR client_id = "")',
        whereArgs: [phone],
        limit: 1,
      );
      if (intakes.isEmpty) return false;

      final intakeId = intakes.first['id'] as String;
      // Find corresponding plan
      final plans = await db.query(
        'case_plans',
        where: 'intake_id = ?',
        whereArgs: [intakeId],
        limit: 1,
      );
      if (plans.isEmpty) return false;

      final planId = plans.first['id'] as String;
      await linkClientToUser(
          intakeId: intakeId, planId: planId, userId: userId);
      return true;
    } catch (e) {
      developer.log('⚠️ [CaseManagement] Auto-link by phone failed: $e');
      return false;
    }
  }

  /// Tries to auto-link any unlinked intake whose client name roughly matches
  /// [email] (exact email match on the intake is not stored, but we can
  /// match by email on the users table — used as a fallback).
  static Future<bool> tryAutoLinkByEmail(String userId, String email) async {
    if (email.isEmpty) return false;
    try {
      final db = await LocalDatabaseService.database;
      // Check if user already has a linked plan
      final existing = await db.query(
        'case_plans',
        where: 'client_id = ? AND plan_status != ?',
        whereArgs: [userId, 'closed'],
        limit: 1,
      );
      if (existing.isNotEmpty) return false; // already linked

      // Look for an intake where client_phone is not set but client_name
      // matches the display_name from the users table for this userId
      final userRows = await db.query('users',
          where: 'id = ?', whereArgs: [userId], limit: 1);
      if (userRows.isEmpty) return false;
      final displayName =
          (userRows.first['display_name'] as String? ?? '').trim().toLowerCase();
      if (displayName.isEmpty) return false;

      final intakes = await db.query(
        'client_intakes',
        where: 'client_id IS NULL OR client_id = ""',
      );
      for (final intake in intakes) {
        final clientName =
            (intake['client_name'] as String? ?? '').trim().toLowerCase();
        if (clientName == displayName) {
          final intakeId = intake['id'] as String;
          final plans = await db.query('case_plans',
              where: 'intake_id = ?', whereArgs: [intakeId], limit: 1);
          if (plans.isNotEmpty) {
            await linkClientToUser(
                intakeId: intakeId,
                planId: plans.first['id'] as String,
                userId: userId);
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      developer.log('⚠️ [CaseManagement] Auto-link by name failed: $e');
      return false;
    }
  }

  // ─── Case Programs ─────────────────────────────────────────────────────────

  static Future<String> createProgram(CaseProgram program) async {
    try {
      await _sync.upsert(
        table: 'case_programs',
        data: program.toMap(),
        localWrite: (data) async {
          final db = await LocalDatabaseService.database;
          await db.insert('case_programs', data,
              conflictAlgorithm: ConflictAlgorithm.replace);
        },
      );
      developer.log('✅ [CaseManagement] Program created: ${program.id}');
      return program.id;
    } catch (e) {
      developer.log('❌ [CaseManagement] Error creating program: $e');
      rethrow;
    }
  }

  static Future<List<CaseProgram>> getProgramsForPlan(
      String casePlanId) async {
    try {
      final rows = await _sync.fetchAll(
        table: 'case_programs',
        filters: {'case_plan_id': casePlanId},
        orderBy: 'program_number',
        ascending: true,
        localRead: () async {
          final db = await LocalDatabaseService.database;
          return db.query('case_programs',
              where: 'case_plan_id = ?',
              whereArgs: [casePlanId],
              orderBy: 'program_number ASC, created_at ASC');
        },
      );
      return rows.map((r) => CaseProgram.fromMap(r)).toList();
    } catch (e) {
      developer.log('❌ [CaseManagement] Error getting programs: $e');
      return [];
    }
  }

  static Future<CaseProgram?> getProgram(String id) async {
    try {
      final row = await _sync.fetchOne(
        table: 'case_programs',
        id: id,
        localRead: (id) async {
          final db = await LocalDatabaseService.database;
          final r = await db.query('case_programs',
              where: 'id = ?', whereArgs: [id], limit: 1);
          return r.isEmpty ? null : r.first;
        },
      );
      return row == null ? null : CaseProgram.fromMap(row);
    } catch (e) {
      developer.log('❌ [CaseManagement] Error getting program: $e');
      return null;
    }
  }

  static Future<void> updateProgram(CaseProgram program) async {
    try {
      final updated = program.copyWith(updatedAt: DateTime.now());
      await _sync.upsert(
        table: 'case_programs',
        data: updated.toMap(),
        localWrite: (data) async {
          final db = await LocalDatabaseService.database;
          await db.update('case_programs', data,
              where: 'id = ?', whereArgs: [program.id]);
        },
      );
    } catch (e) {
      developer.log('❌ [CaseManagement] Error updating program: $e');
      rethrow;
    }
  }

  static Future<void> toggleAction(
    String programId,
    int actionIndex,
    bool completed,
  ) async {
    final program = await getProgram(programId);
    if (program == null) return;
    final updatedActions = List<ProgramAction>.from(program.actions);
    if (actionIndex >= 0 && actionIndex < updatedActions.length) {
      updatedActions[actionIndex] = updatedActions[actionIndex].copyWith(
        completed: completed,
        completedAt: completed ? DateTime.now() : null,
      );
      await updateProgram(program.copyWith(actions: updatedActions));
    }
  }

  static Future<void> addActionToProgram(
      String programId, String actionText) async {
    final program = await getProgram(programId);
    if (program == null) return;
    final updatedActions = List<ProgramAction>.from(program.actions)
      ..add(ProgramAction(text: actionText));
    await updateProgram(program.copyWith(actions: updatedActions));
  }

  static Future<void> deleteActionFromProgram(
      String programId, int actionIndex) async {
    final program = await getProgram(programId);
    if (program == null) return;
    final updatedActions = List<ProgramAction>.from(program.actions);
    if (actionIndex >= 0 && actionIndex < updatedActions.length) {
      updatedActions.removeAt(actionIndex);
      await updateProgram(program.copyWith(actions: updatedActions));
    }
  }

  // ─── Case Notes ────────────────────────────────────────────────────────────

  static Future<void> addNote(CaseNote note) async {
    try {
      await _sync.upsert(
        table: 'case_notes',
        data: note.toMap(),
        localWrite: (data) async {
          final db = await LocalDatabaseService.database;
          await db.insert('case_notes', data,
              conflictAlgorithm: ConflictAlgorithm.replace);
        },
      );
    } catch (e) {
      developer.log('❌ [CaseManagement] Error adding note: $e');
      rethrow;
    }
  }

  static Future<List<CaseNote>> getNotesForPlan(
    String casePlanId, {
    String? programId,
  }) async {
    try {
      // IS NULL check requires raw SQL — read locally (cache is up to date)
      final db = await LocalDatabaseService.database;
      if (programId != null) {
        final r = await db.query(
          'case_notes',
          where: 'case_plan_id = ? AND case_program_id = ?',
          whereArgs: [casePlanId, programId],
          orderBy: 'created_at DESC',
        );
        return r.map((row) => CaseNote.fromMap(row)).toList();
      } else {
        final r = await db.query(
          'case_notes',
          where: 'case_plan_id = ? AND case_program_id IS NULL',
          whereArgs: [casePlanId],
          orderBy: 'created_at DESC',
        );
        return r.map((row) => CaseNote.fromMap(row)).toList();
      }
    } catch (e) {
      developer.log('❌ [CaseManagement] Error getting notes: $e');
      return [];
    }
  }

  // ─── Stats ─────────────────────────────────────────────────────────────────

  static Future<Map<String, int>> getCaseManagementStats() async {
    try {
      final db = await LocalDatabaseService.database;
      final totalResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM case_plans',
      );
      final activeResult = await db.rawQuery(
        "SELECT COUNT(*) as count FROM case_plans WHERE plan_status = 'active'",
      );
      final urgentResult = await db.rawQuery(
        "SELECT COUNT(*) as count FROM case_programs WHERE priority = 'urgent' AND is_completed = 0",
      );
      return {
        'totalCasePlans': totalResult.first['count'] as int? ?? 0,
        'activeCasePlans': activeResult.first['count'] as int? ?? 0,
        'urgentPrograms': urgentResult.first['count'] as int? ?? 0,
      };
    } catch (e) {
      developer.log('❌ [CaseManagement] Error getting stats: $e');
      return {'totalCasePlans': 0, 'activeCasePlans': 0, 'urgentPrograms': 0};
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  static String generateId() => _uuid.v4();

  static CaseProgram programFromTemplate(
    ProgramTemplate template,
    String casePlanId,
    int nextNumber,
  ) {
    final now = DateTime.now();
    return CaseProgram(
      id: generateId(),
      casePlanId: casePlanId,
      programNumber: nextNumber,
      programName: template.name,
      goal: template.goal,
      currentStatusNotes: '',
      priority: template.priority,
      actions: const [],
      createdAt: now,
      updatedAt: now,
    );
  }
}

