import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../models/case_plan.dart';
import '../../services/case_management_service.dart';

class CaseProgramDetailScreen extends StatefulWidget {
  final String programId;
  final String casePlanId;
  final bool isAdmin;
  final String? adminName;

  const CaseProgramDetailScreen({
    super.key,
    required this.programId,
    required this.casePlanId,
    this.isAdmin = false,
    this.adminName,
  });

  @override
  State<CaseProgramDetailScreen> createState() =>
      _CaseProgramDetailScreenState();
}

class _CaseProgramDetailScreenState extends State<CaseProgramDetailScreen> {
  CaseProgram? _program;
  List<CaseNote> _notes = [];
  bool _isLoading = true;
  bool _isAddingAction = false;
  final _newActionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _newActionCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final program =
          await CaseManagementService.getProgram(widget.programId);
      final notes = await CaseManagementService.getNotesForPlan(
        widget.casePlanId,
        programId: widget.programId,
      );
      if (mounted) {
        setState(() {
          _program = program;
          _notes = notes;
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error loading program: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _program?.programName ?? 'Program',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _program != null
            ? _priorityColor(_program!.priority)
            : const Color(0xFFE65100),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: widget.isAdmin && _program != null
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  onPressed: _showEditSheet,
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE65100)))
          : _program == null
              ? const Center(child: Text('Program not found'))
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
                        _buildGoalSection(),
                        const SizedBox(height: 20),
                        _buildStatusSection(),
                        const SizedBox(height: 20),
                        _buildActionsSection(),
                        const SizedBox(height: 20),
                        _buildNotesSection(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    final program = _program!;
    final priorityColor = _priorityColor(program.priority);
    final priorityLabel = _priorityLabel(program.priority);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: priorityColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: priorityColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  priorityLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              if (program.deadlineLabel != null)
                Row(
                  children: [
                    Icon(Icons.schedule,
                        size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      program.deadlineLabel!,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
            ],
          ),
          if (program.totalActionCount > 0) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: program.completionPercent,
                      backgroundColor: Colors.grey[200],
                      color: program.isCompleted
                          ? Colors.green
                          : priorityColor,
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${program.completedActionCount}/${program.totalActionCount}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontSize: 13),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalSection() {
    return _section(
      title: 'Goal',
      icon: Icons.flag_outlined,
      child: Text(
        _program!.goal.isEmpty ? 'No goal set yet' : _program!.goal,
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: _program!.goal.isEmpty ? Colors.grey[400] : Colors.black87,
          fontStyle: _program!.goal.isEmpty
              ? FontStyle.italic
              : FontStyle.normal,
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return _section(
      title: 'Current Status',
      icon: Icons.info_outline,
      trailing: widget.isAdmin
          ? TextButton(
              onPressed: _showEditStatusSheet,
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFE65100)),
              child: const Text('Update'),
            )
          : null,
      child: Text(
        _program!.currentStatusNotes.isEmpty
            ? 'No status update yet'
            : _program!.currentStatusNotes,
        style: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: _program!.currentStatusNotes.isEmpty
              ? Colors.grey[400]
              : Colors.black87,
          fontStyle: _program!.currentStatusNotes.isEmpty
              ? FontStyle.italic
              : FontStyle.normal,
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    final program = _program!;
    return _section(
      title: 'Action Items',
      icon: Icons.checklist,
      trailing: widget.isAdmin
          ? TextButton.icon(
              onPressed: () => setState(() => _isAddingAction = true),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFE65100)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (program.actions.isEmpty && !_isAddingAction)
            Text(
              widget.isAdmin
                  ? 'No actions yet — tap "Add" to create action items'
                  : 'No action items yet',
              style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                  fontSize: 13),
            ),
          ...program.actions.asMap().entries.map((entry) {
            final i = entry.key;
            final action = entry.value;
            return _buildActionTile(i, action);
          }),
          if (_isAddingAction) _buildAddActionField(),
        ],
      ),
    );
  }

