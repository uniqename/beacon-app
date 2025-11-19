import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyLocationsScreen extends StatefulWidget {
  final String locationType;
  
  const EmergencyLocationsScreen({super.key, required this.locationType});

  @override
  State<EmergencyLocationsScreen> createState() => _EmergencyLocationsScreenState();
}

class _EmergencyLocationsScreenState extends State<EmergencyLocationsScreen> {
  List<EmergencyLocation> _locations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  void _loadLocations() {
    setState(() {
      _locations = _getLocationsByType(widget.locationType);
      _isLoading = false;
    });
  }

  List<EmergencyLocation> _getLocationsByType(String type) {
    switch (type) {
      case 'shelters':
        return [
          EmergencyLocation(
            name: 'Beacon of New Beginnings Emergency Shelter',
            address: '123 Liberation Road, East Legon, Accra',
            phone: '+233-123-456-789',
            distance: '1.2 km',
            isOpen24Hours: true,
            specialties: ['Women & Children', 'Crisis Support', 'Counseling'],
          ),
          EmergencyLocation(
            name: 'Safe Haven Women\'s Shelter',
            address: '45 Unity Avenue, Adabraka, Accra',
            phone: '+233-987-654-321',
            distance: '2.8 km',
            isOpen24Hours: true,
            specialties: ['Women Only', 'Legal Aid', 'Job Training'],
          ),
          EmergencyLocation(
            name: 'New Hope Family Shelter',
            address: '78 Peace Street, Tema',
            phone: '+233-555-123-456',
            distance: '15.3 km',
            isOpen24Hours: false,
            openHours: '6:00 AM - 10:00 PM',
            specialties: ['Families', 'Children Services', 'Education'],
          ),
        ];
      case 'medical':
        return [
          EmergencyLocation(
            name: 'Korle Bu Teaching Hospital',
            address: 'Guggisberg Avenue, Korle Bu, Accra',
            phone: '+233-302-674301',
            distance: '3.5 km',
            isOpen24Hours: true,
            specialties: ['Emergency Care', 'Trauma Unit', 'Mental Health'],
          ),
          EmergencyLocation(
            name: '37 Military Hospital',
            address: '37 Station, Accra',
            phone: '+233-302-776111',
            distance: '5.2 km',
            isOpen24Hours: true,
            specialties: ['Emergency Medicine', 'Surgery', 'Pediatrics'],
          ),
          EmergencyLocation(
            name: 'Ridge Hospital',
            address: 'Castle Road, Ridge, Accra',
            phone: '+233-302-685009',
            distance: '2.1 km',
            isOpen24Hours: false,
            openHours: '24/7 Emergency Only',
            specialties: ['General Medicine', 'Emergency Care'],
          ),
        ];
      case 'police':
        return [
          EmergencyLocation(
            name: 'East Legon Police Station',
            address: 'East Legon, Accra',
            phone: '191',
            distance: '0.8 km',
            isOpen24Hours: true,
            specialties: ['Domestic Violence Unit', 'General Crimes', 'Emergency Response'],
          ),
          EmergencyLocation(
            name: 'Accra Central Police Station',
            address: 'High Street, Accra Central',
            phone: '191',
            distance: '4.2 km',
            isOpen24Hours: true,
            specialties: ['DOVVSU Unit', 'Criminal Investigation', 'Traffic'],
          ),
          EmergencyLocation(
            name: 'Airport Police Station',
            address: 'Airport Residential Area, Accra',
            phone: '191',
            distance: '6.7 km',
            isOpen24Hours: true,
            specialties: ['General Policing', 'Emergency Response'],
          ),
        ];
      default:
        return [];
    }
  }

  String _getTitle() {
    switch (widget.locationType) {
      case 'shelters':
        return 'Emergency Shelters';
      case 'medical':
        return 'Medical Centers';
      case 'police':
        return 'Police Stations';
      default:
        return 'Emergency Locations';
    }
  }

  String _getDescription() {
    switch (widget.locationType) {
      case 'shelters':
        return 'Safe accommodation options near you';
      case 'medical':
        return 'Hospitals and medical facilities';
      case 'police':
        return 'Police stations for emergency assistance';
      default:
        return 'Emergency locations near you';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.red[50],
                  child: Column(
                    children: [
                      Icon(
                        _getIcon(),
                        size: 32,
                        color: Colors.red[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getDescription(),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _locations.length,
                    itemBuilder: (context, index) {
                      final location = _locations[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(_getIcon(), color: Colors.red[600]),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          location.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          location.address,
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      location.distance,
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Hours and availability
                              Row(
                                children: [
                                  Icon(
                                    location.isOpen24Hours ? Icons.access_time : Icons.schedule,
                                    size: 16,
                                    color: location.isOpen24Hours ? Colors.green[600] : Colors.orange[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    location.isOpen24Hours ? '24/7 Available' : location.openHours ?? 'Call for hours',
                                    style: TextStyle(
                                      color: location.isOpen24Hours ? Colors.green[600] : Colors.orange[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Specialties
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: location.specialties.map((specialty) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue[200]!),
                                  ),
                                  child: Text(
                                    specialty,
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                )).toList(),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Action buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _callLocation(location.phone),
                                      icon: const Icon(Icons.phone),
                                      label: const Text('Call'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red[600],
                                        side: BorderSide(color: Colors.red[600]!),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _getDirections(location.address),
                                      icon: const Icon(Icons.directions),
                                      label: const Text('Directions'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red[600],
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  IconData _getIcon() {
    switch (widget.locationType) {
      case 'shelters':
        return Icons.home;
      case 'medical':
        return Icons.local_hospital;
      case 'police':
        return Icons.local_police;
      default:
        return Icons.location_on;
    }
  }

  void _callLocation(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not call $phone')),
        );
      }
    }
  }

  void _getDirections(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    }
  }
}

class EmergencyLocation {
  final String name;
  final String address;
  final String phone;
  final String distance;
  final bool isOpen24Hours;
  final String? openHours;
  final List<String> specialties;

  EmergencyLocation({
    required this.name,
    required this.address,
    required this.phone,
    required this.distance,
    required this.isOpen24Hours,
    this.openHours,
    required this.specialties,
  });
}