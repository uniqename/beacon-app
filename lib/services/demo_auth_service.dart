import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

/// Demo authentication service that works without Firebase
/// This allows testing the app UI and features without needing Firebase setup
class DemoAuthService extends ChangeNotifier {
  static final DemoAuthService _instance = DemoAuthService._internal();
  factory DemoAuthService() => _instance;
  DemoAuthService._internal();

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  // Simulate anonymous sign in
  Future<AppUser?> signInAnonymously() async {
    try {
      print('Demo: Attempting anonymous sign in...');
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      final userId = 'demo_anonymous_${Random().nextInt(10000)}';
      
      final appUser = AppUser(
        id: userId,
        email: 'anonymous@survivor.local',
        displayName: 'Anonymous Survivor',
        userType: UserType.survivor,
        isAnonymous: true,
        createdAt: DateTime.now(),
      );
      
      _currentUser = appUser;
      await _saveAnonymousStatus(true);
      notifyListeners(); // Notify UI of auth state change
      
      print('Demo: Anonymous sign in successful');
      return appUser;
    } catch (e) {
      print('Demo: Error signing in anonymously: $e');
      return null;
    }
  }

  // Simulate email/password registration
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
      print('Demo: Attempting registration for $email...');
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Basic validation
      if (password.length < 6) {
        throw Exception('Password should be at least 6 characters');
      }
      
      if (!email.contains('@')) {
        throw Exception('Invalid email format');
      }
      
      final userId = 'demo_user_${Random().nextInt(10000)}';
      
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
      
      _currentUser = appUser;
      await _saveAnonymousStatus(false);
      notifyListeners(); // Notify UI of auth state change
      
      print('Demo: Registration successful for $email');
      return appUser;
    } catch (e) {
      print('Demo: Error registering: $e');
      return null;
    }
  }

  // Simulate email/password sign in
  Future<AppUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('Demo: Attempting login for $email...');
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 600));
      
      // For demo, any email/password combo works
      final userId = 'demo_user_${email.hashCode.abs()}';
      
      final appUser = AppUser(
        id: userId,
        email: email,
        displayName: 'Demo User',
        userType: UserType.survivor,
        isAnonymous: false,
        createdAt: DateTime.now(),
      );
      
      _currentUser = appUser;
      await _saveAnonymousStatus(false);
      notifyListeners(); // Notify UI of auth state change
      
      print('Demo: Login successful for $email');
      return appUser;
    } catch (e) {
      print('Demo: Error signing in: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    print('Demo: Signing out...');
    _currentUser = null;
    await _saveAnonymousStatus(false);
    notifyListeners(); // Notify UI of auth state change
    print('Demo: Sign out successful');
  }

  // Helper method to save anonymous status
  Future<void> _saveAnonymousStatus(bool isAnonymous) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_anonymous', isAnonymous);
    } catch (e) {
      print('Demo: Error saving anonymous status: $e');
    }
  }

  // Check if user is anonymous
  Future<bool> isAnonymousUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_anonymous') ?? false;
    } catch (e) {
      print('Demo: Error checking anonymous status: $e');
      return false;
    }
  }
}