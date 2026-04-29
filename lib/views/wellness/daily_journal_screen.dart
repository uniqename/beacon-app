import 'package:flutter/material.dart';
import '../../services/local_database_service.dart';
import 'package:intl/intl.dart';

class DailyJournalScreen extends StatefulWidget {
  final String userId;

  const DailyJournalScreen({super.key, required this.userId});

  @override
  State<DailyJournalScreen> createState() => _DailyJournalScreenState();
}

class _DailyJournalScreenState extends State<DailyJournalScreen> {
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    try {
      final entries = await LocalDatabaseService.getJournalEntries(widget.userId, days: 90);
      if (mounted) {
        setState(() {
          _entries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Reflection Journal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo[600],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : _entries.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _entries.length,
                  itemBuilder: (context, i) => _buildEntryCard(_entries[i]),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        backgroundColor: Colors.indigo[600],
        icon: const Icon(Icons.edit),
        label: const Text('New Entry'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_stories, size: 80, color: Colors.indigo[200]),
            const SizedBox(height: 24),
            const Text(
              'Your Journal',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'A private space for your thoughts and feelings. Journaling helps process emotions '
              'and track your healing journey.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => _openEditor(context),
              icon: const Icon(Icons.edit),
              label: const Text('Write Your First Entry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCard(Map<String, dynamic> entry) {
    final date = entry['date'] as String? ?? '';
    final title = entry['title'] as String? ?? 'Untitled';
    final content = entry['content'] as String? ?? '';
    final moodBefore = entry['mood_before'] as int? ?? 5;
    final moodAfter = entry['mood_after'] as int? ?? 5;
    final hasVoice = (entry['has_voice_note'] as int? ?? 0) == 1;

    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(date);
    } catch (_) {}

    final displayDate = parsedDate != null
        ? DateFormat('EEEE, MMMM d').format(parsedDate)
        : date;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openViewer(context, entry),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasVoice) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.mic, size: 16, color: Colors.indigo),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                displayDate,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 8),
              Text(
                content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _moodChip('Before', moodBefore, Colors.orange),
                  const SizedBox(width: 8),
                  _moodChip('After', moodAfter, Colors.green),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: Colors.red[300],
                    onPressed: () => _confirmDelete(entry['id'] as String),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moodChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          const SizedBox(width: 4),
          Text('$value/10', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  void _openEditor(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _JournalEditorScreen(userId: widget.userId)),
    );
    _loadEntries();
  }

  void _openViewer(BuildContext context, Map<String, dynamic> entry) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _JournalViewerScreen(entry: entry)),
    );
    _loadEntries();
  }

  Future<void> _confirmDelete(String entryId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this journal entry? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await LocalDatabaseService.deleteJournalEntry(entryId);
      _loadEntries();
    }
  }
}

// ─── Journal Editor ───────────────────────────────────────────────────────────

class _JournalEditorScreen extends StatefulWidget {
  final String userId;

  const _JournalEditorScreen({required this.userId});

  @override
  State<_JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends State<_JournalEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  int _moodBefore = 5;
  int _moodAfter = 5;
  bool _isSaving = false;
  bool _contentStarted = false;

  static const List<String> _prompts = [
    'What are 3 things you\'re grateful for today?',
    'What was the hardest part of today, and how did you handle it?',
    'What is one kind thing you did for yourself today?',
    'What emotions came up today? Where did you feel them in your body?',
    'What would you tell a dear friend going through what you\'re experiencing?',
    'What is one small step you took toward healing today?',
    'What boundaries did you honor today?',
    'What brought you even a small moment of peace or joy today?',
    'What do you need to let go of to sleep well tonight?',
    'What are you most proud of yourself for this week?',
  ];

  String get _todayPrompt {
    final day = DateTime.now().day;
    return _prompts[day % _prompts.length];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something before saving')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final title = _titleController.text.trim().isEmpty
          ? DateFormat('MMMM d, y').format(DateTime.now())
          : _titleController.text.trim();

      await LocalDatabaseService.saveJournalEntry(
        userId: widget.userId,
        title: title,
        content: content,
        moodBefore: _moodBefore,
        moodAfter: _moodAfter,
      );
      await LocalDatabaseService.updateStreak(widget.userId);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journal entry saved'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('New Entry', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo[600],
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mood before
            const Text('How are you feeling right now? (Before)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _moodSlider(_moodBefore, (v) => setState(() => _moodBefore = v), Colors.orange),
            const SizedBox(height: 20),

            // Today's prompt
            if (!_contentStarted) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.indigo[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.indigo[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.indigo[400], size: 18),
                        const SizedBox(width: 8),
                        Text('Today\'s Prompt', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo[600])),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_todayPrompt, style: TextStyle(fontSize: 14, color: Colors.indigo[800], fontStyle: FontStyle.italic)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        _contentController.text = '';
                        setState(() => _contentStarted = true);
                      },
                      child: const Text('Use this prompt'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Title field
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Title (optional)',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            // Content field
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                hintText: 'Write freely here. This is your private space...',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 12,
              onChanged: (_) {
                if (!_contentStarted) setState(() => _contentStarted = true);
              },
            ),
            const SizedBox(height: 20),

            // Mood after
            const Text('How do you feel after writing? (After)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _moodSlider(_moodAfter, (v) => setState(() => _moodAfter = v), Colors.green),
            const SizedBox(height: 32),

            // Privacy note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, size: 16, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your journal is stored privately on this device only.',
                      style: TextStyle(fontSize: 12, color: Colors.green[700]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _moodSlider(int value, ValueChanged<int> onChanged, Color color) {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.sentiment_very_dissatisfied, color: Colors.red, size: 20),
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: color,
                label: '$value',
                onChanged: (v) => onChanged(v.toInt()),
              ),
            ),
            const Icon(Icons.sentiment_very_satisfied, color: Colors.green, size: 20),
          ],
        ),
        Center(
          child: Text(
            '$value/10',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }
}

// ─── Journal Viewer ───────────────────────────────────────────────────────────

class _JournalViewerScreen extends StatelessWidget {
  final Map<String, dynamic> entry;

  const _JournalViewerScreen({required this.entry});

  @override
  Widget build(BuildContext context) {
    final title = entry['title'] as String? ?? 'Untitled';
    final content = entry['content'] as String? ?? '';
    final date = entry['date'] as String? ?? '';
    final moodBefore = entry['mood_before'] as int? ?? 5;
    final moodAfter = entry['mood_after'] as int? ?? 5;

    DateTime? parsedDate;
    try { parsedDate = DateTime.parse(date); } catch (_) {}
    final displayDate = parsedDate != null ? DateFormat('EEEE, MMMM d, y').format(parsedDate) : date;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Journal Entry', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo[600],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(displayDate, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                _moodBadge('Before', moodBefore, Colors.orange),
                const SizedBox(width: 12),
                _moodBadge('After', moodAfter, Colors.green),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(content, style: const TextStyle(fontSize: 15, height: 1.6)),
          ],
        ),
      ),
    );
  }

  Widget _moodBadge(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label mood: ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Text('$value/10', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        ],
      ),
    );
  }
}
