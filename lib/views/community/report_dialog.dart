import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../constants/brand_colors.dart';
import '../../services/local_database_service.dart';
import '../../services/support_group_service.dart';
import '../../services/email_notification_service.dart';

/// Dialog for reporting issues or users in support groups
///
/// Allows users to report:
/// - Inappropriate behavior
/// - Harassment or bullying
/// - Spam or scam
/// - Safety concerns
/// - Other issues
class ReportDialog extends StatefulWidget {
  final String groupId;
  final String? sessionId;
  final String reporterId;
  final String? reportedUserId;

  const ReportDialog({
    super.key,
    required this.groupId,
    this.sessionId,
    required this.reporterId,
    this.reportedUserId,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  String _selectedReason = 'inappropriate';
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _reportReasons = [
    {
      'value': 'inappropriate',
      'label': 'Inappropriate Behavior',
      'icon': Icons.warning_amber_rounded,
      'description': 'Content or behavior that violates community guidelines',
    },
    {
      'value': 'harassment',
      'label': 'Harassment or Bullying',
      'icon': Icons.sentiment_very_dissatisfied,
      'description': 'Targeted attacks, threats, or intimidation',
    },
    {
      'value': 'spam',
      'label': 'Spam or Scam',
      'icon': Icons.report_problem,
      'description': 'Unsolicited advertising or fraudulent content',
    },
    {
      'value': 'safety',
      'label': 'Safety Concern',
      'icon': Icons.health_and_safety,
      'description': 'Immediate safety risk or crisis situation',
    },
    {
      'value': 'other',
      'label': 'Other',
      'icon': Icons.more_horiz,
      'description': 'Other issues not listed above',
    },
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  /// Send email notification to admins about the report
  Future<void> _sendReportNotification(String reportId) async {
    try {
      final db = await LocalDatabaseService.database;
      final groupService = SupportGroupService();
      final emailService = EmailNotificationService();

      // Get reporter name
      final reporterResult = await db.query('users', where: 'id = ?', whereArgs: [widget.reporterId]);
      final reporterName = reporterResult.isNotEmpty
          ? (reporterResult.first['name'] as String? ?? 'Anonymous User')
          : 'Anonymous User';

      // Get group name
      final group = await groupService.getGroup(widget.groupId);
      final groupName = group?.name ?? 'Unknown Group';

      // Get reason label
      final reasonLabel = _reportReasons
          .firstWhere(
            (r) => r['value'] == _selectedReason,
            orElse: () => {'label': _selectedReason},
          )['label'] as String;

      // Get admin email from .env
      final adminEmail = dotenv.get('ADMIN_EMAIL', fallback: 'admin@beaconnewbeginnings.org');

      // Send email
      await emailService.sendReportNotificationEmail(
        adminEmail: adminEmail,
        reportId: reportId,
        reporterName: reporterName,
        groupName: groupName,
        reason: reasonLabel,
        description: _descriptionController.text.trim(),
      );
    } catch (e) {
      developer.log('Error sending report notification: $e');
      // Don't rethrow - email is optional
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final db = await LocalDatabaseService.database;

      // Generate report ID
      final reportId = const Uuid().v4();

      // Insert report into database
      await db.insert('support_group_reports', {
        'id': reportId,
        'group_id': widget.groupId,
        'session_id': widget.sessionId,
        'reporter_id': widget.reporterId,
        'reported_user_id': widget.reportedUserId,
        'reason': _selectedReason,
        'description': _descriptionController.text.trim(),
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Send email notification to admins (non-blocking)
      _sendReportNotification(reportId).catchError((error) {
        developer.log('Failed to send report email notification: $error');
      });

      if (mounted) {
        Navigator.of(context).pop(true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Report submitted. Our team will review it promptly.'),
            backgroundColor: BeaconColors.softSageGreen,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      developer.log('Error submitting report: $e');

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flag, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Report Issue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info message
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: BeaconColors.softSageGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: BeaconColors.softSageGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Your report is confidential and will be reviewed by our moderation team. We take all reports seriously.',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Reason selection
                      Text(
                        'What\'s the issue? *',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ..._reportReasons.map((reason) {
                        final isSelected = _selectedReason == reason['value'];

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedReason = reason['value'];
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.red.withValues(alpha: 0.05)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.red
                                    : BeaconColors.deepCharcoal.withValues(alpha: 0.2),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  reason['icon'] as IconData,
                                  color: isSelected
                                      ? Colors.red
                                      : BeaconColors.deepCharcoal.withValues(alpha: 0.6),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        reason['label'],
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        reason['description'],
                                        style: TextStyle(
                                          color: BeaconColors.deepCharcoal.withValues(alpha: 0.6),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 20),

                      // Description
                      Text(
                        'Additional Details *',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: InputDecoration(
                          hintText: 'Please describe what happened...',
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: BeaconColors.deepCharcoal.withValues(alpha: 0.3),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: BeaconColors.deepCharcoal.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please provide details about the issue';
                          }
                          if (value.trim().length < 10) {
                            return 'Please provide more details (at least 10 characters)';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Safety message for crisis situations
                      if (_selectedReason == 'safety')
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.emergency,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Immediate Safety Concern?',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'If you or someone else is in immediate danger, please contact emergency services (911) or the National Domestic Violence Hotline at 1-800-799-7233.',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: BeaconColors.deepCharcoal.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: BeaconColors.deepCharcoal),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Submit Report'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
