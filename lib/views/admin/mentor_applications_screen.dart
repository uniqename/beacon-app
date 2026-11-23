import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/mentor_application_service.dart';

const _orange = Color(0xFFF0562D);

/// Admin list of SheBelongs mentor applications (website, app and paper).
class MentorApplicationsScreen extends StatefulWidget {
  const MentorApplicationsScreen({super.key});

  @override
  State<MentorApplicationsScreen> createState() => _MentorApplicationsScreenState();
}

class _MentorApplicationsScreenState extends State<MentorApplicationsScreen> {
  bool _signedIn = MentorApplicationService.isSignedIn;
  bool _loading = false;
  String? _error;
  String _filter = 'all';
  List<MentorApplication> _items = [];

  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (_signedIn) _load();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await MentorApplicationService.signIn(_email.text, _password.text);
      _signedIn = true;
      _password.clear();
      await _load();
    } catch (e) {
      setState(() {
        _error = 'Sign-in failed. Check the admin email and password.';
        _loading = false;
      });
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await MentorApplicationService.list(status: _filter);
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load applications. You may not be on the admin list.';
        _loading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await MentorApplicationService.signOut();
    setState(() {
      _signedIn = false;
      _items = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SheBelongs Applications'),
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        actions: [
          if (_signedIn)
            IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh', onPressed: _load),
          if (_signedIn)
            IconButton(icon: const Icon(Icons.logout), tooltip: 'Sign out', onPressed: _signOut),
        ],
      ),
      floatingActionButton: _signedIn
          ? FloatingActionButton.extended(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Paper form'),
              onPressed: () async {
                final saved = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const PaperApplicationScreen()),
                );
                if (saved == true) _load();
              },
            )
          : null,
      body: _signedIn ? _buildList() : _buildSignIn(),
    );
  }

  Widget _buildSignIn() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Sign in with your admin account to review mentor applications.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Admin email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                onSubmitted: (_) => _signIn(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _orange, foregroundColor: Colors.white),
                onPressed: _loading ? null : _signIn,
                child: Text(_loading ? 'Signing in...' : 'Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Text('Status: '),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _filter,
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('All')),
                  ...MentorApplicationService.statuses.map(
                    (s) => DropdownMenuItem(value: s, child: Text(s.replaceAll('_', ' '))),
                  ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _filter = v);
                  _load();
                },
              ),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
                  ? const Center(child: Text('No applications yet.'))
                  : ListView.separated(
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final a = _items[i];
                        return ListTile(
                          title: Text(a.fullName),
                          subtitle: Text(
                            '${a.status.replaceAll('_', ' ')} · ${a.source} · '
                            '${a.county ?? a.city ?? ''} · ${_date(a.createdAt)}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            final changed = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(builder: (_) => MentorApplicationDetailScreen(application: a)),
                            );
                            if (changed == true) _load();
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

String _date(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Full view of one application, with status, notes and the paper photo if there is one.
class MentorApplicationDetailScreen extends StatefulWidget {
  final MentorApplication application;
  const MentorApplicationDetailScreen({super.key, required this.application});

  @override
  State<MentorApplicationDetailScreen> createState() => _MentorApplicationDetailScreenState();
}

class _MentorApplicationDetailScreenState extends State<MentorApplicationDetailScreen> {
  late String _status = widget.application.status;
  late final TextEditingController _notes = TextEditingController(text: widget.application.adminNotes ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await MentorApplicationService.updateStatus(widget.application.id, _status, adminNotes: _notes.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save. Try again.')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _viewPaper(String path) async {
    try {
      final url = await MentorApplicationService.paperPhotoUrl(path);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => Dialog(
          child: InteractiveViewer(child: Image.network(url, errorBuilder: (_, __, ___) => const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Could not load the photo.'),
              ))),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the paper photo.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.application;
    return Scaffold(
        appBar: AppBar(
          title: Text(a.fullName),
          backgroundColor: _orange,
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _row('Source', a.source),
            _row('Submitted', _date(a.createdAt)),
            _row('Email', a.email),
            _row('Phone', a.phone),
            _row('City', a.city),
            _row('County', a.county),
            _row('Availability', a.availability),
            _row('21 or older', a.age21Plus ? 'Yes' : 'No'),
            _row('Can commit one school year', a.canCommitOneYear ? 'Yes' : 'No'),
            _row('Background check agreed', a.agreedBackgroundCheck ? 'Yes' : 'No'),
            _row('Code of conduct agreed', a.agreedCodeOfConduct ? 'Yes' : 'No'),
            _row('Experience', a.experience),
            _row('Motivation', a.motivation),
            _row('Reference', a.referenceName),
            _row('Reference contact', a.referenceContact),
            if (a.paperImagePath != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.image_outlined),
                label: const Text('View paper photo'),
                onPressed: () => _viewPaper(a.paperImagePath!),
              ),
            ],
            const Divider(height: 32),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: MentorApplicationService.statuses
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.replaceAll('_', ' '))))
                  .toList(),
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Admin notes', alignLabelWithHint: true),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _orange, foregroundColor: Colors.white),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save'),
            ),
          ],
        ),
    );
  }

  Widget _row(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value),
        ],
      ),
    );
  }
}

