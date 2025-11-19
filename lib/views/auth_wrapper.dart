import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import 'auth/enhanced_login_screen.dart';
import 'home/home_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;
  bool _showFallback = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
    // Add fallback timer in case initialization takes too long
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isInitialized && mounted) {
        setState(() {
          _showFallback = true;
        });
      }
    });
  }

  void _initializeAuth() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    // Show fallback if initialization takes too long
    if (_showFallback && !_isInitialized) {
      return const EnhancedLoginScreen();
    }
    
    // Listen to local auth state changes
    return StreamBuilder<AppUser?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading only briefly
        if (snapshot.connectionState == ConnectionState.waiting && !_isInitialized) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading Beacon of New Beginnings...'),
                ],
              ),
            ),
          );
        }
        
        // Check if user is authenticated
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }
        
        return const EnhancedLoginScreen();
      },
    );
  }
}