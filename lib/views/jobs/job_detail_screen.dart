import 'package:flutter/material.dart';
import '../../models/beacon_division.dart';
import '../applications/application_form_screen.dart';

class JobDetailScreen extends StatelessWidget {
  final JobOpportunity job;

  const JobDetailScreen({Key? key, required this.job}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Job Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF2E8B57),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.white),
            onPressed: () {
              // Handle share
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildJobHeader(),
            SizedBox(height: 20),
            _buildJobDetails(),
            SizedBox(height: 20),
            _buildRequirements(),
            SizedBox(height: 20),
            _buildApplicationInfo(),
            SizedBox(height: 100), // Space for floating button
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _navigateToApplication(context);
        },
        backgroundColor: Color(0xFF2E8B57),
        icon: Icon(Icons.send, color: Colors.white),
        label: Text(
          'Apply Now',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildJobHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  job.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E8B57),
                  ),
                ),
              ),
              if (job.isUrgent)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'URGENT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            job.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(job.type.toUpperCase(), Icons.schedule, _getTypeColor()),
              _buildInfoChip(job.location, Icons.location_on, Colors.blue),
              if (job.isRemote)
                _buildInfoChip('REMOTE AVAILABLE', Icons.home, Colors.green),
              _buildInfoChip(
                'Posted ${_getTimeAgo(job.postedDate)}',
                Icons.calendar_today,
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobDetails() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Job Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E8B57),
            ),
          ),
          SizedBox(height: 16),
          _buildDetailRow('Position Type', job.type),
          _buildDetailRow('Location', job.location),
          _buildDetailRow('Remote Work', job.isRemote ? 'Available' : 'On-site only'),
          _buildDetailRow('Application Email', job.applicationEmail),
          _buildDetailRow('Posted Date', _formatDate(job.postedDate)),
          if (job.isUrgent)
            _buildDetailRow('Priority', 'URGENT HIRING', isHighlighted: true),
        ],
      ),
    );
  }

  Widget _buildRequirements() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requirements',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E8B57),
            ),
          ),
          SizedBox(height: 16),
          ...job.requirements.map((requirement) => Container(
            margin: EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Color(0xFF2E8B57),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    requirement,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildApplicationInfo() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.indigo[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700]),
              SizedBox(width: 8),
              Text(
                'How to Apply',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            '1. Review all requirements carefully\n'
            '2. Prepare your resume and cover letter\n'
            '3. Click "Apply Now" to send your application\n'
            '4. You will receive a confirmation email within 24 hours',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blue[700],
              height: 1.6,
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.yellow[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.yellow[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.orange[700]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tip: Applications are reviewed weekly. Apply early for best consideration!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w500,
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

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: isHighlighted ? Colors.red[600] : Colors.grey[800],
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor() {
    switch (job.type.toLowerCase()) {
      case 'volunteer':
        return Colors.green;
      case 'full-time':
        return Colors.blue;
      case 'part-time':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return 'Recently';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }


  void _navigateToApplication(BuildContext context) {
    // Create a dummy division for the job application
    BeaconDivision dummyDivision = BeaconDivision(
      id: 'job_division',
      name: 'Job Application',
      shortName: 'Jobs',
      description: 'Job applications for ${job.title}',
      icon: 'work',
      color: '#2E8B57',
      services: [],
      resources: [],
      isAvailable: true,
      capacity: 100,
      contactEmail: job.applicationEmail,
      contactPhone: '',
      donationUrl: 'https://beaconnewbeginnings.org/donate',
      jobOpenings: [job],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApplicationFormScreen(
          division: dummyDivision,
          serviceType: 'job',
          jobOpportunity: job,
        ),
      ),
    );
  }
}