import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'services/accessibility_service.dart';
import 'services/chat_service.dart';
import 'constants/app_constants.dart';
import 'services/app_config_service.dart';
import 'views/auth/enhanced_login_screen.dart';
import 'views/services/service_divisions_screen.dart';
import 'views/home/home_screen.dart';
import 'views/emergency/emergency_screen.dart';
import 'views/auth/register_screen.dart';
import 'views/auth/admin_login_screen.dart';
import 'views/auth/admin_register_screen.dart';
import 'views/auth_wrapper.dart';
import 'views/admin/admin_dashboard_screen.dart';
import 'models/user.dart';

// Safety Planning
import 'views/safety/safety_plan_dashboard.dart';
import 'views/safety/emergency_contacts_screen.dart';
import 'views/safety/safe_places_screen.dart';
import 'views/safety/escape_plan_screen.dart';
import 'views/safety/essential_items_screen.dart';
import 'views/safety/code_words_screen.dart';
import 'views/safety/children_safety_screen.dart';
import 'views/safety/pet_safety_screen.dart';
import 'views/safety/financial_safety_screen.dart';
import 'views/safety/digital_safety_screen.dart';

// Evidence Documentation
import 'views/evidence/evidence_timeline_screen.dart';
import 'views/evidence/create_evidence_screen.dart';
import 'views/evidence/medical_records_screen.dart';
import 'views/evidence/message_evidence_screen.dart';

// Disguise Mode
import 'views/disguise/disguise_login_screen.dart';
import 'views/disguise/fake_calculator_screen.dart';
import 'views/disguise/disguise_settings_screen.dart';
import 'views/disguise/offline_content_screen.dart';

// Wellness
import 'views/wellness/mood_dashboard_screen.dart';
import 'views/wellness/mood_checkin_screen.dart';
import 'views/wellness/daily_checkin_screen.dart';
import 'views/wellness/mood_trends_screen.dart';

// Support
import 'views/support/ai_chat_screen.dart';
import 'views/support/content_library_screen.dart';

// Financial
import 'views/financial/budget_dashboard_screen.dart';
import 'views/financial/add_transaction_screen.dart';
import 'views/financial/budget_reports_screen.dart';
import 'views/financial/hidden_savings_screen.dart';

// Documents
import 'views/documents/document_vault_screen.dart';
import 'views/documents/upload_document_screen.dart';
import 'views/documents/document_checklist_screen.dart';

