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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Upload Document'),
        backgroundColor: Colors.deepOrange[700],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Secure upload banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepOrange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepOrange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, color: Colors.deepOrange[700]),
                      const SizedBox(width: 12),
                      Text(
                        'Secure Upload',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.deepOrange[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Documents are encrypted with AES-256 before storage. Only you can access them.',
                    style: TextStyle(color: Colors.deepOrange[900], fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Document Title *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.title),
                helperText: 'Give this document a descriptive name',
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
              ),
              validator: (value) =>
                  value?.trim().isEmpty ?? true ? 'Title required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              dropdownColor: colorScheme.surface,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Category',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.category),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
              ),
              items: categories
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat,
                            style: TextStyle(color: colorScheme.onSurface)),
                      ))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _selectedCategory = value!),
            ),
            const SizedBox(height: 24),
            Text(
              'Select File',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                border: Border.all(color: colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading:
                        Icon(Icons.camera_alt, color: Colors.blue[700]),
                    title: Text('Take Photo',
                        style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600)),
                    subtitle: Text('Capture document with camera',
                        style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13)),
                    onTap: _takePhoto,
                  ),
                  Divider(height: 1, color: colorScheme.outlineVariant),
                  ListTile(
                    leading:
                        Icon(Icons.photo_library, color: Colors.green[700]),
                    title: Text('Choose from Gallery',
                        style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600)),
                    subtitle: Text('Select existing photo',
                        style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13)),
                    onTap: _chooseFromGallery,
                  ),
                  Divider(height: 1, color: colorScheme.outlineVariant),
                  ListTile(
                    leading:
                        Icon(Icons.insert_drive_file, color: Colors.orange[700]),
                    title: Text('Choose File',
                        style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600)),
                    subtitle: Text('PDF, DOC, or other document',
                        style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13)),
                    onTap: _chooseFile,
                  ),
                ],
              ),
            ),
            if (_selectedFilePath != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'File selected: ${_selectedFilePath!.split('/').last}',
                        style: TextStyle(color: Colors.green[900]),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      color: Colors.green[800],
                      onPressed: () =>
                          setState(() => _selectedFilePath = null),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _selectedFilePath == null ? null : _uploadDocument,
              icon: const Icon(Icons.upload),
              label: const Text('Upload Document',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange[700],
                foregroundColor: Colors.white,
                disabledBackgroundColor: colorScheme.surfaceContainerHighest,
                disabledForegroundColor: colorScheme.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            // Tips box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.amber[800], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Tips for Document Photos',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[900],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _tip('Ensure good lighting'),
                  _tip('Capture the entire document'),
                  _tip('Keep the document flat and readable'),
                  _tip('Avoid shadows and glare'),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _tip(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ', style: TextStyle(color: Colors.amber[900])),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 13, color: Colors.amber[900]),
              ),
            ),
          ],
        ),
      );

  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() => _selectedFilePath = photo.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Photo captured successfully'),
                backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error accessing camera: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _chooseFromGallery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _selectedFilePath = image.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Image selected successfully'),
                backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error accessing gallery: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _chooseFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() => _selectedFilePath = result.files.single.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('File selected successfully'),
                backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error selecting file: $e'),
              backgroundColor: Colors.red),
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
          const SnackBar(
              content: Text('Document uploaded and encrypted'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Upload error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}