  Widget _buildActionTile(int index, ProgramAction action) {
    return Dismissible(
      key: Key('action_${_program!.id}_$index'),
      direction: widget.isAdmin
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red[50],
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Remove Action'),
            content: const Text('Remove this action item?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Remove',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        await CaseManagementService.deleteActionFromProgram(
            _program!.id, index);
        _load();
      },
      child: CheckboxListTile(
        value: action.completed,
        onChanged: widget.isAdmin
            ? (v) async {
                await CaseManagementService.toggleAction(
                    _program!.id, index, v ?? false);
                _load();
              }
            : null,
        title: Text(
          action.text,
          style: TextStyle(
            fontSize: 14,
            decoration:
                action.completed ? TextDecoration.lineThrough : null,
            color: action.completed ? Colors.grey[500] : Colors.black87,
          ),
        ),
        subtitle: action.completed && action.completedAt != null
            ? Text(
                'Done ${_fmt(action.completedAt!)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              )
            : null,
        activeColor: const Color(0xFFE65100),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildAddActionField() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _newActionCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Describe the action…',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: (_) => _saveNewAction(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.check_circle,
                color: Color(0xFFE65100)),
            onPressed: _saveNewAction,
          ),
          IconButton(
            icon: Icon(Icons.cancel_outlined, color: Colors.grey[400]),
            onPressed: () => setState(() {
              _isAddingAction = false;
              _newActionCtrl.clear();
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNewAction() async {
    if (_newActionCtrl.text.trim().isEmpty) return;
    await CaseManagementService.addActionToProgram(
        _program!.id, _newActionCtrl.text.trim());
    _newActionCtrl.clear();
    setState(() => _isAddingAction = false);
    _load();
  }

  Widget _buildNotesSection() {
    return _section(
      title: 'Program Notes',
      icon: Icons.notes,
      trailing: widget.isAdmin
          ? TextButton.icon(
              onPressed: _showAddNoteSheet,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFE65100)),
            )
          : null,
      child: _notes.isEmpty
          ? Text(
              'No notes yet',
              style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                  fontSize: 13),
            )
          : Column(
              children: _notes
                  .map((note) => _buildNoteCard(note))
                  .toList(),
            ),
    );
  }

  Widget _buildNoteCard(CaseNote note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(note.noteText,
              style: const TextStyle(fontSize: 14, height: 1.4)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.person_outline, size: 12, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(note.createdBy,
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey[500])),
              const Spacer(),
              Text(_fmt(note.createdAt),
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFFE65100)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFFE65100)),
              ),
              if (trailing != null) ...[
                const Spacer(),
                trailing,
              ],
            ],
          ),
          const Divider(height: 16),
          child,
        ],
      ),
    );
  }

  void _showEditSheet() {
    if (_program == null) return;
    final nameCtrl = TextEditingController(text: _program!.programName);
    final goalCtrl = TextEditingController(text: _program!.goal);
    final deadlineLabelCtrl =
        TextEditingController(text: _program!.deadlineLabel ?? '');
    String selectedPriority = _program!.priority;

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
                const Text('Edit Program',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Program Name',
                    border: OutlineInputBorder(),
                  ),
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
                        value: 'urgent', child: Text('🔴  Urgent')),
                    DropdownMenuItem(
                        value: 'high', child: Text('🟠  High')),
                    DropdownMenuItem(
                        value: 'medium', child: Text('🟡  Medium')),
                    DropdownMenuItem(
                        value: 'monitor', child: Text('🔵  Monitor')),
                    DropdownMenuItem(
                        value: 'ongoing', child: Text('🟢  Ongoing')),
                  ],
                  onChanged: (v) => setSheetState(
                      () => selectedPriority = v ?? selectedPriority),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: deadlineLabelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Deadline Label',
                    hintText: 'e.g. "Within 30 days", "May 2026"',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final nav = Navigator.of(ctx);
                      final updated = _program!.copyWith(
                        programName: nameCtrl.text.trim(),
                        goal: goalCtrl.text.trim(),
                        priority: selectedPriority,
                        deadlineLabel:
                            deadlineLabelCtrl.text.trim().isEmpty
                                ? null
                                : deadlineLabelCtrl.text.trim(),
                      );
                      await CaseManagementService.updateProgram(updated);
                      nav.pop();
                      _load();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Save Changes',
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

  void _showEditStatusSheet() {
    final statusCtrl =
        TextEditingController(text: _program!.currentStatusNotes);
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
            const Text('Update Current Status',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: statusCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText:
                    'Describe the current state of this program…',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final nav = Navigator.of(ctx);
                  final updated = _program!
                      .copyWith(currentStatusNotes: statusCtrl.text.trim());
                  await CaseManagementService.updateProgram(updated);
                  nav.pop();
                  _load();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Save',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
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
            const Text('Add Program Note',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Write your note…',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
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
                    caseProgramId: widget.programId,
                    noteText: noteCtrl.text.trim(),
                    createdBy: widget.adminName ?? 'Admin',
                    createdAt: DateTime.now(),
                  );
                  await CaseManagementService.addNote(note);
                  nav.pop();
                  _load();
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
        return '🔴  URGENT';
      case 'high':
        return '🟠  HIGH';
      case 'medium':
        return '🟡  MEDIUM';
      case 'monitor':
        return '🔵  MONITOR';
      case 'ongoing':
        return '🟢  ONGOING';
      default:
        return priority.toUpperCase();
    }
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
