import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class MentorProfile {
  final String id;
  final String alias;
  final int yearsOfRecovery;
  final List<String> specialties;
  final String bio;
  bool isAvailable;
  final DateTime joinedDate;

  MentorProfile({
    required this.id,
    required this.alias,
    required this.yearsOfRecovery,
    required this.specialties,
    required this.bio,
    required this.isAvailable,
    required this.joinedDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'alias': alias,
        'yearsOfRecovery': yearsOfRecovery,
        'specialties': specialties,
        'bio': bio,
        'isAvailable': isAvailable,
        'joinedDate': joinedDate.toIso8601String(),
      };

  factory MentorProfile.fromJson(Map<String, dynamic> json) => MentorProfile(
        id: json['id'] as String,
        alias: json['alias'] as String,
        yearsOfRecovery: json['yearsOfRecovery'] as int,
        specialties: List<String>.from(json['specialties'] as List),
        bio: json['bio'] as String,
        isAvailable: json['isAvailable'] as bool,
        joinedDate: DateTime.parse(json['joinedDate'] as String),
      );
}

// ---------------------------------------------------------------------------
// Seed data
// ---------------------------------------------------------------------------

List<MentorProfile> _buildSeedMentors() => [
      MentorProfile(
        id: 'mentor_001',
        alias: 'Rose',
        yearsOfRecovery: 3,
        specialties: ['Housing', 'Legal'],
        bio:
            'I found my strength one step at a time. After navigating the housing system and legal hurdles myself, I\'m here to guide you through the same journey. You are not alone, and there is a way forward.',
        isAvailable: true,
        joinedDate: DateTime(2023, 4, 12),
      ),
      MentorProfile(
        id: 'mentor_002',
        alias: 'Grace',
        yearsOfRecovery: 5,
        specialties: ['Children', 'Emotional Healing'],
        bio:
            'Rebuilding my life meant rebuilding my family first. I\'ve walked through the pain of separation and the joy of reunion. My heart is open to anyone raising children through hardship or healing from deep emotional wounds.',
        isAvailable: true,
        joinedDate: DateTime(2022, 9, 3),
      ),
      MentorProfile(
        id: 'mentor_003',
        alias: 'Strength',
        yearsOfRecovery: 2,
        specialties: ['Financial Independence', 'Career'],
        bio:
            'Two years ago I had nothing. Today I have a job, a savings account, and a future I built with my own hands. I want to help you find that same financial footing and career direction — because you deserve stability.',
        isAvailable: true,
        joinedDate: DateTime(2024, 1, 18),
      ),
      MentorProfile(
        id: 'mentor_004',
        alias: 'Hope',
        yearsOfRecovery: 7,
        specialties: ['PTSD Recovery', 'Support Groups'],
        bio:
            'Seven years of healing have taught me that trauma is not the end of your story. Through support groups and professional help I found my peace. I can help you navigate PTSD recovery and find the communities that will hold you up.',
        isAvailable: false,
        joinedDate: DateTime(2021, 6, 7),
      ),
      MentorProfile(
        id: 'mentor_005',
        alias: 'Victory',
        yearsOfRecovery: 4,
        specialties: ['Faith & Spirituality', 'Community'],
        bio:
            'Faith carried me when I had nothing else. My community became my lifeline. I\'m here for anyone seeking spiritual grounding or wanting to connect with others who truly understand the journey of rebuilding after loss.',
        isAvailable: true,
        joinedDate: DateTime(2022, 11, 22),
      ),
    ];

// ---------------------------------------------------------------------------
// Available specialties for the "Become a Mentor" form
// ---------------------------------------------------------------------------

const List<String> _allSpecialties = [
  'Housing',
  'Legal',
  'Children',
  'Emotional Healing',
  'Financial Independence',
  'Career',
  'PTSD Recovery',
  'Support Groups',
  'Faith & Spirituality',
  'Community',
  'Healthcare',
  'Education',
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class PeerMentorshipScreen extends StatefulWidget {
  final String userId;

  const PeerMentorshipScreen({super.key, required this.userId});

  @override
  State<PeerMentorshipScreen> createState() => _PeerMentorshipScreenState();
}

class _PeerMentorshipScreenState extends State<PeerMentorshipScreen> {
  // ── Colors ──────────────────────────────────────────────────────────────
  static const Color _bg = Color(0xFF0A0E1A);
  static const Color _card = Color(0xFF141929);
  static const Color _accent = Color(0xFF00D4AA);
  static const Color _gold = Color(0xFFFFB347);
  static const Color _red = Color(0xFFFF5C7A);
  static const Color _purple = Color(0xFF9B59B6);
  static const Color _blue = Color(0xFF3B82F6);

  // ── State ────────────────────────────────────────────────────────────────
  List<MentorProfile> _mentors = [];
  bool _isLoading = true;

  // My request
  String _myMentorRequestId = '';

  // Am I already a mentor?
  bool _isMentor = false;

  // "Become a Mentor" form expansion
  bool _becomeMentorExpanded = false;
  final TextEditingController _aliasController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final Set<String> _selectedSpecialties = {};

  // ── Keys ─────────────────────────────────────────────────────────────────
  static const String _mentorsKey = 'mentor_profiles';
  String get _myRequestKey => 'my_mentor_request_${widget.userId}';
  String get _isMentorKey => 'is_mentor_${widget.userId}';

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load mentors
    final raw = prefs.getString(_mentorsKey);
    List<MentorProfile> loaded;
    if (raw == null || raw.isEmpty) {
      loaded = _buildSeedMentors();
      await prefs.setString(
        _mentorsKey,
        jsonEncode(loaded.map((m) => m.toJson()).toList()),
      );
    } else {
      final decoded = jsonDecode(raw) as List;
      loaded = decoded
          .map((e) => MentorProfile.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final requestId = prefs.getString(_myRequestKey) ?? '';
    final isMentor = prefs.getBool(_isMentorKey) ?? false;

    if (mounted) {
      setState(() {
        _mentors = loaded;
        _myMentorRequestId = requestId;
        _isMentor = isMentor;
        _isLoading = false;
      });
    }
  }

  Future<void> _persistMentors() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _mentorsKey,
      jsonEncode(_mentors.map((m) => m.toJson()).toList()),
    );
  }

  Future<void> _sendMentorRequest(MentorProfile mentor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_myRequestKey, mentor.id);
    setState(() => _myMentorRequestId = mentor.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Connection request sent to ${mentor.alias}. They will reach out within 24–48 hours.',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: _accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _cancelMentorRequest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_myRequestKey, '');
    setState(() => _myMentorRequestId = '');
  }

  Future<void> _registerAsMentor() async {
    final alias = _aliasController.text.trim();
    final bio = _bioController.text.trim();

    if (alias.isEmpty) {
      _showValidationError('Please enter an anonymous alias.');
      return;
    }
    if (bio.isEmpty) {
      _showValidationError('Please write a short bio.');
      return;
    }
    if (_selectedSpecialties.isEmpty) {
      _showValidationError('Please select at least one specialty.');
      return;
    }

    final newMentor = MentorProfile(
      id: 'mentor_user_${widget.userId}',
      alias: alias,
      yearsOfRecovery: 1,
      specialties: _selectedSpecialties.toList(),
      bio: bio,
      isAvailable: true,
      joinedDate: DateTime.now(),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isMentorKey, true);

    setState(() {
      _mentors.add(newMentor);
      _isMentor = true;
      _becomeMentorExpanded = false;
    });
    await _persistMentors();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You are now listed as a peer mentor. Thank you!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: _purple,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showValidationError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showRequestConfirmDialog(MentorProfile mentor) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Connect with ${mentor.alias}?',
          style: const TextStyle(color: Colors.white, fontSize: 17),
        ),
        content: Text(
          '${mentor.alias} will be notified of your request and will reach out within 24–48 hours. Your identity remains anonymous until you choose to share it.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _sendMentorRequest(mentor);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────
  Widget _buildPageHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _purple.withValues(alpha: 0.25),
            _blue.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purple.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.people_alt_rounded,
                    color: _purple, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Peer Mentorship',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Survivor to Survivor',
            style: TextStyle(
              color: _gold,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Guided by those who\'ve walked this path',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBecomeMentorBanner() {
    if (_isMentor) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        color: _purple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purple.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          // Header row with toggle
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () =>
                setState(() => _becomeMentorExpanded = !_becomeMentorExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.volunteer_activism,
                        color: _purple, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Become a Mentor',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Share your journey with someone who needs it',
                          style: TextStyle(
                            color: _purple,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _becomeMentorExpanded,
                    onChanged: (v) =>
                        setState(() => _becomeMentorExpanded = v),
                    activeThumbColor: _purple,
                    activeTrackColor: _purple.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
          ),
          // Expandable form
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _becomeMentorExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _buildBecomeMentorForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildBecomeMentorForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 10),
          // Alias field
          _formLabel('Your Anonymous Alias'),
          const SizedBox(height: 6),
          TextField(
            controller: _aliasController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration(
                'e.g. "River", "Dawn", "Phoenix"', Icons.person_outline),
          ),
          const SizedBox(height: 14),
          // Bio field
          _formLabel('Your Story (short bio)'),
          const SizedBox(height: 6),
          TextField(
            controller: _bioController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: _inputDecoration(
                'Share what you\'ve overcome and how you can help…',
                Icons.edit_note),
          ),
          const SizedBox(height: 14),
          // Specialties
          _formLabel('Areas You Can Help With'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _allSpecialties
                .map((s) => _specialtyCheckChip(s))
                .toList(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _registerAsMentor,
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Register as Mentor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _specialtyCheckChip(String label) {
    final selected = _selectedSpecialties.contains(label);
    return GestureDetector(
      onTap: () => setState(() {
        if (selected) {
          _selectedSpecialties.remove(label);
        } else {
          _selectedSpecialties.add(label);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? _purple.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? _purple.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 13, color: _purple),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? _purple : Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formLabel(String text) => Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );

  InputDecoration _inputDecoration(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.3), size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _purple),
        ),
      );

  // My mentor section (shown when a match exists)
  Widget _buildMyMentorSection() {
    if (_myMentorRequestId.isEmpty) return const SizedBox.shrink();

    // Pending request — not yet matched
    final mentor = _mentors
        .where((m) => m.id == _myMentorRequestId)
        .cast<MentorProfile?>()
        .firstWhere((_) => true, orElse: () => null);

    if (mentor == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hourglass_top_rounded,
                  color: _accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'Waiting for ${mentor.alias} to connect',
                style: const TextStyle(
                  color: _accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildMentorCardInner(mentor, isMyMentor: true),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/support_chat'),
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: Text('Message ${mentor.alias}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accent,
                    side: const BorderSide(color: _accent),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: _cancelMentorRequest,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _red,
                  side: const BorderSide(color: _red),
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.45),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildMentorCard(MentorProfile mentor) {
    final isPending = _myMentorRequestId == mentor.id;
    final hasActiveRequest = _myMentorRequestId.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? _accent.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMentorCardInner(mentor, isMyMentor: false),
            const SizedBox(height: 14),
            // Action button
            SizedBox(
              width: double.infinity,
              child: isPending
                  ? ElevatedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.hourglass_top_rounded, size: 15),
                      label: const Text('Request Pending'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent.withValues(alpha: 0.15),
                        foregroundColor: _accent,
                        disabledBackgroundColor: _accent.withValues(alpha: 0.15),
                        disabledForegroundColor: _accent,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    )
                  : !mentor.isAvailable
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Text(
                            'Currently Full',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: hasActiveRequest
                              ? null
                              : () => _showRequestConfirmDialog(mentor),
                          icon: const Icon(Icons.connect_without_contact,
                              size: 16),
                          label: const Text('Request this Mentor'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasActiveRequest
                                ? Colors.white12
                                : _accent,
                            foregroundColor: hasActiveRequest
                                ? Colors.white38
                                : Colors.black,
                            disabledBackgroundColor: Colors.white12,
                            disabledForegroundColor: Colors.white38,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMentorCardInner(MentorProfile mentor,
      {required bool isMyMentor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        CircleAvatar(
          radius: 26,
          backgroundColor: _accent.withValues(alpha: 0.15),
          child: Text(
            mentor.alias[0].toUpperCase(),
            style: const TextStyle(
              color: _accent,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + availability badge
              Row(
                children: [
                  Text(
                    mentor.alias,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!mentor.isAvailable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Currently full',
                        style: TextStyle(
                          color: _red,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              // Years badge
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${mentor.yearsOfRecovery} yr${mentor.yearsOfRecovery == 1 ? '' : 's'} recovery',
                      style: const TextStyle(
                        color: _gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Specialty chips
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: mentor.specialties
                    .map(
                      (s) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _blue.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            color: _blue.withValues(alpha: 0.9),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              // Truncated bio
              Text(
                mentor.bio,
                maxLines: isMyMentor ? 10 : 3,
                overflow: isMyMentor
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
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
          'Peer Mentorship',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                _buildPageHeader(),
                _buildBecomeMentorBanner(),
                if (_myMentorRequestId.isNotEmpty) ...[
                  _buildSectionLabel('MY MENTOR REQUEST'),
                  _buildMyMentorSection(),
                ],
                _buildSectionLabel(
                    'AVAILABLE MENTORS (${_mentors.where((m) => m.isAvailable).length})'),
                ..._mentors
                    .where((m) => m.isAvailable)
                    .map(_buildMentorCard),
                if (_mentors.any((m) => !m.isAvailable)) ...[
                  _buildSectionLabel('CURRENTLY UNAVAILABLE'),
                  ..._mentors
                      .where((m) => !m.isAvailable)
                      .map(_buildMentorCard),
                ],
              ],
            ),
    );
  }
}
