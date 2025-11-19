import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../models/resource.dart';
import '../../services/resource_service.dart';
import '../../services/auth_service.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final ResourceService _resourceService = ResourceService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Resource> _allResources = [];
  List<Resource> _filteredResources = [];
  Position? _userLocation;
  bool _isLoading = true;
  String _searchQuery = '';

  final List<ResourceType> _resourceTypes = [
    ResourceType.shelter,
    ResourceType.counseling,
    ResourceType.legal,
    ResourceType.medical,
    ResourceType.hotline,
    ResourceType.employment,
    ResourceType.financial,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _resourceTypes.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadResources();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition();
      setState(() => _userLocation = position);
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _loadResources() async {
    setState(() => _isLoading = true);
    
    final currentType = _resourceTypes[_tabController.index];
    final resources = await _resourceService.getResourcesByType(currentType);
    
    setState(() {
      _allResources = resources;
      _filteredResources = resources;
      _isLoading = false;
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadResources();
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredResources = _allResources;
      } else {
        _filteredResources = _allResources
            .where((resource) =>
                resource.name.toLowerCase().contains(query.toLowerCase()) ||
                resource.description.toLowerCase().contains(query.toLowerCase()) ||
                resource.services.any((service) =>
                    service.toLowerCase().contains(query.toLowerCase())))
            .toList();
      }
    });
  }

  Future<void> _showAllResources() async {
    setState(() => _isLoading = true);
    
    // Get all resources from all types
    List<Resource> allTypeResources = [];
    for (var type in _resourceTypes) {
      final resources = await _resourceService.getResourcesByType(type);
      allTypeResources.addAll(resources);
    }
    
    setState(() {
      _allResources = allTypeResources;
      _filteredResources = allTypeResources;
      _isLoading = false;
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  String _getDistanceText(Resource resource) {
    if (_userLocation == null || resource.latitude == null || resource.longitude == null) {
      return '';
    }

    final distance = Geolocator.distanceBetween(
      _userLocation!.latitude,
      _userLocation!.longitude,
      resource.latitude!,
      resource.longitude!,
    ) / 1000; // Convert to km

    if (distance < 1) {
      return '${(distance * 1000).round()}m away';
    } else {
      return '${distance.toStringAsFixed(1)}km away';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Resources'),
        automaticallyImplyLeading: false,
        actions: [
          // Quick Exit Button
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            tooltip: 'Quick Exit',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search resources...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              // Tab bar with back to all option
              Row(
                children: [
                  Expanded(
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabs: _resourceTypes.map((type) {
                        return Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getResourceIcon(type)),
                              const SizedBox(width: 4),
                              Text(type.toString().split('.').last.toUpperCase()),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  // Back to All button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextButton.icon(
                      onPressed: () => _showAllResources(),
                      icon: const Icon(Icons.view_list, size: 16),
                      label: const Text('All'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredResources.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No resources found',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your search or browse other categories',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadResources,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredResources.length,
                    itemBuilder: (context, index) {
                      final resource = _filteredResources[index];
                      return _ResourceCard(
                        resource: resource,
                        distanceText: _getDistanceText(resource),
                        onCall: resource.phone != null
                            ? () => _makePhoneCall(resource.phone!)
                            : null,
                        onEmail: resource.email != null
                            ? () => _sendEmail(resource.email!)
                            : null,
                        onRequest: () => _requestResource(resource),
                      );
                    },
                  ),
                ),
    );
  }

  IconData _getResourceIcon(ResourceType type) {
    switch (type) {
      case ResourceType.shelter:
        return Icons.home;
      case ResourceType.counseling:
        return Icons.psychology;
      case ResourceType.legal:
        return Icons.gavel;
      case ResourceType.medical:
        return Icons.local_hospital;
      case ResourceType.hotline:
        return Icons.phone;
      case ResourceType.employment:
        return Icons.work;
      case ResourceType.financial:
        return Icons.attach_money;
      case ResourceType.education:
        return Icons.school;
      case ResourceType.emergency:
        return Icons.emergency;
    }
  }

  void _requestResource(Resource resource) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ResourceRequestSheet(resource: resource),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final Resource resource;
  final String distanceText;
  final VoidCallback? onCall;
  final VoidCallback? onEmail;
  final VoidCallback onRequest;

  const _ResourceCard({
    required this.resource,
    required this.distanceText,
    this.onCall,
    this.onEmail,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (distanceText.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          distanceText,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Service Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: resource.status == ResourceStatus.available ? Colors.green[100] : Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        resource.status == ResourceStatus.available ? '✅ Available' : '🔄 Coming Soon',
                        style: TextStyle(
                          color: resource.status == ResourceStatus.available ? Colors.green[800] : Colors.orange[800],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Hours Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: resource.is24Hours ? Colors.green[100] : Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        resource.is24Hours ? '24/7' : 'Scheduled',
                        style: TextStyle(
                          color: resource.is24Hours ? Colors.green[800] : Colors.blue[800],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              resource.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 12),

            // Services
            if (resource.services.isNotEmpty) ...[
              Text(
                'Services:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: resource.services.map((service) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      service,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Contact info
            if (resource.address != null || resource.phone != null) ...[
              Row(
                children: [
                  if (resource.address != null) ...[
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        resource.address!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Capacity info for shelters
            if (resource.type == ResourceType.shelter && resource.capacity > 0) ...[
              LinearProgressIndicator(
                value: resource.occupancyRate,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  resource.occupancyRate > 0.8 ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${resource.currentOccupancy}/${resource.capacity} occupied',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
            ],

            // Action buttons - Fixed alignment
            Row(
              children: [
                if (onCall != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCall,
                      icon: const Icon(Icons.phone, size: 16),
                      label: const Text('Call'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                if (onCall != null && onEmail != null) const SizedBox(width: 8),
                if (onEmail != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEmail,
                      icon: const Icon(Icons.email, size: 16),
                      label: const Text('Email'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                if ((onCall != null || onEmail != null)) const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onRequest,
                    icon: const Icon(Icons.assignment, size: 16),
                    label: const Text('Request'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourceRequestSheet extends StatefulWidget {
  final Resource resource;

  const _ResourceRequestSheet({required this.resource});

  @override
  State<_ResourceRequestSheet> createState() => _ResourceRequestSheetState();
}

class _ResourceRequestSheetState extends State<_ResourceRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  DateTime? _preferredDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Get current user from auth service
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      
      String userId;
      if (currentUser != null) {
        userId = currentUser.id;
      } else {
        // For anonymous users, create a temporary ID or prompt for registration
        _handleAnonymousResourceRequest();
        return;
      }

      final success = await ResourceService().requestResource(
        resourceId: widget.resource.id,
        userId: userId,
        notes: _notesController.text.trim().isNotEmpty 
            ? _notesController.text.trim() 
            : null,
        preferredDate: _preferredDate,
      );

      setState(() => _isSubmitting = false);

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resource request submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit request. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting request: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleAnonymousResourceRequest() async {
    setState(() => _isSubmitting = false);
    
    if (!mounted) return;
    
    Navigator.pop(context); // Close the resource request sheet
    
    // Show dialog explaining options for anonymous users
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.info_outline, color: Colors.blue, size: 48),
        title: Text('Resource Access'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To submit resource requests, please choose an option:'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.phone, color: Colors.green[600], size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Quick Access Options:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Call directly: ${widget.resource.phone ?? "Contact number available"}\n'
                    '• Email: ${widget.resource.email ?? "Contact email available"}\n'
                    '• Visit in person at their location',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Or create an account for:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              '• Online resource requests\n'
              '• Case tracking\n'
              '• Follow-up notifications\n'
              '• Access to additional services',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          if (widget.resource.phone != null)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                final Uri phoneUri = Uri(scheme: 'tel', path: widget.resource.phone!);
                launchUrl(phoneUri);
              },
              icon: Icon(Icons.phone, size: 16),
              label: Text('Call Now'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/register');
            },
            child: Text('Create Account'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Request: ${widget.resource.name}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes (Optional)',
                  hintText: 'Any specific needs or questions...',
                ),
              ),
              const SizedBox(height: 16),

              if (widget.resource.requiresAppointment) ...[
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (date != null) {
                      setState(() => _preferredDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Preferred Date',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _preferredDate != null
                          ? '${_preferredDate!.day}/${_preferredDate!.month}/${_preferredDate!.year}'
                          : 'Select date',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Request'),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}