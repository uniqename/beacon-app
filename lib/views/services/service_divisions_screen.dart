import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/beacon_division.dart';
import '../../services/smart_ai_service.dart';
import 'division_detail_screen.dart';

class ServiceDivisionsScreen extends StatefulWidget {
  final String? initialFilter;
  
  const ServiceDivisionsScreen({Key? key, this.initialFilter}) : super(key: key);
  
  @override
  _ServiceDivisionsScreenState createState() => _ServiceDivisionsScreenState();
}

class _ServiceDivisionsScreenState extends State<ServiceDivisionsScreen> {
  List<BeaconDivision> _divisions = [];
  bool _isLoading = true;
  String _selectedHelpType = 'emergency';
  String _selectedUrgency = 'normal';

  @override
  void initState() {
    super.initState();
    // Set initial filter if provided
    if (widget.initialFilter != null) {
      _selectedHelpType = widget.initialFilter!;
    }
    _loadDivisions();
  }

  void _loadDivisions() {
    final divisions = SmartAIService.smartResourceRouting(
      helpType: _selectedHelpType,
      urgency: _selectedUrgency,
      location: 'Accra',
    );
    setState(() {
      _divisions = divisions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Beacon Services',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF2E8B57),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.tune, color: Colors.white),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF2E8B57)))
          : Column(
              children: [
                _buildHelpTypeSelector(),
                _buildAIInsights(),
                Expanded(child: _buildDivisionsList()),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/emergency');
        },
        backgroundColor: Colors.red[600],
        icon: Icon(Icons.emergency, color: Colors.white),
        label: Text(
          'Emergency',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHelpTypeSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2E8B57),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What type of help do you need?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Container(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildHelpTypeChip('emergency', '🚨', 'Emergency'),
                _buildHelpTypeChip('shelter', '🏠', 'Shelter'),
                _buildHelpTypeChip('legal', '⚖️', 'Legal'),
                _buildHelpTypeChip('counseling', '💬', 'Counseling'),
                _buildHelpTypeChip('healthcare', '🏥', 'Healthcare'),
                _buildHelpTypeChip('job-training', '💼', 'Job Training'),
                _buildHelpTypeChip('education', '🎓', 'Education'),
                _buildHelpTypeChip('financial', '💰', 'Financial'),
                _buildHelpTypeChip('food', '🍽️', 'Basic Needs'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpTypeChip(String type, String emoji, String label) {
    bool isSelected = _selectedHelpType == type;
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedHelpType = type;
          });
          _loadDivisions();
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Color(0xFF2E8B57) : Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emoji,
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Color(0xFF2E8B57) : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIInsights() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.indigo[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.psychology, color: Colors.blue[700], size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Resource Matching',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Services are matched to your specific needs and location',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivisionsList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: _divisions.length,
      itemBuilder: (context, index) {
        BeaconDivision division = _divisions[index];
        return _buildDivisionCard(division, index);
      },
    );
  }

  Widget _buildDivisionCard(BeaconDivision division, int index) {
    Color cardColor = Color(int.parse(division.color.replaceFirst('#', '0xFF')));
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        shadowColor: cardColor.withOpacity(0.3),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DivisionDetailScreen(division: division),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cardColor.withOpacity(0.1),
                  cardColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        division.icon,
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (index == 0)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'AI Recommended',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ),
                              if (index == 0) SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  division.shortName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: cardColor.withOpacity(0.9),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            division.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatusChip(
                      division.isAvailable ? 'Available' : 'Limited',
                      division.isAvailable ? Colors.green : Colors.orange,
                      division.isAvailable ? Icons.check_circle : Icons.access_time,
                    ),
                    SizedBox(width: 12),
                    _buildStartupStatusChip(division),
                    SizedBox(width: 12),
                    _buildStartupJobsChip(),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DivisionDetailScreen(division: division),
                            ),
                          );
                        },
                        icon: Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                        label: Text(
                          'View Services',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        _showQuickContactDialog(division);
                      },
                      child: Icon(Icons.phone, color: cardColor, size: 16),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: cardColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartupStatusChip(BeaconDivision division) {
    String status;
    Color color;
    IconData icon;
    
    if (division.services.any((service) => service.contains('Available'))) {
      status = 'Available';
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (division.services.any((service) => service.contains('Coming Soon'))) {
      status = 'Coming Soon';
      color = Colors.blue;
      icon = Icons.schedule;
    } else if (division.services.any((service) => service.contains('Planning'))) {
      status = 'Planning';
      color = Colors.orange;
      icon = Icons.construction;
    } else {
      status = 'In Development';
      color = Colors.purple;
      icon = Icons.build;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartupJobsChip() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.work_outline, color: Colors.purple, size: 12),
          SizedBox(width: 4),
          Text(
            'Hiring Soon',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Services'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedUrgency,
              decoration: InputDecoration(
                labelText: 'Urgency Level',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'normal', child: Text('Normal')),
                DropdownMenuItem(value: 'high', child: Text('High')),
                DropdownMenuItem(value: 'emergency', child: Text('Emergency')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedUrgency = value!;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadDivisions();
            },
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showQuickContactDialog(BeaconDivision division) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact ${division.shortName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.email, color: Color(0xFF2E8B57)),
              title: Text('Email'),
              subtitle: Text(division.contactEmail),
              onTap: () {
                Navigator.pop(context);
                _sendEmail(division);
              },
            ),
            ListTile(
              leading: Icon(Icons.phone, color: Color(0xFF2E8B57)),
              title: Text('Phone'),
              subtitle: Text(division.contactPhone),
              onTap: () {
                Navigator.pop(context);
                _callDivision(division);
              },
            ),
          ],
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

  void _sendEmail(BeaconDivision division) async {
    final String subject = Uri.encodeComponent('General Inquiry - ${division.name}');
    final String body = Uri.encodeComponent(
      'Hello ${division.name} team,\n\n'
      'I am interested in learning more about your services. '
      'Could you please provide information about:\n\n'
      '• Available services\n'
      '• How to access support\n'
      '• Eligibility requirements\n'
      '• Current availability\n\n'
      'Thank you for your time and assistance.\n\n'
      'Best regards'
    );
    
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: division.contactEmail,
      query: 'subject=$subject&body=$body',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        _showEmailFallback(division);
      }
    } catch (e) {
      _showEmailFallback(division);
    }
  }

  void _callDivision(BeaconDivision division) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: division.contactPhone);
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showPhoneFallback(division);
      }
    } catch (e) {
      _showPhoneFallback(division);
    }
  }

  void _showEmailFallback(BeaconDivision division) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.email, color: Colors.blue[600]),
            SizedBox(width: 12),
            Text('Contact Information'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please contact ${division.name} directly:'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  SelectableText(
                    division.contactEmail,
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                ],
              ),
            ),
          ],
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

  void _showPhoneFallback(BeaconDivision division) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.phone, color: Colors.green[600]),
            SizedBox(width: 12),
            Text('Call ${division.shortName}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please call directly:'),
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
                  Icon(Icons.phone, color: Colors.green[600]),
                  SizedBox(width: 12),
                  Expanded(
                    child: SelectableText(
                      division.contactPhone,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
}