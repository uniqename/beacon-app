import 'package:flutter/material.dart';
import '../../services/local_database_service.dart';
import 'package:intl/intl.dart';

class WellnessReportsScreen extends StatefulWidget {
  final String userId;

  const WellnessReportsScreen({super.key, required this.userId});

  @override
  State<WellnessReportsScreen> createState() => _WellnessReportsScreenState();
}

class _WellnessReportsScreenState extends State<WellnessReportsScreen> {
  bool _isWeekly = true;
  bool _isLoading = true;

  // Current period data
  List<Map<String, dynamic>> _moodEntries = [];
  List<Map<String, dynamic>> _selfcareEntries = [];
  List<Map<String, dynamic>> _journalEntries = [];
  Map<String, dynamic> _streak = {};

  // Comparison period data
  List<Map<String, dynamic>> _prevMoodEntries = [];
  List<Map<String, dynamic>> _prevSelfcareEntries = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final days = _isWeekly ? 7 : 30;
    final prevDays = _isWeekly ? 14 : 60;
    try {
      final mood = await LocalDatabaseService.getMoodEntries(widget.userId, days: days);
      final prevMood = await LocalDatabaseService.getMoodEntries(widget.userId, days: prevDays);
      final selfcare = await LocalDatabaseService.getSelfcareHistory(widget.userId, days: days);
      final prevSelfcare = await LocalDatabaseService.getSelfcareHistory(widget.userId, days: prevDays);
      final journal = await LocalDatabaseService.getJournalEntries(widget.userId, days: days);
      final streak = await LocalDatabaseService.getStreak(widget.userId);

      if (mounted) {
        setState(() {
          _moodEntries = mood;
          _prevMoodEntries = prevMood.where((e) {
            // only keep entries from the previous period (not current)
            final d = e['date'] as String? ?? '';
            try {
              final date = DateTime.parse(d);
              final cutoff = DateTime.now().subtract(Duration(days: days));
              return date.isBefore(cutoff);
            } catch (_) {
              return false;
            }
          }).toList();
          _selfcareEntries = selfcare;
          _prevSelfcareEntries = prevSelfcare.where((e) {
            final d = e['date'] as String? ?? '';
            try {
              final date = DateTime.parse(d);
              final cutoff = DateTime.now().subtract(Duration(days: days));
              return date.isBefore(cutoff);
            } catch (_) {
              return false;
            }
          }).toList();
          _journalEntries = journal;
          _streak = streak;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _avgMood => _moodEntries.isEmpty
      ? 0.0
      : _moodEntries.fold<int>(0, (s, e) => s + (e['mood_rating'] as int? ?? 5)) / _moodEntries.length;

  double get _prevAvgMood => _prevMoodEntries.isEmpty
      ? 0.0
      : _prevMoodEntries.fold<int>(0, (s, e) => s + (e['mood_rating'] as int? ?? 5)) / _prevMoodEntries.length;

  double get _avgSelfcare => _selfcareEntries.isEmpty
      ? 0.0
      : _selfcareEntries.fold<int>(0, (s, e) => s + (e['score'] as int? ?? 0)) / _selfcareEntries.length;

  double get _prevAvgSelfcare => _prevSelfcareEntries.isEmpty
      ? 0.0
      : _prevSelfcareEntries.fold<int>(0, (s, e) => s + (e['score'] as int? ?? 0)) / _prevSelfcareEntries.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Wellness Reports', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple[600],
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _isWeekly = !_isWeekly);
              _loadData();
            },
            child: Text(
              _isWeekly ? 'Monthly' : 'Weekly',
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPeriodHeader(),
                    const SizedBox(height: 20),
                    _buildSummaryCards(),
                    const SizedBox(height: 20),
                    _buildMoodChart(),
                    const SizedBox(height: 20),
                    _buildSelfcareBreakdown(),
                    const SizedBox(height: 20),
                    _buildJournalSummary(),
                    const SizedBox(height: 20),
                    _buildStreakSection(),
                    const SizedBox(height: 20),
                    _buildInsightsCard(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodHeader() {
    final now = DateTime.now();
    final days = _isWeekly ? 7 : 30;
    final start = now.subtract(Duration(days: days - 1));
    final label = _isWeekly ? 'Weekly Report' : 'Monthly Report';
    final range = '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d, y').format(now)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.deepPurple[600]!, Colors.deepPurple[400]!]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(range, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              _periodToggleChip('Weekly', _isWeekly),
              const SizedBox(width: 8),
              _periodToggleChip('Monthly', !_isWeekly),
            ],
          ),
        ],
      ),
    );
  }

  Widget _periodToggleChip(String label, bool active) {
    return GestureDetector(
      onTap: () {
        if ((label == 'Weekly') != _isWeekly) {
          setState(() => _isWeekly = label == 'Weekly');
          _loadData();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: active ? Colors.deepPurple[700] : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final days = _isWeekly ? 7 : 30;
    final moodTrend = _avgMood - _prevAvgMood;
    final selfcareTrend = _avgSelfcare - _prevAvgSelfcare;

    return Row(
      children: [
        Expanded(child: _summaryCard(
          'Avg Mood',
          _avgMood.toStringAsFixed(1),
          '/ 10',
          Icons.mood,
          Colors.pink,
          _prevAvgMood > 0 ? moodTrend : null,
        )),
        const SizedBox(width: 10),
        Expanded(child: _summaryCard(
          'Check-Ins',
          '${_moodEntries.length}',
          '/ $days days',
          Icons.check_circle,
          Colors.blue,
          null,
        )),
        const SizedBox(width: 10),
        Expanded(child: _summaryCard(
          'Self-Care',
          _avgSelfcare.toStringAsFixed(1),
          'items/day',
          Icons.spa,
          Colors.teal,
          _prevAvgSelfcare > 0 ? selfcareTrend : null,
        )),
      ],
    );
  }

  Widget _summaryCard(String label, String value, String unit, IconData icon, Color color, double? trend) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey[200]!, blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(unit, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          if (trend != null && trend != 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(trend > 0 ? Icons.trending_up : Icons.trending_down,
                    size: 12,
                    color: trend > 0 ? Colors.green : Colors.red),
                Text(
                  trend.abs().toStringAsFixed(1),
                  style: TextStyle(fontSize: 10, color: trend > 0 ? Colors.green : Colors.red),
                ),
              ],
            ),
          ],
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildMoodChart() {
    if (_moodEntries.isEmpty) {
      return _emptySection('Mood Trend', 'No mood check-ins recorded in this period', Icons.mood);
    }

    final days = _isWeekly ? 7 : 30;
    final now = DateTime.now();

    // Build day-by-day mood map
    final moodMap = <String, int>{};
    for (final e in _moodEntries) {
      moodMap[e['date'] as String? ?? ''] = e['mood_rating'] as int? ?? 5;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey[200]!, blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, color: Colors.pink, size: 20),
              const SizedBox(width: 8),
              const Text('Mood Trend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Text('${_moodEntries.length} entries', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(days, (i) {
                final day = now.subtract(Duration(days: days - 1 - i));
                final dateStr = '${day.year}-${day.month.toString().padLeft(2,'0')}-${day.day.toString().padLeft(2,'0')}';
                final moodVal = moodMap[dateStr];
                final height = moodVal != null ? (moodVal / 10 * 60) + 4.0 : 4.0;
                final color = moodVal == null
                    ? Colors.grey[200]!
                    : moodVal >= 7
                        ? Colors.green[400]!
                        : moodVal >= 4
                            ? Colors.orange[300]!
                            : Colors.red[300]!;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Tooltip(
                      message: moodVal != null ? 'Mood: $moodVal/10' : 'No entry',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (moodVal != null)
                            Text('$moodVal', style: const TextStyle(fontSize: 7, color: Colors.grey)),
                          Container(
                            height: height,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('MMM d').format(now.subtract(Duration(days: days - 1))),
                  style: TextStyle(fontSize: 10, color: Colors.grey[400])),
              Text(DateFormat('MMM d').format(now),
                  style: TextStyle(fontSize: 10, color: Colors.grey[400])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _legendBar(Colors.green[400]!, 'Good (7-10)'),
              const SizedBox(width: 12),
              _legendBar(Colors.orange[300]!, 'Okay (4-6)'),
              const SizedBox(width: 12),
              _legendBar(Colors.red[300]!, 'Low (1-3)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendBar(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildSelfcareBreakdown() {
    if (_selfcareEntries.isEmpty) {
      return _emptySection('Self-Care', 'No self-care entries in this period', Icons.spa);
    }

    final days = _isWeekly ? 7 : 30;
    final pct = (_selfcareEntries.length / days * 100).clamp(0.0, 100.0);
    final avgScore = _avgSelfcare;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey[200]!, blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.spa, color: Colors.teal, size: 20),
              const SizedBox(width: 8),
              const Text('Self-Care Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${_selfcareEntries.length}/$days',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                    const Text('Days Completed', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${pct.toInt()}%',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const Text('Completion Rate', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${avgScore.toStringAsFixed(1)}/18',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const Text('Avg Items Done', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                pct >= 70 ? Colors.teal : Colors.orange,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey[200]!, blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories, color: Colors.indigo, size: 20),
              const SizedBox(width: 8),
              const Text('Journal Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Text('${_journalEntries.length} entries', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
          const SizedBox(height: 12),
          if (_journalEntries.isEmpty)
            Text('No journal entries this period.', style: TextStyle(color: Colors.grey[500], fontSize: 13))
          else
            _buildJournalMoodShift(),
        ],
      ),
    );
  }

  Widget _buildJournalMoodShift() {
    final avgMoodBefore = _journalEntries.fold<int>(0, (s, e) => s + (e['mood_before'] as int? ?? 5)) /
        _journalEntries.length;
    final avgMoodAfter = _journalEntries.fold<int>(0, (s, e) => s + (e['mood_after'] as int? ?? 5)) /
        _journalEntries.length;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _journalMoodBadge('Avg mood before writing', avgMoodBefore, Colors.orange)),
            const Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
            Expanded(child: _journalMoodBadge('Avg mood after writing', avgMoodAfter, Colors.green)),
          ],
        ),
        if (avgMoodAfter > avgMoodBefore) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Journaling improved your mood by ${(avgMoodAfter - avgMoodBefore).toStringAsFixed(1)} points on average!',
                    style: const TextStyle(fontSize: 12, color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _journalMoodBadge(String label, double value, Color color) {
    return Column(
      children: [
        Text(value.toStringAsFixed(1), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500]), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildStreakSection() {
    final currentStreak = _streak['current_streak'] as int? ?? 0;
    final longestStreak = _streak['longest_streak'] as int? ?? 0;
    final totalCheckins = _streak['total_checkins'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.deepOrange[400]!, Colors.orange[400]!]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _streakBadge('Current Streak', '$currentStreak days', Icons.local_fire_department),
          _streakBadge('Best Streak', '$longestStreak days', Icons.military_tech),
          _streakBadge('Total Check-Ins', '$totalCheckins', Icons.check_circle),
        ],
      ),
    );
  }

  Widget _streakBadge(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildInsightsCard() {
    final insights = <String>[];

    if (_moodEntries.isNotEmpty) {
      if (_avgMood >= 7) {
        insights.add('Your mood has been strong this period. Great work!');
      } else if (_avgMood >= 4) {
        insights.add('Your mood is in the middle range. Keep checking in — it helps!');
      } else {
        insights.add('Your mood has been low. Please reach out to a counselor or trusted person if you need support.');
      }
    }

    if (_selfcareEntries.length >= (_isWeekly ? 5 : 20)) {
      insights.add('Excellent self-care consistency! You\'re building healthy habits.');
    } else if (_selfcareEntries.isNotEmpty) {
      insights.add('You\'ve done some self-care. Try to build a daily routine for maximum benefit.');
    }

    if (_journalEntries.isNotEmpty) {
      insights.add('Journaling is a powerful tool. You\'ve written ${_journalEntries.length} entries this period.');
    }

    if ((_streak['current_streak'] as int? ?? 0) >= 7) {
      insights.add('You\'re on a ${_streak['current_streak']}-day streak! Keep it going!');
    }

    if (insights.isEmpty) {
      insights.add('Start logging your mood and self-care to see insights here.');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.deepPurple[600], size: 20),
              const SizedBox(width: 8),
              Text('Insights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurple[700])),
            ],
          ),
          const SizedBox(height: 12),
          ...insights.map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: Colors.deepPurple[600], fontWeight: FontWeight.bold)),
                    Expanded(child: Text(insight, style: TextStyle(fontSize: 13, color: Colors.deepPurple[800]))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _emptySection(String title, String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey[200]!, blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(message, style: TextStyle(fontSize: 12, color: Colors.grey[500]), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
