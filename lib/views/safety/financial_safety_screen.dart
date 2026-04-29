import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/safety_plan.dart';
import '../../services/safety_plan_service.dart';

class FinancialSafetyScreen extends StatefulWidget {
  final String userId;

  const FinancialSafetyScreen({super.key, required this.userId});

  @override
  State<FinancialSafetyScreen> createState() => _FinancialSafetyScreenState();
}

class _FinancialSafetyScreenState extends State<FinancialSafetyScreen> {
  final SafetyPlanService _service = SafetyPlanService();
  SafetyPlan? _safetyPlan;
  bool _isLoading = true;
  bool _showAmounts = false;

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
          SnackBar(content: Text('Error loading financial safety data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Financial Safety'),
          backgroundColor: Colors.teal[600],
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final savings = _safetyPlan?.hiddenSavings ?? [];
    final totalSavings = savings.fold<double>(0, (sum, item) => sum + item.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text('Financial Safety'),
        backgroundColor: Colors.teal[600],
        actions: [
          IconButton(
            icon: Icon(_showAmounts ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _showAmounts = !_showAmounts),
            tooltip: _showAmounts ? 'Hide amounts' : 'Show amounts',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.teal[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.security, color: Colors.teal[700]),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hidden Savings for Emergency',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal[900]),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Keep small amounts of money hidden in safe places. This is for emergency escape situations.',
                  style: TextStyle(color: Colors.teal[800]),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Hidden Savings:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[850])),
                      Text(
                        _showAmounts ? 'GH₵ ${totalSavings.toStringAsFixed(2)}' : '••••••',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: savings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.savings, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No hidden savings recorded', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Start building your emergency fund by hiding small amounts in safe places',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: savings.length,
                    itemBuilder: (context, index) {
                      final saving = savings[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal[100],
                            child: Icon(Icons.place, color: Colors.teal[700]),
                          ),
                          title: Text(saving.location, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[850])),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text(
                                _showAmounts ? 'GH₵ ${saving.amount.toStringAsFixed(2)}' : '••••••',
                                style: TextStyle(fontSize: 16, color: Colors.teal[700]),
                              ),
                              if (saving.notes != null && saving.notes!.isNotEmpty) ...[
                                SizedBox(height: 4),
                                Text(saving.notes!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
                                _editSaving(index);
                              } else if (value == 'delete') {
                                _deleteSaving(index);
                              }
                            },
                          ),
                          isThreeLine: saving.notes != null && saving.notes!.isNotEmpty,
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.amber[50],
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tip: Hide small amounts in multiple places like book pages, clothing pockets, or with trusted friends.',
                    style: TextStyle(fontSize: 12, color: Colors.amber[900]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSavingDialog,
        icon: Icon(Icons.add),
        label: Text('Add Hidden Savings'),
        backgroundColor: Colors.teal[600],
      ),
    );
  }

  void _showAddSavingDialog({HiddenSaving? existingSaving, int? index}) {
    final locationController = TextEditingController(text: existingSaving?.location ?? '');
    final amountController = TextEditingController(text: existingSaving?.amount.toString() ?? '');
    final notesController = TextEditingController(text: existingSaving?.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingSaving == null ? 'Add Hidden Savings' : 'Edit Hidden Savings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: 'Location *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.place),
                  helperText: 'Where is this money hidden?',
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Amount (GH₵) *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                  helperText: 'Additional details or access instructions',
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
              if (locationController.text.trim().isEmpty || amountController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Location and amount are required')),
                );
                return;
              }

              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }

              final saving = HiddenSaving(
                id: existingSaving?.id ?? 'saving_${DateTime.now().millisecondsSinceEpoch}',
                location: locationController.text.trim(),
                amount: amount,
                notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
              );

              Navigator.pop(context);
              _saveSaving(saving, index);
            },
            child: Text(existingSaving == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSaving(HiddenSaving saving, int? index) async {
    if (_safetyPlan == null) return;

    final updatedSavings = List<HiddenSaving>.from(_safetyPlan!.hiddenSavings);
    if (index != null) {
      updatedSavings[index] = saving;
    } else {
      updatedSavings.add(saving);
    }

    final updatedPlan = _safetyPlan!.copyWith(
      hiddenSavings: updatedSavings,
      updatedAt: DateTime.now(),
    );

    try {
      await _service.updateSafetyPlan(updatedPlan);
      await _loadSafetyPlan();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(index == null ? 'Savings location added' : 'Savings updated'),
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

  void _editSaving(int index) {
    final savings = _safetyPlan?.hiddenSavings ?? [];
    if (index < savings.length) {
      _showAddSavingDialog(existingSaving: savings[index], index: index);
    }
  }

  void _deleteSaving(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Savings Location'),
        content: Text('Remove this hidden savings location?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              if (_safetyPlan == null) return;

              final updatedSavings = List<HiddenSaving>.from(_safetyPlan!.hiddenSavings)..removeAt(index);
              final updatedPlan = _safetyPlan!.copyWith(
                hiddenSavings: updatedSavings,
                updatedAt: DateTime.now(),
              );

              try {
                await _service.updateSafetyPlan(updatedPlan);
                await _loadSafetyPlan();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Savings location removed')),
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