// New features
import 'services/notification_service.dart';
import 'services/supabase_sync_service.dart';
import 'views/safety/safety_checkin_screen.dart';
import 'views/community/video_devotionals_screen.dart';
import 'views/community/events_screen.dart';
import 'views/volunteer/volunteer_shifts_screen.dart';
import 'views/community/peer_mentorship_screen.dart';
import 'views/admin/case_management_screen.dart';
import 'views/admin/client_intake_screen.dart';
import 'views/home/my_support_plan_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Stripe (non-fatal — payment screens handle failures gracefully)
  try {
    final stripeKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
    if (stripeKey.isNotEmpty) {
      Stripe.publishableKey = stripeKey;
      Stripe.merchantIdentifier = 'merchant.com.beaconnewbeginnings.ngo-support-app';
      await Stripe.instance.applySettings();
    }
  } catch (e) {
    debugPrint('Stripe init skipped: $e');
  }

  // Configure system UI for edge-to-edge support on Android 15
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize accessibility service
  final accessibilityService = AccessibilityService();
  try {
    await accessibilityService.initialize();
  } catch (e) {
    debugPrint('AccessibilityService init skipped: $e');
  }

  // Initialize chat service
  ChatService().initialize();

  // Initialize Supabase sync service (Supabase-first, SQLite fallback)
  try {
    await SupabaseSyncService().initialize();
  } catch (e) {
    debugPrint('SupabaseSyncService init skipped: $e');
  }

  // Initialize notification service (local + FCM — safe, won't crash if Firebase unconfigured)
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('NotificationService init skipped: $e');
  }

  // NOTE: Agora AudioRoomService is initialized lazily when the user enters
  // a room — NOT here. Pre-initializing at startup triggers microphone
  // permission before the user has context, and if denied iOS won't ask again.

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
        ChangeNotifierProvider<AppConfigService>.value(
          value: AppConfigService.instance,
        ),
      ],
      child: Consumer2<AccessibilityService, AppConfigService>(
        builder: (context, accessibility, appConfig, _) {
          return MaterialApp(
            title: appConfig.config.orgName,
            debugShowCheckedModeBanner: false,
            builder: (context, child) => child ?? const SizedBox(),
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
            darkTheme: accessibility.getAccessibleTheme(
              ThemeData(
                brightness: Brightness.dark,
                primaryColor: const Color(AppConstants.primaryColorValue),
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(AppConstants.primaryColorValue),
                  secondary: const Color(AppConstants.accentColorValue),
                  brightness: Brightness.dark,
                  // Brand charcoal #221E1F as dark surface
                  surface: const Color(AppConstants.darkCharcoalValue),
                  onSurface: Colors.white,
                ),
                // Near-black slightly warm bg — deeper than brand charcoal
                scaffoldBackgroundColor: const Color(0xFF120F10),
                appBarTheme: const AppBarTheme(
                  // Brand orange AppBar — consistent brand identity
                  backgroundColor: Color(AppConstants.primaryColorValue),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                cardTheme: const CardThemeData(
                  color: Color(AppConstants.darkCharcoalValue),
                  elevation: 0,
                ),
                dialogTheme: const DialogThemeData(
                  backgroundColor: Color(AppConstants.darkCharcoalValue),
                ),
                bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                  backgroundColor: Color(0xFF1A1617),
                  selectedItemColor: Color(AppConstants.primaryColorValue),
                  unselectedItemColor: Colors.white54,
                ),
                drawerTheme: const DrawerThemeData(
                  backgroundColor: Color(0xFF1A1617),
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: const Color(0xFF2D2829),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF3D393A)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF3D393A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(AppConstants.primaryColorValue)),
                  ),
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintStyle: const TextStyle(color: Colors.white38),
                ),
                dividerTheme: const DividerThemeData(
                  color: Color(0xFF3D393A),
                ),
                listTileTheme: const ListTileThemeData(
                  tileColor: Color(AppConstants.darkCharcoalValue),
                  iconColor: Colors.white70,
                  textColor: Colors.white,
                ),
                chipTheme: ChipThemeData(
                  backgroundColor: const Color(0xFF2D2829),
                  labelStyle: const TextStyle(color: Colors.white),
                  side: const BorderSide(color: Color(0xFF3D393A)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(AppConstants.primaryColorValue),
                    foregroundColor: Colors.white,
                  ),
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(AppConstants.primaryColorValue),
                  ),
                ),
                switchTheme: SwitchThemeData(
                  thumbColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected)
                      ? const Color(AppConstants.primaryColorValue)
                      : Colors.white54),
                  trackColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected)
                      ? const Color(AppConstants.primaryColorValue).withValues(alpha: 0.4)
                      : Colors.white24),
                ),
                useMaterial3: true,
              ),
            ),
            themeMode: ThemeMode.light,
            initialRoute: '/',
            routes: {
              '/': (context) => const AuthWrapper(),
              '/auth': (context) => const AuthWrapper(),
              '/login': (context) => const EnhancedLoginScreen(),
              '/register': (context) => RegisterScreen(),
              '/admin_login': (context) => AdminLoginScreen(),
              '/admin_register': (context) => AdminRegisterScreen(),
              '/home': (context) => HomeScreen(),
              '/services': (context) => ServiceDivisionsScreen(),
              '/emergency': (context) => EmergencyScreen(),
              '/admin': (context) => AdminDashboardScreen(user: AppUser.anonymous().copyWith(userType: UserType.admin)),

              // Case Management Routes
              '/case_management': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                return CaseManagementScreen(user: authService.currentUser ?? AppUser.anonymous().copyWith(userType: UserType.admin));
              },
              '/client_intake': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                return ClientIntakeScreen(user: authService.currentUser ?? AppUser.anonymous().copyWith(userType: UserType.admin));
              },
              '/my_support_plan': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? '';
                return MySupportPlanScreen(userId: userId);
              },

              // Safety Planning Routes
              '/safety_plan': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? 'anonymous';
                return SafetyPlanDashboard(userId: userId);
              },
              '/emergency_contacts': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? 'anonymous';
                return EmergencyContactsScreen(userId: userId);
              },
              '/safe_places': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? 'anonymous';
                return SafePlacesScreen(userId: userId);
              },
              '/escape_plan': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? 'anonymous';
                return EscapePlanScreen(userId: userId);
              },
              '/essential_items': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? 'anonymous';
                return EssentialItemsScreen(userId: userId);
              },
              '/code_words': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? 'anonymous';
                return CodeWordsScreen(userId: userId);
              },
              '/children_safety': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? 'anonymous';
                return ChildrenSafetyScreen(userId: userId);
              },
              '/pet_safety': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? 'anonymous';
                return PetSafetyScreen(userId: userId);
              },
              '/financial_safety': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? 'anonymous';
                return FinancialSafetyScreen(userId: userId);
              },
              '/digital_safety': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? 'anonymous';
                return DigitalSafetyScreen(userId: userId);
              },

              // Evidence Documentation Routes
              '/evidence_timeline': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? 'anonymous';
                return EvidenceTimelineScreen(userId: userId);
              },
              '/create_evidence': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? 'anonymous';
                return CreateEvidenceScreen(userId: userId);
              },
              '/medical_records': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? 'anonymous';
                return MedicalRecordsScreen(userId: userId);
              },
              '/message_evidence': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? 'anonymous';
                return MessageEvidenceScreen(userId: userId);
              },

              // Disguise Mode Routes
              '/disguise_login': (context) => DisguiseLoginScreen(),
              '/fake_calculator': (context) => FakeCalculatorScreen(),
              '/disguise_settings': (context) => DisguiseSettingsScreen(),
              '/offline_content': (context) => OfflineContentScreen(),

              // Wellness Routes
              '/mood_dashboard': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? 'anonymous';
                return MoodDashboardScreen(userId: userId);
              },
              '/mood_checkin': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? 'anonymous';
                return MoodCheckinScreen(userId: userId);
              },
              '/daily_checkin': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? 'anonymous';
                return DailyCheckinScreen(userId: userId);
              },
              '/mood_trends': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? 'anonymous';
                return MoodTrendsScreen(userId: userId);
              },

              // Support Routes
              '/chat_list': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? 'anonymous';
                return AiChatScreen(userId: userId);
              },
              '/ai_chat': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? 'anonymous';
                return AiChatScreen(userId: userId);
              },
              '/content_library': (context) => ContentLibraryScreen(),

              // Financial Routes
              '/budget_dashboard': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? 'anonymous';
                return BudgetDashboardScreen(userId: userId);
              },
              '/add_transaction': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? 'anonymous';
                return AddTransactionScreen(userId: userId);
              },
              '/budget_reports': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? 'anonymous';
                return BudgetReportsScreen(userId: userId);
              },
              '/hidden_savings': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? 'anonymous';
                return HiddenSavingsScreen(userId: userId);
              },

              // Safety Check-In
              '/safety_checkin': (context) => const SafetyCheckInScreen(),

              // Community / Engagement
              '/video_devotionals': (context) => const VideoListScreen(),
              '/events': (context) => const EventsScreen(),
              '/volunteer_shifts': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? 'anonymous';
                return VolunteerShiftsScreen(userId: userId);
              },
              '/peer_mentorship': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? 'anonymous';
                return PeerMentorshipScreen(userId: userId);
              },

              // Document Vault Routes
              '/document_vault': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? 'anonymous';
                return DocumentVaultScreen(userId: userId);
              },
              '/upload_document': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? 'anonymous';
                return UploadDocumentScreen(userId: userId);
              },
              '/document_checklist': (context) {
                final authService = Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.id ?? 'anonymous';
                return DocumentChecklistScreen(userId: userId);
              },
            },
          );
        },
      ),
    );
  }
}
