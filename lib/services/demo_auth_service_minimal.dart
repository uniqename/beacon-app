import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/user_minimal.dart';

/// Demo authentication service that works without Firebase
class DemoAuthService extends ChangeNotifier {
  static final DemoAuthService _instance = DemoAuthService._internal();
  factory DemoAuthService() => _instance;
  DemoAuthService._internal();

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  final StreamController<AppUser?> _authStateController = StreamController<AppUser?>.broadcast();
  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  // Simulate anonymous sign in
  Future<AppUser?> signInAnonymously() async {
    try {
      print('Demo: Attempting anonymous sign in...');
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      final userId = 'demo_anonymous_${Random().nextInt(10000)}';
      
      final appUser = AppUser(
        uid: userId,
        email: 'anonymous@survivor.local',
        name: 'Anonymous Survivor',
        userType: UserType.survivor,
        isAnonymous: true,
        createdAt: DateTime.now(),
      );
      
      _currentUser = appUser;
      await _saveAnonymousStatus(true);
      notifyListeners();
      _authStateController.add(appUser);
      
      print('Demo: Anonymous sign in successful');
      return appUser;
    } catch (e) {
      print('Demo: Error signing in anonymously: $e');
      return null;
    }
  }

  // Simulate email/password registration
  Future<AppUser?> registerWithEmailAndPassword(
    String email, 
    String password, 
    String name, 
    String phone
  ) async {
    try {
      print('Demo: Attempting registration for $email...');
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 1000));
      
      final userId = 'demo_user_${Random().nextInt(10000)}';
      
      final appUser = AppUser(
        uid: userId,
        email: email,
        name: name,
        phone: phone,
        userType: UserType.survivor,
        isAnonymous: false,
        createdAt: DateTime.now(),
      );
      
      _currentUser = appUser;
      await _saveAnonymousStatus(false);
      notifyListeners();
      _authStateController.add(appUser);
      
      print('Demo: Registration successful');
      return appUser;
    } catch (e) {
      print('Demo: Error registering: $e');
      return null;
    }
  }

  // Simulate email/password sign in
  Future<AppUser?> signInWithEmailAndPassword(String email, String password) async {
    try {
      print('Demo: Attempting sign in for $email...');
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      final userId = 'demo_user_${email.hashCode}';
      
      final appUser = AppUser(
        uid: userId,
        email: email,
        name: 'Demo User',
        userType: UserType.survivor,
        isAnonymous: false,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastLoginAt: DateTime.now(),
      );
      
      _currentUser = appUser;
      await _saveAnonymousStatus(false);
      notifyListeners();
      _authStateController.add(appUser);
      
      print('Demo: Sign in successful');
      return appUser;
    } catch (e) {
      print('Demo: Error signing in: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('Demo: Signing out...');
      
      _currentUser = null;
      await _saveAnonymousStatus(false);
      notifyListeners();
      _authStateController.add(null);
      
      print('Demo: Sign out successful');
    } catch (e) {
      print('Demo: Error signing out: $e');
    }
  }

  // Check if current user is anonymous
  Future<bool> isAnonymousUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_anonymous') ?? false;
  }

  // Update user profile
  Future<void> updateUserProfile(AppUser user) async {
    try {
      print('Demo: Updating user profile...');
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      _currentUser = user;
      notifyListeners();
      _authStateController.add(user);
      
      print('Demo: Profile update successful');
    } catch (e) {
      print('Demo: Error updating profile: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      print('Demo: Sending password reset email to $email...');
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 1000));
      
      print('Demo: Password reset email sent');
    } catch (e) {
      print('Demo: Error resetting password: $e');
    }
  }

  // Save anonymous status to local storage
  Future<void> _saveAnonymousStatus(bool isAnonymous) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_anonymous', isAnonymous);
  }

  @override
  void dispose() {
    _authStateController.close();
    super.dispose();
  }
}