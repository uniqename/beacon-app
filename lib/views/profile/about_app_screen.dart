import 'package:flutter/material.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('About Beacon', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF0562D),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF0562D), Color(0xFFFF7043)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.anchor, size: 56, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  'Beacon of New Beginnings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Walking the path from pain to power, hand in hand',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text('Version 2.1.1', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _sectionHeader('Safety & Protection'),
          _featureTile(context, Icons.shield, Colors.teal, 'Safety Plan',
              'Create a personal safety plan covering escape routes, emergency contacts, essential items, safe places, code words for trusted people, and financial/digital safety.'),
          _featureTile(context, Icons.camera_alt, Colors.orange, 'Evidence Logger',
              'Securely document incidents with photos, audio recordings, descriptions, and dates. Creates a private, encrypted timeline of events that can support legal proceedings.'),
          _featureTile(context, Icons.alarm_on, const Color(0xFF00D4AA), 'Safety Check-In',
              'Set scheduled check-ins. If you miss a check-in, the app can alert your emergency contacts. Uses discreet language so it never looks suspicious.'),
          _featureTile(context, Icons.visibility_off, Colors.grey, 'Disguise Mode',
              'Hides the app behind a calculator or weather widget so it looks harmless on your phone if someone checks.'),
          _featureTile(context, Icons.chat, Colors.purple, 'AI Support Chat',
              '24/7 compassionate AI support chat that listens, provides guidance, and can escalate to a human counselor if needed.'),
          _featureTile(context, Icons.auto_awesome, const Color(0xFF00D4AA), 'AI Agents',
              'Specialized AI tools for document analysis, legal rights explanations, safety guidance, and more — powered by Gemini AI.'),

          const SizedBox(height: 8),
          _sectionHeader('Wellness & Healing'),
          _featureTile(context, Icons.healing, Colors.pink, 'Mood Tracker',
              'Log your daily mood (1–10), triggers, and notes. View trends over 7 and 14 days to understand your emotional patterns.'),
          _featureTile(context, Icons.spa, Colors.teal, 'Daily Self-Care Checklist',
              'A daily checklist across 4 categories — Body, Mind, Soul, and Safety — with 18 items. Tracks your completion streak day by day.'),
          _featureTile(context, Icons.auto_stories, Colors.indigo, 'Reflection Journal',
              'Private journal with a daily rotating prompt. Track your mood before and after writing. Entries are stored only on your device.'),
          _featureTile(context, Icons.bar_chart, Colors.deepPurple, 'Wellness Reports',
              'Weekly and monthly summaries of your mood trends, self-care completion rate, journal count, and personalized insights.'),
          _featureTile(context, Icons.local_fire_department, const Color(0xFFF0562D), 'Progress Tracker',
              'View your daily activity heatmap (last 28 days), current and longest streaks, and 8 milestone achievements as you build healthy habits.'),

          const SizedBox(height: 8),
          _sectionHeader('Resources & Finance'),
          _featureTile(context, Icons.account_balance_wallet, Colors.green, 'Budget Tracker',
              'Track income, expenses, and savings. Create a financial safety net. All data is encrypted and stored only on your device.'),
          _featureTile(context, Icons.folder, Colors.blue, 'Document Vault',
              'Securely store scanned copies of important documents — ID, passport, medical records, legal papers — encrypted and password-protected.'),
          _featureTile(context, Icons.library_books, Colors.indigo, 'Resource Library',
              'Articles, guides, and educational content on legal rights, mental health, financial independence, and recovery.'),
          _featureTile(context, Icons.work, Colors.cyan, 'Jobs & Opportunities',
              'Browse job listings, volunteering positions, and internships. Apply with a single tap — attach your resume, cover letter, and Ghana Card directly.'),
          _featureTile(context, Icons.favorite, const Color(0xFFF0562D), 'Donate',
              'Support Beacon\'s mission financially. Donations go directly to survivor support programs. Accepts Flutterwave, PayPal, and Paystack.'),

          const SizedBox(height: 8),
          _sectionHeader('Services & Support'),
          _featureTile(context, Icons.home, Colors.blue, 'Shelter Finder',
              'Find safe shelters and temporary housing near you. Each listing includes address, phone number, and available services.'),
          _featureTile(context, Icons.psychology, Colors.purple, 'Counseling',
              'Connect with professional counselors. Browse available services, book sessions, and get trauma-informed support.'),
          _featureTile(context, Icons.gavel, Colors.indigo, 'Legal Aid',
              'Access legal support services including restraining orders, custody advice, and legal rights information specific to Ghana.'),
          _featureTile(context, Icons.local_hospital, Colors.green, 'Medical Care',
              'Find healthcare providers, clinics, and medical support services for survivors of gender-based violence.'),
          _featureTile(context, Icons.handshake, Colors.orange, 'Partners',
              'Browse Beacon\'s partner organizations — NGOs, churches, government agencies — who provide additional support services.'),
          _featureTile(context, Icons.people, const Color(0xFFE91E8C), 'Peer Mentors',
              'Connect with trained survivor mentors who have walked a similar path. Get one-on-one guidance and encouragement.'),

          const SizedBox(height: 8),
          _sectionHeader('Community & Faith'),
          _featureTile(context, Icons.play_circle, const Color(0xFF9B59B6), 'Devotionals',
              'Watch video devotionals and sermons from faith leaders. Spiritual content curated for healing and restoration.'),
          _featureTile(context, Icons.event, const Color(0xFF3B82F6), 'Events & RSVP',
              'See upcoming Beacon events — workshops, support meetings, fundraisers — and RSVP directly from the app.'),
          _featureTile(context, Icons.schedule, const Color(0xFFFFB347), 'Volunteer Shifts',
              'Sign up for volunteer opportunities to support other survivors. View shift dates, locations, and available spots.'),
          _featureTile(context, Icons.mic, const Color(0xFFF0562D), 'Audio Support Rooms',
              'Join live audio support group sessions. Facilitators lead small groups. Raise your hand to speak. Listeners can stay muted.'),
          _featureTile(context, Icons.quiz, Colors.deepPurple, 'Quizzes',
              'Educational quizzes on legal rights, mental health, financial literacy, and safety. Learn while you earn badges.'),
          _featureTile(context, Icons.flash_on, const Color(0xFFE21B3C), 'Group Quiz (Kahoot-style)',
              'Play live group quiz games with other community members — fun, interactive learning in a safe space.'),

          const SizedBox(height: 8),
          _sectionHeader('Admin & Management'),
          _featureTile(context, Icons.admin_panel_settings, const Color(0xFFF0562D), 'Admin Dashboard',
              'Admins can manage user accounts, review helper applications, respond to support inquiries, and view system reports.'),
          _featureTile(context, Icons.edit_note, Colors.indigo, 'Content Management',
              'Admins can add, edit, and remove jobs, events, devotionals, shelters, peer mentors, Bible verses, quizzes, and service providers.'),
          _featureTile(context, Icons.approval, Colors.teal, 'Helper Approvals',
              'Review and approve/reject applications from counselors and volunteers who want to support survivors on the platform.'),

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: [
                const Icon(Icons.lock, color: Colors.green, size: 28),
                const SizedBox(height: 8),
                const Text('Your Privacy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  'All sensitive data — evidence, journals, documents, safety plans — is encrypted and stored only on your device. '
                  'Beacon never shares your personal information with third parties. '
                  'You can delete all your data at any time from your Profile.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Color(0xFFF0562D),
        ),
      ),
    );
  }

  Widget _featureTile(BuildContext context, IconData icon, Color color, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          Text(description, style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color, height: 1.5)),
        ],
      ),
    );
  }
}
