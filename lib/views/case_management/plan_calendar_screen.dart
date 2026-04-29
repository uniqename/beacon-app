import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/case_plan.dart';
import '../../services/case_management_service.dart';

/// Calendar view of a case plan's deadlines, action items, and review dates.
/// Works for both survivors (read-only, userId) and admins (casePlanId).
class PlanCalendarScreen extends StatefulWidget {
  /// Supply [casePlanId] to load a specific plan (admin view).
  /// Supply [userId] to load the plan linked to that user (survivor view).
  final String? casePlanId;
  final String? userId;
  final bool isAdminView;

  const PlanCalendarScreen({
    super.key,
    this.casePlanId,
    this.userId,
    this.isAdminView = false,
  }) : assert(casePlanId != null || userId != null,
            'Provide casePlanId or userId');

  @override
  State<PlanCalendarScreen> createState() => _PlanCalendarScreenState();
}

class _PlanCalendarScreenState extends State<PlanCalendarScreen> {
  CasePlan? _plan;
  bool _isLoading = true;

  // calendar state
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _format = CalendarFormat.month;

  // map of date → list of events
  final Map<DateTime, List<_CalEvent>> _events = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      CasePlan? plan;
      if (widget.casePlanId != null) {
        plan = await CaseManagementService.getCasePlan(widget.casePlanId!);
      } else if (widget.userId != null) {
        plan = await CaseManagementService.getCasePlanForUser(widget.userId!);
      }

