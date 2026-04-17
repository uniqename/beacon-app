import 'package:flutter/material.dart';
import '../../models/safety_plan.dart';
import '../../services/safety_plan_service.dart';

class EscapePlanScreen extends StatefulWidget {
  final String userId;

  const EscapePlanScreen({super.key, required this.userId});

  @override
  State<EscapePlanScreen> createState() => _EscapePlanScreenState();
}

class _EscapePlanScreenState extends State<EscapePlanScreen> {
  final SafetyPlanService _service = SafetyPlanService();
  final _formKey = GlobalKey<FormState>();
  final _primaryRouteController = TextEditingController();
  final _backupRouteController = TextEditingController();
  final _transportationController = TextEditingController();
  final _notesController = TextEditingController();
  final _hidingPlaceController = TextEditingController();

  SafetyPlan? _safetyPlan;
  List<String> _hidingPlaces = [];
  bool _isLoading = true;
  bool _isSaving = false;

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
        if (plan!.escapePlan != null) {
          _primaryRouteController.text = plan.escapePlan!.primaryRoute;
          _backupRouteController.text = plan.escapePlan!.backupRoute;
          _transportationController.text = plan.escapePlan!.transportation;
          _notesController.text = plan.escapePlan!.notes ?? '';
          _hidingPlaces = List.from(plan.escapePlan!.hidingPlaces);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading escape plan: $e')),
        );
      }
    }
  }

  Future<void> _saveEscapePlan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_safetyPlan == null) return;

    setState(() => _isSaving = true);

    try {
      final escapePlan = EscapePlan(
        primaryRoute: _primaryRouteController.text.trim(),
        backupRoute: _backupRouteController.text.trim(),
        hidingPlaces: _hidingPlaces,
        transportation: _transportationController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      final updatedPlan = _safetyPlan!.copyWith(
        escapePlan: escapePlan,
        updatedAt: DateTime.now(),
      );

      await _service.updateSafetyPlan(updatedPlan);

      setState(() {
        _safetyPlan = updatedPlan;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Escape plan saved'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _primaryRouteController.dispose();
    _backupRouteController.dispose();
    _transportationController.dispose();
    _notesController.dispose();
    _hidingPlaceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Escape Plan'), backgroundColor: Colors.orange[600]),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Escape Plan'), backgroundColor: Colors.orange[600]),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.directions_run, color: Colors.orange[700]),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Plan your safe exit routes and hiding places for emergencies',
                        style: TextStyle(color: Colors.orange[900]),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              TextFormField(
                controller: _primaryRouteController,
                decoration: InputDecoration(
                  labelText: 'Primary Exit Route*',
                  hintText: 'Main escape route',
                  prefixIcon: Icon(Icons.directions),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _backupRouteController,
                decoration: InputDecoration(
                  labelText: 'Backup Exit Route*',
                  hintText: 'Alternative route if primary blocked',
                  prefixIcon: Icon(Icons.alt_route),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
              ),
              SizedBox(height: 16),
              Text('Safe Hiding Places', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _hidingPlaceController,
                      decoration: InputDecoration(
                        hintText: 'Add hiding place',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_hidingPlaceController.text.trim().isNotEmpty) {
                        setState(() {
                          _hidingPlaces.add(_hidingPlaceController.text.trim());
                          _hidingPlaceController.clear();
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[600]),
                    child: Icon(Icons.add),
                  ),
                ],
              ),
              if (_hidingPlaces.isNotEmpty) ...[
                SizedBox(height: 12),
                ..._hidingPlaces.asMap().entries.map((e) => Card(
                  child: ListTile(
                    leading: Icon(Icons.shield, color: Colors.orange),
                    title: Text(e.value),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => setState(() => _hidingPlaces.removeAt(e.key)),
                    ),
                  ),
                )),
              ],
              SizedBox(height: 16),
              TextFormField(
                controller: _transportationController,
                decoration: InputDecoration(
                  labelText: 'Transportation*',
                  hintText: 'How will you leave?',
                  prefixIcon: Icon(Icons.directions_car),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Additional Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveEscapePlan,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[600]),
                  child: _isSaving
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Save Escape Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
