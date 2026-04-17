import 'dart:developer' as developer;
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_database_service.dart';

/// Service for handling permanent account deletion per App Store guideline 5.1.1
/// Deletes all user data, files, and preferences
class AccountDeletionService {
  static final AccountDeletionService _instance = AccountDeletionService._internal();
  factory AccountDeletionService() => _instance;
  AccountDeletionService._internal();

  /// Permanently delete user account and all associated data
  /// Returns true if deletion successful, false otherwise
  Future<bool> deleteUserAccount(String userId, {bool isAnonymous = false}) async {
    try {
      developer.log('🗑️ Starting account deletion for user: $userId (anonymous: $isAnonymous)');

      final db = await LocalDatabaseService.database;

      // 1. Delete all user data from database
      await _deleteUserData(db, userId);

      // 2. Delete all evidence files (photos, audio)
      await _deleteEvidenceFiles(db, userId);

      // 3. Delete all document vault files
      await _deleteDocumentFiles(db, userId);

      // 4. Clear shared preferences
      await _clearSharedPreferences();

      // 5. Log deletion for compliance (GDPR/data protection)
      await _logDeletion(db, userId, isAnonymous);

      developer.log('✅ Account deletion completed successfully for user: $userId');
      return true;
    } catch (e) {
      developer.log('❌ Error deleting account: $e');
      return false;
    }
  }

  /// Delete all user data from database tables
  Future<void> _deleteUserData(Database db, String userId) async {
    developer.log('Deleting database records for user: $userId');

    final tables = [
      'evidence_logs',
      'secure_documents',
      'safety_plans',
      'mood_entries',
      'budget_transactions',
      'chat_messages',
      'conversations',
      'support_group_participants',
      'support_group_invitations',
      'disguise_settings',
      'feedback',
      'donations',
    ];

    for (final table in tables) {
      try {
        final count = await db.delete(
          table,
          where: 'user_id = ?',
          whereArgs: [userId],
        );
        developer.log('  Deleted $count rows from $table');
      } catch (e) {
        // Table might not exist or column name different, continue
        developer.log('  Warning: Could not delete from $table: $e');
      }
    }

    // Delete user record last
    try {
      final count = await db.delete(
        'users',
        where: 'uid = ?',
        whereArgs: [userId],
      );
      developer.log('  Deleted user record: $count rows from users table');
    } catch (e) {
      developer.log('  Warning: Could not delete user record: $e');
    }
  }

