/// Represents a user's participation in a support group
///
/// Tracks the role, join/leave times, mute status, and active status
/// of a user in a specific support group.
class GroupParticipant {
  final String id;
  final String groupId;
  final String userId;
  final ParticipantRole role;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final bool isMuted;
  final bool isActive;
  final String? displayName; // Cached from user table for performance

  const GroupParticipant({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.leftAt,
    this.isMuted = false,
    this.isActive = true,
    this.displayName,
  });

  /// Creates a GroupParticipant from a database map
  factory GroupParticipant.fromMap(Map<String, dynamic> data) {
    return GroupParticipant(
      id: data['id'] ?? '',
      groupId: data['group_id'] ?? '',
      userId: data['user_id'] ?? '',
      role: ParticipantRole.values.firstWhere(
        (e) => e.toString().split('.').last == data['role'],
        orElse: () => ParticipantRole.listener,
      ),
      joinedAt: DateTime.parse(
        data['joined_at'] ?? DateTime.now().toIso8601String(),
      ),
      leftAt: data['left_at'] != null ? DateTime.parse(data['left_at']) : null,
      isMuted: (data['is_muted'] ?? 0) == 1,
      isActive: (data['is_active'] ?? 1) == 1,
      displayName: data['display_name'],
    );
  }

  /// Converts the GroupParticipant to a database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'role': role.toString().split('.').last,
      'joined_at': joinedAt.toIso8601String(),
      'left_at': leftAt?.toIso8601String(),
      'is_muted': isMuted ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      // Note: display_name is not stored in this table, it's joined from users
    };
  }

  /// Returns true if this participant is currently in the room
  bool get isInRoom => isActive && leftAt == null;

  /// Returns true if this participant can speak (facilitator, moderator, or speaker)
  bool get canSpeak =>
      role == ParticipantRole.facilitator ||
      role == ParticipantRole.moderator ||
      role == ParticipantRole.speaker;

  /// Returns true if this participant has moderator privileges
  bool get hasModerationPrivileges =>
      role == ParticipantRole.facilitator || role == ParticipantRole.moderator;

  /// Duration the participant has been in the room
  Duration get sessionDuration {
    final endTime = leftAt ?? DateTime.now();
    return endTime.difference(joinedAt);
  }

  /// Creates a copy with updated fields
  GroupParticipant copyWith({
    String? id,
    String? groupId,
    String? userId,
    ParticipantRole? role,
    DateTime? joinedAt,
    DateTime? leftAt,
    bool? isMuted,
    bool? isActive,
    String? displayName,
  }) {
    return GroupParticipant(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      isMuted: isMuted ?? this.isMuted,
      isActive: isActive ?? this.isActive,
      displayName: displayName ?? this.displayName,
    );
  }

  @override
  String toString() {
    return 'GroupParticipant(id: $id, userId: $userId, role: $role, '
        'isActive: $isActive, isMuted: $isMuted, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GroupParticipant &&
        other.id == id &&
        other.groupId == groupId &&
        other.userId == userId &&
        other.role == role;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        groupId.hashCode ^
        userId.hashCode ^
        role.hashCode;
  }
}

/// Defines the role a participant can have in a support group
enum ParticipantRole {
  /// Room creator/owner with full control
  facilitator,

  /// Designated moderators with limited control
  moderator,

  /// Active participants who can speak
  speaker,

  /// Passive participants who can only listen
  listener,
}

/// Extension methods for ParticipantRole
extension ParticipantRoleExtension on ParticipantRole {
  /// Human-readable display name for the role
  String get displayName {
    switch (this) {
      case ParticipantRole.facilitator:
        return 'Facilitator';
      case ParticipantRole.moderator:
        return 'Moderator';
      case ParticipantRole.speaker:
        return 'Speaker';
      case ParticipantRole.listener:
        return 'Listener';
    }
  }

  /// Icon name suitable for display
  String get iconName {
    switch (this) {
      case ParticipantRole.facilitator:
        return 'star'; // Star icon for facilitator
      case ParticipantRole.moderator:
        return 'shield'; // Shield icon for moderator
      case ParticipantRole.speaker:
        return 'mic'; // Microphone icon for speaker
      case ParticipantRole.listener:
        return 'headphones'; // Headphones icon for listener
    }
  }

  /// Short description of the role
  String get description {
    switch (this) {
      case ParticipantRole.facilitator:
        return 'Room host with full control';
      case ParticipantRole.moderator:
        return 'Can moderate discussions';
      case ParticipantRole.speaker:
        return 'Can speak in the room';
      case ParticipantRole.listener:
        return 'Listening only';
    }
  }

  /// Returns true if this role can speak
  bool get canSpeak =>
      this == ParticipantRole.facilitator ||
      this == ParticipantRole.moderator ||
      this == ParticipantRole.speaker;

  /// Returns true if this role has moderation privileges
  bool get canModerate =>
      this == ParticipantRole.facilitator ||
      this == ParticipantRole.moderator;
}
