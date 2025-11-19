import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_constants.dart';
import '../../services/location_service.dart';
import '../../data/location_based_resources.dart';
import '../../models/resource.dart';

class ResourcesListScreen extends StatefulWidget {
  final String? category;

  const ResourcesListScreen({super.key, this.category});

  @override
  State<ResourcesListScreen> createState() => _ResourcesListScreenState();
}

class _ResourcesListScreenState extends State<ResourcesListScreen> {
  String? _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedCategory ?? 'Resources'),
      ),
      body: Column(
        children: [
          // Location display
          _buildLocationHeader(),
          
          // Search and Filter
          _buildSearchAndFilter(),
          
          // Resources List
          Expanded(
            child: _buildResourcesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationHeader() {
    return Consumer<LocationService>(
      builder: (context, locationService, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            border: Border(bottom: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.3))),
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
                'Resources for: ${locationService.getLocationDisplayText()}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search resources...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Category Filter
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip('All', null),
                ...AppConstants.resourceCategories.map((category) {
                  return _buildCategoryChip(category, category);
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? value) {
    final isSelected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? value : null;
          });
        },
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
      ),
    );
  }

  Widget _buildResourcesList() {
    final filteredResources = _getFilteredResources();
    
    if (filteredResources.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredResources.length,
      itemBuilder: (context, index) {
        final resource = filteredResources[index];
        return _buildResourceCard(resource);
      },
    );
  }

  Widget _buildResourceCard(Resource resource) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getCategoryIcon(resource.typeDisplayName),
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    resource.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (resource.type == ResourceType.emergency || resource.is24Hours)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Emergency',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Text(
              resource.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            const SizedBox(height: 8),
            
            if (resource.address != null && resource.address!.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    resource.address!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            // Action Buttons
            Row(
              children: [
                if (resource.phone != null && resource.phone!.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => _makeCall(resource.phone!),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(80, 32),
                    ),
                  ),
                const SizedBox(width: 8),
                if (resource.website != null && resource.website!.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _launchWebsite(resource.website!),
                    icon: const Icon(Icons.language, size: 16),
                    label: const Text('Website'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(80, 32),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or category filter',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedCategory = null;
                _searchQuery = '';
              });
            },
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  List<Resource> _getFilteredResources() {
    final locationService = Provider.of<LocationService>(context, listen: false);
    
    // Get location-based resources
    List<Resource> allResources = [];
    
    if (locationService.isInGhana) {
      allResources = LocationBasedResources.getGhanaResources();
    } else if (locationService.isInUSA) {
      allResources = LocationBasedResources.getUSAResources(locationService.currentState);
    } else {
      allResources = LocationBasedResources.getInternationalResources();
    }

    // Filter by category
    if (_selectedCategory != null) {
      allResources = allResources.where((resource) => 
          resource.typeDisplayName == _selectedCategory).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      allResources = allResources.where((resource) =>
          resource.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          resource.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          resource.typeDisplayName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    return allResources;
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Shelter & Housing':
        return Icons.home;
      case 'Legal Support':
        return Icons.gavel;
      case 'Mental Health':
        return Icons.psychology;
      case 'Healthcare':
        return Icons.local_hospital;
      case 'Crisis Support':
        return Icons.support_agent;
      case 'Emergency Services':
        return Icons.emergency;
      case 'Government Services':
        return Icons.account_balance;
      default:
        return Icons.help;
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

  Future<void> _launchWebsite(String url) async {
    final Uri launchUri = Uri.parse(url);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }
}