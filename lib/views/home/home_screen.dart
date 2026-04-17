import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/affirmation_service.dart';
import '../../models/user.dart';
import '../emergency/emergency_screen.dart';
import '../resources/resources_screen.dart';
import '../community/community_screen.dart';
import '../profile/profile_screen.dart';
import '../services/service_divisions_screen.dart';
import '../support/ai_chat_screen.dart';
import '../safety/safety_plan_dashboard.dart';
import '../evidence/evidence_timeline_screen.dart';
import '../wellness/mood_dashboard_screen.dart';
import '../financial/budget_dashboard_screen.dart';
import '../documents/document_vault_screen.dart';
import '../disguise/disguise_settings_screen.dart';
import '../helper/helper_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../donations/enhanced_donation_screen.dart';
import '../../models/beacon_division.dart';
import '../partners/partners_screen.dart';
import '../quiz/beacon_quiz_home_screen.dart';
import '../jobs/jobs_screen.dart';
import '../ai_agents/ai_agents_hub_screen.dart';
import '../quiz/kahoot_game_screen.dart';
import '../safety/safety_checkin_screen.dart';
import '../community/video_devotionals_screen.dart';
import '../community/events_screen.dart';
import '../volunteer/volunteer_shifts_screen.dart';
import '../community/peer_mentorship_screen.dart';
import '../wellness/progress_tracker_screen.dart';
import '../wellness/daily_selfcare_screen.dart';
import '../wellness/daily_journal_screen.dart';
import '../wellness/wellness_reports_screen.dart';
import 'my_support_plan_screen.dart';
import 'survivor_intake_screen.dart';
import '../../services/case_management_service.dart';

final _beaconGeneralDivision = BeaconDivision(
  id: 'general',
  name: 'Beacon of New Beginnings',
  shortName: 'Beacon',
  description: 'Supporting survivors with essential services',
  icon: '🧡',
  color: '#F0562D',
  services: const [],
  resources: const [],
  isAvailable: true,
  capacity: 100,
  contactEmail: 'support@beaconnewbeginnings.org',
  contactPhone: '+233302000000',
  donationUrl: '',
  jobOpenings: const [],
);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    final userType = currentUser?.userType ?? UserType.survivor;
    final approvalStatus = currentUser?.approvalStatus ?? 'approved';

    // Build screens based on user role
    List<Widget> screens;
    List<BottomNavigationBarItem> navItems;

    // Check if helper is approved - only show helper dashboard if approved
    final isApprovedHelper = (userType == UserType.counselor || userType == UserType.volunteer)
        && approvalStatus == 'approved';

    if (isApprovedHelper) {
      // Approved helper view: Dashboard, Resources, Community, Profile
      screens = [
        const HelperDashboardScreen(),
        const ResourcesScreen(),
        const CommunityScreen(),
        const ProfileScreen(),
      ];

      navItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.library_books_outlined),
          activeIcon: Icon(Icons.library_books),
          label: 'Resources',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Community',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    } else if (userType == UserType.admin) {
      // Admin view: Regular home + Admin tab
      screens = [
        const HomeTabScreen(),
        const ResourcesScreen(),
        const CommunityScreen(),
        AdminDashboardScreen(user: currentUser!),
        const ProfileScreen(),
      ];

      navItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.library_books_outlined),
          activeIcon: Icon(Icons.library_books),
          label: 'Resources',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Community',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings_outlined),
          activeIcon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    } else {
      // Survivor view: Default home screen
      screens = [
        const HomeTabScreen(),
        const ResourcesScreen(),
        const CommunityScreen(),
        const ProfileScreen(),
      ];

      navItems = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.library_books_outlined),
          activeIcon: Icon(Icons.library_books),
          label: 'Resources',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Community',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: navItems,
      ),
    );
  }
}

