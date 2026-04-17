import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'ai_consent_service.dart';
import 'app_config_service.dart';

/// AI-powered case plan generator using Gemini.
///
/// When a Gemini API key is configured, sends the intake information to
/// Gemini and receives a structured JSON array of recommended programs.
/// Falls back to a smart rule-based generator when no API key is set.
class CaseAiService {
  static final CaseAiService _instance = CaseAiService._internal();
  factory CaseAiService() => _instance;
  CaseAiService._internal();

  GenerativeModel? _model;
  String? _modelOrgKey; // track which config the model was built for

  void _ensureModel() {
    final cfg = AppConfigService.instance.config;
    // Rebuild if org has changed (e.g. admin switched country)
    if (_model != null && _modelOrgKey == cfg.orgKey) return;
    final key = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (key.isEmpty) return;
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: key,
      systemInstruction: Content.system(
        'You are an expert case manager for "${cfg.orgName}", a '
        'domestic violence and vulnerable-persons support organisation in ${cfg.countryName}. '
        'When given client intake information, you produce a structured support '
        'plan as a JSON array. Each element is a program object. '
        'Respond ONLY with valid JSON — no markdown fences, no explanation.',
      ),
    );
    _modelOrgKey = cfg.orgKey;
  }

  /// Generates a list of program maps from intake data.
  ///
  /// Each map has the keys:
  ///   program_name, goal, priority, deadline_label, current_status_notes,
  ///   actions (list of strings)
  Future<List<Map<String, dynamic>>> generatePrograms({
    required String presentingSituation,
    required List<String> needsIdentified,
    String? additionalContext,
  }) async {
    _ensureModel();

    if (_model != null) {
      // Guard: never transmit data to Gemini without stored user consent.
      final consented = await AiConsentService.hasConsented();
      if (!consented) {
        developer.log('⚠️ [CaseAI] No AI consent — falling back to rule-based');
        return _generateRuleBased(
          situation: presentingSituation,
          needs: needsIdentified,
        );
      }
      return await _generateWithGemini(
        situation: presentingSituation,
        needs: needsIdentified,
        extra: additionalContext,
      );
    }

    developer.log('⚠️ [CaseAI] No Gemini key — using rule-based fallback');
    return _generateRuleBased(
      situation: presentingSituation,
      needs: needsIdentified,
    );
  }

  // ─── Gemini path ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _generateWithGemini({
    required String situation,
    required List<String> needs,
    String? extra,
  }) async {
    final needsList = needs.join(', ');
    final extraSection =
        extra != null && extra.isNotEmpty ? '\n\nAdditional context:\n$extra' : '';

    final prompt = '''
Client intake information:

Presenting situation:
$situation

Identified needs: $needsList$extraSection

Generate a personalised support plan for this client. For each recommended program area, return a JSON object with these exact keys:
- "program_name": short name of the support program
- "goal": specific, measurable goal tailored to this client's situation (2-3 sentences)
- "priority": one of exactly: "urgent", "high", "medium", "monitor", "ongoing"
- "deadline_label": human-readable timeline, e.g. "Within 30 days", "3 months", "Ongoing"
- "current_status_notes": current state and what needs to happen first (2-3 sentences)
- "actions": array of 4-6 specific, concrete action steps (strings)

Rules:
- Only include programs relevant to the identified needs and situation
- Always include a "Case Management" program as the first item
- Always include a "Psychosocial Support & Counselling" program
- Prioritise safety, housing, and psychosocial issues urgently when the situation indicates risk
- Use culturally sensitive language appropriate for ${AppConfigService.instance.config.countryName}. ${AppConfigService.instance.config.culturalContext}
- Do NOT wrap the JSON in markdown code fences
- Return ONLY a JSON array, nothing else

Example of a single program object:
{"program_name":"Education Support & Continuity","goal":"Ensure the client completes her academic programme without financial interruption.","priority":"high","deadline_label":"May 2026","current_status_notes":"Client is enrolled but fees are outstanding. Immediate payment needed.","actions":["Confirm outstanding tuition fees and due date","Arrange payment of fees within 2 weeks","Connect client with campus financial aid office","Explore bursary and scholarship options","Monitor academic performance monthly"]}
''';

    try {
      final response =
          await _model!.generateContent([Content.text(prompt)]);
      final text = (response.text ?? '').trim();
      developer.log('✅ [CaseAI] Gemini response received (${text.length} chars)');

      // Strip any accidental markdown fences
      final cleaned = text
          .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
          .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
          .trim();

      final decoded = jsonDecode(cleaned);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      throw FormatException('Expected a JSON array');
    } catch (e) {
      developer.log('⚠️ [CaseAI] Gemini generation failed, using fallback: $e');
      return _generateRuleBased(situation: situation, needs: needs);
    }
  }

  // ─── Rule-based fallback ─────────────────────────────────────────────────

  List<Map<String, dynamic>> _generateRuleBased({
    required String situation,
    required List<String> needs,
  }) {
    final lower = situation.toLowerCase();
    final programs = <Map<String, dynamic>>[];

    // Always: Case Management
    programs.add({
      'program_name': 'Case Management',
      'goal':
          'Maintain a complete, coordinated case file and serve as the primary '
          'Beacon point of contact throughout the client\'s support journey.',
      'priority': 'ongoing',
      'deadline_label': 'Ongoing',
      'current_status_notes':
          'Case opened. Initial intake completed. Regular check-ins to be scheduled.',
      'actions': [
        'Create and maintain complete case file with all supporting documents',
        'Schedule regular check-in meetings with client',
        'Coordinate communication between all programme areas',
        'Document all interventions and outcomes',
        'Conduct quarterly review and update plan as needed',
      ],
    });

    // Always: Psychosocial
    final psychoPriority = _containsAny(lower, [
      'trauma', 'abuse', 'violence', 'fear', 'depressed', 'grief',
      'loss', 'died', 'death', 'hurt', 'scared', 'isolated',
    ]) ? 'urgent' : 'high';
    programs.add({
      'program_name': 'Psychosocial Support & Counselling',
      'goal':
          'Address emotional trauma, grief, and psychological distress through '
          'professional counselling and peer support.',
      'priority': psychoPriority,
      'deadline_label': 'Within 30 days',
      'current_status_notes':
          'Psychosocial assessment needed immediately. Referral to trained '
          'counsellor to be arranged as a priority.',
      'actions': [
        'Complete initial psychosocial assessment',
        'Refer to trained counsellor specialising in trauma and grief',
        'Book and attend first counselling session within 2 weeks',
        'Assess for depression, anxiety, or PTSD indicators',
        'Establish regular emotional wellbeing check-ins',
        'Review counselling progress at each quarterly review',
      ],
    });

    final needsLower = needs.map((n) => n.toLowerCase()).toList();

    // Education
    if (_containsAnyList(needsLower, ['education']) ||
        _containsAny(lower, ['school', 'university', 'student', 'tuition', 'academic'])) {
      programs.add({
        'program_name': 'Education Support & Continuity',
        'goal':
            'Ensure the client completes their academic programme without '
            'financial or social interruption.',
        'priority': 'high',
        'deadline_label': 'Next semester',
        'current_status_notes':
            'Academic status and outstanding fees need to be confirmed. '
            'Financial support plan to be established.',
        'actions': [
          'Confirm current academic enrolment and outstanding fees',
          'Arrange payment of outstanding fees',
          'Connect client with campus pastoral or chaplaincy support',
          'Explore merit scholarships, bursaries, and financial aid',
          'Monitor academic performance and attendance',
          'Review education plan at next quarterly review',
        ],
      });
    }

    // Housing
    if (_containsAnyList(needsLower, ['housing']) ||
        _containsAny(lower, ['homeless', 'house', 'shelter', 'hostel', 'accommodation', 'evict', 'nowhere to go'])) {
      final housePriority = _containsAny(lower, [
        'homeless', 'nowhere', 'evict', 'kicked out',
      ]) ? 'urgent' : 'high';
      programs.add({
        'program_name': 'Housing Stability & Safety Planning',
        'goal':
            'Ensure safe, stable housing during and after the support period; '
            'prevent any forced return to an unsafe environment.',
        'priority': housePriority,
        'deadline_label': housePriority == 'urgent' ? 'Immediate' : '3 months',
        'current_status_notes':
            'Current housing situation to be assessed. Secure long-term '
            'accommodation plan needed.',
        'actions': [
          'Assess current housing situation and immediate safety',
          'Identify safe housing options (hostel, shelter, partner accommodation)',
          'Arrange safe housing if needed',
          'Create personal safety plan for contact with unsafe persons',
          'Assess housing contract timeline and plan for renewal',
          'Review housing plan at each quarterly review',
        ],
      });
    }

    // Community
    if (_containsAnyList(needsLower, ['community', 'social reintegration']) ||
        _containsAny(lower, ['isolated', 'alone', 'no friends', 'no family', 'estranged', 'rejected'])) {
      programs.add({
        'program_name': 'Community & Social Reintegration',
        'goal':
            'Rebuild a sense of community and belonging; establish a safe, '
            'supportive social network.',
        'priority': 'medium',
        'deadline_label': '3 months',
        'current_status_notes':
            'Client is socially isolated. Priority is connecting them with a '
            'safe community and peer support network.',
        'actions': [
          'Connect client with a church, community group, or fellowship',
          'Introduce client to campus or community support services',
          'Identify at least one peer mentor or trusted contact',
          'Explore community clubs, volunteering, or group activities',
          'Review social support network at quarterly review',
        ],
      });
    }

    // Economic / Skills
    if (_containsAnyList(needsLower, ['economic', 'skills', 'training', 'employment']) ||
        _containsAny(lower, ['job', 'work', 'income', 'skills', 'unemployed', 'financial', 'money'])) {
      programs.add({
        'program_name': 'Skills Training & Economic Empowerment',
        'goal':
            'Equip the client with practical skills and lay the foundation for '
            'financial independence.',
        'priority': 'medium',
        'deadline_label': '6 months',
        'current_status_notes':
            'Economic empowerment planning to begin once client is settled '
            'and emotionally stable.',
        'actions': [
          'Assess client\'s interests, strengths, and career aspirations',
          'Identify relevant skills training programmes',
          'Enroll in at least one skills course within 3 months',
          'Connect with BNB economic empowerment partners',
          'Develop a basic personal budget and financial literacy plan',
          'Review progress at 6-month follow-up',
        ],
      });
    }

    // Legal
    if (_containsAnyList(needsLower, ['legal', 'legal resources']) ||
        _containsAny(lower, ['police', 'court', 'arrest', 'legal', 'threat', 'ultimatum', 'forced', 'coerce'])) {
      final legalPriority = _containsAny(lower, [
        'threat', 'ultimatum', 'forced', 'coerce', 'criminal',
      ]) ? 'high' : 'monitor';
      programs.add({
        'program_name': 'Legal Resource Navigation',
        'goal':
            'Ensure the client understands their legal rights and that a '
            'referral pathway is ready if threats or coercion escalate.',
        'priority': legalPriority,
        'deadline_label':
            legalPriority == 'high' ? 'Within 30 days' : 'Ongoing — monitor',
        'current_status_notes':
            'Legal situation being monitored. Rights briefing to be provided. '
            'Legal aid partner identified for referral if needed.',
        'actions': [
          'Brief client on their legal rights and available protections',
          'Identify legal aid partner (LAWA or equivalent)',
          'Document any threats, ultimatums, or coercive incidents',
          'Establish clear escalation trigger for legal referral',
          'Review legal situation at each quarterly check-in',
        ],
      });
    }

    // Safety Planning (standalone if Safety is a need)
    if (_containsAnyList(needsLower, ['safety', 'safety planning']) &&
        !_containsAnyList(needsLower, ['housing'])) {
      programs.add({
        'program_name': 'Personal Safety Planning',
        'goal':
            'Create and maintain a practical safety plan that the client can '
            'activate immediately if their safety is threatened.',
        'priority': 'high',
        'deadline_label': 'Within 2 weeks',
        'current_status_notes':
            'Personal safety plan not yet created. Must be completed as a '
            'priority during first case management session.',
        'actions': [
          'Complete personal safety plan with client',
          'Identify safe contacts client can call in an emergency',
          'Identify safe locations client can go to',
          'Establish a code word with a trusted contact',
          'Save emergency numbers on client\'s phone',
          'Review safety plan at each check-in',
        ],
      });
    }

    // Healthcare
    if (_containsAnyList(needsLower, ['healthcare']) ||
        _containsAny(lower, ['health', 'medical', 'hospital', 'injured', 'injury', 'sick', 'illness'])) {
      programs.add({
        'program_name': 'Healthcare & Medical Support',
        'goal':
            'Ensure the client\'s physical health needs are addressed and '
            'access to healthcare is secured.',
        'priority': 'high',
        'deadline_label': 'Within 30 days',
        'current_status_notes':
            'Healthcare needs to be assessed. Referral to clinic or hospital '
            'to be arranged if required.',
        'actions': [
          'Conduct health needs assessment with client',
          'Arrange medical consultation if required',
          'Connect client with affordable healthcare options',
          'Follow up on any ongoing medical treatment',
          'Review healthcare needs at quarterly review',
        ],
      });
    }

    return programs;
  }

  bool _containsAny(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));

  bool _containsAnyList(List<String> list, List<String> keywords) =>
      keywords.any((k) => list.any((item) => item.contains(k)));
}
