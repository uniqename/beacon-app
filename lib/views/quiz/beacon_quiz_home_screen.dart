import 'package:flutter/material.dart';
import '../../models/beacon_quiz_model.dart';
import '../../services/beacon_quiz_service.dart';
import '../../constants/brand_colors.dart';
import 'beacon_quiz_play_screen.dart';
import 'beacon_quiz_builder_screen.dart';

class BeaconQuizHomeScreen extends StatefulWidget {
  final String? userId;
  final String? userName;
  final bool canCreate;

  const BeaconQuizHomeScreen({
    super.key,
    this.userId,
    this.userName,
    this.canCreate = false,
  });

  @override
  State<BeaconQuizHomeScreen> createState() => _BeaconQuizHomeScreenState();
}

class _BeaconQuizHomeScreenState extends State<BeaconQuizHomeScreen> {
  final _service = BeaconQuizService();
  List<BeaconQuizModel> _quizzes = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  static const _categoryColors = {
    'Know Your Rights': Color(0xFF1565C0),
    'Safety Smarts': Color(0xFFF57C00),
    'Healthy Relationships': Color(0xFF2E7D32),
    'Healing Journey': Color(0xFF7B1FA2),
    'Financial Independence': Color(0xFF00838F),
    'Community Resources': BeaconColors.vibrantOrange,
    'All': BeaconColors.deepCharcoal,
  };

  static const _categoryIcons = {
    'Know Your Rights': Icons.gavel,
    'Safety Smarts': Icons.shield,
    'Healthy Relationships': Icons.favorite,
    'Healing Journey': Icons.self_improvement,
    'Financial Independence': Icons.account_balance_wallet,
    'Community Resources': Icons.people,
    'All': Icons.grid_view,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final quizzes = await _service.getAllQuizzes();
    if (mounted) {
      setState(() {
        _quizzes = quizzes;
        _isLoading = false;
      });
    }
  }

  List<BeaconQuizModel> get _filtered => _selectedCategory == 'All'
      ? _quizzes
      : _quizzes.where((q) => q.category == _selectedCategory).toList();

  Color _colorFor(String category) =>
      _categoryColors[category] ?? BeaconColors.vibrantOrange;

  IconData _iconFor(String category) =>
      _categoryIcons[category] ?? Icons.quiz;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false),
            icon: const Icon(Icons.home, color: Colors.white70, size: 18),
            label: const Text('Home', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildCategoryFilter(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: BeaconColors.vibrantOrange))
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _buildQuizCard(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: widget.canCreate
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BeaconQuizBuilderScreen(
                      creatorId: widget.userId ?? 'admin',
                      creatorName: widget.userName ?? 'Admin',
                    ),
                  ),
                );
                _load();
              },
              backgroundColor: BeaconColors.vibrantOrange,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Create Quiz'),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1B2A),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [BeaconColors.vibrantOrange, Color(0xFFE04925)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Text('🧠', style: TextStyle(fontSize: 36)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Knowledge Hub',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_quizzes.length} quizzes · Learn & grow every day',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['All', ...BeaconQuizService.quizCategories];
    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: categories.length,
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isSelected = _selectedCategory == cat;
          final color = _colorFor(cat);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: color.withValues(alpha: isSelected ? 1 : 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_iconFor(cat),
                        size: 12,
                        color: isSelected ? Colors.white : color),
                    const SizedBox(width: 5),
                    Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuizCard(BeaconQuizModel quiz) {
    final color = _colorFor(quiz.category);
    final icon = _iconFor(quiz.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2D42),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(quiz.category,
                            style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                if (!quiz.isSystem)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        color: Colors.white54, size: 18),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BeaconQuizBuilderScreen(
                            existing: quiz,
                            creatorId: widget.userId ?? 'admin',
                            creatorName: widget.userName ?? 'Admin',
                          ),
                        ),
                      );
                      _load();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              quiz.description,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.quiz_outlined, size: 13, color: Colors.white38),
                const SizedBox(width: 4),
                Text(
                  '${quiz.questions.length} questions',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _showLeaderboard(quiz),
                  icon: const Icon(Icons.leaderboard, size: 14),
                  label: const Text('Board'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    textStyle: const TextStyle(fontSize: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _play(quiz),
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Play'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _play(BeaconQuizModel quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BeaconQuizPlayScreen(
          quiz: quiz,
          userId: widget.userId ?? 'guest',
          userName: widget.userName ?? 'You',
        ),
      ),
    );
  }

  void _showLeaderboard(BeaconQuizModel quiz) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2D42),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _LeaderboardSheet(quiz: quiz, service: _service),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('No quizzes found',
              style: TextStyle(color: Colors.white54, fontSize: 16)),
        ],
      ),
    );
  }
}

class _LeaderboardSheet extends StatelessWidget {
  final BeaconQuizModel quiz;
  final BeaconQuizService service;

  const _LeaderboardSheet({required this.quiz, required this.service});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: service.getLeaderboard(quiz.id),
      builder: (context, snapshot) {
        final scores = snapshot.data ?? [];
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('🏆',
                      style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Text(
                    '${quiz.title} — Top Scores',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (scores.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No scores yet. Be the first to play!',
                        style: TextStyle(color: Colors.white54)),
                  ),
                )
              else
                ...scores.asMap().entries.map((e) {
                  final rank = e.key + 1;
                  final s = e.value;
                  final medal = rank == 1
                      ? '🥇'
                      : rank == 2
                          ? '🥈'
                          : rank == 3
                              ? '🥉'
                              : '$rank.';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Text(medal,
                        style: const TextStyle(fontSize: 20)),
                    title: Text(s['user_name'] as String? ?? 'Player',
                        style: const TextStyle(color: Colors.white)),
                    trailing: Text('${s['score']} pts',
                        style: const TextStyle(
                            color: BeaconColors.vibrantOrange,
                            fontWeight: FontWeight.bold)),
                  );
                }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