/// Typed entry for a paper application. The photo of the paper form is stored
/// with the record, and the admin copies the fields from the photo.
class PaperApplicationScreen extends StatefulWidget {
  const PaperApplicationScreen({super.key});

  @override
  State<PaperApplicationScreen> createState() => _PaperApplicationScreenState();
}

class _PaperApplicationScreenState extends State<PaperApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _experience = TextEditingController();
  final _motivation = TextEditingController();
  final _refName = TextEditingController();
  final _refContact = TextEditingController();
  String? _county;
  String _availability = 'Weekdays';
  bool _age21 = false;
  bool _oneYear = false;
  bool _background = false;
  bool _conduct = false;
  XFile? _photo;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _city, _experience, _motivation, _refName, _refContact]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _photo = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_age21 || !_background || !_conduct) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Only save when the paper form confirms age, background check and code of conduct.'),
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      String? photoPath;
      if (_photo != null) {
        final bytes = await _photo!.readAsBytes();
        final ext = _photo!.name.contains('.') ? _photo!.name.split('.').last.toLowerCase() : 'jpg';
        photoPath = await MentorApplicationService.uploadPaperPhoto(bytes, extension: ext);
      }
      await MentorApplicationService.addPaperApplication({
        'full_name': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'city': _city.text.trim().isEmpty ? null : _city.text.trim(),
        'county': _county,
        'age_21_plus': _age21,
        'availability': _availability,
        'can_commit_one_year': _oneYear,
        'experience': _experience.text.trim().isEmpty ? null : _experience.text.trim(),
        'motivation': _motivation.text.trim().isEmpty ? null : _motivation.text.trim(),
        'reference_name': _refName.text.trim().isEmpty ? null : _refName.text.trim(),
        'reference_contact': _refContact.text.trim().isEmpty ? null : _refContact.text.trim(),
        'agreed_background_check': _background,
        'agreed_code_of_conduct': _conduct,
        'paper_image_path': photoPath,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save the paper application.')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(TextEditingController c, String label, {bool required = false, int lines = 1, TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        maxLines: lines,
        keyboardType: type,
        decoration: InputDecoration(labelText: required ? '$label *' : label, alignLabelWithHint: lines > 1),
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paper application'),
        backgroundColor: _orange,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(_photo == null ? 'Attach photo of the paper form' : 'Photo attached: ${_photo!.name}'),
              onPressed: _pickPhoto,
            ),
            const SizedBox(height: 16),
            _field(_name, 'Full name', required: true),
            _field(_email, 'Email', required: true, type: TextInputType.emailAddress),
            _field(_phone, 'Phone', type: TextInputType.phone),
            _field(_city, 'City'),
            DropdownButtonFormField<String>(
              initialValue: _county,
              decoration: const InputDecoration(labelText: 'County'),
              items: const ['Franklin', 'Fairfield', 'Licking', 'Delaware', 'Other']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _county = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _availability,
              decoration: const InputDecoration(labelText: 'Usual availability'),
              items: const ['Weekdays', 'Weekends', 'Evenings', 'Flexible']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _availability = v ?? _availability),
            ),
            const SizedBox(height: 12),
            _field(_experience, 'Experience', lines: 3),
            _field(_motivation, 'Motivation', lines: 3),
            _field(_refName, 'Reference name'),
            _field(_refContact, 'Reference email or phone'),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _age21,
              onChanged: (v) => setState(() => _age21 = v ?? false),
              title: const Text('Applicant is 21 or older and lives near the program area'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _oneYear,
              onChanged: (v) => setState(() => _oneYear = v ?? false),
              title: const Text('Can commit to at least one school year'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _background,
              onChanged: (v) => setState(() => _background = v ?? false),
              title: const Text('Agreed to background check'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _conduct,
              onChanged: (v) => setState(() => _conduct = v ?? false),
              title: const Text('Agreed to code of conduct and policies'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _orange, foregroundColor: Colors.white),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save application'),
            ),
          ],
        ),
      ),
    );
  }
}
