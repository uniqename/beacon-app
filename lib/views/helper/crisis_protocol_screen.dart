import 'package:flutter/material.dart';
import '../../config/org_config.dart';
import '../../services/app_config_service.dart';

class CrisisProtocolScreen extends StatefulWidget {
  const CrisisProtocolScreen({super.key});

  @override
  State<CrisisProtocolScreen> createState() => _CrisisProtocolScreenState();
}

class _CrisisProtocolScreenState extends State<CrisisProtocolScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  OrgConfig get _cfg => AppConfigService.instance.config;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Crisis Protocol',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFB91C1C),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.red[100],
          labelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.checklist, size: 18), text: 'Assess'),
            Tab(icon: Icon(Icons.bolt, size: 18), text: 'Respond'),
            Tab(icon: Icon(Icons.shield, size: 18), text: 'Safety Plan'),
            Tab(icon: Icon(Icons.menu_book, size: 18), text: 'Reference'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _AssessTab(cfg: _cfg),
          _RespondTab(),
          _SafetyPlanGuideTab(),
          _ReferenceTab(cfg: _cfg),
        ],
      ),
    );
  }
}

// ─── Tab 1: Risk Assessment ──────────────────────────────────────────────────

class _AssessTab extends StatefulWidget {
  final OrgConfig cfg;
  const _AssessTab({required this.cfg});

  @override
  State<_AssessTab> createState() => _AssessTabState();
}

class _AssessTabState extends State<_AssessTab> {
  final Set<String> _checked = {};
  bool _showResult = false;

  static const _suicideFactors = [
    'Thinking about hurting themselves',
    'Has a specific plan',
    'Has access to means (pills, weapons)',
    'Has made preparations (notes, giving away things)',
    'Previous suicide attempt',
    'Under influence of alcohol or drugs',
  ];

  static const _violenceFactors = [
    'Thinking about hurting someone else',
    'Has a target in mind',
    'Has a plan',
    'Has access to weapons',
  ];

  static const _safetyFactors = [
    'Not safe right now',
    'Someone else is in danger',
    'Unable to state current location',
    'Severe impairment in judgement',
    'Active psychosis / hallucinations',
  ];

  String get _riskLevel {
    final c = _checked.length;
    final hasImminent = _checked.contains('Thinking about hurting themselves') &&
            _checked.contains('Has a specific plan') ||
        _checked.contains('Thinking about hurting someone else') &&
            _checked.contains('Has a plan') ||
        _checked.contains('Not safe right now') ||
        _checked.contains('Active psychosis / hallucinations');

    if (hasImminent || c >= 4) return 'IMMINENT';
    if (c >= 3) return 'HIGH';
    if (c >= 1) return 'MODERATE';
    return 'LOW';
  }

  Color get _riskColor {
    switch (_riskLevel) {
      case 'IMMINENT':
        return Colors.red[700]!;
      case 'HIGH':
        return Colors.orange[700]!;
      case 'MODERATE':
        return Colors.amber[700]!;
      default:
        return Colors.green[700]!;
    }
  }

