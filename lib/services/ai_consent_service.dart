import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages user consent before sending personal data to the Gemini AI service.
///
/// Apple App Store guidelines 5.1.1(i) / 5.1.2(i) require that apps:
///   - Disclose what data is sent to a third-party
///   - Identify the recipient
///   - Obtain user permission before transmitting personal data
///
/// Call [requestConsentIfNeeded] at every AI entry-point. Returns true
/// immediately (no dialog) if consent was already granted.
class AiConsentService {
  static const _kConsentKey = 'ai_gemini_consent_v1';

  /// Returns true if the user has already accepted the AI data-sharing notice.
  static Future<bool> hasConsented() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kConsentKey) ?? false;
  }

  /// Persists the user's consent acceptance.
  static Future<void> saveConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kConsentKey, true);
  }

  /// Removes stored consent (e.g. if the user revokes from settings).
  static Future<void> revokeConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kConsentKey);
  }

  /// Shows a consent dialog if the user has not yet consented.
  ///
  /// Returns true if consent is granted (either previously or just now),
  /// false if the user declines. Call this before any Gemini API request.
  static Future<bool> requestConsentIfNeeded(BuildContext context) async {
    if (await hasConsented()) return true;
    if (!context.mounted) return false;
    return await _showConsentDialog(context);
  }

  static Future<bool> _showConsentDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.smart_toy_outlined, color: Color(0xFF6A1B9A), size: 22),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'AI-Assisted Plan Generation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'To generate a personalised support plan, some of the information you have entered will be sent to a third-party AI service.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              _infoRow(
                Icons.upload_rounded,
                'What is shared',
                'The presenting situation and identified support needs you have entered. '
                    'No names, phone numbers, or contact details are sent.',
              ),
              const SizedBox(height: 10),
              _infoRow(
                Icons.business_outlined,
                'Who receives it',
                'Google LLC, via the Gemini AI service (ai.google.dev). '
                    "Google's use of this data is governed by the Google AI Terms of Service.",
              ),
              const SizedBox(height: 10),
              _infoRow(
                Icons.shield_outlined,
                'How it is used',
                'Solely to generate a structured support plan. '
                    'Beacon of New Beginnings does not retain data sent to Gemini.',
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: const Text(
                  'Declining will not affect the standard intake process. '
                  'A support plan can still be created manually.',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Decline', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Allow AI'),
          ),
        ],
      ),
    );

    if (result == true) {
      await saveConsent();
      return true;
    }
    return false;
  }

  static Widget _infoRow(IconData icon, String label, String detail) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6A1B9A)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: detail),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
