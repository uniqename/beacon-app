import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/app_config_service.dart';
import '../models/user.dart';
import 'auth/enhanced_login_screen.dart';
import 'home/home_screen.dart';
import 'onboarding/region_select_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;
  bool _showFallback = false;
  bool _regionSelected = true; // assume selected until loaded

  @override
  void initState() {
    super.initState();
    _init();
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isInitialized && mounted) {
        setState(() => _showFallback = true);
      }
    });
  }

  void _init() async {
    // Load region config first
    final hasRegion = await AppConfigService.instance.load();
    if (mounted) setState(() => _regionSelected = hasRegion);

    // Then init auth
    try {
      if (!mounted) return;
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.initialize();
    } catch (e) {
      debugPrint('Auth initialization error: $e');
    }
    if (mounted) setState(() => _isInitialized = true);
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // Show fallback if initialization takes too long
    if (_showFallback && !_isInitialized) {
      return const EnhancedLoginScreen();
    }

    // Region picker — shown only on first ever launch
    if (!_regionSelected) {
      return RegionSelectScreen(
        onSelected: () => setState(() => _regionSelected = true),
      );
    }

    // Listen to local auth state changes
    return StreamBuilder<AppUser?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !_isInitialized) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading…'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }

        return const EnhancedLoginScreen();
      },
    );
  }
}