  String get _riskResponse {
    switch (_riskLevel) {
      case 'IMMINENT':
        return 'DO NOT leave client alone.\nCall 911 or mobile crisis team NOW.\nNotify supervisor immediately.\nStay on the line until help arrives.';
      case 'HIGH':
        return 'Develop safety plan together.\nIncrease contact frequency.\nConnect to mental health services within 24 hours.\nConsider hospitalization — discuss with supervisor.';
      case 'MODERATE':
        return 'Create a safety plan.\nIncrease monitoring and check-ins.\nConnect to appropriate services.\nSchedule follow-up within 48 hours.';
      default:
        return 'Continue standard case management.\nMaintain therapeutic relationship.\nRoutine monitoring — no immediate escalation needed.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.red[700], size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Check all risk factors present. The risk level updates in real time.',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.red[800]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _riskSection('Suicide Risk', Icons.warning_amber, Colors.red,
              _suicideFactors),
          _riskSection('Violence / Homicide Risk', Icons.dangerous,
              Colors.deepOrange, _violenceFactors),
          _riskSection(
              'Current Safety', Icons.security, Colors.orange, _safetyFactors),

          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _showResult = true),
              icon: const Icon(Icons.assessment),
              label: const Text('Get Risk Level & Response'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          if (_showResult) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _riskColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _riskColor, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _riskLevel == 'IMMINENT'
                            ? Icons.crisis_alert
                            : _riskLevel == 'HIGH'
                                ? Icons.warning
                                : _riskLevel == 'MODERATE'
                                    ? Icons.info
                                    : Icons.check_circle,
                        color: _riskColor,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('RISK LEVEL',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: _riskColor,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1)),
                          Text(
                            _riskLevel,
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: _riskColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Required Response:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(_riskResponse,
                      style: const TextStyle(fontSize: 14, height: 1.6)),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _checked.clear()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Clear & Reassess'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: _riskColor),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          _infoBox(
            '💬 Key Questions to Ask',
            _riskLevel == 'IMMINENT' || _checked.contains('Thinking about hurting themselves')
                ? '"Are you safe right now?"\n"Do you have access to means?"\n"What has stopped you from acting on these thoughts?"'
                : '"Are you thinking about hurting yourself or anyone else?"\n"Are you safe right now?"\n"Where are you currently?"',
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _riskSection(
      String title, IconData icon, Color color, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey[200]!,
                  blurRadius: 4,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            children: items.map((item) {
              final checked = _checked.contains(item);
              return CheckboxListTile(
                dense: true,
                value: checked,
                title: Text(item,
                    style: TextStyle(
                        fontSize: 13,
                        color: checked ? color : Colors.grey[800])),
                activeColor: color,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _checked.add(item);
                  } else {
                    _checked.remove(item);
                  }
                  _showResult = false;
                }),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _infoBox(String title, String body, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: color)),
          const SizedBox(height: 6),
          Text(body,
              style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5)),
        ],
      ),
    );
  }
}

// ─── Tab 2: Respond ──────────────────────────────────────────────────────────

class _RespondTab extends StatelessWidget {
  const _RespondTab();

  static const _steps = [
    (
      '1',
      'Ensure Your Safety First',
      Icons.security,
      Colors.red,
      [
        'Assess the environment before approaching',
        'Position yourself near an exit',
        'Remove dangerous objects if possible',
        'Call for assistance if needed',
        'Trust your instincts — leave if unsafe',
      ]
    ),
    (
      '2',
      'Make Contact',
      Icons.waving_hand,
      Colors.blue,
      [
        'Approach calmly and non-threateningly',
        'Introduce yourself clearly',
        'Speak in a calm, reassuring tone',
        'Maintain appropriate distance',
        'Use open body language and appropriate eye contact',
      ]
    ),
    (
      '3',
      'Gather Information',
      Icons.search,
      Colors.orange,
      [
        'Ask direct questions about safety',
        'Assess immediate danger',
        'Identify what triggered the crisis',
        'Determine risk level (use Assess tab)',
        'Identify existing support and resources',
      ]
    ),
    (
      '4',
      'Provide Support',
      Icons.favorite,
      Colors.pink,
      [
        'Listen actively and empathetically',
        'Validate feelings — do not agree with distorted thoughts',
        'Avoid judgement or criticism',
        'Offer hope and remind them they are not alone',
        'Help them identify their own options',
      ]
    ),
    (
      '5',
      'Take Action',
      Icons.bolt,
      Colors.green,
      [
        'Implement response based on risk level',
        'Involve the client in decision-making when possible',
        'Contact emergency services if needed',
        'Notify your supervisor',
        'Activate support system',
        'Document thoroughly within 24 hours',
      ]
    ),
  ];

  static const _deEscVerbal = [
    'Speak slowly and calmly — lower your voice, do not raise it',
    'Use simple, clear language — avoid jargon',
    'Acknowledge feelings ("I can see you are really upset")',
    'Repeat key phrases to show you are listening',
    'Offer choices — give the person some control',
    'Set clear limits calmly, without threats',
    'Do not argue, debate, or dismiss concerns',
    'Do not make promises you cannot keep',
  ];

  static const _deEscNonVerbal = [
    'Maintain a calm, relaxed demeanour',
    'Keep your body language open — no crossed arms',
    'Avoid threatening gestures',
    'Give personal space — at least an arm\'s length',
    'Position at an angle, not face-to-face',
    'Stay at or below the client\'s eye level',
    'Do not touch without permission',
    'Do not block exits',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('5-Step Crisis Response'),
          const SizedBox(height: 8),
          ..._steps.map((s) => _StepCard(
                number: s.$1,
                title: s.$2,
                icon: s.$3,
                color: s.$4,
                items: s.$5,
              )),
          const SizedBox(height: 20),
          const _SectionLabel('De-escalation Techniques'),
          const SizedBox(height: 8),
          _deEscCard('Verbal Strategies', Icons.record_voice_over,
              Colors.blue, _deEscVerbal),
          const SizedBox(height: 10),
          _deEscCard('Non-Verbal Strategies', Icons.pan_tool,
              Colors.teal, _deEscNonVerbal),
        ],
      ),
    );
  }

  Widget _deEscCard(
      String title, IconData icon, Color color, List<String> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey[200]!,
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          radius: 20,
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, size: 6, color: color),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(item,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  height: 1.5))),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  const _StepCard({
    required this.number,
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey[200]!,
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: ExpansionTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(number,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: color)),
          ),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('${items.length} actions',
            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 16, color: color),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(item,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  height: 1.5))),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ─── Tab 3: Safety Plan Guide ────────────────────────────────────────────────