class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  _HomeTabScreenState createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  int _logoTapCount = 0;
  DateTime? _lastTap;

  void _handleLogoTap() {
    DateTime now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!).inSeconds > 2) {
      _logoTapCount = 0;
    }
    
    _logoTapCount++;
    _lastTap = now;
    
    if (_logoTapCount >= 7) {
      _logoTapCount = 0;
      _showAdminAccess();
    }
  }

  void _showAdminAccess() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.orange[600]),
            SizedBox(width: 12),
            Text('Admin Access'),
          ],
        ),
        content: Text('Access admin dashboard to manage divisions and services?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
            ),
            child: Text('Access Admin'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo header
              Center(
                child: GestureDetector(
                  onTap: _handleLogoTap,
                  child: Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset(
                        'assets/images/beacon_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFF0562D),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Icon(
                              Icons.home,
                              size: 30,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              
              // Header with greeting
              Consumer<AuthService>(
                builder: (context, authService, child) {
                  return FutureBuilder<bool>(
                    future: authService.isAnonymousUser(),
                    builder: (context, anonymousSnapshot) {
                      final isAnonymous = anonymousSnapshot.data ?? false;
                      final currentUser = authService.currentUser;
                      
                      if (isAnonymous || currentUser == null) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to Beacon of New Beginnings',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'You are safe here. How can we help you today?',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.login, size: 16),
                                    label: const Text('Sign In'),
                                    onPressed: () => Navigator.pushNamed(context, '/login'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFF0562D),
                                      side: const BorderSide(color: Color(0xFFF0562D)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.person_add, size: 16),
                                    label: const Text('Create Account'),
                                    onPressed: () => Navigator.pushNamed(context, '/register'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF0562D),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                      
                      // Registered user - fetch and display name
                      return FutureBuilder(
                        future: authService.getUserData(currentUser.id),
                        builder: (context, snapshot) {
                          final user = snapshot.data;
                          final displayName = user?.displayName ?? currentUser.displayName ?? 'Friend';
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, $displayName',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'You are safe here. How can we help you today?',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),
              
              const SizedBox(height: 24),

              // Emergency button - prominent placement
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red[400]!, Colors.red[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EmergencyScreen()),
                    );
                  },
                  child: Column(
                    children: [
                      const Icon(
                        Icons.emergency,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Emergency Help',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Get immediate assistance - Available 24/7',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── My Support Plan (shown only if case plan exists) ─────────
              Consumer<AuthService>(
                builder: (context, authService, _) {
                  final user = authService.currentUser;
                  if (user == null || user.userType != UserType.survivor) {
                    return const SizedBox.shrink();
                  }
                  return FutureBuilder(
                    future: CaseManagementService.getCasePlanOrAutoLink(
                      user.id,
                      phone: user.phoneNumber,
                      email: user.email,
                    ),
                    builder: (context, snapshot) {
                      // While loading, show nothing
                      if (!snapshot.hasData && !snapshot.hasError) {
                        return const SizedBox.shrink();
                      }
                      final plan = snapshot.data;

                      // No plan yet — prompt survivor to create one
                      if (plan == null) {
                        return Column(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SurvivorIntakeScreen(user: user),
                                ),
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFF0562D),
                                      Color(0xFFFF7043)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF0562D)
                                          .withValues(alpha: 0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.white.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.auto_awesome,
                                          color: Colors.white, size: 24),
                                    ),
                                    const SizedBox(width: 14),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Create Your Support Plan',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Colors.white),
                                          ),
                                          SizedBox(height: 3),
                                          Text(
                                            'Let our AI build a personalised plan for you — takes 2 minutes.',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white70),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios,
                                        color: Colors.white70, size: 16),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      }

                      // Plan exists — show the My Support Plan card
                      return Column(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    MySupportPlanScreen(userId: user.id),
                              ),
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: const Color(0xFFF0562D)
                                        .withValues(alpha: 0.3)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey[200]!,
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0562D)
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.folder_special,
                                        color: Color(0xFFF0562D), size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'My Support Plan',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15),
                                        ),
                                        Text(
                                          'Managed by ${plan.caseManagerName}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right,
                                      color: Color(0xFFF0562D)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  );
                },
              ),

              // ── Safety & Protection ──────────────────────────────────────
              _SectionHeader(title: 'Safety & Protection', icon: Icons.shield, color: Colors.teal),
              const SizedBox(height: 10),
              _HorizontalCardRow(cards: [
                _CardData(Icons.shield_outlined, 'Safety Plan', Colors.teal, () {
                  final uid = Provider.of<AuthService>(context, listen: false).currentUser?.id ?? 'anonymous';
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SafetyPlanDashboard(userId: uid)));
                }),
                _CardData(Icons.camera_alt_outlined, 'Evidence', Colors.orange, () {
                  final uid = Provider.of<AuthService>(context, listen: false).currentUser?.id ?? 'anonymous';
                  Navigator.push(context, MaterialPageRoute(builder: (_) => EvidenceTimelineScreen(userId: uid)));
                }),
                _CardData(Icons.alarm_on, 'Check-In', const Color(0xFF00D4AA), () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SafetyCheckInScreen()));
                }),
                _CardData(Icons.visibility_off_outlined, 'Disguise', Colors.grey, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => DisguiseSettingsScreen()));
                }),
                _CardData(Icons.chat_outlined, 'AI Support', Colors.purple, () {
                  final uid = Provider.of<AuthService>(context, listen: false).currentUser?.id ?? 'anonymous';
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AiChatScreen(userId: uid)));
                }),
                _CardData(Icons.auto_awesome, 'AI Agents', const Color(0xFF00D4AA), () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAgentsHubScreen()));
                }),
              ]),

              const SizedBox(height: 20),

              // ── Wellness & Healing ───────────────────────────────────────
              _SectionHeader(title: 'Wellness & Healing', icon: Icons.favorite, color: Colors.pink),
              const SizedBox(height: 10),
              _HorizontalCardRow(cards: [
                _CardData(Icons.healing_outlined, 'Mood Tracker', Colors.pink, () {
                  final uid = Provider.of<AuthService>(context, listen: false).currentUser?.id ?? 'anonymous';
                  Navigator.push(context, MaterialPageRoute(builder: (_) => MoodDashboardScreen(userId: uid)));
                }),
                _CardData(Icons.spa, 'Self-Care', Colors.teal, () {
                  final uid = Provider.of<AuthService>(context, listen: false).currentUser?.id ?? 'anonymous';
                  Navigator.push(context, MaterialPageRoute(builder: (_) => DailySelfCareScreen(userId: uid)));
                }),
                _CardData(Icons.auto_stories, 'Journal', Colors.indigo, () {
                  final uid = Provider.of<AuthService>(context, listen: false).currentUser?.id ?? 'anonymous';
                  Navigator.push(context, MaterialPageRoute(builder: (_) => DailyJournalScreen(userId: uid)));
                }),
                _CardData(Icons.bar_chart, 'Reports', Colors.deepPurple, () {
                  final uid = Provider.of<AuthService>(context, listen: false).currentUser?.id ?? 'anonymous';
                  Navigator.push(context, MaterialPageRoute(builder: (_) => WellnessReportsScreen(userId: uid)));
                }),
                _CardData(Icons.local_fire_department, 'Progress', const Color(0xFFF0562D), () {
                  final uid = Provider.of<AuthService>(context, listen: false).currentUser?.id ?? 'anonymous';
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ProgressTrackerScreen(userId: uid)));
                }),
              ]),

              const SizedBox(height: 20),

              // ── Resources & Finance ──────────────────────────────────────
              _SectionHeader(title: 'Resources & Finance', icon: Icons.library_books, color: Colors.blue),
              const SizedBox(height: 10),
              _HorizontalCardRow(cards: [
                _CardData(Icons.account_balance_wallet_outlined, 'Finances', Colors.green, () {
                  final uid = Provider.of<AuthService>(context, listen: false).currentUser?.id ?? 'anonymous';
                  Navigator.push(context, MaterialPageRoute(builder: (_) => BudgetDashboardScreen(userId: uid)));
                }),
                _CardData(Icons.folder_outlined, 'Documents', Colors.blue, () {
                  final uid = Provider.of<AuthService>(context, listen: false).currentUser?.id ?? 'anonymous';
                  Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentVaultScreen(userId: uid)));
                }),
                _CardData(Icons.library_books_outlined, 'Resources', Colors.indigo, () {
                  Navigator.pushNamed(context, '/content_library');
                }),
                _CardData(Icons.work_outline, 'Jobs', Colors.cyan, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const JobsScreen()));
                }),
                _CardData(Icons.favorite, 'Donate', const Color(0xFFF0562D), () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => EnhancedDonationScreen(division: _beaconGeneralDivision)));
                }),
              ]),

              const SizedBox(height: 20),

              // ── Services & Support ───────────────────────────────────────
              _SectionHeader(title: 'Services & Support', icon: Icons.local_hospital, color: Colors.purple),
              const SizedBox(height: 10),
              _HorizontalCardRow(cards: [
                _CardData(Icons.home_outlined, 'Shelter', Colors.blue, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDivisionsScreen(initialFilter: 'shelter')));
                }),
                _CardData(Icons.psychology_outlined, 'Counseling', Colors.purple, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDivisionsScreen(initialFilter: 'counseling')));
                }),
                _CardData(Icons.gavel_outlined, 'Legal Aid', Colors.indigo, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDivisionsScreen(initialFilter: 'legal')));
                }),
                _CardData(Icons.local_hospital_outlined, 'Medical', Colors.green, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDivisionsScreen(initialFilter: 'healthcare')));
                }),
                _CardData(Icons.handshake_outlined, 'Partners', Colors.orange, () {
                  final auth = Provider.of<AuthService>(context, listen: false);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PartnersScreen(isAdmin: auth.currentUser?.userType == UserType.admin)));
                }),
                _CardData(Icons.people_outline, 'Peer Mentors', const Color(0xFFE91E8C), () {
                  final uid = Provider.of<AuthService>(context, listen: false).currentUser?.id ?? 'anonymous';
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PeerMentorshipScreen(userId: uid)));
                }),
              ]),

              const SizedBox(height: 20),

              // ── Community & Faith ────────────────────────────────────────
              _SectionHeader(title: 'Community & Faith', icon: Icons.people, color: Colors.deepOrange),
              const SizedBox(height: 10),
              _HorizontalCardRow(cards: [
                _CardData(Icons.play_circle_outline, 'Devotionals', const Color(0xFF9B59B6), () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const VideoListScreen()));
                }),
                _CardData(Icons.event, 'Events', const Color(0xFF3B82F6), () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen()));
                }),
                _CardData(Icons.schedule, 'Volunteer', const Color(0xFFFFB347), () {
                  final uid = Provider.of<AuthService>(context, listen: false).currentUser?.id ?? 'anonymous';
                  Navigator.push(context, MaterialPageRoute(builder: (_) => VolunteerShiftsScreen(userId: uid)));
                }),
                _CardData(Icons.quiz_outlined, 'Quiz', Colors.deepPurple, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BeaconQuizHomeScreen()));
                }),
                _CardData(Icons.flash_on_rounded, 'Group Quiz', const Color(0xFFE21B3C), () {
                  final name = Provider.of<AuthService>(context, listen: false).currentUser?.displayName ?? 'Player 1';
                  Navigator.push(context, MaterialPageRoute(builder: (_) => KahootLobbyScreen(hostName: name)));
                }),
              ]),

              const SizedBox(height: 24),

              // ── Support Beacon ───────────────────────────────────────────
              InkWell(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => EnhancedDonationScreen(division: _beaconGeneralDivision))),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF0562D), Color(0xFFE84393)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF0562D).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Support Beacon\'s Mission',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Your donation helps survivors rebuild their lives',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white70),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Daily Bible Verse
              Text(
                'Daily Bible Verse',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Builder(
                builder: (context) {
                  final dailyVerse = AffirmationService.getDailyVerse();
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal[50]!, Colors.teal[100]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.menu_book,
                          color: Theme.of(context).primaryColor,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '"${dailyVerse['text']}"',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '- ${dailyVerse['reference']}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section header widget ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

// ─── Card data model ──────────────────────────────────────────────────────────

class _CardData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CardData(this.icon, this.label, this.color, this.onTap);
}

// ─── Horizontal scrolling card row ───────────────────────────────────────────

class _HorizontalCardRow extends StatelessWidget {
  final List<_CardData> cards;

  const _HorizontalCardRow({required this.cards});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final card = cards[i];
          return GestureDetector(
            onTap: card.onTap,
            child: Container(
              width: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: card.color.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: card.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(card.icon, color: card.color, size: 20),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    card.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}