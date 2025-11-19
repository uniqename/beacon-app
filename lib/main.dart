import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'constants/app_branding.dart';
import 'views/auth/enhanced_login_screen.dart';
import 'views/services/service_divisions_screen.dart';
import 'views/home/home_screen.dart';
import 'views/emergency/emergency_screen.dart';
import 'views/auth/register_screen.dart';
import 'views/auth_wrapper.dart';
import 'views/admin/admin_dashboard_screen.dart';
import 'models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure system UI for edge-to-edge support on Android 15
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  runApp(const NGOSupportApp());
}

class NGOSupportApp extends StatelessWidget {
  const NGOSupportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<LocationService>(
          create: (_) => LocationService(),
        ),
      ],
      child: MaterialApp(
        title: AppBranding.appName,
        debugShowCheckedModeBanner: false,
        theme: AppBranding.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const EnhancedLoginScreen(), // Direct login screen to avoid loading issues
          '/auth': (context) => AuthWrapper(),
          '/login': (context) => EnhancedLoginScreen(),
          '/register': (context) => RegisterScreen(),
          '/home': (context) => HomeScreen(),
          '/services': (context) => ServiceDivisionsScreen(),
          '/emergency': (context) => EmergencyScreen(),
          '/admin': (context) => AdminDashboardScreen(user: AppUser.anonymous().copyWith(userType: UserType.admin)),
        },
      ),
    );
  }
}
