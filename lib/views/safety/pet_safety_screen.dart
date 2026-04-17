import 'package:flutter/material.dart';
import '../../models/safety_plan.dart';
import '../../services/safety_plan_service.dart';

class PetSafetyScreen extends StatefulWidget {
  final String userId;

  const PetSafetyScreen({super.key, required this.userId});

  @override
  State<PetSafetyScreen> createState() => _PetSafetyScreenState();
}

class _PetSafetyScreenState extends State<PetSafetyScreen> {
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
          SnackBar(content: Text('Error loading pet data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Pet Safety'),
          backgroundColor: Colors.brown[400],
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pets = _safetyPlan?.pets ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Pet Safety'),
        backgroundColor: Colors.brown[400],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.amber[50],
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber[700]),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Plan for your pets\' safety during an emergency. Many shelters accept pets.',
                    style: TextStyle(color: Colors.amber[900]),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: pets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pets, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No pets added yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                        SizedBox(height: 8),
                        Text('Add your pets to plan for their safety', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: pets.length,
                    itemBuilder: (context, index) {
                      final pet = pets[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.brown[100],
                            child: Icon(_getPetIcon(pet.type), color: Colors.brown[700]),
                          ),
                          title: Text(pet.name, style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${pet.type} • ${pet.breed}'),
                              if (pet.specialNeeds.isNotEmpty) ...[
                                SizedBox(height: 4),
                                Text('Special needs: ${pet.specialNeeds}', style: TextStyle(color: Colors.red[700], fontSize: 12)),
                              ],
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editPet(index);
                              } else if (value == 'delete') {
                                _deletePet(index);
                              }
                            },
                          ),
                          isThreeLine: pet.specialNeeds.isNotEmpty,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPetDialog,
        icon: Icon(Icons.add),
        label: Text('Add Pet'),
        backgroundColor: Colors.brown[400],
      ),
    );
  }

  IconData _getPetIcon(String type) {
    switch (type.toLowerCase()) {
      case 'dog':
        return Icons.pets;
      case 'cat':
        return Icons.pets;
      case 'bird':
        return Icons.flutter_dash;
      case 'fish':
        return Icons.water;
      case 'rabbit':
        return Icons.pets;
      default:
        return Icons.pets;
    }
  }

  void _showAddPetDialog({Pet? existingPet, int? index}) {
    final nameController = TextEditingController(text: existingPet?.name ?? '');
    final breedController = TextEditingController(text: existingPet?.breed ?? '');
    final specialNeedsController = TextEditingController(text: existingPet?.specialNeeds ?? '');
    String selectedType = existingPet?.type ?? 'Dog';

    final petTypes = ['Dog', 'Cat', 'Bird', 'Fish', 'Rabbit', 'Other'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existingPet == null ? 'Add Pet' : 'Edit Pet'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Pet Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.pets),
                  ),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: InputDecoration(
                    labelText: 'Type *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: petTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                  onChanged: (value) => setDialogState(() => selectedType = value!),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: breedController,
                  decoration: InputDecoration(
                    labelText: 'Breed',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: specialNeedsController,
                  decoration: InputDecoration(
                    labelText: 'Special Needs/Medications',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.medical_services),
                    helperText: 'Medications, diet restrictions, medical conditions',
                  ),
                  maxLines: 3,
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
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Pet name is required')),
                  );
                  return;
                }

                final pet = Pet(
                  id: existingPet?.id ?? 'pet_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text.trim(),
                  type: selectedType,
                  breed: breedController.text.trim(),
                  specialNeeds: specialNeedsController.text.trim(),
                );

                Navigator.pop(context);
                _savePet(pet, index);
              },
              child: Text(existingPet == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePet(Pet pet, int? index) async {
    if (_safetyPlan == null) return;

    final updatedPets = List<Pet>.from(_safetyPlan!.pets);
    if (index != null) {
      updatedPets[index] = pet;
    } else {
      updatedPets.add(pet);
    }

    final updatedPlan = _safetyPlan!.copyWith(
      pets: updatedPets,
      updatedAt: DateTime.now(),
    );

    try {
      await _service.updateSafetyPlan(updatedPlan);
      await _loadSafetyPlan();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(index == null ? 'Pet added' : 'Pet updated'),
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

  void _editPet(int index) {
    final pets = _safetyPlan?.pets ?? [];
    if (index < pets.length) {
      _showAddPetDialog(existingPet: pets[index], index: index);
    }
  }

  void _deletePet(int index) {
    final pets = _safetyPlan?.pets ?? [];
    if (index >= pets.length) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Pet'),
        content: Text('Remove ${pets[index].name} from safety plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              if (_safetyPlan == null) return;

              final updatedPets = List<Pet>.from(_safetyPlan!.pets)..removeAt(index);
              final updatedPlan = _safetyPlan!.copyWith(
                pets: updatedPets,
                updatedAt: DateTime.now(),
              );

              try {
                await _service.updateSafetyPlan(updatedPlan);
                await _loadSafetyPlan();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Pet removed')),
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
