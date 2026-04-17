import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../services/local_database_service.dart';
import '../../services/auth_service.dart';
import '../../services/email_notification_service.dart';

class AdminHelperApprovalsScreen extends StatefulWidget {
  const AdminHelperApprovalsScreen({super.key});

  @override
  State<AdminHelperApprovalsScreen> createState() => _AdminHelperApprovalsScreenState();
}

class _AdminHelperApprovalsScreenState extends State<AdminHelperApprovalsScreen> {
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = true;
  String _filter = 'pending'; // 'all', 'pending', 'approved', 'rejected'

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);

    try {
      final allApps = await LocalDatabaseService.getAllHelperApplications();

      setState(() {
        _applications = allApps;
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error loading applications: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredApplications {
    if (_filter == 'all') return _applications;
    return _applications.where((app) => app['approval_status'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _applications.where((a) => a['approval_status'] == 'pending').length;
    final approvedCount = _applications.where((a) => a['approval_status'] == 'approved').length;
    final rejectedCount = _applications.where((a) => a['approval_status'] == 'rejected').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Helper Applications'),
        backgroundColor: const Color(0xFFF0562D),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplications,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: _buildStatChip('Pending', pendingCount, Colors.orange, _filter == 'pending'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatChip('Approved', approvedCount, Colors.green, _filter == 'approved'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatChip('Rejected', rejectedCount, Colors.red, _filter == 'rejected'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatChip('All', _applications.length, Colors.blue, _filter == 'all'),
                ),
              ],
            ),
          ),

          // Applications List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredApplications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No ${_filter == 'all' ? '' : _filter} applications',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadApplications,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredApplications.length,
                          itemBuilder: (context, index) {
                            final app = _filteredApplications[index];
                            return _buildApplicationCard(app);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _filter = label.toLowerCase();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> app) {
    final submittedAt = DateTime.parse(app['submitted_at'] as String);
    final approvalStatus = app['approval_status'] as String;
    final userType = app['user_type'] as String;

    Color statusColor;
    IconData statusIcon;
    switch (approvalStatus) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewApplicationDetails(app),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: userType == 'counselor' ? Colors.purple[100] : Colors.blue[100],
                    child: Icon(
                      userType == 'counselor' ? Icons.psychology : Icons.volunteer_activism,
                      color: userType == 'counselor' ? Colors.purple[700] : Colors.blue[700],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app['display_name'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          userType == 'counselor' ? 'Counselor Application' : 'Volunteer Application',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          approvalStatus.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.email, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    app['email'] as String,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    timeago.format(submittedAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              if (approvalStatus == 'pending') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _viewApplicationDetails(app),
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text('Review'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF0562D),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _viewApplicationDetails(Map<String, dynamic> app) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApplicationDetailScreen(application: app),
      ),
    );
    _loadApplications(); // Reload after reviewing
  }
}

// Application Detail Screen
class ApplicationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> application;

  const ApplicationDetailScreen({super.key, required this.application});

  @override
  State<ApplicationDetailScreen> createState() => _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  final _notesController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _approveApplication() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final adminId = authService.currentUser?.id ?? 'unknown';

    setState(() => _isProcessing = true);

    try {
      await LocalDatabaseService.approveHelperApplication(
        userId: widget.application['user_id'] as String,
        reviewerId: adminId,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      // Send approval email notification
      final emailService = EmailNotificationService();
      final emailSent = await emailService.sendApprovalEmail(
        recipientEmail: widget.application['email'] as String,
        recipientName: widget.application['display_name'] as String,
        userType: widget.application['user_type'] as String,
        adminNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              emailSent
                  ? 'Application approved! Email notification sent.'
                  : 'Application approved! (Email notification could not be sent)',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving application: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rejectApplication() async {
    final reason = _notesController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a reason for rejection'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final adminId = authService.currentUser?.id ?? 'unknown';

    setState(() => _isProcessing = true);

    try {
      await LocalDatabaseService.rejectHelperApplication(
        userId: widget.application['user_id'] as String,
        reviewerId: adminId,
        reason: reason,
      );

      // Send rejection email notification
      final emailService = EmailNotificationService();
      final emailSent = await emailService.sendRejectionEmail(
        recipientEmail: widget.application['email'] as String,
        recipientName: widget.application['display_name'] as String,
        userType: widget.application['user_type'] as String,
        reason: reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              emailSent
                  ? 'Application rejected. Email notification sent.'
                  : 'Application rejected. (Email notification could not be sent)',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting application: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userType = widget.application['user_type'] as String;
    final approvalStatus = widget.application['approval_status'] as String;
    final submittedAt = DateTime.parse(widget.application['submitted_at'] as String);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Details'),
        backgroundColor: const Color(0xFFF0562D),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Applicant Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: userType == 'counselor' ? Colors.purple[100] : Colors.blue[100],
                          radius: 30,
                          child: Icon(
                            userType == 'counselor' ? Icons.psychology : Icons.volunteer_activism,
                            color: userType == 'counselor' ? Colors.purple[700] : Colors.blue[700],
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.application['display_name'] as String,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                userType == 'counselor' ? 'Counselor' : 'Volunteer',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.email, widget.application['email'] as String),
                    if (widget.application['phone'] != null)
                      _buildInfoRow(Icons.phone, widget.application['phone'] as String),
                    _buildInfoRow(Icons.access_time, 'Submitted ${timeago.format(submittedAt)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Experience
            const Text(
              'Professional Experience',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.application['experience_description'] as String,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Reason for Joining
            const Text(
              'Motivation for Joining',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.application['joining_reason'] as String,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Services Offered
            const Text(
              'Services Offered',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.application['services_offered'] as String,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Documents
            const Text(
              'Submitted Documents',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (widget.application['certificate_path'] != null)
              _buildDocumentTile('Professional Certificate', widget.application['certificate_path'] as String),
            if (widget.application['id_document_path'] != null)
              _buildDocumentTile('ID Document', widget.application['id_document_path'] as String),
            if ((widget.application['additional_docs_paths'] as List).isNotEmpty)
              ...(widget.application['additional_docs_paths'] as List<String>).map((path) =>
                _buildDocumentTile('Additional Document', path)
              ),
            const SizedBox(height: 24),

            // Review Notes
            if (approvalStatus == 'pending') ...[
              const Text(
                'Review Notes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Add notes about this application (optional for approval, required for rejection)...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _rejectApplication,
                      icon: const Icon(Icons.cancel),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _approveApplication,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: approvalStatus == 'approved' ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: approvalStatus == 'approved' ? Colors.green : Colors.red,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          approvalStatus == 'approved' ? Icons.check_circle : Icons.cancel,
                          color: approvalStatus == 'approved' ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          approvalStatus == 'approved' ? 'Application Approved' : 'Application Rejected',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: approvalStatus == 'approved' ? Colors.green[900] : Colors.red[900],
                          ),
                        ),
                      ],
                    ),
                    if (widget.application['review_notes'] != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Notes: ${widget.application['review_notes']}',
                        style: TextStyle(
                          color: approvalStatus == 'approved' ? Colors.green[800] : Colors.red[800],
                        ),
                      ),
                    ],
                    if (widget.application['reviewed_at'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Reviewed ${timeago.format(DateTime.parse(widget.application['reviewed_at'] as String))}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTile(String label, String path) {
    final fileName = path.split('/').last;
    final fileExists = File(path).existsSync();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          fileExists ? Icons.check_circle : Icons.warning,
          color: fileExists ? Colors.green : Colors.orange,
        ),
        title: Text(label),
        subtitle: Text(
          fileName,
          style: const TextStyle(fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: fileExists
            ? IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: () async {
                  try {
                    final uri = Uri.file(path);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cannot open this file type'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error opening document: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              )
            : null,
      ),
    );
  }
}
