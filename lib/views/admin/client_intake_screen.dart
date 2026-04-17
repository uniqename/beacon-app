import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/user.dart';
import '../../models/client_intake.dart';
import '../../models/case_plan.dart';
import '../../services/ai_consent_service.dart';
import '../../services/app_config_service.dart';
import '../../services/case_ai_service.dart';
import '../../services/case_management_service.dart';
import '../../services/local_database_service.dart';
import 'case_plan_screen.dart';

class ClientIntakeScreen extends StatefulWidget {
  final AppUser user;

  const ClientIntakeScreen({super.key, required this.user});

  @override
  State<ClientIntakeScreen> createState() => _ClientIntakeScreenState();
}

class _ClientIntakeScreenState extends State<ClientIntakeScreen> {
  final _formKey = GlobalKey<FormState>();

  final _clientNameCtrl = TextEditingController();
  final _clientPhoneCtrl = TextEditingController();
  final _situationCtrl = TextEditingController();
  final _emergencyDescCtrl = TextEditingController();
  final _emergencyAmountCtrl = TextEditingController();

  final _selectedNeeds = <String>{};
  static const _needOptions = [
    'Education',
    'Housing',
    'Psychosocial / Counselling',
    'Community & Social Reintegration',
    'Economic / Skills Training',
    'Legal Resources',
    'Safety Planning',
    'Healthcare',
    'Other',
  ];

  DateTime? _nextReviewDate;
  String _reviewFrequency = 'quarterly';
  String _currency = AppConfigService.instance.config.currencyCode;

  List<Map<String, dynamic>> _appUsers = [];
  String? _linkedUserId;

  bool _isSubmitting = false;
  bool _isGeneratingAI = false;

  @override
  void initState() {
    super.initState();
    _loadAppUsers();
  }

  @override
  void dispose() {
    _clientNameCtrl.dispose();
    _clientPhoneCtrl.dispose();
    _situationCtrl.dispose();
    _emergencyDescCtrl.dispose();
    _emergencyAmountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAppUsers() async {
    try {
      final db = await LocalDatabaseService.database;
      final results = await db.query(
        'users',
        where: 'user_type = ? AND is_anonymous = 0',
        whereArgs: ['survivor'],
        orderBy: 'name ASC',
      );
      if (mounted) setState(() => _appUsers = results);
    } catch (e) {
      developer.log('Error loading app users: $e');
    }
  }

  Future<void> _pickReviewDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFE65100)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _nextReviewDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedNeeds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one need'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final now = DateTime.now();
      final intakeId = CaseManagementService.generateId();
      final planId = CaseManagementService.generateId();

