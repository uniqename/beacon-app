import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class BeaconEvent {
  final String id;
  final String title;
  final String description;
  final String date;
  final String time;
  final String location;
  final int capacity;
  final String category;
  final Color color;

  const BeaconEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.capacity,
    required this.category,
    required this.color,
  });
}

// ---------------------------------------------------------------------------
// Sample data
// ---------------------------------------------------------------------------

final List<BeaconEvent> _events = [
  const BeaconEvent(
    id: 'ev001',
    title: 'Community Healing Circle',
    description:
        'A safe, facilitated space for survivors to share, support one another, '
        'and begin the journey of healing together. Every Saturday morning.',
    date: 'April 5, 2026',
    time: '10:00 AM',
    location: 'Beacon Center',
    capacity: 20,
    category: 'Weekly Support',
    color: Color(0xFF00D4AA),
  ),
  const BeaconEvent(
    id: 'ev002',
    title: 'Legal Rights Workshop',
    description:
        'Know your rights. A practising attorney will walk through legal protections '
        'available to survivors, how to access them, and what to do if they are violated.',
    date: 'April 12, 2026',
    time: '2:00 PM',
    location: 'Beacon Center',
    capacity: 30,
    category: 'Know Your Rights',
    color: Color(0xFF1A6B9A),
  ),
  const BeaconEvent(
    id: 'ev003',
    title: "Children's Art Therapy Day",
    description:
        'A nurturing half-day programme for children aged 5–14 using art, '
        'storytelling, and play to support emotional wellbeing and resilience.',
    date: 'April 19, 2026',
    time: '9:00 AM',
    location: 'Beacon Center',
    capacity: 15,
    category: 'Kids Programme',
    color: Color(0xFFFFB347),
  ),
  const BeaconEvent(
    id: 'ev004',
    title: 'Financial Freedom Workshop',
    description:
        'Practical financial literacy and empowerment training covering budgeting, '
        'savings, small business basics, and pathways to economic independence.',
    date: 'April 26, 2026',
    time: '11:00 AM',
    location: 'Beacon Center',
    capacity: 25,
    category: 'Financial Empowerment',
    color: Color(0xFF2ECC71),
  ),
  const BeaconEvent(
    id: 'ev005',
    title: 'Survivor Celebration Evening',
    description:
        'An evening of joy, recognition, and community. Celebrating the courage '
        'and progress of survivors in the Beacon family. Food, music, and testimonies.',
    date: 'May 3, 2026',
    time: '5:00 PM',
    location: 'Beacon Center',
    capacity: 50,
    category: 'Community Celebration',
    color: Color(0xFFE74C6F),
  ),
  const BeaconEvent(
    id: 'ev006',
    title: 'New Beginnings Retreat',
    description:
        'A two-day residential retreat focused on deep healing, identity restoration, '
        'and visioning your future. Includes workshops, rest, and spiritual renewal.',
    date: 'May 17–18, 2026',
    time: 'Starts 8:00 AM',
    location: 'Retreat Venue (TBC)',
    capacity: 20,
    category: 'Weekend Retreat',
    color: Color(0xFF7B2D8B),
  ),
];

// ---------------------------------------------------------------------------
// Color constants
// ---------------------------------------------------------------------------

const Color _bgColor = Color(0xFF0A0E1A);
const Color _cardColor = Color(0xFF141929);
const Color _accentColor = Color(0xFF00D4AA);
const Color _goldColor = Color(0xFFFFB347);

const String _rsvpPrefsKey = 'event_rsvps';

