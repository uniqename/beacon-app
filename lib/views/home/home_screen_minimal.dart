import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service_minimal.dart';
import '../auth/login_screen_minimal.dart';

class HomeScreenMinimal extends StatefulWidget {
  const HomeScreenMinimal({super.key});

  @override
  State<HomeScreenMinimal> createState() => _HomeScreenMinimalState();
}

class _HomeScreenMinimalState extends State<HomeScreenMinimal> {

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beacon of New Beginnings'),
        actions: [
          // Quick Exit Button (Security Feature)
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            tooltip: 'Quick Exit (Triple-tap)',
            onPressed: () => _handleQuickExit(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreenMinimal()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            FutureBuilder<bool>(
              future: authService.isAnonymousUser(),
              builder: (context, anonymousSnapshot) {
                final isAnonymous = anonymousSnapshot.data ?? false;
                final currentUser = authService.currentUser;
                
                if (isAnonymous || currentUser == null) {
                  // Anonymous user - show supportive message
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You are safe here. Take your time and access the support you need.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  );
                } else {
                  // Registered user
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${currentUser.name}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'How can we support you today?',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            
            const SizedBox(height: 32),
            
            // Quick Action Cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildActionCard(
                  context,
                  'Emergency Help',
                  Icons.emergency,
                  Colors.red,
                  () => _showEmergencyDialog(context),
                  isEmergency: true,
                ),
                _buildActionCard(
                  context,
                  'Find Resources',
                  Icons.search,
                  Colors.blue,
                  () => _showResourcesDialog(context),
                ),
                _buildActionCard(
                  context,
                  'Safe Space',
                  Icons.shield,
                  Colors.green,
                  () => _showSafeSpaceDialog(context),
                ),
                _buildActionCard(
                  context,
                  'More Options',
                  Icons.more_horiz,
                  Colors.grey,
                  () => _showMoreOptionsDialog(context),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Support Message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.favorite,
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You are not alone',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Our community is here to support you on your journey to healing and empowerment.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Anonymous Mode Indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 16, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Anonymous Mode - Your privacy is protected',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap, {bool isEmergency = false}) {
    return Card(
      elevation: isEmergency ? 8 : 4,
      color: isEmergency ? Colors.red.withOpacity(0.1) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: isEmergency ? BoxDecoration(
            border: Border.all(color: Colors.red.withOpacity(0.3), width: 2),
            borderRadius: BorderRadius.circular(12),
          ) : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isEmergency ? Colors.red[800] : null,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Quick Exit Functionality
  int _exitTapCount = 0;
  
  void _handleQuickExit(BuildContext context) {
    _exitTapCount++;
    
    if (_exitTapCount >= 3) {
      // Triple tap - exit immediately
      Navigator.of(context).pop();
      return;
    }
    
    // Show quick exit dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Exit'),
        content: Text('Tap this button ${3 - _exitTapCount} more times to exit immediately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Exit Now'),
          ),
        ],
      ),
    );
    
    // Reset counter after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _exitTapCount = 0;
    });
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency Support'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🚨 Ghana Emergency Services:'),
            Text('Police: 191'),
            Text('Fire: 192'),
            Text('Ambulance: 193'),
            Text(''),
            Text('🆘 Crisis Support:'),
            Text('Domestic Violence: 0800-800-800'),
            Text('Crisis Line: +233 50 123 4567'),
            Text(''),
            Text('You are not alone. Help is available 24/7.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showResourcesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resources'),
        content: const Text('Access shelter information, counseling services, legal aid, and livelihood programs. This demo shows the app structure.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSafeSpaceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shield, color: Colors.green),
            SizedBox(width: 8),
            Text('Safe Space'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🛡️ Community Support:'),
            Text('• Peer support groups'),
            Text('• Success stories'),
            Text('• Anonymous sharing'),
            Text('• Moderated environment'),
            Text(''),
            Text('💬 Chat Support:'),
            Text('• WhatsApp groups'),
            Text('• Professional counselors'),
            Text('• Crisis intervention'),
            Text(''),
            Text('This is your safe space to heal and grow.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMoreOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.more_horiz, color: Colors.grey),
            SizedBox(width: 8),
            Text('More Options'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('⚙️ Settings:'),
            Text('• Privacy settings'),
            Text('• Emergency contacts'),
            Text('• App preferences'),
            Text(''),
            Text('📱 Account:'),
            Text('• Profile management'),
            Text('• Data export'),
            Text('• Delete account'),
            Text(''),
            Text('ℹ️ About:'),
            Text('• App information'),
            Text('• Support contacts'),
            Text('• Feedback'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}