      final intake = ClientIntake(
        id: intakeId,
        clientName: _clientNameCtrl.text.trim(),
        clientPhone: _clientPhoneCtrl.text.trim().isEmpty
            ? null
            : _clientPhoneCtrl.text.trim(),
        clientId: _linkedUserId,
        caseManagerId: widget.user.id,
        caseManagerName: widget.user.name,
        intakeDate: now,
        presentingSituation: _situationCtrl.text.trim(),
        needsIdentified: _selectedNeeds.toList(),
        emergencySupportDesc: _emergencyDescCtrl.text.trim().isEmpty
            ? null
            : _emergencyDescCtrl.text.trim(),
        emergencySupportAmount: _emergencyAmountCtrl.text.trim().isEmpty
            ? null
            : double.tryParse(_emergencyAmountCtrl.text.trim()),
        currency: _currency,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      final plan = CasePlan(
        id: planId,
        intakeId: intakeId,
        clientName: _clientNameCtrl.text.trim(),
        clientId: _linkedUserId,
        caseManagerId: widget.user.id,
        caseManagerName: widget.user.name,
        planStatus: 'active',
        nextReviewDate: _nextReviewDate,
        reviewFrequency: _reviewFrequency,
        createdAt: now,
        updatedAt: now,
      );

      await CaseManagementService.createIntake(intake);
      await CaseManagementService.createCasePlan(plan);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CasePlanScreen(casePlanId: planId, adminUser: widget.user),
          ),
        );
      }
    } catch (e) {
      developer.log('Error creating intake: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving intake: $e')),
        );
      }
    }
  }

  Future<void> _generateWithAI() async {
    if (!_formKey.currentState!.validate()) return;
    if (_situationCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please describe the presenting situation first'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    final consented = await AiConsentService.requestConsentIfNeeded(context);
    if (!mounted || !consented) return;

    setState(() => _isGeneratingAI = true);
    try {
      final aiPrograms = await CaseAiService().generatePrograms(
        presentingSituation: _situationCtrl.text.trim(),
        needsIdentified: _selectedNeeds.toList(),
      );

      if (!mounted) return;
      setState(() => _isGeneratingAI = false);

      // Show review sheet — admin confirms before saving
      final confirmed = await _showAIProgramsReview(aiPrograms);
      if (confirmed != true || !mounted) return;

      setState(() => _isSubmitting = true);
      final now = DateTime.now();
      final intakeId = CaseManagementService.generateId();
      final planId = CaseManagementService.generateId();

      final intake = ClientIntake(
        id: intakeId,
        clientName: _clientNameCtrl.text.trim(),
        clientPhone: _clientPhoneCtrl.text.trim().isEmpty
            ? null : _clientPhoneCtrl.text.trim(),
        clientId: _linkedUserId,
        caseManagerId: widget.user.id,
        caseManagerName: widget.user.name,
        intakeDate: now,
        presentingSituation: _situationCtrl.text.trim(),
        needsIdentified: _selectedNeeds.toList(),
        emergencySupportDesc: _emergencyDescCtrl.text.trim().isEmpty
            ? null : _emergencyDescCtrl.text.trim(),
        emergencySupportAmount: _emergencyAmountCtrl.text.trim().isEmpty
            ? null : double.tryParse(_emergencyAmountCtrl.text.trim()),
        currency: _currency,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );

      final plan = CasePlan(
        id: planId,
        intakeId: intakeId,
        clientName: _clientNameCtrl.text.trim(),
        clientId: _linkedUserId,
        caseManagerId: widget.user.id,
        caseManagerName: widget.user.name,
        planStatus: 'active',
        nextReviewDate: _nextReviewDate ?? now.add(const Duration(days: 90)),
        reviewFrequency: _reviewFrequency,
        createdAt: now,
        updatedAt: now,
      );

      await CaseManagementService.createIntake(intake);
      await CaseManagementService.createCasePlan(plan);

      // Save AI-generated programs
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
          casePlanId: planId,
          programNumber: i + 1,
          programName: p['program_name'] as String? ?? 'Program ${i + 1}',
          goal: p['goal'] as String? ?? '',
          currentStatusNotes: p['current_status_notes'] as String? ?? '',
          priority: p['priority'] as String? ?? 'medium',
          deadlineLabel: (p['deadline_label'] as String?)?.isEmpty == false
              ? p['deadline_label'] as String : null,
          deadlineDate: deadlineDate,
          actions: actions,
          createdAt: now,
          updatedAt: now,
        );
        await CaseManagementService.createProgram(program);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CasePlanScreen(casePlanId: planId, adminUser: widget.user),
          ),
        );
      }
    } catch (e) {
      developer.log('AI generation error: $e');
      if (mounted) {
        setState(() { _isGeneratingAI = false; _isSubmitting = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<bool?> _showAIProgramsReview(List<Map<String, dynamic>> programs) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFF6A1B9A)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI-Generated Plan',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 17)),
                          Text('Review programs before saving',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${programs.length} programs',
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6A1B9A),
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  itemCount: programs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final p = programs[i];
                    final priority = p['priority'] as String? ?? 'medium';
                    final priorityColor = _priorityColor(priority);
                    final actions =
                        (p['actions'] as List<dynamic>? ?? []).cast<String>();
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.1),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(
                                    color: priorityColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    p['program_name'] as String? ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: priorityColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    priority.toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['goal'] as String? ?? '',
                                    style: const TextStyle(fontSize: 13, height: 1.4)),
                                if ((p['deadline_label'] as String?)?.isNotEmpty == true) ...[
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    Icon(Icons.schedule,
                                        size: 13, color: Colors.grey[500]),
                                    const SizedBox(width: 4),
                                    Text(p['deadline_label'] as String,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600])),
                                  ]),
                                ],
                                if (actions.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text('${actions.length} actions',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                          fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  ...actions.take(3).map((a) => Padding(
                                        padding: const EdgeInsets.only(top: 3),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('•  ',
                                                style: TextStyle(
                                                    color: Colors.grey[500])),
                                            Expanded(
                                              child: Text(a,
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[700])),
                                            ),
                                          ],
                                        ),
                                      )),
                                  if (actions.length > 3)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 3),
                                      child: Text(
                                        '+ ${actions.length - 3} more',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500]),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    16, 8, 16,
                    16 + MediaQuery.of(context).viewInsets.bottom),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: const Text('Regenerate'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A1B9A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Save This Plan',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'urgent': return Colors.red;
      case 'high':   return const Color(0xFFE65100);
      case 'medium': return Colors.amber[700]!;
      case 'monitor': return Colors.blue;
      default:       return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'New Client Intake',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFE65100),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader('1. Client Information', Icons.person),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clientNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Full name is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clientPhoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (optional)',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              if (_appUsers.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildLinkToAppAccount(),
              ],

              const SizedBox(height: 24),
              _sectionHeader('2. Presenting Situation', Icons.description),
              const SizedBox(height: 12),
              TextFormField(
                controller: _situationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Describe the presenting situation *',
                  hintText: 'Background, key events, current circumstances…',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Please describe the situation'
                    : null,
              ),

              const SizedBox(height: 24),
              _sectionHeader(
                  '3. Needs Identified at Intake', Icons.checklist),
              const SizedBox(height: 4),
              const Text('Select all that apply',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              _buildNeedsChecklist(),

              const SizedBox(height: 24),
              _sectionHeader(
                  '4. Emergency Support Provided', Icons.volunteer_activism),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emergencyDescCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText:
                      'e.g. School tuition GHC 1,900 + Hostel GHC 1,200…',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _emergencyAmountCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Amount (optional)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(),
                      ),
                      items: ['GHC', 'USD', 'GBP', 'EUR']
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _currency = v!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _sectionHeader('5. Case Manager', Icons.manage_accounts),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Color(0xFFE65100)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.user.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        Text('Assigned Case Manager',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _sectionHeader('6. Review Schedule', Icons.event_repeat),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickReviewDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 18, color: Color(0xFFE65100)),
                            const SizedBox(width: 10),
                            Text(
                              _nextReviewDate != null
                                  ? _fmt(_nextReviewDate!)
                                  : 'Next review date',
                              style: TextStyle(
                                color: _nextReviewDate != null
                                    ? Colors.black87
                                    : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _reviewFrequency,
                      decoration: const InputDecoration(
                        labelText: 'Frequency',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'monthly', child: Text('Monthly')),
                        DropdownMenuItem(
                            value: 'quarterly', child: Text('Quarterly')),
                        DropdownMenuItem(
                            value: 'biannual', child: Text('Bi-annual')),
                      ],
                      onChanged: (v) =>
                          setState(() => _reviewFrequency = v!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              // AI-assisted plan generation button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: (_isSubmitting || _isGeneratingAI)
                      ? null
                      : _generateWithAI,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A1B9A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isGeneratingAI
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    _isGeneratingAI
                        ? 'Generating plan…'
                        : 'Save & Generate Plan with AI',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('or', style: TextStyle(color: Colors.grey[500])),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _isSubmitting
                        ? 'Saving…'
                        : 'Save Intake & Open Case Plan',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFE65100), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE65100),
          ),
        ),
      ],
    );
  }

  Widget _buildNeedsChecklist() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: _needOptions.map((need) {
          return CheckboxListTile(
            value: _selectedNeeds.contains(need),
            title: Text(need, style: const TextStyle(fontSize: 14)),
            activeColor: const Color(0xFFE65100),
            dense: true,
            onChanged: (v) => setState(() {
              if (v == true) {
                _selectedNeeds.add(need);
              } else {
                _selectedNeeds.remove(need);
              }
            }),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLinkToAppAccount() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Link to App Account (optional)',
            style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _linkedUserId,
          decoration: InputDecoration(
            hintText: 'Select an existing app user',
            prefixIcon: const Icon(Icons.link),
            border: const OutlineInputBorder(),
            suffixIcon: _linkedUserId != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () =>
                        setState(() => _linkedUserId = null),
                  )
                : null,
          ),
          items: _appUsers
              .map((u) => DropdownMenuItem(
                    value: u['id'] as String,
                    child: Text(u['name'] as String? ?? u['id'] as String),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _linkedUserId = v),
        ),
        if (_linkedUserId != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Client will see their plan in the app',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[700],
                  fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
