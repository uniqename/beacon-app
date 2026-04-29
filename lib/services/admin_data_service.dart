import 'dart:developer' as developer;
import 'local_database_service.dart';

/// Service for admin-level data management
/// Provides access to view, update, and delete user data and app data
class AdminDataService {
  // ========== USER MANAGEMENT ==========

  /// Get all users in the system
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await LocalDatabaseService.database;
    return await db.query('users', orderBy: 'created_at DESC');
  }

  /// Get users by type
  Future<List<Map<String, dynamic>>> getUsersByType(String userType) async {
    final db = await LocalDatabaseService.database;
    return await db.query(
      'users',
      where: 'user_type = ?',
      whereArgs: [userType],
      orderBy: 'created_at DESC',
    );
  }

  /// Get user by ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    final db = await LocalDatabaseService.database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    return results.isEmpty ? null : results.first;
  }

  /// Update user data (admin can modify any field)
  Future<bool> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      final db = await LocalDatabaseService.database;
      final rowsAffected = await db.update(
        'users',
        updates,
        where: 'id = ?',
        whereArgs: [userId],
      );
      return rowsAffected > 0;
    } catch (e) {
      developer.log('Error updating user: $e');
      return false;
    }
  }

  /// Delete user and all associated data
  Future<bool> deleteUser(String userId) async {
    try {
      final db = await LocalDatabaseService.database;

      // Delete all associated data
      await db.delete('safety_plans', where: 'user_id = ?', whereArgs: [userId]);
      await db.delete('evidence_logs', where: 'user_id = ?', whereArgs: [userId]);
      await db.delete('mood_entries', where: 'user_id = ?', whereArgs: [userId]);
      await db.delete('budget_transactions', where: 'user_id = ?', whereArgs: [userId]);
      await db.delete('secure_documents', where: 'user_id = ?', whereArgs: [userId]);
      await db.delete('disguise_settings', where: 'user_id = ?', whereArgs: [userId]);
      await db.delete('cases', where: 'survivor_id = ?', whereArgs: [userId]);
      await db.delete('emergency_alerts', where: 'user_id = ?', whereArgs: [userId]);

      // Delete user account
      final rowsAffected = await db.delete('users', where: 'id = ?', whereArgs: [userId]);
      return rowsAffected > 0;
    } catch (e) {
      developer.log('Error deleting user: $e');
      return false;
    }
  }

  /// Get user statistics
  Future<Map<String, int>> getUserStatistics() async {
    final db = await LocalDatabaseService.database;

    final totalUsers = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    final survivors = await db.rawQuery('SELECT COUNT(*) as count FROM users WHERE user_type = ?', ['survivor']);
    final counselors = await db.rawQuery('SELECT COUNT(*) as count FROM users WHERE user_type = ?', ['counselor']);
    final admins = await db.rawQuery('SELECT COUNT(*) as count FROM users WHERE user_type = ?', ['admin']);
    final anonymous = await db.rawQuery('SELECT COUNT(*) as count FROM users WHERE is_anonymous = 1');

    return {
      'total': totalUsers.first['count'] as int,
      'survivors': survivors.first['count'] as int,
      'counselors': counselors.first['count'] as int,
      'admins': admins.first['count'] as int,
      'anonymous': anonymous.first['count'] as int,
    };
  }

  // ========== EVIDENCE LOG MANAGEMENT ==========

  /// Get all evidence logs (all users)
  Future<List<Map<String, dynamic>>> getAllEvidenceLogs() async {
    final db = await LocalDatabaseService.database;
    return await db.query('evidence_logs', orderBy: 'date DESC');
  }

  /// Get evidence logs for specific user
  Future<List<Map<String, dynamic>>> getEvidenceLogsByUser(String userId) async {
    return await LocalDatabaseService.getEvidenceLogs(userId);
  }

  /// Update evidence log
  Future<bool> updateEvidenceLog(String evidenceId, Map<String, dynamic> updates) async {
    try {
      final db = await LocalDatabaseService.database;
      final rowsAffected = await db.update(
        'evidence_logs',
        updates,
        where: 'id = ?',
        whereArgs: [evidenceId],
      );
      return rowsAffected > 0;
    } catch (e) {
      developer.log('Error updating evidence log: $e');
      return false;
    }
  }

  /// Delete evidence log
  Future<bool> deleteEvidenceLog(String evidenceId) async {
    try {
      await LocalDatabaseService.deleteEvidenceLog(evidenceId);
      return true;
    } catch (e) {
      developer.log('Error deleting evidence log: $e');
      return false;
    }
  }

  /// Get evidence statistics
  Future<Map<String, dynamic>> getEvidenceStatistics() async {
    final db = await LocalDatabaseService.database;

    final total = await db.rawQuery('SELECT COUNT(*) as count FROM evidence_logs');
    final bySeverity = await db.rawQuery(
      'SELECT incident_type, COUNT(*) as count FROM evidence_logs GROUP BY incident_type'
    );

    return {
      'total': total.first['count'] as int,
      'by_severity': { for (var e in bySeverity) e['incident_type'] : e['count'] },
    };
  }

  // ========== SAFETY PLAN MANAGEMENT ==========

  /// Get all safety plans
  Future<List<Map<String, dynamic>>> getAllSafetyPlans() async {
    final db = await LocalDatabaseService.database;
    return await db.query('safety_plans', orderBy: 'updated_at DESC');
  }

  /// Get safety plan by user
  Future<Map<String, dynamic>?> getSafetyPlanByUser(String userId) async {
    return await LocalDatabaseService.getSafetyPlan(userId);
  }

  /// Delete safety plan
  Future<bool> deleteSafetyPlan(String userId) async {
    try {
      final db = await LocalDatabaseService.database;
      final rowsAffected = await db.delete('safety_plans', where: 'user_id = ?', whereArgs: [userId]);
      return rowsAffected > 0;
    } catch (e) {
      developer.log('Error deleting safety plan: $e');
      return false;
    }
  }

  // ========== MOOD TRACKING MANAGEMENT ==========

  /// Get all mood entries
  Future<List<Map<String, dynamic>>> getAllMoodEntries() async {
    final db = await LocalDatabaseService.database;
    return await db.query('mood_entries', orderBy: 'date DESC');
  }

  /// Get mood entries by user
  Future<List<Map<String, dynamic>>> getMoodEntriesByUser(String userId, {int? days}) async {
    return await LocalDatabaseService.getMoodEntries(userId, days: days);
  }

  /// Delete mood entry
  Future<bool> deleteMoodEntry(String entryId) async {
    try {
      final db = await LocalDatabaseService.database;
      final rowsAffected = await db.delete('mood_entries', where: 'id = ?', whereArgs: [entryId]);
      return rowsAffected > 0;
    } catch (e) {
      developer.log('Error deleting mood entry: $e');
      return false;
    }
  }

  /// Get mood statistics
  Future<Map<String, dynamic>> getMoodStatistics() async {
    final db = await LocalDatabaseService.database;

    final total = await db.rawQuery('SELECT COUNT(*) as count FROM mood_entries');
    final avgMood = await db.rawQuery('SELECT AVG(mood_rating) as avg FROM mood_entries');

    return {
      'total_entries': total.first['count'] as int,
      'average_mood': (avgMood.first['avg'] as num?)?.toDouble() ?? 0.0,
    };
  }

  // ========== BUDGET/FINANCIAL MANAGEMENT ==========

  /// Get all budget transactions
  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await LocalDatabaseService.database;
    return await db.query('budget_transactions', orderBy: 'date DESC');
  }

  /// Get transactions by user
  Future<List<Map<String, dynamic>>> getTransactionsByUser(String userId, {bool includeHidden = true}) async {
    return await LocalDatabaseService.getBudgetTransactions(userId, includeHidden: includeHidden);
  }

  /// Delete transaction
  Future<bool> deleteTransaction(String transactionId) async {
    try {
      final db = await LocalDatabaseService.database;
      final rowsAffected = await db.delete('budget_transactions', where: 'id = ?', whereArgs: [transactionId]);
      return rowsAffected > 0;
    } catch (e) {
      developer.log('Error deleting transaction: $e');
      return false;
    }
  }

  /// Get financial statistics
  Future<Map<String, dynamic>> getFinancialStatistics() async {
    final db = await LocalDatabaseService.database;

    final totalIncome = await db.rawQuery('SELECT SUM(amount) as total FROM budget_transactions WHERE is_income = 1');
    final totalExpenses = await db.rawQuery('SELECT SUM(amount) as total FROM budget_transactions WHERE is_income = 0');
    final hiddenTransactions = await db.rawQuery('SELECT COUNT(*) as count FROM budget_transactions WHERE is_hidden = 1');

    return {
      'total_income': (totalIncome.first['total'] as num?)?.toDouble() ?? 0.0,
      'total_expenses': (totalExpenses.first['total'] as num?)?.toDouble() ?? 0.0,
      'hidden_transactions': hiddenTransactions.first['count'] as int,
    };
  }

  // ========== DOCUMENT VAULT MANAGEMENT ==========

  /// Get all documents
  Future<List<Map<String, dynamic>>> getAllDocuments() async {
    final db = await LocalDatabaseService.database;
    return await db.query('secure_documents', orderBy: 'uploaded_at DESC');
  }

  /// Get documents by user
  Future<List<Map<String, dynamic>>> getDocumentsByUser(String userId) async {
    return await LocalDatabaseService.getSecureDocuments(userId);
  }

  /// Delete document
  Future<bool> deleteDocument(String documentId) async {
    try {
      await LocalDatabaseService.deleteSecureDocument(documentId);
      return true;
    } catch (e) {
      developer.log('Error deleting document: $e');
      return false;
    }
  }

  // ========== CHAT MESSAGE MANAGEMENT ==========

  /// Get all chat messages
  Future<List<Map<String, dynamic>>> getAllChatMessages() async {
    final db = await LocalDatabaseService.database;
    return await db.query('chat_messages', orderBy: 'timestamp DESC');
  }

  /// Get messages by conversation
  Future<List<Map<String, dynamic>>> getMessagesByConversation(String conversationId) async {
    return await LocalDatabaseService.getChatMessages(conversationId);
  }

  /// Delete chat message
  Future<bool> deleteChatMessage(String messageId) async {
    try {
      final db = await LocalDatabaseService.database;
      final rowsAffected = await db.delete('chat_messages', where: 'id = ?', whereArgs: [messageId]);
      return rowsAffected > 0;
    } catch (e) {
      developer.log('Error deleting chat message: $e');
      return false;
    }
  }

  // ========== EMERGENCY ALERTS MANAGEMENT ==========

  /// Get all emergency alerts
  Future<List<Map<String, dynamic>>> getAllEmergencyAlerts() async {
    final db = await LocalDatabaseService.database;
    return await db.query('emergency_alerts', orderBy: 'timestamp DESC');
  }

  /// Get emergency alerts by user
  Future<List<Map<String, dynamic>>> getEmergencyAlertsByUser(String userId) async {
    final db = await LocalDatabaseService.database;
    return await db.query(
      'emergency_alerts',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );
  }

  /// Delete emergency alert
  Future<bool> deleteEmergencyAlert(String alertId) async {
    try {
      final db = await LocalDatabaseService.database;
      final rowsAffected = await db.delete('emergency_alerts', where: 'id = ?', whereArgs: [alertId]);
      return rowsAffected > 0;
    } catch (e) {
      developer.log('Error deleting emergency alert: $e');
      return false;
    }
  }

  // ========== GLOBAL APP STATISTICS ==========

  /// Get comprehensive app statistics
  Future<Map<String, dynamic>> getAppStatistics() async {
    final userStats = await getUserStatistics();
    final evidenceStats = await getEvidenceStatistics();
    final moodStats = await getMoodStatistics();
    final financialStats = await getFinancialStatistics();

    final db = await LocalDatabaseService.database;
    final totalSafetyPlans = await db.rawQuery('SELECT COUNT(*) as count FROM safety_plans');
    final totalDocuments = await db.rawQuery('SELECT COUNT(*) as count FROM secure_documents');
    final totalMessages = await db.rawQuery('SELECT COUNT(*) as count FROM chat_messages');
    final totalAlerts = await db.rawQuery('SELECT COUNT(*) as count FROM emergency_alerts');

    return {
      'users': userStats,
      'evidence': evidenceStats,
      'mood': moodStats,
      'financial': financialStats,
      'safety_plans': totalSafetyPlans.first['count'] as int,
      'documents': totalDocuments.first['count'] as int,
      'messages': totalMessages.first['count'] as int,
      'emergency_alerts': totalAlerts.first['count'] as int,
    };
  }

  // ========== DATA EXPORT ==========

  /// Export all user data for a specific user (GDPR compliance)
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    final user = await getUserById(userId);
    final safetyPlan = await getSafetyPlanByUser(userId);
    final evidence = await getEvidenceLogsByUser(userId);
    final moodEntries = await getMoodEntriesByUser(userId);
    final transactions = await getTransactionsByUser(userId);
    final documents = await getDocumentsByUser(userId);
    final alerts = await getEmergencyAlertsByUser(userId);

    return {
      'user': user,
      'safety_plan': safetyPlan,
      'evidence_logs': evidence,
      'mood_entries': moodEntries,
      'transactions': transactions,
      'documents': documents,
      'emergency_alerts': alerts,
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  // ========== BULK OPERATIONS ==========

  /// Delete all data for users who haven't logged in for X days
  Future<int> deleteInactiveUsers(int inactiveDays) async {
    try {
      final db = await LocalDatabaseService.database;
      final cutoffDate = DateTime.now().subtract(Duration(days: inactiveDays)).toIso8601String();

      // Get inactive users
      final inactiveUsers = await db.query(
        'users',
        where: 'last_login_at < ? OR last_login_at IS NULL',
        whereArgs: [cutoffDate],
      );

      int deletedCount = 0;
      for (final user in inactiveUsers) {
        final success = await deleteUser(user['id'] as String);
        if (success) deletedCount++;
      }

      return deletedCount;
    } catch (e) {
      developer.log('Error deleting inactive users: $e');
      return 0;
    }
  }

  /// Clear all anonymous user data
  Future<int> clearAnonymousData() async {
    try {
      final db = await LocalDatabaseService.database;

      // Get all anonymous users
      final anonymousUsers = await db.query(
        'users',
        where: 'is_anonymous = 1',
      );

      int deletedCount = 0;
      for (final user in anonymousUsers) {
        final success = await deleteUser(user['id'] as String);
        if (success) deletedCount++;
      }

      return deletedCount;
    } catch (e) {
      developer.log('Error clearing anonymous data: $e');
      return 0;
    }
  }
}
