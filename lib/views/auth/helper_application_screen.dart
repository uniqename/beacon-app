import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/auth_service.dart';
import '../../services/local_database_service.dart';
import '../../services/email_notification_service.dart';

class HelperApplicationScreen extends StatefulWidget {
  final String userId;
  final String userType; // 'counselor' or 'volunteer'

  const HelperApplicationScreen({
    super.key,
    required this.userId,
    required this.userType,
  });

  @override
  State<HelperApplicationScreen> createState() => _HelperApplicationScreenState();
}

class _HelperApplicationScreenState extends State<HelperApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _experienceController = TextEditingController();
  final _reasonController = TextEditingController();
  final _servicesController = TextEditingController();

  String? _certificatePath;
  String? _idDocumentPath;
  final List<String> _additionalDocsPaths = [];

  bool _isSubmitting = false;

  @override
  void dispose() {
    _experienceController.dispose();
    _reasonController.dispose();
    _servicesController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(String type) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        final filePath = result.files.single.path!;
        setState(() {
          switch (type) {
            case 'certificate':
              _certificatePath = filePath;
              break;
            case 'id':
              _idDocumentPath = filePath;
              break;
            case 'additional':
              _additionalDocsPaths.add(filePath);
              break;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate required documents
    if (widget.userType == 'counselor' && _certificatePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Certificate is required for counselors'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_idDocumentPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID document is required'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await LocalDatabaseService.saveHelperApplication(
        userId: widget.userId,
        experienceDescription: _experienceController.text.trim(),
        joiningReason: _reasonController.text.trim(),
        servicesOffered: _servicesController.text.trim(),
        certificatePath: _certificatePath,
        idDocumentPath: _idDocumentPath,
        additionalDocsPaths: _additionalDocsPaths.isNotEmpty ? _additionalDocsPaths : null,
      );

      // Get user details for email notification
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      // Send confirmation email
      if (currentUser != null) {
        final emailService = EmailNotificationService();
        await emailService.sendApplicationReceivedEmail(
          recipientEmail: currentUser.email ?? '',
          recipientName: currentUser.displayName ?? 'User',
          userType: widget.userType,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Application submitted! You\'ll access normal user features until our admin team reviews and approves your application. You\'ll receive an email when approved.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 6),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting application: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCounselor = widget.userType == 'counselor';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          // Back button cancels application and returns to login
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${isCounselor ? 'Counselor' : 'Volunteer'} Application'),
          backgroundColor: const Color(0xFFF0562D),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Back button returns to login screen
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
          ),
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Information Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Application Review Process',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your application will be reviewed by our admin team. You will be able to access the app and help users once your application is approved.',
                      style: TextStyle(fontSize: 14, color: Colors.blue[700]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Required documents:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    Text(
                      isCounselor
                          ? '• Professional certificate/license\n• Government-issued ID'
                          : '• Government-issued ID',
                      style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Experience Description
              const Text(
                'Professional Experience *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _experienceController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: isCounselor
                      ? 'Describe your counseling experience, years of practice, specializations...'
                      : 'Describe your relevant volunteer experience and skills...',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe your experience';
                  }
                  if (value.trim().length < 50) {
                    return 'Please provide more detail (at least 50 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Reason for Joining
              const Text(
                'Why do you want to join our NGO? *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Share your motivation for helping domestic violence survivors...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please share your motivation';
                  }
                  if (value.trim().length < 30) {
                    return 'Please provide more detail (at least 30 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Services Offered
              const Text(
                'What services can you offer? *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _servicesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: isCounselor
                      ? 'e.g., Trauma counseling, support groups, crisis intervention...'
                      : 'e.g., Peer support, resource navigation, administrative help...',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please specify services you can offer';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Certificate Upload (counselors only)
              if (isCounselor) ...[
                const Text(
                  'Professional Certificate/License *',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildDocumentUpload(
                  label: 'Upload Certificate',
                  path: _certificatePath,
                  onTap: () => _pickFile('certificate'),
                  isRequired: true,
                ),
                const SizedBox(height: 24),
              ],

              // ID Document Upload
              const Text(
                'Government-Issued ID *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Ghana Card, Driver\'s License, Passport, or National ID',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              _buildDocumentUpload(
                label: 'Upload ID Document',
                path: _idDocumentPath,
                onTap: () => _pickFile('id'),
                isRequired: true,
              ),
              const SizedBox(height: 24),

              // Additional Documents
              const Text(
                'Additional Documents (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'References, certifications, background checks, etc.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              if (_additionalDocsPaths.isNotEmpty)
                ..._additionalDocsPaths.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildDocumentUpload(
                      label: 'Additional Document ${entry.key + 1}',
                      path: entry.value,
                      onTap: () {},
                      isRequired: false,
                      onDelete: () {
                        setState(() {
                          _additionalDocsPaths.removeAt(entry.key);
                        });
                      },
                    ),
                  );
                }),
              ElevatedButton.icon(
                onPressed: () => _pickFile('additional'),
                icon: const Icon(Icons.add),
                label: const Text('Add Document'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black87,
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF0562D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Application',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      ), // closes WillPopScope
    );
  }

  Widget _buildDocumentUpload({
    required String label,
    required String? path,
    required VoidCallback onTap,
    required bool isRequired,
    VoidCallback? onDelete,
  }) {
    final hasFile = path != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasFile ? Colors.green[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasFile ? Colors.green : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasFile ? Icons.check_circle : Icons.upload_file,
            color: hasFile ? Colors.green : Colors.grey[600],
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: hasFile ? Colors.green[700] : Colors.grey[700],
                  ),
                ),
                if (hasFile) ...[
                  const SizedBox(height: 4),
                  Text(
                    path.split('/').last,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (hasFile && onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            )
          else if (!hasFile)
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF0562D),
                foregroundColor: Colors.white,
              ),
              child: const Text('Choose File'),
            ),
        ],
      ),
    );
  }
}
