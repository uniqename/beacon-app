import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/beacon_division.dart';

class ApplicationFormScreen extends StatefulWidget {
  final BeaconDivision division;
  final String serviceType; // 'volunteer', 'job', 'support'
  final JobOpportunity? jobOpportunity;
  final String? serviceName;

  const ApplicationFormScreen({
    Key? key,
    required this.division,
    required this.serviceType,
    this.jobOpportunity,
    this.serviceName,
  }) : super(key: key);

  @override
  _ApplicationFormScreenState createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _motivationController = TextEditingController();
  final TextEditingController _availabilityController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _referencesController = TextEditingController();

  List<PlatformFile?> _selectedFiles = [];
  String _selectedAvailability = 'Weekdays';
  bool _hasTransportation = false;
  bool _agreedToTerms = false;
  String _preferredContact = 'Email';

  @override
  Widget build(BuildContext context) {
    Color primaryColor = Color(int.parse(widget.division.color.replaceFirst('#', '0xFF')));
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _getTitle(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildApplicationHeader(primaryColor),
                    SizedBox(height: 24),
                    _buildPersonalInfoSection(),
                    SizedBox(height: 24),
                    _buildExperienceSection(),
                    SizedBox(height: 24),
                    _buildAvailabilitySection(),
                    SizedBox(height: 24),
                    _buildDocumentSection(),
                    SizedBox(height: 24),
                    _buildAgreementSection(),
                    SizedBox(height: 100), // Space for button
                  ],
                ),
              ),
            ),
            _buildSubmitButton(primaryColor),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (widget.serviceType) {
      case 'volunteer':
        return 'Volunteer Application';
      case 'job':
        return 'Job Application';
      case 'support':
        return 'Support Request';
      default:
        return 'Application Form';
    }
  }

  Widget _buildApplicationHeader(Color primaryColor) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: primaryColor,
                child: Icon(
                  _getServiceIcon(),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.division.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.jobOpportunity?.title ?? widget.serviceName ?? 'General Application',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            _getApplicationDescription(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getServiceIcon() {
    switch (widget.serviceType) {
      case 'volunteer':
        return Icons.volunteer_activism;
      case 'job':
        return Icons.work;
      case 'support':
        return Icons.support_agent;
      default:
        return Icons.assignment;
    }
  }

  String _getApplicationDescription() {
    switch (widget.serviceType) {
      case 'volunteer':
        return 'Thank you for your interest in volunteering with Beacon of New Beginnings. Please fill out the form below to help us understand your background and how you can best contribute to our mission.';
      case 'job':
        return 'We appreciate your interest in joining our team. Please provide detailed information about your qualifications and experience for this position.';
      case 'support':
        return 'We\'re here to help you. Please provide information about the support services you need, and we\'ll connect you with the appropriate resources.';
      default:
        return 'Please fill out the application form below.';
    }
  }

  Widget _buildPersonalInfoSection() {
    return _buildSection(
      'Personal Information',
      Icons.person,
      [
        _buildTextField(
          controller: _nameController,
          label: 'Full Name',
          hint: 'Enter your full name',
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Name is required';
            return null;
          },
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'Enter your email address',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Email is required';
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
              return 'Enter a valid email address';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: 'Enter your phone number',
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Phone number is required';
            return null;
          },
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _addressController,
          label: 'Address',
          hint: 'Enter your full address',
          maxLines: 2,
        ),
        SizedBox(height: 16),
        _buildDropdownField(
          'Preferred Contact Method',
          _preferredContact,
          ['Email', 'Phone', 'SMS'],
          (value) => setState(() => _preferredContact = value!),
        ),
      ],
    );
  }

  Widget _buildExperienceSection() {
    return _buildSection(
      'Experience & Qualifications',
      Icons.school,
      [
        _buildTextField(
          controller: _experienceController,
          label: 'Relevant Experience',
          hint: 'Describe your relevant experience, education, or training',
          maxLines: 4,
          validator: (value) {
            if (widget.serviceType == 'job' && (value?.isEmpty ?? true)) {
              return 'Experience details are required for job applications';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _skillsController,
          label: 'Skills & Qualifications',
          hint: 'List your relevant skills, certifications, or qualifications',
          maxLines: 3,
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _motivationController,
          label: 'Motivation & Goals',
          hint: 'Why are you interested in this opportunity? What are your goals?',
          maxLines: 3,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Please share your motivation';
            return null;
          },
        ),
        if (widget.serviceType != 'support') ...[
          SizedBox(height: 16),
          _buildTextField(
            controller: _referencesController,
            label: 'References',
            hint: 'Please provide 2-3 references (Name, relationship, contact info)',
            maxLines: 3,
          ),
        ],
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    return _buildSection(
      'Availability & Preferences',
      Icons.schedule,
      [
        _buildDropdownField(
          'Availability',
          _selectedAvailability,
          ['Weekdays', 'Weekends', 'Evenings', 'Flexible', 'Full-time'],
          (value) => setState(() => _selectedAvailability = value!),
        ),
        SizedBox(height: 16),
        _buildTextField(
          controller: _availabilityController,
          label: 'Specific Availability Details',
          hint: 'Please specify your available days, times, and any constraints',
          maxLines: 2,
        ),
        SizedBox(height: 16),
        CheckboxListTile(
          title: Text('I have reliable transportation'),
          subtitle: Text('Check if you can travel to different locations as needed'),
          value: _hasTransportation,
          onChanged: (value) => setState(() => _hasTransportation = value ?? false),
          activeColor: Color(int.parse(widget.division.color.replaceFirst('#', '0xFF'))),
        ),
      ],
    );
  }

  Widget _buildDocumentSection() {
    return _buildSection(
      'Supporting Documents',
      Icons.upload_file,
      [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            children: [
              Icon(Icons.cloud_upload, size: 32, color: Colors.blue[600]),
              SizedBox(height: 8),
              Text(
                'Upload Supporting Documents',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Resume, certificates, ID copy, or other relevant documents',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _pickFiles,
                icon: Icon(Icons.add),
                label: Text('Select Files'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        if (_selectedFiles.isNotEmpty) ...[
          SizedBox(height: 16),
          ..._selectedFiles.map((file) => Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.insert_drive_file, color: Colors.green[600]),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    file?.name ?? 'Unknown file',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red[600]),
                  onPressed: () => _removeFile(file),
                ),
              ],
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildAgreementSection() {
    return _buildSection(
      'Terms & Agreement',
      Icons.gavel,
      [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Application Terms:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '• All information provided is accurate and truthful\n'
                '• Background checks may be conducted for certain positions\n'
                '• Volunteer commitments should be honored\n'
                '• Personal information will be kept confidential\n'
                '• Application review may take 3-5 business days',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        CheckboxListTile(
          title: Text('I agree to the terms and conditions'),
          subtitle: Text('Required to submit application'),
          value: _agreedToTerms,
          onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
          activeColor: Color(int.parse(widget.division.color.replaceFirst('#', '0xFF'))),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Color(int.parse(widget.division.color.replaceFirst('#', '0xFF')))),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(int.parse(widget.division.color.replaceFirst('#', '0xFF'))),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Color(int.parse(widget.division.color.replaceFirst('#', '0xFF'))),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> options,
    void Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Color(int.parse(widget.division.color.replaceFirst('#', '0xFF'))),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: options.map((option) => DropdownMenuItem(
        value: option,
        child: Text(option),
      )).toList(),
    );
  }

  Widget _buildSubmitButton(Color primaryColor) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey[300]!,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _agreedToTerms ? _submitApplication : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Text(
              'Submit Application',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          _selectedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking files: $e')),
      );
    }
  }

  void _removeFile(PlatformFile? file) {
    setState(() {
      _selectedFiles.remove(file);
    });
  }

  void _submitApplication() {
    if (_formKey.currentState!.validate()) {
      _showConfirmationDialog();
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            SizedBox(width: 12),
            Text('Application Submitted!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thank you for your application. We have received your information and will review it within 3-5 business days.',
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What happens next?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Application review: 3-5 days\n'
                    '• Background check (if required)\n'
                    '• Interview scheduling\n'
                    '• Notification via ${_preferredContact.toLowerCase()}',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close application screen
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _experienceController.dispose();
    _motivationController.dispose();
    _availabilityController.dispose();
    _skillsController.dispose();
    _referencesController.dispose();
    super.dispose();
  }
}