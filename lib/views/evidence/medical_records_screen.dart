import 'package:flutter/material.dart';
import '../../models/evidence_log.dart';
import '../../services/evidence_service.dart';

class MedicalRecordsScreen extends StatefulWidget {
  final String userId;

  const MedicalRecordsScreen({super.key, required this.userId});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  final EvidenceService _service = EvidenceService();
  List<EvidenceLog> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);

    try {
      final allEvidence = await _service.getAllEvidence(widget.userId);
      // Filter for medical records (evidence with medicalAttention = true)
      setState(() {
        _records = allEvidence.where((e) => e.medicalAttention).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading medical records: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Medical Records'),
          backgroundColor: Colors.teal[700],
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Medical Records'),
        backgroundColor: Colors.teal[700],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.teal[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.medical_services, color: Colors.teal[700]),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Medical Evidence Documentation',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[900]),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Document injuries, medical visits, prescriptions, and treatment. Medical records are critical evidence.',
                  style: TextStyle(color: Colors.teal[800]),
                ),
              ],
            ),
          ),
          Expanded(
            child: _records.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medical_information, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No medical records yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                        SizedBox(height: 8),
                        Text('Add medical visits, injuries, or prescriptions', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final record = _records[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal[100],
                            child: Icon(Icons.medical_services, color: Colors.teal[700]),
                          ),
                          title: Text(record.title, style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text(record.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                              SizedBox(height: 4),
                              Text(
                                record.incidentDate.toString().substring(0, 10),
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              if (record.hospitalName != null) ...[
                                SizedBox(height: 2),
                                Text(
                                  'Hospital: ${record.hospitalName}',
                                  style: TextStyle(fontSize: 12, color: Colors.teal[700]),
                                ),
                              ],
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteRecord(record.id),
                          ),
                          isThreeLine: true,
                          onTap: () => _showRecordDetails(record),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRecordDialog,
        icon: Icon(Icons.add),
        label: Text('Add Medical Record'),
        backgroundColor: Colors.teal[700],
      ),
    );
  }

  void _showAddRecordDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final facilityController = TextEditingController();
    final doctorController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedType = 'Injury';

    final types = ['Injury', 'Visit', 'Prescription', 'Report', 'Other'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Medical Record'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (value) => setDialogState(() => selectedType = value!),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Bruised arm',
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description *',
                    border: OutlineInputBorder(),
                    hintText: 'Describe the injury or treatment',
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 12),
                TextField(
                  controller: facilityController,
                  decoration: InputDecoration(
                    labelText: 'Facility/Hospital',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: doctorController,
                  decoration: InputDecoration(
                    labelText: 'Doctor/Provider',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                ListTile(
                  title: Text('Date'),
                  subtitle: Text(selectedDate.toString().substring(0, 10)),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
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
                if (titleController.text.trim().isEmpty || descriptionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Title and description are required')),
                  );
                  return;
                }

                Navigator.pop(context);

                try {
                  await _service.createEvidence(
                    userId: widget.userId,
                    title: titleController.text.trim(),
                    description: '$selectedType: ${descriptionController.text.trim()}\n\nFacility: ${facilityController.text.trim()}\nDoctor: ${doctorController.text.trim()}',
                    incidentDate: selectedDate,
                    severity: Severity.medium,
                    location: facilityController.text.trim(),
                    photoUrls: [],
                    audioUrls: [],
                    witnesses: [],
                    policeInvolved: false,
                    medicalAttention: true,
                    hospitalName: facilityController.text.trim().isEmpty ? null : facilityController.text.trim(),
                  );

                  await _loadRecords();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Medical record added'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding record: $e'), backgroundColor: Colors.red),
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

  void _showRecordDetails(EvidenceLog record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(record.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Date', record.incidentDate.toString().substring(0, 10)),
              _buildDetailRow('Description', record.description),
              if (record.location.isNotEmpty) _buildDetailRow('Location', record.location),
              if (record.hospitalName != null) _buildDetailRow('Hospital', record.hospitalName!),
              if (record.witnesses.isNotEmpty) _buildDetailRow('Witnesses', record.witnesses.join(', ')),
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

  void _deleteRecord(String evidenceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Record'),
        content: Text('Delete this medical record?'),
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
                await _loadRecords();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Record deleted')),
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
