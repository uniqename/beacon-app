import 'package:flutter/material.dart';
import '../../models/evidence_log.dart';
// import '../../services/document_vault_service.dart'; // TODO: Service not yet implemented

class DocumentChecklistScreen extends StatefulWidget {
  final String userId;

  const DocumentChecklistScreen({super.key, required this.userId});

  @override
  State<DocumentChecklistScreen> createState() => _DocumentChecklistScreenState();
}

class _DocumentChecklistScreenState extends State<DocumentChecklistScreen> {
  // final DocumentVaultService _service = DocumentVaultService(); // TODO: Service not yet implemented
  List<SecureDocument> _userDocuments = [];
  bool _isLoading = true;

  final List<Map<String, String>> _importantDocuments = [
    {'name': 'National ID / Passport', 'category': 'ID Documents', 'why': 'Essential for identification and legal processes'},
    {'name': 'Birth Certificate', 'category': 'ID Documents', 'why': 'Proof of identity and citizenship'},
    {'name': 'Marriage Certificate', 'category': 'Legal', 'why': 'Legal proof of marriage status'},
    {'name': 'Children\'s Birth Certificates', 'category': 'ID Documents', 'why': 'Essential for custody and identification'},
    {'name': 'Medical Records', 'category': 'Medical Records', 'why': 'Document injuries and medical history'},
    {'name': 'Prescriptions', 'category': 'Medical Records', 'why': 'Ensure continued access to medications'},
    {'name': 'Bank Statements', 'category': 'Financial', 'why': 'Proof of financial situation'},
    {'name': 'Property Deeds', 'category': 'Legal', 'why': 'Proof of ownership'},
    {'name': 'Vehicle Registration', 'category': 'Legal', 'why': 'Proof of vehicle ownership'},
    {'name': 'Insurance Policies', 'category': 'Financial', 'why': 'Access to insurance benefits'},
    {'name': 'Educational Certificates', 'category': 'Educational', 'why': 'For employment and future opportunities'},
    {'name': 'Protection Order (if any)', 'category': 'Legal', 'why': 'Legal protection documentation'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    // TODO: Implement document vault service
    final docs = <SecureDocument>[]; // await _service.getAllDocuments(widget.userId);
    setState(() {
      _userDocuments = docs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _importantDocuments.where((doc) {
      return _userDocuments.any((userDoc) =>
          userDoc.title.toLowerCase().contains(doc['name']!.toLowerCase()) ||
          userDoc.category == doc['category']);
    }).length;

    final completionPercentage = (_importantDocuments.isNotEmpty
        ? (completedCount / _importantDocuments.length * 100)
        : 0).round();

    return Scaffold(
      appBar: AppBar(
        title: Text('Document Checklist'),
        backgroundColor: Colors.deepOrange[700],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepOrange[600]!, Colors.deepOrange[800]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Checklist Progress',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$completionPercentage%',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                LinearProgressIndicator(
                  value: completedCount / _importantDocuments.length,
                  backgroundColor: Colors.white30,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                ),
                SizedBox(height: 8),
                Text(
                  '$completedCount of ${_importantDocuments.length} documents',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.amber[50],
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Keep copies of these important documents in your secure vault for emergency situations.',
                    style: TextStyle(fontSize: 13, color: Colors.amber[900]),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _importantDocuments.length,
                    itemBuilder: (context, index) {
                      final doc = _importantDocuments[index];
                      final isCompleted = _userDocuments.any((userDoc) =>
                          userDoc.title.toLowerCase().contains(doc['name']!.toLowerCase()) ||
                          userDoc.category == doc['category']);

                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          leading: Checkbox(
                            value: isCompleted,
                            onChanged: null,
                            activeColor: Colors.green,
                          ),
                          title: Text(
                            doc['name']!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                              color: isCompleted ? Colors.grey : Colors.black,
                            ),
                          ),
                          subtitle: Text(doc['category']!),
                          children: [
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Why it\'s important:',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  SizedBox(height: 4),
                                  Text(doc['why']!, style: TextStyle(fontSize: 13)),
                                  SizedBox(height: 12),
                                  if (!isCompleted)
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/upload_document').then((_) => _loadDocuments());
                                      },
                                      icon: Icon(Icons.upload_file, size: 18),
                                      label: Text('Upload This Document'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepOrange[700],
                                      ),
                                    )
                                  else
                                    Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                                        SizedBox(width: 8),
                                        Text('Document uploaded', style: TextStyle(color: Colors.green)),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
