import 'package:flutter/material.dart';
import '../../services/local_database_service.dart';

class ProgressTrackerScreen extends StatefulWidget {
  final String userId;

  const ProgressTrackerScreen({super.key, required this.userId});

  @override
  State<ProgressTrackerScreen> createState() => _ProgressTrackerScreenState();
}

class _ProgressTrackerScreenState extends State<ProgressTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Map<String, dynamic> _streak = {};
  List<Map<String, dynamic>> _selfcareHistory = [];
  List<Map<String, dynamic>> _moodHistory = [];
  List<Map<String, dynamic>> _journalHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final streak = await LocalDatabaseService.getStreak(widget.userId);
      final selfcare = await LocalDatabaseService.getSelfcareHistory(widget.userId, days: 30);
      final mood = await LocalDatabaseService.getMoodEntries(widget.userId, days: 30);
      final journal = await LocalDatabaseService.getJournalEntries(widget.userId, days: 30);
      if (mounted) {
        setState(() {
          _streak = streak;
          _selfcareHistory = selfcare;
          _moodHistory = mood;
          _journalHistory = journal;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Progress Tracker', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF0562D),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.local_fire_department), text: 'Streaks'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Milestones'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Activity'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF0562D)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStreaksTab(),
                _buildMilestonesTab(),
                _buildActivityTab(),
              ],
            ),
    );
  }

  Widget _buildStreaksTab() {
    final currentStreak = _streak['current_streak'] as int? ?? 0;
    final longestStreak = _streak['longest_streak'] as int? ?? 0;
    final totalCheckins = _streak['total_checkins'] as int? ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Hero streak card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF0562D), Color(0xFFFF7043)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: const Color(0xFFF0562D).withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange, size: 60),
                const SizedBox(height: 12),
                Text(
                  '$currentStreak',
                  style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Text('Day Streak', style: TextStyle(fontSize: 18, color: Colors.white70)),
                const SizedBox(height: 8),
                Text(
                  currentStreak == 0
                      ? 'Check in today to start your streak!'
                      : currentStreak == 1
                          ? 'Great start! Keep going!'
                          : currentStreak < 7
                              ? 'You\'re building momentum!'
                              : currentStreak < 30
                                  ? 'Amazing dedication!'
                                  : 'Incredible commitment!',
                  style: const TextStyle(fontSize: 14, color: Colors.white60),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Streak stats row
          Row(
            children: [
              Expanded(child: _streakStatCard('Longest', '$longestStreak days', Icons.military_tech, Colors.amber)),
              const SizedBox(width: 12),
              Expanded(child: _streakStatCard('Total Check-Ins', '$totalCheckins', Icons.check_circle, Colors.blue)),
            ],
          ),
          const SizedBox(height: 20),

          // Weekly calendar heatmap
          _buildWeeklyCalendar(),
          const SizedBox(height: 20),

          // Streak tips
          _buildTipCard(
            '💡 Streak Tips',
            'Check in each day to keep your streak going. Even a quick mood log counts! '
            'Streaks reset if you miss a day.',
            Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _streakStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey[200]!, blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600]), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildWeeklyCalendar() {
    final moodDates = _moodHistory.map((e) => e['date'] as String).toSet();
    final selfcareDates = _selfcareHistory.map((e) => e['date'] as String).toSet();
    final journalDates = _journalHistory.map((e) => e['date'] as String).toSet();

    final today = DateTime.now();
    final days = List.generate(28, (i) => today.subtract(Duration(days: 27 - i)));

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
          const Text('Last 28 Days', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: days.length,
            itemBuilder: (context, i) {
              final day = days[i];
              final dateStr = '${day.year}-${day.month.toString().padLeft(2,'0')}-${day.day.toString().padLeft(2,'0')}';
              final hasMood = moodDates.contains(dateStr);
              final hasSelfcare = selfcareDates.contains(dateStr);
              final hasJournal = journalDates.contains(dateStr);
              final activityCount = (hasMood ? 1 : 0) + (hasSelfcare ? 1 : 0) + (hasJournal ? 1 : 0);
              final isToday = dateStr == '${today.year}-${today.month.toString().padLeft(2,'0')}-${today.day.toString().padLeft(2,'0')}';

              Color bgColor;
              if (activityCount == 0) {
                bgColor = Colors.grey[100]!;
              } else if (activityCount == 1) {
                bgColor = Colors.green[200]!;
              } else if (activityCount == 2) {
                bgColor = Colors.green[400]!;
              } else {
                bgColor = const Color(0xFFF0562D);
              }

              return Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(4),
                  border: isToday ? Border.all(color: Colors.orange, width: 2) : null,
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: activityCount > 0 ? Colors.white : Colors.grey[400],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _legendDot(Colors.grey[100]!, 'No activity'),
              const SizedBox(width: 12),
              _legendDot(Colors.green[200]!, '1 activity'),
              const SizedBox(width: 12),
              _legendDot(Colors.green[400]!, '2 activities'),
              const SizedBox(width: 12),
              _legendDot(const Color(0xFFF0562D), 'Full day'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildMilestonesTab() {
    final totalCheckins = _streak['total_checkins'] as int? ?? 0;
    final currentStreak = _streak['current_streak'] as int? ?? 0;
    final journalCount = _journalHistory.length;
    final selfcareCount = _selfcareHistory.length;

    final milestones = [
      _MilestoneData(
        title: 'First Step',
        description: 'Complete your first check-in',
        icon: Icons.star,
        color: Colors.amber,
        progress: totalCheckins >= 1 ? 1.0 : 0.0,
        achieved: totalCheckins >= 1,
        achievedText: 'Achieved!',
      ),
      _MilestoneData(
        title: 'One Week Strong',
        description: 'Check in for 7 days in a row',
        icon: Icons.local_fire_department,
        color: Colors.orange,
        progress: (currentStreak / 7).clamp(0.0, 1.0),
        achieved: currentStreak >= 7,
        achievedText: '7-Day Streak',
      ),
      _MilestoneData(
        title: 'Month Warrior',
        description: 'Complete 30 check-ins total',
        icon: Icons.military_tech,
        color: Colors.purple,
        progress: (totalCheckins / 30).clamp(0.0, 1.0),
        achieved: totalCheckins >= 30,
        achievedText: '$totalCheckins/30 done',
      ),
      _MilestoneData(
        title: 'Reflective Soul',
        description: 'Write 7 journal entries',
        icon: Icons.auto_stories,
        color: Colors.teal,
        progress: (journalCount / 7).clamp(0.0, 1.0),
        achieved: journalCount >= 7,
        achievedText: '$journalCount/7 entries',
      ),
      _MilestoneData(
        title: 'Self-Care Champion',
        description: 'Complete self-care checklist 10 times',
        icon: Icons.spa,
        color: Colors.pink,
        progress: (selfcareCount / 10).clamp(0.0, 1.0),
        achieved: selfcareCount >= 10,
        achievedText: '$selfcareCount/10 done',
      ),
      _MilestoneData(
        title: 'Resilience Builder',
        description: 'Maintain a 30-day streak',
        icon: Icons.emoji_events,
        color: Colors.indigo,
        progress: (currentStreak / 30).clamp(0.0, 1.0),
        achieved: currentStreak >= 30,
        achievedText: '$currentStreak/30 days',
      ),
      _MilestoneData(
        title: 'Wellness Devotee',
        description: 'Complete 100 check-ins total',
        icon: Icons.workspace_premium,
        color: Colors.deepOrange,
        progress: (totalCheckins / 100).clamp(0.0, 1.0),
        achieved: totalCheckins >= 100,
        achievedText: '$totalCheckins/100 done',
      ),
      _MilestoneData(
        title: 'Journal Keeper',
        description: 'Write 30 journal entries',
        icon: Icons.book,
        color: Colors.brown,
        progress: (journalCount / 30).clamp(0.0, 1.0),
        achieved: journalCount >= 30,
        achievedText: '$journalCount/30 entries',
      ),
    ];

    final achieved = milestones.where((m) => m.achieved).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.purple[400]!, Colors.purple[700]!]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 40),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$achieved of ${milestones.length} Milestones',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Keep going — you\'re making progress!',
                        style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...milestones.map((m) => _buildMilestoneCard(m)),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(_MilestoneData milestone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey[200]!, blurRadius: 6, offset: const Offset(0, 3))],
        border: milestone.achieved
            ? Border.all(color: milestone.color, width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: milestone.achieved ? milestone.color : Colors.grey[200],
                child: Icon(milestone.icon, color: milestone.achieved ? Colors.white : Colors.grey[400], size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(milestone.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(milestone.description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              if (milestone.achieved)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: milestone.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('✓ Done', style: TextStyle(fontSize: 12, color: milestone.color, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: milestone.progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                milestone.achieved ? milestone.color : milestone.color.withValues(alpha: 0.5),
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(milestone.progress * 100).toInt()}% — ${milestone.achievedText}',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    final moodDays = _moodHistory.length;
    final selfcareDays = _selfcareHistory.length;
    final journalDays = _journalHistory.length;
    final avgSelfcareScore = _selfcareHistory.isEmpty
        ? 0.0
        : _selfcareHistory.fold<int>(0, (s, e) => s + (e['score'] as int? ?? 0)) / _selfcareHistory.length;
    final avgMood = _moodHistory.isEmpty
        ? 0.0
        : _moodHistory.fold<int>(0, (s, e) => s + (e['mood_rating'] as int? ?? 5)) / _moodHistory.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Last 30 Days Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _activityCard('Mood Logs', '$moodDays', Icons.mood, Colors.pink)),
              const SizedBox(width: 12),
              Expanded(child: _activityCard('Self-Care Days', '$selfcareDays', Icons.spa, Colors.teal)),
              const SizedBox(width: 12),
              Expanded(child: _activityCard('Journal Entries', '$journalDays', Icons.book, Colors.indigo)),
            ],
          ),
          const SizedBox(height: 20),

          // Averages
          const Text('Averages', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildAverageRow('Average Mood', avgMood, 10, Colors.pink, '/ 10'),
          const SizedBox(height: 12),
          _buildAverageRow('Avg Self-Care Score', avgSelfcareScore, 8, Colors.teal, 'items / day'),
          const SizedBox(height: 20),

          // Module completion breakdown
          const Text('Module Completion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _moduleRow('Daily Mood Check-In', moodDays, 30, Colors.pink),
          const SizedBox(height: 8),
          _moduleRow('Self-Care Checklist', selfcareDays, 30, Colors.teal),
          const SizedBox(height: 8),
          _moduleRow('Reflection Journal', journalDays, 30, Colors.indigo),
          const SizedBox(height: 20),
          _buildTipCard(
            '🌱 Keep Growing',
            'You\'re on a healing journey. Every entry — no matter how small — is a step forward. '
            'The goal isn\'t perfection, it\'s progress.',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _activityCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey[200]!, blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600]), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildAverageRow(String label, double value, double max, Color color, String suffix) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.grey[200]!, blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('${value.toStringAsFixed(1)} $suffix',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: max == 0 ? 0 : (value / max).clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _moduleRow(String label, int completed, int total, Color color) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (completed / total).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text('$completed/$total', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildTipCard(String title, String body, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 6),
          Text(body, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        ],
      ),
    );
  }
}

class _MilestoneData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final double progress;
  final bool achieved;
  final String achievedText;

  _MilestoneData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.progress,
    required this.achieved,
    required this.achievedText,
  });
}
