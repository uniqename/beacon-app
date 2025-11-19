import 'package:flutter/foundation.dart';
import '../models/user_minimal.dart';
import 'demo_auth_service_minimal.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final DemoAuthService _demoAuth = DemoAuthService();
  
  AppUser? get currentUser => _demoAuth.currentUser;
  
  Stream<AppUser?> get authStateChanges => _demoAuth.authStateChanges;
  
  Future<bool> isAnonymousUser() async {
    return _demoAuth.isAnonymousUser();
  }
  
  Future<AppUser?> signInAnonymously() async {
    try {
      return await _demoAuth.signInAnonymously();
    } catch (e) {
      if (kDebugMode) {
        print('Error signing in anonymously: $e');
      }
      return null;
    }
  }
  
  Future<AppUser?> registerWithEmailAndPassword(String email, String password, String name, String phone) async {
    try {
      return await _demoAuth.registerWithEmailAndPassword(email, password, name, phone);
    } catch (e) {
      if (kDebugMode) {
        print('Error registering: $e');
      }
      return null;
    }
  }
  
  Future<AppUser?> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _demoAuth.signInWithEmailAndPassword(email, password);
    } catch (e) {
      if (kDebugMode) {
        print('Error signing in: $e');
      }
      return null;
    }
  }
  
  Future<void> signOut() async {
    try {
      await _demoAuth.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
    }
  }
  
  Future<void> updateUserProfile(AppUser user) async {
    try {
      await _demoAuth.updateUserProfile(user);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating profile: $e');
      }
    }
  }
  
  Future<void> resetPassword(String email) async {
    try {
      await _demoAuth.resetPassword(email);
    } catch (e) {
      if (kDebugMode) {
        print('Error resetting password: $e');
      }
    }
  }
}