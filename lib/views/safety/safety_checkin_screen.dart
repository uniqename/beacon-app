import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/notification_service.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const _kBg = Color(0xFF0A0E1A);
const _kCardBg = Color(0xFF141929);
const _kGreen = Color(0xFF00D4AA);
const _kRed = Color(0xFFFF5C7A);
const _kTextPrimary = Color(0xFFEAEADA);
const _kTextSecondary = Color(0xFF8A91A8);
const _kDivider = Color(0xFF1E2640);

// ── Prefs keys ────────────────────────────────────────────────────────────────
const _kLastCheckIn = 'last_checkin';
const _kIntervalHours = 'checkin_interval_hours';
const _kTrustedContacts = 'trusted_contacts';
const _kCheckInHistory = 'checkin_history';

// ── Interval option model ─────────────────────────────────────────────────────
class _IntervalOption {
  final String label;
  final int hours;
  const _IntervalOption(this.label, this.hours);
}

const List<_IntervalOption> _kIntervals = [
  _IntervalOption('Every 4 hours', 4),
  _IntervalOption('Every 8 hours', 8),
  _IntervalOption('Every 12 hours', 12),
  _IntervalOption('Every 24 hours', 24),
  _IntervalOption('Twice daily', 12), // 12 h is the equivalent interval
];

// ── Contact model ─────────────────────────────────────────────────────────────
class _Contact {
  String name;
  String phone;
  _Contact({required this.name, required this.phone});

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone};

  factory _Contact.fromJson(Map<String, dynamic> json) =>
      _Contact(name: json['name'] as String, phone: json['phone'] as String);
}

// ── Screen ────────────────────────────────────────────────────────────────────

class SafetyCheckInScreen extends StatefulWidget {
  const SafetyCheckInScreen({super.key});

  @override
  State<SafetyCheckInScreen> createState() => _SafetyCheckInScreenState();
}

class _SafetyCheckInScreenState extends State<SafetyCheckInScreen> {
  // State
  DateTime? _lastCheckIn;
  int _intervalHours = 12;
  String _intervalLabel = 'Every 12 hours';
  List<_Contact> _contacts = [];
  List<DateTime> _history = [];

  bool _loading = true;

