import 'package:flutter/material.dart';
import '../../services/anonymous_data_service.dart';
import '../../constants/app_constants.dart';

class AnonymousSubmissionForm extends StatefulWidget {
  final String submissionType;
  final VoidCallback? onSubmitted;

  const AnonymousSubmissionForm({
    super.key,
    required this.submissionType,
    this.onSubmitted,
  });

  @override
  State<AnonymousSubmissionForm> createState() => _AnonymousSubmissionFormState();
}

class _AnonymousSubmissionFormState extends State<AnonymousSubmissionForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactInfoController = TextEditingController();
  final AnonymousDataService _anonymousService = AnonymousDataService();

  String _selectedUrgency = 'medium';
  String? _selectedContactMethod;
  String? _selectedResourceType;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _contactInfoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getFormTitle()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Privacy Notice
              _buildPrivacyNotice(),
              
              const SizedBox(height: 24),
              
              // Form Fields
              _buildFormFields(),
              
              const SizedBox(height: 32),
              
              // Submit Button
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.privacy_tip, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'Your Privacy is Protected',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This form is completely anonymous. You can choose how we contact you, or not at all. Your information is encrypted and secure.',
            style: TextStyle(color: Colors.blue[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resource Type (for resource requests)
        if (widget.submissionType == 'resource_need') ...[
          Text(
            'What type of resource do you need?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedResourceType,
            items: AppConstants.resourceCategories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedResourceType = value;
              });
            },
            decoration: const InputDecoration(
              labelText: 'Resource Type',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (widget.submissionType == 'resource_need' && value == null) {
                return 'Please select a resource type';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
        ],

        // Description
        Text(
          _getDescriptionLabel(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: _getDescriptionLabel(),
            hintText: _getDescriptionHint(),
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please provide a description';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Location (optional)
        Text(
          'Location (Optional)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'General location (e.g., Accra, Kumasi)',
            hintText: 'This helps us provide local resources',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 16),

        // Urgency Level
        Text(
          'How urgent is this?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedUrgency,
          items: const [
            DropdownMenuItem(value: 'low', child: Text('Low - Can wait a few days')),
            DropdownMenuItem(value: 'medium', child: Text('Medium - Within a few days')),
            DropdownMenuItem(value: 'high', child: Text('High - As soon as possible')),
            DropdownMenuItem(value: 'critical', child: Text('Critical - Emergency')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedUrgency = value!;
            });
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 16),

        // Contact Preference
        Text(
          'How would you prefer we follow up? (Optional)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedContactMethod,
          items: const [
            DropdownMenuItem(value: null, child: Text('No contact needed')),
            DropdownMenuItem(value: 'phone', child: Text('Phone call')),
            DropdownMenuItem(value: 'sms', child: Text('Text message')),
            DropdownMenuItem(value: 'email', child: Text('Email')),
            DropdownMenuItem(value: 'in_person', child: Text('In-person meeting')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedContactMethod = value;
              if (value == null) {
                _contactInfoController.clear();
              }
            });
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),

        // Contact Info (if contact method selected)
        if (_selectedContactMethod != null && _selectedContactMethod != 'in_person') ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _contactInfoController,
            decoration: InputDecoration(
              labelText: _getContactInfoLabel(),
              hintText: _getContactInfoHint(),
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              if (_selectedContactMethod != null && 
                  _selectedContactMethod != 'in_person' && 
                  (value == null || value.trim().isEmpty)) {
                return 'Please provide contact information';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Submit Anonymous Request'),
      ),
    );
  }

  String _getFormTitle() {
    switch (widget.submissionType) {
      case 'help_request':
        return 'Request Support';
      case 'resource_need':
        return 'Resource Request';
      case 'emergency_info':
        return 'Emergency Information';
      default:
        return 'Anonymous Submission';
    }
  }

  String _getDescriptionLabel() {
    switch (widget.submissionType) {
      case 'help_request':
        return 'How can we help you?';
      case 'resource_need':
        return 'Describe what you need';
      case 'emergency_info':
        return 'Describe your situation';
      default:
        return 'Tell us what you need';
    }
  }

  String _getDescriptionHint() {
    switch (widget.submissionType) {
      case 'help_request':
        return 'Please describe your situation and how we can support you...';
      case 'resource_need':
        return 'Describe the specific resource or service you need...';
      case 'emergency_info':
        return 'Describe your emergency situation. If immediate, call 191 first...';
      default:
        return 'Provide as much detail as you feel comfortable sharing...';
    }
  }

  String _getContactInfoLabel() {
    switch (_selectedContactMethod) {
      case 'phone':
      case 'sms':
        return 'Phone Number';
      case 'email':
        return 'Email Address';
      default:
        return 'Contact Information';
    }
  }

  String _getContactInfoHint() {
    switch (_selectedContactMethod) {
      case 'phone':
        return 'Your phone number for a call';
      case 'sms':
        return 'Your phone number for text messages';
      case 'email':
        return 'Your email address';
      default:
        return 'How to reach you';
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String submissionId;
      
      if (widget.submissionType == 'resource_need') {
        submissionId = await _anonymousService.submitResourceRequest(
          resourceType: _selectedResourceType!,
          description: _descriptionController.text.trim(),
          location: _locationController.text.trim().isNotEmpty 
              ? _locationController.text.trim() 
              : null,
          preferredContact: _selectedContactMethod,
          contactInfo: _contactInfoController.text.trim().isNotEmpty 
              ? _contactInfoController.text.trim() 
              : null,
        );
      } else if (widget.submissionType == 'emergency_info') {
        submissionId = await _anonymousService.submitEmergencyInfo(
          situation: _descriptionController.text.trim(),
          location: _locationController.text.trim().isNotEmpty 
              ? _locationController.text.trim() 
              : null,
          safeContactMethod: _selectedContactMethod,
          isImmediate: _selectedUrgency == 'critical',
        );
      } else {
        submissionId = await _anonymousService.submitHelpRequest(
          helpDescription: _descriptionController.text.trim(),
          location: _locationController.text.trim().isNotEmpty 
              ? _locationController.text.trim() 
              : null,
          contactPreference: _selectedContactMethod,
          contactInfo: _contactInfoController.text.trim().isNotEmpty 
              ? _contactInfoController.text.trim() 
              : null,
        );
      }

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Submission Received'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 48),
                const SizedBox(height: 16),
                const Text('Thank you for reaching out. Your submission has been received securely.'),
                const SizedBox(height: 8),
                Text(
                  'Reference ID: ${submissionId.substring(0, 8)}',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
                const SizedBox(height: 8),
                if (_selectedContactMethod != null)
                  const Text('We will follow up based on your contact preferences.')
                else
                  const Text('No follow-up was requested. You can submit another request anytime.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to home
                  widget.onSubmitted?.call();
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}