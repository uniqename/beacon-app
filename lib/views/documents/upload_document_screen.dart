import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/document_vault_service.dart';

class UploadDocumentScreen extends StatefulWidget {
  final String userId;

  const UploadDocumentScreen({super.key, required this.userId});

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final DocumentVaultService _service = DocumentVaultService();
  final _titleController = TextEditingController();
  String _selectedCategory = 'ID Documents';
  String? _selectedFilePath;

  @override
  Widget build(BuildContext context) {
    final categories = _service.getDocumentCategories();

    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Document'),
        backgroundColor: Colors.deepOrange[700],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepOrange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, color: Colors.deepOrange[700]),
                      SizedBox(width: 12),
                      Text('Secure Upload', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Documents are encrypted with AES-256 before storage. Only you can access them.',
                    style: TextStyle(color: Colors.deepOrange[900], fontSize: 13),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Document Title *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
                helperText: 'Give this document a descriptive name',
              ),
              validator: (value) => value?.trim().isEmpty ?? true ? 'Title required' : null,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
            SizedBox(height: 24),
            Text('Select File', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.camera_alt, color: Colors.blue),
                    title: Text('Take Photo'),
                    subtitle: Text('Capture document with camera'),
                    onTap: _takePhoto,
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.photo_library, color: Colors.green),
                    title: Text('Choose from Gallery'),
                    subtitle: Text('Select existing photo'),
                    onTap: _chooseFromGallery,
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.insert_drive_file, color: Colors.orange),
                    title: Text('Choose File'),
                    subtitle: Text('PDF, DOC, or other document'),
                    onTap: _chooseFile,
                  ),
                ],
              ),
            ),
            if (_selectedFilePath != null) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700]),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'File selected: ${_selectedFilePath!.split('/').last}',
                        style: TextStyle(color: Colors.green[900]),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 20),
                      onPressed: () => setState(() => _selectedFilePath = null),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _selectedFilePath == null ? null : _uploadDocument,
              icon: Icon(Icons.upload),
              label: Text('Upload Document'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange[700],
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                      SizedBox(width: 8),
                      Text('Tips for Document Photos', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('• Ensure good lighting', style: TextStyle(fontSize: 12)),
                  Text('• Capture the entire document', style: TextStyle(fontSize: 12)),
                  Text('• Keep the document flat and readable', style: TextStyle(fontSize: 12)),
                  Text('• Avoid shadows and glare', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() => _selectedFilePath = photo.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Photo captured successfully'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accessing camera: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _chooseFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _selectedFilePath = image.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image selected successfully'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accessing gallery: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _chooseFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _selectedFilePath = result.files.single.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File selected successfully'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting file: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _uploadDocument() async {
    if (!_formKey.currentState!.validate() || _selectedFilePath == null) return;

    try {
      await _service.uploadDocument(
        userId: widget.userId,
        title: _titleController.text.trim(),
        category: _selectedCategory,
        filePath: _selectedFilePath!,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document uploaded and encrypted'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}
