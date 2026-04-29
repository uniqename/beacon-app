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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Upload Document',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.deepOrange[700],
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Secure Upload banner ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(color: Colors.deepOrange[700]!, width: 4),
                  top: BorderSide(color: Colors.deepOrange[200]!),
                  right: BorderSide(color: Colors.deepOrange[200]!),
                  bottom: BorderSide(color: Colors.deepOrange[200]!),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange[700],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.security,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Secure Upload',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Documents are encrypted with AES-256 before storage. Only you can access them.',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Document Title ────────────────────────────────────────────
            TextFormField(
              controller: _titleController,
              style: TextStyle(color: Colors.grey[900], fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Document Title *',
                labelStyle: TextStyle(color: Colors.grey[700]),
                hintText: 'Give this document a descriptive name',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[350]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: Colors.deepOrange[700]!, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon:
                    Icon(Icons.title, color: Colors.deepOrange[700]),
              ),
              validator: (v) =>
                  v?.trim().isEmpty ?? true ? 'Title is required' : null,
            ),
            const SizedBox(height: 14),

            // ── Category dropdown ─────────────────────────────────────────
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              dropdownColor: Colors.white,
              style: TextStyle(color: Colors.grey[900], fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: TextStyle(color: Colors.grey[700]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[350]!),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                prefixIcon:
                    Icon(Icons.category, color: Colors.deepOrange[700]),
              ),
              items: categories
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat,
                            style: TextStyle(color: Colors.grey[900])),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            const SizedBox(height: 20),

            // ── Select File ───────────────────────────────────────────────
            Text(
              'Select File',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  _fileTile(
                    icon: Icons.camera_alt,
                    iconColor: Colors.blue[700]!,
                    title: 'Take Photo',
                    subtitle: 'Capture document with camera',
                    onTap: _takePhoto,
                  ),
                  Divider(height: 1, color: Colors.grey[200]),
                  _fileTile(
                    icon: Icons.photo_library,
                    iconColor: Colors.green[700]!,
                    title: 'Choose from Gallery',
                    subtitle: 'Select existing photo',
                    onTap: _chooseFromGallery,
                  ),
                  Divider(height: 1, color: Colors.grey[200]),
                  _fileTile(
                    icon: Icons.insert_drive_file,
                    iconColor: Colors.orange[700]!,
                    title: 'Choose File',
                    subtitle: 'PDF, DOC, or other document',
                    onTap: _chooseFile,
                  ),
                ],
              ),
            ),

            // ── Selected file confirmation ─────────────────────────────
            if (_selectedFilePath != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green[400]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green[700], size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedFilePath!.split('/').last,
                        style: TextStyle(
                            color: Colors.green[900],
                            fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _selectedFilePath = null),
                      child: Icon(Icons.close,
                          size: 20, color: Colors.green[700]),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Upload button ─────────────────────────────────────────────
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed:
                    _selectedFilePath == null ? null : _uploadDocument,
                icon: const Icon(Icons.upload, size: 20),
                label: const Text('Upload Document',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange[700],
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[200],
                  disabledForegroundColor: Colors.grey[500],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Tips box ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(color: Colors.amber[600]!, width: 4),
                  top: BorderSide(color: Colors.amber[300]!),
                  right: BorderSide(color: Colors.amber[300]!),
                  bottom: BorderSide(color: Colors.amber[300]!),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: Colors.amber[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Tips for Document Photos',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.grey[900],
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

  Widget _fileTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: Colors.grey[900],
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      );

  Widget _tip(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ',
                style: TextStyle(
                    color: Colors.amber[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            Expanded(
              child: Text(
                text,
                style:
                    TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.4),
              ),
            ),
          ],
        ),
      );

  Future<void> _takePhoto() async {
    try {
      final photo = await ImagePicker()
          .pickImage(source: ImageSource.camera, maxWidth: 1920, imageQuality: 85);
      if (photo != null) {
        setState(() => _selectedFilePath = photo.path);
        _snack('Photo captured successfully', Colors.green);
      }
    } catch (e) {
      _snack('Error accessing camera: $e', Colors.red);
    }
  }

  Future<void> _chooseFromGallery() async {
    try {
      final image = await ImagePicker()
          .pickImage(source: ImageSource.gallery, maxWidth: 1920, imageQuality: 85);
      if (image != null) {
        setState(() => _selectedFilePath = image.path);
        _snack('Image selected successfully', Colors.green);
      }
    } catch (e) {
      _snack('Error accessing gallery: $e', Colors.red);
    }
  }

  Future<void> _chooseFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );
      if (result?.files.single.path != null) {
        setState(() => _selectedFilePath = result!.files.single.path);
        _snack('File selected successfully', Colors.green);
      }
    } catch (e) {
      _snack('Error selecting file: $e', Colors.red);
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
        _snack('Document uploaded and encrypted', Colors.green);
      }
    } catch (e) {
      _snack('Upload error: $e', Colors.red);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}
