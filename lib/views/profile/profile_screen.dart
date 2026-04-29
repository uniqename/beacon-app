import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/org_config.dart';
import '../../services/app_config_service.dart';
import '../../services/auth_service.dart';
import '../../services/account_deletion_service.dart';
import 'feedback_screen.dart';
import 'help_screen.dart';
import 'notification_settings_screen.dart';
import 'accessibility_settings_screen.dart';
import 'about_app_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About App',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AboutAppScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              // Show confirmation dialog
              final shouldSignOut = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
              
              if (shouldSignOut == true && context.mounted) {
                await authService.signOut();
                // Navigate back to login
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
        ],
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          return FutureBuilder<bool>(
            future: authService.isAnonymousUser(),
            builder: (context, anonymousSnapshot) {
              final isAnonymous = anonymousSnapshot.data ?? false;
              final currentUser = authService.currentUser;
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Profile Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal[400]!, Colors.teal[600]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: Icon(
                              isAnonymous ? Icons.shield : Icons.person,
                              size: 50,
                              color: Colors.teal[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isAnonymous 
                              ? 'Anonymous User' 
                              : currentUser?.displayName ?? 'User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isAnonymous 
                              ? 'Your privacy is protected' 
                              : currentUser?.email ?? 'No email',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),

                    // Sign in banner for anonymous users
                    if (isAnonymous) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF0562D), Color(0xFFFF7043)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Have an account?',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Sign in to access your saved data and full features.',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      await authService.signOut();
                                      if (context.mounted) {
                                        Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
                                      }
                                    },
                                    icon: const Icon(Icons.login, size: 16),
                                    label: const Text('Sign In'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFFF0562D),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      await authService.signOut();
                                      if (context.mounted) {
                                        Navigator.of(context).pushNamedAndRemoveUntil('/register', (r) => false);
                                      }
                                    },
                                    icon: const Icon(Icons.person_add, size: 16),
                                    label: const Text('Create Account'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(color: Colors.white70),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Settings Section
                    _buildSettingsSection(context, isAnonymous, authService),
                    
                    const SizedBox(height: 24),
                    
                    // Safety Section
                    _buildSafetySection(context),
                    
                    const SizedBox(height: 24),
                    
                    // Support Section
                    _buildSupportSection(context),
                    
                    const SizedBox(height: 32),
                    
                    // App Info
                    _buildAppInfo(context),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  Widget _buildSettingsSection(BuildContext context, bool isAnonymous, [AuthService? authService]) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (!isAnonymous) ...[
              _buildSettingsItem(
                context,
                icon: Icons.person_outline,
                title: 'Edit Profile',
                subtitle: 'Update your display name',
                onTap: () => _showEditProfileDialog(context, authService),
              ),
              const Divider(),
            ],
            _buildSettingsItem(
              context,
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Manage notification preferences',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationSettingsScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            _buildSettingsItem(
              context,
              icon: Icons.accessibility_new,
              title: 'Accessibility',
              subtitle: 'Font size & display settings',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccessibilitySettingsScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            Builder(builder: (ctx) {
              final appConfig = Provider.of<AppConfigService>(ctx);
              final cfg = appConfig.config;
              final flag = cfg.orgKey == 'gh' ? '🇬🇭' : '🇺🇸';
              return _buildSettingsItem(
                ctx,
                icon: Icons.public,
                title: 'Region',
                subtitle: '$flag ${cfg.orgName}',
                onTap: () => _showRegionDialog(ctx, appConfig),
              );
            }),
            const Divider(),
            _buildSettingsItem(
              context,
              icon: Icons.security,
              title: 'Privacy & Security',
              subtitle: 'Control your privacy settings',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Row(
                      children: [
                        Icon(Icons.security, color: Colors.teal[600]),
                        SizedBox(width: 12),
                        Text('Privacy & Security'),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your privacy settings:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 12),
                        Text('✓ Anonymous browsing enabled'),
                        Text('✓ Data encryption active'),
                        Text('✓ Location data not stored'),
                        Text('✓ No data sharing with third parties'),
                        SizedBox(height: 12),
                        Text('For additional privacy controls, please contact our support team.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(),
            if (authService != null)
              ListTile(
                leading: Icon(Icons.delete_forever, color: Colors.red),
                title: Text(
                  isAnonymous ? 'Delete All Data' : 'Delete Account',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                ),
                subtitle: Text('Permanently delete your account and all data'),
                trailing: Icon(Icons.chevron_right, color: Colors.red),
                onTap: () => _showDeleteAccountDialog(context, authService, isAnonymous),
              ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthService? authService) {
    if (authService == null) return;
    final controller = TextEditingController(
      text: authService.currentUser?.displayName ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Display name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              final user = authService.currentUser;
              if (user != null) {
                await authService.updateUserData(user.copyWith(displayName: name));
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Display name updated'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AuthService authService, bool isAnonymous) async {
    final userId = authService.currentUser?.id;
    if (userId == null) return;

    // Step 1: Show what will be deleted
    final dataCounts = await AccountDeletionService().getUserDataCounts(userId);
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text(isAnonymous ? 'Delete All Data?' : 'Delete Account?'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will PERMANENTLY delete:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 16),
              if (dataCounts['evidence']! > 0)
                Text('• ${dataCounts['evidence']} evidence records'),
              if (dataCounts['documents']! > 0)
                Text('• ${dataCounts['documents']} secure documents'),
              if (dataCounts['safety_plans']! > 0)
                Text('• ${dataCounts['safety_plans']} safety plans'),
              if (dataCounts['mood_entries']! > 0)
                Text('• ${dataCounts['mood_entries']} mood entries'),
              if (dataCounts['budget_entries']! > 0)
                Text('• ${dataCounts['budget_entries']} budget entries'),
              Text('• All photos and audio recordings'),
              Text('• All personal information'),
              if (!isAnonymous)
                Text('• Your account login credentials'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: Text(
                  '⚠️ This action CANNOT be undone. All data will be permanently deleted.',
                  style: TextStyle(
                    color: Colors.red[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Continue'),
          ),
        ],
      ),
    );

    if (shouldContinue != true || !context.mounted) return;

    // Step 2: Require typing DELETE to confirm
    final textController = TextEditingController();
    final confirmedText = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Deletion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type DELETE in capital letters to confirm:'),
            SizedBox(height: 16),
            TextField(
              controller: textController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Type DELETE',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text == 'DELETE') {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('You must type DELETE exactly'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmedText != true || !context.mounted) return;

    // Step 3: For registered users, require password
    if (!isAnonymous) {
      final passwordController = TextEditingController();
      final passwordConfirmed = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Enter Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter your password to confirm account deletion:'),
              SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, passwordController.text),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete Account'),
            ),
          ],
        ),
      );

      if (passwordConfirmed == null || passwordConfirmed.isEmpty || !context.mounted) return;

      // Verify password before deletion
      final passwordValid = await authService.verifyPassword(passwordConfirmed);
      if (!passwordValid && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Incorrect password. Account deletion cancelled.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Perform deletion
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Deleting account...'),
              ],
            ),
          ),
        ),
      ),
    );

    final success = await AccountDeletionService().deleteUserAccount(
      userId,
      isAnonymous: isAnonymous,
    );

    if (!context.mounted) return;
    Navigator.pop(context); // Close loading dialog

    if (success) {
      await authService.signOut();
      if (context.mounted) {
        // Show success message and navigate to welcome screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Widget _buildSafetySection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Safety Features',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsItem(
              context,
              icon: Icons.emergency,
              title: 'Emergency Contacts',
              subtitle: 'Quick access to emergency services',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Emergency contacts: 191 (Police), 193 (Ambulance)')),
                );
              },
            ),
            const Divider(),
            _buildSettingsItem(
              context,
              icon: Icons.exit_to_app,
              title: 'Quick Exit',
              subtitle: 'Quickly close the app in emergencies',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Quick Exit'),
                    content: const Text('This feature allows you to quickly close the app. Press the volume down button 3 times to activate.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSupportSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Support',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsItem(
              context,
              icon: Icons.help_outline,
              title: 'Help & FAQ',
              subtitle: 'Get answers to common questions',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HelpScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            _buildSettingsItem(
              context,
              icon: Icons.feedback_outlined,
              title: 'Send Feedback',
              subtitle: 'Help us improve the app',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FeedbackScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            _buildSettingsItem(
              context,
              icon: Icons.phone,
              title: 'Contact Support',
              subtitle: 'Reach out to our support team',
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Contact Support'),
                    content: const Text('For support, please contact:\n\nEmail: support@beaconnewbeginnings.org\nPhone: Available 24/7 through the app'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAppInfo(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Beacon of New Beginnings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Providing safety, healing, and empowerment to survivors of abuse and homelessness',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).primaryColor,
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showRegionDialog(BuildContext context, AppConfigService appConfig) {
    String selected = appConfig.config.orgKey;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Select Region'),
          content: RadioGroup<String>(
            groupValue: selected,
            onChanged: (val) {
              if (val != null) setDialogState(() => selected = val);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: allConfigs.entries.map((entry) {
                final cfg = entry.value;
                final flag = cfg.orgKey == 'gh' ? '🇬🇭' : '🇺🇸';
                return RadioListTile<String>(
                  value: cfg.orgKey,
                  title: Text('$flag ${cfg.orgName}'),
                  subtitle: Text(cfg.countryName),
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await appConfig.setConfig(selected);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}