import 'package:flutter/material.dart';
import '../../services/app_config_service.dart';

class CrisisCoopingScreen extends StatefulWidget {
  const CrisisCoopingScreen({super.key});

  @override
  State<CrisisCoopingScreen> createState() => _CrisisCoopingScreenState();
}

class _CrisisCoopingScreenState extends State<CrisisCoopingScreen> {
  final Map<int, bool> _expanded = {};

  bool _isExpanded(int step) => _expanded[step] ?? (step == 0);

  void _toggle(int step) => setState(() => _expanded[step] = !_isExpanded(step));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Crisis Coping Plan',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFD32F2F),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _headerBanner(),
          const SizedBox(height: 16),
          _stepCard(
            step: 0,
            icon: Icons.warning_amber_rounded,
            color: Colors.amber[700]!,
            title: 'Step 1: Recognise Your Warning Signs',
            subtitle: 'Know when a crisis is building',
            body: _step1(),
          ),
          _stepCard(
            step: 1,
            icon: Icons.self_improvement,
            color: Colors.teal[600]!,
            title: 'Step 2: Internal Coping Strategies',
            subtitle: 'Things you can do on your own',
            body: _step2(),
          ),
          _stepCard(
            step: 2,
            icon: Icons.people_outline,
            color: Colors.blue[600]!,
            title: 'Step 3: People & Places for Distraction',
            subtitle: 'Social contacts and safe environments',
            body: _step3(),
          ),
          _stepCard(
            step: 3,
            icon: Icons.phone_in_talk,
            color: Colors.purple[600]!,
            title: 'Step 4: People I Can Ask for Help',
            subtitle: 'Trusted individuals + crisis lines',
            body: _step4(),
          ),
          _stepCard(
            step: 4,
            icon: Icons.local_hospital_outlined,
            color: Colors.red[700]!,
            title: 'Step 5: Professional Resources',
            subtitle: 'Counsellors, hotlines, and services',
            body: _step5(),
          ),
          _stepCard(
            step: 5,
            icon: Icons.home_outlined,
            color: Colors.green[700]!,
            title: 'Step 6: Making My Environment Safer',
            subtitle: 'Reduce access to means of harm',
            body: _step6(),
          ),
          const SizedBox(height: 16),
          _safetyNote(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _headerBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD32F2F).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD32F2F).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite, color: Color(0xFFD32F2F), size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Your Personal Crisis Coping Plan',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD32F2F)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'This plan is for moments when emotions feel overwhelming. '
            'Work through the steps in order — each one builds on the last. '
            'You have survived hard times before. You can get through this.',
            style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _stepCard({
    required int step,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget body,
  }) {
    final open = _isExpanded(step);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: open ? 3 : 1,
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggle(step),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Icon(open ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey[500]),
                ],
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: Colors.grey[200]),
                  const SizedBox(height: 8),
                  body,
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _step1() {
    return _textBlock([
      _heading('Emotional warning signs'),
      _bullet('Feeling numb, detached, or "not real"'),
      _bullet('Intense hopelessness — believing things will never get better'),
      _bullet('Sudden calmness after a period of deep distress'),
      _bullet('Feeling like a burden to everyone around you'),
      _bullet('Thoughts of hurting yourself or wishing you were not here'),
      const SizedBox(height: 12),
      _heading('Physical warning signs'),
      _bullet('Heart racing, shallow breathing, feeling "frozen"'),
      _bullet('Unable to sleep, or sleeping all day'),
      _bullet('Not eating or overeating'),
      _bullet('Physical pain with no clear cause'),
      const SizedBox(height: 12),
      _infoBox(
        Icons.edit_note,
        Colors.amber[700]!,
        'Think about YOUR warning signs. What happens in your body '
        'and mind just before you hit a crisis? Knowing this early '
        'gives you more time to use the steps below.',
      ),
    ]);
  }

  Widget _step2() {
    return _textBlock([
      _heading('Try these first — no one else needed'),
      _bullet('Slow breathing: breathe in for 4 counts, hold 4, out for 6'),
      _bullet('5-4-3-2-1 grounding: name 5 things you see, 4 you can touch, 3 sounds, 2 smells, 1 taste'),
      _bullet('Hold an ice cube, splash cold water on your face, or take a cold shower'),
      _bullet('Go for a walk — even 5 minutes outside can shift your state'),
      _bullet('Put on music and let yourself feel it — cry, move, breathe'),
      _bullet('Write down exactly what is happening inside you — no editing, just words'),
      _bullet('Do something with your hands: draw, cook, tidy, build'),
      const SizedBox(height: 12),
      _infoBox(
        Icons.lightbulb_outline,
        Colors.teal[600]!,
        'You do not need to feel better immediately. The goal of '
        'coping strategies is to ride the wave of emotion long enough '
        'for it to pass — not to make it disappear instantly.',
      ),
    ]);
  }

  Widget _step3() {
    return _textBlock([
      _heading('Places that feel safe'),
      _bullet('A trusted friend\'s or family member\'s home'),
      _bullet('A community centre, place of worship, or library'),
      _bullet('A café or public space where you feel anonymous but not alone'),
      const SizedBox(height: 12),
      _heading('People who provide distraction (not crisis support)'),
      _bullet('A friend who makes you laugh or feel normal'),
      _bullet('A family member you can visit without having to explain yourself'),
      _bullet('A neighbour or colleague you enjoy being around'),
      const SizedBox(height: 12),
      _infoBox(
        Icons.info_outline,
        Colors.blue[600]!,
        'Distraction contacts are different from crisis contacts. '
        'You do not need to tell them you are struggling — '
        'just being around safe people can lower the intensity of a crisis.',
      ),
    ]);
  }

  Widget _step4() {
    final cfg = AppConfigService.instance.config;
    final isUs = cfg.orgKey == 'us';

    return _textBlock([
      _heading('People you trust'),
      _bullet('Think of 2–3 people you can call when things feel unbearable'),
      _bullet('Let them know in advance so they are prepared to support you'),
      _bullet('It is okay to say: "I am struggling right now and I need someone to talk to"'),
      const SizedBox(height: 12),
      _heading('Crisis lines — available now'),
      if (isUs) ...[
        _crisisLineCard('988 Suicide & Crisis Lifeline', '988',
            'Call or text 988 — 24/7 free, confidential', Colors.red[700]!),
        _crisisLineCard('Crisis Text Line', 'Text HOME to 741741',
            'Text support 24/7', Colors.blue[700]!),
        _crisisLineCard('National DV Hotline', '1-800-799-7233',
            'Domestic violence support 24/7', Colors.purple[700]!),
      ] else ...[
        _crisisLineCard('Mental Health Hotline (Ghana)', '0800-111-222',
            'Free mental health support', Colors.red[700]!),
        _crisisLineCard('National Emergency', '999',
            'Police, fire, ambulance', Colors.blue[700]!),
        _crisisLineCard('DOVVSU (DV Support)', '0302-773-906',
            'Domestic Violence & Victim Support Unit', Colors.purple[700]!),
        _crisisLineCard('Befrienders Ghana', '028-510-0500',
            'Emotional support & crisis line', Colors.teal[700]!),
      ],
    ]);
  }

  Widget _step5() {
    final cfg = AppConfigService.instance.config;
    final isUs = cfg.orgKey == 'us';

    return _textBlock([
      _heading('When to seek professional help immediately'),
      _bullet('You are thinking about suicide or have a plan'),
      _bullet('You feel you might harm yourself or someone else'),
      _bullet('You are unable to care for yourself or your children'),
      _bullet('The crisis has not improved after trying steps 1–4'),
      const SizedBox(height: 12),
      _heading('Professional resources'),
      if (isUs) ...[
        _bullet('Emergency Room (ER) — go or call 911 in immediate danger'),
        _bullet('Your therapist or counsellor — call or send an emergency message'),
        _bullet('Primary care doctor — can refer to mental health services'),
        _bullet('SAMHSA National Helpline: 1-800-662-4357 (mental health & substance use)'),
      ] else ...[
        _bullet('Emergency (Police / Ambulance): 999'),
        _bullet('Accra Psychiatric Hospital: 030-277-2118'),
        _bullet('Your Beacon case manager or counsellor'),
        _bullet('Nearest district hospital — ask for psychiatric or social welfare unit'),
      ],
      const SizedBox(height: 12),
      _infoBox(
        Icons.local_hospital_outlined,
        Colors.red[700]!,
        'Going to a hospital or calling a hotline is not a sign of weakness. '
        'It is one of the bravest decisions you can make. '
        'You deserve professional support.',
      ),
    ]);
  }

  Widget _step6() {
    return _textBlock([
      _heading('Reducing access to means of harm'),
      Text(
        'When we are in crisis, impulsive urges can feel overwhelming. '
        'Making it harder to act on those urges in the moment saves lives. '
        'This is called "means restriction" and it works.',
        style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5),
      ),
      const SizedBox(height: 12),
      _bullet('Ask a trusted person to hold medications for you'),
      _bullet('Remove or store securely any items that could be used to self-harm'),
      _bullet('Keep sharp items in a place that requires extra steps to reach'),
      _bullet('Avoid alcohol or substances when you are feeling low — they increase impulsivity'),
      _bullet('If you have firearms, arrange for someone else to store them'),
      const SizedBox(height: 12),
      _heading('Create a safer phone environment'),
      _bullet('Delete triggering social media apps temporarily'),
      _bullet('Block contacts that cause distress during vulnerable times'),
      _bullet('Add crisis line numbers to your favourites now, before you need them'),
      const SizedBox(height: 12),
      _infoBox(
        Icons.shield_outlined,
        Colors.green[700]!,
        'These changes do not have to be permanent. They are practical, '
        'temporary steps to keep you safe until the crisis passes. '
        'You can reassess when you feel stable.',
      ),
    ]);
  }

  Widget _safetyNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD32F2F).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFFD32F2F).withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.favorite, color: Color(0xFFD32F2F), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'If you are in immediate danger, please call emergency services now. '
              'You matter. Your life has value. '
              'This crisis will pass — please hold on.',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[800],
                  height: 1.55,
                  fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textBlock(List<Widget> children) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  Widget _heading(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Expanded(
              child: Text(text,
                  style:
                      TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.45))),
        ],
      ),
    );
  }

  Widget _infoBox(IconData icon, Color color, String text) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[800], height: 1.5))),
        ],
      ),
    );
  }

  Widget _crisisLineCard(
      String name, String number, String desc, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.phone, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(number,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text(desc,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
