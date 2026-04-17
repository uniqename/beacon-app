import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/app_config_service.dart';

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
    final cfg = AppConfigService.instance.config;
    setState(() {
      _locations = cfg.orgKey == 'us'
          ? _getUSLocations(widget.locationType, cfg)
          : _getGhanaLocations(widget.locationType, cfg);
      _isLoading = false;
    });
  }

  List<EmergencyLocation> _getGhanaLocations(String type, dynamic cfg) {
    switch (type) {
      case 'shelters':
        return [
          EmergencyLocation(
            name: 'Ark Foundation',
            address: 'Tema, Greater Accra',
            phone: '+233244765988',
            distance: 'Nationwide',
            isOpen24Hours: true,
            specialties: ['Women & Children', 'Crisis Support', 'Counseling'],
          ),
          EmergencyLocation(
            name: 'Women in Need Network',
            address: 'Osu, Accra',
            phone: '+233302500920',
            distance: 'Accra',
            isOpen24Hours: true,
            specialties: ['Women Only', 'Emergency Housing', 'Counseling'],
          ),
          EmergencyLocation(
            name: 'Department of Social Welfare',
            address: 'Accra, Ghana',
            phone: '+233302664191',
            distance: 'Nationwide',
            isOpen24Hours: false,
            openHours: 'Mon–Fri 8AM–5PM',
            specialties: ['Emergency Housing', 'Family Services', 'Government Support'],
          ),
        ];
      case 'medical':
        return [
          EmergencyLocation(
            name: 'Korle-Bu Teaching Hospital',
            address: 'Guggisberg Avenue, Korle Bu, Accra',
            phone: '+233302674191',
            distance: 'Accra',
            isOpen24Hours: true,
            specialties: ['Emergency Care', 'Trauma Unit', 'Mental Health'],
          ),
          EmergencyLocation(
            name: '37 Military Hospital',
            address: '37 Station, Accra',
            phone: '+233302776111',
            distance: 'Accra',
            isOpen24Hours: true,
            specialties: ['Emergency Medicine', 'Surgery', 'Pediatrics'],
          ),
          EmergencyLocation(
            name: 'Ridge Hospital',
            address: 'Castle Road, Ridge, Accra',
            phone: '+233302684464',
            distance: 'Accra',
            isOpen24Hours: true,
            openHours: '24/7 Emergency',
            specialties: ['General Medicine', 'Emergency Care'],
          ),
        ];
      case 'police':
        return [
          EmergencyLocation(
            name: 'Ghana Police — Emergency Line',
            address: 'Nationwide',
            phone: '191',
            distance: 'Nationwide',
            isOpen24Hours: true,
            specialties: ['Emergency Response', 'Domestic Violence', 'General Crimes'],
          ),
          EmergencyLocation(
            name: 'DOVVSU — DV & Victim Support Unit',
            address: 'Police Headquarters, Accra',
            phone: cfg.dvHotline,
            distance: 'Nationwide',
            isOpen24Hours: true,
            specialties: ['Domestic Violence', 'Protection Orders', 'Victim Support'],
          ),
          EmergencyLocation(
            name: 'Commission on Human Rights (CHRAJ)',
            address: 'Accra, Ghana',
            phone: '+233302664661',
            distance: 'Nationwide',
            isOpen24Hours: false,
            openHours: 'Mon–Fri 8AM–5PM',
            specialties: ['Human Rights', 'Legal Advocacy', 'DV Complaints'],
          ),
        ];
      default:
        return [];
    }
  }

  List<EmergencyLocation> _getUSLocations(String type, dynamic cfg) {
    switch (type) {
      case 'shelters':
        return [
          EmergencyLocation(
            name: 'National DV Hotline — Shelter Referral',
            address: 'National Service',
            phone: '1-800-799-7233',
            distance: 'Nationwide',
            isOpen24Hours: true,
            specialties: ['Shelter Finder', 'Crisis Support', 'Safety Planning'],
          ),
          EmergencyLocation(
            name: 'Safe Horizon',
            address: 'National / New York-based',
            phone: '1-800-621-4673',
            distance: 'Nationwide',
            isOpen24Hours: true,
            specialties: ['Emergency Shelter', 'Legal Advocacy', 'Counseling'],
          ),
          EmergencyLocation(
            name: '211 — Local Shelter Finder',
            address: 'Nationwide',
            phone: '211',
            distance: 'Nationwide',
            isOpen24Hours: true,
            specialties: ['Local Shelters', 'Housing Assistance', 'Food & Support'],
          ),
        ];
      case 'medical':
        return [
          EmergencyLocation(
            name: 'Emergency Medical Services',
            address: 'Nationwide',
            phone: '911',
            distance: 'Nearest',
            isOpen24Hours: true,
            specialties: ['Emergency Care', 'Trauma Response', 'Ambulance'],
          ),
          EmergencyLocation(
            name: 'SAMHSA Mental Health Crisis Line',
            address: 'National Service',
            phone: '1-800-662-4357',
            distance: 'Nationwide',
            isOpen24Hours: true,
            specialties: ['Mental Health', 'Crisis Support', 'Trauma Counseling'],
          ),
          EmergencyLocation(
            name: 'Crisis Text Line',
            address: 'National — Text Service',
            phone: '741741',
            distance: 'Nationwide',
            isOpen24Hours: true,
            specialties: ['Text-Based Support', 'Crisis Counseling', 'Safety Planning'],
          ),
        ];
      case 'police':
        return [
          EmergencyLocation(
            name: 'Emergency — Police / Fire / Ambulance',
            address: 'Nationwide',
            phone: '911',
            distance: 'Nearest',
            isOpen24Hours: true,
            specialties: ['Emergency Response', 'Domestic Violence', 'Immediate Danger'],
          ),
          EmergencyLocation(
            name: 'National DV Hotline — Safety Planning',
            address: 'National Service',
            phone: '1-800-799-7233',
            distance: 'Nationwide',
            isOpen24Hours: true,
            specialties: ['Safety Planning', 'Law Enforcement Guidance', 'Protection Orders'],
          ),
          EmergencyLocation(
            name: 'Non-Emergency Police / Community Services',
            address: 'Nationwide',
            phone: '311',
            distance: 'Local',
            isOpen24Hours: false,
            openHours: 'Varies by city',
            specialties: ['Non-Emergency Reports', 'Community Safety', 'Referrals'],
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
        return 'Police & Crisis Lines';
      default:
        return 'Emergency Locations';
    }
  }

  String _getDescription() {
    switch (widget.locationType) {
      case 'shelters':
        return 'Safe accommodation and shelter referrals';
      case 'medical':
        return 'Hospitals and medical facilities';
      case 'police':
        return 'Emergency police and crisis support lines';
      default:
        return 'Emergency locations and contacts';
    }
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.red[950] : Colors.red[50],
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: isDark ? Colors.red[900] : Colors.red[100],
                  child: Column(
                    children: [
                      Icon(_getIcon(), size: 32, color: isDark ? Colors.red[300] : Colors.red[600]),
                      const SizedBox(height: 8),
                      Text(
                        _getDescription(),
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.red[200] : Colors.red[700],
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
                              Row(
                                children: [
                                  Icon(
                                    location.isOpen24Hours ? Icons.access_time : Icons.schedule,
                                    size: 16,
                                    color: location.isOpen24Hours ? Colors.green[600] : Colors.orange[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    location.isOpen24Hours
                                        ? '24/7 Available'
                                        : location.openHours ?? 'Call for hours',
                                    style: TextStyle(
                                      color: location.isOpen24Hours
                                          ? Colors.green[600]
                                          : Colors.orange[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: location.specialties
                                    .map((s) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.blue[200]!),
                                          ),
                                          child: Text(
                                            s,
                                            style: TextStyle(
                                              color: Colors.blue[700],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _callLocation(location.phone),
                                      icon: const Icon(Icons.phone),
                                      label: Text(location.phone),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red[600],
                                        side: BorderSide(color: Colors.red[600]!),
                                      ),
                                    ),
                                  ),
                                  if (location.address != 'National Service' &&
                                      location.address != 'Nationwide' &&
                                      location.address != 'National — Text Service') ...[
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

  void _callLocation(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not call $phone')),
      );
    }
  }

  void _getDirections(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encodedAddress');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not open maps')));
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
