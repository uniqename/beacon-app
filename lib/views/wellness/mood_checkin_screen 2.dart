import 'package:flutter/material.dart';
import '../../services/mood_tracking_service.dart';

class MoodCheckinScreen extends StatefulWidget {
  final String userId;

  const MoodCheckinScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<MoodCheckinScreen> createState() => _MoodCheckinScreenState();
}

class _MoodCheckinScreenState extends State<MoodCheckinScreen> {
  final _service = MoodTrackingService();
  final _notesController = TextEditingController();
  double _moodRating = 5.0;
  final List<String> _selectedTriggers = [];
  bool _isSaving = false;

  final List<String> _availableTriggers = [
    'Stress',
    'Sleep',
    'Work',
    'Relationships',
    'Finances',
    'Health',
    'Loneliness',
    'Anxiety',
    'Safety Concerns',
    'Other',
  ];

  Future<void> _saveMood() async {
    setState(() => _isSaving = true);

    try {
      await _service.createEntry(
        userId: widget.userId,
        moodScore: _moodRating.toInt(),
        triggers: _selectedTriggers,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mood logged successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging mood: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Log Your Mood'),
        backgroundColor: Colors.purple[600],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How are you feeling today?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_getMoodIcon(_moodRating), size: 48, color: _getMoodColor(_moodRating)),
                        SizedBox(width: 16),
                        Text(
                          _moodRating.toStringAsFixed(1),
                          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(_getMoodLabel(_moodRating), style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                    SizedBox(height: 16),
                    Slider(
                      value: _moodRating,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: _getMoodColor(_moodRating),
                      onChanged: (value) => setState(() => _moodRating = value),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('1', style: TextStyle(color: Colors.grey)),
                        Text('10', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Text('What\'s affecting your mood?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTriggers.map((trigger) {
                final isSelected = _selectedTriggers.contains(trigger);
                return FilterChip(
                  label: Text(trigger),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTriggers.add(trigger);
                      } else {
                        _selectedTriggers.remove(trigger);
                      }
                    });
                  },
                  selectedColor: Colors.purple[100],
                  checkmarkColor: Colors.purple[700],
                );
              }).toList(),
            ),
            SizedBox(height: 24),
            Text('Notes (optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'How are you feeling? What happened today?',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveMood,
                child: _isSaving
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Save Mood Entry', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMoodIcon(double mood) {
    if (mood >= 8) return Icons.sentiment_very_satisfied;
    if (mood >= 6) return Icons.sentiment_satisfied;
    if (mood >= 4) return Icons.sentiment_neutral;
    if (mood >= 2) return Icons.sentiment_dissatisfied;
    return Icons.sentiment_very_dissatisfied;
  }

  Color _getMoodColor(double mood) {
    if (mood >= 8) return Colors.green;
    if (mood >= 6) return Colors.lightGreen;
    if (mood >= 4) return Colors.orange;
    if (mood >= 2) return Colors.deepOrange;
    return Colors.red;
  }

  String _getMoodLabel(double mood) {
    if (mood >= 8) return 'Great';
    if (mood >= 6) return 'Good';
    if (mood >= 4) return 'Okay';
    if (mood >= 2) return 'Not Great';
    return 'Very Bad';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
