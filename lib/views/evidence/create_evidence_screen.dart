import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../models/evidence_log.dart';
import '../../services/evidence_service.dart';

class CreateEvidenceScreen extends StatefulWidget {
  final String userId;

  const CreateEvidenceScreen({super.key, required this.userId});

  @override
  State<CreateEvidenceScreen> createState() => _CreateEvidenceScreenState();
}

class _CreateEvidenceScreenState extends State<CreateEvidenceScreen> {
  final _formKey = GlobalKey<FormState>();
  final EvidenceService _service = EvidenceService();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _witnessesController = TextEditingController();

  DateTime _incidentDate = DateTime.now();
  Severity _severity = Severity.medium;
  bool _policeInvolved = false;
  bool _medicalAttention = false;
  String? _policeReportNumber;
  String? _hospitalName;

  final List<String> _photoUrls = [];
  final List<String> _audioUrls = [];
  bool _isRecording = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Document Evidence'),
        backgroundColor: Colors.deepPurple[700],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.amber[700]),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All entries are timestamped and can be exported for legal use.',
                      style: TextStyle(color: Colors.amber[900], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
                helperText: 'Brief summary of the incident',
              ),
              validator: (value) => value?.trim().isEmpty ?? true ? 'Title required' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                helperText: 'Detailed description of what happened',
              ),
              maxLines: 5,
              validator: (value) => value?.trim().isEmpty ?? true ? 'Description required' : null,
            ),
            SizedBox(height: 16),
            ListTile(
              title: Text('Incident Date & Time'),
              subtitle: Text(_incidentDate.toString().substring(0, 16)),
              leading: Icon(Icons.calendar_today),
              trailing: Icon(Icons.edit),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _incidentDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_incidentDate),
                  );
                  if (time != null) {
                    setState(() {
                      _incidentDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                    });
                  }
                }
              },
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<Severity>(
              initialValue: _severity,
              decoration: InputDecoration(
                labelText: 'Severity',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.priority_high),
              ),
              items: Severity.values
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.toString().split('.').last.toUpperCase()),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _severity = value!),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.place),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _witnessesController,
              decoration: InputDecoration(
                labelText: 'Witnesses',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people),
                helperText: 'Names of any witnesses present',
              ),
              maxLines: 2,
            ),
            SizedBox(height: 24),

            // Photo Evidence Section
            Text('Photo Evidence', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _capturePhoto,
                    icon: Icon(Icons.camera_alt),
                    label: Text('Take Photo'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple[700]),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickPhotos,
                    icon: Icon(Icons.photo_library),
                    label: Text('Pick Photos'),
                  ),
                ),
              ],
            ),
            if (_photoUrls.isNotEmpty) ...[
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _photoUrls.asMap().entries.map((entry) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(entry.value),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          icon: Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => setState(() => _photoUrls.removeAt(entry.key)),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              Text('${_photoUrls.length} photo(s) attached', style: TextStyle(color: Colors.grey[600])),
            ],
            SizedBox(height: 24),

            // Audio Recording Section
            Text('Audio Recording', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _toggleAudioRecording,
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label: Text(_isRecording ? 'Stop Recording' : 'Record Audio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRecording ? Colors.red : Colors.deepPurple[700],
              ),
            ),
            if (_audioUrls.isNotEmpty) ...[
              SizedBox(height: 12),
              ...List.generate(_audioUrls.length, (index) {
                return Card(
                  child: ListTile(
                    leading: Icon(Icons.audiotrack, color: Colors.deepPurple[700]),
                    title: Text('Recording ${index + 1}'),
                    subtitle: Text('Audio file'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => setState(() => _audioUrls.removeAt(index)),
                    ),
                  ),
                );
              }),
              Text('${_audioUrls.length} recording(s) attached', style: TextStyle(color: Colors.grey[600])),
            ],
            SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Police Involved'),
                    subtitle: Text('Was this reported to police?'),
                    value: _policeInvolved,
                    onChanged: (value) => setState(() => _policeInvolved = value),
                  ),
                  if (_policeInvolved) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Police Report Number',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _policeReportNumber = value,
                      ),
                    ),
                    SizedBox(height: 12),
                  ],
                  SwitchListTile(
                    title: Text('Medical Attention'),
                    subtitle: Text('Did you seek medical help?'),
                    value: _medicalAttention,
                    onChanged: (value) => setState(() => _medicalAttention = value),
                  ),
                  if (_medicalAttention) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Hospital/Clinic Name',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _hospitalName = value,
                      ),
                    ),
                    SizedBox(height: 12),
                  ],
                ],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saveEvidence,
              icon: Icon(Icons.save),
              label: Text('Save Evidence'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple[700],
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _capturePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() => _photoUrls.add(image.path));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo captured successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing photo: $e')),
      );
    }
  }

  Future<void> _pickPhotos() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(imageQuality: 80);

      if (images.isNotEmpty) {
        setState(() {
          _photoUrls.addAll(images.map((img) => img.path));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${images.length} photo(s) added')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking photos: $e')),
      );
    }
  }

  Future<void> _toggleAudioRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      if (path != null) {
        setState(() {
          _audioUrls.add(path);
          _isRecording = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audio recorded successfully')),
        );
      }
    } else {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/evidence_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: filePath,
        );

        setState(() => _isRecording = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording started...')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Microphone permission required')),
        );
      }
    }
  }

  Future<void> _saveEvidence() async {
    if (!_formKey.currentState!.validate()) return;


    try {
      await _service.createEvidence(
        userId: widget.userId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        incidentDate: _incidentDate,
        severity: _severity,
        location: _locationController.text.trim(),
        photoUrls: _photoUrls,
        audioUrls: _audioUrls,
        witnesses: _witnessesController.text.trim().split('\n').where((w) => w.trim().isNotEmpty).toList(),
        policeInvolved: _policeInvolved,
        policeReportNumber: _policeReportNumber,
        medicalAttention: _medicalAttention,
        hospitalName: _hospitalName,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Evidence saved successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving evidence: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _witnessesController.dispose();
    super.dispose();
  }
}
