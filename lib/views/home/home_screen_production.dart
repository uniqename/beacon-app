import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service_minimal.dart';
import '../../services/location_service.dart';
import '../../services/anonymous_data_service.dart';
import '../../constants/app_constants.dart';
import '../auth/login_screen_minimal.dart';
import '../forms/anonymous_submission_form.dart';
import '../emergency/emergency_contacts_screen.dart';
import '../resources/resources_list_screen.dart';

class HomeScreenProduction extends StatefulWidget {
  const HomeScreenProduction({super.key});

  @override
  State<HomeScreenProduction> createState() => _HomeScreenProductionState();
}

class _HomeScreenProductionState extends State<HomeScreenProduction> {
  final AnonymousDataService _anonymousService = AnonymousDataService();
  int _pendingSubmissions = 0;
  bool _locationLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPendingSubmissions();
    _initializeLocation();
  }

  Future<void> _loadPendingSubmissions() async {
    final count = await _anonymousService.getSubmissionCount();
    setState(() {
      _pendingSubmissions = count;
    });
  }

  Future<void> _initializeLocation() async {
    setState(() => _locationLoading = true);
    final locationService = Provider.of<LocationService>(context, listen: false);
    await locationService.getCurrentLocation();
    setState(() => _locationLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beacon of New Beginnings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => _launchWebsite(),
            tooltip: 'Visit Website',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showSignOutDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(authService),
            
            const SizedBox(height: 32),
            
            // Emergency Banner
            _buildEmergencyBanner(),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            _buildQuickActions(),
            
            const SizedBox(height: 32),
            
            // Anonymous Support Section
            _buildAnonymousSupportSection(),
            
            const SizedBox(height: 32),
            
            // Resources Section
            _buildResourcesSection(),
            
            const SizedBox(height: 32),
            
            // Support Message
            _buildSupportMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(AuthService authService) {
    return FutureBuilder<bool>(
      future: authService.isAnonymousUser(),
      builder: (context, anonymousSnapshot) {
        final isAnonymous = anonymousSnapshot.data ?? false;
        final currentUser = authService.currentUser;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAnonymous || currentUser == null
                  ? 'Welcome to Beacon of New Beginnings'
                  : 'Welcome back, ${currentUser.name}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You are safe here. We are here to support you on your journey to healing and empowerment.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            _buildLocationDisplay(),
            if (_pendingSubmissions > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You have $_pendingSubmissions pending submission${_pendingSubmissions == 1 ? '' : 's'}. We will follow up with you soon.',
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEmergencyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.emergency, size: 32, color: Colors.red[700]),
          const SizedBox(height: 8),
          Text(
            'In Immediate Danger?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Call ${AppConstants.emergencyContacts['Police']} for Police or press the button below for emergency contacts.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red[600]),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _showEmergencyContacts(),
            icon: const Icon(Icons.phone),
            label: const Text('Emergency Contacts'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How can we help you today?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildActionCard(
              'Emergency Help',
              Icons.emergency,
              Colors.red[700]!,
              () => _showEmergencyContacts(),
            ),
            _buildActionCard(
              'Find Resources',
              Icons.library_books,
              Colors.blue[700]!,
              () => _showResources(),
            ),
            _buildActionCard(
              'Request Support',
              Icons.support_agent,
              Colors.green[700]!,
              () => _showAnonymousForm('help_request'),
            ),
            _buildActionCard(
              'Share Information',
              Icons.feedback,
              Colors.purple[700]!,
              () => _showAnonymousForm('general'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnonymousSupportSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.privacy_tip,
            size: 48,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Anonymous Support Available',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share your needs anonymously. We will follow up based on your preferences while keeping your privacy protected.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showAnonymousForm('help_request'),
            child: const Text('Submit Anonymous Request'),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Resources',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.resourceCategories.map((category) {
            return ActionChip(
              label: Text(category),
              onPressed: () => _showResourceCategory(category),
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _showResources(),
          icon: const Icon(Icons.search),
          label: const Text('Browse All Resources'),
        ),
      ],
    );
  }

  Widget _buildSupportMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.favorite,
            size: 48,
            color: Colors.green[700],
          ),
          const SizedBox(height: 16),
          Text(
            'You are not alone',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppConstants.appDescription,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _showEmergencyContacts() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EmergencyContactsScreen(),
      ),
    );
  }

  void _showResources() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ResourcesListScreen(),
      ),
    );
  }

  void _showResourceCategory(String category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ResourcesListScreen(category: category),
      ),
    );
  }

  void _showAnonymousForm(String type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AnonymousSubmissionForm(
          submissionType: type,
          onSubmitted: () {
            _loadPendingSubmissions();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Your submission has been received. We will follow up soon.'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _launchWebsite() async {
    final Uri url = Uri.parse(AppConstants.websiteUrl);
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open website')),
        );
      }
    }
  }

  Widget _buildLocationDisplay() {
    return Consumer<LocationService>(
      builder: (context, locationService, child) {
        if (_locationLoading) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Getting location...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Location',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      locationService.getLocationDisplayText(),
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (locationService.isInGhana || locationService.isInUSA)
                      Text(
                        'Emergency: ${locationService.getLocationBasedEmergencyNumber()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreenMinimal()),
                  (route) => false,
                );
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}