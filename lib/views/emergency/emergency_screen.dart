import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/emergency_service.dart';
import 'emergency_locations_screen.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  Position? _currentPosition;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _makeEmergencyCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _sendEmergencyAlert() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available. Please enable location services.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    
    if (currentUser != null) {
      final emergencyService = EmergencyService();
      final success = await emergencyService.sendEmergencyAlert(
        userId: currentUser.id,
        location: _currentPosition!,
        message: 'Emergency alert triggered from Beacon of New Beginnings app',
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency alert sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      appBar: AppBar(
        title: const Text('Emergency Support'),
        backgroundColor: Colors.red[600],
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: _isLoadingLocation ? null : _getCurrentLocation,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Emergency alert card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red[800],
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You Are Not Alone',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'If you are in immediate danger, use the options below to get help quickly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Emergency actions
              Text(
                'Immediate Help',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Call emergency services
              _EmergencyActionCard(
                icon: Icons.phone,
                title: 'Call Emergency Services',
                subtitle: 'Police, Fire, Medical Emergency',
                phoneNumber: '999', // Ghana emergency number
                color: Colors.red,
                onTap: () => _makeEmergencyCall('999'),
              ),

              const SizedBox(height: 12),

              // Domestic violence hotline
              _EmergencyActionCard(
                icon: Icons.support_agent,
                title: 'Domestic Violence Hotline',
                subtitle: '24/7 Support & Counseling',
                phoneNumber: '+233-XXX-XXXX', // Replace with actual hotline
                color: Colors.orange,
                onTap: () => _makeEmergencyCall('0800800800'),
              ),

              const SizedBox(height: 12),

              // Send emergency alert
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Icon(Icons.my_location, color: Colors.blue[600]),
                  ),
                  title: const Text('Send Emergency Alert'),
                  subtitle: _currentPosition != null
                      ? const Text('Share location with emergency contacts')
                      : _isLoadingLocation
                          ? const Text('Getting location...')
                          : const Text('Location not available'),
                  trailing: _isLoadingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward_ios),
                  onTap: _currentPosition != null ? _sendEmergencyAlert : null,
                ),
              ),

              const SizedBox(height: 32),

              // Safe spaces
              Text(
                'Find Safe Spaces',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: Icon(Icons.home, color: Colors.green[600]),
                  ),
                  title: const Text('Emergency Shelters'),
                  subtitle: const Text('Find nearby safe accommodation'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EmergencyLocationsScreen(locationType: 'shelters'),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple[100],
                    child: Icon(Icons.local_hospital, color: Colors.purple[600]),
                  ),
                  title: const Text('Medical Centers'),
                  subtitle: const Text('Hospitals and clinics nearby'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EmergencyLocationsScreen(locationType: 'medical'),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo[100],
                    child: Icon(Icons.local_police, color: Colors.indigo[600]),
                  ),
                  title: const Text('Police Stations'),
                  subtitle: const Text('Nearest police stations'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EmergencyLocationsScreen(locationType: 'police'),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Safety tips
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Safety Tips',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('• Keep this app easily accessible on your phone'),
                    const SizedBox(height: 4),
                    const Text('• Trust your instincts if something feels wrong'),
                    const SizedBox(height: 4),
                    const Text('• Have a safety plan and share it with trusted contacts'),
                    const SizedBox(height: 4),
                    const Text('• Remember: You deserve to be safe and supported'),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String phoneNumber;
  final Color color;
  final VoidCallback onTap;

  const _EmergencyActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.phoneNumber,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                radius: 24,
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phoneNumber,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.phone, color: color),
            ],
          ),
        ),
      ),
    );
  }
}