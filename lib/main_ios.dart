import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/demo_auth_service.dart';
import 'views/home/home_screen.dart';
import 'views/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('Starting Beacon of New Beginnings in iOS Demo Mode');
  
  runApp(const NGOSupportApp());
}

class NGOSupportApp extends StatelessWidget {
  const NGOSupportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DemoAuthService()),
      ],
      child: MaterialApp(
        title: 'Beacon of New Beginnings',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          primaryColor: Colors.teal[600],
          visualDensity: VisualDensity.adaptivePlatformDensity,
          cardTheme: const CardThemeData(
            elevation: 4,
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.teal[600],
            foregroundColor: Colors.white,
            elevation: 2,
          ),
        ),
        home: const AuthWrapperIOS(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapperIOS extends StatelessWidget {
  const AuthWrapperIOS({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DemoAuthService>(
      builder: (context, authService, child) {
        if (authService.isAuthenticated) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}