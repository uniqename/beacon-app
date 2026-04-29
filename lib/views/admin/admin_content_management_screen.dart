import 'dart:developer' as developer;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../services/local_database_service.dart';

/// Admin Content Management Screen
///
/// Unified CRUD interface for all app content:
/// Jobs, Events, Devotionals, Shelters, Volunteer Shifts,
/// Peer Mentors, Bible Verses, Service Providers, Quizzes, Resources
class AdminContentManagementScreen extends StatefulWidget {
  const AdminContentManagementScreen({super.key});

  @override
  State<AdminContentManagementScreen> createState() =>
      _AdminContentManagementScreenState();
}

class _AdminContentManagementScreenState
    extends State<AdminContentManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color _primary = Color(0xFFF0562D);

  final List<_ContentSection> _sections = const [
    _ContentSection('Jobs', Icons.work_outline, 'job_postings'),
    _ContentSection('Events', Icons.event, 'events'),
    _ContentSection('Devotionals', Icons.menu_book, 'devotionals'),
    _ContentSection('Volunteer Shifts', Icons.volunteer_activism, 'volunteer_shifts_v2'),
    _ContentSection('Peer Mentors', Icons.people, 'peer_mentors_v2'),
    _ContentSection('Shelters', Icons.home_outlined, 'shelters'),
    _ContentSection('Services', Icons.local_hospital_outlined, 'service_providers'),
    _ContentSection('Bible Verses', Icons.book, 'bible_verses'),
    _ContentSection('Quizzes', Icons.quiz_outlined, 'quizzes'),
    _ContentSection('Resources', Icons.folder_outlined, 'resources'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _sections.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Content Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: _sections
              .map((s) => Tab(icon: Icon(s.icon, size: 18), text: s.label))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _sections
            .map((s) => _ContentListTab(section: s))
            .toList(),
      ),
    );
  }
}

class _ContentSection {
  final String label;
  final IconData icon;
  final String table;
  const _ContentSection(this.label, this.icon, this.table);
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic content list tab — shows items from any content table
// ─────────────────────────────────────────────────────────────────────────────
class _ContentListTab extends StatefulWidget {
  final _ContentSection section;
  const _ContentListTab({required this.section});