// ---------------------------------------------------------------------------
// EventsScreen
// ---------------------------------------------------------------------------

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, bool> _rsvpMap = {};
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRsvps();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRsvps() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_rsvpPrefsKey);
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        _rsvpMap = decoded.map((k, v) => MapEntry(k, v as bool));
      });
    }
    setState(() => _prefsLoaded = true);
  }

  Future<void> _saveRsvps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rsvpPrefsKey, jsonEncode(_rsvpMap));
  }

  void _toggleRsvp(String eventId) {
    setState(() {
      _rsvpMap[eventId] = !(_rsvpMap[eventId] ?? false);
    });
    _saveRsvps();
  }

  void _cancelRsvp(String eventId) {
    setState(() {
      _rsvpMap[eventId] = false;
    });
    _saveRsvps();
  }

  bool _isRsvpd(String eventId) => _rsvpMap[eventId] ?? false;

  List<BeaconEvent> get _rsvpdEvents =>
      _events.where((e) => _isRsvpd(e.id)).toList();

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Event Information',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.08),
              margin: const EdgeInsets.only(bottom: 16),
            ),
            _infoRow(Icons.location_on_outlined, _accentColor,
                'Events are held at Beacon of New Beginnings Center.'),
            const SizedBox(height: 12),
            _infoRow(Icons.phone_outlined, _goldColor,
                'Call us: 0302-BEACON'),
            const SizedBox(height: 12),
            _infoRow(Icons.email_outlined, _accentColor,
                'events@beaconnewbeginnings.org'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Got it',
              style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, Color iconColor, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        elevation: 0,
        title: const Text(
          'Events',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _accentColor,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.45),
          indicatorColor: _accentColor,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'My RSVPs'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _accentColor,
        foregroundColor: Colors.white,
        onPressed: _showInfoDialog,
        tooltip: 'Event information',
        child: const Icon(Icons.info_outline),
      ),
      body: _prefsLoaded
          ? TabBarView(
              controller: _tabController,
              children: [
                _UpcomingTab(
                  events: _events,
                  isRsvpd: _isRsvpd,
                  onToggleRsvp: _toggleRsvp,
                  onCancelRsvp: _cancelRsvp,
                ),
                _MyRsvpsTab(
                  events: _rsvpdEvents,
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(color: _accentColor),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Upcoming tab
// ---------------------------------------------------------------------------

class _UpcomingTab extends StatelessWidget {
  final List<BeaconEvent> events;
  final bool Function(String) isRsvpd;
  final void Function(String) onToggleRsvp;
  final void Function(String) onCancelRsvp;

  const _UpcomingTab({
    required this.events,
    required this.isRsvpd,
    required this.onToggleRsvp,
    required this.onCancelRsvp,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _EventCard(
          event: event,
          rsvpd: isRsvpd(event.id),
          onToggleRsvp: () => onToggleRsvp(event.id),
          onCancelRsvp: () => onCancelRsvp(event.id),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// My RSVPs tab
// ---------------------------------------------------------------------------

class _MyRsvpsTab extends StatelessWidget {
  final List<BeaconEvent> events;

  const _MyRsvpsTab({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 56,
              color: Colors.white.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Text(
              'No RSVPs yet',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Head to Upcoming to register for events.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _RsvpdEventCard(event: event);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Event card (Upcoming tab)
// ---------------------------------------------------------------------------

class _EventCard extends StatelessWidget {
  final BeaconEvent event;
  final bool rsvpd;
  final VoidCallback onToggleRsvp;
  final VoidCallback onCancelRsvp;

  const _EventCard({
    required this.event,
    required this.rsvpd,
    required this.onToggleRsvp,
    required this.onCancelRsvp,
  });

  // Parse a rough day + month from the date string for the date badge.
  // Handles "April 5, 2026" and "May 17–18, 2026".
  (String, String) _parseDateBadge() {
    final parts = event.date.split(' ');
    if (parts.length < 2) return ('--', '---');
    final month = parts[0].substring(0, 3).toUpperCase();
    // Strip any non-digit suffix (e.g. "17–18,")
    final dayRaw = parts[1].replaceAll(RegExp(r'[^0-9\-–]'), '');
    // For ranges like "17–18" just show the first number
    final day = dayRaw.split(RegExp(r'[–\-]')).first;
    return (day.isEmpty ? '--' : day, month);
  }

  @override
  Widget build(BuildContext context) {
    final (day, month) = _parseDateBadge();
    final spotsLeft = event.capacity;

    return GestureDetector(
      onLongPress: rsvpd ? onCancelRsvp : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top section: date badge + event info
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date badge
                  Container(
                    width: 52,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: event.color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: event.color.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          day,
                          style: TextStyle(
                            color: event.color,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          month,
                          style: TextStyle(
                            color: event.color.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Title + category chip
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: event.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            event.category,
                            style: TextStyle(
                              color: event.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Time + location row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.access_time,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.45)),
                  const SizedBox(width: 5),
                  Text(
                    event.time,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Icon(Icons.location_on_outlined,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.45)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      event.location,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                event.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  height: 1.55,
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Divider
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.06),
            ),

            // Bottom row: capacity indicator + RSVP button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  // Capacity indicator
                  Icon(
                    Icons.people_outline,
                    size: 15,
                    color: spotsLeft <= 5
                        ? _goldColor
                        : Colors.white.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$spotsLeft spots',
                    style: TextStyle(
                      color: spotsLeft <= 5
                          ? _goldColor
                          : Colors.white.withValues(alpha: 0.45),
                      fontSize: 12,
                      fontWeight: spotsLeft <= 5
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),

                  const Spacer(),

                  // RSVP button
                  rsvpd
                      ? _RsvpdButton(onLongPress: onCancelRsvp)
                      : _RsvpNowButton(
                          color: event.color,
                          onTap: onToggleRsvp,
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// RSVP button variants
// ---------------------------------------------------------------------------

class _RsvpNowButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _RsvpNowButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _accentColor, width: 1.5),
        ),
        child: const Text(
          'RSVP Now',
          style: TextStyle(
            color: _accentColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _RsvpdButton extends StatelessWidget {
  final VoidCallback onLongPress;

  const _RsvpdButton({required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: _accentColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, color: Colors.white, size: 14),
            SizedBox(width: 5),
            Text(
              "RSVP'd",
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// RSVP'd event card (My RSVPs tab)
// ---------------------------------------------------------------------------

class _RsvpdEventCard extends StatelessWidget {
  final BeaconEvent event;

  const _RsvpdEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _accentColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accent top bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: event.color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + RSVP badge row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 12, color: _accentColor),
                          SizedBox(width: 4),
                          Text(
                            "RSVP'd",
                            style: TextStyle(
                              color: _accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Date + time
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.4)),
                    const SizedBox(width: 5),
                    Text(
                      event.date,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time,
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.4)),
                    const SizedBox(width: 5),
                    Text(
                      event.time,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // Location
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.4)),
                    const SizedBox(width: 5),
                    Text(
                      event.location,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Reminder button
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Reminder set for ${event.title}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: const Color(0xFF1E2A3A),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        action: SnackBarAction(
                          label: 'OK',
                          textColor: _accentColor,
                          onPressed: () {},
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _goldColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _goldColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_outlined,
                            color: _goldColor, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Set Reminder',
                          style: TextStyle(
                            color: _goldColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
