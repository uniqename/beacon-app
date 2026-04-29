// Export Evidence Screen for Beacon of New Beginnings
// Export evidence log to text/PDF format

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:share_plus/share_plus.dart'; // TODO: Add share_plus to pubspec.yaml
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../models/evidence_log.dart';
import '../../services/evidence_service.dart';
import '../../constants/app_constants.dart';

class ExportEvidenceScreen extends StatefulWidget {
  final EvidenceLog log;
  final String userId;

  const ExportEvidenceScreen({
    super.key,
    required this.log,
    required this.userId,
  });

  @override
  State<ExportEvidenceScreen> createState() => _ExportEvidenceScreenState();
}

class _ExportEvidenceScreenState extends State<ExportEvidenceScreen> {
  final EvidenceService _evidenceService = EvidenceService();
  final _passwordController = TextEditingController();

  bool _passwordProtect = false;
  bool _isExporting = false;
  String? _error;
  String? _exportedText;

  @override
  void initState() {
    super.initState();
    _generatePreview();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _generatePreview() async {
    final text = await _evidenceService.exportToText(widget.log);
    setState(() {
      _exportedText = text;
    });
  }

  Future<void> _exportAsText() async {
    setState(() {
      _isExporting = true;
      _error = null;
    });

    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'evidence_log_${widget.log.id}_${DateTime.now().millisecondsSinceEpoch}.txt';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(_exportedText!);

      if (!mounted) return;

      setState(() {
        _isExporting = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Evidence exported to $fileName'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Share',
            textColor: Colors.white,
            onPressed: () => _shareFile(filePath),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isExporting = false;
      });
    }
  }

  Future<void> _shareFile(String filePath) async {
    // TODO: Implement sharing when share_plus is added
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share feature coming soon. File saved to: Documents/Beacon'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _exportedText!));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Evidence text copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _printDocument() async {
    // Note: Printing functionality would require additional packages
    // like printing or pdf packages. For now, show a placeholder.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Print functionality will be available in future updates'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Export Evidence'),
        backgroundColor: const Color(AppConstants.primaryColorValue),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Notice
            _buildInfoNotice(),
            const SizedBox(height: 24),

            // Preview Section
            _buildPreviewSection(),
            const SizedBox(height: 24),

            // Password Protection Section
            _buildPasswordSection(),
            const SizedBox(height: 24),

            // Export Options
            _buildExportOptions(),
            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(),

            // Error Message
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[300]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Legal Documentation Export',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This export is formatted for legal proceedings and includes all evidence details with timestamps.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[900],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.preview, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Export Preview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: _copyToClipboard,
                  tooltip: 'Copy to clipboard',
                ),
              ],
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                _exportedText ?? 'Generating preview...',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Password Protection',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Switch(
                value: _passwordProtect,
                onChanged: (value) {
                  setState(() {
                    _passwordProtect = value;
                  });
                },
                activeThumbColor: const Color(AppConstants.primaryColorValue),
              ),
            ],
          ),
          if (_passwordProtect) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Export Password',
                hintText: 'Enter a password for this export',
                prefixIcon: const Icon(Icons.vpn_key),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(AppConstants.primaryColorValue),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Note: Password protection is currently a placeholder. Full encryption will be available in future updates.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExportOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.settings, size: 20),
              SizedBox(width: 8),
              Text(
                'Export Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Severity', widget.log.severity.name.toUpperCase()),
          _buildInfoRow('Total Photos', widget.log.photoUrls.length.toString()),
          _buildInfoRow('Total Audio', widget.log.audioUrls.length.toString()),
          _buildInfoRow('Total Documents', widget.log.documentUrls.length.toString()),
          _buildInfoRow('Witnesses', widget.log.witnesses.length.toString()),
          _buildInfoRow('Police Involved', widget.log.policeInvolved ? 'Yes' : 'No'),
          const Divider(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.amber[800], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Media files (photos, audio) are not included in text export. They remain securely stored in the app.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Export as Text File
        ElevatedButton.icon(
          onPressed: _isExporting ? null : _exportAsText,
          icon: _isExporting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.file_download),
          label: Text(_isExporting ? 'Exporting...' : 'Export as Text File'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(AppConstants.primaryColorValue),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Print (Placeholder)
        OutlinedButton.icon(
          onPressed: _printDocument,
          icon: const Icon(Icons.print),
          label: const Text('Print Document'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(
              color: Color(AppConstants.primaryColorValue),
            ),
            foregroundColor: const Color(AppConstants.primaryColorValue),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Copy to Clipboard
        OutlinedButton.icon(
          onPressed: _copyToClipboard,
          icon: const Icon(Icons.copy),
          label: const Text('Copy to Clipboard'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: BorderSide(color: Colors.grey[400]!),
            foregroundColor: Colors.grey[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
