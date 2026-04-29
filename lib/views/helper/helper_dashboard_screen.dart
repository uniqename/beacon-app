import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/auth_service.dart';
import '../../services/local_database_service.dart';
import '../admin/admin_inquiry_management_screen.dart';
import '../community/support_groups_tab.dart';
import '../admin/case_management_screen.dart';
import '../admin/case_plan_screen.dart';
import '../../models/case_plan.dart';
import '../../services/case_management_service.dart';
import 'crisis_protocol_screen.dart';

class HelperDashboardScreen extends StatefulWidget {
  const HelperDashboardScreen({super.key});

  @override
  State<HelperDashboardScreen> createState() => _HelperDashboardScreenState();
}

class _HelperDashboardScreenState extends State<HelperDashboardScreen> {
  Map<String, int> _stats = {};
  List<Map<String, dynamic>> _recentTickets = [];
  List<CasePlan> _myCases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.id ?? '';
      if (userId.isNotEmpty) {
        final cases =
            await CaseManagementService.getCasePlansForManager(userId);
        if (mounted) setState(() => _myCases = cases);
      }
    });
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);

    try {
      // Load ticket statistics
      final totalInquiries = await LocalDatabaseService.getTotalInquiriesCount();
      final pendingInquiries = await LocalDatabaseService.getPendingInquiriesCount();
      final allTickets = await LocalDatabaseService.getAllInquiryTickets();

      // Filter high priority tickets
      final highPriorityTickets = allTickets.where((t) =>
        t['priority'] == 'high' && t['status'] != 'resolved'
      ).toList();

      // Get recent tickets (top 5)
      final recentTickets = allTickets.take(5).toList();

      if (mounted) {
        setState(() {
          _stats = {
            'totalInquiries': totalInquiries,
            'pendingInquiries': pendingInquiries,
            'emergencyTickets': highPriorityTickets.length,
            'activeTickets': allTickets.where((t) => t['status'] == 'in_progress').length,
          };
          _recentTickets = recentTickets;
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error loading helper dashboard: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    final userRole = currentUser?.userType.toString().split('.').last ?? 'helper';

    // Check approval status
    if (currentUser?.approvalStatus == 'pending') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Application Pending'),
          backgroundColor: Colors.orange[700],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pending_actions, size: 80, color: Colors.orange[700]),
                const SizedBox(height: 24),
                Text(
                  'Application Under Review',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Your ${userRole == 'counselor' ? 'counselor' : 'volunteer'} application is being reviewed by our admin team.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'You will be notified once your application has been approved.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange[700],
                    side: BorderSide(color: Colors.orange[700]!),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (currentUser?.approvalStatus == 'rejected') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Application Status'),
          backgroundColor: Colors.red[700],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cancel, size: 80, color: Colors.red[700]),
                const SizedBox(height: 24),
                Text(
                  'Application Not Approved',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[900],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Unfortunately, your application was not approved at this time.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                if (currentUser?.approvalNotes != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Notes:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[900],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentUser!.approvalNotes!,
                          style: TextStyle(color: Colors.red[800]),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[700],
                    side: BorderSide(color: Colors.red[700]!),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with greeting
                _buildHeader(currentUser?.displayName ?? 'Helper', userRole),
                const SizedBox(height: 24),

                // Quick Stats
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  _buildQuickStats(),
                  const SizedBox(height: 24),

                  // Quick Actions
                  _buildQuickActions(),
                  const SizedBox(height: 24),

                  // My Cases
                  if (_myCases.isNotEmpty) ...[
                    _buildMyCases(),
                    const SizedBox(height: 24),
                  ],

                  // Recent Tickets
                  _buildRecentTickets(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name, String role) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFF0562D), const Color(0xFFFF7043)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF0562D).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
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
                child: Icon(
                  role == 'counselor' ? Icons.psychology : Icons.volunteer_activism,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $name',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      role == 'counselor' ? 'Counselor' : 'Volunteer',
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your Dashboard - Help users in need',
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
        const Text(
          'Support Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF0562D),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '${_stats['totalInquiries'] ?? 0}',
                'Total Inquiries',
                Icons.inbox,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '${_stats['pendingInquiries'] ?? 0}',
                'Pending',
                Icons.pending_actions,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '${_stats['emergencyTickets'] ?? 0}',
                'Emergency',
                Icons.emergency,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '${_stats['activeTickets'] ?? 0}',
                'In Progress',
                Icons.support_agent,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String number, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
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
          const SizedBox(height: 8),
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

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF0562D),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildActionCard(
              'View All Tickets',
              'Manage support inquiries',
              Icons.support_agent,
              Colors.blue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminInquiryManagementScreen(),
                  ),
                ).then((_) => _loadDashboard());
              },
            ),
            _buildActionCard(
              'Emergency Cases',
              'High priority tickets',
              Icons.emergency,
              Colors.red,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminInquiryManagementScreen(),
                  ),
                ).then((_) => _loadDashboard());
              },
            ),
            _buildActionCard(
              'Support Groups',
              'Community discussions',
              Icons.groups,
              Colors.purple,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SupportGroupsTab(),
                  ),
                );
              },
            ),
            _buildActionCard(
              'Resources',
              'Share helpful content',
              Icons.library_books,
              Colors.indigo,
              () {
                Navigator.pushNamed(context, '/content_library');
              },
            ),
            _buildActionCard(
              'Case Management',
              'View and manage client support plans',
              Icons.folder_special,
              const Color(0xFFE65100),
              () {
                final authService =
                    Provider.of<AuthService>(context, listen: false);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CaseManagementScreen(
                        user: authService.currentUser!),
                  ),
                ).then((_) => _loadDashboard());
              },
            ),
            _buildActionCard(
              'Crisis Protocol',
              'Risk assessment & response guide',
              Icons.crisis_alert,
              Colors.red[700]!,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CrisisProtocolScreen(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMyCases() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Cases',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF0562D),
              ),
            ),
            TextButton(
              onPressed: () {
                final authService =
                    Provider.of<AuthService>(context, listen: false);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CaseManagementScreen(
                        user: authService.currentUser!),
                  ),
                ).then((_) => _loadDashboard());
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._myCases.take(3).map((plan) {
          Color statusColor;
          switch (plan.planStatus) {
            case 'active':
              statusColor = Colors.green;
              break;
            case 'under_review':
              statusColor = Colors.amber[700]!;
              break;
            default:
              statusColor = Colors.grey;
          }
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    const Color(0xFFE65100).withValues(alpha: 0.1),
                child: Text(
                  plan.clientName.isNotEmpty
                      ? plan.clientName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Color(0xFFE65100),
                      fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(plan.clientName,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: plan.nextReviewDate != null
                  ? Text(
                      'Review: ${plan.nextReviewDate!.day}/${plan.nextReviewDate!.month}/${plan.nextReviewDate!.year}',
                      style: const TextStyle(fontSize: 12))
                  : null,
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  plan.planStatus == 'active'
                      ? 'Active'
                      : plan.planStatus == 'under_review'
                          ? 'Review'
                          : plan.planStatus,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor),
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CasePlanScreen(
                      casePlanId: plan.id,
                    ),
                  ),
                );
              },
            ),
          );
        }),
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
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

  Widget _buildRecentTickets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Tickets',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF0562D),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminInquiryManagementScreen(),
                  ),
                ).then((_) => _loadDashboard());
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_recentTickets.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[200]!,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'No tickets yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'New inquiries will appear here',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          )
        else
          ..._recentTickets.map((ticket) => _buildTicketPreview(ticket)),
      ],
    );
  }

  Widget _buildTicketPreview(Map<String, dynamic> ticket) {
    final priority = ticket['priority'] as String;
    final status = ticket['status'] as String;
    final createdAt = DateTime.parse(ticket['created_at'] as String);
    final isEmergency = priority == 'high';

    Color priorityColor;
    switch (priority) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      default:
        priorityColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isEmergency ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isEmergency
            ? const BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TicketDetailScreen(ticket: ticket),
            ),
          ).then((_) => _loadDashboard());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isEmergency) ...[
                    const Icon(Icons.emergency, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      ticket['subject'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isEmergency ? Colors.red[900] : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      priority.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: priorityColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ticket['description'] as String,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    timeago.format(createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: status == 'resolved'
                          ? Colors.green[100]
                          : status == 'in_progress'
                              ? Colors.blue[100]
                              : Colors.orange[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status.toUpperCase().replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: status == 'resolved'
                            ? Colors.green
                            : status == 'in_progress'
                                ? Colors.blue
                                : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