  @override
  State<_ContentListTab> createState() => _ContentListTabState();
}

class _ContentListTabState extends State<_ContentListTab>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  static const Color _primary = Color(0xFFF0562D);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db = await LocalDatabaseService.database;
      final rows = await db.query(
        widget.section.table,
        orderBy: _orderColumn,
      );
      if (mounted) {
        setState(() {
          _items = rows;
          _loading = false;
        });
      }
    } catch (e) {
      developer.log('AdminContent: Error loading ${widget.section.table}: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _orderColumn {
    switch (widget.section.table) {
      case 'job_postings':
        return 'posted_at DESC';
      case 'events':
        return 'event_date ASC';
      case 'devotionals':
        return 'published_at DESC';
      case 'volunteer_shifts_v2':
        return 'shift_date ASC';
      case 'bible_verses':
        return 'rowid DESC';
      default:
        return 'rowid DESC';
    }
  }

  String _getTitle(Map<String, dynamic> item) {
    final title = item['title']?.toString();
    if (title != null && title.isNotEmpty) return title;
    final name = item['name']?.toString();
    if (name != null && name.isNotEmpty) return name;
    final verse = item['verse']?.toString();
    if (verse != null && verse.isNotEmpty) {
      return verse.length > 40 ? '${verse.substring(0, 40)}…' : verse;
    }
    return item['id']?.toString() ?? '—';
  }

  String _getSubtitle(Map<String, dynamic> item) {
    switch (widget.section.table) {
      case 'job_postings':
        return '${item['type'] ?? ''} · ${item['location'] ?? ''}';
      case 'events':
        return item['event_date']?.toString().substring(0, 10) ?? '';
      case 'devotionals':
        return item['scripture']?.toString() ?? '';
      case 'volunteer_shifts_v2':
        return '${item['shift_date'] ?? ''} ${item['start_time'] ?? ''}–${item['end_time'] ?? ''}';
      case 'peer_mentors_v2':
        return item['specialization']?.toString() ?? '';
      case 'shelters':
        return item['city']?.toString() ?? item['address']?.toString() ?? '';
      case 'service_providers':
        return item['type']?.toString() ?? '';
      case 'bible_verses':
        return item['reference']?.toString() ?? '';
      case 'quizzes':
        return item['category']?.toString() ?? '';
      case 'resources':
        return item['category']?.toString() ?? '';
      default:
        return '';
    }
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final db = await LocalDatabaseService.database;
      await db.delete(widget.section.table, where: 'id = ?', whereArgs: [id]);
      _load();
    }
  }

  void _openForm([Map<String, dynamic>? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContentFormSheet(
        section: widget.section,
        existing: existing,
        onSaved: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.section.icon, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'No ${widget.section.label} yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add),
                    label: Text('Add ${widget.section.label}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final item = _items[i];
                  final id = item['id']?.toString() ?? '';
                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                      leading: CircleAvatar(
                        backgroundColor: _primary.withValues(alpha: 0.1),
                        child: Icon(widget.section.icon,
                            color: _primary, size: 20),
                      ),
                      title: Text(
                        _getTitle(item),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        _getSubtitle(item),
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: Color(0xFFF0562D)),
                            onPressed: () => _openForm(item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () => _delete(id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Add ${widget.section.label}'),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form sheet — fields adapt to the content type
// ─────────────────────────────────────────────────────────────────────────────
class _ContentFormSheet extends StatefulWidget {
  final _ContentSection section;
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;

  const _ContentFormSheet({
    required this.section,
    required this.onSaved,
    this.existing,
  });

  @override
  State<_ContentFormSheet> createState() => _ContentFormSheetState();
}

class _ContentFormSheetState extends State<_ContentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  // Shared controllers
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // Section-specific
  final _typeCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _timeStartCtrl = TextEditingController();
  final _timeEndCtrl = TextEditingController();
  final _scriptureCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _verseCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _specializationCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  bool _isActive = true;
  bool _isRemote = false;
  bool _isUrgent = false;
  bool _isOnline = false;
  bool _isAvailable = true;

  static const Color _primary = Color(0xFFF0562D);

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  void _prefill() {
    final e = widget.existing;
    if (e == null) return;
    _titleCtrl.text = e['title']?.toString() ?? '';
    _descCtrl.text = e['description']?.toString() ??
        e['content']?.toString() ?? '';
    _locationCtrl.text = e['location']?.toString() ??
        e['address']?.toString() ?? '';
    _phoneCtrl.text = e['phone']?.toString() ??
        e['contact_phone']?.toString() ?? '';
    _emailCtrl.text = e['email']?.toString() ??
        e['application_email']?.toString() ??
        e['contact_email']?.toString() ?? '';
    _typeCtrl.text = e['type']?.toString() ?? '';
    _dateCtrl.text = e['event_date']?.toString() ??
        e['shift_date']?.toString() ??
        e['published_at']?.toString() ??
        e['display_date']?.toString() ?? '';
    _timeStartCtrl.text = e['start_time']?.toString() ?? '';
    _timeEndCtrl.text = e['end_time']?.toString() ?? '';
    _scriptureCtrl.text = e['scripture']?.toString() ?? '';
    _authorCtrl.text = e['author']?.toString() ??
        e['name']?.toString() ?? '';
    _verseCtrl.text = e['verse']?.toString() ?? '';
    _referenceCtrl.text = e['reference']?.toString() ?? '';
    _categoryCtrl.text = e['category']?.toString() ?? '';
    _specializationCtrl.text = e['specialization']?.toString() ?? '';
    _hoursCtrl.text = e['hours']?.toString() ?? '';
    _isActive = (e['is_active'] as int?) != 0;
    _isRemote = (e['is_remote'] as int?) == 1;
    _isUrgent = (e['is_urgent'] as int?) == 1;
    _isOnline = (e['is_online'] as int?) == 1;
    _isAvailable = (e['is_available'] as int?) != 0;
  }

  @override
  void dispose() {
    for (final c in [
      _titleCtrl, _descCtrl, _locationCtrl, _phoneCtrl, _emailCtrl,
      _typeCtrl, _dateCtrl, _timeStartCtrl, _timeEndCtrl, _scriptureCtrl,
      _authorCtrl, _verseCtrl, _referenceCtrl, _categoryCtrl,
      _specializationCtrl, _hoursCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final db = await LocalDatabaseService.database;
      final id = widget.existing?['id']?.toString() ?? const Uuid().v4();
      final now = DateTime.now().toIso8601String();

      final Map<String, dynamic> data = {'id': id};

      switch (widget.section.table) {
        case 'job_postings':
          data.addAll({
            'title': _titleCtrl.text.trim(),
            'type': _typeCtrl.text.trim().isEmpty ? 'volunteer' : _typeCtrl.text.trim(),
            'description': _descCtrl.text.trim(),
            'location': _locationCtrl.text.trim(),
            'application_email': _emailCtrl.text.trim(),
            'is_remote': _isRemote ? 1 : 0,
            'is_urgent': _isUrgent ? 1 : 0,
            'posted_at': now,
            'is_active': _isActive ? 1 : 0,
          });
          break;

        case 'events':
          data.addAll({
            'title': _titleCtrl.text.trim(),
            'description': _descCtrl.text.trim(),
            'event_date': _dateCtrl.text.trim(),
            'location': _locationCtrl.text.trim(),
            'is_online': _isOnline ? 1 : 0,
            'created_at': now,
            'is_active': _isActive ? 1 : 0,
          });
          break;

        case 'devotionals':
          data.addAll({
            'title': _titleCtrl.text.trim(),
            'content': _descCtrl.text.trim(),
            'scripture': _scriptureCtrl.text.trim(),
            'author': _authorCtrl.text.trim(),
            'published_at': now,
            'is_active': _isActive ? 1 : 0,
          });
          break;

        case 'volunteer_shifts_v2':
          data.addAll({
            'title': _titleCtrl.text.trim(),
            'description': _descCtrl.text.trim(),
            'shift_date': _dateCtrl.text.trim(),
            'start_time': _timeStartCtrl.text.trim(),
            'end_time': _timeEndCtrl.text.trim(),
            'location': _locationCtrl.text.trim(),
            'is_active': _isActive ? 1 : 0,
          });
          break;

        case 'peer_mentors_v2':
          data.addAll({
            'name': _authorCtrl.text.trim(),
            'bio': _descCtrl.text.trim(),
            'specialization': _specializationCtrl.text.trim(),
            'contact_email': _emailCtrl.text.trim(),
            'contact_phone': _phoneCtrl.text.trim(),
            'is_available': _isAvailable ? 1 : 0,
            'created_at': now,
          });
          break;

        case 'shelters':
          data.addAll({
            'name': _titleCtrl.text.trim(),
            'address': _locationCtrl.text.trim(),
            'city': _typeCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'services': _descCtrl.text.trim(),
            'is_active': _isActive ? 1 : 0,
          });
          break;

        case 'service_providers':
          data.addAll({
            'name': _titleCtrl.text.trim(),
            'type': _typeCtrl.text.trim(),
            'description': _descCtrl.text.trim(),
            'address': _locationCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'hours': _hoursCtrl.text.trim(),
            'is_active': _isActive ? 1 : 0,
          });
          break;

        case 'bible_verses':
          data.addAll({
            'verse': _verseCtrl.text.trim(),
            'reference': _referenceCtrl.text.trim(),
            'category': _categoryCtrl.text.trim(),
            'display_date': _dateCtrl.text.trim(),
            'is_active': _isActive ? 1 : 0,
          });
          break;

        case 'quizzes':
          data.addAll({
            'title': _titleCtrl.text.trim(),
            'description': _descCtrl.text.trim(),
            'category': _categoryCtrl.text.trim(),
            'questions': jsonEncode([]),
            'created_at': now,
            'is_active': _isActive ? 1 : 0,
          });
          break;

        case 'resources':
          data.addAll({
            'title': _titleCtrl.text.trim(),
            'description': _descCtrl.text.trim(),
            'category': _categoryCtrl.text.trim(),
          });
          break;
      }

      if (widget.existing != null) {
        data.remove('id');
        await db.update(
          widget.section.table, data,
          where: 'id = ?',
          whereArgs: [id],
        );
      } else {
        await db.insert(widget.section.table, data);
      }

      widget.onSaved();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.existing != null
              ? '${widget.section.label} updated'
              : '${widget.section.label} added'),
          backgroundColor: _primary,
        ));
      }
    } catch (e) {
      developer.log('AdminContent: Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error saving: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Icon(widget.section.icon, color: _primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.existing != null
                          ? 'Edit ${widget.section.label}'
                          : 'Add ${widget.section.label}',
                      style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Form
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildFields(),
                  ),
                ),
              ),
            ),
            // Save button
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            widget.existing != null ? 'Save Changes' : 'Add Item',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFields() {
    switch (widget.section.table) {
      case 'job_postings':
        return [
          _field('Job Title *', _titleCtrl, required: true),
          _field('Type (volunteer / part-time / full-time)', _typeCtrl),
          _field('Description', _descCtrl, maxLines: 4),
          _field('Location', _locationCtrl),
          _field('Application Email', _emailCtrl,
              keyboardType: TextInputType.emailAddress),
          _toggle('Remote?', _isRemote, (v) => setState(() => _isRemote = v)),
          _toggle('Urgent?', _isUrgent, (v) => setState(() => _isUrgent = v)),
          _toggle('Active', _isActive, (v) => setState(() => _isActive = v)),
        ];

      case 'events':
        return [
          _field('Event Title *', _titleCtrl, required: true),
          _field('Description', _descCtrl, maxLines: 4),
          _field('Date & Time (YYYY-MM-DD HH:MM)', _dateCtrl),
          _field('Location / Venue', _locationCtrl),
          _toggle('Online Event?', _isOnline,
              (v) => setState(() => _isOnline = v)),
          _toggle('Active', _isActive, (v) => setState(() => _isActive = v)),
        ];

      case 'devotionals':
        return [
          _field('Title *', _titleCtrl, required: true),
          _field('Content / Message', _descCtrl, maxLines: 6),
          _field('Scripture Reference', _scriptureCtrl),
          _field('Author', _authorCtrl),
          _toggle('Active', _isActive, (v) => setState(() => _isActive = v)),
        ];

      case 'volunteer_shifts_v2':
        return [
          _field('Shift Title *', _titleCtrl, required: true),
          _field('Description', _descCtrl, maxLines: 3),
          _field('Date (YYYY-MM-DD)', _dateCtrl),
          _field('Start Time (HH:MM)', _timeStartCtrl),
          _field('End Time (HH:MM)', _timeEndCtrl),
          _field('Location', _locationCtrl),
          _toggle('Active', _isActive, (v) => setState(() => _isActive = v)),
        ];

      case 'peer_mentors_v2':
        return [
          _field('Mentor Name *', _authorCtrl, required: true),
          _field('Bio', _descCtrl, maxLines: 4),
          _field('Specialization (e.g. Trauma, Finance)', _specializationCtrl),
          _field('Email', _emailCtrl, keyboardType: TextInputType.emailAddress),
          _field('Phone', _phoneCtrl, keyboardType: TextInputType.phone),
          _toggle('Available?', _isAvailable,
              (v) => setState(() => _isAvailable = v)),
        ];

      case 'shelters':
        return [
          _field('Shelter Name *', _titleCtrl, required: true),
          _field('City', _typeCtrl),
          _field('Address', _locationCtrl),
          _field('Phone', _phoneCtrl, keyboardType: TextInputType.phone),
          _field('Services Offered', _descCtrl, maxLines: 3),
          _toggle('Active', _isActive, (v) => setState(() => _isActive = v)),
        ];

      case 'service_providers':
        return [
          _field('Organization Name *', _titleCtrl, required: true),
          _field('Type (counseling / legal / medical / partner)', _typeCtrl),
          _field('Description', _descCtrl, maxLines: 3),
          _field('Address', _locationCtrl),
          _field('Phone', _phoneCtrl, keyboardType: TextInputType.phone),
          _field('Email', _emailCtrl, keyboardType: TextInputType.emailAddress),
          _field('Operating Hours', _hoursCtrl),
          _toggle('Active', _isActive, (v) => setState(() => _isActive = v)),
        ];

      case 'bible_verses':
        return [
          _field('Verse Text *', _verseCtrl, required: true, maxLines: 5),
          _field('Reference (e.g. John 3:16)', _referenceCtrl),
          _field('Category', _categoryCtrl),
          _field('Display Date (YYYY-MM-DD, optional)', _dateCtrl),
          _toggle('Active', _isActive, (v) => setState(() => _isActive = v)),
        ];

      case 'quizzes':
        return [
          _field('Quiz Title *', _titleCtrl, required: true),
          _field('Description', _descCtrl, maxLines: 3),
          _field('Category', _categoryCtrl),
          _toggle('Active', _isActive, (v) => setState(() => _isActive = v)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Note: After saving the quiz, tap Edit to add questions.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ];

      case 'resources':
        return [
          _field('Title *', _titleCtrl, required: true),
          _field('Description', _descCtrl, maxLines: 3),
          _field('Category', _categoryCtrl),
        ];

      default:
        return [
          _field('Title *', _titleCtrl, required: true),
          _field('Description', _descCtrl, maxLines: 3),
        ];
    }
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFF0562D), width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        value: value,
        activeThumbColor: const Color(0xFFF0562D),
        onChanged: onChanged,
      ),
    );
  }
}
