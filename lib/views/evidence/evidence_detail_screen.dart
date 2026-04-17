import 'package:flutter/material.dart';
import '../../models/evidence_log.dart';
import '../../services/evidence_service.dart';

class EvidenceDetailScreen extends StatefulWidget {
  final String evidenceId;
  final String userId;

  const EvidenceDetailScreen({
    super.key,
    required this.evidenceId,
    required this.userId,
  });

  @override
  State<EvidenceDetailScreen> createState() => _EvidenceDetailScreenState();
}

class _EvidenceDetailScreenState extends State<EvidenceDetailScreen> {
  final EvidenceService _service = EvidenceService();
  EvidenceLog? _evidence;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvidence();
  }

  Future<void> _loadEvidence() async {
    final evidence = await _service.getEvidence(widget.evidenceId);
    setState(() {
      _evidence = evidence;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Evidence Details')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_evidence == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Evidence Details')),
        body: Center(child: Text('Evidence not found')),
      );
    }

    final evidence = _evidence!;
    final severityColor = _getSeverityColor(evidence.severity);

    return Scaffold(
      appBar: AppBar(
        title: Text('Evidence Details'),
        backgroundColor: Colors.deepPurple[700],
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _exportEvidence(evidence),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
            ],
            onSelected: (value) {
              if (value == 'delete') _deleteEvidence();
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: severityColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          evidence.severity.toString().split('.').last.toUpperCase(),
                          style: TextStyle(
                            color: severityColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    evidence.title,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  _buildInfoRow(Icons.calendar_today, 'Incident Date', evidence.incidentDate.toString().substring(0, 16)),
                  _buildInfoRow(Icons.place, 'Location', evidence.location),
                  if (evidence.witnesses.isNotEmpty)
                    _buildInfoRow(Icons.people, 'Witnesses', evidence.witnesses.join(', ')),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Text(evidence.description, style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
          if (evidence.photoUrls.isNotEmpty) ...[
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Photos (${evidence.photoUrls.length})', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: evidence.photoUrls.length,
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.image, size: 48, color: Colors.grey[600]),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (evidence.audioUrls.isNotEmpty) ...[
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Audio Recordings (${evidence.audioUrls.length})', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    ...evidence.audioUrls.asMap().entries.map((entry) {
                      return ListTile(
                        leading: Icon(Icons.audiotrack, color: Colors.red[700]),
                        title: Text('Recording ${entry.key + 1}'),
                        trailing: Icon(Icons.play_arrow),
                        onTap: () {
                          // TODO: Play audio
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
          if (evidence.policeInvolved) ...[
            SizedBox(height: 16),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_police, color: Colors.blue[700]),
                        SizedBox(width: 12),
                        Text('Police Involvement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (evidence.policeReportNumber != null) ...[
                      SizedBox(height: 12),
                      Text('Report Number: ${evidence.policeReportNumber}', style: TextStyle(fontSize: 16)),
                    ],
                  ],
                ),
              ),
            ),
          ],
          if (evidence.medicalAttention) ...[
            SizedBox(height: 16),
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.medical_services, color: Colors.red[700]),
                        SizedBox(width: 12),
                        Text('Medical Attention', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (evidence.hospitalName != null) ...[
                      SizedBox(height: 12),
                      Text('Hospital: ${evidence.hospitalName}', style: TextStyle(fontSize: 16)),
                    ],
                  ],
                ),
              ),
            ),
          ],
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Metadata', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  SizedBox(height: 8),
                  Text('Created: ${evidence.createdAt.toString().substring(0, 16)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text('Updated: ${evidence.updatedAt.toString().substring(0, 16)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text('ID: ${evidence.id}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(Severity severity) {
    switch (severity) {
      case Severity.low:
        return Colors.green;
      case Severity.medium:
        return Colors.orange;
      case Severity.high:
        return Colors.red;
      case Severity.critical:
        return Colors.purple;
    }
  }

  Future<void> _exportEvidence(EvidenceLog evidence) async {
    final exported = await _service.exportToText(evidence);
    // TODO: Share or save the exported text
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Evidence exported')),
      );
    }
  }

  Future<void> _deleteEvidence() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Evidence'),
        content: Text('This action cannot be undone. Delete this evidence entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.deleteEvidence(widget.evidenceId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Evidence deleted')),
        );
      }
    }
  }
}
