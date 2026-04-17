class BeaconQuizQuestion {
  final String question;
  final String? imageUrl;
  final List<String> options;
  final int correctIndex;
  final int timeLimitSeconds;

  const BeaconQuizQuestion({
    required this.question,
    this.imageUrl,
    required this.options,
    required this.correctIndex,
    this.timeLimitSeconds = 20,
  });

  BeaconQuizQuestion copyWith({
    String? question,
    String? imageUrl,
    List<String>? options,
    int? correctIndex,
    int? timeLimitSeconds,
  }) =>
      BeaconQuizQuestion(
        question: question ?? this.question,
        imageUrl: imageUrl ?? this.imageUrl,
        options: options ?? this.options,
        correctIndex: correctIndex ?? this.correctIndex,
        timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      );

  factory BeaconQuizQuestion.fromJson(Map<String, dynamic> j) =>
      BeaconQuizQuestion(
        question: j['question'] as String,
        imageUrl: j['image_url'] as String?,
        options: List<String>.from(j['options'] as List),
        correctIndex: j['correct_index'] as int,
        timeLimitSeconds: j['time_limit_seconds'] as int? ?? 20,
      );

  Map<String, dynamic> toJson() => {
        'question': question,
        'image_url': imageUrl,
        'options': options,
        'correct_index': correctIndex,
        'time_limit_seconds': timeLimitSeconds,
      };
}

class BeaconQuizModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final List<BeaconQuizQuestion> questions;
  final bool isActive;

  const BeaconQuizModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.questions,
    this.isActive = true,
  });

  bool get isSystem => createdBy == 'system';

  factory BeaconQuizModel.fromJson(Map<String, dynamic> j) => BeaconQuizModel(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String? ?? '',
        category: j['category'] as String? ?? 'General',
        createdBy: j['created_by'] as String,
        createdByName: j['created_by_name'] as String? ?? 'Beacon',
        createdAt: DateTime.parse(j['created_at'] as String),
        questions: (j['questions'] as List)
            .map((q) => BeaconQuizQuestion.fromJson(q as Map<String, dynamic>))
            .toList(),
        isActive: j['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'created_by': createdBy,
        'created_by_name': createdByName,
        'created_at': createdAt.toIso8601String(),
        'questions': questions.map((q) => q.toJson()).toList(),
        'is_active': isActive,
      };
}
