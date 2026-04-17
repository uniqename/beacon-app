import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import '../models/user.dart';
import '../constants/admin_config.dart';
import 'local_database_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  
  bool _initialized = false;
  
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      developer.log('🔐 [Auth] Initializing authentication service...');
      // Check for existing session
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString('currentUserId');
      final savedEmail = prefs.getString('userEmail');

      if (savedUserId != null) {
        developer.log('🔐 [Auth] Found saved session for user ID: $savedUserId, email: $savedEmail');
        // Load full user data from database
        final userData = await getUserData(savedUserId);
        if (userData != null) {
          developer.log('✅ [Auth] Successfully loaded user data: ${userData.email}, type: ${userData.userType}');
          _currentUser = userData;
        } else {
          developer.log('⚠️ [Auth] User data not found in database, clearing session');
          // Clear invalid session
          await prefs.remove('currentUserId');
          await prefs.remove('userEmail');
          await prefs.remove('userDisplayName');
        }
      } else {
        developer.log('ℹ️ [Auth] No saved session found');
      }
      _authStateController.add(_currentUser);
      _initialized = true;
      developer.log('✅ [Auth] Authentication service initialized');
    } catch (e) {
      developer.log('❌ [Auth] Error initializing auth: $e');
      _authStateController.add(null);
      _initialized = true;
    }
  }

  AppUser? _currentUser;
  final StreamController<AppUser?> _authStateController = StreamController<AppUser?>.broadcast();

  AppUser? get currentUser => _currentUser;

  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  // Anonymous sign in for survivors who want privacy
  Future<AppUser?> signInAnonymously() async {
    try {
      developer.log('Creating anonymous user...');
      final userId = 'anonymous_${DateTime.now().millisecondsSinceEpoch}';

      final appUser = AppUser(
        id: userId,
        email: 'anonymous@survivor.local',
        displayName: 'Anonymous Survivor',
        userType: UserType.survivor,
        isAnonymous: true,
        createdAt: DateTime.now(),
      );

      // Do NOT persist anonymous users to the DB — they are session-only
      _currentUser = appUser;
      _authStateController.add(_currentUser);
      await _saveAnonymousStatus(true);
      await _saveUserSession(userId, appUser.email ?? 'anonymous@survivor.local', appUser.displayName ?? 'Anonymous Survivor');

      developer.log('Anonymous sign in successful: ${appUser.id}');
      return appUser;
    } catch (e) {
      developer.log('Error signing in anonymously: $e');
      // Still return a valid anonymous user even if session save fails
      final userId = 'anonymous_${DateTime.now().millisecondsSinceEpoch}';
      return AppUser(
        id: userId,
        email: 'anonymous@survivor.local',
        displayName: 'Anonymous Survivor',
        userType: UserType.survivor,
        isAnonymous: true,
        createdAt: DateTime.now(),
      );
    }
  }

  // Email/password registration — uses Supabase Auth for cloud accounts,
  // falls back to local SQLite if Supabase is not configured.
  Future<AppUser?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required UserType userType,
    String? phoneNumber,
    String? emergencyContact,
    String? emergencyContactPhone,
  }) async {
    try {
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

      String userId;

      if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
        // Register via Supabase Auth — account works across devices
        sb.SupabaseClient client;
        try {
          client = sb.Supabase.instance.client;
        } catch (_) {
          await sb.Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
          client = sb.Supabase.instance.client;
        }

        final response = await client.auth.signUp(
          email: email,
          password: password,
          data: {
            'display_name': displayName,
            'user_type': userType.toString().split('.').last,
            'phone_number': phoneNumber ?? '',
          },
        );

        if (response.user == null) {
          throw Exception('Account creation failed. Please try again.');
        }
        userId = response.user!.id;
        developer.log('✅ [Auth] Supabase registration successful for $email');
      } else {
        // Fallback: local SQLite
        final db = await LocalDatabaseService.database;
        final existingUsers = await db.query('users', where: 'email = ?', whereArgs: [email]);
        if (existingUsers.isNotEmpty) {
          throw Exception('An account with this email already exists');
        }
        userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
        developer.log('⚠️ [Auth] Supabase not configured, using local storage');
      }

      // Helpers (counselors/volunteers) start as pending, others are auto-approved
      final approvalStatus = (userType == UserType.counselor || userType == UserType.volunteer)
          ? 'pending'
          : 'approved';

      final appUser = AppUser(
        id: userId,
        email: email,
        displayName: displayName,
        phoneNumber: phoneNumber,
        userType: userType,
        isAnonymous: false,
        createdAt: DateTime.now(),
        emergencyContact: emergencyContact,
        emergencyContactPhone: emergencyContactPhone,
        approvalStatus: approvalStatus,
      );

      // Always save to local DB for offline access
      try {
        final db = await LocalDatabaseService.database;
        final userData = appUser.toMap();
        userData['password_hash'] = _hashPassword(password);
        await db.insert('users', userData,
            conflictAlgorithm: ConflictAlgorithm.ignore);
      } catch (dbErr) {
        developer.log('⚠️ [Auth] Local DB save failed (non-fatal): $dbErr');
      }

      _currentUser = appUser;
      _authStateController.add(_currentUser);
      await _saveAnonymousStatus(false);
      await _saveUserSession(userId, email, displayName);

      developer.log('✅ [Auth] Registration successful for $email');
      return appUser;
    } catch (e) {
      developer.log('❌ [Auth] Registration error: $e');
      rethrow; // Let the UI show the real error message
    }
  }

  // Admin registration with secret code validation
  Future<AppUser?> registerAdmin({
    required String email,
    required String password,
    required String displayName,
    required String adminSecretCode,
  }) async {
    try {
      // Validate admin secret code
      if (!AdminConfig.validateSecretCode(adminSecretCode)) {
        throw Exception('Invalid admin secret code');
      }

      // Check email domain restrictions
      if (!AdminConfig.isAllowedAdminEmail(email) && !AdminConfig.isPreApprovedEmail(email)) {
        throw Exception('Email domain not authorized for admin access');
      }

      // Check if user already exists
      final db = await LocalDatabaseService.database;
      final existingUsers = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (existingUsers.isNotEmpty) {
        throw Exception('User with this email already exists');
      }

      // Check max admin accounts limit
      final adminCount = await db.rawQuery(
        'SELECT COUNT(*) as count FROM users WHERE user_type = ?',
        ['admin'],
      );
      final count = adminCount.first['count'] as int;
      if (count >= AdminConfig.maxAdminAccounts) {
        throw Exception('Maximum admin accounts limit reached');
      }

      // Validate password
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      final userId = 'admin_${DateTime.now().millisecondsSinceEpoch}';
      final passwordHash = _hashPassword(password);

      final appUser = AppUser(
        id: userId,
        email: email,
        displayName: displayName,
        userType: UserType.admin,
        isAnonymous: false,
        createdAt: DateTime.now(),
      );

      final userData = appUser.toMap();
      userData['password_hash'] = passwordHash;
      userData['admin_secret_validated'] = 1;

      developer.log('🔐 [Auth] Inserting admin user with type: ${userData['user_type']}');
      await db.insert('users', userData);

      // Verify the user was inserted correctly
      final verifyUsers = await db.query('users', where: 'id = ?', whereArgs: [userId]);
      if (verifyUsers.isNotEmpty) {
        developer.log('✅ [Auth] Admin user verified in DB: type=${verifyUsers.first['user_type']}');
      }

      _currentUser = appUser;
      _authStateController.add(_currentUser);
      await _saveAnonymousStatus(false);
      await _saveUserSession(userId, email, displayName);

      developer.log('✅ [Auth] Admin registration successful for $email as ${appUser.userType}');
      return appUser;
    } catch (e) {
      developer.log('Error registering admin: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Email/password sign in
  Future<AppUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final db = await LocalDatabaseService.database;
      final passwordHash = _hashPassword(password);

      developer.log('🔐 [Auth] Attempting sign in for: $email');
      developer.log('🔐 [Auth] Password hash: ${passwordHash.substring(0, 10)}...');

      final users = await db.query(
        'users',
        where: 'email = ? AND password_hash = ?',
        whereArgs: [email, passwordHash],
      );

      developer.log('🔐 [Auth] Found ${users.length} matching users');

      if (users.isEmpty) {
        // Try without password hash to see if user exists
        final allUsers = await db.query('users', where: 'email = ?', whereArgs: [email]);
        if (allUsers.isNotEmpty) {
          developer.log('❌ [Auth] User exists but password doesn\'t match');
          developer.log('❌ [Auth] Stored hash: ${allUsers.first['password_hash']}');
        } else {
          developer.log('❌ [Auth] No user found with email: $email');
        }
        throw Exception('Invalid email or password');
      }

      final userData = users.first;
      developer.log('✅ [Auth] User data: ${userData.keys.join(', ')}');
      developer.log('✅ [Auth] User type in DB: ${userData['user_type']}');

      await _updateLastLogin(userData['id'] as String);

      final appUser = AppUser.fromMap(userData);
      developer.log('✅ [Auth] Loaded user type: ${appUser.userType}');

      _currentUser = appUser;
      _authStateController.add(_currentUser);
      await _saveAnonymousStatus(appUser.isAnonymous);
      await _saveUserSession(appUser.id, email, appUser.displayName ?? 'User');

      developer.log('✅ [Auth] Sign in successful for $email as ${appUser.userType}');
      return appUser;
    } catch (e) {
      developer.log('❌ [Auth] Error signing in: $e');
      return null;
    }
  }

  // Get user data from local database
  Future<AppUser?> getUserData(String uid) async {
    try {
      developer.log('🔐 [Auth] Fetching user data for ID: $uid');
      final db = await LocalDatabaseService.database;
      final users = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [uid],
      );

      if (users.isNotEmpty) {
        developer.log('✅ [Auth] User found in database: ${users.first['email']}, type: ${users.first['user_type']}');
        final user = AppUser.fromMap(users.first);
        developer.log('✅ [Auth] User mapped to AppUser: ${user.email}, type: ${user.userType}');
        return user;
      }
      developer.log('⚠️ [Auth] No user found with ID: $uid');
      return null;
    } catch (e) {
      developer.log('❌ [Auth] Error getting user data: $e');
      return null;
    }
  }

  // Update user data
  Future<bool> updateUserData(AppUser user) async {
    try {
      final db = await LocalDatabaseService.database;
      await db.update(
        'users',
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
      
      if (_currentUser?.id == user.id) {
        _currentUser = user;
        _authStateController.add(_currentUser);
      }
      
      return true;
    } catch (e) {
      developer.log('Error updating user data: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _currentUser = null;
      _authStateController.add(null);
      await _clearAnonymousStatus();

      // Clear user session
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('currentUserId');
      await prefs.remove('userEmail');
      await prefs.remove('userDisplayName');

      developer.log('Sign out successful');
    } catch (e) {
      developer.log('Error signing out: $e');
    }
  }

  // Password reset via Supabase Auth email
  Future<bool> resetPassword(String email) async {
    try {
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        developer.log('⚠️ [Auth] Supabase not configured for password reset');
        return false;
      }

      // Initialize a temporary Supabase client if needed
      sb.SupabaseClient? client;
      try {
        client = sb.Supabase.instance.client;
      } catch (_) {
        await sb.Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
        client = sb.Supabase.instance.client;
      }

      await client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://beaconnewbeginnings.org/reset-password',
      );

      developer.log('✅ [Auth] Password reset email sent to $email');
      return true;
    } catch (e) {
      developer.log('❌ [Auth] Error sending password reset email: $e');
      return false;
    }
  }

  // Delete account (for anonymous users)
  Future<bool> deleteAccount() async {
    try {
      if (_currentUser != null) {
        final db = await LocalDatabaseService.database;
        
        // Delete user cases
        await db.delete(
          'cases',
          where: 'survivor_id = ?',
          whereArgs: [_currentUser!.id],
        );
        
        // Delete user emergency alerts
        await db.delete(
          'emergency_alerts',
          where: 'user_id = ?',
          whereArgs: [_currentUser!.id],
        );
        
        // Delete user account
        await db.delete(
          'users',
          where: 'id = ?',
          whereArgs: [_currentUser!.id],
        );
        
        _currentUser = null;
        _authStateController.add(null);
        await _clearAnonymousStatus();
        
        developer.log('Account deleted successfully');
        return true;
      }
      return false;
    } catch (e) {
      developer.log('Error deleting account: $e');
      return false;
    }
  }

  // Check if user is anonymous
  Future<bool> isAnonymousUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_anonymous') ?? false;
  }

  // Private helper methods
  String _hashPassword(String password) {
    final bytes = utf8.encode('${password}ngo_support_salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _updateLastLogin(String uid) async {
    try {
      final db = await LocalDatabaseService.database;
      await db.update(
        'users',
        {'last_updated': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [uid],
      );
      developer.log('✅ [Auth] Updated last login for user: $uid');
    } catch (e) {
      developer.log('❌ [Auth] Failed to update last login: $e');
      developer.log('Error updating last login: $e');
    }
  }

  Future<void> _saveAnonymousStatus(bool isAnonymous) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_anonymous', isAnonymous);
  }

  Future<void> _clearAnonymousStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_anonymous');
  }

  Future<void> _saveUserSession(String userId, String email, String displayName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUserId', userId);
    await prefs.setString('userEmail', email);
    await prefs.setString('userDisplayName', displayName);
  }

  Future<bool> verifyPassword(String password) async {
    try {
      if (_currentUser == null) {
        developer.log('No current user to verify password for');
        return false;
      }

      final db = await LocalDatabaseService.database;
      final List<Map<String, dynamic>> result = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [_currentUser!.email],
      );

      if (result.isEmpty) {
        developer.log('User not found in database');
        return false;
      }

      final storedHash = result.first['password_hash'] as String?;
      if (storedHash == null) {
        developer.log('No password hash found for user');
        return false;
      }

      final inputHash = _hashPassword(password);
      return inputHash == storedHash;
    } catch (e) {
      developer.log('Error verifying password: $e');
      return false;
    }
  }
}