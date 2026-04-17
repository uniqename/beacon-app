/// Represents a single audio room session for a support group
///
/// Tracks when a room went live, how long it lasted, who facilitated,
/// and participant statistics.
class GroupSession {
  final String id;
  final String groupId;
  final String agoraChannelName;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String facilitatorId;
  final int totalParticipants;
  final int maxConcurrentParticipants;
  final int? durationMinutes;

  const GroupSession({
    required this.id,
    required this.groupId,
    required this.agoraChannelName,
    required this.startedAt,
    this.endedAt,
    required this.facilitatorId,
    this.totalParticipants = 0,
    this.maxConcurrentParticipants = 0,
    this.durationMinutes,
  });

  /// Creates a GroupSession from a database map
  factory GroupSession.fromMap(Map<String, dynamic> data) {
    return GroupSession(
      id: data['id'] ?? '',
      groupId: data['group_id'] ?? '',
      agoraChannelName: data['agora_channel_name'] ?? '',
      startedAt: DateTime.parse(
        data['started_at'] ?? DateTime.now().toIso8601String(),
      ),
      endedAt: data['ended_at'] != null ? DateTime.parse(data['ended_at']) : null,
      facilitatorId: data['facilitator_id'] ?? '',
      totalParticipants: data['total_participants'] ?? 0,
      maxConcurrentParticipants: data['max_concurrent_participants'] ?? 0,
      durationMinutes: data['duration_minutes'],
    );
  }

  /// Converts the GroupSession to a database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'agora_channel_name': agoraChannelName,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'facilitator_id': facilitatorId,
      'total_participants': totalParticipants,
      'max_concurrent_participants': maxConcurrentParticipants,
      'duration_minutes': durationMinutes,
    };
  }

  /// Returns true if this session is currently active (ongoing)
  bool get isActive => endedAt == null;

  /// Returns the duration of the session
  Duration get duration {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  /// Returns the duration in minutes
  int get durationInMinutes => duration.inMinutes;

  /// Returns formatted duration string (e.g., "1h 30m", "45m")
  String get formattedDuration {
    final minutes = duration.inMinutes;
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${remainingMinutes}m';
  }

  /// Returns session status text
  String get statusText {
    if (isActive) {
      return 'Live';
    }
    return 'Ended';
  }

  /// Returns average participants per session
  double get averageParticipants {
    if (totalParticipants == 0) return 0.0;
    return totalParticipants / 1; // Could be enhanced with more data
  }

  /// Creates a copy with updated fields
  GroupSession copyWith({
    String? id,
    String? groupId,
    String? agoraChannelName,
    DateTime? startedAt,
    DateTime? endedAt,
    String? facilitatorId,
    int? totalParticipants,
    int? maxConcurrentParticipants,
    int? durationMinutes,
  }) {
    return GroupSession(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      agoraChannelName: agoraChannelName ?? this.agoraChannelName,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      facilitatorId: facilitatorId ?? this.facilitatorId,
      totalParticipants: totalParticipants ?? this.totalParticipants,
      maxConcurrentParticipants:
          maxConcurrentParticipants ?? this.maxConcurrentParticipants,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }

  @override
  String toString() {
    return 'GroupSession(id: $id, groupId: $groupId, '
        'agoraChannel: $agoraChannelName, '
        'status: ${isActive ? "Active" : "Ended"}, '
        'duration: $formattedDuration, '
        'participants: $totalParticipants/$maxConcurrentParticipants)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GroupSession &&
        other.id == id &&
        other.groupId == groupId &&
        other.agoraChannelName == agoraChannelName;
  }

  @override
  int get hashCode {
    return id.hashCode ^ groupId.hashCode ^ agoraChannelName.hashCode;
  }
}

/// Extension methods for session statistics
extension GroupSessionStats on List<GroupSession> {
  /// Total duration across all sessions
  Duration get totalDuration {
    return fold(
      Duration.zero,
      (prev, session) => prev + session.duration,
    );
  }

  /// Average session duration
  Duration get averageDuration {
    if (isEmpty) return Duration.zero;
    return Duration(
      milliseconds: totalDuration.inMilliseconds ~/ length,
    );
  }

  /// Total unique participants across all sessions
  int get totalParticipants {
    return fold(0, (prev, session) => prev + session.totalParticipants);
  }

  /// Average participants per session
  double get averageParticipantsPerSession {
    if (isEmpty) return 0.0;
    return totalParticipants / length;
  }

  /// Peak concurrent participants across all sessions
  int get peakConcurrentParticipants {
    if (isEmpty) return 0;
    return map((s) => s.maxConcurrentParticipants).reduce(
      (a, b) => a > b ? a : b,
    );
  }

  /// Number of active sessions
  int get activeSessionCount {
    return where((session) => session.isActive).length;
  }

  /// Number of ended sessions
  int get endedSessionCount {
    return where((session) => !session.isActive).length;
  }

  /// Sessions in the last N days
  List<GroupSession> inLastDays(int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return where((session) => session.startedAt.isAfter(cutoffDate)).toList();
  }

  /// Sessions for a specific month
  List<GroupSession> inMonth(int year, int month) {
    return where((session) =>
        session.startedAt.year == year &&
        session.startedAt.month == month).toList();
  }
}
