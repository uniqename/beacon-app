import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:async';
import '../models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  
  bool _initialized = false;
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Check for existing session
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString('currentUserId');
      if (savedUserId != null) {
        _currentUser = AppUser(
          id: savedUserId,
          email: prefs.getString('userEmail') ?? '',
          displayName: prefs.getString('userDisplayName') ?? 'User',
          userType: UserType.survivor,
          isAnonymous: false,
          createdAt: DateTime.now(),
        );
      }
      _authStateController.add(_currentUser);
      _initialized = true;
    } catch (e) {
      _authStateController.add(null);
      _initialized = true;
    }
  }

  Database? _database;
  AppUser? _currentUser;
  final StreamController<AppUser?> _authStateController = StreamController<AppUser?>.broadcast();

  AppUser? get currentUser => _currentUser;
  
  Stream<AppUser?> get authStateChanges => _authStateController.stream;
  
  // Initialize local database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ngo_support.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id TEXT PRIMARY KEY,
            email TEXT,
            password_hash TEXT,
            display_name TEXT,
            phone_number TEXT,
            user_type TEXT,
            is_anonymous INTEGER,
            created_at TEXT,
            last_login_at TEXT,
            emergency_contact TEXT,
            emergency_contact_phone TEXT,
            support_needs TEXT,
            current_location TEXT,
            has_active_cases INTEGER,
            specialization TEXT,
            qualifications TEXT,
            is_available INTEGER
          )
        ''');
        
        await db.execute('''
          CREATE TABLE cases(
            id TEXT PRIMARY KEY,
            survivor_id TEXT,
            type TEXT,
            priority TEXT,
            status TEXT,
            title TEXT,
            description TEXT,
            created_at TEXT,
            is_anonymous INTEGER,
            contact_info TEXT,
            latitude REAL,
            longitude REAL,
            assigned_counselor_id TEXT,
            assigned_at TEXT,
            notes TEXT,
            attachments TEXT
          )
        ''');
        
        await db.execute('''
          CREATE TABLE emergency_alerts(
            id TEXT PRIMARY KEY,
            user_id TEXT,
            latitude REAL,
            longitude REAL,
            accuracy REAL,
            timestamp TEXT,
            message TEXT,
            status TEXT,
            type TEXT
          )
        ''');
      },
    );
  }

  // Anonymous sign in for survivors who want privacy
  Future<AppUser?> signInAnonymously() async {
    try {
      print('Creating anonymous user...');
      final userId = 'anonymous_${DateTime.now().millisecondsSinceEpoch}';
      
      final appUser = AppUser(
        id: userId,
        email: 'anonymous@survivor.local',
        displayName: 'Anonymous Survivor',
        userType: UserType.survivor,
        isAnonymous: true,
        createdAt: DateTime.now(),
      );
      
      final db = await database;
      await db.insert('users', appUser.toMap());
      
      _currentUser = appUser;
      _authStateController.add(_currentUser);
      await _saveAnonymousStatus(true);
      
      print('Anonymous sign in successful: ${appUser.id}');
      return appUser;
    } catch (e) {
      print('Error signing in anonymously: $e');
      return null;
    }
  }

  // Email/password registration
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
      // Check if user already exists
      final db = await database;
      final existingUsers = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );
      
      if (existingUsers.isNotEmpty) {
        throw Exception('User with this email already exists');
      }
      
      // Validate password
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }
      
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final passwordHash = _hashPassword(password);
      
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
      );
      
      final userData = appUser.toMap();
      userData['password_hash'] = passwordHash;
      
      await db.insert('users', userData);
      
      _currentUser = appUser;
      _authStateController.add(_currentUser);
      await _saveAnonymousStatus(false);
      
      print('Registration successful for $email');
      return appUser;
    } catch (e) {
      print('Error registering user: $e');
      return null;
    }
  }

  // Email/password sign in
  Future<AppUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final db = await database;
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
      await _updateLastLogin(userData['id'] as String);
      
      final appUser = AppUser.fromMap(userData);
      _currentUser = appUser;
      _authStateController.add(_currentUser);
      await _saveAnonymousStatus(appUser.isAnonymous);
      
      print('Sign in successful for $email');
      return appUser;
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  // Get user data from local database
  Future<AppUser?> getUserData(String uid) async {
    try {
      final db = await database;
      final users = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [uid],
      );
      
      if (users.isNotEmpty) {
        return AppUser.fromMap(users.first);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update user data
  Future<bool> updateUserData(AppUser user) async {
    try {
      final db = await database;
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
      print('Error updating user data: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _currentUser = null;
      _authStateController.add(null);
      await _clearAnonymousStatus();
      print('Sign out successful');
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  // Password reset (simplified for local storage)
  Future<bool> resetPassword(String email) async {
    try {
      final db = await database;
      final users = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );
      
      if (users.isEmpty) {
        throw Exception('No user found with this email');
      }
      
      // In a real app, you would send an email here
      // For now, we'll just simulate a successful reset
      print('Password reset instructions would be sent to $email');
      return true;
    } catch (e) {
      print('Error sending password reset email: $e');
      return false;
    }
  }

  // Delete account (for anonymous users)
  Future<bool> deleteAccount() async {
    try {
      if (_currentUser != null) {
        final db = await database;
        
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
        
        print('Account deleted successfully');
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting account: $e');
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
    final bytes = utf8.encode(password + 'ngo_support_salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _updateLastLogin(String uid) async {
    try {
      final db = await database;
      await db.update(
        'users',
        {'last_login_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [uid],
      );
    } catch (e) {
      print('Error updating last login: $e');
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
}