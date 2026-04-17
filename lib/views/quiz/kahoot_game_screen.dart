import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/beacon_quiz_model.dart';
import '../../services/beacon_quiz_service.dart';

// ── Colours ───────────────────────────────────────────────────────────────────
const _kBg      = Color(0xFF0A0E1A);
const _kCard    = Color(0xFF141929);
const _kBorder  = Color(0xFF2A3550);
const _kAccent  = Color(0xFF00D4AA);

// Answer button colours (Kahoot palette)
const _kAnsA = Color(0xFFE21B3C); // red triangle
const _kAnsB = Color(0xFF1368CE); // blue diamond
const _kAnsC = Color(0xFFD89E00); // yellow circle
const _kAnsD = Color(0xFF26890C); // green square

const _kAnsColors  = [_kAnsA, _kAnsB, _kAnsC, _kAnsD];
const _kAnsIcons   = [Icons.change_history, Icons.diamond, Icons.circle, Icons.square];
const _kAnsLabels  = ['A', 'B', 'C', 'D'];

// ── Player model ──────────────────────────────────────────────────────────────
class KahootPlayer {
  final String id;
  final String name;
  final Color color;
  int score;
  int streak;
  int lastGain;

  KahootPlayer({
    required this.id,
    required this.name,
    required this.color,
    this.score = 0,
    this.streak = 0,
    this.lastGain = 0,
  });
}

// ── Entry screen: pick quiz + players ────────────────────────────────────────
class KahootLobbyScreen extends StatefulWidget {
  final String? hostName;

  const KahootLobbyScreen({super.key, this.hostName});

  @override
  State<KahootLobbyScreen> createState() => _KahootLobbyScreenState();
}

class _KahootLobbyScreenState extends State<KahootLobbyScreen> {
  final _service = BeaconQuizService();
  List<BeaconQuizModel> _quizzes = [];
  BeaconQuizModel? _selectedQuiz;
  bool _loading = true;

