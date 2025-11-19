import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service_minimal.dart';
import '../models/user_minimal.dart';
import 'auth/login_screen_minimal.dart';
import 'home/home_screen_production.dart';

class AuthWrapperMinimal extends StatelessWidget {
  const AuthWrapperMinimal({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return StreamBuilder<AppUser?>(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasData) {
              return const HomeScreenProduction();
            } else {
              return const LoginScreenMinimal();
            }
          },
        );
      },
    );
  }
}