  /// Delete all evidence files (photos and audio recordings)
  Future<void> _deleteEvidenceFiles(Database db, String userId) async {
    developer.log('Deleting evidence files for user: $userId');

    try {
      final evidenceRecords = await db.query(
        'evidence_logs',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      int deletedFiles = 0;

      for (final record in evidenceRecords) {
        // Delete photo files
        final photos = record['photos'] as String?;
        if (photos != null && photos.isNotEmpty) {
          // Photos stored as JSON array of paths
          final photosPaths = photos.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').split(',');
          for (final photoPath in photosPaths) {
            if (photoPath.trim().isNotEmpty) {
              try {
                final file = File(photoPath.trim());
                if (await file.exists()) {
                  await file.delete();
                  deletedFiles++;
                }
              } catch (e) {
                developer.log('    Warning: Could not delete photo: $photoPath - $e');
              }
            }
          }
        }

        // Delete audio files
        final audio = record['audio'] as String?;
        if (audio != null && audio.isNotEmpty) {
          // Audio stored as JSON array of paths
          final audioPaths = audio.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').split(',');
          for (final audioPath in audioPaths) {
            if (audioPath.trim().isNotEmpty) {
              try {
                final file = File(audioPath.trim());
                if (await file.exists()) {
                  await file.delete();
                  deletedFiles++;
                }
              } catch (e) {
                developer.log('    Warning: Could not delete audio: $audioPath - $e');
              }
            }
          }
        }
      }

      developer.log('  Deleted $deletedFiles evidence files');
    } catch (e) {
      developer.log('  Warning: Error deleting evidence files: $e');
    }
  }

  /// Delete all document vault files
  Future<void> _deleteDocumentFiles(Database db, String userId) async {
    developer.log('Deleting document files for user: $userId');

    try {
      final documentRecords = await db.query(
        'secure_documents',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      int deletedFiles = 0;

      for (final record in documentRecords) {
        final filePath = record['file_path'] as String?;
        if (filePath != null && filePath.isNotEmpty) {
          try {
            final file = File(filePath);
            if (await file.exists()) {
              await file.delete();
              deletedFiles++;
            }
          } catch (e) {
            developer.log('    Warning: Could not delete document: $filePath - $e');
          }
        }
      }

      developer.log('  Deleted $deletedFiles document files');
    } catch (e) {
      developer.log('  Warning: Error deleting document files: $e');
    }
  }

  /// Clear all shared preferences
  Future<void> _clearSharedPreferences() async {
    developer.log('Clearing shared preferences');

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      developer.log('  Shared preferences cleared');
    } catch (e) {
      developer.log('  Warning: Error clearing shared preferences: $e');
    }
  }

  /// Log account deletion for compliance (GDPR, data protection laws)
  /// Does NOT store any personal data, only metadata for audit trail
  Future<void> _logDeletion(Database db, String userId, bool isAnonymous) async {
    developer.log('Logging account deletion');

    try {
      // Create deletion log table if it doesn't exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS account_deletions(
          id TEXT PRIMARY KEY,
          user_id_hash TEXT NOT NULL,
          deleted_at TEXT NOT NULL,
          deletion_type TEXT,
          user_type TEXT
        )
      ''');

      // Hash user ID for privacy (don't store actual user ID)
      final userIdHash = userId.hashCode.toString();

      await db.insert('account_deletions', {
        'id': 'del_${DateTime.now().millisecondsSinceEpoch}',
        'user_id_hash': userIdHash,
        'deleted_at': DateTime.now().toIso8601String(),
        'deletion_type': 'user_requested',
        'user_type': isAnonymous ? 'anonymous' : 'registered',
      });

      developer.log('  Deletion logged (user_id_hash: $userIdHash)');
    } catch (e) {
      developer.log('  Warning: Error logging deletion: $e');
    }
  }

  /// Get list of evidence file paths for a user (for confirmation dialog)
  Future<List<String>> getUserEvidenceFiles(String userId) async {
    final List<String> files = [];

    try {
      final db = await LocalDatabaseService.database;
      final evidenceRecords = await db.query(
        'evidence_logs',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      for (final record in evidenceRecords) {
        final photos = record['photos'] as String?;
        if (photos != null && photos.isNotEmpty) {
          files.add('Photos: ${photos.split(',').length} files');
        }

        final audio = record['audio'] as String?;
        if (audio != null && audio.isNotEmpty) {
          files.add('Audio: ${audio.split(',').length} files');
        }
      }
    } catch (e) {
      developer.log('Error getting evidence files: $e');
    }

    return files;
  }

  /// Get count of user data for confirmation dialog
  Future<Map<String, int>> getUserDataCounts(String userId) async {
    final Map<String, int> counts = {};

    try {
      final db = await LocalDatabaseService.database;

      final tables = {
        'evidence': 'evidence_logs',
        'documents': 'secure_documents',
        'safety_plans': 'safety_plans',
        'mood_entries': 'mood_entries',
        'budget_entries': 'budget_transactions',
      };

      for (final entry in tables.entries) {
        try {
          final result = await db.rawQuery(
            'SELECT COUNT(*) as count FROM ${entry.value} WHERE user_id = ?',
            [userId],
          );
          counts[entry.key] = result.first['count'] as int? ?? 0;
        } catch (e) {
          counts[entry.key] = 0;
        }
      }
    } catch (e) {
      developer.log('Error getting data counts: $e');
    }

    return counts;
  }
}
