import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../models/evidence_log.dart';
import '../../services/mood_tracking_service.dart';

class MoodDashboardScreen extends StatefulWidget {
  final String userId;

  const MoodDashboardScreen({super.key, required this.userId});

  @override
  State<MoodDashboardScreen> createState() => _MoodDashboardScreenState();
}

class _MoodDashboardScreenState extends State<MoodDashboardScreen> {
  final MoodTrackingService _service = MoodTrackingService();
  List<MoodEntry> _recentEntries = [];
  double _averageMood = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      developer.log('🔍 [Wellness] Loading data for user: ${widget.userId}');
      final entries = await _service.getEntries(widget.userId, days: 7);
      final average = await _service.getAverageMood(widget.userId, days: 7);
      developer.log('✅ [Wellness] Loaded ${entries.length} entries, average: $average');
      setState(() {
        _recentEntries = entries;
        _averageMood = average;
        _isLoading = false;
      });
    } catch (e, stack) {
      developer.log('❌ [Wellness] ERROR loading data: $e');
      developer.log('   Stack: $stack');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading wellness data: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wellness Tracker'),
        backgroundColor: Colors.purple[600],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple[400]!, Colors.purple[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Your 7-Day Average',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_getMoodIcon(_averageMood), color: Colors.white, size: 48),
                            SizedBox(width: 16),
                            Text(
                              _averageMood.toStringAsFixed(1),
                              style: TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '/10',
                              style: TextStyle(color: Colors.white70, fontSize: 24),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          _getMoodLabel(_averageMood),
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.purple[700], size: 20),
                      SizedBox(width: 8),
                      Text('Recent Entries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Spacer(),
                      Text('${_recentEntries.length} entries', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                  SizedBox(height: 16),
                  if (_recentEntries.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.sentiment_neutral, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No mood entries yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                            SizedBox(height: 8),
                            Text('Tap + to log your first mood', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._recentEntries.map((entry) => _buildMoodCard(entry)),
                  SizedBox(height: 24),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.timeline, color: Colors.purple[700]),
                      title: Text('View Trends & Insights'),
                      subtitle: Text('See your mood patterns over time'),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pushNamed(context, '/mood_trends');
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/mood_checkin').then((_) => _loadData());
        },
        icon: Icon(Icons.add),
        label: Text('Log Mood'),
        backgroundColor: Colors.purple[600],
      ),
    );
  }

  Widget _buildMoodCard(MoodEntry entry) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getMoodColor(entry.moodScore),
          child: Icon(_getMoodIcon(entry.moodScore.toDouble()), color: Colors.white),
        ),
        title: Row(
          children: [
            Text(
              entry.moodScore.toString(),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text('/10', style: TextStyle(color: Colors.grey[600])),
            SizedBox(width: 12),
            Text(_getMoodLabel(entry.moodScore.toDouble())),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(entry.date.toString().substring(0, 16)),
            if (entry.triggers.isNotEmpty) ...[
              SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: entry.triggers.take(3).map((trigger) {
                  return Chip(
                    label: Text(trigger, style: TextStyle(fontSize: 11)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        isThreeLine: entry.triggers.isNotEmpty,
      ),
    );
  }

  IconData _getMoodIcon(double score) {
    if (score >= 8) return Icons.sentiment_very_satisfied;
    if (score >= 6) return Icons.sentiment_satisfied;
    if (score >= 4) return Icons.sentiment_neutral;
    if (score >= 2) return Icons.sentiment_dissatisfied;
    return Icons.sentiment_very_dissatisfied;
  }

  String _getMoodLabel(double score) {
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
}
