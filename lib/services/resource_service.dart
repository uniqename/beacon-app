import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/resource.dart';
import 'auth_service.dart';

class ResourceService {
  static final ResourceService _instance = ResourceService._internal();
  factory ResourceService() => _instance;
  ResourceService._internal();

  final AuthService _authService = AuthService();
  List<Resource>? _cachedResources;

  // Initialize resources if not cached
  Future<void> _initializeResources() async {
    if (_cachedResources == null) {
      await _loadSampleResources();
    }
  }

  // Get all resources by type
  Future<List<Resource>> getResourcesByType(ResourceType type) async {
    try {
      await _initializeResources();
      return _cachedResources!
          .where((resource) => resource.type == type && resource.status == ResourceStatus.available)
          .toList();
    } catch (e) {
      print('Error getting resources by type: $e');
      return [];
    }
  }

  // Get nearby resources based on user location
  Future<List<Resource>> getNearbyResources({
    required Position userLocation,
    ResourceType? type,
    double radiusKm = 20.0,
  }) async {
    try {
      await _initializeResources();
      List<Resource> allResources = _cachedResources!
          .where((resource) => resource.status == ResourceStatus.available)
          .toList();

      if (type != null) {
        allResources = allResources.where((resource) => resource.type == type).toList();
      }

      List<Resource> nearbyResources = [];

      for (final resource in allResources) {
        if (resource.latitude != null && resource.longitude != null) {
          final distance = Geolocator.distanceBetween(
            userLocation.latitude,
            userLocation.longitude,
            resource.latitude!,
            resource.longitude!,
          ) / 1000; // Convert to km

          if (distance <= radiusKm) {
            nearbyResources.add(resource);
          }
        } else {
          // Include resources without location (like hotlines)
          if (resource.type == ResourceType.hotline || 
              resource.type == ResourceType.emergency) {
            nearbyResources.add(resource);
          }
        }
      }

      // Sort by distance (resources without location come first)
      nearbyResources.sort((a, b) {
        if (a.latitude == null || a.longitude == null) return -1;
        if (b.latitude == null || b.longitude == null) return 1;

        final distanceA = Geolocator.distanceBetween(
          userLocation.latitude, userLocation.longitude,
          a.latitude!, a.longitude!,
        );
        final distanceB = Geolocator.distanceBetween(
          userLocation.latitude, userLocation.longitude,
          b.latitude!, b.longitude!,
        );

        return distanceA.compareTo(distanceB);
      });

      return nearbyResources;
    } catch (e) {
      print('Error getting nearby resources: $e');
      return [];
    }
  }

  // Get available shelters with capacity
  Future<List<Resource>> getAvailableShelters() async {
    try {
      await _initializeResources();
      return _cachedResources!
          .where((resource) => 
              resource.type == ResourceType.shelter &&
              resource.status == ResourceStatus.available &&
              resource.hasAvailableSpace)
          .toList();
    } catch (e) {
      print('Error getting available shelters: $e');
      return [];
    }
  }

  // Search resources by name or services
  Future<List<Resource>> searchResources(String searchTerm) async {
    try {
      await _initializeResources();
      final searchLower = searchTerm.toLowerCase();
      
      return _cachedResources!
          .where((resource) => 
              resource.status == ResourceStatus.available &&
              (resource.name.toLowerCase().contains(searchLower) ||
               resource.description.toLowerCase().contains(searchLower) ||
               resource.services.any((service) => 
                   service.toLowerCase().contains(searchLower))))
          .toList();
    } catch (e) {
      print('Error searching resources: $e');
      return [];
    }
  }

  // Get emergency hotlines (24/7 available)
  Future<List<Resource>> getEmergencyHotlines() async {
    try {
      await _initializeResources();
      return _cachedResources!
          .where((resource) => 
              resource.type == ResourceType.hotline &&
              resource.is24Hours)
          .toList();
    } catch (e) {
      print('Error getting emergency hotlines: $e');
      return [];
    }
  }

  // Book/request a resource
  Future<bool> requestResource({
    required String resourceId,
    required String userId,
    String? notes,
    DateTime? preferredDate,
  }) async {
    try {
      // Store resource request in SharedPreferences for simplicity
      final prefs = await SharedPreferences.getInstance();
      final requestsList = prefs.getStringList('resource_requests_$userId') ?? [];
      
      final requestData = {
        'resourceId': resourceId,
        'userId': userId,
        'status': 'pending',
        'notes': notes,
        'preferredDate': preferredDate?.toIso8601String(),
        'requestedAt': DateTime.now().toIso8601String(),
      };

      requestsList.add(requestData.toString());
      await prefs.setStringList('resource_requests_$userId', requestsList);

      // Create a case for follow-up if needed
      await _createResourceCase(
        resourceId: resourceId,
        userId: userId,
        notes: notes,
      );

      print('Resource request submitted successfully');
      return true;
    } catch (e) {
      print('Error requesting resource: $e');
      return false;
    }
  }

