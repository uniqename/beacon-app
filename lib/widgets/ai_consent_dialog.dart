import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ai_consent_service.dart';

/// Shows a modal bottom sheet disclosing Google Gemini data sharing.
/// Returns `true` if the user accepted, `false` if they declined or dismissed.
///
/// Satisfies App Store Guidelines 5.1.1(i) and 5.1.2(i):
///   - Discloses what data is sent
///   - Identifies the third party (Google Gemini)
///   - Obtains explicit permission before sending any data
Future<bool> showAiConsentDialogIfNeeded(BuildContext context) async {
  final alreadyConsented = await AiConsentService.hasConsented();
  if (alreadyConsented) return true;

  if (!context.mounted) return false;

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AiConsentSheet(),
  );

  return result == true;
}

class _AiConsentSheet extends StatefulWidget {
  const _AiConsentSheet();

  @override
  State<_AiConsentSheet> createState() => _AiConsentSheetState();
}

class _AiConsentSheetState extends State<_AiConsentSheet> {
  bool _checked = false;

  static const _kBg      = Color(0xFF141929);
  static const _kSurface = Color(0xFF1C2333);
  static const _kBorder  = Color(0xFF2A3550);
  static const _kAccent  = Color(0xFF00D4AA);
  static const _kGold    = Color(0xFFFFB347);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 20, 24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: _kBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kGold.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.privacy_tip_rounded, color: _kGold, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'AI Features & Data Sharing',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Intro
            Text(
              'Before using AI-powered features, please review how your information is used.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13.5,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 18),

            // What is sent
            _InfoBlock(
              icon: Icons.send_rounded,
              color: _kAccent,
              title: 'What data is sent',
              body:
                  'Only the text you type is sent — your messages and any documents or text you paste. Your name, email, phone number, and account details are never included.',
            ),

            const SizedBox(height: 12),

            // Who receives it
            _InfoBlock(
              icon: Icons.business_rounded,
              color: _kGold,
              title: 'Who receives your data',
              body:
                  'Your messages are processed by Google LLC via the Gemini API. Google\'s own Privacy Policy governs how they handle this data. Beacon of New Beginnings does not sell or share your data with any other third party.',
            ),

            const SizedBox(height: 12),

            // How it's used
            _InfoBlock(
              icon: Icons.auto_awesome_rounded,
              color: const Color(0xFF7C3AED),
              title: 'How it is used',
              body:
                  'Your data is used solely to generate AI responses within the app (counselling support, document analysis, safety planning, and legal guidance). It is not used for advertising.',
            ),

            const SizedBox(height: 12),

            // Your choice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder),
              ),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'AI features are optional. You can use all other Beacon features without sharing data with Google. Read '),
                    TextSpan(
                      text: 'Google\'s Privacy Policy',
                      style: const TextStyle(
                        color: _kAccent,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => launchUrl(
                              Uri.parse('https://policies.google.com/privacy'),
                              mode: LaunchMode.externalApplication,
                            ),
                    ),
                    const TextSpan(text: ' for details on how Google handles AI data.'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Consent checkbox
            GestureDetector(
              onTap: () => setState(() => _checked = !_checked),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _checked ? _kAccent : Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: _checked ? _kAccent : _kBorder,
                        width: 2,
                      ),
                    ),
                    child: _checked
                        ? const Icon(Icons.check, color: Colors.black, size: 14)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'I understand that my messages will be sent to Google Gemini AI for processing, and I agree to this data sharing.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: _kBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('No Thanks', style: TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _checked
                        ? () async {
                            await AiConsentService.saveConsent();
                            if (context.mounted) Navigator.pop(context, true);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kAccent,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: _kAccent.withValues(alpha: 0.3),
                      disabledForegroundColor: Colors.black45,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Enable AI Features',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _InfoBlock({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
