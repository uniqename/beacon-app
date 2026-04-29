import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/case_plan.dart';
import '../../models/client_intake.dart';
import '../../models/user.dart';
import '../../services/ai_consent_service.dart';
import '../../services/app_config_service.dart';
import '../../services/case_ai_service.dart';
import '../../services/case_management_service.dart';
import 'my_support_plan_screen.dart';

/// Survivor-facing intake form.
/// Trauma-informed, minimal friction. On submit, AI generates a full
/// case plan draft which is saved and immediately visible in MySupportPlanScreen.
class SurvivorIntakeScreen extends StatefulWidget {
  final AppUser user;

  const SurvivorIntakeScreen({super.key, required this.user});

  @override
  State<SurvivorIntakeScreen> createState() => _SurvivorIntakeScreenState();
}

class _SurvivorIntakeScreenState extends State<SurvivorIntakeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _situationCtrl = TextEditingController();

  final _selectedNeeds = <String>{};
  static const _needOptions = [
    'A safe place to stay',
    'Help with school or education fees',
    'Emotional support or counselling',
    'Legal advice or protection',
    'Help finding work or building skills',
    'Reconnecting with a safe community',
    'Help with healthcare',
    'Personal safety planning',
    'Something else',
  ];

  // Maps survivor-friendly labels back to canonical need keys
  static const _needMap = {
    'A safe place to stay': 'Housing',
    'Help with school or education fees': 'Education',
    'Emotional support or counselling': 'Psychosocial / Counselling',
    'Legal advice or protection': 'Legal Resources',
    'Help finding work or building skills': 'Economic / Skills Training',
    'Reconnecting with a safe community': 'Community & Social Reintegration',
    'Help with healthcare': 'Healthcare',
    'Personal safety planning': 'Safety Planning',
    'Something else': 'Other',
  };

  int _step = 0; // 0 = welcome, 1 = situation, 2 = needs, 3 = generating
  bool _isGenerating = false;
  String _generatingMessage = 'Creating your support plan…';

  @override
  void dispose() {
    _situationCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_step == 1 && _situationCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please share a little about your situation first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_step == 2 && _selectedNeeds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one area where you need support.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final consented = await AiConsentService.requestConsentIfNeeded(context);
    if (!mounted || !consented) return;

    setState(() {
      _step = 3;
      _isGenerating = true;
      _generatingMessage = 'Understanding your situation…';
    });

    try {
      final situation = _situationCtrl.text.trim();
      final canonicalNeeds = _selectedNeeds
          .map((n) => _needMap[n] ?? n)
          .toList();

      // Step 1: AI generates programs
      if (mounted) setState(() => _generatingMessage = 'Building your support plan with AI…');
      final aiPrograms = await CaseAiService().generatePrograms(
        presentingSituation: situation,
        needsIdentified: canonicalNeeds,
      );

      if (mounted) setState(() => _generatingMessage = 'Saving your plan…');

      final now = DateTime.now();
      final intakeId = const Uuid().v4();
      final planId = const Uuid().v4();

      final intake = ClientIntake(
        id: intakeId,
        clientName: widget.user.displayName ?? widget.user.email ?? 'Client',
        clientPhone: widget.user.phoneNumber,
        clientId: widget.user.id,
        caseManagerId: 'system_ai',
        caseManagerName: 'Beacon Support Team',
        intakeDate: now,
        presentingSituation: situation,
        needsIdentified: canonicalNeeds,
        currency: AppConfigService.instance.config.currencyCode,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      final plan = CasePlan(
        id: planId,
        intakeId: intakeId,
        clientName: intake.clientName,
        clientId: widget.user.id,
        caseManagerId: 'system_ai',
        caseManagerName: 'Beacon Support Team',
        planStatus: 'active',
        nextReviewDate: now.add(const Duration(days: 90)),
        reviewFrequency: 'quarterly',
        createdAt: now,
        updatedAt: now,
      );

      await CaseManagementService.createIntake(intake);
      await CaseManagementService.createCasePlan(plan);

      // Save AI-generated programs
      for (var i = 0; i < aiPrograms.length; i++) {
        final p = aiPrograms[i];
        final actions = (p['actions'] as List<dynamic>? ?? [])
            .map((a) => ProgramAction(text: a.toString()))
            .toList();

        DateTime? deadlineDate;
        final deadlineLabel = p['deadline_label'] as String? ?? '';
        if (deadlineLabel.contains('30 days')) {
          deadlineDate = now.add(const Duration(days: 30));
        } else if (deadlineLabel.contains('2 weeks')) {
          deadlineDate = now.add(const Duration(days: 14));
        } else if (deadlineLabel.contains('3 month')) {
          deadlineDate = now.add(const Duration(days: 90));
        } else if (deadlineLabel.contains('6 month')) {
          deadlineDate = now.add(const Duration(days: 180));
        }

        final program = CaseProgram(
          id: const Uuid().v4(),
          casePlanId: planId,
          programNumber: i + 1,
          programName: p['program_name'] as String? ?? 'Support Program ${i + 1}',
          goal: p['goal'] as String? ?? '',
          currentStatusNotes: p['current_status_notes'] as String? ?? '',
          priority: p['priority'] as String? ?? 'medium',
          deadlineLabel: deadlineLabel.isEmpty ? null : deadlineLabel,
          deadlineDate: deadlineDate,
          actions: actions,
          createdAt: now,
          updatedAt: now,
        );
        await CaseManagementService.createProgram(program);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MySupportPlanScreen(userId: widget.user.id),
          ),
        );
      }
    } catch (e) {
      developer.log('Error generating survivor plan: $e');
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _step = 2;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      appBar: AppBar(
        title: const Text(
          'Your Support Plan',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFF0562D),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _step == 3 ? _buildGenerating() : _buildForm(),
      ),
    );
  }

  Widget _buildGenerating() {
    return Center(
      key: const ValueKey('generating'),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 72,
              height: 72,
              child: CircularProgressIndicator(
                  color: Color(0xFFF0562D), strokeWidth: 5),
            ),
            const SizedBox(height: 32),
            const Text(
              'Just a moment',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _generatingMessage,
                key: ValueKey(_generatingMessage),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'We\'re creating a personalised support plan\nbased on what you\'ve shared.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 40),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Go Back to Home'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      key: const ValueKey('form'),
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_step == 0) ..._buildWelcome(),
            if (_step == 1) ..._buildSituationStep(),
            if (_step == 2) ..._buildNeedsStep(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWelcome() {
    return [
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF0562D), Color(0xFFFF7043)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.favorite, color: Colors.white, size: 36),
            const SizedBox(height: 16),
            const Text(
              'You\'re not alone.',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Beacon of New Beginnings is here to support you. '
              'We\'d like to create a personalised plan to help you '
              'get the support you need — at your pace.',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9), fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
      const SizedBox(height: 28),
      _infoRow(Icons.lock_outline, 'Everything you share is confidential.'),
      const SizedBox(height: 12),
      _infoRow(Icons.auto_awesome_outlined,
          'Our AI assistant will create a personalised support plan for you.'),
      const SizedBox(height: 12),
      _infoRow(Icons.people_outline,
          'A real case manager will review and personalise your plan.'),
      const SizedBox(height: 36),
      _primaryButton(
        label: 'Get Started',
        icon: Icons.arrow_forward,
        onTap: () => setState(() => _step = 1),
      ),
      const SizedBox(height: 16),
      Center(
        child: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Not now',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildSituationStep() {
    return [
      const Text(
        'Tell us about your situation',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Text(
        'Share as much or as little as you\'re comfortable with. '
        'There are no right or wrong answers — just your story.',
        style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
      ),
      const SizedBox(height: 24),
      TextFormField(
        controller: _situationCtrl,
        maxLines: 8,
        decoration: InputDecoration(
          hintText:
              'What has been happening? What brings you to Beacon today?\n\n'
              'e.g. "I\'ve been experiencing abuse at home…"\n'
              '"I lost my support system and need help…"',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFFF0562D), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      const SizedBox(height: 28),
      _primaryButton(
        label: 'Continue',
        icon: Icons.arrow_forward,
        onTap: () {
          if (_situationCtrl.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Please share a little first.'),
                  backgroundColor: Colors.orange),
            );
            return;
          }
          setState(() => _step = 2);
        },
      ),
      const SizedBox(height: 12),
      Center(
        child: TextButton(
          onPressed: () => setState(() => _step = 0),
          child: const Text('Back'),
        ),
      ),
    ];
  }

  List<Widget> _buildNeedsStep() {
    return [
      const Text(
        'Where do you need support?',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Text(
        'Select everything that applies. This helps us build '
        'the right plan for you.',
        style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
      ),
      const SizedBox(height: 20),
      ..._needOptions.map((need) {
        final selected = _selectedNeeds.contains(need);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() {
              if (selected) {
                _selectedNeeds.remove(need);
              } else {
                _selectedNeeds.add(need);
              }
            }),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFF0562D).withValues(alpha: 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFF0562D)
                      : Colors.grey[300]!,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: selected
                        ? const Color(0xFFF0562D)
                        : Colors.grey[400],
                    size: 22,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      need,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: selected
                            ? const Color(0xFFF0562D)
                            : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
      const SizedBox(height: 28),
      _primaryButton(
        label: 'Create My Support Plan',
        icon: Icons.auto_awesome,
        onTap: _isGenerating ? null : _generate,
      ),
      const SizedBox(height: 12),
      Center(
        child: TextButton(
          onPressed: () => setState(() => _step = 1),
          child: const Text('Back'),
        ),
      ),
      const SizedBox(height: 32),
    ];
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFFF0562D)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey[700], height: 1.4)),
        ),
      ],
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF0562D),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        icon: Icon(icon, size: 20),
        label: Text(label,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
