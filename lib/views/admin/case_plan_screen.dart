import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/case_plan.dart';
import '../../models/case_referral.dart';
import 'package:uuid/uuid.dart';
import '../../services/ai_consent_service.dart';
import '../../services/case_ai_service.dart';
import '../../services/case_management_service.dart';
import '../../services/local_database_service.dart';
import '../case_management/plan_calendar_screen.dart';
import 'case_program_detail_screen.dart';

class CasePlanScreen extends StatefulWidget {
  final String casePlanId;
  final AppUser? adminUser;

  const CasePlanScreen({
    super.key,
    required this.casePlanId,
    this.adminUser,
  });

  @override
  State<CasePlanScreen> createState() => _CasePlanScreenState();
}

class _CasePlanScreenState extends State<CasePlanScreen> {
  CasePlan? _plan;
  List<CaseProgram> _programs = [];
  List<CaseNote> _generalNotes = [];
  List<CaseReferral> _referrals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        CaseManagementService.getCasePlan(widget.casePlanId),
        CaseManagementService.getProgramsForPlan(widget.casePlanId),
        CaseManagementService.getNotesForPlan(widget.casePlanId,
            programId: null),
        CaseManagementService.getReferralsForPlan(widget.casePlanId),
      ]);
      if (mounted) {
        setState(() {
          _plan = results[0] as CasePlan?;
          _programs = results[1] as List<CaseProgram>;
          _generalNotes = results[2] as List<CaseNote>;
          _referrals = results[3] as List<CaseReferral>;
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error loading case plan: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _isAdmin => widget.adminUser != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _plan?.clientName ?? 'Case Plan',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFE65100),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
                IconButton(
                  icon: const Icon(Icons.calendar_month, color: Colors.white),
                  tooltip: 'Calendar',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlanCalendarScreen(
                        casePlanId: widget.casePlanId,
                        isAdminView: _isAdmin,
                      ),
                    ),
                  ),
                ),
                if (_isAdmin)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (v) => _handleMenuAction(v),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'ai_suggest',
                        child: Row(children: [
                          Icon(Icons.auto_awesome,
                              size: 18, color: Color(0xFF6A1B9A)),
                          SizedBox(width: 8),
                          Text('AI Suggest Programs'),
                        ])),
                    const PopupMenuItem(
                        value: 'mark_review',
                        child: Text('Mark as Under Review')),
                    const PopupMenuItem(
                        value: 'mark_active',
                        child: Text('Mark as Active')),
                    if (_plan?.clientId == null)
                      const PopupMenuItem(
                          value: 'link_user',
                          child: Row(children: [
                            Icon(Icons.link, size: 18, color: Color(0xFFE65100)),
                            SizedBox(width: 8),
                            Text('Link to App Account'),
                          ])),
                    if (_plan?.clientId != null)
                      const PopupMenuItem(
                          value: 'unlink_user',
                          child: Row(children: [
                            Icon(Icons.link_off, size: 18, color: Colors.grey),
                            SizedBox(width: 8),
                            Text('Unlink App Account'),
                          ])),
                    const PopupMenuItem(
                        value: 'close',
                        child: Text('Close Case',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showAddProgramSheet,
              backgroundColor: const Color(0xFFE65100),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Program',
                  style: TextStyle(color: Colors.white)),
            )
          : null,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE65100)))
          : _plan == null
              ? const Center(child: Text('Case plan not found'))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFFE65100),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        if (_plan!.isReviewOverdue || _plan!.isReviewDueSoon)
                          _buildReviewBanner(),
                        if (_plan!.isReviewOverdue || _plan!.isReviewDueSoon)
                          const SizedBox(height: 12),
                        _buildProgramsSection(),
                        const SizedBox(height: 20),
                        _buildReferralsSection(),
                        const SizedBox(height: 20),
                        _buildGeneralNotesSection(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    final plan = _plan!;
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE65100), Color(0xFFFF7043)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE65100).withValues(alpha: 0.3),
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
                radius: 24,
                child: Text(
                  plan.clientName.isNotEmpty
                      ? plan.clientName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.clientName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Case Manager: ${plan.caseManagerName}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.8), width: 1.5),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                      color: statusColor == Colors.green
                          ? Colors.white
                          : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _headerInfo(
                Icons.event_repeat,
                plan.reviewFrequency[0].toUpperCase() +
                    plan.reviewFrequency.substring(1),
                'Review',
              ),
              const SizedBox(width: 16),
              if (plan.nextReviewDate != null)
                _headerInfo(
                  Icons.calendar_today,
                  _fmt(plan.nextReviewDate!),
                  'Next Review',
                ),
              const Spacer(),
              _headerInfo(
                Icons.folder_special,
                '${_programs.length}',
                'Programs',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerInfo(IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
      ],
    );
  }

  Widget _buildReviewBanner() {
    final overdue = _plan!.isReviewOverdue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: overdue ? Colors.red[50] : Colors.amber[50],
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: overdue ? Colors.red[200]! : Colors.amber[200]!),
      ),
      child: Row(
        children: [
          Icon(
            overdue ? Icons.warning_amber : Icons.schedule,
            color: overdue ? Colors.red[700] : Colors.amber[800],
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            overdue
                ? 'Case review is overdue'
                : 'Case review is due within 14 days',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: overdue ? Colors.red[800] : Colors.amber[900],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Support Programs',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE65100)),
        ),
        const SizedBox(height: 12),
        if (_programs.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey[200]!,
                    blurRadius: 8,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.add_circle_outline,
                      size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    _isAdmin
                        ? 'No programs yet\nTap "+ Add Program" to get started'
                        : 'No programs have been added yet',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          )
        else
          ..._programs.map((p) => _buildProgramCard(p)),
      ],
    );
  }

  Widget _buildProgramCard(CaseProgram program) {
    final priorityColor = _priorityColor(program.priority);
    final priorityLabel = _priorityLabel(program.priority);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CaseProgramDetailScreen(
                programId: program.id,
                casePlanId: widget.casePlanId,
                isAdmin: _isAdmin,
                adminName: widget.adminUser?.name,
              ),
            ),
          );
          _load();
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Priority colour band
            Container(
              width: 6,
              height: 80,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            program.programName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            priorityLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: priorityColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (program.goal.isNotEmpty)
                      Text(
                        program.goal,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600]),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Progress
                        if (program.totalActionCount > 0) ...[
                          SizedBox(
                            width: 80,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: program.completionPercent,
                                backgroundColor: Colors.grey[200],
                                color: program.isCompleted
                                    ? Colors.green
                                    : priorityColor,
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${program.completedActionCount}/${program.totalActionCount} done',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[600]),
                          ),
                        ] else
                          Text('No actions yet',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[400])),
                        const Spacer(),
                        if (program.deadlineLabel != null)
                          Text(
                            program.deadlineLabel!,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500]),
                          ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right, color: Colors.grey[400]),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Referrals ───────────────────────────────────────────────────────────

  Widget _buildReferralsSection() {
    final inbound = _referrals.where((r) => r.isInbound).length;
    final outbound = _referrals.where((r) => r.isOutbound).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Referrals',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE65100)),
            ),
            const SizedBox(width: 8),
            if (_referrals.isNotEmpty) ...[
              _referralChip('↓ $inbound In', Colors.blue),
              const SizedBox(width: 4),
              _referralChip('↑ $outbound Out', Colors.teal),
            ],
            const Spacer(),
            if (_isAdmin)
              TextButton.icon(
                onPressed: _showAddReferralSheet,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Log Referral'),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFE65100)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_referrals.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey[200]!,
                    blurRadius: 8,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: Center(
              child: Text(
                _isAdmin
                    ? 'No referrals logged yet\nTap "Log Referral" to record one'
                    : 'No referrals recorded',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ),
          )
        else
          ..._referrals.map((r) => _buildReferralCard(r)),
      ],
    );
  }

  Widget _referralChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildReferralCard(CaseReferral referral) {
    final isIn = referral.isInbound;
    final dirColor = isIn ? Colors.blue : Colors.teal;
    final dirLabel = isIn ? 'INBOUND' : 'OUTBOUND';
    final dirIcon = isIn ? Icons.arrow_downward : Icons.arrow_upward;

    Color statusColor;
    switch (referral.status) {
      case 'active':
        statusColor = Colors.blue;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'declined':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.amber[700]!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey[200]!,
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: InkWell(
        onTap: _isAdmin ? () => _showEditReferralSheet(referral) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: dirColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(dirIcon, size: 11, color: dirColor),
                        const SizedBox(width: 4),
                        Text(dirLabel,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: dirColor)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      referral.partnerOrganization,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      referral.status[0].toUpperCase() +
                          referral.status.substring(1),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor),
                    ),
                  ),
                ],
              ),
              if (referral.serviceType != null) ...[
                const SizedBox(height: 6),
                Text(referral.serviceType!,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
              const SizedBox(height: 6),
              Text(
                referral.reason,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 11, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(_fmt(referral.referralDate),
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[500])),
                  const Spacer(),
                  _urgencyBadge(referral.urgency),
                  if (_isAdmin) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.edit_outlined,
                        size: 14, color: Colors.grey[400]),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _urgencyBadge(String urgency) {
    Color c;
    switch (urgency) {
      case 'urgent':
        c = Colors.orange;
        break;
      case 'emergency':
        c = Colors.red;
        break;
      default:
        c = Colors.grey;
    }
    return Text(
      urgency[0].toUpperCase() + urgency.substring(1),
      style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: c),
    );
  }

  void _showAddReferralSheet() => _showReferralSheet(null);
  void _showEditReferralSheet(CaseReferral referral) =>
      _showReferralSheet(referral);

  void _showReferralSheet(CaseReferral? existing) {
    String direction = existing?.direction ?? 'outbound';
    final partnerCtrl = TextEditingController(
        text: existing?.partnerOrganization ?? '');
    final contactNameCtrl =
        TextEditingController(text: existing?.partnerContactName ?? '');
    final contactPhoneCtrl =
        TextEditingController(text: existing?.partnerContactPhone ?? '');
    final reasonCtrl =
        TextEditingController(text: existing?.reason ?? '');
    String? serviceType = existing?.serviceType;
    String urgency = existing?.urgency ?? 'routine';
    String status = existing?.status ?? 'pending';
    final outcomeCtrl =
        TextEditingController(text: existing?.outcomeNotes ?? '');
    DateTime referralDate = existing?.referralDate ?? DateTime.now();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      existing == null ? 'Log Referral' : 'Edit Referral',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (existing != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        tooltip: 'Delete referral',
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await CaseManagementService.deleteReferral(
                              existing.id);
                          _load();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Direction toggle
                const Text('Direction',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _directionToggle(
                        setS,
                        label: '↓ Inbound (referred to us)',
                        value: 'inbound',
                        current: direction,
                        color: Colors.blue,
                        onTap: () => setS(() => direction = 'inbound'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _directionToggle(
                        setS,
                        label: '↑ Outbound (we referred out)',
                        value: 'outbound',
                        current: direction,
                        color: Colors.teal,
                        onTap: () => setS(() => direction = 'outbound'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading:
                      const Icon(Icons.calendar_today, size: 18),
                  title: Text(
                      'Date: ${_fmt(referralDate)}',
                      style: const TextStyle(fontSize: 14)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: referralDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now()
                          .add(const Duration(days: 365)),
                    );
                    if (picked != null) setS(() => referralDate = picked);
                  },
                ),
                const SizedBox(height: 10),

                // Partner
                Autocomplete<String>(
                  initialValue:
                      TextEditingValue(text: partnerCtrl.text),
                  optionsBuilder: (v) => kKnownPartners
                      .where((p) => p
                          .toLowerCase()
                          .contains(v.text.toLowerCase()))
                      .toList(),
                  onSelected: (v) => partnerCtrl.text = v,
                  fieldViewBuilder: (ctx2, ctrl, focus, onSubmit) =>
                      TextField(
                    controller: ctrl,
                    focusNode: focus,
                    onChanged: (v) => partnerCtrl.text = v,
                    decoration: const InputDecoration(
                      labelText: 'Partner Organisation *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: contactNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Contact Name (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: contactPhoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Contact Phone (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),

                // Service type dropdown
                DropdownButtonFormField<String>(
                  initialValue: serviceType,
                  decoration: const InputDecoration(
                    labelText: 'Service Type',
                    border: OutlineInputBorder(),
                  ),
                  items: kServiceTypes
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setS(() => serviceType = v),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Referral *',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),

                // Urgency chips
                const Text('Urgency',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ['routine', 'urgent', 'emergency']
                      .map((u) => ChoiceChip(
                            label: Text(u[0].toUpperCase() +
                                u.substring(1)),
                            selected: urgency == u,
                            selectedColor: u == 'emergency'
                                ? Colors.red[100]
                                : u == 'urgent'
                                    ? Colors.orange[100]
                                    : Colors.grey[200],
                            onSelected: (_) =>
                                setS(() => urgency = u),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),

                // Status chips
                const Text('Status',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children:
                      ['pending', 'active', 'completed', 'declined']
                          .map((s) => ChoiceChip(
                                label: Text(s[0].toUpperCase() +
                                    s.substring(1)),
                                selected: status == s,
                                selectedColor:
                                    s == 'completed'
                                        ? Colors.green[100]
                                        : s == 'declined'
                                            ? Colors.red[100]
                                            : s == 'active'
                                                ? Colors.blue[100]
                                                : Colors.grey[200],
                                onSelected: (_) =>
                                    setS(() => status = s),
                              ))
                          .toList(),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: outcomeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Outcome / Notes (optional)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100),
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: saving
                        ? null
                        : () async {
                            final partner =
                                partnerCtrl.text.trim();
                            final reason = reasonCtrl.text.trim();
                            if (partner.isEmpty || reason.isEmpty) {
                              ScaffoldMessenger.of(ctx)
                                  .showSnackBar(const SnackBar(
                                content: Text(
                                    'Partner organisation and reason are required'),
                                backgroundColor: Colors.red,
                              ));
                              return;
                            }
                            setS(() => saving = true);
                            try {
                              final now = DateTime.now();
                              if (existing == null) {
                                await CaseManagementService
                                    .createReferral(CaseReferral(
                                  id: const Uuid().v4(),
                                  intakeId: _plan!.intakeId,
                                  casePlanId: widget.casePlanId,
                                  direction: direction,
                                  referralDate: referralDate,
                                  partnerOrganization: partner,
                                  partnerContactName: contactNameCtrl
                                          .text
                                          .trim()
                                          .isEmpty
                                      ? null
                                      : contactNameCtrl.text.trim(),
                                  partnerContactPhone:
                                      contactPhoneCtrl.text
                                              .trim()
                                              .isEmpty
                                          ? null
                                          : contactPhoneCtrl.text
                                              .trim(),
                                  reason: reason,
                                  serviceType: serviceType,
                                  urgency: urgency,
                                  status: status,
                                  outcomeNotes:
                                      outcomeCtrl.text.trim().isEmpty
                                          ? null
                                          : outcomeCtrl.text.trim(),
                                  recordedBy: widget.adminUser
                                          ?.name ??
                                      'Admin',
                                  createdAt: now,
                                  updatedAt: now,
                                ));
                              } else {
                                await CaseManagementService
                                    .updateReferral(
                                  existing.copyWith(
                                    direction: direction,
                                    referralDate: referralDate,
                                    partnerOrganization: partner,
                                    partnerContactName:
                                        contactNameCtrl.text
                                                .trim()
                                                .isEmpty
                                            ? null
                                            : contactNameCtrl.text
                                                .trim(),
                                    partnerContactPhone:
                                        contactPhoneCtrl.text
                                                .trim()
                                                .isEmpty
                                            ? null
                                            : contactPhoneCtrl.text
                                                .trim(),
                                    reason: reason,
                                    serviceType: serviceType,
                                    urgency: urgency,
                                    status: status,
                                    outcomeNotes: outcomeCtrl.text
                                            .trim()
                                            .isEmpty
                                        ? null
                                        : outcomeCtrl.text.trim(),
                                    updatedAt: now,
                                  ),
                                );
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                              _load();
                            } catch (e) {
                              setS(() => saving = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red),
                                );
                              }
                            }
                          },
                    child: saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : Text(
                            existing == null
                                ? 'Save Referral'
                                : 'Update Referral',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _directionToggle(
    StateSetter setS, {
    required String label,
    required String value,
    required String current,
    required Color color,
    required VoidCallback onTap,
  }) {
    final selected = current == value;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected
                  ? color
                  : Colors.grey[300]!,
              width: selected ? 1.5 : 1),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? color : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Case Notes',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE65100)),
            ),
            const Spacer(),
            if (_isAdmin)
              TextButton.icon(
                onPressed: _showAddNoteSheet,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Note'),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFE65100)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_generalNotes.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey[200]!,
                    blurRadius: 8,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: Center(
              child: Text(
                'No general notes yet',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ),
          )
        else
          ..._generalNotes.map((note) => _buildNoteCard(note)),
      ],
    );
  }

  Widget _buildNoteCard(CaseNote note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.grey[200]!,
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(note.noteText,
              style: const TextStyle(fontSize: 14, height: 1.4)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person_outline, size: 12, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(note.createdBy,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              const Spacer(),
              Text(_fmt(note.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddProgramSheet() {
    final nameCtrl = TextEditingController();
    final goalCtrl = TextEditingController();
    final deadlineLabelCtrl = TextEditingController();
    String selectedPriority = 'medium';
    ProgramTemplate? selectedTemplate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Add Program',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                // Templates row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: kProgramTemplates
                        .map((t) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                label: Text(t.name,
                                    style: const TextStyle(fontSize: 11)),
                                onPressed: () {
                                  setSheetState(() {
                                    selectedTemplate = t;
                                    nameCtrl.text = t.name;
                                    goalCtrl.text = t.goal;
                                    selectedPriority = t.priority;
                                  });
                                },
                                backgroundColor: selectedTemplate == t
                                    ? const Color(0xFFE65100)
                                        .withValues(alpha: 0.15)
                                    : null,
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Program Name *',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: goalCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Goal',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'urgent',
                        child: Text('🔴  Urgent')),
                    DropdownMenuItem(
                        value: 'high',
                        child: Text('🟠  High')),
                    DropdownMenuItem(
                        value: 'medium',
                        child: Text('🟡  Medium')),
                    DropdownMenuItem(
                        value: 'monitor',
                        child: Text('🔵  Monitor')),
                    DropdownMenuItem(
                        value: 'ongoing',
                        child: Text('🟢  Ongoing')),
                  ],
                  onChanged: (v) => setSheetState(
                      () => selectedPriority = v ?? selectedPriority),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: deadlineLabelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Deadline Label (optional)',
                    hintText: 'e.g. "Within 30 days", "May 2026"',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      final now = DateTime.now();
                      final nextNum = _programs.isEmpty
                          ? 1
                          : _programs
                                  .map((p) => p.programNumber)
                                  .reduce((a, b) => a > b ? a : b) +
                              1;
                      final program = CaseProgram(
                        id: CaseManagementService.generateId(),
                        casePlanId: widget.casePlanId,
                        programNumber: nextNum,
                        programName: nameCtrl.text.trim(),
                        goal: goalCtrl.text.trim(),
                        priority: selectedPriority,
                        deadlineLabel: deadlineLabelCtrl.text.trim().isEmpty
                            ? null
                            : deadlineLabelCtrl.text.trim(),
                        createdAt: now,
                        updatedAt: now,
                      );
                      final nav = Navigator.of(ctx);
                      await CaseManagementService.createProgram(program);
                      if (mounted) {
                        nav.pop();
                        _load();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Add Program',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddNoteSheet() {
    final noteCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Add General Note',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Write your case note…',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (noteCtrl.text.trim().isEmpty) return;
                  final nav = Navigator.of(ctx);
                  final note = CaseNote(
                    id: CaseManagementService.generateId(),
                    casePlanId: widget.casePlanId,
                    noteText: noteCtrl.text.trim(),
                    createdBy: widget.adminUser?.name ?? 'Admin',
                    createdAt: DateTime.now(),
                  );
                  await CaseManagementService.addNote(note);
                  if (mounted) {
                    nav.pop();
                    _load();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Save Note',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMenuAction(String action) async {
    if (_plan == null) return;
    switch (action) {
      case 'mark_review':
        await CaseManagementService.updateCasePlan(
            _plan!.copyWith(planStatus: 'under_review'));
        _load();
        break;
      case 'mark_active':
        await CaseManagementService.updateCasePlan(
            _plan!.copyWith(planStatus: 'active'));
        _load();
        break;
      case 'ai_suggest':
        await _showAISuggestPrograms();
        break;
      case 'link_user':
        await _showLinkUserDialog();
        break;
      case 'unlink_user':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Unlink App Account'),
            content: const Text(
                'Remove the link between this case plan and the app user? The user will no longer see their plan in the app.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Unlink',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        );
        if (confirm == true && _plan != null) {
          final db = await LocalDatabaseService.database;
          final now = DateTime.now().toIso8601String();
          await db.update('client_intakes',
              {'client_id': null, 'updated_at': now},
              where: 'id = ?', whereArgs: [_plan!.intakeId]);
          await db.update('case_plans',
              {'client_id': null, 'updated_at': now},
              where: 'id = ?', whereArgs: [_plan!.id]);
          _load();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('App account unlinked')),
            );
          }
        }
        break;
      case 'close':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Close Case'),
            content: Text(
                'Are you sure you want to close the case for ${_plan!.clientName}?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Close Case',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await CaseManagementService.updateCasePlan(
              _plan!.copyWith(planStatus: 'closed'));
          if (mounted) Navigator.pop(context);
        }
        break;
    }
  }

  Future<void> _showAISuggestPrograms() async {
    if (_plan == null) return;

    final consented = await AiConsentService.requestConsentIfNeeded(context);
    if (!mounted || !consented) return;

    // Load intake for context
    final db = await LocalDatabaseService.database;
    final intakeRows = await db.query('client_intakes',
        where: 'id = ?', whereArgs: [_plan!.intakeId], limit: 1);
    final situation = intakeRows.isNotEmpty
        ? (intakeRows.first['presenting_situation'] as String? ?? '')
        : '';
    final needsRaw = intakeRows.isNotEmpty
        ? (intakeRows.first['needs_identified'] as String? ?? '[]')
        : '[]';
    List<String> needs = [];
    try {
      needs = List<String>.from(
          (const [] + (intakeRows.isNotEmpty
              ? (intakeRows.first['needs_identified'] != null
                  ? (intakeRows.first['needs_identified'] as String)
                      .replaceAll('[', '')
                      .replaceAll(']', '')
                      .split(',')
                      .map((e) => e.trim().replaceAll('"', ''))
                      .where((e) => e.isNotEmpty)
                      .toList()
                  : <String>[])
              : <String>[])));
      developer.log('Needs: $needsRaw → $needs');
    } catch (e) {
      developer.log('Could not parse needs: $e');
    }

    if (!mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(children: [
          CircularProgressIndicator(color: Color(0xFF6A1B9A)),
          SizedBox(width: 20),
          Text('Generating suggestions…'),
        ]),
      ),
    );

    try {
      final aiPrograms = await CaseAiService().generatePrograms(
        presentingSituation: situation,
        needsIdentified: needs,
        additionalContext:
            'This plan already has ${_programs.length} program(s): '
            '${_programs.map((p) => p.programName).join(', ')}. '
            'Only suggest NEW programs not already covered.',
      );

      if (!mounted) return;
      Navigator.pop(context); // close loading dialog

      if (aiPrograms.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No additional programs suggested')),
        );
        return;
      }

      // Show review sheet
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          builder: (ctx, controller) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFF6A1B9A)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('AI Suggested Programs',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 17)),
                          Text('${aiPrograms.length} new program(s) suggested',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.all(16),
                    itemCount: aiPrograms.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final p = aiPrograms[i];
                      final priority = p['priority'] as String? ?? 'medium';
                      final pc = _priorityColor(priority);
                      final actions =
                          (p['actions'] as List<dynamic>? ?? []).cast<String>();
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border(left: BorderSide(color: pc, width: 4)),
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text(p['program_name'] as String? ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color: pc,
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(priority.toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ]),
                            const SizedBox(height: 6),
                            Text(p['goal'] as String? ?? '',
                                style: const TextStyle(
                                    fontSize: 13, height: 1.4)),
                            if (actions.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('${actions.length} actions',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500])),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      16, 8, 16,
                      16 + MediaQuery.of(ctx).viewInsets.bottom),
                  child: Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A1B9A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Add These Programs',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      );

      if (confirmed != true || _plan == null) return;

      final now = DateTime.now();
      final nextNumber = _programs.length + 1;
      for (var i = 0; i < aiPrograms.length; i++) {
        final p = aiPrograms[i];
        final actions = (p['actions'] as List<dynamic>? ?? [])
            .map((a) => ProgramAction(text: a.toString()))
            .toList();
        DateTime? deadlineDate;
        final label = (p['deadline_label'] as String? ?? '').toLowerCase();
        if (label.contains('30 day')) {
          deadlineDate = now.add(const Duration(days: 30));
        } else if (label.contains('2 week')) {
          deadlineDate = now.add(const Duration(days: 14));
        } else if (label.contains('3 month')) {
          deadlineDate = now.add(const Duration(days: 90));
        } else if (label.contains('6 month')) {
          deadlineDate = now.add(const Duration(days: 180));
        }
        final program = CaseProgram(
          id: const Uuid().v4(),
          casePlanId: _plan!.id,
          programNumber: nextNumber + i,
          programName: p['program_name'] as String? ?? 'Program ${nextNumber + i}',
          goal: p['goal'] as String? ?? '',
          currentStatusNotes: p['current_status_notes'] as String? ?? '',
          priority: p['priority'] as String? ?? 'medium',
          deadlineLabel: (p['deadline_label'] as String?)?.isNotEmpty == true
              ? p['deadline_label'] as String : null,
          deadlineDate: deadlineDate,
          actions: actions,
          createdAt: now,
          updatedAt: now,
        );
        await CaseManagementService.createProgram(program);
      }
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${aiPrograms.length} program(s) added'),
            backgroundColor: const Color(0xFF6A1B9A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading dialog if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('AI error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showLinkUserDialog() async {
    if (_plan == null) return;

    // Load all non-anonymous users
    final db = await LocalDatabaseService.database;
    final userRows = await db.query(
      'users',
      where: 'is_anonymous = 0',
      orderBy: 'display_name ASC',
    );
    if (!mounted) return;

    String? selectedUserId;
    final searchCtrl = TextEditingController();
    List<Map<String, dynamic>> filtered = List.from(userRows);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Link to App Account'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search by name or email…',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (q) {
                    final lower = q.toLowerCase();
                    setS(() {
                      filtered = userRows.where((u) {
                        final name = (u['display_name'] as String? ?? '').toLowerCase();
                        final email = (u['email'] as String? ?? '').toLowerCase();
                        return name.contains(lower) || email.contains(lower);
                      }).toList();
                    });
                  },
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: filtered.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No users found',
                              style: TextStyle(color: Colors.grey)),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final u = filtered[i];
                            final uid = u['id'] as String;
                            final name = u['display_name'] as String? ?? uid;
                            final email = u['email'] as String? ?? '';
                            final type = u['user_type'] as String? ?? '';
                            final isSelected = selectedUserId == uid;
                            return InkWell(
                              onTap: () => setS(() => selectedUserId = uid),
                              child: Container(
                                color: isSelected
                                    ? const Color(0xFFE65100).withValues(alpha: 0.08)
                                    : null,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      color: isSelected
                                          ? const Color(0xFFE65100)
                                          : Colors.grey[400],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(name,
                                              style: const TextStyle(
                                                  fontSize: 14)),
                                          Text('$email · $type',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600])),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100)),
              onPressed: selectedUserId == null
                  ? null
                  : () => Navigator.pop(ctx, selectedUserId),
              child: const Text('Link',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    ).then((userId) async {
      if (userId == null || _plan == null) return;
      try {
        await CaseManagementService.linkClientToUser(
          intakeId: _plan!.intakeId,
          planId: _plan!.id,
          userId: userId as String,
        );
        _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('App account linked — they can now see this plan'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        developer.log('Error linking user: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    });
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return const Color(0xFFE65100);
      case 'medium':
        return Colors.amber[700]!;
      case 'monitor':
        return Colors.blue;
      case 'ongoing':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _priorityLabel(String priority) {
    switch (priority) {
      case 'urgent':
        return 'URGENT';
      case 'high':
        return 'HIGH';
      case 'medium':
        return 'MEDIUM';
      case 'monitor':
        return 'MONITOR';
      case 'ongoing':
        return 'ONGOING';
      default:
        return priority.toUpperCase();
    }
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
