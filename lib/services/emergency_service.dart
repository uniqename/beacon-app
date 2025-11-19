import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/resource.dart';
import 'auth_service.dart';

class EmergencyService {
  static final EmergencyService _instance = EmergencyService._internal();
  factory EmergencyService() => _instance;
  EmergencyService._internal();

  final AuthService _authService = AuthService();

  // Send emergency alert with location
  Future<bool> sendEmergencyAlert({
    required String userId,
    required Position location,
    String? message,
  }) async {
    try {
      final db = await _authService.database;
      final alertId = 'alert_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create emergency alert
      final alertData = {
        'id': alertId,
        'user_id': userId,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'accuracy': location.accuracy,
        'timestamp': DateTime.now().toIso8601String(),
        'message': message ?? 'Emergency alert triggered',
        'status': 'active',
        'type': 'location_alert',
      };

      await db.insert('emergency_alerts', alertData);

      // Get user data to find emergency contacts
      final userData = await _authService.getUserData(userId);

      if (userData != null) {
        // Log emergency contact notification (in real app, would send SMS/call)
        if (userData.emergencyContact != null && 
            userData.emergencyContactPhone != null) {
          await _logEmergencyContactNotification(
            alertId: alertId,
            userName: userData.displayName ?? 'Someone',
            emergencyContact: userData.emergencyContact!,
            emergencyPhone: userData.emergencyContactPhone!,
            location: location,
          );
        }

        // Create emergency case for NGO staff follow-up
        await _createEmergencyCase(
          alertId: alertId,
          userId: userId,
          userName: userData.displayName ?? 'Anonymous',
          location: location,
          message: message,
          isAnonymous: userData.isAnonymous,
        );
      }

      print('Emergency alert sent successfully');
      return true;
    } catch (e) {
      print('Error sending emergency alert: $e');
      return false;
    }
  }

  // Create emergency case
  Future<String?> createEmergencyCase({
    required String survivorId,
    required String description,
    Position? location,
    String? contactInfo,
  }) async {
    try {
      final db = await _authService.database;
      final caseId = 'case_${DateTime.now().millisecondsSinceEpoch}';
      
      final caseData = {
        'id': caseId,
        'survivor_id': survivorId,
        'type': 'emergency',
        'priority': 'critical',
        'status': 'pending',
        'title': 'Emergency Support Request',
        'description': description,
        'created_at': DateTime.now().toIso8601String(),
        'is_anonymous': 1,
        'contact_info': contactInfo,
        'latitude': location?.latitude,
        'longitude': location?.longitude,
        'notes': '',
        'attachments': '',
      };

      await db.insert('cases', caseData);

      // Find available counselor for assignment
      await _assignEmergencyCase(caseId);

      print('Emergency case created: $caseId');
      return caseId;
    } catch (e) {
      print('Error creating emergency case: $e');
      return null;
    }
  }

  // Get nearby emergency resources (using hardcoded local data)
  Future<List<Map<String, dynamic>>> getNearbyEmergencyResources({
    required Position userLocation,
    double radiusKm = 10.0,
  }) async {
    try {
      final emergencyResources = _getHardcodedEmergencyResources();
      List<Map<String, dynamic>> nearbyResources = [];

      for (final resource in emergencyResources) {
        if (resource['latitude'] != null && resource['longitude'] != null) {
          final distance = Geolocator.distanceBetween(
            userLocation.latitude,
            userLocation.longitude,
            resource['latitude'],
            resource['longitude'],
          ) / 1000; // Convert to km

          if (distance <= radiusKm) {
            nearbyResources.add({
              'distance': distance,
              ...resource,
            });
          }
        } else {
          // Include resources without location (like hotlines)
          if (resource['type'] == 'hotline' || resource['type'] == 'emergency') {
            nearbyResources.add({
              'distance': 0.0,
              ...resource,
            });
          }
        }
      }

      // Sort by distance
      nearbyResources.sort((a, b) => a['distance'].compareTo(b['distance']));

      return nearbyResources;
    } catch (e) {
      print('Error getting nearby emergency resources: $e');
      return [];
    }
  }

