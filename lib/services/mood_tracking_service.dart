import '../models/evidence_log.dart';
import '../services/local_database_service.dart';

class MoodTrackingService {
  Future<MoodEntry> createEntry({
    required String userId,
    required int moodScore,
    List<String> triggers = const [],
    String? notes,
  }) async {
    await LocalDatabaseService.saveMoodEntry(userId, moodScore, triggers, notes ?? '');

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
    final entries = await LocalDatabaseService.getMoodEntries(userId, days: days);
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

    final sum = entries.fold<int>(0, (sum, entry) => sum + entry.moodScore);
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
}
