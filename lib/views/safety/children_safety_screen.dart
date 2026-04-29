import 'package:flutter/material.dart';
import '../../models/safety_plan.dart';
import '../../services/safety_plan_service.dart';

class ChildrenSafetyScreen extends StatefulWidget {
  final String userId;

  const ChildrenSafetyScreen({super.key, required this.userId});

  @override
  State<ChildrenSafetyScreen> createState() => _ChildrenSafetyScreenState();
}

class _ChildrenSafetyScreenState extends State<ChildrenSafetyScreen> {
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
          SnackBar(content: Text('Error loading children data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Children Safety'),
          backgroundColor: Colors.pink[400],
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final children = _safetyPlan?.children ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Children Safety'),
        backgroundColor: Colors.pink[400],
      ),
      body: children.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.child_care, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No children added yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  SizedBox(height: 8),
                  Text('Add children to create safety plans for them', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: children.length,
              itemBuilder: (context, index) {
                final child = children[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.pink[100],
                      child: Text(child.name[0], style: TextStyle(color: Colors.pink[700])),
                    ),
                    title: Text(child.name, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Age: ${child.age}${child.school.isNotEmpty ? " • ${child.school}" : ""}'),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (child.specialNeeds.isNotEmpty) ...[
                              Text('Special Needs:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink[700])),
                              SizedBox(height: 4),
                              Text(child.specialNeeds),
                              SizedBox(height: 12),
                            ],
                            if (child.medicationsAndAllergies.isNotEmpty) ...[
                              Text('Medications & Allergies:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink[700])),
                              SizedBox(height: 4),
                              Text(child.medicationsAndAllergies),
                              SizedBox(height: 12),
                            ],
                            if (child.schoolAddress.isNotEmpty) ...[
                              Text('School Address:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink[700])),
                              SizedBox(height: 4),
                              Text(child.schoolAddress),
                              SizedBox(height: 12),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _editChild(index),
                                  icon: Icon(Icons.edit, size: 18),
                                  label: Text('Edit'),
                                ),
                                TextButton.icon(
                                  onPressed: () => _deleteChild(index),
                                  icon: Icon(Icons.delete, size: 18, color: Colors.red),
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
        onPressed: _showAddChildDialog,
        icon: Icon(Icons.add),
        label: Text('Add Child'),
        backgroundColor: Colors.pink[400],
      ),
    );
  }

  void _showAddChildDialog({Child? existingChild, int? index}) {
    final nameController = TextEditingController(text: existingChild?.name ?? '');
    final ageController = TextEditingController(text: existingChild?.age.toString() ?? '');
    final schoolController = TextEditingController(text: existingChild?.school ?? '');
    final schoolAddressController = TextEditingController(text: existingChild?.schoolAddress ?? '');
    final specialNeedsController = TextEditingController(text: existingChild?.specialNeeds ?? '');
    final medicationsController = TextEditingController(text: existingChild?.medicationsAndAllergies ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingChild == null ? 'Add Child' : 'Edit Child'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: ageController,
                decoration: InputDecoration(
                  labelText: 'Age *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cake),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 12),
              TextField(
                controller: schoolController,
                decoration: InputDecoration(
                  labelText: 'School',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: schoolAddressController,
                decoration: InputDecoration(
                  labelText: 'School Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 12),
              TextField(
                controller: specialNeedsController,
                decoration: InputDecoration(
                  labelText: 'Special Needs',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.accessibility),
                  helperText: 'Any special care or attention required',
                ),
                maxLines: 2,
              ),
              SizedBox(height: 12),
              TextField(
                controller: medicationsController,
                decoration: InputDecoration(
                  labelText: 'Medications & Allergies',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medication),
                  helperText: 'Important medical information',
                ),
                maxLines: 2,
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
              if (nameController.text.trim().isEmpty || ageController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Name and age are required')),
                );
                return;
              }

              final child = Child(
                id: existingChild?.id ?? 'child_${DateTime.now().millisecondsSinceEpoch}',
                name: nameController.text.trim(),
                age: int.tryParse(ageController.text) ?? 0,
                school: schoolController.text.trim(),
                schoolAddress: schoolAddressController.text.trim(),
                specialNeeds: specialNeedsController.text.trim(),
                medicationsAndAllergies: medicationsController.text.trim(),
              );

              Navigator.pop(context);
              _saveChild(child, index);
            },
            child: Text(existingChild == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChild(Child child, int? index) async {
    if (_safetyPlan == null) return;

    final updatedChildren = List<Child>.from(_safetyPlan!.children);
    if (index != null) {
      updatedChildren[index] = child;
    } else {
      updatedChildren.add(child);
    }

    final updatedPlan = _safetyPlan!.copyWith(
      children: updatedChildren,
      updatedAt: DateTime.now(),
    );

    try {
      await _service.updateSafetyPlan(updatedPlan);
      await _loadSafetyPlan();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(index == null ? 'Child added' : 'Child updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editChild(int index) {
    final children = _safetyPlan?.children ?? [];
    if (index < children.length) {
      _showAddChildDialog(existingChild: children[index], index: index);
    }
  }

  void _deleteChild(int index) {
    final children = _safetyPlan?.children ?? [];
    if (index >= children.length) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Child'),
        content: Text('Remove ${children[index].name} from safety plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              if (_safetyPlan == null) return;

              final updatedChildren = List<Child>.from(_safetyPlan!.children)..removeAt(index);
              final updatedPlan = _safetyPlan!.copyWith(
                children: updatedChildren,
                updatedAt: DateTime.now(),
              );

              try {
                await _service.updateSafetyPlan(updatedPlan);
                await _loadSafetyPlan();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Child removed')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}