class _SafetyPlanGuideTab extends StatelessWidget {
  const _SafetyPlanGuideTab();

  static const _planSteps = [
    (
      '1',
      'Warning Signs',
      Icons.radar,
      Colors.red,
      'Thoughts, images, moods, or behaviours that signal a crisis is developing.',
      [
        'Internal: "When I start thinking no one cares about me"',
        'Internal: "When I feel numb and start isolating"',
        'External: "When my partner starts drinking"',
        'External: "When I lose my job or housing"',
        'Ask: "What does it look like right before things get really bad for you?"',
      ]
    ),
    (
      '2',
      'Internal Coping Strategies',
      Icons.self_improvement,
      Colors.orange,
      'Things the client can do alone, without contacting anyone else.',
      [
        'Distraction: music, walking, drawing, cooking',
        'Self-soothing: breathing exercises, journaling',
        'Grounding: "5 things I can see, 4 I can feel..."',
        'Physical: exercise, cold water on face',
        'Ask: "What has helped you get through hard moments before?"',
      ]
    ),
    (
      '3',
      'Social Contacts for Distraction',
      Icons.people,
      Colors.blue,
      'People or places that provide distraction (not necessarily crisis support).',
      [
        'A friend to call and talk about something light',
        'A coffee shop, library, or other familiar public space',
        'A support group or community space',
        'Ask: "Who makes you feel safe without having to explain everything?"',
      ]
    ),
    (
      '4',
      'People to Ask for Help',
      Icons.phone_in_talk,
      Colors.purple,
      'People the client can call when they need direct support. Include names and numbers.',
      [
        'Family member — what kind of help can they provide?',
        'Friend — are they available at any hour?',
        'Sponsor or mentor',
        'Case manager / counsellor contact',
        'Always include at least 2 people with phone numbers',
      ]
    ),
    (
      '5',
      'Professional Resources',
      Icons.local_hospital,
      Colors.green,
      'Crisis hotlines, services, and professional contacts.',
      [
        '988 — Suicide & Crisis Lifeline (call or text)',
        'Crisis Text Line: Text HOME to 741741',
        'National DV Hotline: 1-800-799-7233',
        'Local case manager contact details',
        'Nearest emergency department / hospital',
      ]
    ),
    (
      '6',
      'Making the Environment Safer',
      Icons.lock,
      Colors.teal,
      'Reducing access to lethal means.',
      [
        'Medications — locked away or managed by a trusted person',
        'Firearms — removed from the home if possible',
        'Sharp objects — secured or given to someone to hold',
        'Alcohol or substances — removed from easy access',
        'Identify a "safe room" or safe space in or near the home',
      ]
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Text(
              'Walk the client through each step collaboratively. The safety plan works best when it comes from the client\'s own words — use these prompts to guide the conversation.',
              style:
                  TextStyle(fontSize: 13, color: Colors.blue[900], height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
          ..._planSteps.map((s) => _PlanStepCard(
                number: s.$1,
                title: s.$2,
                icon: s.$3,
                color: s.$4,
                description: s.$5,
                prompts: s.$6,
              )),
        ],
      ),
    );
  }
}

class _PlanStepCard extends StatelessWidget {
  final String number;
  final String title;
  final IconData icon;
  final Color color;
  final String description;
  final List<String> prompts;

