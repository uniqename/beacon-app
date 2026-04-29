import 'package:flutter/material.dart';
import '../../services/local_database_service.dart';
import 'dart:convert';

class DailySelfCareScreen extends StatefulWidget {
  final String userId;

  const DailySelfCareScreen({super.key, required this.userId});

  @override
  State<DailySelfCareScreen> createState() => _DailySelfCareScreenState();
}

class _DailySelfCareScreenState extends State<DailySelfCareScreen> {
  final Map<String, List<_SelfCareItem>> _categories = {
    'Body': [
      _SelfCareItem('Drank enough water today', Icons.water_drop),
      _SelfCareItem('Ate a nourishing meal', Icons.restaurant),
      _SelfCareItem('Moved my body (walk, stretch, exercise)', Icons.directions_walk),
      _SelfCareItem('Got enough sleep last night', Icons.bedtime),
      _SelfCareItem('Took my medication / vitamins', Icons.medication),
    ],
    'Mind': [
      _SelfCareItem('Took 5 deep breaths or meditated', Icons.air),
      _SelfCareItem('Journaled or reflected on my feelings', Icons.book),
      _SelfCareItem('Did something creative', Icons.palette),
      _SelfCareItem('Spent time away from screens', Icons.phone_android),
      _SelfCareItem('Set a small goal for today', Icons.flag),
    ],
    'Soul': [
      _SelfCareItem('Spent time in prayer or scripture', Icons.menu_book),
      _SelfCareItem('Connected with someone I trust', Icons.people),
      _SelfCareItem('Did something kind for myself', Icons.favorite),
      _SelfCareItem('Celebrated a small win', Icons.star),
      _SelfCareItem('Practiced gratitude', Icons.volunteer_activism),
    ],
    'Safety': [
      _SelfCareItem('Checked my surroundings felt safe', Icons.shield),
      _SelfCareItem('My escape plan is remembered', Icons.exit_to_app),
      _SelfCareItem('Emergency contacts are accessible', Icons.contacts),
    ],
  };

  final Set<String> _checked = {};
  bool _alreadySavedToday = false;
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic> _streak = {};

  @override
  void initState() {
    super.initState();
    _loadTodayEntry();
  }

  Future<void> _loadTodayEntry() async {
    try {
      final entry = await LocalDatabaseService.getTodaySelfcareEntry(widget.userId);
      final streak = await LocalDatabaseService.getStreak(widget.userId);
      if (entry != null) {
        final items = jsonDecode(entry['completed_items'] as String? ?? '[]') as List;
        setState(() {
          _checked.addAll(items.cast<String>());
          _alreadySavedToday = true;
        });
      }
      setState(() {
        _streak = streak;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  int get _totalItems => _categories.values.fold(0, (s, list) => s + list.length);
  int get _checkedCount => _checked.length;
  double get _completionPct => _totalItems == 0 ? 0 : _checkedCount / _totalItems;

  String get _scoreMessage {
    if (_completionPct >= 0.8) return 'Excellent self-care today! 🌟';
    if (_completionPct >= 0.6) return 'Great effort! Keep going 💪';
    if (_completionPct >= 0.4) return 'You\'re making progress 🌱';
    if (_checkedCount > 0) return 'Every little bit counts 💛';
    return 'Start checking off your self-care for today';
  }

  Future<void> _saveEntry() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await LocalDatabaseService.saveSelfcareEntry(widget.userId, _checked.toList());
      await LocalDatabaseService.updateStreak(widget.userId);
      final streak = await LocalDatabaseService.getStreak(widget.userId);
      setState(() {
        _alreadySavedToday = true;
        _isSaving = false;
        _streak = streak;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Self-care logged! Streak: ${streak['current_streak']} days 🔥'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStreak = _streak['current_streak'] as int? ?? 0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Daily Self-Care', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal[600],
        actions: [
          if (currentStreak > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text('$currentStreak', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ..._categories.entries.map((entry) => _buildCategory(entry.key, entry.value)),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _alreadySavedToday
          ? null
          : FloatingActionButton.extended(
              onPressed: _checkedCount == 0 ? null : _saveEntry,
              backgroundColor: _checkedCount == 0 ? Colors.grey : Colors.teal[600],
              icon: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check),
              label: Text(_isSaving ? 'Saving...' : 'Save Today\'s Check-In'),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.teal[600]!, Colors.teal[400]!]),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$_checkedCount',
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                ' / $_totalItems',
                style: const TextStyle(fontSize: 24, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _completionPct,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(
                _completionPct >= 0.8 ? Colors.greenAccent : Colors.white,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _scoreMessage,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (_alreadySavedToday) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('Saved for today', style: TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategory(String categoryName, List<_SelfCareItem> items) {
    final categoryChecked = items.where((i) => _checked.contains(i.label)).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey[200]!, blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  categoryName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[700],
                  ),
                ),
                const Spacer(),
                Text(
                  '$categoryChecked/${items.length}',
                  style: TextStyle(
                    fontSize: 13,
                    color: categoryChecked == items.length ? Colors.green : Colors.grey[500],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...items.map((item) => _buildCheckItem(item)),
        ],
      ),
    );
  }

  Widget _buildCheckItem(_SelfCareItem item) {
    final isChecked = _checked.contains(item.label);

    return InkWell(
      onTap: _alreadySavedToday
          ? null
          : () {
              setState(() {
                if (isChecked) {
                  _checked.remove(item.label);
                } else {
                  _checked.add(item.label);
                }
              });
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(item.icon, size: 20, color: isChecked ? Colors.teal : Colors.grey[400]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
                  color: isChecked ? Colors.black87 : Colors.grey[700],
                  decoration: isChecked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isChecked ? Colors.teal : Colors.transparent,
                border: Border.all(color: isChecked ? Colors.teal : Colors.grey[300]!, width: 2),
              ),
              child: isChecked
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelfCareItem {
  final String label;
  final IconData icon;

  _SelfCareItem(this.label, this.icon);
}
