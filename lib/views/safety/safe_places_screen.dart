import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/safety_plan.dart';
import '../../services/safety_plan_service.dart';

class SafePlacesScreen extends StatefulWidget {
  final String userId;

  const SafePlacesScreen({super.key, required this.userId});

  @override
  State<SafePlacesScreen> createState() => _SafePlacesScreenState();
}

class _SafePlacesScreenState extends State<SafePlacesScreen> {
  final SafetyPlanService _service = SafetyPlanService();
  SafetyPlan? _safetyPlan;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSafetyPlan();
  }

  Future<void> _loadSafetyPlan() async {
    setState(() => _isLoading = true);

    try {
      var plan = await _service.getSafetyPlan(widget.userId);
      plan ??= await _service.createSafetyPlan(widget.userId);

      setState(() {
        _safetyPlan = plan;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading safe places: $e')),
        );
      }
    }
  }

  Future<void> _saveSafePlace(SafePlace place) async {
    if (_safetyPlan == null) return;

    final updatedPlaces = List<SafePlace>.from(_safetyPlan!.safePlaces)..add(place);
    final updatedPlan = _safetyPlan!.copyWith(
      safePlaces: updatedPlaces,
      updatedAt: DateTime.now(),
    );

    await _service.updateSafetyPlan(updatedPlan);
    await _loadSafetyPlan();
  }

  Future<void> _updateSafePlace(int index, SafePlace place) async {
    if (_safetyPlan == null) return;

    final updatedPlaces = List<SafePlace>.from(_safetyPlan!.safePlaces);
    updatedPlaces[index] = place;

    final updatedPlan = _safetyPlan!.copyWith(
      safePlaces: updatedPlaces,
      updatedAt: DateTime.now(),
    );

    await _service.updateSafetyPlan(updatedPlan);
    await _loadSafetyPlan();
  }

  Future<void> _deleteSafePlace(int index) async {
    if (_safetyPlan == null) return;

    final updatedPlaces = List<SafePlace>.from(_safetyPlan!.safePlaces)..removeAt(index);
    final updatedPlan = _safetyPlan!.copyWith(
      safePlaces: updatedPlaces,
      updatedAt: DateTime.now(),
    );

    await _service.updateSafetyPlan(updatedPlan);
    await _loadSafetyPlan();
  }

  Future<void> _openInMaps(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Safe Places'),
          backgroundColor: Colors.blue[600],
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final places = _safetyPlan?.safePlaces ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Safe Places'),
        backgroundColor: Colors.blue[600],
      ),
      body: places.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.place, size: 80, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    'No safe places added yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Add places where you can go if you need to leave quickly or feel unsafe',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: places.length,
              itemBuilder: (context, index) {
                final place = places[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[600],
                      child: Icon(Icons.place, color: Colors.white),
                    ),
                    title: Text(
                      place.name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(place.address),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (place.operatingHours != null) ...[
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Hours: ${place.operatingHours}',
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                            ],
                            if (place.notes != null) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.notes, size: 16, color: Colors.grey[600]),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      place.notes!,
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _openInMaps(place.address),
                                  icon: Icon(Icons.directions),
                                  label: Text('Directions'),
                                ),
                                SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _showAddPlaceDialog(existingPlace: place, index: index),
                                  icon: Icon(Icons.edit),
                                  label: Text('Edit'),
                                ),
                                SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _confirmDelete(index, place.name),
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  label: Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPlaceDialog(),
        icon: Icon(Icons.add_location),
        label: Text('Add Place'),
        backgroundColor: Colors.blue[600],
      ),
    );
  }

  void _confirmDelete(int index, String placeName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Safe Place?'),
        content: Text('Are you sure you want to remove "$placeName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSafePlace(index);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Safe place removed')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddPlaceDialog({SafePlace? existingPlace, int? index}) {
    final nameController = TextEditingController(text: existingPlace?.name ?? '');
    final addressController = TextEditingController(text: existingPlace?.address ?? '');
    final hoursController = TextEditingController(text: existingPlace?.operatingHours ?? '');
    final notesController = TextEditingController(text: existingPlace?.notes ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingPlace == null ? 'Add Safe Place' : 'Edit Safe Place'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Place Name*',
                    hintText: 'e.g., Friend\'s House, Shelter, Police Station',
                    prefixIcon: Icon(Icons.label),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: 'Address*',
                    hintText: 'Full address or area name',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: hoursController,
                  decoration: InputDecoration(
                    labelText: 'Operating Hours (Optional)',
                    hintText: 'e.g., 24/7, Mon-Fri 9AM-5PM',
                    prefixIcon: Icon(Icons.access_time),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'Additional information about this place',
                    prefixIcon: Icon(Icons.notes),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
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
                final place = SafePlace(
                  id: existingPlace?.id ?? 'place_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text.trim(),
                  address: addressController.text.trim(),
                  operatingHours: hoursController.text.trim().isEmpty ? null : hoursController.text.trim(),
                  notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                );

                Navigator.pop(context);

                if (existingPlace == null) {
                  await _saveSafePlace(place);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Safe place added')),
                    );
                  }
                } else if (index != null) {
                  await _updateSafePlace(index, place);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Safe place updated')),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600]),
            child: Text(existingPlace == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    ).then((_) {
      nameController.dispose();
      addressController.dispose();
      hoursController.dispose();
      notesController.dispose();
    });
  }
}
