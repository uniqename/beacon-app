import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../models/evidence_log.dart';
import '../../services/evidence_service.dart';
import 'create_evidence_screen.dart';
import 'evidence_detail_screen.dart';

class EvidenceTimelineScreen extends StatefulWidget {
  final String userId;

  const EvidenceTimelineScreen({super.key, required this.userId});

  @override
  State<EvidenceTimelineScreen> createState() => _EvidenceTimelineScreenState();
}

class _EvidenceTimelineScreenState extends State<EvidenceTimelineScreen> {
  final EvidenceService _service = EvidenceService();
  List<EvidenceLog> _evidence = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, photo, audio, medical, document

  @override
  void initState() {
    super.initState();
    _loadEvidence();
  }

  Future<void> _loadEvidence() async {
    setState(() => _isLoading = true);
    try {
      developer.log('🔍 [Evidence] Loading evidence for user: ${widget.userId}');
      final evidence = await _service.getAllEvidence(widget.userId);
      developer.log('✅ [Evidence] Loaded ${evidence.length} evidence entries');
      setState(() {
        _evidence = evidence;
        _isLoading = false;
      });
    } catch (e, stack) {
      developer.log('❌ [Evidence] ERROR loading evidence: $e');
      developer.log('   Stack: $stack');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading evidence: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  List<EvidenceLog> get _filteredEvidence {
    if (_filter == 'all') return _evidence;
    return _evidence.where((e) {
      switch (_filter) {
        case 'photo':
          return e.photoUrls.isNotEmpty;
        case 'audio':
          return e.audioUrls.isNotEmpty;
        case 'medical':
          return e.medicalAttention;
        case 'document':
          return e.documentUrls.isNotEmpty;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Evidence Timeline'),
        backgroundColor: Colors.deepPurple[700],
        actions: [
          PopupMenuButton(
            icon: Icon(Icons.filter_list),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'all', child: Text('All Evidence')),
              PopupMenuItem(value: 'photo', child: Text('Photos')),
              PopupMenuItem(value: 'audio', child: Text('Audio')),
              PopupMenuItem(value: 'medical', child: Text('Medical')),
              PopupMenuItem(value: 'document', child: Text('Documents')),
            ],
            onSelected: (value) => setState(() => _filter = value),
          ),
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: _exportAllEvidence,
            tooltip: 'Export All',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.deepPurple[50],
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.deepPurple[700]),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Document incidents with photos, audio, and detailed notes. All evidence is timestamped and court-admissible.',
                    style: TextStyle(color: Colors.deepPurple[900]),
                  ),
                ),
              ],
            ),
          ),
          if (_filter != 'all') ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[200],
              child: Row(
                children: [
                  Text('Filter: ${_filter.toUpperCase()}', style: TextStyle(fontWeight: FontWeight.bold)),
                  Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _filter = 'all'),
                    child: Text('Clear'),
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredEvidence.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.description, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              _filter == 'all' ? 'No evidence documented yet' : 'No $_filter evidence found',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap + to add your first evidence entry',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _filteredEvidence.length,
                        itemBuilder: (context, index) => _buildEvidenceCard(_filteredEvidence[index]),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateEvidenceScreen(userId: widget.userId),
            ),
          );

          if (result == true) {
            _loadEvidence();
          }
        },
        icon: Icon(Icons.add),
        label: Text('Add Evidence'),
        backgroundColor: Colors.deepPurple[700],
      ),
    );
  }

  Widget _buildEvidenceCard(EvidenceLog evidence) {
    final severityColor = _getSeverityColor(evidence.severity);
    final timeAgo = _getTimeAgo(evidence.incidentDate);

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EvidenceDetailScreen(
                evidenceId: evidence.id,
                userId: widget.userId,
              ),
            ),
          );
          // Reload if evidence was deleted
          if (result == true) {
            _loadEvidence();
          }
        },
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      evidence.severity.toString().split('.').last.toUpperCase(),
                      style: TextStyle(
                        color: severityColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      evidence.title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                evidence.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700]),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(timeAgo, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  if (evidence.photoUrls.isNotEmpty) ...[
                    SizedBox(width: 12),
                    Icon(Icons.photo, size: 14, color: Colors.blue),
                    SizedBox(width: 4),
                    Text('${evidence.photoUrls.length}', style: TextStyle(fontSize: 12)),
                  ],
                  if (evidence.audioUrls.isNotEmpty) ...[
                    SizedBox(width: 12),
                    Icon(Icons.mic, size: 14, color: Colors.red),
                    SizedBox(width: 4),
                    Text('${evidence.audioUrls.length}', style: TextStyle(fontSize: 12)),
                  ],
                  if (evidence.policeInvolved) ...[
                    SizedBox(width: 12),
                    Icon(Icons.local_police, size: 14, color: Colors.blue[700]),
                  ],
                  if (evidence.medicalAttention) ...[
                    SizedBox(width: 12),
                    Icon(Icons.medical_services, size: 14, color: Colors.red[700]),
                  ],
                ],
              ),
            ],
          ),
        ),
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

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _exportAllEvidence() async {
    if (_evidence.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No evidence to export')),
      );
      return;
    }

    // TODO: Implement full export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exporting ${_evidence.length} evidence entries...')),
    );
  }
}
