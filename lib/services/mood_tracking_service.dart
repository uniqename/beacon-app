import 'dart:developer' as developer;
import '../models/evidence_log.dart';
import '../services/local_database_service.dart';
import '../services/supabase_sync_service.dart';

class MoodTrackingService {
  final _sync = SupabaseSyncService();

  Future<MoodEntry> createEntry({
    required String userId,
    required int moodScore,
    List<String> triggers = const [],
    String? notes,
  }) async {
    await LocalDatabaseService.saveMoodEntry(
        userId, moodScore, triggers, notes ?? '');

    // Push latest mood entry to Supabase
    await _pushLatestMoodToCloud(userId);

    return MoodEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      date: DateTime.now(),
      moodScore: moodScore,
      triggers: triggers,
      notes: notes,
    );
  }

  Future<List<MoodEntry>> getEntries(String userId, {int days = 14}) async {
    final entries =
        await LocalDatabaseService.getMoodEntries(userId, days: days);
    return entries.map((entry) {
      return MoodEntry(
        id: entry['id'] as String,
        userId: entry['user_id'] as String,
        date: DateTime.parse(entry['date'] as String),
        moodScore: entry['mood_rating'] as int,
        triggers: (entry['triggers'] as List?)?.cast<String>() ?? [],
        notes: entry['notes'] as String?,
      );
    }).toList();
  }

  Future<double> getAverageMood(String userId, {int days = 7}) async {
    final entries = await getEntries(userId, days: days);
    if (entries.isEmpty) return 0.0;
    final sum = entries.fold<int>(0, (s, e) => s + e.moodScore);
    return sum / entries.length;
  }

  List<String> getCommonTriggers() {
    return [
      'Financial stress',
      'Argument',
      'Loneliness',
      'Physical pain',
      'Lack of sleep',
      'Work stress',
      'Family issues',
      'Health concerns',
      'Other',
    ];
  }

  // ─── Private helpers ────────────────────────────────────────────────────────

  Future<void> _pushLatestMoodToCloud(String userId) async {
    try {
      final db = await LocalDatabaseService.database;
      final rows = await db.query(
        'mood_entries',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
        limit: 1,
      );
      if (rows.isEmpty) return;
      await _sync.upsert(
        table: 'mood_entries',
        data: Map<String, dynamic>.from(rows.first),
        localWrite: (_) async {},
      );
    } catch (e) {
      developer.log('⚠️ [Mood] Cloud push failed (non-fatal): $e');
    }
  }
}
