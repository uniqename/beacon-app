import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/local_database_service.dart';
import 'manage_divisions_screen.dart';
import 'manage_services_screen.dart';
import 'admin_reports_screen.dart';
import 'user_management_screen.dart';
import 'admin_inquiry_management_screen.dart';
import 'admin_helper_approvals_screen.dart';
import 'admin_content_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final AppUser user;

  const AdminDashboardScreen({super.key, required this.user});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, int> _stats = {};
  bool _isLoadingStats = true;

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
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      developer.log('Error loading admin stats: $e');
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is admin
    if (widget.user.userType != UserType.admin) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Access Denied'),
          backgroundColor: Colors.red[600],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 64, color: Colors.red[600]),
              SizedBox(height: 16),
              Text(
                'Admin Access Required',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'You do not have permission to access this area.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFFF0562D),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // Handle notifications
            },
          ),
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Text('Settings'),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            SizedBox(height: 24),
            _buildQuickStats(),
            SizedBox(height: 24),
            _buildAdminActions(),
            SizedBox(height: 24),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF0562D), Color(0xFFFF7043)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFF0562D).withValues(alpha: 0.3),
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
              CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Icon(Icons.admin_panel_settings, color: Colors.white),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${widget.user.name}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'System Administrator',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Manage services, divisions, and monitor system activity',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
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

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF0562D),
          ),
        ),
        SizedBox(height: 16),
        _isLoadingStats
            ? Center(child: CircularProgressIndicator(color: Color(0xFFF0562D)))
            : Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildStatCard(
                        '${_stats['totalUsers'] ?? 0}',
                        'Total Users',
                        Icons.people,
                        Colors.blue
                      )),
                      SizedBox(width: 12),
                      Expanded(child: _buildStatCard(
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
                      Expanded(child: _buildStatCard(
                        '${_stats['totalInquiries'] ?? 0}',
                        'Total Inquiries',
                        Icons.support_agent,
                        Colors.orange
                      )),
                      SizedBox(width: 12),
                      Expanded(child: _buildStatCard(
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
                      Expanded(child: _buildStatCard(
                        '${_stats['totalCases'] ?? 0}',
                        'Total Cases',
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
                            child: TextButton.icon(
                              onPressed: _loadStats,
                              icon: Icon(Icons.refresh, size: 18),
                              label: Text('Refresh'),
                              style: TextButton.styleFrom(
                                foregroundColor: Color(0xFFF0562D),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildStatCard(String number, String label, IconData icon, Color color) {
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

  Widget _buildAdminActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Admin Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF0562D),
          ),
        ),
        SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _buildActionCard(
              'Manage Divisions',
              'Add, edit, or remove service divisions',
              Icons.business,
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManageDivisionsScreen()),
              ),
            ),
            _buildActionCard(
              'Manage Services',
              'Add, edit, or remove individual services',
              Icons.medical_services,
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManageServicesScreen()),
              ),
            ),
            _buildActionCard(
              'User Management',
              'Manage user accounts and permissions',
              Icons.people,
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserManagementScreen()),
              ),
            ),
            _buildActionCard(
              'Reports',
              'View system reports and analytics',
              Icons.analytics,
              Colors.purple,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminReportsScreen()),
              ),
            ),
            _buildActionCard(
              'Support Inquiries',
              'Manage escalated chat support tickets',
              Icons.support_agent,
              Colors.red,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminInquiryManagementScreen()),
              ),
            ),
            _buildActionCard(
              'Helper Applications',
              'Review counselor & volunteer applications',
              Icons.approval,
              Colors.teal,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminHelperApprovalsScreen()),
              ),
            ),
            _buildActionCard(
              'Content Management',
              'Add/edit jobs, events, devotionals, shelters, mentors & more',
              Icons.edit_note,
              Colors.indigo,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminContentManagementScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
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
                Icon(Icons.timeline, size: 48, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'Activity Log',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Recent system activities and changes will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'Activities are tracked when you:\n• Add or edit divisions\n• Add or edit services\n• Manage user accounts\n• Respond to inquiries',
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
}