  const _PlanStepCard({
    required this.number,
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    required this.prompts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.grey[200]!,
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color,
          radius: 18,
          child: Text(number,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description,
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(height: 10),
                ...prompts.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            p.startsWith('"') || p.startsWith('Ask:')
                                ? Icons.chat_bubble_outline
                                : Icons.circle,
                            size: p.startsWith('"') ? 14 : 6,
                            color: color,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(p,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: p.startsWith('"') ||
                                              p.startsWith('Ask:')
                                          ? Colors.grey[800]
                                          : Colors.grey[700],
                                      fontStyle: p.startsWith('"') ||
                                              p.startsWith('Ask:')
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                      height: 1.5))),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 4: Reference ────────────────────────────────────────────────────────

class _ReferenceTab extends StatelessWidget {
  final OrgConfig cfg;
  const _ReferenceTab({required this.cfg});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Call 911 Now
          _urgentCard(
            'Call 911 / Emergency Services NOW if:',
            Icons.crisis_alert,
            Colors.red,
            [
              'Client states intent to harm self or others RIGHT NOW',
              'Client has a weapon or access to lethal means',
              'Client is actively harming themselves',
              'Medical emergency (overdose, injury, chest pain)',
              'Violence is occurring or imminent',
              'Client is leaving to attempt suicide',
              'YOU feel unsafe',
            ],
          ),
          const SizedBox(height: 12),

          // When calling 911
          _refCard(
            'When Calling 911',
            Icons.phone,
            Colors.red[800]!,
            [
              'State it\'s a mental health emergency',
              'Provide specific address/location',
              'Describe the situation briefly',
              'Mention if weapons are involved',
              'Request a CIT (Crisis Intervention Team) officer if available',
              'Stay on the line until help arrives',
              'Do NOT put yourself in danger',
            ],
          ),
          const SizedBox(height: 12),

          // Field safety
          _refCard(
            'Field & Personal Safety',
            Icons.shield,
            Colors.orange[800]!,
            [
              'Review client history before any visit',
              'Inform your supervisor of location and expected return time',
              'Park in a visible, accessible location',
              'Position yourself near the exit during sessions',
              'Have your phone accessible at all times',
              'Leave immediately if you feel unsafe — postpone and reschedule',
              'Do not meet clients in isolated locations alone',
            ],
          ),
          const SizedBox(height: 12),

          // Mandatory reporting
          _refCard(
            'Mandatory Reporting',
            Icons.report,
            Colors.purple[800]!,
            [
              'Report immediately if you suspect child abuse or neglect',
              'Report immediately if you suspect elder or vulnerable adult abuse',
              'Document observations objectively — record what was reported and to whom',
              'Do NOT investigate — leave that to the authorities',
              'Continue services to the client during investigation',
            ],
          ),
          const SizedBox(height: 12),

          // Post-crisis
          _refCard(
            'Post-Crisis Procedures',
            Icons.restore,
            Colors.teal[800]!,
            [
              'Debrief with supervisor within 24 hours',
              'Daily contact with client for first week minimum',
              'Update safety plan based on what triggered the crisis',
              'Revise service/case plan goals',
              'Document the incident and all actions taken',
              'Self-care: process the emotional impact — this work is hard',
            ],
          ),
          const SizedBox(height: 12),

          // Emergency numbers
          _emergencyNumbers(context),
        ],
      ),
    );
  }

  Widget _urgentCard(
      String title, IconData icon, Color color, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: color)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_right, color: color, size: 18),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text(item,
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[800],
                                height: 1.4))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _refCard(
      String title, IconData icon, Color color, List<String> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey[200]!,
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          radius: 20,
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, size: 6, color: color),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(item,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  height: 1.5))),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _emergencyNumbers(BuildContext context) {
    final isUs = cfg.orgKey == 'us';
    final numbers = isUs
        ? [
            ('988', 'Suicide & Crisis Lifeline', Colors.purple),
            ('741741', 'Crisis Text Line (text HOME)', Colors.blue),
            ('1-800-799-7233', 'National DV Hotline', Colors.red),
            ('1-800-656-4673', 'RAINN Sexual Assault Hotline', Colors.pink),
            ('911', 'Police / Fire / Medical Emergency', Colors.red[900]!),
          ]
        : [
            ('999', 'Police / Fire / Medical Emergency', Colors.red[900]!),
            ('0800800800', 'DOVVSU DV Hotline (free)', Colors.red),
            ('191', 'Ghana Police Service', Colors.blue[800]!),
            ('193', 'Ambulance Service', Colors.green[800]!),
            ('988 / 741741', 'Crisis resources (US)', Colors.purple),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Emergency Numbers'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey[200]!,
                  blurRadius: 4,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            children: numbers.map((n) {
              final (number, label, color) = n;
              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  radius: 18,
                  child: Icon(Icons.phone, color: color, size: 16),
                ),
                title: Text(number,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: color)),
                subtitle: Text(label,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[600])),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Shared widgets ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E293B)),
    );
  }
}
