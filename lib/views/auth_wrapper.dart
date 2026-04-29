import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/app_config_service.dart';
import '../models/user.dart';
import 'auth/enhanced_login_screen.dart';
import 'auth/reset_password_screen.dart';
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
  bool _regionSelected = true;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _init();
    _setupDeepLinks();
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isInitialized && mounted) {
        setState(() => _showFallback = true);
      }
    });
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  void _setupDeepLinks() async {
    final appLinks = AppLinks();

    // Handle cold-start deep link (app launched via the link)
    final initialUri = await appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    // Handle warm-start deep link (app already running)
    _linkSub = appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  void _handleDeepLink(Uri uri) {
    // Only handle password reset links: beaconnewbeginnings://reset-password#...
    final fragment = uri.fragment;
    final isReset = (uri.host == 'reset-password' || uri.path.contains('reset-password')) &&
        fragment.contains('type=recovery');
    if (!isReset) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ResetPasswordScreen(deepLinkUri: uri)),
      );
    });
  }

  void _init() async {
    final hasRegion = await AppConfigService.instance.load();
    if (mounted) setState(() => _regionSelected = hasRegion);

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

    if (_showFallback && !_isInitialized) {
      return const EnhancedLoginScreen();
    }

    if (!_regionSelected) {
      return RegionSelectScreen(
        onSelected: () => setState(() => _regionSelected = true),
      );
    }

    return StreamBuilder<AppUser?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !_isInitialized) {
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
