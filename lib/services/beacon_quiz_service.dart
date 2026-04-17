import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/beacon_quiz_model.dart';

class BeaconQuizService {
  static final BeaconQuizService _instance = BeaconQuizService._internal();
  factory BeaconQuizService() => _instance;
  BeaconQuizService._internal();

  final _uuid = const Uuid();
  static const _customKey = 'beacon_custom_quizzes';
  static const _scoresKey = 'beacon_quiz_scores';

  String generateId() => _uuid.v4();

  // ── Built-in trauma-informed educational quizzes ────────────────────────────
  static final List<BeaconQuizModel> _seedQuizzes = [
    BeaconQuizModel(
      id: 'seed-know-your-rights',
      title: 'Know Your Rights',
      description: 'Learn about Ghana\'s domestic violence laws and your legal protections.',
      category: 'Know Your Rights',
      createdBy: 'system',
      createdByName: 'Beacon',
      createdAt: DateTime(2024, 1, 1),
      questions: const [
        BeaconQuizQuestion(
          question: 'What is the name of Ghana\'s law that protects domestic violence victims?',
          options: [
            'Criminal Offences Act',
            'Domestic Violence Act 732 (2007)',
            'Family Protection Law',
            'Women\'s Rights Decree',
          ],
          correctIndex: 1,
          timeLimitSeconds: 30,
        ),
        BeaconQuizQuestion(
          question: 'DOVVSU stands for which Ghana Police unit?',
          options: [
            'Domestic Violence & Victim Support Unit',
            'Department of Violence & Victim Services',
            'Domestic Violence & Victim Safety Unit',
            'Division of Victims & Violence Support',
          ],
          correctIndex: 0,
          timeLimitSeconds: 20,
        ),
        BeaconQuizQuestion(
          question: 'Which of these is a form of domestic violence under Ghana\'s DV Act?',
          options: [
            'Only physical abuse',
            'Only sexual abuse',
            'Physical, emotional, economic, and sexual abuse',
            'Only abuse that causes visible injuries',
          ],
          correctIndex: 2,
          timeLimitSeconds: 25,
        ),
        BeaconQuizQuestion(
          question: 'What can a court issue to stop an abuser from contacting you?',
          options: [
            'A court summons',
            'A protection order',
            'A restraining fee',
            'A police caution letter',
          ],
          correctIndex: 1,
          timeLimitSeconds: 20,
        ),
        BeaconQuizQuestion(
          question: 'FIDA Ghana provides which type of free service?',
          options: [
            'Medical care for survivors',
            'Shelter and housing',
            'Legal aid and court representation',
            'Job placement services',
          ],
          correctIndex: 2,
          timeLimitSeconds: 20,
        ),
        BeaconQuizQuestion(
          question: 'If you are in immediate danger in Ghana, which number should you call first?',
          options: ['191', '999', '112', '18555'],
          correctIndex: 1,
          timeLimitSeconds: 15,
        ),
      ],
    ),

    BeaconQuizModel(
      id: 'seed-safety-smarts',
      title: 'Safety Smarts',
      description: 'Learn safety planning strategies and how to recognize warning signs.',
      category: 'Safety Smarts',
      createdBy: 'system',
      createdByName: 'Beacon',
      createdAt: DateTime(2024, 1, 1),
      questions: const [
        BeaconQuizQuestion(
          question: 'A safety plan is best described as:',
          options: [
            'A list of things the abuser has done wrong',
            'A personalized strategy to increase your safety',
            'A report filed at the police station',
            'A document for the court',
          ],
          correctIndex: 1,
          timeLimitSeconds: 25,
        ),
        BeaconQuizQuestion(
          question: 'Which item is MOST important to include in an emergency bag?',
          options: [
            'Jewelry and valuables',
            'Important documents (ID, birth certificates)',
            'Extra shoes',
            'A laptop',
          ],
          correctIndex: 1,
          timeLimitSeconds: 20,
        ),
        BeaconQuizQuestion(
          question: 'A code word or signal with trusted friends is useful because:',
          options: [
            'It sounds exciting',
            'It allows you to call for help without alerting the abuser',
            'It is required by police',
            'It helps prove abuse happened',
          ],
          correctIndex: 1,
          timeLimitSeconds: 25,
        ),
        BeaconQuizQuestion(
          question: 'Which behavior is a common warning sign (red flag) of an abusive relationship?',
          options: [
            'Encouraging you to see your friends and family',
            'Checking your phone without permission and isolating you',
            'Asking about your day',
            'Planning future goals together',
          ],
          correctIndex: 1,
          timeLimitSeconds: 25,
        ),
        BeaconQuizQuestion(
          question: 'Clearing your browser history on your phone is recommended because:',
          options: [
            'It speeds up your phone',
            'It protects your privacy from an abuser who monitors your device',
            'It is required to access help hotlines',
            'It prevents apps from crashing',
          ],
          correctIndex: 1,
          timeLimitSeconds: 20,
        ),
      ],
    ),

    BeaconQuizModel(
      id: 'seed-healthy-relationships',
      title: 'Healthy Relationships',
      description: 'Understand what healthy and unhealthy relationship patterns look like.',
      category: 'Healthy Relationships',
      createdBy: 'system',
      createdByName: 'Beacon',
      createdAt: DateTime(2024, 1, 1),
      questions: const [
        BeaconQuizQuestion(
          question: 'Which of these best describes a healthy relationship?',
          options: [
            'One partner makes all the decisions',
            'Both partners respect each other\'s boundaries',
            'Jealousy shows how much they care',
            'One partner controls the finances',
          ],
          correctIndex: 1,
          timeLimitSeconds: 25,
        ),
        BeaconQuizQuestion(
          question: 'Emotional abuse can include:',
          options: [
            'Only physical hitting or pushing',
            'Name-calling, humiliation, and threats',
            'Disagreements about money',
            'Forgetting important dates',
          ],
          correctIndex: 1,
          timeLimitSeconds: 20,
        ),
        BeaconQuizQuestion(
          question: 'Gaslighting in a relationship means:',
          options: [
            'Using gas appliances dangerously',
            'Being overly romantic',
            'Making someone doubt their own memory and perceptions',
            'Ignoring phone calls',
          ],
          correctIndex: 2,
          timeLimitSeconds: 25,
        ),
        BeaconQuizQuestion(
          question: 'Economic abuse happens when a partner:',
          options: [
            'Spends money on gifts for you',
            'Controls your money, stops you from working, or ruins your credit',
            'Asks you to save more money',
            'Pays all the household bills',
          ],
          correctIndex: 1,
          timeLimitSeconds: 25,
        ),
        BeaconQuizQuestion(
          question: 'Which statement about abuse is TRUE?',
          options: [
            'Abuse only happens in poor families',
            'Victims can easily just leave',
            'Abuse affects people of all backgrounds and leaving can be very dangerous',
            'Abuse always involves physical violence',
          ],
          correctIndex: 2,
          timeLimitSeconds: 30,
        ),
      ],
    ),

    BeaconQuizModel(
      id: 'seed-healing-journey',
      title: 'The Healing Journey',
      description: 'Learn about trauma, recovery, and taking care of your mental health.',
      category: 'Healing Journey',
      createdBy: 'system',
      createdByName: 'Beacon',
      createdAt: DateTime(2024, 1, 1),
      questions: const [
        BeaconQuizQuestion(
          question: 'Trauma can affect survivors in which of these ways?',
          options: [
            'Only emotionally',
            'Only physically',
            'Emotionally, physically, and mentally',
            'It only affects children',
          ],
          correctIndex: 2,
          timeLimitSeconds: 20,
        ),
        BeaconQuizQuestion(
          question: 'Which of these is a healthy self-care practice for survivors?',
          options: [
            'Isolating from everyone',
            'Connecting with a trusted support person or counselor',
            'Blaming yourself for what happened',
            'Ignoring your feelings',
          ],
          correctIndex: 1,
          timeLimitSeconds: 25,
        ),
        BeaconQuizQuestion(
          question: 'The healing journey from abuse is:',
          options: [
            'Quick and straightforward',
            'The same for everyone',
            'Unique for each person and takes time',
            'Complete once you leave the abuser',
          ],
          correctIndex: 2,
          timeLimitSeconds: 25,
        ),
        BeaconQuizQuestion(
          question: 'PTSD (Post-Traumatic Stress Disorder) can include which symptom?',
          options: [
            'Feeling too happy',
            'Flashbacks and nightmares about the traumatic event',
            'Forgetting how to speak',
            'Growing taller',
          ],
          correctIndex: 1,
          timeLimitSeconds: 20,
        ),
        BeaconQuizQuestion(
          question: 'Talking to a counselor or therapist after abuse is:',
          options: [
            'A sign of weakness',
            'Only for people with serious mental illness',
            'A sign of strength and a key part of healing',
            'Not necessary if you feel okay',
          ],
          correctIndex: 2,
          timeLimitSeconds: 20,
        ),
      ],
    ),

    BeaconQuizModel(
      id: 'seed-financial-independence',
      title: 'Financial Independence',
      description: 'Build financial literacy and learn strategies for economic freedom.',
      category: 'Financial Independence',
      createdBy: 'system',
      createdByName: 'Beacon',
      createdAt: DateTime(2024, 1, 1),
      questions: const [
        BeaconQuizQuestion(
          question: 'Financial abuse can look like:',
          options: [
            'Your partner paying shared bills',
            'Being prevented from working or having your own money',
            'Sharing a joint bank account',
            'Saving money together',
          ],
          correctIndex: 1,
          timeLimitSeconds: 25,
        ),
        BeaconQuizQuestion(
          question: 'A hidden savings strategy is useful because:',
          options: [
            'It helps you save for a vacation',
            'It builds a private emergency fund in case you need to leave safely',
            'It earns more interest than normal accounts',
            'Banks require it',
          ],
          correctIndex: 1,
          timeLimitSeconds: 25,
        ),
        BeaconQuizQuestion(
          question: 'Which organization in Ghana can help survivors access micro-loans or financial support?',
          options: [
            'Ghana Revenue Authority',
            'NGOs and women\'s empowerment programs like Ark Foundation',
            'Ghana Stock Exchange',
            'National Insurance Commission',
          ],
          correctIndex: 1,
          timeLimitSeconds: 25,
        ),
        BeaconQuizQuestion(
          question: 'A budget helps a survivor by:',
          options: [
            'Spending all available money',
            'Tracking income and expenses to plan for independence',
            'Hiding money from authorities',
            'Avoiding the need to work',
          ],
          correctIndex: 1,
          timeLimitSeconds: 20,
        ),
        BeaconQuizQuestion(
          question: 'Skills training programs help survivors by:',
          options: [
            'Keeping them busy',
            'Building income-generating skills for financial independence',
            'Requiring them to stay in shelters',
            'Replacing the need for legal aid',
          ],
          correctIndex: 1,
          timeLimitSeconds: 20,
        ),
      ],
    ),

    BeaconQuizModel(
      id: 'seed-community-resources',
      title: 'Community Resources',
      description: 'Know where to find help across Ghana — key organizations and services.',
      category: 'Community Resources',
      createdBy: 'system',
      createdByName: 'Beacon',
      createdAt: DateTime(2024, 1, 1),
      questions: const [
        BeaconQuizQuestion(
          question: 'The Ark Foundation Ghana primarily provides:',
          options: [
            'Legal court representation only',
            'Emergency shelter, counseling, and advocacy for DV survivors',
            'Police services',
            'Hospital medical care',
          ],
          correctIndex: 1,
          timeLimitSeconds: 25,
        ),
        BeaconQuizQuestion(
          question: 'Korle Bu Teaching Hospital can help survivors with:',
          options: [
            'Only broken bones',
            'Emergency care, forensic examination, and DV documentation',
            'Legal advice and court paperwork',
            'Shelter and safe housing',
          ],
          correctIndex: 1,
          timeLimitSeconds: 25,
        ),
        BeaconQuizQuestion(
          question: 'If you need free legal help in Ghana, which organization should you contact?',
          options: [
            'Ghana Police Headquarters',
            'FIDA Ghana or the Legal Aid Commission',
            'Korle Bu Hospital Social Work',
            'National Communications Authority',
          ],
          correctIndex: 1,
          timeLimitSeconds: 25,
        ),
        BeaconQuizQuestion(
          question: 'Oasis Ghana provides which service to survivors?',
          options: [
            'Free legal representation',
            'Safe housing and holistic support',
            'Police investigations',
            'Medical forensic exams',
          ],
          correctIndex: 1,
          timeLimitSeconds: 20,
        ),
        BeaconQuizQuestion(
          question: 'The Beacon of New Beginnings app is designed to help survivors by:',
          options: [
            'Replacing police services',
            'Providing safety tools, resources, community support, and partner connections',
            'Providing medical diagnoses',
            'Offering housing directly',
          ],
          correctIndex: 1,
          timeLimitSeconds: 25,
        ),
      ],
    ),
  ];

