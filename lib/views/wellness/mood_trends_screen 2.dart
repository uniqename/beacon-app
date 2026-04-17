import 'package:flutter/material.dart';
import '../../models/evidence_log.dart';
import '../../services/mood_tracking_service.dart';

class MoodTrendsScreen extends StatefulWidget {
  final String userId;

  const MoodTrendsScreen({super.key, required this.userId});

  @override
  State<MoodTrendsScreen> createState() => _MoodTrendsScreenState();
}

class _MoodTrendsScreenState extends State<MoodTrendsScreen> {
  final MoodTrackingService _service = MoodTrackingService();
  List<MoodEntry> _entries = [];
  final int _selectedDays = 14;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final entries = await _service.getEntries(widget.userId, days: _selectedDays);
    setState(() {
      _entries = entries;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final average7 = _calculateAverage(7);
    final average14 = _calculateAverage(14);
    final average30 = _calculateAverage(30);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mood Trends'),
        backgroundColor: Colors.purple[600],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Average Mood', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 16),
                        _buildAverageRow('Last 7 days', average7, Colors.blue),
                        SizedBox(height: 12),
                        _buildAverageRow('Last 14 days', average14, Colors.purple),
                        SizedBox(height: 12),
                        _buildAverageRow('Last 30 days', average30, Colors.indigo),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mood Chart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: _entries.isEmpty
                              ? Center(child: Text('No data to display', style: TextStyle(color: Colors.grey)))
                              : _buildMoodChart(),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Common Triggers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 16),
                        ..._getTopTriggers().map((trigger) => Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber, size: 20, color: Colors.orange),
                                  SizedBox(width: 12),
                                  Expanded(child: Text(trigger['name'])),
                                  Text('${trigger['count']}x', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )),
                        if (_getTopTriggers().isEmpty)
                          Center(child: Text('No triggers recorded', style: TextStyle(color: Colors.grey))),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Colors.amber[700]),
                            SizedBox(width: 12),
                            Text('Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(height: 16),
                        ..._getInsights().map((insight) => Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('•', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  SizedBox(width: 8),
                                  Expanded(child: Text(insight)),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAverageRow(String label, double average, Color color) {
    return Row(
      children: [
        Expanded(flex: 2, child: Text(label)),
        Expanded(
          flex: 3,
          child: LinearProgressIndicator(
            value: average / 10,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
        SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            average.toStringAsFixed(1),
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildMoodChart() {
    final sortedEntries = List<MoodEntry>.from(_entries)..sort((a, b) => a.date.compareTo(b.date));

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: sortedEntries.length,
      itemBuilder: (context, index) {
        final entry = sortedEntries[index];
        final height = (entry.moodScore / 10) * 180;

        return Container(
          width: 40,
          margin: EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(entry.moodScore.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Container(
                width: 32,
                height: height,
                decoration: BoxDecoration(
                  color: _getMoodColor(entry.moodScore),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
              SizedBox(height: 4),
              Text(
                entry.date.day.toString(),
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      },
    );
  }

  double _calculateAverage(int days) {
    if (_entries.isEmpty) return 0;
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final relevantEntries = _entries.where((e) => e.date.isAfter(cutoffDate)).toList();
    if (relevantEntries.isEmpty) return 0;
    final sum = relevantEntries.fold<int>(0, (sum, entry) => sum + entry.moodScore);
    return sum / relevantEntries.length;
  }

  List<Map<String, dynamic>> _getTopTriggers() {
    final triggerCounts = <String, int>{};
    for (var entry in _entries) {
      for (var trigger in entry.triggers) {
        triggerCounts[trigger] = (triggerCounts[trigger] ?? 0) + 1;
      }
    }

    final sortedTriggers = triggerCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTriggers.take(5).map((e) => {'name': e.key, 'count': e.value}).toList();
  }

  List<String> _getInsights() {
    final insights = <String>[];
    final avg7 = _calculateAverage(7);
    final avg14 = _calculateAverage(14);

    if (avg7 > avg14) {
      insights.add('Your mood has improved in the last week compared to the previous week.');
    } else if (avg7 < avg14) {
      insights.add('Your mood has declined in the last week. Consider reaching out for support.');
    }

    final topTriggers = _getTopTriggers();
    if (topTriggers.isNotEmpty) {
      insights.add('${topTriggers[0]['name']} is your most common trigger. Try to identify patterns around this.');
    }

    if (_entries.length >= 7) {
      insights.add('Great job tracking your mood for ${_entries.length} days! Consistency helps identify patterns.');
    }

    if (insights.isEmpty) {
      insights.add('Keep logging your mood daily to see personalized insights here.');
    }

    return insights;
  }

  Color _getMoodColor(int score) {
    if (score >= 8) return Colors.green;
    if (score >= 6) return Colors.lightGreen;
    if (score >= 4) return Colors.amber;
    if (score >= 2) return Colors.orange;
    return Colors.red;
  }
}
