import 'package:flutter/material.dart';
import '../../models/safety_plan.dart';
import '../../services/safety_plan_service.dart';

class CodeWordsScreen extends StatefulWidget {
  final String userId;

  const CodeWordsScreen({super.key, required this.userId});

  @override
  State<CodeWordsScreen> createState() => _CodeWordsScreenState();
}

class _CodeWordsScreenState extends State<CodeWordsScreen> {
  final SafetyPlanService _service = SafetyPlanService();
  final _formKey = GlobalKey<FormState>();
  final _dangerController = TextEditingController();
  final _helpController = TextEditingController();

  SafetyPlan? _safetyPlan;
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
        _dangerController.text = plan!.dangerCodeWord ?? '';
        _helpController.text = plan.helpCodeWord ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading code words: $e')),
        );
      }
    }
  }

  Future<void> _saveCodeWords() async {
    if (!_formKey.currentState!.validate()) return;
    if (_safetyPlan == null) return;

    setState(() => _isSaving = true);

    try {
      final updatedPlan = _safetyPlan!.copyWith(
        dangerCodeWord: _dangerController.text.trim().isEmpty ? null : _dangerController.text.trim(),
        helpCodeWord: _helpController.text.trim().isEmpty ? null : _helpController.text.trim(),
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
            content: Text('Code words saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving code words: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _dangerController.dispose();
    _helpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Code Words'),
          backgroundColor: Colors.purple[600],
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Code Words'),
        backgroundColor: Colors.purple[600],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.purple[700]),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'What are code words?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Code words are secret words or phrases you can use to communicate danger or the need for help without alerting an abuser.',
                      style: TextStyle(color: Colors.purple[900]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Share these code words with trusted friends, family, or emergency contacts.',
                      style: TextStyle(color: Colors.purple[900]),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Danger code word
              Text(
                'Danger Code Word',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[700], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Use when in immediate danger',
                        style: TextStyle(color: Colors.red[900], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _dangerController,
                decoration: InputDecoration(
                  labelText: 'Danger Code Word',
                  hintText: 'e.g., "Red Alert", "Code 911"',
                  prefixIcon: Icon(Icons.emergency, color: Colors.red),
                  border: OutlineInputBorder(),
                  helperText: 'Choose a word that sounds natural in conversation',
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (value.trim() == _helpController.text.trim()) {
                      return 'Must be different from help code word';
                    }
                  }
                  return null;
                },
              ),

              SizedBox(height: 32),

              // Help code word
              Text(
                'Help Code Word',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.help_outline, color: Colors.orange[700], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Use when you need help (non-emergency)',
                        style: TextStyle(color: Colors.orange[900], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _helpController,
                decoration: InputDecoration(
                  labelText: 'Help Code Word',
                  hintText: 'e.g., "Need groceries", "Movie night"',
                  prefixIcon: Icon(Icons.help, color: Colors.orange),
                  border: OutlineInputBorder(),
                  helperText: 'Choose a casual phrase that won\'t raise suspicion',
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (value.trim() == _dangerController.text.trim()) {
                      return 'Must be different from danger code word';
                    }
                  }
                  return null;
                },
              ),

              SizedBox(height: 32),

              // Examples section
              ExpansionTile(
                title: Text(
                  'Code Word Examples',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                leading: Icon(Icons.lightbulb_outline, color: Colors.purple[600]),
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Danger Code Words:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700]),
                        ),
                        SizedBox(height: 8),
                        _buildExample('• "Pizza order" - sounds like ordering food'),
                        _buildExample('• "Mom\'s birthday" - sounds like a reminder'),
                        _buildExample('• "Red envelope" - sounds casual'),
                        SizedBox(height: 16),
                        Text(
                          'Help Code Words:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[700]),
                        ),
                        SizedBox(height: 8),
                        _buildExample('• "Coffee catch-up" - sounds like a social invitation'),
                        _buildExample('• "Library book" - sounds like an errand'),
                        _buildExample('• "Recipe swap" - sounds harmless'),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveCodeWords,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[600],
                  ),
                  child: _isSaving
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Save Code Words',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              SizedBox(height: 16),

              // Share reminder
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.share, color: Colors.blue[700], size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Remember to share these code words with your trusted contacts',
                        style: TextStyle(color: Colors.blue[900], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExample(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Text(text, style: TextStyle(color: Colors.grey[700])),
    );
  }
}
