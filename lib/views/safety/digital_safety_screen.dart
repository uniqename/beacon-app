import 'package:flutter/material.dart';
import '../../models/safety_plan.dart';
import '../../services/safety_plan_service.dart';

class DigitalSafetyScreen extends StatefulWidget {
  final String userId;

  const DigitalSafetyScreen({super.key, required this.userId});

  @override
  State<DigitalSafetyScreen> createState() => _DigitalSafetyScreenState();
}

class _DigitalSafetyScreenState extends State<DigitalSafetyScreen> {
  final SafetyPlanService _service = SafetyPlanService();
  SafetyPlan? _safetyPlan;
  bool _isLoading = true;
  bool _isSaving = false;
  final TextEditingController _notesController = TextEditingController();

  DigitalSafetyPlan _plan = DigitalSafetyPlan(
    hasChangedPasswords: false,
    hasSecuredDevices: false,
    hasDisabledLocationSharing: false,
    hasReviewedPrivacySettings: false,
    hasBackedUpImportantData: false,
    notes: '',
  );

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
        _plan = plan!.digitalSafety ?? DigitalSafetyPlan(
          hasChangedPasswords: false,
          hasSecuredDevices: false,
          hasDisabledLocationSharing: false,
          hasReviewedPrivacySettings: false,
          hasBackedUpImportantData: false,
          notes: '',
        );
        _notesController.text = _plan.notes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading digital safety data: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _securityChecklist = [
    {
      'key': 'hasChangedPasswords',
      'title': 'Change Important Passwords',
      'description': 'Update passwords for email, banking, social media, and other critical accounts',
      'icon': Icons.password,
      'color': Colors.red,
    },
    {
      'key': 'hasSecuredDevices',
      'title': 'Secure Your Devices',
      'description': 'Enable biometric locks, set strong PINs, and enable device encryption',
      'icon': Icons.phone_android,
      'color': Colors.blue,
    },
    {
      'key': 'hasDisabledLocationSharing',
      'title': 'Disable Location Sharing',
      'description': 'Turn off location sharing in apps, photos, and social media',
      'icon': Icons.location_off,
      'color': Colors.orange,
    },
    {
      'key': 'hasReviewedPrivacySettings',
      'title': 'Review Privacy Settings',
      'description': 'Check who can see your posts, location, and personal information',
      'icon': Icons.privacy_tip,
      'color': Colors.purple,
    },
    {
      'key': 'hasBackedUpImportantData',
      'title': 'Backup Important Data',
      'description': 'Save photos, documents, and important information to secure cloud storage',
      'icon': Icons.backup,
      'color': Colors.green,
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Digital Safety'),
          backgroundColor: Colors.indigo[600],
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final completedTasks = _getCompletedCount();
    final totalTasks = _securityChecklist.length;
    final completionPercentage = (completedTasks / totalTasks * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: Text('Digital Safety'),
        backgroundColor: Colors.indigo[600],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.indigo[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.security, color: Colors.indigo[700], size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Protect Your Digital Privacy',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo[900]),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  'Follow these steps to secure your online presence and prevent digital stalking or tracking.',
                  style: TextStyle(color: Colors.indigo[800]),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: completedTasks / totalTasks,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo[600]!),
                        minHeight: 8,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      '$completionPercentage%',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo[700]),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  '$completedTasks of $totalTasks tasks completed',
                  style: TextStyle(fontSize: 12, color: Colors.indigo[600]),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _securityChecklist.length,
              itemBuilder: (context, index) {
                final item = _securityChecklist[index];
                final isCompleted = _getChecklistValue(item['key']);

                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  elevation: isCompleted ? 1 : 2,
                  child: CheckboxListTile(
                    value: isCompleted,
                    onChanged: (value) => _updateChecklistItem(item['key'], value ?? false),
                    secondary: CircleAvatar(
                      backgroundColor: isCompleted ? Colors.green[100] : (item['color'] as Color).withValues(alpha: 0.2),
                      child: Icon(
                        isCompleted ? Icons.check : item['icon'],
                        color: isCompleted ? Colors.green[700] : item['color'],
                      ),
                    ),
                    title: Text(
                      item['title'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted ? Colors.grey : Colors.black,
                      ),
                    ),
                    subtitle: Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        item['description'],
                        style: TextStyle(
                          color: isCompleted ? Colors.grey : Colors.grey[700],
                        ),
                      ),
                    ),
                    isThreeLine: true,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Additional Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add any specific digital safety concerns or steps you\'ve taken...',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) {
                    _plan = DigitalSafetyPlan(
                      hasChangedPasswords: _plan.hasChangedPasswords,
                      hasSecuredDevices: _plan.hasSecuredDevices,
                      hasDisabledLocationSharing: _plan.hasDisabledLocationSharing,
                      hasReviewedPrivacySettings: _plan.hasReviewedPrivacySettings,
                      hasBackedUpImportantData: _plan.hasBackedUpImportantData,
                      notes: value,
                    );
                  },
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _savePlan,
                    icon: _isSaving ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Save Digital Safety Plan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[600],
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _getChecklistValue(String key) {
    switch (key) {
      case 'hasChangedPasswords':
        return _plan.hasChangedPasswords;
      case 'hasSecuredDevices':
        return _plan.hasSecuredDevices;
      case 'hasDisabledLocationSharing':
        return _plan.hasDisabledLocationSharing;
      case 'hasReviewedPrivacySettings':
        return _plan.hasReviewedPrivacySettings;
      case 'hasBackedUpImportantData':
        return _plan.hasBackedUpImportantData;
      default:
        return false;
    }
  }

  void _updateChecklistItem(String key, bool value) {
    setState(() {
      switch (key) {
        case 'hasChangedPasswords':
          _plan = DigitalSafetyPlan(
            hasChangedPasswords: value,
            hasSecuredDevices: _plan.hasSecuredDevices,
            hasDisabledLocationSharing: _plan.hasDisabledLocationSharing,
            hasReviewedPrivacySettings: _plan.hasReviewedPrivacySettings,
            hasBackedUpImportantData: _plan.hasBackedUpImportantData,
            notes: _plan.notes,
          );
          break;
        case 'hasSecuredDevices':
          _plan = DigitalSafetyPlan(
            hasChangedPasswords: _plan.hasChangedPasswords,
            hasSecuredDevices: value,
            hasDisabledLocationSharing: _plan.hasDisabledLocationSharing,
            hasReviewedPrivacySettings: _plan.hasReviewedPrivacySettings,
            hasBackedUpImportantData: _plan.hasBackedUpImportantData,
            notes: _plan.notes,
          );
          break;
        case 'hasDisabledLocationSharing':
          _plan = DigitalSafetyPlan(
            hasChangedPasswords: _plan.hasChangedPasswords,
            hasSecuredDevices: _plan.hasSecuredDevices,
            hasDisabledLocationSharing: value,
            hasReviewedPrivacySettings: _plan.hasReviewedPrivacySettings,
            hasBackedUpImportantData: _plan.hasBackedUpImportantData,
            notes: _plan.notes,
          );
          break;
        case 'hasReviewedPrivacySettings':
          _plan = DigitalSafetyPlan(
            hasChangedPasswords: _plan.hasChangedPasswords,
            hasSecuredDevices: _plan.hasSecuredDevices,
            hasDisabledLocationSharing: _plan.hasDisabledLocationSharing,
            hasReviewedPrivacySettings: value,
            hasBackedUpImportantData: _plan.hasBackedUpImportantData,
            notes: _plan.notes,
          );
          break;
        case 'hasBackedUpImportantData':
          _plan = DigitalSafetyPlan(
            hasChangedPasswords: _plan.hasChangedPasswords,
            hasSecuredDevices: _plan.hasSecuredDevices,
            hasDisabledLocationSharing: _plan.hasDisabledLocationSharing,
            hasReviewedPrivacySettings: _plan.hasReviewedPrivacySettings,
            hasBackedUpImportantData: value,
            notes: _plan.notes,
          );
          break;
      }
    });
  }

  int _getCompletedCount() {
    int count = 0;
    if (_plan.hasChangedPasswords) count++;
    if (_plan.hasSecuredDevices) count++;
    if (_plan.hasDisabledLocationSharing) count++;
    if (_plan.hasReviewedPrivacySettings) count++;
    if (_plan.hasBackedUpImportantData) count++;
    return count;
  }

  Future<void> _savePlan() async {
    if (_safetyPlan == null) return;

    setState(() => _isSaving = true);

    try {
      final updatedPlan = _safetyPlan!.copyWith(
        digitalSafety: _plan,
        updatedAt: DateTime.now(),
      );

      await _service.updateSafetyPlan(updatedPlan);

      setState(() {
        _safetyPlan = updatedPlan;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Digital safety plan saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
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
}