  // Get user's resource requests (simplified for local storage)
  Future<List<Map<String, dynamic>>> getUserResourceRequests(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final requestsList = prefs.getStringList('resource_requests_$userId') ?? [];
      
      await _initializeResources();
      List<Map<String, dynamic>> requests = [];

      for (final requestString in requestsList) {
        // In a real implementation, you'd parse this properly
        // For demo purposes, we'll create a simple request structure
        requests.add({
          'id': 'request_${requests.length}',
          'status': 'pending',
          'notes': 'Resource request from local storage',
          'requestedAt': DateTime.now(),
        });
      }

      return requests;
    } catch (e) {
      print('Error getting user resource requests: $e');
      return [];
    }
  }

  // Load sample resources for local storage
  Future<void> _loadSampleResources() async {
    try {
      _cachedResources = [
        Resource(
          id: 'resource_1',
          name: 'Beacon of New Beginnings Emergency Shelter',
          description: 'Secure emergency accommodation for women and children escaping domestic violence',
          type: ResourceType.shelter,
          status: ResourceStatus.available,
          address: 'Accra, Ghana',
          phone: '+233-XXX-XXXX',
          email: 'shelter@beaconnewbeginnings.org',
          services: ['Emergency accommodation', 'Meals', 'Childcare', 'Security'],
          operatingHours: {
            'monday': '24 hours',
            'tuesday': '24 hours',
            'wednesday': '24 hours',
            'thursday': '24 hours',
            'friday': '24 hours',
            'saturday': '24 hours',
            'sunday': '24 hours',
          },
          requiresAppointment: false,
          is24Hours: true,
          latitude: 5.6037,
          longitude: -0.1870,
          capacity: 50,
          currentOccupancy: 32,
          eligibilityCriteria: ['Women and children', 'Domestic violence survivors'],
          contactPerson: 'Sarah Mensah',
          createdAt: DateTime.now(),
        ),
        Resource(
          id: 'resource_2',
          name: 'Legal Aid Ghana - Domestic Violence Unit',
          description: 'Free legal support for domestic violence cases',
          type: ResourceType.legal,
          status: ResourceStatus.available,
          address: 'Ring Road, Accra',
          phone: '+233-XXX-XXXX',
          email: 'legal@legalaidgh.org',
          services: ['Legal consultation', 'Court representation', 'Restraining orders'],
          operatingHours: {
            'monday': '8:00 AM - 5:00 PM',
            'tuesday': '8:00 AM - 5:00 PM',
            'wednesday': '8:00 AM - 5:00 PM',
            'thursday': '8:00 AM - 5:00 PM',
            'friday': '8:00 AM - 5:00 PM',
          },
          requiresAppointment: true,
          is24Hours: false,
          latitude: 5.5502,
          longitude: -0.2174,
          eligibilityCriteria: ['Low income', 'Domestic violence cases'],
          contactPerson: 'Kwame Asante',
          createdAt: DateTime.now(),
        ),
        Resource(
          id: 'resource_3',
          name: 'Domestic Violence Hotline Ghana',
          description: '24/7 crisis support and counseling for domestic violence survivors',
          type: ResourceType.hotline,
          status: ResourceStatus.available,
          phone: '+233-XXX-XXXX',
          services: ['Crisis counseling', 'Safety planning', 'Resource referrals'],
          is24Hours: true,
          contactPerson: 'Crisis Team',
          createdAt: DateTime.now(),
        ),
        Resource(
          id: 'resource_4',
          name: 'Korle-Bu Teaching Hospital - Trauma Unit',
          description: 'Emergency medical care and trauma treatment',
          type: ResourceType.medical,
          status: ResourceStatus.available,
          address: 'Korle-Bu, Accra',
          phone: '+233-XXX-XXXX',
          services: ['Emergency care', 'Trauma treatment', 'Mental health support'],
          is24Hours: true,
          latitude: 5.5385,
          longitude: -0.2317,
          contactPerson: 'Emergency Department',
          createdAt: DateTime.now(),
        ),
      ];

      print('Sample resources loaded successfully');
    } catch (e) {
      print('Error loading sample resources: $e');
      _cachedResources = [];
    }
  }

  // Private helper methods
  Future<void> _createResourceCase({
    required String resourceId,
    required String userId,
    String? notes,
  }) async {
    try {
      final db = await _authService.database;
      final caseId = 'resource_case_${DateTime.now().millisecondsSinceEpoch}';
      
      final caseData = {
        'id': caseId,
        'survivor_id': userId,
        'type': 'resource_request',
        'priority': 'medium',
        'status': 'pending',
        'title': 'Resource Request Follow-up',
        'description': 'Follow-up for resource request: $resourceId',
        'created_at': DateTime.now().toIso8601String(),
        'is_anonymous': 1,
        'notes': notes ?? '',
        'attachments': '',
      };

      await db.insert('cases', caseData);
      print('Resource case created: $caseId');
    } catch (e) {
      print('Error creating resource case: $e');
    }
  }
}