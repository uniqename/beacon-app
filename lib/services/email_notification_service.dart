import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;

class EmailNotificationService {
  static final EmailNotificationService _instance = EmailNotificationService._internal();
  factory EmailNotificationService() => _instance;
  EmailNotificationService._internal();

  // App store links
  static const String appStoreUrl = 'https://apps.apple.com/app/beacon-new-beginnings';
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.beaconnewbeginnings.app';
  static const String appName = 'Beacon of New Beginnings';

  /// Send approval notification email to helper applicant
  Future<bool> sendApprovalEmail({
    required String recipientEmail,
    required String recipientName,
    required String userType, // 'counselor' or 'volunteer'
    String? adminNotes,
  }) async {
    try {
      final subject = Uri.encodeComponent('$appName - Application Approved! 🎉');

      final body = Uri.encodeComponent('''
Dear $recipientName,

Congratulations! Your ${userType == 'counselor' ? 'counselor' : 'volunteer'} application has been approved by our admin team.

You now have access to the full ${userType == 'counselor' ? 'counselor' : 'volunteer'} features in the $appName app.

${adminNotes != null && adminNotes.isNotEmpty ? '\nAdmin Notes:\n$adminNotes\n' : ''}

To get started:
1. Open the $appName app on your device
2. Log in with your registered email and password
3. You'll now see your ${userType == 'counselor' ? 'counselor' : 'volunteer'} dashboard

If you haven't installed the app yet, download it here:
📱 iOS App Store: $appStoreUrl
🤖 Google Play Store: $playStoreUrl

Thank you for joining our mission to support domestic violence survivors. Your commitment to helping others makes a real difference.

Best regards,
$appName Admin Team

---
This is an automated notification. Please do not reply to this email.
''');

      final mailtoUri = Uri.parse('mailto:$recipientEmail?subject=$subject&body=$body');

      if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri);
        developer.log('Approval email opened for: $recipientEmail', name: 'EmailNotificationService');
        return true;
      } else {
        developer.log('Could not launch email client for: $recipientEmail', name: 'EmailNotificationService', error: 'mailto not supported');
        return false;
      }
    } catch (e) {
      developer.log('Error sending approval email', name: 'EmailNotificationService', error: e);
      return false;
    }
  }

  /// Send rejection notification email to helper applicant
  Future<bool> sendRejectionEmail({
    required String recipientEmail,
    required String recipientName,
    required String userType, // 'counselor' or 'volunteer'
    required String reason,
  }) async {
    try {
      final subject = Uri.encodeComponent('$appName - Application Update');

      final body = Uri.encodeComponent('''
Dear $recipientName,

Thank you for your interest in becoming a ${userType == 'counselor' ? 'counselor' : 'volunteer'} with $appName.

After careful review, we regret to inform you that we are unable to approve your application at this time.

Reason:
$reason

We appreciate your willingness to support domestic violence survivors. You can still use the app as a regular user to access resources and support services.

If you believe this decision was made in error or if you have additional documentation to submit, please contact us at admin@beaconnewbeginnings.org.

Thank you for your understanding.

Best regards,
$appName Admin Team

---
This is an automated notification. Please do not reply to this email.
''');

      final mailtoUri = Uri.parse('mailto:$recipientEmail?subject=$subject&body=$body');

      if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri);
        developer.log('Rejection email opened for: $recipientEmail', name: 'EmailNotificationService');
        return true;
      } else {
        developer.log('Could not launch email client for: $recipientEmail', name: 'EmailNotificationService', error: 'mailto not supported');
        return false;
      }
    } catch (e) {
      developer.log('Error sending rejection email', name: 'EmailNotificationService', error: e);
      return false;
    }
  }

  /// Send application received confirmation email
  Future<bool> sendApplicationReceivedEmail({
    required String recipientEmail,
    required String recipientName,
    required String userType,
  }) async {
    try {
      final subject = Uri.encodeComponent('$appName - Application Received');

      final body = Uri.encodeComponent('''
Dear $recipientName,

Thank you for submitting your ${userType == 'counselor' ? 'counselor' : 'volunteer'} application to $appName.

Your application is currently under review by our admin team. We carefully review all applications to ensure the safety and quality of our support services.

What happens next:
• Our team will review your application and supporting documents
• You'll receive an email notification once a decision is made
• In the meantime, you can access the app with normal user features

Application Review Timeline:
• Most applications are reviewed within 3-5 business days
• You may be contacted if we need additional information

If you have any questions, please contact us at admin@beaconnewbeginnings.org.

Thank you for your patience and commitment to helping others.

Best regards,
$appName Admin Team

---
This is an automated notification. Please do not reply to this email.
''');

      final mailtoUri = Uri.parse('mailto:$recipientEmail?subject=$subject&body=$body');

      if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri);
        developer.log('Application received email opened for: $recipientEmail', name: 'EmailNotificationService');
        return true;
      } else {
        developer.log('Could not launch email client for: $recipientEmail', name: 'EmailNotificationService', error: 'mailto not supported');
        return false;
      }
    } catch (e) {
      developer.log('Error sending application received email', name: 'EmailNotificationService', error: e);
      return false;
    }
  }

  /// Send invitation notification email for support groups
  Future<bool> sendGroupInvitationEmail({
    required String recipientEmail,
    required String recipientName,
    required String inviterName,
    required String groupName,
    required String groupDescription,
  }) async {
    try {
      final subject = Uri.encodeComponent('You\'ve been invited to join "$groupName" 🎤');

      final body = Uri.encodeComponent('''
Dear $recipientName,

$inviterName has invited you to join their private support group on $appName!

Group: $groupName
$groupDescription

Support groups are safe spaces where you can:
• Share your experiences with others who understand
• Listen to stories from survivors on their healing journey
• Connect with professional counselors and volunteers
• Find strength through community support

To accept this invitation:
1. Open the $appName app on your device
2. Go to the Community tab
3. Tap on Invitations (you'll see a notification badge)
4. Accept the invitation to join

This invitation will expire in 30 days.

If you haven't installed the app yet:
📱 iOS: $appStoreUrl
🤖 Android: $playStoreUrl

Remember: Everything shared in support groups is confidential. Our community guidelines ensure a safe and respectful environment for all participants.

Best regards,
$appName Team

---
This is an automated notification. Please do not reply to this email.
''');

      final mailtoUri = Uri.parse('mailto:$recipientEmail?subject=$subject&body=$body');

      if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri);
        developer.log('Group invitation email opened for: $recipientEmail', name: 'EmailNotificationService');
        return true;
      } else {
        developer.log('Could not launch email client for: $recipientEmail', name: 'EmailNotificationService', error: 'mailto not supported');
        return false;
      }
    } catch (e) {
      developer.log('Error sending group invitation email', name: 'EmailNotificationService', error: e);
      return false;
    }
  }

  /// Send safety report notification to admins
  Future<bool> sendReportNotificationEmail({
    required String adminEmail,
    required String reportId,
    required String reporterName,
    required String groupName,
    required String reason,
    required String description,
  }) async {
    try {
      final subject = Uri.encodeComponent('🚨 Safety Report - "$groupName"');

      final body = Uri.encodeComponent('''
SAFETY REPORT SUBMITTED

Report ID: $reportId
Submitted by: $reporterName
Support Group: $groupName
Report Category: $reason

Description:
$description

ACTION REQUIRED:
Please review this report in the admin dashboard and take appropriate action.

To review this report:
1. Open the $appName app
2. Go to Admin Dashboard
3. Navigate to Reports section
4. Review report ID: $reportId

Time-sensitive reports require immediate attention to ensure the safety of our community members.

---
$appName Admin Team
This is an automated notification.
''');

      final mailtoUri = Uri.parse('mailto:$adminEmail?subject=$subject&body=$body');

      if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri);
        developer.log('Report notification email opened for admin', name: 'EmailNotificationService');
        return true;
      } else {
        developer.log('Could not launch email client for admin notification', name: 'EmailNotificationService', error: 'mailto not supported');
        return false;
      }
    } catch (e) {
      developer.log('Error sending report notification email', name: 'EmailNotificationService', error: e);
      return false;
    }
  }

  /// Send report resolution notification to reporter
  Future<bool> sendReportResolutionEmail({
    required String recipientEmail,
    required String recipientName,
    required String groupName,
    required String resolution,
  }) async {
    try {
      final subject = Uri.encodeComponent('Your Safety Report Has Been Reviewed');

      final body = Uri.encodeComponent('''
Dear $recipientName,

Thank you for reporting a safety concern in the support group "$groupName".

Our moderation team has reviewed your report, and we wanted to update you on the outcome:

Resolution:
$resolution

Your safety and the safety of all community members is our top priority. We take all reports seriously and investigate them thoroughly.

If you have any additional concerns or questions about this resolution, please contact us at admin@beaconnewbeginnings.org.

Thank you for helping us maintain a safe and supportive community.

Best regards,
$appName Moderation Team

---
This is an automated notification. Please do not reply to this email.
''');

      final mailtoUri = Uri.parse('mailto:$recipientEmail?subject=$subject&body=$body');

      if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri);
        developer.log('Report resolution email opened for: $recipientEmail', name: 'EmailNotificationService');
        return true;
      } else {
        developer.log('Could not launch email client for: $recipientEmail', name: 'EmailNotificationService', error: 'mailto not supported');
        return false;
      }
    } catch (e) {
      developer.log('Error sending report resolution email', name: 'EmailNotificationService', error: e);
      return false;
    }
  }

  /// Send session reminder email
  Future<bool> sendSessionReminderEmail({
    required String recipientEmail,
    required String recipientName,
    required String groupName,
    required String hostName,
    required DateTime scheduledTime,
  }) async {
    try {
      final minutesUntil = scheduledTime.difference(DateTime.now()).inMinutes;
      final subject = Uri.encodeComponent('"$groupName" starts in $minutesUntil minutes 🔔');

      final body = Uri.encodeComponent('''
Dear $recipientName,

This is a reminder that your support group session is starting soon!

Group: $groupName
Host: $hostName
Start Time: ${scheduledTime.toString().substring(0, 16)}

To join the session:
1. Open the $appName app
2. Go to the Community tab
3. Tap on "$groupName"
4. Join the audio room when it goes live

Tips for a great session:
• Find a quiet, private space
• Use headphones for better audio quality
• Remember our community guidelines
• Feel free to just listen if you prefer

We look forward to seeing you there!

Best regards,
$appName Team

---
This is an automated reminder. Please do not reply to this email.
''');

      final mailtoUri = Uri.parse('mailto:$recipientEmail?subject=$subject&body=$body');

      if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri);
        developer.log('Session reminder email opened for: $recipientEmail', name: 'EmailNotificationService');
        return true;
      } else {
        developer.log('Could not launch email client for: $recipientEmail', name: 'EmailNotificationService', error: 'mailto not supported');
        return false;
      }
    } catch (e) {
      developer.log('Error sending session reminder email', name: 'EmailNotificationService', error: e);
      return false;
    }
  }

}
