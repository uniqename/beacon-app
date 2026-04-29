import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/case_plan.dart';
import '../../services/case_management_service.dart';
import 'client_intake_screen.dart';
import 'case_plan_screen.dart';

class CaseManagementScreen extends StatefulWidget {
  final AppUser user;

  const CaseManagementScreen({super.key, required this.user});

  @override
  State<CaseManagementScreen> createState() => _CaseManagementScreenState();
}

class _CaseManagementScreenState extends State<CaseManagementScreen> {
  List<CasePlan> _allPlans = [];
  Map<String, int> _stats = {};
  Map<String, int> _urgentCountByPlan = {};
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final plans = await CaseManagementService.getAllCasePlans();
      final stats = await CaseManagementService.getCaseManagementStats();
      // Load urgent program counts per plan
      final urgentMap = <String, int>{};
      for (final plan in plans) {
        final programs = await CaseManagementService.getProgramsForPlan(plan.id);
        urgentMap[plan.id] = programs
            .where((p) => p.priority == 'urgent' && !p.isCompleted)
            .length;
      }
      if (mounted) {
        setState(() {
          _allPlans = plans;
          _stats = stats;
          _urgentCountByPlan = urgentMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error loading case plans: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<CasePlan> get _filteredPlans {
    var plans = _allPlans;
    if (_filterStatus != 'all') {
      plans = plans.where((p) => p.planStatus == _filterStatus).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      plans = plans
          .where((p) =>
              p.clientName.toLowerCase().contains(q) ||
              p.caseManagerName.toLowerCase().contains(q))
          .toList();
    }
    return plans;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Case Management',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFE65100),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClientIntakeScreen(user: widget.user),
            ),
          );
          _load();
        },
        backgroundColor: const Color(0xFFE65100),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('New Client', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: const Color(0xFFE65100),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFE65100)),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStats(),
                    const SizedBox(height: 20),
                    _buildSearch(),
                    const SizedBox(height: 12),
                    _buildFilterChips(),
                    const SizedBox(height: 16),
                    _buildList(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            '${_stats['totalCasePlans'] ?? 0}',
            'Total Cases',
            Icons.folder_special,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            '${_stats['activeCasePlans'] ?? 0}',
            'Active',
            Icons.play_circle_outline,
            Colors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            '${_stats['urgentPrograms'] ?? 0}',
            'Urgent Programs',
            Icons.priority_high,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey[200]!, blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(value,
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      onChanged: (v) => setState(() => _searchQuery = v),
      decoration: InputDecoration(
        hintText: 'Search by client name…',
        prefixIcon: const Icon(Icons.search, color: Color(0xFFE65100)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE65100)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      ('all', 'All'),
      ('active', 'Active'),
      ('under_review', 'Under Review'),
      ('closed', 'Closed'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters
            .map((f) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f.$2),
                    selected: _filterStatus == f.$1,
                    onSelected: (_) => setState(() => _filterStatus = f.$1),
                    selectedColor: const Color(0xFFE65100).withValues(alpha: 0.2),
                    checkmarkColor: const Color(0xFFE65100),
                    labelStyle: TextStyle(
                      color: _filterStatus == f.$1
                          ? const Color(0xFFE65100)
                          : Colors.grey[700],
                      fontWeight: _filterStatus == f.$1
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildList() {
    final plans = _filteredPlans;
    if (plans.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Icon(Icons.folder_open, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                _allPlans.isEmpty
                    ? 'No cases yet\nTap "+ New Client" to start a case plan'
                    : 'No cases match your search',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: plans.length,
      itemBuilder: (_, i) => _buildPlanCard(plans[i]),
    );
  }

  Widget _buildPlanCard(CasePlan plan) {
    final urgentCount = _urgentCountByPlan[plan.id] ?? 0;
    Color statusColor;
    String statusLabel;
    switch (plan.planStatus) {
      case 'active':
        statusColor = Colors.green;
        statusLabel = 'Active';
        break;
      case 'under_review':
        statusColor = Colors.amber[700]!;
        statusLabel = 'Under Review';
        break;
      case 'closed':
        statusColor = Colors.grey;
        statusLabel = 'Closed';
        break;
      default:
        statusColor = Colors.blue;
        statusLabel = plan.planStatus;
    }

    final reviewBannerColor = plan.isReviewOverdue
        ? Colors.red[50]
        : plan.isReviewDueSoon
            ? Colors.amber[50]
            : null;
    final reviewBannerBorder = plan.isReviewOverdue
        ? Colors.red[200]!
        : plan.isReviewDueSoon
            ? Colors.amber[200]!
            : Colors.transparent;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: urgentCount > 0 ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: urgentCount > 0
            ? const BorderSide(color: Colors.red, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CasePlanScreen(
                casePlanId: plan.id,
                adminUser: widget.user,
              ),
            ),
          );
          _load();
        },
        onLongPress: () => _showPlanActions(plan),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Review banner
            if (plan.isReviewOverdue || plan.isReviewDueSoon)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: reviewBannerColor,
                  border: Border(bottom: BorderSide(color: reviewBannerBorder)),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      plan.isReviewOverdue ? Icons.warning : Icons.schedule,
                      size: 14,
                      color: plan.isReviewOverdue ? Colors.red[700] : Colors.amber[800],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      plan.isReviewOverdue ? 'Review overdue' : 'Review due soon',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: plan.isReviewOverdue
                            ? Colors.red[700]
                            : Colors.amber[800],
                      ),
                    ),
                    if (plan.nextReviewDate != null) ...[
                      const Spacer(),
                      Text(
                        _formatDate(plan.nextReviewDate!),
                        style: TextStyle(
                          fontSize: 11,
                          color: plan.isReviewOverdue
                              ? Colors.red[600]
                              : Colors.amber[700],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFE65100).withValues(alpha: 0.1),
                        child: Text(
                          plan.clientName.isNotEmpty
                              ? plan.clientName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Color(0xFFE65100),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.clientName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Case Manager: ${plan.caseManagerName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (urgentCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.priority_high,
                                  size: 12, color: Colors.red[700]),
                              const SizedBox(width: 4),
                              Text(
                                '$urgentCount urgent',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (plan.nextReviewDate != null &&
                          !plan.isReviewOverdue &&
                          !plan.isReviewDueSoon) ...[
                        Icon(Icons.calendar_today,
                            size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          'Review: ${_formatDate(plan.nextReviewDate!)}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                      const Spacer(),
                      Icon(Icons.chevron_right, color: Colors.grey[400]),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlanActions(CasePlan plan) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('View Plan'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CasePlanScreen(
                      casePlanId: plan.id,
                      adminUser: widget.user,
                    ),
                  ),
                ).then((_) => _load());
              },
            ),
            if (plan.planStatus != 'closed')
              ListTile(
                leading: const Icon(Icons.close, color: Colors.red),
                title: const Text('Close Case',
                    style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await CaseManagementService.updateCasePlan(
                    plan.copyWith(planStatus: 'closed'),
                  );
                  _load();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
