import 'dart:async' show Future, Timer, unawaited;
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/admin_config.dart';
import 'local_database_service.dart';

/// Supabase-first sync service.
///
/// Write priority:
///   1. Write to local SQLite immediately (instant UI feedback, never blocks).
///   2. Attempt Supabase upsert in the background.
///   3. If Supabase fails, queue the record in `pending_syncs` for retry.
///
/// Read priority:
///   1. Attempt Supabase fetch (always fresh).
///   2. On network failure, return SQLite cached data.
///
/// Background retry:
///   Every 5 minutes (if pending records exist) the service flushes the queue.
class SupabaseSyncService {
  static final SupabaseSyncService _instance = SupabaseSyncService._internal();
  factory SupabaseSyncService() => _instance;
  SupabaseSyncService._internal();

  SupabaseClient? _client;
  Timer? _retryTimer;
  bool _isSyncing = false;

  // ─── Initialisation ─────────────────────────────────────────────────────────

  Future<void> initialize() async {
    try {
      _client = Supabase.instance.client;
      developer.log('✅ [Sync] Supabase client ready');
    } catch (_) {
      developer.log('⚠️ [Sync] Supabase not yet initialised — sync deferred');
    }

    // Retry pending syncs every 5 minutes
    _retryTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      final count = await getPendingSyncCount();
      if (count > 0) {
        developer.log('⏰ [Sync] Retry timer — $count pending sync(s)');
        await flushPendingSyncs();
      }
    });

    // Flush any leftovers from a previous session right away
    unawaited(flushPendingSyncs());
  }

  /// Call this after a successful Supabase sign-in so the client is ready.
  void setClient(SupabaseClient client) {
    _client = client;
  }

  void dispose() {
    _retryTimer?.cancel();
  }

  // ─── Core upsert ─────────────────────────────────────────────────────────────

  /// Upsert [data] into [table].
  ///
  /// Always writes locally first via [localWrite], then attempts Supabase.
  /// On Supabase failure the record is queued for later retry.
  Future<void> upsert({
    required String table,
    required Map<String, dynamic> data,
    required Future<void> Function(Map<String, dynamic> data) localWrite,
  }) async {
    // 1. Local write — never fails silently
    try {
      await localWrite(data);
    } catch (e) {
      developer.log('❌ [Sync] Local write to $table failed: $e');
    }

    // 2. Cloud write
    await _cloudUpsert(table: table, data: data);
  }

  /// Delete record [id] from [table].
  Future<void> delete({
    required String table,
    required String id,
    required Future<void> Function(String id) localDelete,
  }) async {
    try {
      await localDelete(id);
    } catch (e) {
      developer.log('❌ [Sync] Local delete on $table/$id failed: $e');
    }

    if (_client != null) {
      try {
        await _client!.from(table).delete().eq('id', id);
        developer.log('✅ [Sync] Supabase delete OK → $table/$id');
        await _clearPendingSync(table, id);
        return;
      } catch (e) {
        developer.log('⚠️ [Sync] Supabase delete failed for $table/$id — queuing: $e');
      }
    }

    await _queuePendingSync(
      table: table,
      recordId: id,
      operation: 'delete',
      data: {'id': id},
    );
  }

  // ─── Core fetch ──────────────────────────────────────────────────────────────

  /// Fetch rows from Supabase; fall back to SQLite on failure.
  Future<List<Map<String, dynamic>>> fetchAll({
    required String table,
    required Future<List<Map<String, dynamic>>> Function() localRead,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = false,
  }) async {
    if (_client != null) {
      try {
        final entries = filters?.entries.toList() ?? [];
        List<dynamic> rows;

        if (entries.isNotEmpty) {
          // Apply first filter to get a PostgrestFilterBuilder, then chain the rest
          var q = _client!
              .from(table)
              .select()
              .eq(entries.first.key, entries.first.value);
          for (final e in entries.skip(1)) {
            q = q.eq(e.key, e.value);
          }
          rows = orderBy != null
              ? await q.order(orderBy, ascending: ascending)
              : await q;
        } else {
          final q = _client!.from(table).select();
          rows = orderBy != null
              ? await q.order(orderBy, ascending: ascending)
              : await q;
        }

        developer.log(
            '✅ [Sync] Supabase fetch OK → $table (${rows.length} rows)');
        return List<Map<String, dynamic>>.from(rows);
      } catch (e) {
        developer.log(
            '⚠️ [Sync] Supabase fetch failed for $table — using local: $e');
      }
    }
    return localRead();
  }

  /// Fetch a single record from Supabase; fall back to SQLite on failure.
  Future<Map<String, dynamic>?> fetchOne({
    required String table,
    required String id,
    required Future<Map<String, dynamic>?> Function(String id) localRead,
  }) async {
    if (_client != null) {
      try {
        final rows =
            await _client!.from(table).select().eq('id', id).limit(1);
        if (rows.isNotEmpty) {
          developer.log('✅ [Sync] Supabase fetchOne OK → $table/$id');
          return Map<String, dynamic>.from(rows.first);
        }
      } catch (e) {
        developer.log(
            '⚠️ [Sync] Supabase fetchOne failed for $table/$id — using local: $e');
      }
    }
    return localRead(id);
  }

  // ─── Pending sync management ─────────────────────────────────────────────────

  Future<void> _cloudUpsert({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    if (_client != null) {
      try {
        await _client!.from(table).upsert(data);
        developer.log('✅ [Sync] Supabase upsert OK → $table');
        await _clearPendingSync(table, data['id'] as String?);
        return;
      } catch (e) {
        developer.log(
            '⚠️ [Sync] Supabase upsert failed for $table — queuing: $e');
      }
    }

    await _queuePendingSync(
      table: table,
      recordId: data['id'] as String?,
      operation: 'upsert',
      data: data,
    );
  }

  Future<void> _queuePendingSync({
    required String table,
    required String? recordId,
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    if (recordId == null) return;
    try {
      final db = await LocalDatabaseService.database;
      await db.insert(
        'pending_syncs',
        {
          'id': '${table}_${recordId}_$operation',
          'table_name': table,
          'record_id': recordId,
          'operation': operation,
          'data': jsonEncode(data),
          'created_at': DateTime.now().toIso8601String(),
          'retry_count': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      developer.log(
          '📦 [Sync] Queued pending sync: $operation on $table/$recordId');
    } catch (e) {
      developer.log('❌ [Sync] Failed to queue pending sync: $e');
    }
  }

  Future<void> _clearPendingSync(String table, String? recordId) async {
    if (recordId == null) return;
    try {
      final db = await LocalDatabaseService.database;
      await db.delete(
        'pending_syncs',
        where: 'table_name = ? AND record_id = ?',
        whereArgs: [table, recordId],
      );
    } catch (_) {}
  }

  /// Push all queued local changes to Supabase.
  /// Safe to call multiple times — protected by [_isSyncing] guard.
  Future<void> flushPendingSyncs() async {
    if (_client == null || _isSyncing) return;
    _isSyncing = true;

    try {
      final db = await LocalDatabaseService.database;
      final pending = await db.query(
        'pending_syncs',
        orderBy: 'created_at ASC',
        limit: 50,
      );

      if (pending.isEmpty) return;

      developer.log('🔄 [Sync] Flushing ${pending.length} pending sync(s)...');
      int successCount = 0;

      for (final row in pending) {
        final table = row['table_name'] as String;
        final recordId = row['record_id'] as String;
        final operation = row['operation'] as String;
        final data =
            jsonDecode(row['data'] as String) as Map<String, dynamic>;
        final retryCount = (row['retry_count'] as int?) ?? 0;

        try {
          if (operation == 'upsert') {
            await _client!.from(table).upsert(data);
          } else if (operation == 'delete') {
            await _client!.from(table).delete().eq('id', recordId);
          }

          await db.delete(
            'pending_syncs',
            where: 'id = ?',
            whereArgs: [row['id']],
          );
          successCount++;
          developer.log(
              '✅ [Sync] Flushed $operation on $table/$recordId');
        } catch (e) {
          await db.update(
            'pending_syncs',
            {
              'retry_count': retryCount + 1,
              'last_error': e.toString(),
            },
            where: 'id = ?',
            whereArgs: [row['id']],
          );
          if (retryCount >= 5) {
            developer.log(
                '⚠️ [Sync] Persistent failure ($retryCount retries) for $table/$recordId: $e');
          }
        }
      }

      developer.log(
          '✅ [Sync] Flush complete: $successCount/${pending.length} succeeded');
    } catch (e) {
      developer.log('❌ [Sync] flushPendingSyncs error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Returns the count of records waiting to be synced to Supabase.
  Future<int> getPendingSyncCount() async {
    try {
      final db = await LocalDatabaseService.database;
      final result =
          await db.rawQuery('SELECT COUNT(*) as c FROM pending_syncs');
      return (result.first['c'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  bool get isConnectedToSupabase => _client != null;

  Future<void> updateUserPasswordHash(String userId, String passwordHash) async {
    if (_client == null) return;
    try {
      await _client!.from('users').update({'password_hash': passwordHash}).eq('id', userId);
      developer.log('✅ [Sync] password_hash updated for $userId');
    } catch (e) {
      developer.log('⚠️ [Sync] updateUserPasswordHash failed: $e');
    }
  }

  /// Updates the user's actual Supabase Auth password via the admin API.
  /// This is the call that makes the new password work at login.
  Future<void> adminResetUserPassword(String userId, String newPassword) async {
    try {
      final response = await http.patch(
        Uri.parse('${AdminConfig.supabaseUrl}/auth/v1/admin/users/$userId'),
        headers: {
          'Authorization': 'Bearer ${AdminConfig.supabaseServiceRoleKey}',
          'apikey': AdminConfig.supabaseServiceRoleKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'password': newPassword}),
      );
      if (response.statusCode == 200) {
        developer.log('✅ [Sync] Supabase Auth password reset for $userId');
      } else {
        developer.log('⚠️ [Sync] adminResetUserPassword failed: ${response.body}');
        throw Exception('Password reset failed: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('⚠️ [Sync] adminResetUserPassword error: $e');
      rethrow;
    }
  }
}
