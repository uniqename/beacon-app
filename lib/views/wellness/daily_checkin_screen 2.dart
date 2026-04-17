import 'package:flutter/material.dart';
import '../../services/mood_tracking_service.dart';

class DailyCheckinScreen extends StatefulWidget {
  final String userId;

  const DailyCheckinScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<DailyCheckinScreen> createState() => _DailyCheckinScreenState();
}

class _DailyCheckinScreenState extends State<DailyCheckinScreen> {
  final MoodTrackingService _service = MoodTrackingService();
  int _selectedMood = 5;
  final List<String> _selectedTriggers = [];
  final TextEditingController _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Check-In'),
        backgroundColor: Colors.purple[600],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text(
            'How are you feeling today?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Icon(
                  _getMoodIcon(_selectedMood),
                  size: 80,
                  color: _getMoodColor(_selectedMood),
                ),
                SizedBox(height: 16),
                Text(
                  _getMoodLabel(_selectedMood),
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _getMoodColor(_selectedMood)),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Rate your mood (1-10)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.sentiment_very_dissatisfied, color: Colors.red),
              Expanded(
                child: Slider(
                  value: _selectedMood.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: _selectedMood.toString(),
                  activeColor: _getMoodColor(_selectedMood),
                  onChanged: (value) => setState(() => _selectedMood = value.toInt()),
                ),
              ),
              Icon(Icons.sentiment_very_satisfied, color: Colors.green),
            ],
          ),
          Center(child: Text(_selectedMood.toString(), style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold))),
          SizedBox(height: 32),
          Text(
            'Any triggers or stressors?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _service.getCommonTriggers().map((trigger) {
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
                selectedColor: Colors.purple[200],
              );
            }).toList(),
          ),
          SizedBox(height: 24),
          Text(
            'Notes (optional)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              hintText: 'How are you feeling? What happened today?',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            maxLines: 5,
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _saveMoodEntry,
            icon: Icon(Icons.check),
            label: Text('Save Check-In'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[600],
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMoodIcon(int score) {
    if (score >= 8) return Icons.sentiment_very_satisfied;
    if (score >= 6) return Icons.sentiment_satisfied;
    if (score >= 4) return Icons.sentiment_neutral;
    if (score >= 2) return Icons.sentiment_dissatisfied;
    return Icons.sentiment_very_dissatisfied;
  }

  String _getMoodLabel(int score) {
    if (score >= 8) return 'Great';
    if (score >= 6) return 'Good';
    if (score >= 4) return 'Okay';
    if (score >= 2) return 'Not Good';
    return 'Very Bad';
  }

  Color _getMoodColor(int score) {
    if (score >= 8) return Colors.green;
    if (score >= 6) return Colors.lightGreen;
    if (score >= 4) return Colors.amber;
    if (score >= 2) return Colors.orange;
    return Colors.red;
  }

  Future<void> _saveMoodEntry() async {
    try {
      await _service.createEntry(
        userId: widget.userId,
        moodScore: _selectedMood,
        triggers: _selectedTriggers,
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mood logged successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving mood: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
