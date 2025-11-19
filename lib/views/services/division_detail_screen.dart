import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../models/beacon_division.dart';
import '../../services/auth_service.dart';
import '../jobs/job_detail_screen.dart';
import '../donations/enhanced_donation_screen.dart';
import '../applications/application_form_screen.dart';

class DivisionDetailScreen extends StatefulWidget {
  final BeaconDivision division;

  const DivisionDetailScreen({Key? key, required this.division}) : super(key: key);

  @override
  _DivisionDetailScreenState createState() => _DivisionDetailScreenState();
}

class _DivisionDetailScreenState extends State<DivisionDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor = Color(int.parse(widget.division.color.replaceFirst('#', '0xFF')));
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(primaryColor),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildHeaderInfo(primaryColor),
                _buildTabSection(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActions(primaryColor),
    );
  }

  Widget _buildSliverAppBar(Color primaryColor) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shadowColor: primaryColor.withOpacity(0.3),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 16, bottom: 16),
        title: Text(
          widget.division.shortName,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3,
                color: Colors.black.withOpacity(0.5),
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                primaryColor,
                primaryColor.withAlpha(200),
              ],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.2),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 40),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      widget.division.icon,
                      style: TextStyle(fontSize: 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.share, color: Colors.white),
          tooltip: 'Share',
          onPressed: () {
            // Handle share
          },
        ),
        IconButton(
          icon: Icon(Icons.favorite_border, color: Colors.white),
          tooltip: 'Favorite',
          onPressed: () {
            // Handle favorite
          },
        ),
      ],
    );
  }

  Widget _buildHeaderInfo(Color primaryColor) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withAlpha(26),
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
                  widget.division.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          SizedBox(height: 12),
          Text(
            widget.division.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(
                '${widget.division.capacity}% Available',
                Icons.assessment,
                widget.division.capacity > 80 ? Colors.green : Colors.orange,
              ),
              SizedBox(width: 12),
              _buildInfoChip(
                '${widget.division.jobOpenings.length} Jobs',
                Icons.work,
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.division.isAvailable ? Colors.green[100] : Colors.orange[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.division.isAvailable ? Icons.check_circle : Icons.access_time,
            color: widget.division.isAvailable ? Colors.green[700] : Colors.orange[700],
            size: 16,
          ),
          SizedBox(width: 4),
          Text(
            widget.division.isAvailable ? 'Available' : 'Limited',
            style: TextStyle(
              color: widget.division.isAvailable ? Colors.green[700] : Colors.orange[700],
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  Widget _buildTabSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: Color(int.parse(widget.division.color.replaceFirst('#', '0xFF'))),
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: Color(int.parse(widget.division.color.replaceFirst('#', '0xFF'))),
            tabs: [
              Tab(text: 'Services'),
              Tab(text: 'Resources'),
              Tab(text: 'Jobs'),
              Tab(text: 'Donate'),
            ],
          ),
          SizedBox(height: 20),
          Container(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildServicesTab(),
                _buildResourcesTab(),
                _buildJobsTab(),
                _buildDonateTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    return ListView.builder(
      itemCount: widget.division.services.length,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(int.parse(widget.division.color.replaceFirst('#', '0xFF'))).withAlpha(51),
              child: Icon(
                Icons.medical_services,
                color: Color(int.parse(widget.division.color.replaceFirst('#', '0xFF'))),
              ),
            ),
            title: Text(
              widget.division.services[index],
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('Available 24/7 with qualified staff'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showServiceDetails(widget.division.services[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildResourcesTab() {
    return ListView.builder(
      itemCount: widget.division.resources.length,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.folder_open, color: Colors.blue[700]),
            ),
            title: Text(
              widget.division.resources[index],
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('Immediate access available'),
            trailing: Icon(Icons.download, size: 16),
            onTap: () {
              _showResourceDetails(widget.division.resources[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildJobsTab() {
    if (widget.division.jobOpenings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No job openings available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Check back later for new opportunities',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.division.jobOpenings.length,
      itemBuilder: (context, index) {
        JobOpportunity job = widget.division.jobOpenings[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JobDetailScreen(job: job),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          job.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (job.isUrgent)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'URGENT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    job.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      _buildJobInfoChip(job.type.toUpperCase(), Icons.schedule),
                      SizedBox(width: 8),
                      _buildJobInfoChip(job.location, Icons.location_on),
                      if (job.isRemote) ...[
                        SizedBox(width: 8),
                        _buildJobInfoChip('REMOTE', Icons.home),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildJobInfoChip(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonateTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support ${widget.division.shortName}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(int.parse(widget.division.color.replaceFirst('#', '0xFF'))),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Your donation directly supports our ${widget.division.shortName.toLowerCase()} services, helping us provide essential support to those in need.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          SizedBox(height: 24),
          _buildDonationOptions(),
        ],
      ),
    );
  }

  Widget _buildDonationOptions() {
    List<Map<String, dynamic>> donationAmounts = [
      {'amount': 25, 'description': 'Provides basic supplies for one person'},
      {'amount': 50, 'description': 'Supports counseling session'},
      {'amount': 100, 'description': 'Helps with emergency assistance'},
      {'amount': 250, 'description': 'Sponsors training program'},
    ];

    return Column(
      children: donationAmounts.map((donation) {
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EnhancedDonationScreen(
                      division: widget.division,
                      suggestedAmount: donation['amount'],
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(int.parse(widget.division.color.replaceFirst('#', '0xFF'))).withAlpha(51),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '₵${donation['amount']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(int.parse(widget.division.color.replaceFirst('#', '0xFF'))),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        donation['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFloatingActions(Color primaryColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: "contact",
          onPressed: () {
            _showContactOptions();
          },
          backgroundColor: primaryColor,
          child: Icon(Icons.phone, color: Colors.white),
        ),
        SizedBox(height: 16),
        FloatingActionButton.extended(
          heroTag: "emergency",
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
      ],
    );
  }

  void _showServiceDetails(String service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.medical_services,
              color: Color(int.parse(widget.division.color.replaceFirst('#', '0xFF'))),
            ),
            SizedBox(width: 12),
            Expanded(child: Text(service)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getServiceDescription(service),
                style: TextStyle(fontSize: 14, height: 1.4),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to get involved:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Apply as a volunteer to help with this service\n'
                      '• Request this service for yourself or someone else\n'
                      '• Donate to support this program\n'
                      '• Share with others who might need help',
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSupportOptions(service);
            },
            child: Text('Get Support'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showApplicationOptions(service);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(int.parse(widget.division.color.replaceFirst('#', '0xFF'))),
              foregroundColor: Colors.white,
            ),
            child: Text('Volunteer/Apply'),
          ),
        ],
      ),
    );
  }

  void _showResourceDetails(String resource) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(resource),
        content: Text('Information about $resource and how to access it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _accessResource(resource);
            },
            child: Text('Access Resource'),
          ),
        ],
      ),
    );
  }

  void _accessResource(String resource) {
    // Create a comprehensive resource access flow
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ResourceAccessSheet(
        division: widget.division,
        resource: resource,
      ),
    );
  }

  void _showContactOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Contact ${widget.division.shortName}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.phone, color: Color(0xFF2E8B57)),
              title: Text('Call'),
              subtitle: Text(widget.division.contactPhone),
              onTap: () {
                Navigator.pop(context);
                _callHotline();
              },
            ),
            ListTile(
              leading: Icon(Icons.email, color: Color(0xFF2E8B57)),
              title: Text('Email'),
              subtitle: Text(widget.division.contactEmail),
              onTap: () {
                Navigator.pop(context);
                _sendEmail('general inquiry');
              },
            ),
            ListTile(
              leading: Icon(Icons.message, color: Color(0xFF2E8B57)),
              title: Text('Message'),
              subtitle: Text('Send secure message'),
              onTap: () {
                Navigator.pop(context);
                // Handle messaging
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getServiceDescription(String service) {
    Map<String, String> serviceDescriptions = {
      'Crisis Counseling': 'Professional counseling services available 24/7 for individuals facing emotional or mental health crises. Our trained counselors provide confidential support, safety planning, and resource referrals.',
      'Emergency Shelter': 'Safe, temporary housing for individuals and families fleeing domestic violence or facing homelessness. Includes meals, safety planning, and connections to long-term housing solutions.',
      'Legal Advocacy': 'Free legal assistance including help with restraining orders, court accompaniment, custody issues, and immigration matters. Provided by experienced legal advocates.',
      'Support Groups': 'Peer-led support groups for survivors of trauma, domestic violence, and other challenges. Groups meet weekly and provide a safe space for healing and connection.',
      'Job Training': 'Skills training programs to help individuals gain employment and financial independence. Includes resume help, interview preparation, and job placement assistance.',
      'Financial Assistance': 'Emergency financial aid for rent, utilities, transportation, and other essential needs. Also includes financial literacy education.',
      'Childcare Services': 'Safe childcare while parents attend appointments, court hearings, or job interviews. Includes trauma-informed care for children who have experienced violence.',
      'Healthcare Navigation': 'Help accessing medical care, mental health services, and specialized trauma treatment. Includes assistance with insurance and transportation to appointments.',
      'Housing Search': 'Assistance finding safe, affordable long-term housing including help with applications, credit repair, and landlord advocacy.',
      'Life Skills Training': 'Classes on budgeting, cooking, parenting, computer skills, and other essential life skills to support independence and stability.',
    };
    
    return serviceDescriptions[service] ?? 
           'This service provides essential support and resources to individuals and families in need. Our trained staff work with clients to assess their needs and develop personalized support plans.';
  }

  void _showApplicationOptions(String service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'How would you like to get involved?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(int.parse(widget.division.color.replaceFirst('#', '0xFF'))),
              ),
            ),
            SizedBox(height: 24),
            _buildApplicationOption(
              'Volunteer for this Service',
              'Help provide $service to community members',
              Icons.volunteer_activism,
              Colors.green,
              () => _navigateToApplication('volunteer', serviceName: service),
            ),
            SizedBox(height: 12),
            _buildApplicationOption(
              'Apply for Job Position',
              'Join our team as a professional staff member',
              Icons.work,
              Colors.blue,
              () => _navigateToApplication('job', serviceName: service),
            ),
            SizedBox(height: 12),
            _buildApplicationOption(
              'Support with Donation',
              'Help fund this service for others in need',
              Icons.favorite,
              Colors.red,
              () => _showDonationOptions(service),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showSupportOptions(String service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Get Support for $service',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(int.parse(widget.division.color.replaceFirst('#', '0xFF'))),
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.amber[600]),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'To access support services, you\'ll need to create a secure account to protect your privacy.',
                      style: TextStyle(color: Colors.amber[700]),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            _buildSupportOption(
              'Request This Service',
              'Get immediate help with $service',
              Icons.support_agent,
              Colors.blue,
              () => _requestService(service),
            ),
            SizedBox(height: 12),
            _buildSupportOption(
              'Email for Information',
              'Send us a message about this service',
              Icons.email,
              Colors.green,
              () => _sendEmail(service),
            ),
            SizedBox(height: 12),
            _buildSupportOption(
              'Call Our Hotline',
              'Speak with someone right now',
              Icons.phone,
              Colors.red,
              () => _callHotline(),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationOption(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportOption(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  void _navigateToApplication(String serviceType, {String? serviceName}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApplicationFormScreen(
          division: widget.division,
          serviceType: serviceType,
          serviceName: serviceName,
        ),
      ),
    );
  }

  void _showDonationOptions(String service) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Support $service',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(int.parse(widget.division.color.replaceFirst('#', '0xFF'))),
              ),
            ),
            SizedBox(height: 20),
            _buildDonationOption('Monthly Donation', 'Ongoing support', Icons.calendar_today, () {}),
            SizedBox(height: 12),
            _buildDonationOption('One-time Donation', 'Single contribution', Icons.payment, () {}),
            SizedBox(height: 12),
            _buildDonationOption('Donate Items', 'In-kind donations', Icons.inventory, () {}),
            SizedBox(height: 12),
            _buildDonationOption('Volunteer Time', 'Give your time', Icons.volunteer_activism, 
              () => _navigateToApplication('volunteer', serviceName: service)),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationOption(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Color(int.parse(widget.division.color.replaceFirst('#', '0xFF')))),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  void _requestService(String service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.blue[600]),
            SizedBox(width: 12),
            Expanded(child: Text('Account Required')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To request support services, you need a secure account to protect your privacy and safety.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock, size: 16, color: Colors.blue[600]),
                      SizedBox(width: 8),
                      Text(
                        'Why we need this:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Secure communication with counselors\n'
                    '• Track your service requests and progress\n'
                    '• Maintain confidential records\n'
                    '• Provide personalized support',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_user, size: 16, color: Colors.green[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your information is encrypted and never shared',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
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
            child: Text('Maybe Later'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/register');
            },
            icon: Icon(Icons.person_add, size: 16),
            label: Text('Create Account'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _sendEmail(String service) async {
    final String subject = Uri.encodeComponent('Inquiry about $service - ${widget.division.name}');
    final String body = Uri.encodeComponent(
      'Hello,\n\n'
      'I am interested in learning more about the $service program offered by ${widget.division.name}. '
      'Could you please provide more information about:\n\n'
      '• How to access this service\n'
      '• Eligibility requirements\n'
      '• Available appointment times\n'
      '• Any documentation needed\n\n'
      'Thank you for your time.\n\n'
      'Best regards'
    );
    
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: widget.division.contactEmail,
      query: 'subject=$subject&body=$body',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        _showEmailFallback(service);
      }
    } catch (e) {
      _showEmailFallback(service);
    }
  }

  void _showEmailFallback(String service) {
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
            Text('Please contact us directly:'),
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
                    widget.division.contactEmail,
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Subject:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  SelectableText('Inquiry about $service - ${widget.division.name}'),
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

  void _callHotline() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: widget.division.contactPhone);
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showPhoneFallback();
      }
    } catch (e) {
      _showPhoneFallback();
    }
  }

  void _showPhoneFallback() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.phone, color: Colors.green[600]),
            SizedBox(width: 12),
            Text('Call ${widget.division.shortName}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please call us directly:'),
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
                      widget.division.contactPhone,
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
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, size: 16, color: Colors.amber[600]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Available 24/7 for crisis support',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[700],
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

class _ResourceAccessSheet extends StatefulWidget {
  final BeaconDivision division;
  final String resource;

  const _ResourceAccessSheet({
    required this.division,
    required this.resource,
  });

  @override
  State<_ResourceAccessSheet> createState() => _ResourceAccessSheetState();
}

class _ResourceAccessSheetState extends State<_ResourceAccessSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  String _urgencyLevel = 'Normal';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Check authentication status
      final context = this.context;
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      final isAnonymous = await authService.isAnonymousUser();

      if (currentUser == null || isAnonymous) {
        // Handle anonymous users - provide immediate access options
        setState(() => _isSubmitting = false);
        Navigator.pop(context);
        _showAnonymousAccessOptions();
        return;
      }

      // Simulate API call for authenticated users
      await Future.delayed(Duration(seconds: 2));

      setState(() => _isSubmitting = false);

      if (mounted) {
        Navigator.pop(context);
        _showSuccessDialog();
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        Navigator.pop(context);
        _showErrorDialog();
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: Text('Request Submitted'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your request for "${widget.resource}" has been submitted to ${widget.division.shortName}.'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[600], size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Next Steps:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• You will receive a confirmation call within 2-4 hours\n'
                    '• A case worker will be assigned to help you\n'
                    '• Keep your phone accessible for updates',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 13,
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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _callDivision();
            },
            child: Text('Call Now'),
          ),
        ],
      ),
    );
  }

  void _callDivision() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: widget.division.contactPhone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _showAnonymousAccessOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.info_outline, color: Colors.blue, size: 48),
        title: Text('Resource Access Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You can access "${widget.resource}" from ${widget.division.shortName} in these ways:'),
            SizedBox(height: 16),
            
            // Immediate access options
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.phone, color: Colors.green[600], size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Immediate Access:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Call: ${widget.division.contactPhone}\n'
                    '• Email: ${widget.division.contactEmail}\n'
                    '• Visit: Available during operating hours\n'
                    '• Walk-in consultation available',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 12),
            Text(
              'Or create an account for enhanced services:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              '• Online resource booking\n'
              '• Case management and tracking\n'
              '• Appointment scheduling\n'
              '• Follow-up notifications\n'
              '• Access to support groups',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Maybe Later'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _callDivision();
            },
            icon: Icon(Icons.phone, size: 16),
            label: Text('Call Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/register');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(int.parse(widget.division.color.replaceFirst('#', '0xFF'))),
              foregroundColor: Colors.white,
            ),
            child: Text('Create Account'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.error_outline, color: Colors.red, size: 48),
        title: Text('Request Error'),
        content: Text(
          'There was an error processing your request. Please try calling directly or visiting in person for immediate assistance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _callDivision();
            },
            child: Text('Call Instead'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 20),
          
          // Header
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(int.parse(widget.division.color.replaceFirst('#', '0xFF'))),
                child: Text(
                  widget.division.icon,
                  style: TextStyle(fontSize: 20),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Access Resource',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.resource} from ${widget.division.shortName}',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Form
          Flexible(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Your Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email (Optional)',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _urgencyLevel,
                      decoration: InputDecoration(
                        labelText: 'Urgency Level',
                        prefixIcon: Icon(Icons.priority_high),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        DropdownMenuItem(value: 'Low', child: Text('Low - Can wait a few days')),
                        DropdownMenuItem(value: 'Normal', child: Text('Normal - Within 24-48 hours')),
                        DropdownMenuItem(value: 'High', child: Text('High - Need help today')),
                        DropdownMenuItem(value: 'Emergency', child: Text('Emergency - Immediate assistance')),
                      ],
                      onChanged: (value) {
                        setState(() => _urgencyLevel = value!);
                      },
                    ),
                    SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Additional Details',
                        hintText: 'Please describe your specific needs...',
                        prefixIcon: Icon(Icons.note_alt),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 20),
                    
                    // Urgency warning
                    if (_urgencyLevel == 'Emergency')
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red[600]),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'For immediate emergencies, please call 999 or use the Emergency tab',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    SizedBox(height: 20),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(int.parse(widget.division.color.replaceFirst('#', '0xFF'))),
                              foregroundColor: Colors.white,
                            ),
                            child: _isSubmitting
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text('Submit Request'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          SizedBox(height: 20),
        ],
      ),
    );
  }
}