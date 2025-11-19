import 'package:flutter/material.dart';
import '../../models/beacon_division.dart';
import '../../services/smart_ai_service.dart';

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({Key? key}) : super(key: key);

  @override
  _ManageServicesScreenState createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  List<BeaconDivision> _divisions = [];
  List<ServiceItem> _allServices = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final divisions = SmartAIService.smartResourceRouting(
      helpType: 'all',
      urgency: 'normal',
      location: 'all',
    );
    
    List<ServiceItem> services = [];
    for (BeaconDivision division in divisions) {
      for (String service in division.services) {
        services.add(ServiceItem(
          name: service,
          division: division,
          isActive: true,
        ));
      }
    }
    
    setState(() {
      _divisions = divisions;
      _allServices = services;
      _isLoading = false;
    });
  }

  List<ServiceItem> get _filteredServices {
    if (_searchQuery.isEmpty) return _allServices;
    return _allServices.where((service) =>
      service.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      service.division.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Manage Services',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF2E8B57),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search services...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF2E8B57)))
          : Column(
              children: [
                _buildSummaryCard(),
                Expanded(child: _buildServicesList()),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddServiceDialog,
        backgroundColor: Color(0xFF2E8B57),
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Service',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    int totalServices = _allServices.length;
    int activeDivisions = _divisions.where((d) => d.isAvailable).length;
    
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.teal[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.medical_services, color: Colors.green[700], size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalServices Total Services',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Across $activeDivisions active divisions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList() {
    List<ServiceItem> filteredServices = _filteredServices;
    
    if (filteredServices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No services found' : 'No matching services',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty 
                  ? 'Add your first service to get started'
                  : 'Try adjusting your search terms',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredServices.length,
      itemBuilder: (context, index) {
        ServiceItem service = filteredServices[index];
        return _buildServiceCard(service);
      },
    );
  }

  Widget _buildServiceCard(ServiceItem service) {
    Color divisionColor = Color(int.parse(service.division.color.replaceFirst('#', '0xFF')));

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _showServiceDetails(service),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: divisionColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.medical_services,
                        color: divisionColor,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            service.division.name,
                            style: TextStyle(
                              fontSize: 13,
                              color: divisionColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: service.isActive ? Colors.green[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        service.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 11,
                          color: service.isActive ? Colors.green[700] : Colors.red[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                          value: 'edit',
                        ),
                        PopupMenuItem(
                          child: Row(
                            children: [
                              Icon(
                                service.isActive ? Icons.pause : Icons.play_arrow,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(service.isActive ? 'Deactivate' : 'Activate'),
                            ],
                          ),
                          value: 'toggle',
                        ),
                        PopupMenuItem(
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                          value: 'delete',
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditServiceDialog(service);
                        } else if (value == 'toggle') {
                          _toggleServiceStatus(service);
                        } else if (value == 'delete') {
                          _showDeleteConfirmation(service);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showServiceDetails(ServiceItem service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.medical_services, size: 32, color: Color(0xFF2E8B57)),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        service.division.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: service.isActive ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    service.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      fontSize: 12,
                      color: service.isActive ? Colors.green[700] : Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildDetailRow('Division', service.division.name),
            _buildDetailRow('Contact Email', service.division.contactEmail),
            _buildDetailRow('Contact Phone', service.division.contactPhone),
            _buildDetailRow('Status', service.isActive ? 'Active' : 'Inactive'),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditServiceDialog(service);
                    },
                    icon: Icon(Icons.edit, size: 16),
                    label: Text('Edit Service'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2E8B57),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _toggleServiceStatus(service);
                    },
                    icon: Icon(
                      service.isActive ? Icons.pause : Icons.play_arrow,
                      size: 16,
                    ),
                    label: Text(service.isActive ? 'Deactivate' : 'Activate'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Color(0xFF2E8B57)),
                      foregroundColor: Color(0xFF2E8B57),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddServiceDialog() {
    _showServiceFormDialog(null);
  }

  void _showEditServiceDialog(ServiceItem service) {
    _showServiceFormDialog(service);
  }

  void _showServiceFormDialog(ServiceItem? service) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: service?.name ?? '');
    BeaconDivision? selectedDivision = service?.division ?? _divisions.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(service == null ? 'Add New Service' : 'Edit Service'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Service Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Name is required';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<BeaconDivision>(
                  value: selectedDivision,
                  decoration: InputDecoration(
                    labelText: 'Division',
                    border: OutlineInputBorder(),
                  ),
                  items: _divisions.map((division) => DropdownMenuItem(
                    value: division,
                    child: Text(division.name),
                  )).toList(),
                  onChanged: (division) {
                    setState(() {
                      selectedDivision = division;
                    });
                  },
                  validator: (value) {
                    if (value == null) return 'Division is required';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate() && selectedDivision != null) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(service == null 
                          ? 'Service created successfully!' 
                          : 'Service updated successfully!'),
                    ),
                  );
                  _loadData();
                }
              },
              child: Text(service == null ? 'Create' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleServiceStatus(ServiceItem service) {
    setState(() {
      service.isActive = !service.isActive;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Service ${service.isActive ? 'activated' : 'deactivated'}'),
      ),
    );
  }

  void _showDeleteConfirmation(ServiceItem service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[600]),
            SizedBox(width: 12),
            Text('Confirm Delete'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${service.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _allServices.remove(service);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Service "${service.name}" deleted successfully!'),
                  backgroundColor: Colors.red[600],
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class ServiceItem {
  final String name;
  final BeaconDivision division;
  bool isActive;

  ServiceItem({
    required this.name,
    required this.division,
    required this.isActive,
  });
}