import 'package:flutter/material.dart';
import '../../models/beacon_quiz_model.dart';
import '../../services/beacon_quiz_service.dart';
import '../../constants/brand_colors.dart';

class BeaconQuizBuilderScreen extends StatefulWidget {
  final BeaconQuizModel? existing;
  final String creatorId;
  final String creatorName;

  const BeaconQuizBuilderScreen({
    super.key,
    this.existing,
    required this.creatorId,
    required this.creatorName,
  });

  @override
  State<BeaconQuizBuilderScreen> createState() =>
      _BeaconQuizBuilderScreenState();
}

class _BeaconQuizBuilderScreenState extends State<BeaconQuizBuilderScreen> {
  final _service = BeaconQuizService();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String _category = 'Know Your Rights';
  List<_EditableQuestion> _questions = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final q = widget.existing!;
      _titleController.text = q.title;
      _descController.text = q.description;
      _category = q.category;
      _questions = q.questions
          .map((qq) => _EditableQuestion.fromQuestion(qq))
          .toList();
    }
    if (_questions.isEmpty) _addQuestion();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _addQuestion() {
    setState(() => _questions.add(_EditableQuestion()));
  }

  void _removeQuestion(int index) {
    if (_questions.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('A quiz must have at least one question')),
      );
      return;
    }
    setState(() => _questions.removeAt(index));
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a quiz title')),
      );
      return;
    }
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.questionController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Question ${i + 1} text is required')),
        );
        return;
      }
      for (int j = 0; j < q.optionControllers.length; j++) {
        if (q.optionControllers[j].text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Question ${i + 1}: Option ${j + 1} is required')),
          );
          return;
        }
      }
    }

    setState(() => _isSaving = true);
    try {
      final questions = _questions
          .map((q) => BeaconQuizQuestion(
                question: q.questionController.text.trim(),
                imageUrl: q.imageUrlController.text.trim().isEmpty
                    ? null
                    : q.imageUrlController.text.trim(),
                options:
                    q.optionControllers.map((c) => c.text.trim()).toList(),
                correctIndex: q.correctIndex,
                timeLimitSeconds: q.timeLimit,
              ))
          .toList();

      final isEdit = widget.existing != null;
      final quiz = BeaconQuizModel(
        id: isEdit
            ? widget.existing!.id
            : _service.generateId(),
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _category,
        createdBy: isEdit
            ? widget.existing!.createdBy
            : widget.creatorId,
        createdByName: isEdit
            ? widget.existing!.createdByName
            : widget.creatorName,
        createdAt:
            isEdit ? widget.existing!.createdAt : DateTime.now(),
        questions: questions,
      );

      if (isEdit) {
        await _service.updateQuiz(quiz);
      } else {
        await _service.saveQuiz(quiz);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Quiz updated!' : 'Quiz created!'),
            backgroundColor: const Color(0xFF43A047),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Quiz' : 'Create Quiz'),
        backgroundColor: BeaconColors.vibrantOrange,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Save',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.quiz, color: BeaconColors.vibrantOrange),
              const SizedBox(width: 8),
              Text(
                'Questions (${_questions.length})',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._questions
              .asMap()
              .entries
              .map((e) => _buildQuestionCard(e.key, e.value)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _addQuestion,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add Question'),
            style: OutlinedButton.styleFrom(
              foregroundColor: BeaconColors.vibrantOrange,
              side: const BorderSide(color: BeaconColors.vibrantOrange),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2D42),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quiz Details',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _field(_titleController, 'Quiz Title', Icons.title),
          const SizedBox(height: 10),
          _field(_descController, 'Description (optional)',
              Icons.description,
              maxLines: 2),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _category,
            dropdownColor: const Color(0xFF1A2D42),
            decoration: _inputDecor('Category', Icons.category),
            items: BeaconQuizService.quizCategories
                .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c,
                        style: const TextStyle(color: Colors.white))))
                .toList(),
            onChanged: (v) =>
                setState(() => _category = v ?? 'Know Your Rights'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index, _EditableQuestion q) {
    final answerColors = [
      const Color(0xFFE53935),
      const Color(0xFF1E88E5),
      const Color(0xFFFDD835),
      const Color(0xFF43A047),
    ];
    final answerLabels = ['A', 'B', 'C', 'D'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2D42),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: BeaconColors.vibrantOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Q${index + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: BeaconColors.vibrantOrange),
                ),
              ),
              const Spacer(),
              DropdownButton<int>(
                value: q.timeLimit,
                dropdownColor: const Color(0xFF1A2D42),
                underline: const SizedBox(),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                items: const [
                  DropdownMenuItem(
                      value: 10,
                      child: Text('10s',
                          style: TextStyle(color: Colors.white70))),
                  DropdownMenuItem(
                      value: 20,
                      child: Text('20s',
                          style: TextStyle(color: Colors.white70))),
                  DropdownMenuItem(
                      value: 30,
                      child: Text('30s',
                          style: TextStyle(color: Colors.white70))),
                  DropdownMenuItem(
                      value: 60,
                      child: Text('60s',
                          style: TextStyle(color: Colors.white70))),
                ],
                onChanged: (v) =>
                    setState(() => q.timeLimit = v ?? 20),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 20),
                onPressed: () => _removeQuestion(index),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _field(q.questionController, 'Question text', Icons.help_outline,
              maxLines: 2),
          const SizedBox(height: 8),
          _field(q.imageUrlController, 'Image URL (optional)',
              Icons.image_outlined),
          const SizedBox(height: 12),
          const Text('Answers — tap circle to mark correct:',
              style: TextStyle(fontSize: 12, color: Colors.white54)),
          const SizedBox(height: 8),
          ...List.generate(4, (i) {
            final isCorrect = q.correctIndex == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        setState(() => q.correctIndex = i),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? answerColors[i]
                            : answerColors[i].withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: answerColors[i], width: 2),
                      ),
                      child: Center(
                        child: Text(
                          answerLabels[i],
                          style: TextStyle(
                            color:
                                isCorrect ? Colors.white : answerColors[i],
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: q.optionControllers[i],
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Option ${i + 1}',
                        hintStyle:
                            const TextStyle(color: Colors.white38),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: const Color(0xFF0D1B2A),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: answerColors[i]
                                    .withValues(alpha: 0.4))),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: isCorrect
                                  ? answerColors[i]
                                  : Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: answerColors[i], width: 2),
                        ),
                      ),
                    ),
                  ),
                  if (isCorrect) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.check_circle,
                        color: Color(0xFF43A047), size: 20),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecor(label, icon),
    );
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      prefixIcon:
          Icon(icon, color: BeaconColors.vibrantOrange, size: 20),
      filled: true,
      fillColor: const Color(0xFF0D1B2A),
      border:
          OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
            color: BeaconColors.vibrantOrange, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}

class _EditableQuestion {
  final TextEditingController questionController;
  final TextEditingController imageUrlController;
  final List<TextEditingController> optionControllers;
  int correctIndex;
  int timeLimit;

  _EditableQuestion()
      : questionController = TextEditingController(),
        imageUrlController = TextEditingController(),
        optionControllers =
            List.generate(4, (_) => TextEditingController()),
        correctIndex = 0,
        timeLimit = 20;

  factory _EditableQuestion.fromQuestion(BeaconQuizQuestion qq) {
    final e = _EditableQuestion();
    e.questionController.text = qq.question;
    e.imageUrlController.text = qq.imageUrl ?? '';
    for (int i = 0; i < qq.options.length && i < 4; i++) {
      e.optionControllers[i].text = qq.options[i];
    }
    e.correctIndex = qq.correctIndex;
    e.timeLimit = qq.timeLimitSeconds;
    return e;
  }
}
