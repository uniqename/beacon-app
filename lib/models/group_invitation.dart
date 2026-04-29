import 'support_group.dart';

/// Represents an invitation to join a support group
///
/// Used for managing access to private groups where members
/// must be explicitly invited.
class GroupInvitation {
  final String id;
  final String groupId;
  final String inviterId;
  final String inviteeId;
  final InvitationStatus status;
  final DateTime invitedAt;
  final DateTime? respondedAt;

  // Optional fields populated when fetching invitation details
  final SupportGroup? group;
  final String? inviterName;
  final String? inviteeName;

  const GroupInvitation({
    required this.id,
    required this.groupId,
    required this.inviterId,
    required this.inviteeId,
    required this.status,
    required this.invitedAt,
    this.respondedAt,
    this.group,
    this.inviterName,
    this.inviteeName,
  });

  /// Creates a GroupInvitation from a database map
  factory GroupInvitation.fromMap(Map<String, dynamic> data) {
    return GroupInvitation(
      id: data['id'] ?? '',
      groupId: data['group_id'] ?? '',
      inviterId: data['inviter_id'] ?? '',
      inviteeId: data['invitee_id'] ?? '',
      status: InvitationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => InvitationStatus.pending,
      ),
      invitedAt: DateTime.parse(
        data['invited_at'] ?? DateTime.now().toIso8601String(),
      ),
      respondedAt: data['responded_at'] != null
          ? DateTime.parse(data['responded_at'])
          : null,
      // These are populated via JOIN queries
      inviterName: data['inviter_name'],
      inviteeName: data['invitee_name'],
    );
  }

  /// Converts the GroupInvitation to a database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'inviter_id': inviterId,
      'invitee_id': inviteeId,
      'status': status.toString().split('.').last,
      'invited_at': invitedAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
    };
  }

  /// Returns true if the invitation is still pending
  bool get isPending => status == InvitationStatus.pending;

  /// Returns true if the invitation was accepted
  bool get isAccepted => status == InvitationStatus.accepted;

  /// Returns true if the invitation was rejected
  bool get isRejected => status == InvitationStatus.rejected;

  /// Returns true if the invitation has been responded to
  bool get hasResponded => respondedAt != null;

  /// Duration since the invitation was sent
  Duration get timeSinceInvited => DateTime.now().difference(invitedAt);

  /// Human-readable time since invited (e.g., "2 hours ago", "3 days ago")
  String get timeSinceInvitedText {
    final minutes = timeSinceInvited.inMinutes;
    if (minutes < 60) {
      return '${minutes}m ago';
    }
    final hours = timeSinceInvited.inHours;
    if (hours < 24) {
      return '${hours}h ago';
    }
    final days = timeSinceInvited.inDays;
    if (days < 7) {
      return '${days}d ago';
    }
    final weeks = days ~/ 7;
    if (weeks < 4) {
      return '${weeks}w ago';
    }
    final months = days ~/ 30;
    return '${months}mo ago';
  }

  /// Returns true if the invitation has expired (older than 30 days and still pending)
  bool get isExpired {
    if (!isPending) return false;
    return timeSinceInvited.inDays > 30;
  }

  /// Creates a copy with updated fields
  GroupInvitation copyWith({
    String? id,
    String? groupId,
    String? inviterId,
    String? inviteeId,
    InvitationStatus? status,
    DateTime? invitedAt,
    DateTime? respondedAt,
    SupportGroup? group,
    String? inviterName,
    String? inviteeName,
  }) {
    return GroupInvitation(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      inviterId: inviterId ?? this.inviterId,
      inviteeId: inviteeId ?? this.inviteeId,
      status: status ?? this.status,
      invitedAt: invitedAt ?? this.invitedAt,
      respondedAt: respondedAt ?? this.respondedAt,
      group: group ?? this.group,
      inviterName: inviterName ?? this.inviterName,
      inviteeName: inviteeName ?? this.inviteeName,
    );
  }

  @override
  String toString() {
    return 'GroupInvitation(id: $id, groupId: $groupId, '
        'status: $status, inviter: $inviterName, '
        'invitee: $inviteeName, timeSince: $timeSinceInvitedText)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GroupInvitation &&
        other.id == id &&
        other.groupId == groupId &&
        other.inviterId == inviterId &&
        other.inviteeId == inviteeId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        groupId.hashCode ^
        inviterId.hashCode ^
        inviteeId.hashCode;
  }
}

/// Status of a group invitation
enum InvitationStatus {
  /// Invitation has been sent but not responded to
  pending,

  /// Invitation was accepted by the invitee
  accepted,

  /// Invitation was rejected by the invitee
  rejected,
}

/// Extension methods for InvitationStatus
extension InvitationStatusExtension on InvitationStatus {
  /// Human-readable display name for the status
  String get displayName {
    switch (this) {
      case InvitationStatus.pending:
        return 'Pending';
      case InvitationStatus.accepted:
        return 'Accepted';
      case InvitationStatus.rejected:
        return 'Rejected';
    }
  }

  /// Icon name suitable for display
  String get iconName {
    switch (this) {
      case InvitationStatus.pending:
        return 'schedule'; // Clock icon for pending
      case InvitationStatus.accepted:
        return 'check_circle'; // Check icon for accepted
      case InvitationStatus.rejected:
        return 'cancel'; // X icon for rejected
    }
  }

  /// Color suitable for status display
  String get colorName {
    switch (this) {
      case InvitationStatus.pending:
        return 'orange'; // Vibrant orange for pending
      case InvitationStatus.accepted:
        return 'green'; // Soft sage green for accepted
      case InvitationStatus.rejected:
        return 'grey'; // Grey for rejected
    }
  }
}

/// Extension methods for invitation lists
extension GroupInvitationList on List<GroupInvitation> {
  /// Filters to only pending invitations
  List<GroupInvitation> get pending =>
      where((inv) => inv.status == InvitationStatus.pending).toList();

  /// Filters to only accepted invitations
  List<GroupInvitation> get accepted =>
      where((inv) => inv.status == InvitationStatus.accepted).toList();

  /// Filters to only rejected invitations
  List<GroupInvitation> get rejected =>
      where((inv) => inv.status == InvitationStatus.rejected).toList();

  /// Filters to only non-expired invitations
  List<GroupInvitation> get active =>
      where((inv) => !inv.isExpired).toList();

  /// Filters to only expired invitations
  List<GroupInvitation> get expired =>
      where((inv) => inv.isExpired).toList();

  /// Invitations for a specific user (as invitee)
  List<GroupInvitation> forUser(String userId) =>
      where((inv) => inv.inviteeId == userId).toList();

  /// Invitations sent by a specific user
  List<GroupInvitation> sentBy(String userId) =>
      where((inv) => inv.inviterId == userId).toList();

  /// Invitations for a specific group
  List<GroupInvitation> forGroup(String groupId) =>
      where((inv) => inv.groupId == groupId).toList();

  /// Sorts by most recent first
  List<GroupInvitation> get sortedByRecent {
    final sorted = List<GroupInvitation>.from(this);
    sorted.sort((a, b) => b.invitedAt.compareTo(a.invitedAt));
    return sorted;
  }
}
