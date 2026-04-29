import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../models/evidence_log.dart';
import '../../services/document_vault_service.dart';

class DocumentVaultScreen extends StatefulWidget {
  final String userId;

  const DocumentVaultScreen({super.key, required this.userId});

  @override
  State<DocumentVaultScreen> createState() => _DocumentVaultScreenState();
}

class _DocumentVaultScreenState extends State<DocumentVaultScreen> {
  final DocumentVaultService _service = DocumentVaultService();
  List<SecureDocument> _documents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      developer.log('🔍 [Documents] Loading documents for user: ${widget.userId}');
      final docs = await _service.getAllDocuments(widget.userId);
      developer.log('✅ [Documents] Loaded ${docs.length} documents');
      setState(() {
        _documents = docs;
        _isLoading = false;
      });
    } catch (e, stack) {
      developer.log('❌ [Documents] ERROR loading documents: $e');
      developer.log('   Stack: $stack');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading documents: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final missingDocs = _service.getMissingDocuments(_documents);

    return Scaffold(
      appBar: AppBar(
        title: Text('Document Vault'),
        backgroundColor: Colors.deepOrange[700],
        actions: [
          IconButton(
            icon: Icon(Icons.checklist),
            onPressed: () => Navigator.pushNamed(context, '/document_checklist'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.deepOrange[50],
            child: Row(
              children: [
                Icon(Icons.lock, color: Colors.deepOrange[700], size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'All documents are encrypted and stored securely',
                    style: TextStyle(color: Colors.deepOrange[900], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          if (missingDocs.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.all(12),
              color: Colors.amber[50],
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.amber[700], size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${missingDocs.length} important documents missing',
                      style: TextStyle(color: Colors.amber[900], fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/document_checklist'),
                    child: Text('View'),
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.folder, color: Colors.deepOrange[700], size: 20),
                SizedBox(width: 8),
                Text('My Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[850])),
                Spacer(),
                Text('${_documents.length}', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _documents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No documents uploaded', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                            SizedBox(height: 8),
                            Text('Tap + to upload your first document', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _documents.length,
                        itemBuilder: (context, index) {
                          final doc = _documents[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getCategoryColor(doc.category).withValues(alpha: 0.2),
                                child: Icon(
                                  _getCategoryIcon(doc.category),
                                  color: _getCategoryColor(doc.category),
                                ),
                              ),
                              title: Text(doc.title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[850])),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text(doc.category),
                                  SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                                      SizedBox(width: 4),
                                      Text(
                                        doc.uploadedAt.toString().substring(0, 10),
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                      if (doc.isEncrypted) ...[
                                        SizedBox(width: 8),
                                        Icon(Icons.lock, size: 12, color: Colors.green[700]),
                                        SizedBox(width: 2),
                                        Text(
                                          'Encrypted',
                                          style: TextStyle(fontSize: 10, color: Colors.green[700]),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(value: 'view', child: Text('View')),
                                  PopupMenuItem(value: 'share', child: Text('Share')),
                                  PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                                onSelected: (value) {
                                  if (value == 'delete') _deleteDocument(doc);
                                },
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/upload_document').then((_) => _loadDocuments());
        },
        icon: Icon(Icons.upload_file),
        label: Text('Upload'),
        backgroundColor: Colors.deepOrange[700],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'ID Documents': Colors.blue,
      'Medical Records': Colors.red,
      'Financial': Colors.green,
      'Legal': Colors.purple,
      'Educational': Colors.orange,
      'Other': Colors.grey,
    };
    return colors[category] ?? Colors.grey;
  }

  IconData _getCategoryIcon(String category) {
    final icons = {
      'ID Documents': Icons.badge,
      'Medical Records': Icons.medical_services,
      'Financial': Icons.account_balance,
      'Legal': Icons.gavel,
      'Educational': Icons.school,
      'Other': Icons.insert_drive_file,
    };
    return icons[category] ?? Icons.insert_drive_file;
  }

  void _deleteDocument(SecureDocument doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Document'),
        content: Text('Permanently delete ${doc.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _service.deleteDocument(doc.id);
              Navigator.pop(context);
              _loadDocuments();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Document deleted')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}