      if (plan == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final programs =
          await CaseManagementService.getProgramsForPlan(plan.id);

      final events = <DateTime, List<_CalEvent>>{};

      void addEvent(DateTime? date, _CalEvent event) {
        if (date == null) return;
        final key = _normalise(date);
        events[key] = [...(events[key] ?? []), event];
      }

      // Review date
      if (plan.nextReviewDate != null) {
        addEvent(
          plan.nextReviewDate,
          _CalEvent(
            title: 'Plan Review',
            subtitle: 'Quarterly review — ${plan.clientName}',
            type: _EventType.review,
          ),
        );
      }

      // Program deadlines + action items
      for (final prog in programs) {
        if (prog.deadlineDate != null) {
          addEvent(
            prog.deadlineDate,
            _CalEvent(
              title: prog.programName,
              subtitle: prog.deadlineLabel ?? 'Deadline',
              type: _eventTypeForPriority(prog.priority),
              priority: prog.priority,
            ),
          );
        }

        // Individual actions that have a date hint from deadline
        for (final action in prog.actions) {
          if (action.completedAt != null) {
            addEvent(
              action.completedAt,
              _CalEvent(
                title: action.text,
                subtitle: '${prog.programName} — completed',
                type: _EventType.completed,
              ),
            );
          }
        }
      }

      if (mounted) {
        setState(() {
          _plan = plan;
          _events.clear();
          _events.addAll(events);
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error loading calendar: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  DateTime _normalise(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  List<_CalEvent> _eventsForDay(DateTime day) =>
      _events[_normalise(day)] ?? [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      appBar: AppBar(
        title: Text(
          _plan != null
              ? '${_plan!.clientName} — Calendar'
              : 'Plan Calendar',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFF0562D),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.today, color: Colors.white),
            onPressed: () => setState(() {
              _focusedDay = DateTime.now();
              _selectedDay = DateTime.now();
            }),
            tooltip: 'Today',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF0562D)))
          : _plan == null
              ? _buildNoPlan()
              : Column(
                  children: [
                    _buildLegend(),
                    _buildCalendar(),
                    const Divider(height: 1),
                    Expanded(child: _buildEventList()),
                  ],
                ),
    );
  }

  Widget _buildNoPlan() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No plan found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _legendDot(Colors.red, 'Urgent'),
          const SizedBox(width: 12),
          _legendDot(const Color(0xFFF0562D), 'High'),
          const SizedBox(width: 12),
          _legendDot(Colors.amber[700]!, 'Medium'),
          const SizedBox(width: 12),
          _legendDot(Colors.blue, 'Review'),
          const SizedBox(width: 12),
          _legendDot(Colors.green, 'Done'),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ],
    );
  }

  Widget _buildCalendar() {
    return Container(
      color: Colors.white,
      child: TableCalendar<_CalEvent>(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 730)),
        focusedDay: _focusedDay,
        calendarFormat: _format,
        selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
        eventLoader: _eventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: const Color(0xFFF0562D).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
              color: Color(0xFFF0562D), fontWeight: FontWeight.bold),
          selectedDecoration: const BoxDecoration(
            color: Color(0xFFF0562D),
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: Color(0xFFF0562D),
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: true,
          titleCentered: true,
          formatButtonDecoration: BoxDecoration(
            border: Border.fromBorderSide(
                BorderSide(color: Color(0xFFF0562D))),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          formatButtonTextStyle:
              TextStyle(color: Color(0xFFF0562D), fontSize: 12),
        ),
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
          });
        },
        onFormatChanged: (f) => setState(() => _format = f),
        onPageChanged: (focused) => setState(() => _focusedDay = focused),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (ctx, day, events) {
            if (events.isEmpty) return null;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: events.take(3).map((e) {
                return Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: _colorForEvent(e),
                    shape: BoxShape.circle,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventList() {
    final day = _selectedDay ?? DateTime.now();
    final events = _eventsForDay(day);

    if (events.isEmpty) {
      // Show upcoming events if nothing on selected day
      final upcoming = _upcomingEvents(5);
      if (upcoming.isEmpty) {
        return Center(
          child: Text(
            'No events on ${_fmtDate(day)}',
            style: TextStyle(color: Colors.grey[700]),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text('Upcoming',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey[700])),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: upcoming.length,
              itemBuilder: (_, i) => _buildEventTile(
                  upcoming[i].$1, upcoming[i].$2),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Text(_fmtDate(day),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: events.length,
            itemBuilder: (_, i) => _buildEventTile(day, events[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildEventTile(DateTime date, _CalEvent event) {
    final color = _colorForEvent(event);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.grey[200]!,
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(_iconForEvent(event), color: color, size: 20),
        ),
        title: Text(event.title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(event.subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: Text(
          _fmtDate(date),
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
      ),
    );
  }

  // Returns up to [n] upcoming events from today
  List<(DateTime, _CalEvent)> _upcomingEvents(int n) {
    final today = _normalise(DateTime.now());
    final result = <(DateTime, _CalEvent)>[];
    final sorted = _events.keys
        .where((d) => !d.isBefore(today))
        .toList()
      ..sort();
    for (final date in sorted) {
      for (final e in (_events[date] ?? [])) {
        result.add((date, e));
        if (result.length >= n) return result;
      }
    }
    return result;
  }

  Color _colorForEvent(_CalEvent e) {
    switch (e.type) {
      case _EventType.urgent:  return Colors.red;
      case _EventType.high:    return const Color(0xFFF0562D);
      case _EventType.medium:  return Colors.amber[700]!;
      case _EventType.review:  return Colors.blue;
      case _EventType.completed: return Colors.green;
      default:                 return Colors.grey;
    }
  }

  IconData _iconForEvent(_CalEvent e) {
    switch (e.type) {
      case _EventType.review:    return Icons.event_repeat;
      case _EventType.completed: return Icons.check_circle;
      case _EventType.urgent:    return Icons.warning_amber;
      default:                   return Icons.flag;
    }
  }

  _EventType _eventTypeForPriority(String priority) {
    switch (priority) {
      case 'urgent':  return _EventType.urgent;
      case 'high':    return _EventType.high;
      case 'medium':  return _EventType.medium;
      default:        return _EventType.other;
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}

enum _EventType { urgent, high, medium, review, completed, other }

class _CalEvent {
  final String title;
  final String subtitle;
  final _EventType type;
  final String? priority;

  const _CalEvent({
    required this.title,
    required this.subtitle,
    required this.type,
    this.priority,
  });
}