  // Get emergency hotlines (using hardcoded local data)
  Future<List<Map<String, dynamic>>> getEmergencyHotlines() async {
    try {
      final allResources = _getHardcodedEmergencyResources();
      return allResources
          .where((resource) => resource['type'] == 'hotline' && resource['is24Hours'] == true)
          .toList();
    } catch (e) {
      print('Error getting emergency hotlines: $e');
      return [];
    }
  }

  // Private helper methods
  Future<void> _logEmergencyContactNotification({
    required String alertId,
    required String userName,
    required String emergencyContact,
    required String emergencyPhone,
    required Position location,
  }) async {
    try {
      // In a real implementation, this would send SMS/call to emergency contact
      // For now, we'll just log it for demonstration
      final prefs = await SharedPreferences.getInstance();
      final notificationLog = prefs.getStringList('emergency_notifications') ?? [];
      
      final notification = 'Emergency Alert: $userName needs help at ${location.latitude}, ${location.longitude}. Contact: $emergencyContact ($emergencyPhone) - ${DateTime.now()}';
      notificationLog.add(notification);
      
      await prefs.setStringList('emergency_notifications', notificationLog);
      print('Emergency contact notification logged for $emergencyContact');
    } catch (e) {
      print('Error logging emergency contact notification: $e');
    }
  }

  Future<void> _createEmergencyCase({
    required String alertId,
    required String userId,
    required String userName,
    required Position location,
    String? message,
    required bool isAnonymous,
  }) async {
    try {
      final db = await _authService.database;
      final caseId = 'emergency_case_${DateTime.now().millisecondsSinceEpoch}';
      
      final caseData = {
        'id': caseId,
        'survivor_id': userId,
        'type': 'emergency_alert',
        'priority': 'critical',
        'status': 'active',
        'title': 'Emergency Alert Response',
        'description': isAnonymous 
            ? 'Anonymous user triggered emergency alert'
            : '$userName triggered emergency alert: ${message ?? "No message provided"}',
        'created_at': DateTime.now().toIso8601String(),
        'is_anonymous': isAnonymous ? 1 : 0,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'notes': 'Alert ID: $alertId',
        'attachments': '',
      };

      await db.insert('cases', caseData);
      print('Emergency case created for alert: $alertId');
    } catch (e) {
      print('Error creating emergency case: $e');
    }
  }

  Future<void> _assignEmergencyCase(String caseId) async {
    try {
      final db = await _authService.database;
      
      // Find available counselors
      final counselors = await db.query(
        'users',
        where: 'user_type = ? AND is_available = ?',
        whereArgs: ['counselor', 1],
      );

      if (counselors.isNotEmpty) {
        // Assign to first available counselor (simplified assignment)
        final counselorId = counselors.first['id'] as String;

        await db.update(
          'cases',
          {
            'assigned_counselor_id': counselorId,
            'status': 'active',
            'assigned_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [caseId],
        );

        print('Emergency case $caseId assigned to counselor $counselorId');
      } else {
        print('No available counselors found for case assignment');
      }
    } catch (e) {
      print('Error assigning emergency case: $e');
    }
  }

  // Hardcoded emergency resources for local storage
  List<Map<String, dynamic>> _getHardcodedEmergencyResources() {
    return [
      {
        'id': 'emergency_1',
        'name': 'Beacon Emergency Shelter',
        'description': 'Safe emergency accommodation for survivors',
        'type': 'shelter',
        'status': 'available',
        'address': 'Accra, Ghana',
        'phone': '+233-XXX-XXXX',
        'is24Hours': true,
        'latitude': 5.6037,
        'longitude': -0.1870,
      },
      {
        'id': 'emergency_2',
        'name': 'Ghana Domestic Violence Hotline',
        'description': '24/7 crisis support hotline',
        'type': 'hotline',
        'status': 'available',
        'phone': '+233-XXX-XXXX',
        'is24Hours': true,
      },
      {
        'id': 'emergency_3',
        'name': 'Korle-Bu Emergency Department',
        'description': 'Emergency medical care',
        'type': 'medical',
        'status': 'available',
        'address': 'Korle-Bu, Accra',
        'phone': '+233-XXX-XXXX',
        'is24Hours': true,
        'latitude': 5.5385,
        'longitude': -0.2317,
      },
    ];
  }
}