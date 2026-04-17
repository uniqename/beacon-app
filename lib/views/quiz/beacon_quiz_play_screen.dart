import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/beacon_quiz_model.dart';
import '../../services/beacon_quiz_service.dart';
import '../../constants/brand_colors.dart';

class BeaconQuizPlayScreen extends StatefulWidget {
  final BeaconQuizModel quiz;
  final String userId;
  final String userName;

  const BeaconQuizPlayScreen({
    super.key,
    required this.quiz,
    required this.userId,
    required this.userName,
  });

  @override
  State<BeaconQuizPlayScreen> createState() => _BeaconQuizPlayScreenState();
}

class _BeaconQuizPlayScreenState extends State<BeaconQuizPlayScreen>
    with TickerProviderStateMixin {
  int _questionIndex = 0;
  int _score = 0;
  int? _selectedAnswer;
  bool _answered = false;
  bool _showCountdown = true;
  int _countdown = 3;

  AnimationController? _timerController;
  Animation<double>? _timerAnim;
  late AnimationController _burstController;
  late Animation<double> _burstScale;

  int _earnedPts = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _burstController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _burstScale = Tween<double>(begin: 0.5, end: 1.4).animate(
        CurvedAnimation(parent: _burstController, curve: Curves.elasticOut));
    _initTimerFor(_currentQuestion);
    _startCountdown();
  }

  void _initTimerFor(BeaconQuizQuestion q) {
    _timerController?.dispose();
    _timerController = AnimationController(
      duration: Duration(seconds: q.timeLimitSeconds),
      vsync: this,
    );
    _timerAnim = Tween<double>(begin: 1.0, end: 0.0).animate(_timerController!);
    _timerController!.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_answered) {
        _handleAnswer(null);
      }
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        if (mounted) {
          setState(() => _showCountdown = false);
          _timerController!.forward();
        }
      } else {
        if (mounted) setState(() => _countdown--);
      }
    });
  }

  BeaconQuizQuestion get _currentQuestion =>
      widget.quiz.questions[_questionIndex];

  bool get _isLastQuestion =>
      _questionIndex == widget.quiz.questions.length - 1;

  @override
  void dispose() {
    _timerController?.dispose();
    _burstController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _handleAnswer(int? index) {
    if (_answered) return;
    _timerController?.stop();
    setState(() {
      _selectedAnswer = index;
      _answered = true;
    });

    if (index == _currentQuestion.correctIndex) {
      final timeRatio = _timerAnim?.value ?? 0.5;
      _earnedPts = (500 + (500 * timeRatio)).round();
      setState(() => _score += _earnedPts);
      _burstController.forward(from: 0);
    } else {
      _earnedPts = 0;
    }

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      if (_isLastQuestion) {
        _saveAndShowResult();
      } else {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      _questionIndex++;
      _selectedAnswer = null;
      _answered = false;
      _countdown = 3;
      _showCountdown = true;
    });
    _initTimerFor(_currentQuestion);
    _startCountdown();
  }

  void _saveAndShowResult() async {
    await BeaconQuizService().saveScore(
      quizId: widget.quiz.id,
      quizTitle: widget.quiz.title,
      userId: widget.userId,
      userName: widget.userName,
      score: _score,
      totalQuestions: widget.quiz.questions.length,
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_showCountdown) return _buildCountdown();
    if (_answered && _isLastQuestion && !(_timerController?.isAnimating ?? false)) {
      return _buildResultScreen();
    }
    return _buildQuestion();
  }

  Widget _buildCountdown() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$_countdown',
              style: const TextStyle(
                  color: BeaconColors.vibrantOrange,
                  fontSize: 96,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Question ${_questionIndex + 1} of ${widget.quiz.questions.length}',
              style: const TextStyle(color: Colors.white60, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    final q = _currentQuestion;
    final tileColors = [
      const Color(0xFFE53935),
      const Color(0xFF1E88E5),
      const Color(0xFFFDD835),
      const Color(0xFF43A047),
    ];
    final tileIcons = [
      Icons.change_history,
      Icons.diamond,
      Icons.circle,
      Icons.square,
    ];

    return WillPopScope(
      onWillPop: () async {
        _confirmQuit();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1B2A),
        body: SafeArea(
          child: Column(
            children: [
              // Top bar — fixed
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: _confirmQuit,
                    ),
                    Expanded(child: _buildProgressPills()),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: BeaconColors.vibrantOrange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_score pts',
                        style: const TextStyle(
                            color: BeaconColors.vibrantOrange,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // Timer — fixed
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: AnimatedBuilder(
                  animation: _timerAnim ?? const AlwaysStoppedAnimation(1.0),
                  builder: (_, __) {
                    final ratio = _timerAnim?.value ?? 1.0;
                    final color = ratio > 0.5
                        ? const Color(0xFF43A047)
                        : ratio > 0.25
                            ? const Color(0xFFFDD835)
                            : const Color(0xFFE53935);
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            value: ratio,
                            strokeWidth: 5,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            color: color,
                          ),
                        ),
                        Text(
                          '${(ratio * q.timeLimitSeconds).ceil()}',
                          style: TextStyle(
                              color: color,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Question + answers — scrollable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    children: [
                      // Question card
                      Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (q.imageUrl != null && q.imageUrl!.isNotEmpty) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    q.imageUrl!,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              Text(
                                q.question,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Answer tiles 2×2 — shrinkWrap so scrollable
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.6,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: List.generate(4, (i) {
                          final isSelected = _selectedAnswer == i;
                          final isCorrect =
                              _answered && i == _currentQuestion.correctIndex;
                          final isWrong =
                              _answered && isSelected && !isCorrect;

                          Color tileColor = tileColors[i];
                          if (_answered) {
                            if (isCorrect) {
                              tileColor = const Color(0xFF43A047);
                            } else if (isWrong) {
                              tileColor = Colors.grey.shade700;
                            } else {
                              tileColor = tileColors[i].withValues(alpha: 0.35);
                            }
                          }

                          return GestureDetector(
                            onTap: () => _handleAnswer(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: tileColor,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(tileIcons[i],
                                          color: Colors.white70, size: 24),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        child: Text(
                                          q.options[i],
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isCorrect)
                                    const Icon(Icons.check_circle,
                                        color: Colors.white, size: 40),
                                  if (isWrong)
                                    const Icon(Icons.cancel,
                                        color: Colors.white70, size: 40),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),

                      // +pts burst
                      if (_answered && _earnedPts > 0) ...[
                        const SizedBox(height: 12),
                        ScaleTransition(
                          scale: _burstScale,
                          child: Text(
                            '+$_earnedPts pts!',
                            style: const TextStyle(
                              color: BeaconColors.vibrantOrange,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressPills() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.quiz.questions.length, (i) {
        Color c;
        if (i < _questionIndex) {
          c = const Color(0xFF43A047);
        } else if (i == _questionIndex) {
          c = BeaconColors.vibrantOrange;
        } else {
          c = Colors.white24;
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: i == _questionIndex ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildResultScreen() {
    final total = widget.quiz.questions.length;
    final maxScore = total * 1000;
    final pct = maxScore > 0 ? (_score / maxScore * 100).round() : 0;
    final medal = pct >= 80
        ? '🏆'
        : pct >= 60
            ? '🥈'
            : pct >= 40
                ? '🥉'
                : '⭐';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(medal, style: const TextStyle(fontSize: 80)),
              const SizedBox(height: 20),
              const Text('Quiz Complete!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                widget.quiz.title,
                style: const TextStyle(color: Colors.white60, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2D42),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      '$_score',
                      style: const TextStyle(
                          color: BeaconColors.vibrantOrange,
                          fontSize: 56,
                          fontWeight: FontWeight.bold),
                    ),
                    const Text('points',
                        style: TextStyle(color: Colors.white54, fontSize: 16)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.percent,
                            color: Colors.white54, size: 16),
                        const SizedBox(width: 4),
                        Text('$pct% accuracy',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _restartQuiz(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Play Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BeaconColors.vibrantOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white60,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Quiz List'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context, '/home', (route) => false),
                      icon: const Icon(Icons.home_rounded),
                      label: const Text('Home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A2D42),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _restartQuiz() {
    setState(() {
      _questionIndex = 0;
      _score = 0;
      _selectedAnswer = null;
      _answered = false;
      _countdown = 3;
      _showCountdown = true;
    });
    _initTimerFor(_currentQuestion);
    _startCountdown();
  }

  void _confirmQuit() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quit Quiz?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Playing'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Quit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
