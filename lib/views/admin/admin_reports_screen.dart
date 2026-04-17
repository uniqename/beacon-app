import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../services/local_database_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  _AdminReportsScreenState createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _selectedTimeframe = 'Last 30 Days';
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await LocalDatabaseService.getAdminDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error loading stats: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Admin Reports & Analytics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFFF0562D),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFF0562D)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimeframeSelector(),
                  SizedBox(height: 24),
                  _buildUsageMetrics(),
                  SizedBox(height: 24),
                  _buildServiceMetrics(),
                  SizedBox(height: 24),
                  _buildAnalyticsInfo(),
                ],
              ),
            ),
    );
  }

  Widget _buildTimeframeSelector() {
    List<String> timeframes = [
      'Last 7 Days',
      'Last 30 Days',
      'Last 90 Days',
      'Last Year'
    ];

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report Period',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF0562D),
            ),
          ),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedTimeframe,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: timeframes.map((timeframe) => DropdownMenuItem(
              value: timeframe,
              child: Text(timeframe),
            )).toList(),
            onChanged: (value) {
              setState(() {
                _selectedTimeframe = value!;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Timeframe filtering will be available in future updates'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUsageMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Usage Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF0562D),
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildMetricCard(
              '${_stats['totalUsers'] ?? 0}',
              'Total Users',
              Icons.people,
              Colors.blue
            )),
            SizedBox(width: 12),
            Expanded(child: _buildMetricCard(
              '${_stats['activeUsers'] ?? 0}',
              'Active Users',
              Icons.people_outline,
              Colors.green
            )),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricCard(
              '${_stats['totalInquiries'] ?? 0}',
              'Total Inquiries',
              Icons.support_agent,
              Colors.orange
            )),
            SizedBox(width: 12),
            Expanded(child: _buildMetricCard(
              '${_stats['pendingInquiries'] ?? 0}',
              'Pending Inquiries',
              Icons.pending_actions,
              Colors.red
            )),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricCard(
              '${_stats['totalCases'] ?? 0}',
              'Emergency Cases',
              Icons.folder,
              Colors.purple
            )),
            SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey[200]!,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(Icons.analytics, size: 40, color: Colors.grey[400]),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Analytics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF0562D),
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey[200]!,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'Service Usage Reports',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Detailed service analytics coming soon',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'Track:\n• Service usage by category\n• Popular services\n• Response times\n• User satisfaction ratings',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsInfo() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.indigo[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700]),
              SizedBox(width: 12),
              Text(
                'About These Reports',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'All data displayed is pulled directly from the live database. Statistics update in real-time as users interact with the app.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Use the refresh button to reload the latest data.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String number, String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              Spacer(),
              Text(
                number,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
