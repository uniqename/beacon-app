import 'package:flutter/material.dart';
import '../../models/evidence_log.dart';
import '../../services/evidence_service.dart';

class MessageEvidenceScreen extends StatefulWidget {
  final String userId;

  const MessageEvidenceScreen({super.key, required this.userId});

  @override
  State<MessageEvidenceScreen> createState() => _MessageEvidenceScreenState();
}

class _MessageEvidenceScreenState extends State<MessageEvidenceScreen> {
  final EvidenceService _service = EvidenceService();
  List<EvidenceLog> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      final allEvidence = await _service.getAllEvidence(widget.userId);
      // Filter for message evidence (using location field to store platform)
      setState(() {
        _messages = allEvidence.where((e) =>
          e.location.contains('SMS') || e.location.contains('Email') ||
          e.location.contains('WhatsApp') || e.location.contains('Message Platform:')
        ).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Message Evidence'),
          backgroundColor: Colors.indigo[700],
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Message Evidence'),
        backgroundColor: Colors.indigo[700],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.indigo[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.message, color: Colors.indigo[700]),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Document Threatening Messages',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo[900]),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Save threatening or harassing messages from texts, social media, or emails. Include timestamps and sender info.',
                  style: TextStyle(color: Colors.indigo[800]),
                ),
              ],
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No messages documented', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                        SizedBox(height: 8),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Document threatening texts, emails, or social media messages',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final platform = message.location.replaceAll('Message Platform: ', '');
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getSeverityColor(message.severity),
                            child: Icon(_getPlatformIcon(platform), color: Colors.white, size: 20),
                          ),
                          title: Text(message.title, style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text(
                                message.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Text(
                                    message.incidentDate.toString().substring(0, 16),
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                  SizedBox(width: 12),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getSeverityColor(message.severity).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      message.severity.toString().split('.').last.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _getSeverityColor(message.severity),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteMessage(message.id),
                          ),
                          isThreeLine: true,
                          onTap: () => _showMessageDetails(message, platform),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMessageDialog,
        icon: Icon(Icons.add),
        label: Text('Add Message'),
        backgroundColor: Colors.indigo[700],
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'sms':
        return Icons.sms;
      case 'whatsapp':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'facebook':
      case 'social':
      case 'instagram':
      case 'twitter':
        return Icons.public;
      default:
        return Icons.message;
    }
  }

  Color _getSeverityColor(Severity severity) {
    switch (severity) {
      case Severity.low:
        return Colors.orange;
      case Severity.medium:
        return Colors.deepOrange;
      case Severity.high:
      case Severity.critical:
        return Colors.red;
    }
  }

  void _showAddMessageDialog() {
    final senderController = TextEditingController();
    final contentController = TextEditingController();
    final contextController = TextEditingController();
    DateTime selectedTimestamp = DateTime.now();
    String selectedPlatform = 'SMS';
    Severity selectedSeverity = Severity.medium;

    final platforms = ['SMS', 'WhatsApp', 'Email', 'Facebook', 'Instagram', 'Twitter', 'Other'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Document Message'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: senderController,
                  decoration: InputDecoration(
                    labelText: 'Sender/From *',
                    border: OutlineInputBorder(),
                    hintText: 'Name or phone/email',
                  ),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedPlatform,
                  decoration: InputDecoration(
                    labelText: 'Platform',
                    border: OutlineInputBorder(),
                  ),
                  items: platforms.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (value) => setDialogState(() => selectedPlatform = value!),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: 'Message Content *',
                    border: OutlineInputBorder(),
                    hintText: 'Copy the exact message',
                  ),
                  maxLines: 5,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: contextController,
                  decoration: InputDecoration(
                    labelText: 'Context/Notes',
                    border: OutlineInputBorder(),
                    hintText: 'Any relevant context',
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<Severity>(
                  initialValue: selectedSeverity,
                  decoration: InputDecoration(
                    labelText: 'Threat Level',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: Severity.low, child: Text('Low')),
                    DropdownMenuItem(value: Severity.medium, child: Text('Medium')),
                    DropdownMenuItem(value: Severity.high, child: Text('High')),
                    DropdownMenuItem(value: Severity.critical, child: Text('Critical')),
                  ],
                  onChanged: (value) => setDialogState(() => selectedSeverity = value!),
                ),
                SizedBox(height: 12),
                ListTile(
                  title: Text('Message Date & Time'),
                  subtitle: Text(selectedTimestamp.toString().substring(0, 16)),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedTimestamp,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedTimestamp),
                      );
                      if (time != null) {
                        setDialogState(() {
                          selectedTimestamp = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (senderController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sender and content are required')),
                  );
                  return;
                }

                Navigator.pop(context);

                try {
                  await _service.createEvidence(
                    userId: widget.userId,
                    title: 'Message from ${senderController.text.trim()}',
                    description: '${contentController.text.trim()}\n\n${contextController.text.trim().isNotEmpty ? "Context: ${contextController.text.trim()}" : ""}',
                    incidentDate: selectedTimestamp,
                    severity: selectedSeverity,
                    location: 'Message Platform: $selectedPlatform',
                    photoUrls: [],
                    audioUrls: [],
                    witnesses: [],
                    policeInvolved: false,
                    medicalAttention: false,
                  );

                  await _loadMessages();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Message documented'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding message: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageDetails(EvidenceLog message, String platform) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Platform', platform),
              _buildDetailRow('Timestamp', message.incidentDate.toString().substring(0, 16)),
              _buildDetailRow('Threat Level', message.severity.toString().split('.').last.toUpperCase()),
              _buildDetailRow('Message', message.description),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  void _deleteMessage(String evidenceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Message'),
        content: Text('Delete this message evidence?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await _service.deleteEvidence(evidenceId);
                await _loadMessages();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Message deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting: $e'), backgroundColor: Colors.red),
                  );
                }
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
