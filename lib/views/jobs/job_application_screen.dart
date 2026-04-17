import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../../models/beacon_division.dart';

class JobApplicationScreen extends StatefulWidget {
  final JobOpportunity job;
  const JobApplicationScreen({super.key, required this.job});

  @override
  State<JobApplicationScreen> createState() => _JobApplicationScreenState();
}

class _JobApplicationScreenState extends State<JobApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _coverLetterController = TextEditingController();
  final _experienceController = TextEditingController();
  final _skillsController = TextEditingController();

  static const _darkBg = Color(0xFF0A0E1A);
  static const _cardBg = Color(0xFF141929);
  static const _accent = Color(0xFFF0562D);
  static const _accentLight = Color(0xFF00D4AA);

  String _availability = 'Weekdays';
  bool _hasTransport = false;
  bool _agreedToTerms = false;
  bool _isSubmitting = false;
  int _currentStep = 0;

  File? _profilePhoto;
  List<PlatformFile> _cvFiles = [];
  List<PlatformFile> _supportingDocs = [];

  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _coverLetterController.dispose();
    _experienceController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _profilePhoto = File(picked.path));
  }

  Future<void> _pickCV() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _cvFiles = result.files);
    }
  }

  Future<void> _pickSupportingDocs() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      allowMultiple: true,
    );
    if (result != null) {
      setState(() => _supportingDocs = [..._supportingDocs, ...result.files]);
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields'), backgroundColor: Colors.red),
      );
      return;
    }
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the terms'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Save application to local storage
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString('job_applications') ?? '[]';
      final list = List<Map<String, dynamic>>.from(jsonDecode(existing) as List);

      list.add({
        'id': const Uuid().v4(),
        'job_id': widget.job.id,
        'job_title': widget.job.title,
        'job_type': widget.job.type,
        'applicant_name': _nameController.text.trim(),
        'applicant_email': _emailController.text.trim(),
        'applicant_phone': _phoneController.text.trim(),
        'cover_letter': _coverLetterController.text.trim(),
        'experience': _experienceController.text.trim(),
        'skills': _skillsController.text.trim(),
        'availability': _availability,
        'has_transport': _hasTransport,
        'cv_filename': _cvFiles.isNotEmpty ? _cvFiles.first.name : null,
        'supporting_docs': _supportingDocs.map((f) => f.name).toList(),
        'status': 'submitted',
        'submitted_at': DateTime.now().toIso8601String(),
      });

      await prefs.setString('job_applications', jsonEncode(list));

      setState(() => _isSubmitting = false);

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF00D4AA), size: 56),
            SizedBox(height: 12),
            Text('Application Submitted!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Your application for ${widget.job.title} has been received.\n\n'
          'We will review it and contact you at ${_emailController.text} within 5–7 business days.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white60, height: 1.5),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // close application screen
                Navigator.pop(context); // close detail screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentLight,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: _cardBg,
        elevation: 0,
        title: Text(
          'Apply: ${widget.job.title}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _currentStep == 0
                    ? _buildPersonalInfo()
                    : _currentStep == 1
                        ? _buildDocuments()
                        : _buildReview(),
              ),
            ),
            _buildNavButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Personal Info', 'Documents', 'Review'];
    return Container(
      color: _cardBg,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: steps.asMap().entries.map((e) {
          final done = e.key < _currentStep;
          final active = e.key == _currentStep;
          final color = done || active ? _accentLight : Colors.white24;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: done ? _accentLight : (active ? _accentLight.withValues(alpha: 0.2) : Colors.transparent),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Center(
                    child: done
                        ? const Icon(Icons.check, size: 14, color: Colors.black)
                        : Text('${e.key + 1}',
                            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(e.value,
                      style: TextStyle(
                          color: active ? Colors.white : Colors.white38,
                          fontSize: 11,
                          fontWeight: active ? FontWeight.bold : FontWeight.normal)),
                ),
                if (e.key < steps.length - 1)
                  Expanded(
                    child: Container(
                        height: 1,
                        color: e.key < _currentStep ? _accentLight : Colors.white12),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile photo
        Center(
          child: GestureDetector(
            onTap: _pickProfilePhoto,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _cardBg,
                border: Border.all(color: _accentLight.withValues(alpha: 0.4), width: 2),
                image: _profilePhoto != null
                    ? DecorationImage(image: FileImage(_profilePhoto!), fit: BoxFit.cover)
                    : null,
              ),
              child: _profilePhoto == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_a_photo, color: Color(0xFF00D4AA), size: 24),
                        SizedBox(height: 4),
                        Text('Photo', style: TextStyle(color: Colors.white38, fontSize: 10)),
                      ],
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _field(_nameController, 'Full Name *', Icons.person_outline, required: true),
        const SizedBox(height: 14),
        _field(_emailController, 'Email Address *', Icons.email_outlined,
            required: true, keyboard: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _field(_phoneController, 'Phone Number *', Icons.phone_outlined,
            required: true, keyboard: TextInputType.phone),
        const SizedBox(height: 14),
        _sectionLabel('Availability'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Weekdays', 'Weekends', 'Evenings', 'Flexible']
              .map((a) => _chip(a, _availability == a, () => setState(() => _availability = a)))
              .toList(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Switch(value: _hasTransport, onChanged: (v) => setState(() => _hasTransport = v), activeThumbColor: _accentLight),
            const SizedBox(width: 8),
            const Text('I have my own transportation', style: TextStyle(color: Colors.white70)),
          ],
        ),
        const SizedBox(height: 14),
        _field(_skillsController, 'Key Skills', Icons.star_outline,
            hint: 'e.g., Communication, Microsoft Office, Teaching'),
        const SizedBox(height: 14),
        _field(_experienceController, 'Relevant Experience', Icons.work_outline,
            maxLines: 4, hint: 'Briefly describe any relevant experience or background'),
        const SizedBox(height: 14),
        _field(_coverLetterController, 'Why do you want this role? *', Icons.edit_note,
            required: true, maxLines: 5,
            hint: 'Tell us why you\'re a great fit for ${widget.job.title}'),
      ],
    );
  }

  Widget _buildDocuments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _docSection(
          title: 'CV / Resume',
          subtitle: 'Upload your CV in PDF, DOC, or DOCX format',
          icon: Icons.description_outlined,
          color: _accentLight,
          files: _cvFiles.map((f) => f.name).toList(),
          onPick: _pickCV,
          allowMultiple: false,
        ),
        const SizedBox(height: 16),
        _docSection(
          title: 'Supporting Documents',
          subtitle: 'Certificates, references, or any other relevant documents',
          icon: Icons.attach_file,
          color: const Color(0xFFFFB347),
          files: _supportingDocs.map((f) => f.name).toList(),
          onPick: _pickSupportingDocs,
          allowMultiple: true,
          onRemove: (i) => setState(() => _supportingDocs.removeAt(i)),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _accentLight.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _accentLight.withValues(alpha: 0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.lock_outline, color: Color(0xFF00D4AA), size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your documents are stored securely on this device and only shared with Beacon of New Beginnings staff.',
                  style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReview() {
    final sections = [
      _ReviewRow('Name', _nameController.text),
      _ReviewRow('Email', _emailController.text),
      _ReviewRow('Phone', _phoneController.text),
      _ReviewRow('Availability', _availability),
      _ReviewRow('Transportation', _hasTransport ? 'Yes' : 'No'),
      if (_cvFiles.isNotEmpty) _ReviewRow('CV', _cvFiles.first.name),
      _ReviewRow('Supporting Docs', '${_supportingDocs.length} file(s)'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Applying for'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _accent.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.work_outline, color: Color(0xFFF0562D)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.job.title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('${widget.job.type} · ${widget.job.location}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionLabel('Your Details'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
              color: _cardBg, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: sections
                .map((r) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 110,
                            child: Text(r.label,
                                style: const TextStyle(color: Colors.white38, fontSize: 13)),
                          ),
                          Expanded(
                            child: Text(r.value.isEmpty ? '—' : r.value,
                                style: const TextStyle(color: Colors.white, fontSize: 13)),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _agreedToTerms,
              onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
              activeColor: _accentLight,
              side: const BorderSide(color: Colors.white38),
            ),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'I confirm all information provided is accurate and I agree to Beacon of New Beginnings\' application terms.',
                  style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      color: _cardBg,
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () {
                      if (_currentStep < 2) {
                        if (_currentStep == 0 && !_formKey.currentState!.validate()) return;
                        setState(() => _currentStep++);
                      } else {
                        _submitApplication();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentLight,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text(
                      _currentStep == 2 ? 'Submit Application' : 'Continue',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: _cardBg,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF00D4AA)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      );

  Widget _chip(String label, bool selected, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? _accentLight.withValues(alpha: 0.15) : _cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? _accentLight : Colors.white24, width: 1.5),
          ),
          child: Text(
            label,
            style: TextStyle(
                color: selected ? _accentLight : Colors.white54,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal),
          ),
        ),
      );

  Widget _docSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<String> files,
    required VoidCallback onPick,
    bool allowMultiple = false,
    void Function(int)? onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    Text(subtitle,
                        style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (files.isNotEmpty) ...[
            ...files.asMap().entries.map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.insert_drive_file, color: color, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(e.value,
                            style: TextStyle(color: color, fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (onRemove != null)
                        GestureDetector(
                          onTap: () => onRemove(e.key),
                          child: Icon(Icons.close, color: Colors.white38, size: 16),
                        ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onPick,
              icon: Icon(Icons.upload_file, size: 16, color: color),
              label: Text(
                files.isEmpty
                    ? 'Select File${allowMultiple ? 's' : ''}'
                    : 'Add ${allowMultiple ? 'More' : 'Different'} File',
                style: TextStyle(color: color),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow {
  final String label;
  final String value;
  _ReviewRow(this.label, this.value);
}
