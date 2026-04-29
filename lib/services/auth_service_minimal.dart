import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user_minimal.dart';
import 'local_database_service.dart';
import 'dart:async';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  AppUser? _currentUser;
  final StreamController<AppUser?> _authStateController = StreamController<AppUser?>.broadcast();

  AppUser? get currentUser => _currentUser;

  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  Future<bool> isAnonymousUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_anonymous') ?? false;
  }

  Future<AppUser?> signInAnonymously() async {
    try {
      developer.log('Creating anonymous user...');
      final userId = 'anonymous_${DateTime.now().millisecondsSinceEpoch}';

      final appUser = AppUser(
        uid: userId,
        email: 'anonymous@survivor.local',
        name: 'Anonymous Survivor',
        phone: null,
        userType: UserType.survivor,
        isAnonymous: true,
        createdAt: DateTime.now(),
      );

      final db = await LocalDatabaseService.database;
      await db.insert('users', {
        'uid': userId,
        'name': 'Anonymous Survivor',
        'email': 'anonymous@survivor.local',
        'userType': 'survivor',
        'is_anonymous': 1,
        'created_at': DateTime.now().toIso8601String(),
      });

      _currentUser = appUser;
      _authStateController.add(_currentUser);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_anonymous', true);
      await prefs.setString('currentUserId', userId);

      developer.log('Anonymous sign in successful: ${appUser.uid}');
      return appUser;
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error signing in anonymously: $e');
      }
      return null;
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<AppUser?> registerWithEmailAndPassword(String email, String password, String name, String phone) async {
    try {
      final db = await LocalDatabaseService.database;

      // Check if user already exists
      final existingUsers = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (existingUsers.isNotEmpty) {
        throw Exception('User with this email already exists');
      }

      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final passwordHash = _hashPassword(password);

      await db.insert('users', {
        'uid': userId,
        'name': name,
        'email': email,
        'phone': phone,
        'userType': 'survivor',
        'password_hash': passwordHash,
        'is_anonymous': 0,
        'created_at': DateTime.now().toIso8601String(),
      });

      final appUser = AppUser(
        uid: userId,
        name: name,
        email: email,
        phone: phone,
        userType: UserType.survivor,
        isAnonymous: false,
        createdAt: DateTime.now(),
      );

      _currentUser = appUser;
      _authStateController.add(_currentUser);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_anonymous', false);
      await prefs.setString('currentUserId', userId);
      await prefs.setString('userEmail', email);

      developer.log('Registration successful: $email');
      return appUser;
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error registering: $e');
      }
      return null;
    }
  }

  Future<AppUser?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final db = await LocalDatabaseService.database;
      final passwordHash = _hashPassword(password);

      final users = await db.query(
        'users',
        where: 'email = ? AND password_hash = ?',
        whereArgs: [email, passwordHash],
      );

      if (users.isEmpty) {
        throw Exception('Invalid email or password');
      }

      final userData = users.first;
      final appUser = AppUser(
        uid: userData['uid'] as String? ?? userData['id'] as String,
        name: userData['name'] as String? ?? 'User',
        email: userData['email'] as String? ?? email,
        phone: userData['phone'] as String?,
        userType: UserType.values.firstWhere(
          (e) => e.toString().split('.').last == userData['userType'],
          orElse: () => UserType.survivor,
        ),
        isAnonymous: (userData['is_anonymous'] as int?) == 1,
        createdAt: userData['created_at'] != null
            ? DateTime.parse(userData['created_at'] as String)
            : DateTime.now(),
      );

      _currentUser = appUser;
      _authStateController.add(_currentUser);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_anonymous', false);
      await prefs.setString('currentUserId', appUser.uid);
      await prefs.setString('userEmail', email);

      developer.log('Sign in successful: $email');
      return appUser;
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error signing in: $e');
      }
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      _currentUser = null;
      _authStateController.add(null);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_anonymous');
      await prefs.remove('currentUserId');
      await prefs.remove('userEmail');

      developer.log('Sign out successful');
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error signing out: $e');
      }
    }
  }

  Future<void> updateUserProfile(AppUser user) async {
    try {
      final db = await LocalDatabaseService.database;

      await db.update(
        'users',
        {
          'name': user.name,
          'email': user.email,
          'phone': user.phone,
          'userType': user.userType.toString().split('.').last,
        },
        where: 'uid = ?',
        whereArgs: [user.uid],
      );

      _currentUser = user;
      _authStateController.add(_currentUser);

      developer.log('Profile updated successfully');
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error updating profile: $e');
      }
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      developer.log('Password reset requested for: $email');
      // For local auth, password reset would require email verification
      // This is a simplified implementation
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error resetting password: $e');
      }
    }
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
