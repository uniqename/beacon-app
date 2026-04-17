import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/safety_plan.dart';
import '../../services/safety_plan_service.dart';

class EmergencyContactsScreen extends StatefulWidget {
  final String userId;

  const EmergencyContactsScreen({super.key, required this.userId});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
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

      // Create new plan if it doesn't exist
      plan ??= await _service.createSafetyPlan(widget.userId);

      setState(() {
        _safetyPlan = plan;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading contacts: $e')),
        );
      }
    }
  }

  Future<void> _saveContact(EmergencyContact contact) async {
    if (_safetyPlan == null) return;

    final updatedContacts = List<EmergencyContact>.from(_safetyPlan!.emergencyContacts)..add(contact);
    final updatedPlan = _safetyPlan!.copyWith(
      emergencyContacts: updatedContacts,
      updatedAt: DateTime.now(),
    );

    await _service.updateSafetyPlan(updatedPlan);
    await _loadSafetyPlan();
  }

  Future<void> _updateContact(int index, EmergencyContact contact) async {
    if (_safetyPlan == null) return;

    final updatedContacts = List<EmergencyContact>.from(_safetyPlan!.emergencyContacts);
    updatedContacts[index] = contact;

    final updatedPlan = _safetyPlan!.copyWith(
      emergencyContacts: updatedContacts,
      updatedAt: DateTime.now(),
    );

    await _service.updateSafetyPlan(updatedPlan);
    await _loadSafetyPlan();
  }

  Future<void> _deleteContact(int index) async {
    if (_safetyPlan == null) return;

    final updatedContacts = List<EmergencyContact>.from(_safetyPlan!.emergencyContacts)..removeAt(index);
    final updatedPlan = _safetyPlan!.copyWith(
      emergencyContacts: updatedContacts,
      updatedAt: DateTime.now(),
    );

    await _service.updateSafetyPlan(updatedPlan);
    await _loadSafetyPlan();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not make call to $phoneNumber')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Emergency Contacts'),
          backgroundColor: Colors.red[600],
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final contacts = _safetyPlan?.emergencyContacts ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency Contacts'),
        backgroundColor: Colors.red[600],
      ),
      body: contacts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.contacts, size: 80, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    'No emergency contacts yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add trusted people who can help in an emergency',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red[600],
                      child: Text(
                        contact.name[0].toUpperCase(),
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      contact.name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${contact.relationship} • ${contact.phone}'),
                        if (contact.isTrusted)
                          Row(
                            children: [
                              Icon(Icons.verified, size: 14, color: Colors.green),
                              SizedBox(width: 4),
                              Text('Trusted', style: TextStyle(color: Colors.green, fontSize: 12)),
                            ],
                          ),
                        if (contact.canProvideShelter)
                          Row(
                            children: [
                              Icon(Icons.home, size: 14, color: Colors.blue),
                              SizedBox(width: 4),
                              Text('Can provide shelter', style: TextStyle(color: Colors.blue, fontSize: 12)),
                            ],
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.phone, color: Colors.green),
                          onPressed: () => _makePhoneCall(contact.phone),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showAddContactDialog(existingContact: contact, index: index);
                            } else if (value == 'delete') {
                              _confirmDelete(index);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddContactDialog(),
        icon: Icon(Icons.add),
        label: Text('Add Contact'),
        backgroundColor: Colors.red[600],
      ),
    );
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Contact?'),
        content: Text('Are you sure you want to remove this emergency contact?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteContact(index);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Contact deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog({EmergencyContact? existingContact, int? index}) {
    final nameController = TextEditingController(text: existingContact?.name ?? '');
    final phoneController = TextEditingController(text: existingContact?.phone ?? '');
    final relationshipController = TextEditingController(text: existingContact?.relationship ?? '');
    bool isTrusted = existingContact?.isTrusted ?? false;
    bool canProvideShelter = existingContact?.canProvideShelter ?? false;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existingContact == null ? 'Add Emergency Contact' : 'Edit Contact'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person),
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
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                      hintText: 'e.g. 0241234567',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a phone number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: relationshipController,
                    decoration: InputDecoration(
                      labelText: 'Relationship',
                      prefixIcon: Icon(Icons.people),
                      border: OutlineInputBorder(),
                      hintText: 'e.g. Friend, Family, Counselor',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter relationship';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  CheckboxListTile(
                    title: Text('Trusted Contact'),
                    subtitle: Text('This person knows about your situation'),
                    value: isTrusted,
                    onChanged: (value) {
                      setDialogState(() => isTrusted = value ?? false);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  CheckboxListTile(
                    title: Text('Can Provide Shelter'),
                    subtitle: Text('This person can offer a safe place to stay'),
                    value: canProvideShelter,
                    onChanged: (value) {
                      setDialogState(() => canProvideShelter = value ?? false);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
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
                  final contact = EmergencyContact(
                    id: existingContact?.id ?? 'contact_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    relationship: relationshipController.text.trim(),
                    isTrusted: isTrusted,
                    canProvideShelter: canProvideShelter,
                  );

                  Navigator.pop(context);

                  if (existingContact == null) {
                    await _saveContact(contact);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Contact added successfully')),
                      );
                    }
                  } else if (index != null) {
                    await _updateContact(index, contact);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Contact updated successfully')),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
              child: Text(existingContact == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    ).then((_) {
      nameController.dispose();
      phoneController.dispose();
      relationshipController.dispose();
    });
  }
}
