import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../models/case_plan.dart';
import '../../services/case_management_service.dart';
import '../case_management/plan_calendar_screen.dart';

/// Read-only view of a client's own support plan.
/// Shown when a CasePlan has client_id matching the logged-in user.
class MySupportPlanScreen extends StatefulWidget {
  final String userId;

  const MySupportPlanScreen({super.key, required this.userId});

  @override
  State<MySupportPlanScreen> createState() => _MySupportPlanScreenState();
}

class _MySupportPlanScreenState extends State<MySupportPlanScreen> {
  CasePlan? _plan;
  List<CaseProgram> _programs = [];
  List<CaseNote> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final plan =
          await CaseManagementService.getCasePlanForUser(widget.userId);
      if (plan != null) {
        final programs =
            await CaseManagementService.getProgramsForPlan(plan.id);
        final notes = await CaseManagementService.getNotesForPlan(plan.id,
            programId: null);
        if (mounted) {
          setState(() {
            _plan = plan;
            _programs = programs;
            _notes = notes;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      developer.log('Error loading support plan: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Support Plan',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFF0562D),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: _plan != null
            ? [
                IconButton(
                  icon: const Icon(Icons.calendar_month, color: Colors.white),
                  tooltip: 'Calendar',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlanCalendarScreen(
                        userId: widget.userId,
                        isAdminView: false,
                      ),
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF0562D)))
          : _plan == null
              ? _buildNoPlan()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFFF0562D),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildProgramsSection(),
                        const SizedBox(height: 20),
                        if (_notes.isNotEmpty) _buildNotesSection(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildNoPlan() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 20),
            const Text(
              'No Active Support Plan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your case manager will set up a personalised support plan for you. Check back after your intake has been completed.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final plan = _plan!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0562D), Color(0xFFFF7043)],
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.folder_special,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Support Plan',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Managed by ${plan.caseManagerName}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (plan.nextReviewDate != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    'Next check-in: ${_fmt(plan.nextReviewDate!)}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
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
        Text(
          '${_programs.length} Active Program${_programs.length == 1 ? '' : 's'}',
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF0562D)),
        ),
        const SizedBox(height: 12),
        ..._programs.map((p) => _buildProgramCard(p)),
      ],
    );
  }

  Widget _buildProgramCard(CaseProgram program) {
    final priorityColor = _priorityColor(program.priority);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 90,
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
                  Text(
                    program.programName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  if (program.goal.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      program.goal,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                  if (program.currentStatusNotes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        program.currentStatusNotes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                  if (program.totalActionCount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: program.completionPercent,
                              backgroundColor: Colors.grey[200],
                              color: program.completionPercent == 1.0
                                  ? Colors.green
                                  : priorityColor,
                              minHeight: 5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${program.completedActionCount}/${program.totalActionCount}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Updates from Your Case Manager',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF0562D)),
        ),
        const SizedBox(height: 12),
        ..._notes.map((note) => Container(
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
                      style:
                          const TextStyle(fontSize: 14, height: 1.4)),
                  const SizedBox(height: 8),
                  Text(
                    _fmt(note.createdAt),
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return const Color(0xFFF0562D);
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

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
