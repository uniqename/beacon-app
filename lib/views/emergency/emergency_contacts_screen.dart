import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_constants.dart';
import '../../services/location_service.dart';
import '../../data/location_based_resources.dart';
import '../../models/resource.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.warning, size: 32, color: Colors.red[700]),
                  const SizedBox(height: 8),
                  Consumer<LocationService>(
                    builder: (context, locationService, child) {
                      final emergencyNumber = locationService.getLocationBasedEmergencyNumber();
                      return Text(
                        'If you are in immediate danger, call $emergencyNumber (Police) now',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Emergency Services',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Location-based emergency contacts
            Consumer<LocationService>(
              builder: (context, locationService, child) {
                return Column(
                  children: [
                    // Location display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
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
                          Text(
                            'Emergency services for: ${locationService.getLocationDisplayText()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Location-based emergency numbers
                    _buildContactCard(
                      context,
                      'Police',
                      locationService.getLocationBasedEmergencyNumber(),
                      Icons.local_police,
                      Colors.blue[700]!,
                    ),
                    _buildContactCard(
                      context,
                      'Fire Service',
                      locationService.getLocationBasedFireNumber(),
                      Icons.local_fire_department,
                      Colors.red[700]!,
                    ),
                    _buildContactCard(
                      context,
                      'Ambulance',
                      locationService.getLocationBasedAmbulanceNumber(),
                      Icons.local_hospital,
                      Colors.green[700]!,
                    ),
                    // Additional location-based resources
                    ..._getLocationBasedEmergencyResources(locationService).map((resource) {
                      return _buildContactCard(
                        context,
                        resource.name,
                        resource.phone ?? '',
                        _getContactIcon(resource.typeDisplayName),
                        _getContactColor(resource.typeDisplayName),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Safety Tips
            _buildSafetyTips(context),
            
            const SizedBox(height: 24),
            
            // Quick Exit Button
            _buildQuickExitButton(context),
          ],
        ),
      ),
    );
  }

  List<Resource> _getLocationBasedEmergencyResources(LocationService locationService) {
    List<Resource> resources = [];
    
    if (locationService.isInGhana) {
      resources = LocationBasedResources.getGhanaResources()
          .where((resource) => resource.type == ResourceType.emergency || resource.is24Hours)
          .toList();
    } else if (locationService.isInUSA) {
      resources = LocationBasedResources.getUSAResources(locationService.currentState)
          .where((resource) => resource.type == ResourceType.emergency || resource.is24Hours)
          .toList();
    } else {
      resources = LocationBasedResources.getInternationalResources()
          .where((resource) => resource.type == ResourceType.emergency || resource.is24Hours)
          .toList();
    }
    
    return resources;
  }

  Widget _buildContactCard(BuildContext context, String name, String number, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(number),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _makeCall(number),
              icon: Icon(Icons.phone, color: color),
              tooltip: 'Call $number',
            ),
            IconButton(
              onPressed: () => _sendSMS(number),
              icon: Icon(Icons.message, color: color),
              tooltip: 'Text $number',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyTips(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Safety Tips',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 12),
          const Text('• If possible, call from a safe location'),
          const Text('• Have important information ready (location, situation)'),
          const Text('• Trust your instincts - if something feels wrong, get help'),
          const Text('• Create a safety plan with trusted friends or family'),
          const Text('• Keep important documents in a safe place'),
        ],
      ),
    );
  }

  Widget _buildQuickExitButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.exit_to_app, size: 32, color: Colors.orange[700]),
          const SizedBox(height: 8),
          Text(
            'Quick Exit',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange[700],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'If you need to quickly exit this app, press the back button multiple times or close the app.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            icon: const Icon(Icons.home),
            label: const Text('Go to Home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getContactIcon(String contactType) {
    switch (contactType.toLowerCase()) {
      case 'police':
        return Icons.local_police;
      case 'fire service':
        return Icons.local_fire_department;
      case 'ambulance':
        return Icons.local_hospital;
      case 'domestic violence hotline':
        return Icons.support_agent;
      case 'crisis support':
        return Icons.psychology;
      default:
        return Icons.phone;
    }
  }

  Color _getContactColor(String contactType) {
    switch (contactType.toLowerCase()) {
      case 'police':
        return Colors.blue[700]!;
      case 'fire service':
        return Colors.red[700]!;
      case 'ambulance':
        return Colors.green[700]!;
      case 'domestic violence hotline':
        return Colors.purple[700]!;
      case 'crisis support':
        return Colors.teal[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _sendSMS(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }
}