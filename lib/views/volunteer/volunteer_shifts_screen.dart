import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class VolunteerShift {
  final String id;
  final String title;
  final String date;
  final String startTime;
  final String endTime;
  final String type; // chat | prayer | phone | in-person
  final int spotsTotal;
  List<String> claimedBy;
  final String description;

  VolunteerShift({
    required this.id,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.spotsTotal,
    required this.claimedBy,
    required this.description,
  });

  int get spotsTaken => claimedBy.length;
  int get spotsRemaining => spotsTotal - spotsTaken;
  bool get isFull => spotsRemaining <= 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
        'type': type,
        'spotsTotal': spotsTotal,
        'claimedBy': claimedBy,
        'description': description,
      };

  factory VolunteerShift.fromJson(Map<String, dynamic> json) => VolunteerShift(
        id: json['id'] as String,
        title: json['title'] as String,
        date: json['date'] as String,
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
        type: json['type'] as String,
        spotsTotal: json['spotsTotal'] as int,
        claimedBy: List<String>.from(json['claimedBy'] as List),
        description: json['description'] as String,
      );
}

// ---------------------------------------------------------------------------
// Seed data
// ---------------------------------------------------------------------------

List<VolunteerShift> _buildSeedShifts() => [
      VolunteerShift(
        id: 'shift_001',
        title: 'Evening Chat Support',
        date: 'Mon / Wed / Fri',
        startTime: '7:00 PM',
        endTime: '9:00 PM',
        type: 'chat',
        spotsTotal: 3,
        claimedBy: [],
        description:
            'Provide compassionate text-based support to individuals reaching out during evening hours. Training provided for all volunteers.',
      ),
      VolunteerShift(
        id: 'shift_002',
        title: 'Prayer Line',
        date: 'Daily',
        startTime: '6:00 AM',
        endTime: '8:00 AM',
        type: 'prayer',
        spotsTotal: 2,
        claimedBy: [],
        description:
            'Offer prayer and spiritual encouragement to callers seeking strength at the start of their day. Open to all faith backgrounds.',
      ),
      VolunteerShift(
        id: 'shift_003',
        title: 'Crisis Phone Line',
        date: 'Weekends',
        startTime: '8:00 PM',
        endTime: '12:00 AM',
        type: 'phone',
        spotsTotal: 4,
        claimedBy: [],
        description:
            'Staff our crisis support phone line during peak weekend hours. Crisis intervention training required — we will help you get certified.',
      ),
      VolunteerShift(
        id: 'shift_004',
        title: 'In-Person Drop-In',
        date: 'Saturdays',
        startTime: '10:00 AM',
        endTime: '2:00 PM',
        type: 'in-person',
        spotsTotal: 3,
        claimedBy: [],
        description:
            'Welcome and assist clients at our Saturday drop-in center. Help with intake forms, refreshments, and connecting guests to resources.',
      ),
      VolunteerShift(
        id: 'shift_005',
        title: 'Overnight Chat Monitor',
        date: 'Fri / Sat',
        startTime: '10:00 PM',
        endTime: '2:00 AM',
        type: 'chat',
        spotsTotal: 2,
        claimedBy: [],
        description:
            'Monitor our overnight chat queue and respond to messages from those who reach out during late-night hours when support is scarce.',
      ),
      VolunteerShift(
        id: 'shift_006',
        title: 'Legal Advice Intake',
        date: 'Tuesdays',
        startTime: '2:00 PM',
        endTime: '5:00 PM',
        type: 'in-person',
        spotsTotal: 2,
        claimedBy: [],
        description:
            'Assist our partnered legal team by greeting clients, completing intake paperwork, and preparing case summaries before attorney consultations.',
      ),
    ];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class VolunteerShiftsScreen extends StatefulWidget {
  final String userId;

  const VolunteerShiftsScreen({super.key, required this.userId});

  @override
  State<VolunteerShiftsScreen> createState() => _VolunteerShiftsScreenState();
}

