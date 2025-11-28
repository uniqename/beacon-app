import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'services/accessibility_service.dart';
import 'constants/app_branding.dart';
import 'constants/app_constants.dart';
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

  // Initialize accessibility service
  final accessibilityService = AccessibilityService();
  await accessibilityService.initialize();

  runApp(NGOSupportApp(accessibilityService: accessibilityService));
}

class NGOSupportApp extends StatelessWidget {
  final AccessibilityService accessibilityService;

  const NGOSupportApp({
    super.key,
    required this.accessibilityService,
  });

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
        ChangeNotifierProvider<AccessibilityService>.value(
          value: accessibilityService,
        ),
      ],
      child: Consumer<AccessibilityService>(
        builder: (context, accessibility, _) {
          return MaterialApp(
            title: AppBranding.appName,
            debugShowCheckedModeBanner: false,
            theme: accessibility.getAccessibleTheme(
              ThemeData(
                primaryColor: const Color(AppConstants.primaryColorValue),
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(AppConstants.primaryColorValue),
                  secondary: const Color(AppConstants.accentColorValue),
                ),
                scaffoldBackgroundColor: const Color(AppConstants.warmOffWhiteValue),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(AppConstants.primaryColorValue),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                useMaterial3: true,
              ),
            ),
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
          );
        },
      ),
    );
  }
}