  Future<List<BeaconQuizModel>> getAllQuizzes() async {
    final custom = await _getCustomQuizzes();
    return [..._seedQuizzes, ...custom];
  }

  Future<List<BeaconQuizModel>> getQuizzesByCategory(String category) async {
    final all = await getAllQuizzes();
    return all.where((q) => q.category == category).toList();
  }

  Future<void> saveQuiz(BeaconQuizModel quiz) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customKey);
    List<Map<String, dynamic>> list = [];
    if (raw != null) {
      list = List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
    }
    list.add(quiz.toJson());
    await prefs.setString(_customKey, jsonEncode(list));
  }

  Future<void> updateQuiz(BeaconQuizModel quiz) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customKey);
    List<Map<String, dynamic>> list = [];
    if (raw != null) {
      list = List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
    }
    final idx = list.indexWhere((q) => q['id'] == quiz.id);
    if (idx >= 0) {
      list[idx] = quiz.toJson();
    } else {
      list.add(quiz.toJson());
    }
    await prefs.setString(_customKey, jsonEncode(list));
  }

  Future<void> deleteQuiz(String quizId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customKey);
    if (raw == null) return;
    List<Map<String, dynamic>> list =
        List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
    list.removeWhere((q) => q['id'] == quizId);
    await prefs.setString(_customKey, jsonEncode(list));
  }

  Future<void> saveScore({
    required String quizId,
    required String quizTitle,
    required String userId,
    required String userName,
    required int score,
    required int totalQuestions,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_scoresKey);
    List<Map<String, dynamic>> scores = [];
    if (raw != null) {
      scores = List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
    }
    scores.add({
      'quiz_id': quizId,
      'quiz_title': quizTitle,
      'user_id': userId,
      'user_name': userName,
      'score': score,
      'total_questions': totalQuestions,
      'played_at': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_scoresKey, jsonEncode(scores));
  }

  Future<List<Map<String, dynamic>>> getLeaderboard(String quizId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_scoresKey);
    if (raw == null) return [];
    final all = List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
    final quizScores = all.where((s) => s['quiz_id'] == quizId).toList()
      ..sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    return quizScores.take(10).toList();
  }

  Future<List<BeaconQuizModel>> _getCustomQuizzes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => BeaconQuizModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static const List<String> quizCategories = [
    'Know Your Rights',
    'Safety Smarts',
    'Healthy Relationships',
    'Healing Journey',
    'Financial Independence',
    'Community Resources',
  ];
}