class _VolunteerShiftsScreenState extends State<VolunteerShiftsScreen>
    with TickerProviderStateMixin {
  // ── Colors ──────────────────────────────────────────────────────────────
  static const Color _bg = Color(0xFF0A0E1A);
  static const Color _card = Color(0xFF141929);
  static const Color _accent = Color(0xFF00D4AA);
  static const Color _gold = Color(0xFFFFB347);
  static const Color _red = Color(0xFFFF5C7A);
  // ignore: unused_field
  static const Color _purple = Color(0xFF9B59B6);
  static const Color _blue = Color(0xFF3B82F6);

  // ── State ────────────────────────────────────────────────────────────────
  List<VolunteerShift> _shifts = [];
  bool _isLoading = true;
  late TabController _tabController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ── Keys ─────────────────────────────────────────────────────────────────
  static const String _shiftsKey = 'volunteer_shifts';
  // Per-user key stored alongside the shared shifts list so the spec's
  // 'my_claimed_shifts_$userId' key is written to prefs as a mirror.
  String get _myShiftsKey => 'my_claimed_shifts_${widget.userId}';

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.4, end: 1.0).animate(_pulseController);
    _loadShifts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────
  Future<void> _loadShifts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_shiftsKey);

    List<VolunteerShift> loaded;
    if (raw == null || raw.isEmpty) {
      loaded = _buildSeedShifts();
      await _persistShifts(loaded, prefs);
    } else {
      final decoded = jsonDecode(raw) as List;
      loaded = decoded
          .map((e) => VolunteerShift.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    if (mounted) {
      setState(() {
        _shifts = loaded;
        _isLoading = false;
      });
    }
  }

  Future<void> _persistShifts(List<VolunteerShift> shifts,
      [SharedPreferences? existing]) async {
    final prefs = existing ?? await SharedPreferences.getInstance();
    final encoded = jsonEncode(shifts.map((s) => s.toJson()).toList());
    await prefs.setString(_shiftsKey, encoded);
    // Mirror the IDs of this user's claimed shifts under the per-user key.
    final myIds = shifts
        .where((s) => s.claimedBy.contains(widget.userId))
        .map((s) => s.id)
        .toList();
    await prefs.setString(_myShiftsKey, jsonEncode(myIds));
  }

  Future<void> _claimShift(VolunteerShift shift) async {
    if (shift.isFull || shift.claimedBy.contains(widget.userId)) return;

    setState(() {
      shift.claimedBy = [...shift.claimedBy, widget.userId];
    });
    await _persistShifts(_shifts);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "You're scheduled for ${shift.title}! Thank you for volunteering.",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: _accent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _releaseShift(VolunteerShift shift) async {
    if (!shift.claimedBy.contains(widget.userId)) return;

    setState(() {
      shift.claimedBy =
          shift.claimedBy.where((id) => id != widget.userId).toList();
    });
    await _persistShifts(_shifts);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "You've released the ${shift.title} shift.",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  bool _isClaimed(VolunteerShift s) => s.claimedBy.contains(widget.userId);

  List<VolunteerShift> get _availableShifts =>
      _shifts.where((s) => !s.isFull || _isClaimed(s)).toList();

  List<VolunteerShift> get _myShifts =>
      _shifts.where((s) => _isClaimed(s)).toList();

  int get _totalAvailable =>
      _shifts.where((s) => s.spotsRemaining > 0).length;

  IconData _typeIcon(String type) {
    switch (type) {
      case 'chat':
        return Icons.message_rounded;
      case 'prayer':
        return Icons.favorite_rounded;
      case 'phone':
        return Icons.call_rounded;
      case 'in-person':
        return Icons.person_rounded;
      default:
        return Icons.volunteer_activism;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'chat':
        return _blue;
      case 'prayer':
        return _gold;
      case 'phone':
        return _accent;
      case 'in-person':
        return _red;
      default:
        return _accent;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'in-person':
        return 'In-Person';
      case 'prayer':
        return 'Prayer';
      case 'phone':
        return 'Phone';
      case 'chat':
        return 'Chat';
      default:
        return type;
    }
  }

  // ── Widgets ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Volunteer Shifts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_totalAvailable shifts open · ${_myShifts.length} claimed',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _accent.withValues(alpha: 0.4)),
            ),
            child: Text(
              '${_myShifts.length} active',
              style: const TextStyle(
                color: _accent,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2B1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00C853).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, __) => Opacity(
              opacity: _pulseAnimation.value,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF00C853),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            '3 counselors currently online',
            style: TextStyle(
              color: Color(0xFF00C853),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotsBar(VolunteerShift shift) {
    final ratio =
        shift.spotsTotal > 0 ? shift.spotsTaken / shift.spotsTotal : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${shift.spotsTaken} of ${shift.spotsTotal} spots taken',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
            Text(
              shift.isFull
                  ? 'Full'
                  : '${shift.spotsRemaining} remaining',
              style: TextStyle(
                color: shift.isFull ? _red : _accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              shift.isFull ? _red : _accent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShiftCard(VolunteerShift shift) {
    final claimed = _isClaimed(shift);
    final typeColor = _typeColor(shift.type);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: claimed
              ? _accent.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.06),
        ),
        boxShadow: claimed
            ? [
                BoxShadow(
                  color: _accent.withValues(alpha: 0.08),
                  blurRadius: 12,
                  spreadRadius: 1,
                )
              ]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: icon + title + type badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_typeIcon(shift.type), color: typeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shift.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${shift.date}  ·  ${shift.startTime} – ${shift.endTime}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _typeLabel(shift.type),
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Description
            Text(
              shift.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            // Spots bar
            _buildSpotsBar(shift),
            const SizedBox(height: 14),
            // Action button
            SizedBox(
              width: double.infinity,
              child: claimed
                  ? OutlinedButton.icon(
                      onPressed: () => _releaseShift(shift),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Release Shift'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _red,
                        side: const BorderSide(color: _red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: shift.isFull ? null : () => _claimShift(shift),
                      icon: Icon(
                        shift.isFull
                            ? Icons.lock_outline
                            : Icons.check_circle_outline,
                        size: 16,
                      ),
                      label: Text(shift.isFull ? 'Shift Full' : 'Claim Shift'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            shift.isFull ? Colors.white12 : _accent,
                        foregroundColor:
                            shift.isFull ? Colors.white38 : Colors.black,
                        disabledBackgroundColor: Colors.white12,
                        disabledForegroundColor: Colors.white38,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.volunteer_activism,
              size: 56,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableTab() {
    final list = _availableShifts;
    if (list.isEmpty) {
      return _buildEmptyState('No shifts available right now.\nCheck back soon!');
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: list.length,
      itemBuilder: (_, i) => _buildShiftCard(list[i]),
    );
  }

  Widget _buildMyShiftsTab() {
    final list = _myShifts;
    if (list.isEmpty) {
      return _buildEmptyState(
          'You haven\'t claimed any shifts yet.\nBrowse "Available" to get started.');
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: list.length,
      itemBuilder: (_, i) => _buildShiftCard(list[i]),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text(
          'Volunteer Shifts',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _accent,
          unselectedLabelColor: Colors.white38,
          indicatorColor: _accent,
          indicatorWeight: 2.5,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(
              text:
                  'Available (${_shifts.where((s) => s.spotsRemaining > 0).length})',
            ),
            Tab(text: 'My Shifts (${_myShifts.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _accent),
            )
          : Column(
              children: [
                _buildHeader(),
                _buildOnlineBanner(),
                const SizedBox(height: 4),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAvailableTab(),
                      _buildMyShiftsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