  final List<TextEditingController> _playerCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];

  static const _playerColors = [
    Color(0xFF00D4AA), Color(0xFF7C3AED), Color(0xFFFFB347),
    Color(0xFFFF5C7A), Color(0xFF3B82F6), Color(0xFF10B981),
  ];

  @override
  void initState() {
    super.initState();
    _load();
    // Pre-fill host name if provided
    if (widget.hostName != null) {
      _playerCtrls[0].text = widget.hostName!;
    } else {
      _playerCtrls[0].text = 'Player 1';
      _playerCtrls[1].text = 'Player 2';
    }
  }

  @override
  void dispose() {
    for (final c in _playerCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final quizzes = await _service.getAllQuizzes();
    if (mounted) {
      setState(() {
        _quizzes = quizzes.where((q) => q.questions.isNotEmpty).toList();
        if (_quizzes.isNotEmpty) _selectedQuiz = _quizzes.first;
        _loading = false;
      });
    }
  }

  void _addPlayer() {
    if (_playerCtrls.length >= 6) return;
    setState(() {
      final c = TextEditingController(text: 'Player ${_playerCtrls.length + 1}');
      _playerCtrls.add(c);
    });
  }

  void _removePlayer(int i) {
    if (_playerCtrls.length <= 1) return;
    setState(() {
      _playerCtrls[i].dispose();
      _playerCtrls.removeAt(i);
    });
  }

  void _startGame() {
    if (_selectedQuiz == null) return;
    final players = <KahootPlayer>[];
    for (var i = 0; i < _playerCtrls.length; i++) {
      final name = _playerCtrls[i].text.trim();
      if (name.isEmpty) continue;
      players.add(KahootPlayer(
        id: 'p$i',
        name: name,
        color: _playerColors[i % _playerColors.length],
      ));
    }
    if (players.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KahootGameScreen(
          quiz: _selectedQuiz!,
          players: players,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE21B3C), Color(0xFF1368CE)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('Group Quiz Game', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kAccent))
          : _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startGame,
        backgroundColor: _kAccent,
        foregroundColor: _kBg,
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Start Game', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(),
          const SizedBox(height: 24),
          _buildQuizPicker(),
          const SizedBox(height: 24),
          _buildPlayersList(),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C0A2E), Color(0xFF0A0E1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _colorBlock(_kAnsA, Icons.change_history),
              const SizedBox(width: 6),
              _colorBlock(_kAnsB, Icons.diamond),
              const SizedBox(width: 6),
              _colorBlock(_kAnsC, Icons.circle),
              const SizedBox(width: 6),
              _colorBlock(_kAnsD, Icons.square),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Kahoot-Style Quiz',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Race to answer first. Earn bonus points for speed. Challenge friends in your support group!',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _colorBlock(Color c, IconData icon) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.withValues(alpha: 0.4)),
          ),
          child: Icon(icon, color: c, size: 22),
        ),
      ),
    );
  }

  Widget _buildQuizPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose a Quiz',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        if (_quizzes.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder),
            ),
            child: Text(
              'No quizzes available. Create one in the Quizzes section.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
            ),
          )
        else
          ...List.generate(_quizzes.length, (i) {
            final q = _quizzes[i];
            final isSelected = _selectedQuiz?.id == q.id;
            return GestureDetector(
              onTap: () => setState(() => _selectedQuiz = q),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? _kAccent.withValues(alpha: 0.1) : _kCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? _kAccent : _kBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded, color: _kAccent, size: 20)
                    else
                      Icon(Icons.radio_button_unchecked, color: Colors.white.withValues(alpha: 0.3), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            q.title,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${q.questions.length} questions · ${q.category}',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPlayersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Players',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (_playerCtrls.length < 6)
              GestureDetector(
                onTap: _addPlayer,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kAccent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add, color: _kAccent, size: 14),
                      const SizedBox(width: 4),
                      const Text('Add Player', style: TextStyle(color: _kAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(_playerCtrls.length, (i) {
          final color = _playerColors[i % _playerColors.length];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(color: color, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _playerCtrls[i],
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Player ${i + 1} name',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
                if (_playerCtrls.length > 1)
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.3), size: 18),
                    onPressed: () => _removePlayer(i),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ── Game screen ───────────────────────────────────────────────────────────────
class KahootGameScreen extends StatefulWidget {
  final BeaconQuizModel quiz;
  final List<KahootPlayer> players;

  const KahootGameScreen({super.key, required this.quiz, required this.players});

  @override
  State<KahootGameScreen> createState() => _KahootGameScreenState();
}

class _KahootGameScreenState extends State<KahootGameScreen>
    with TickerProviderStateMixin {
  int _questionIndex = 0;
  _Phase _phase = _Phase.countdown;
  int _countdown = 3;
  int _timeLeft = 20;
  Timer? _timer;
  late List<KahootPlayer> _players;
  late List<int?> _playerAnswers; // index of chosen answer per player

  // Countdown animation
  late AnimationController _countdownCtrl;
  late Animation<double> _countdownScale;

  // Timer bar animation
  late AnimationController _timerBarCtrl;
  late Animation<double> _timerBarAnim;

  @override
  void initState() {
    super.initState();
    _players = List.from(widget.players);
    _countdownCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _countdownScale = Tween(begin: 1.5, end: 0.8).animate(
      CurvedAnimation(parent: _countdownCtrl, curve: Curves.easeOut),
    );
    _timerBarCtrl = AnimationController(vsync: this);
    _timerBarAnim = Tween(begin: 1.0, end: 0.0).animate(_timerBarCtrl);
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownCtrl.dispose();
    _timerBarCtrl.dispose();
    super.dispose();
  }

  BeaconQuizQuestion get _currentQuestion =>
      widget.quiz.questions[_questionIndex];

  void _startCountdown() {
    setState(() {
      _phase = _Phase.countdown;
      _countdown = 3;
      _playerAnswers = List.filled(_players.length, null);
    });
    _countdownCtrl.forward(from: 0);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown > 1) {
        setState(() => _countdown--);
        _countdownCtrl.forward(from: 0);
      } else {
        t.cancel();
        _startQuestion();
      }
    });
  }

  void _startQuestion() {
    final secs = _currentQuestion.timeLimitSeconds;
    setState(() {
      _phase = _Phase.question;
      _timeLeft = secs;
    });
    _timerBarCtrl.duration = Duration(seconds: secs);
    _timerBarCtrl.forward(from: 0);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft > 1) {
        setState(() => _timeLeft--);
      } else {
        t.cancel();
        _revealAnswer();
      }
    });
  }

  void _playerTap(int playerIndex, int answerIndex) {
    if (_phase != _Phase.question) return;
    if (_playerAnswers[playerIndex] != null) return; // already answered

    final correct = _currentQuestion.correctIndex;
    final isCorrect = answerIndex == correct;

    // Points: base 1000, speed bonus up to 500
    final secs = _currentQuestion.timeLimitSeconds;
    final speedRatio = _timeLeft / secs;
    final gain = isCorrect
        ? (1000 + (speedRatio * 500).round()).clamp(100, 1500)
        : 0;

    setState(() {
      _playerAnswers[playerIndex] = answerIndex;
      if (isCorrect) {
        _players[playerIndex].streak++;
        // Streak bonus: extra 100 per 3-streak
        final streakBonus = (_players[playerIndex].streak ~/ 3) * 100;
        _players[playerIndex].lastGain = gain + streakBonus;
        _players[playerIndex].score += gain + streakBonus;
      } else {
        _players[playerIndex].streak = 0;
        _players[playerIndex].lastGain = 0;
      }
    });

    // If all players answered, reveal immediately
    if (_playerAnswers.every((a) => a != null)) {
      _timer?.cancel();
      _timerBarCtrl.stop();
      Future.delayed(const Duration(milliseconds: 300), _revealAnswer);
    }
  }

  void _revealAnswer() {
    _timer?.cancel();
    _timerBarCtrl.stop();
    setState(() {
      _phase = _Phase.reveal;
      // Zero out lastGain for those who didn't answer
      for (var i = 0; i < _players.length; i++) {
        if (_playerAnswers[i] == null) {
          _players[i].streak = 0;
          _players[i].lastGain = 0;
        }
      }
    });
  }

  void _nextQuestion() {
    if (_questionIndex + 1 < widget.quiz.questions.length) {
      setState(() => _questionIndex++);
      _startCountdown();
    } else {
      _showResults();
    }
  }

  void _showResults() {
    _timer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => KahootResultsScreen(
          quiz: widget.quiz,
          players: _players,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: switch (_phase) {
          _Phase.countdown => _buildCountdown(),
          _Phase.question  => _buildQuestion(),
          _Phase.reveal    => _buildReveal(),
        },
      ),
    );
  }

  // ── Countdown (3, 2, 1) ──────────────────────────────────────────────────
  Widget _buildCountdown() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Q${_questionIndex + 1} of ${widget.quiz.questions.length}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _countdownScale,
            builder: (_, __) => Transform.scale(
              scale: _countdownScale.value,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_kAccent, Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _kAccent.withValues(alpha: 0.4),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$_countdown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Get Ready!',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Question + answers ───────────────────────────────────────────────────
  Widget _buildQuestion() {
    final q = _currentQuestion;
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A0A2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2A1A50)),
              ),
              child: Text(
                q.question,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildAnswerGrid(q),
        const SizedBox(height: 16),
        _buildPlayerStatusRow(),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.5)),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _timerBarAnim,
                  builder: (_, __) {
                    final val = _timerBarAnim.value;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: val,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(
                          val > 0.5 ? _kAccent : val > 0.25 ? _kAnsC : _kAnsA,
                        ),
                        minHeight: 8,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  '$_timeLeft s',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder),
            ),
            child: Center(
              child: Text(
                '${_questionIndex + 1}/${widget.quiz.questions.length}',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerGrid(BeaconQuizQuestion q) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.6,
        children: List.generate(
          min(q.options.length, 4),
          (i) => _AnswerButton(
            label: _kAnsLabels[i],
            text: q.options[i],
            color: _kAnsColors[i],
            icon: _kAnsIcons[i],
            onTap: () {
              // Show who picked which answer
              _showAnswerPicker(i);
            },
          ),
        ),
      ),
    );
  }

  // Bottom sheet: choose which player is answering
  void _showAnswerPicker(int answerIndex) {
    if (_players.length == 1) {
      _playerTap(0, answerIndex);
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Who chose "${_currentQuestion.options[answerIndex]}"?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(_players.length, (pi) {
                  final p = _players[pi];
                  final alreadyAnswered = _playerAnswers[pi] != null;
                  return GestureDetector(
                    onTap: alreadyAnswered
                        ? null
                        : () {
                            Navigator.pop(context);
                            _playerTap(pi, answerIndex);
                          },
                    child: Opacity(
                      opacity: alreadyAnswered ? 0.35 : 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: p.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: p.color.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(alreadyAnswered ? Icons.check_circle : Icons.person, color: p.color, size: 16),
                            const SizedBox(width: 6),
                            Text(p.name, style: TextStyle(color: p.color, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerStatusRow() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: List.generate(_players.length, (i) {
          final p = _players[i];
          final answered = _playerAnswers[i] != null;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: answered ? p.color.withValues(alpha: 0.2) : _kCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: answered ? p.color : _kBorder,
                width: answered ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  answered ? Icons.check_rounded : Icons.hourglass_empty_rounded,
                  color: answered ? p.color : Colors.white.withValues(alpha: 0.3),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  p.name,
                  style: TextStyle(
                    color: answered ? Colors.white : Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Reveal ────────────────────────────────────────────────────────────────
  Widget _buildReveal() {
    final correct = _currentQuestion.correctIndex;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          color: _kCard,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kAnsD.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: _kAnsD, size: 36),
              ),
              const SizedBox(height: 10),
              const Text('Correct Answer', style: TextStyle(color: _kAnsD, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Text(
                _currentQuestion.options[correct],
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            itemCount: _players.length,
            itemBuilder: (_, i) {
              final p = _players[i];
              final ans = _playerAnswers[i];
              final isCorrect = ans == correct;
              final didAnswer = ans != null;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? _kAnsD.withValues(alpha: 0.1)
                      : didAnswer
                          ? _kAnsA.withValues(alpha: 0.1)
                          : _kCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isCorrect ? _kAnsD : didAnswer ? _kAnsA : _kBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: p.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text('${i + 1}', style: TextStyle(color: p.color, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          if (didAnswer)
                            Text(
                              _currentQuestion.options[ans],
                              style: TextStyle(
                                color: isCorrect ? _kAnsD : _kAnsA,
                                fontSize: 12,
                              ),
                            )
                          else
                            Text('No answer', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (p.lastGain > 0)
                          Text('+${p.lastGain}', style: const TextStyle(color: _kAnsD, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(
                          '${p.score} pts',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: isCorrect ? _kAnsD : didAnswer ? _kAnsA : Colors.white.withValues(alpha: 0.2),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccent,
                foregroundColor: _kBg,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _questionIndex + 1 < widget.quiz.questions.length
                    ? 'Next Question →'
                    : 'See Final Results 🏆',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Answer button ─────────────────────────────────────────────────────────────
class _AnswerButton extends StatelessWidget {
  final String label;
  final String text;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _AnswerButton({
    required this.label,
    required this.text,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Results screen ────────────────────────────────────────────────────────────
class KahootResultsScreen extends StatelessWidget {
  final BeaconQuizModel quiz;
  final List<KahootPlayer> players;

  const KahootResultsScreen({super.key, required this.quiz, required this.players});

  @override
  Widget build(BuildContext context) {
    final sorted = List<KahootPlayer>.from(players)
      ..sort((a, b) => b.score.compareTo(a.score));
    final winner = sorted.first;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildWinnerBanner(winner),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                itemCount: sorted.length,
                itemBuilder: (_, i) => _buildRankRow(sorted[i], i + 1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context, '/home', (route) => false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: _kBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Home'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Play Again', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(context);
                        final resetPlayers = players.map((p) => KahootPlayer(
                          id: p.id,
                          name: p.name,
                          color: p.color,
                        )).toList();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => KahootGameScreen(quiz: quiz, players: resetPlayers),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kAccent,
                        foregroundColor: _kBg,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWinnerBanner(KahootPlayer winner) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF2A0E3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [winner.color.withValues(alpha: 0.4), Colors.transparent],
                  ),
                ),
              ),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: winner.color.withValues(alpha: 0.2),
                  border: Border.all(color: winner.color, width: 2),
                ),
                child: Center(
                  child: Text(
                    winner.name.isNotEmpty ? winner.name[0].toUpperCase() : '?',
                    style: TextStyle(color: winner.color, fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: _kAnsC,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('🏆  Winner!', style: TextStyle(color: _kAnsC, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(
            winner.name,
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
          ),
          Text(
            '${winner.score} points',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildRankRow(KahootPlayer p, int rank) {
    const medals = ['🥇', '🥈', '🥉'];
    final medal = rank <= 3 ? medals[rank - 1] : '$rank.';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: rank == 1 ? _kAnsC.withValues(alpha: 0.08) : _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: rank == 1 ? _kAnsC.withValues(alpha: 0.4) : _kBorder,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(medal, style: const TextStyle(fontSize: 20)),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: p.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: p.color.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                style: TextStyle(color: p.color, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${p.score}',
                style: TextStyle(
                  color: rank == 1 ? _kAnsC : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              Text(
                'points',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Phase enum ────────────────────────────────────────────────────────────────
enum _Phase { countdown, question, reveal }
