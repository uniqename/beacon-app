import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/beacon_division.dart';
import '../../services/local_database_service.dart';

class ManageDivisionsScreen extends StatefulWidget {
  const ManageDivisionsScreen({super.key});

  @override
  _ManageDivisionsScreenState createState() => _ManageDivisionsScreenState();
}

class _ManageDivisionsScreenState extends State<ManageDivisionsScreen> {
  List<BeaconDivision> _divisions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDivisions();
  }

  Future<void> _loadDivisions() async {
    setState(() => _isLoading = true);
    try {
      final db = await LocalDatabaseService.database;
      final results = await db.query('beacon_divisions', orderBy: 'name ASC');
      setState(() {
        _divisions = results.map((row) => BeaconDivision(
          id: row['id'] as String,
          name: row['name'] as String,
          shortName: row['short_name'] as String? ?? '',
          description: row['description'] as String? ?? '',
          icon: row['icon'] as String? ?? '🏥',
          color: row['color'] as String? ?? '#2E8B57',
          contactEmail: row['contact_email'] as String? ?? '',
          contactPhone: row['contact_phone'] as String? ?? '',
          isAvailable: (row['is_available'] as int? ?? 1) == 1,
          capacity: row['capacity'] as int? ?? 50,
          services: [],
          resources: [],
          donationUrl: '',
          jobOpenings: [],
        )).toList();
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error loading divisions: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Manage Divisions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFFF0562D),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Implement search
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFF0562D)))
          : Column(
              children: [
                _buildSummaryCard(),
                Expanded(child: _buildDivisionsList()),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDivisionDialog,
        backgroundColor: Color(0xFFF0562D),
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Division',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.indigo[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.business, color: Colors.blue[700], size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Divisions: ${_divisions.length}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Active services across all divisions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivisionsList() {
    if (_divisions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_center, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No divisions found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add your first division to get started',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: _divisions.length,
      itemBuilder: (context, index) {
        BeaconDivision division = _divisions[index];
        return _buildDivisionCard(division);
      },
    );
  }

  Widget _buildDivisionCard(BeaconDivision division) {
    Color cardColor = Color(int.parse(division.color.replaceFirst('#', '0xFF')));

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _showDivisionDetails(division),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        division.icon,
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            division.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: cardColor,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            division.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditDivisionDialog(division);
                        } else if (value == 'delete') {
                          _showDeleteConfirmation(division);
                        }
                      },
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip(
                      '${division.services.length} Services',
                      Icons.medical_services,
                      Colors.blue,
                    ),
                    SizedBox(width: 8),
                    _buildInfoChip(
                      '${division.jobOpenings.length} Jobs',
                      Icons.work,
                      Colors.green,
                    ),
                    SizedBox(width: 8),
                    _buildInfoChip(
                      division.isAvailable ? 'Available' : 'Limited',
                      division.isAvailable ? Icons.check_circle : Icons.access_time,
                      division.isAvailable ? Colors.green : Colors.orange,
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

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showDivisionDetails(BeaconDivision division) {
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
                Text(
                  division.icon,
                  style: TextStyle(fontSize: 32),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        division.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        division.shortName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Description:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(division.description),
            SizedBox(height: 16),
            Text(
              'Contact Information:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text('Email: ${division.contactEmail}'),
            Text('Phone: ${division.contactPhone}'),
            SizedBox(height: 16),
            Text(
              'Services (${division.services.length}):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            ...division.services.take(3).map((service) => Text('• $service')),
            if (division.services.length > 3)
              Text('• ... and ${division.services.length - 3} more'),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAddDivisionDialog() {
    _showDivisionFormDialog(null);
  }

  void _showEditDivisionDialog(BeaconDivision division) {
    _showDivisionFormDialog(division);
  }

  void _showDivisionFormDialog(BeaconDivision? division) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: division?.name ?? '');
    final shortNameController = TextEditingController(text: division?.shortName ?? '');
    final descriptionController = TextEditingController(text: division?.description ?? '');
    final contactEmailController = TextEditingController(text: division?.contactEmail ?? '');
    final contactPhoneController = TextEditingController(text: division?.contactPhone ?? '');
    final iconController = TextEditingController(text: division?.icon ?? '🏥');
    String selectedColor = division?.color ?? '#2E8B57';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(division == null ? 'Add New Division' : 'Edit Division'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Division Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Name is required';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: shortNameController,
                  decoration: InputDecoration(
                    labelText: 'Short Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Short name is required';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Description is required';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: contactEmailController,
                  decoration: InputDecoration(
                    labelText: 'Contact Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Email is required';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: contactPhoneController,
                  decoration: InputDecoration(
                    labelText: 'Contact Phone',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Phone is required';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: iconController,
                  decoration: InputDecoration(
                    labelText: 'Icon (Emoji)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Icon is required';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final db = await LocalDatabaseService.database;
                  final now = DateTime.now().toIso8601String();
                  if (division == null) {
                    await db.insert('beacon_divisions', {
                      'id': const Uuid().v4(),
                      'name': nameController.text.trim(),
                      'short_name': shortNameController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'icon': iconController.text.trim(),
                      'color': selectedColor,
                      'contact_email': contactEmailController.text.trim(),
                      'contact_phone': contactPhoneController.text.trim(),
                      'is_available': 1,
                      'capacity': 50,
                      'created_at': now,
                      'updated_at': now,
                    });
                  } else {
                    await db.update('beacon_divisions', {
                      'name': nameController.text.trim(),
                      'short_name': shortNameController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'icon': iconController.text.trim(),
                      'color': selectedColor,
                      'contact_email': contactEmailController.text.trim(),
                      'contact_phone': contactPhoneController.text.trim(),
                      'updated_at': now,
                    }, where: 'id = ?', whereArgs: [division.id]);
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(division == null ? 'Division created!' : 'Division updated!'),
                      backgroundColor: Colors.green,
                    ));
                    _loadDivisions();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ));
                }
              }
            },
            child: Text(division == null ? 'Create' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BeaconDivision division) {
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
          'Are you sure you want to delete "${division.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final db = await LocalDatabaseService.database;
                await db.delete('beacon_divisions', where: 'id = ?', whereArgs: [division.id]);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('"${division.name}" deleted'),
                    backgroundColor: Colors.red[600],
                  ));
                  _loadDivisions();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}