  // ── Lifecycle ───────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    // Rebuild every minute so the countdown timer stays live.
    _startCountdownRefresh();
  }

  void _startCountdownRefresh() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));
      if (!mounted) return false;
      setState(() {});
      return true;
    });
  }

  // ── Prefs I/O ───────────────────────────────────────────────────────────

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final lastRaw = prefs.getString(_kLastCheckIn);
    final intervalHours = prefs.getInt(_kIntervalHours) ?? 12;
    final contactsRaw = prefs.getString(_kTrustedContacts);
    final historyRaw = prefs.getString(_kCheckInHistory);

    final matchedInterval = _kIntervals.firstWhere(
      (o) => o.hours == intervalHours,
      orElse: () => _kIntervals[2],
    );

    List<_Contact> contacts = [];
    if (contactsRaw != null) {
      try {
        final list = jsonDecode(contactsRaw) as List<dynamic>;
        contacts = list
            .map((e) => _Contact.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    List<DateTime> history = [];
    if (historyRaw != null) {
      try {
        final list = jsonDecode(historyRaw) as List<dynamic>;
        history = list
            .map((e) => DateTime.parse(e as String))
            .toList()
          ..sort((a, b) => b.compareTo(a));
        if (history.length > 5) history = history.sublist(0, 5);
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _lastCheckIn = lastRaw != null ? DateTime.tryParse(lastRaw) : null;
        _intervalHours = matchedInterval.hours;
        _intervalLabel = matchedInterval.label;
        _contacts = contacts;
        _history = history;
        _loading = false;
      });
    }
  }

  Future<void> _saveLastCheckIn(DateTime dt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastCheckIn, dt.toIso8601String());
  }

  Future<void> _saveInterval(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kIntervalHours, hours);
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kTrustedContacts,
      jsonEncode(_contacts.map((c) => c.toJson()).toList()),
    );
  }

  Future<void> _saveHistory(List<DateTime> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kCheckInHistory,
      jsonEncode(history.map((d) => d.toIso8601String()).toList()),
    );
  }

  // ── Business logic ──────────────────────────────────────────────────────

  bool get _isOverdue {
    if (_lastCheckIn == null) return false;
    final grace = const Duration(minutes: 30);
    final due = _lastCheckIn!.add(Duration(hours: _intervalHours)).add(grace);
    return DateTime.now().isAfter(due);
  }

  DateTime get _nextDue {
    final base = _lastCheckIn ?? DateTime.now();
    return base.add(Duration(hours: _intervalHours));
  }

  String _formatCountdown() {
    if (_lastCheckIn == null) return 'No check-in recorded yet';
    final diff = _nextDue.difference(DateTime.now());
    if (diff.isNegative) return 'Overdue';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h > 0) return 'Due in ${h}h ${m}m';
    return 'Due in ${m}m';
  }

  Future<void> _checkInNow() async {
    final now = DateTime.now();
    final updatedHistory = [now, ..._history];
    if (updatedHistory.length > 5) {
      updatedHistory.removeRange(5, updatedHistory.length);
    }

    setState(() {
      _lastCheckIn = now;
      _history = updatedHistory;
    });

    await _saveLastCheckIn(now);
    await _saveHistory(updatedHistory);

    // Reschedule next check-in reminder.
    await _scheduleNextCheckIn();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _kGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: const Row(
            children: [
              Icon(Icons.favorite, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Stay safe. We\'re with you.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _scheduleNextCheckIn() async {
    try {
      await NotificationService().cancelCheckIn(1);
      await NotificationService().scheduleCheckIn(
        1,
        'Beacon Safety Check-In',
        _nextDue,
      );
    } catch (_) {
      // Notification service may not be initialised in all environments;
      // silently swallow so the rest of the screen still functions.
    }
  }

  Future<void> _onIntervalChanged(String newLabel) async {
    final option = _kIntervals.firstWhere(
      (o) => o.label == newLabel,
      orElse: () => _kIntervals[2],
    );

    setState(() {
      _intervalLabel = option.label;
      _intervalHours = option.hours;
    });

    await _saveInterval(option.hours);
    await _scheduleNextCheckIn();
  }

  Future<void> _alertContacts() async {
    if (_contacts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: _kRed,
            content: Text('No trusted contacts added yet.'),
          ),
        );
      }
      return;
    }

    int sent = 0;
    for (final contact in _contacts) {
      final uri = Uri.parse(
        'sms:${contact.phone}?body=I%20need%20help%20-%20Beacon%20Safety%20Alert',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        sent++;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: sent > 0 ? _kRed : Colors.grey[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            sent > 0
                ? 'Alert sent to $sent contact${sent == 1 ? '' : 's'}.'
                : 'Could not open SMS app.',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _showAddContactDialog() async {
    if (_contacts.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: _kCardBg,
          content: Text(
            'Maximum 3 trusted contacts allowed.',
            style: TextStyle(color: _kTextPrimary),
          ),
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _kCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Add Trusted Contact',
          style: TextStyle(color: _kTextPrimary, fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                style: const TextStyle(color: _kTextPrimary),
                decoration: _inputDecoration('Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                style: const TextStyle(color: _kTextPrimary),
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('Phone number'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a phone number' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: _kTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop();
                setState(() {
                  _contacts.add(_Contact(
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                  ));
                });
                await _saveContacts();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteContact(int index) async {
    setState(() => _contacts.removeAt(index));
    await _saveContacts();
  }

  // ── Widget helpers ──────────────────────────────────────────────────────

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _kTextSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kGreen),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kRed),
        ),
        filled: true,
        fillColor: const Color(0xFF0D1120),
      );

  String _formatHistoryTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: _kGreen)),
      );
    }

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _kTextPrimary, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Safety Check-In',
          style: TextStyle(
            color: _kTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            if (_isOverdue) _buildOverdueBanner(),
            if (_isOverdue) const SizedBox(height: 16),
            _buildCheckInButton(),
            const SizedBox(height: 24),
            _buildScheduleSection(),
            const SizedBox(height: 24),
            _buildContactsSection(),
            const SizedBox(height: 24),
            _buildAlertButton(),
            const SizedBox(height: 24),
            if (_history.isNotEmpty) _buildHistorySection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Status card ─────────────────────────────────────────────────────────

  Widget _buildStatusCard() {
    final checkedIn = _lastCheckIn != null && !_isOverdue;
    final statusColor = checkedIn ? _kGreen : _kRed;
    final statusText = checkedIn ? 'CHECKED IN ✓' : 'CHECK-IN OVERDUE';
    final statusSub = checkedIn
        ? _formatCountdown()
        : (_lastCheckIn == null
            ? 'Tap the button below to record your first check-in'
            : 'Please check in as soon as possible');

    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withAlpha(77), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withAlpha(40),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: statusColor.withAlpha(31),
              shape: BoxShape.circle,
            ),
            child: Icon(
              checkedIn ? Icons.shield_outlined : Icons.warning_amber_rounded,
              color: statusColor,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusSub,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _kTextSecondary, fontSize: 14),
          ),
          if (_lastCheckIn != null) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Last check-in: ${_formatHistoryTime(_lastCheckIn!)}',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Overdue banner ──────────────────────────────────────────────────────

  Widget _buildOverdueBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _kRed.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kRed.withAlpha(102)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: _kRed, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Your check-in is overdue. Please check in or reach out to someone you trust.',
              style: TextStyle(color: _kRed, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Check-in button ─────────────────────────────────────────────────────

  Widget _buildCheckInButton() {
    return GestureDetector(
      onTap: _checkInNow,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00D4AA), Color(0xFF00B090)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _kGreen.withAlpha(77),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Text(
              "I'm Safe — Check In Now",
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Schedule section ────────────────────────────────────────────────────

  Widget _buildScheduleSection() {
    return _SectionCard(
      title: 'Check-In Schedule',
      icon: Icons.schedule,
      iconColor: _kGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How often do you want to check in?',
            style: TextStyle(color: _kTextSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1120),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kDivider),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _intervalLabel,
                isExpanded: true,
                dropdownColor: const Color(0xFF141929),
                style: const TextStyle(color: _kTextPrimary, fontSize: 15),
                iconEnabledColor: _kGreen,
                items: _kIntervals
                    .map(
                      (o) => DropdownMenuItem<String>(
                        value: o.label,
                        child: Text(o.label),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) _onIntervalChanged(val);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, color: _kTextSecondary, size: 16),
              const SizedBox(width: 6),
              Text(
                _formatCountdown(),
                style: const TextStyle(
                  color: _kTextSecondary,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Contacts section ────────────────────────────────────────────────────

  Widget _buildContactsSection() {
    return _SectionCard(
      title: 'Trusted Contacts',
      icon: Icons.people_outline,
      iconColor: const Color(0xFF7B8FFF),
      trailing: _contacts.length < 3
          ? GestureDetector(
              onTap: _showAddContactDialog,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _kGreen.withAlpha(31),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: _kGreen, size: 20),
              ),
            )
          : null,
      child: _contacts.isEmpty
          ? GestureDetector(
              onTap: _showAddContactDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _kDivider,
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.person_add_alt_1, color: _kTextSecondary, size: 32),
                    SizedBox(height: 8),
                    Text(
                      'Add up to 3 trusted contacts',
                      style: TextStyle(color: _kTextSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: List.generate(_contacts.length, (i) {
                final c = _contacts[i];
                return Container(
                  margin: EdgeInsets.only(bottom: i < _contacts.length - 1 ? 10 : 0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1120),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kDivider),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B8FFF).withAlpha(31),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: Color(0xFF7B8FFF), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.name,
                              style: const TextStyle(
                                color: _kTextPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              c.phone,
                              style: const TextStyle(
                                color: _kTextSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _deleteContact(i),
                        icon: const Icon(Icons.delete_outline,
                            color: _kRed, size: 20),
                        tooltip: 'Remove contact',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              }),
            ),
    );
  }

  // ── Alert button ────────────────────────────────────────────────────────

  Widget _buildAlertButton() {
    return GestureDetector(
      onTap: _alertContacts,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: _kRed.withAlpha(26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kRed.withAlpha(128), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _kRed.withAlpha(46),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_rounded, color: _kRed, size: 24),
            SizedBox(width: 10),
            Text(
              'Alert My Contacts',
              style: TextStyle(
                color: _kRed,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── History section ─────────────────────────────────────────────────────

  Widget _buildHistorySection() {
    return _SectionCard(
      title: 'Recent Check-Ins',
      icon: Icons.history,
      iconColor: _kTextSecondary,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _history.map((dt) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _kGreen.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kGreen.withAlpha(60)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: _kGreen, size: 14),
                const SizedBox(width: 5),
                Text(
                  _formatHistoryTime(dt),
                  style: const TextStyle(
                    color: _kGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Reusable section card widget ──────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kDivider),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: _kTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
