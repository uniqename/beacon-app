import 'dart:developer' as developer;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/support_group.dart';
import '../models/group_participant.dart';
import '../models/group_invitation.dart';
import 'local_database_service.dart';
import 'email_notification_service.dart';

/// Service for managing support groups including CRUD operations,
/// membership management, invitations, and permissions
class SupportGroupService {
  static final SupportGroupService _instance = SupportGroupService._internal();
  factory SupportGroupService() => _instance;
  SupportGroupService._internal();

  final _uuid = const Uuid();

  // ============================================================================
  // GROUP CRUD OPERATIONS
  // ============================================================================

  /// Creates a new support group
  Future<String> createGroup(SupportGroup group) async {
    try {
      final db = await LocalDatabaseService.database;

      final groupData = {
        'id': group.id,
        'name': group.name,
        'description': group.description,
        'type': group.type.toString().split('.').last,
        'privacy': group.privacy.toString().split('.').last,
        'facilitator_id': group.facilitatorId,
        'member_ids': jsonEncode(group.memberIds),
        'moderator_ids': jsonEncode(group.moderatorIds),
        'is_live': group.isLive ? 1 : 0,
        'guidelines': jsonEncode(group.guidelines),
        'max_members': group.maxMembers,
        'tags': jsonEncode(group.tags),
        'host_name': group.hostName,
        'scheduled_time': group.scheduledTime?.toIso8601String(),
        'agora_channel_name': group.agoraChannelName,
        'is_active': group.isActive ? 1 : 0,
        'created_at': group.createdAt.toIso8601String(),
        'last_activity_at': group.lastActivityAt?.toIso8601String(),
      };

      await db.insert('support_groups', groupData);

      // Add facilitator as first participant — non-critical, don't fail group creation
      if (group.facilitatorId != null) {
        try {
          // Bypass canUserJoinGroup for the creator — they always can join their own room
          final participantData = {
            'id': _uuid.v4(),
            'group_id': group.id,
            'user_id': group.facilitatorId!,
            'role': ParticipantRole.facilitator.toString().split('.').last,
            'joined_at': DateTime.now().toIso8601String(),
            'is_muted': 0,
            'is_active': 1,
          };
          await db.insert('support_group_participants', participantData);

          final updatedMemberIds = [...group.memberIds, group.facilitatorId!];
          await updateGroup(group.id, {'member_ids': updatedMemberIds});
        } catch (e) {
          developer.log('⚠️ [SupportGroupService] Could not add facilitator as participant: $e');
        }
      }

      developer.log('✅ [SupportGroupService] Created group: ${group.name}');
      return group.id;
    } catch (e) {
      developer.log('❌ [SupportGroupService] Error creating group: $e');
      rethrow;
    }
  }

  /// Gets a support group by ID
  Future<SupportGroup?> getGroup(String groupId) async {
    try {
      final db = await LocalDatabaseService.database;

      final results = await db.query(
        'support_groups',
        where: 'id = ?',
        whereArgs: [groupId],
      );

      if (results.isEmpty) return null;

      return _supportGroupFromDb(results.first);
    } catch (e) {
      developer.log('❌ [SupportGroupService] Error getting group: $e');
      return null;
    }
  }

  /// Gets all live groups
  Future<List<SupportGroup>> getLiveGroups() async {
    try {
      final db = await LocalDatabaseService.database;

      final results = await db.query(
        'support_groups',
        where: 'is_live = ? AND is_active = ?',
        whereArgs: [1, 1],
        orderBy: 'last_activity_at DESC',
      );

      return results.map(_supportGroupFromDb).toList();
    } catch (e) {
      developer.log('❌ [SupportGroupService] Error getting live groups: $e');
      return [];
    }
  }

  /// Gets all upcoming scheduled groups
  Future<List<SupportGroup>> getUpcomingGroups() async {
    try {
      final db = await LocalDatabaseService.database;

      final now = DateTime.now().toIso8601String();
      final results = await db.query(
        'support_groups',
        where: 'scheduled_time > ? AND is_live = ? AND is_active = ?',
        whereArgs: [now, 0, 1],
        orderBy: 'scheduled_time ASC',
      );

      return results.map(_supportGroupFromDb).toList();
    } catch (e) {
      developer.log('❌ [SupportGroupService] Error getting upcoming groups: $e');
      return [];
    }
  }

  /// Gets all ongoing (regular) groups
  Future<List<SupportGroup>> getOngoingGroups() async {
    try {
      final db = await LocalDatabaseService.database;

      final results = await db.query(
        'support_groups',
        where: 'is_live = ? AND scheduled_time IS NULL AND is_active = ?',
        whereArgs: [0, 1],
        orderBy: 'created_at DESC',
      );

      return results.map(_supportGroupFromDb).toList();
    } catch (e) {
      developer.log('❌ [SupportGroupService] Error getting ongoing groups: $e');
      return [];
    }
  }

  /// Gets groups where user is a member
  Future<List<SupportGroup>> getUserGroups(String userId) async {
    try {
      final db = await LocalDatabaseService.database;

      // Get all active groups
      final results = await db.query(
        'support_groups',
        where: 'is_active = ?',
        whereArgs: [1],
      );

      // Filter to groups where user is a member, facilitator, or moderator
      final userGroups = results.where((groupData) {
        final memberIds = _decodeJsonList(groupData['member_ids'] as String?);
        final moderatorIds = _decodeJsonList(groupData['moderator_ids'] as String?);
        final facilitatorId = groupData['facilitator_id'] as String?;

        return memberIds.contains(userId) ||
               moderatorIds.contains(userId) ||
               facilitatorId == userId;
      }).toList();

      return userGroups.map(_supportGroupFromDb).toList();
    } catch (e) {
      developer.log('❌ [SupportGroupService] Error getting user groups: $e');
      return [];
    }
  }

  /// Updates a support group
  Future<bool> updateGroup(String groupId, Map<String, dynamic> updates) async {
    try {
      final db = await LocalDatabaseService.database;

      // Convert any list/map fields to JSON
      final dbUpdates = <String, dynamic>{};
      updates.forEach((key, value) {
        if (value is List) {
          dbUpdates[key] = jsonEncode(value);
        } else if (value is Map) {
          dbUpdates[key] = jsonEncode(value);
        } else if (value is DateTime) {
          dbUpdates[key] = value.toIso8601String();
        } else if (value is bool) {
          dbUpdates[key] = value ? 1 : 0;
        } else if (value is Enum) {
          dbUpdates[key] = value.toString().split('.').last;
        } else {
          dbUpdates[key] = value;
        }
      });

      await db.update(
        'support_groups',
        dbUpdates,
        where: 'id = ?',
        whereArgs: [groupId],
      );

      developer.log('✅ [SupportGroupService] Updated group: $groupId');
      return true;
    } catch (e) {
      developer.log('❌ [SupportGroupService] Error updating group: $e');
      return false;
    }
  }

  /// Closes a live room — marks it as no longer live so it stops appearing in
  /// the live list. Called by facilitators or admins when ending a session.
  Future<bool> closeRoom(String groupId) async {
    try {
      final db = await LocalDatabaseService.database;
      await db.update(
        'support_groups',
        {
          'is_live': 0,
          'last_activity_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [groupId],
      );
      developer.log('✅ [SupportGroupService] Closed live room: $groupId');
      return true;
    } catch (e) {
      developer.log('❌ [SupportGroupService] Error closing room: $e');
      return false;
    }
  }

  /// Deletes a support group
  Future<bool> deleteGroup(String groupId) async {
    try {
      final db = await LocalDatabaseService.database;

      // Soft delete by setting is_active to false
      await db.update(
        'support_groups',
        {'is_active': 0},
        where: 'id = ?',
        whereArgs: [groupId],
      );

      // Also deactivate all participants
      await db.update(
        'support_group_participants',
        {'is_active': 0, 'left_at': DateTime.now().toIso8601String()},
        where: 'group_id = ? AND is_active = ?',
        whereArgs: [groupId, 1],
      );

      developer.log('✅ [SupportGroupService] Deleted group: $groupId');
      return true;
    } catch (e) {
      developer.log('❌ [SupportGroupService] Error deleting group: $e');
      return false;
    }
  }

  // ============================================================================
  // PERMISSION CHECKS
  // ============================================================================

  /// Checks if a user can create groups
  Future<bool> canUserCreateGroup(String userId) async {
    try {
      final db = await LocalDatabaseService.database;

      final results = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (results.isEmpty) return false;

      final userType = results.first['user_type'] as String?;
      final approvalStatus = results.first['approval_status'] as String?;

      // Approved counselors, volunteers, and admins can create groups
      if (userType == 'counselor' || userType == 'volunteer' || userType == 'admin') {
        return approvalStatus == 'approved';
      }

      // Survivors can also create peer support circles
      if (userType == 'survivor') {
        return true;
      }

      return false;
    } catch (e) {
      developer.log('❌ [SupportGroupService] Error checking create permission: $e');
      return false;
    }
  }

  /// Checks if a user can join a group
  Future<bool> canUserJoinGroup(String userId, String groupId) async {
    try {
      final group = await getGroup(groupId);
      if (group == null) return false;

      // Check if group is full
      if (group.isFull) return false;

      // Public groups: anyone can join
      if (group.privacy == GroupPrivacy.public) return true;

      // Private groups: must be invited or be facilitator/moderator
      if (group.privacy == GroupPrivacy.private) {
        if (group.facilitatorId == userId) return true;
        if (group.moderatorIds.contains(userId)) return true;

        // Check if user has accepted invitation
        final invitation = await _getInvitation(userId, groupId);
        return invitation?.status == InvitationStatus.accepted;
      }

      // Anonymous groups: anyone can join anonymously
      if (group.privacy == GroupPrivacy.anonymous) return true;

      return false;
    } catch (e) {
      developer.log('❌ [SupportGroupService] Error checking join permission: $e');
      return false;
    }
  }

  /// Checks if a user can moderate a group
  Future<bool> canUserModerateGroup(String userId, String groupId) async {
    try {
      final group = await getGroup(groupId);
      if (group == null) return false;

      return group.facilitatorId == userId || group.moderatorIds.contains(userId);
    } catch (e) {
      developer.log('❌ [SupportGroupService] Error checking moderate permission: $e');
      return false;
    }
  }

  // ============================================================================
  // MEMBERSHIP MANAGEMENT
  // ============================================================================

  /// Adds a user to a group
  Future<bool> joinGroup(String userId, String groupId, ParticipantRole role) async {
    try {
      final db = await LocalDatabaseService.database;

      // Check if user can join
      if (!await canUserJoinGroup(userId, groupId)) {
        developer.log('⚠️ [SupportGroupService] User $userId cannot join group $groupId');
        return false;
      }

      // Create participant record
      final participantId = _uuid.v4();
      final participantData = {
        'id': participantId,
        'group_id': groupId,
        'user_id': userId,
        'role': role.toString().split('.').last,
        'joined_at': DateTime.now().toIso8601String(),
        'is_muted': 0,
        'is_active': 1,
      };

      await db.insert('support_group_participants', participantData);

      // Update group's member list
      final group = await getGroup(groupId);
      if (group != null) {
        final updatedMemberIds = [...group.memberIds, userId];
        await updateGroup(groupId, {'member_ids': updatedMemberIds});
      }

      developer.log('✅ [SupportGroupService] User $userId joined group $groupId as $role');
      return true;
    } catch (e) {
      developer.log('❌ [SupportGroupService] Error joining group: $e');
      return false;
    }
  }

  /// Removes a user from a group
  Future<bool> leaveGroup(String userId, String groupId) async {
    try {
      final db = await LocalDatabaseService.database;

      // Mark participant as inactive
      await db.update(
        'support_group_participants',
        {
          'is_active': 0,
          'left_at': DateTime.now().toIso8601String(),
        },
        where: 'group_id = ? AND user_id = ? AND is_active = ?',
        whereArgs: [groupId, userId, 1],
      );

      // Update group's member list
      final group = await getGroup(groupId);
      if (group != null) {
        final updatedMemberIds = group.memberIds.where((id) => id != userId).toList();
        await updateGroup(groupId, {'member_ids': updatedMemberIds});
      }

      developer.log('✅ [SupportGroupService] User $userId left group $groupId');
      return true;
    } catch (e) {
      developer.log('❌ [SupportGroupService] Error leaving group: $e');
      return false;
    }
  }

  /// Gets all members of a group
  Future<List<GroupParticipant>> getGroupMembers(String groupId) async {
    try {
      final db = await LocalDatabaseService.database;

      final results = await db.rawQuery('''
        SELECT p.*, u.display_name
        FROM support_group_participants p
        LEFT JOIN users u ON p.user_id = u.id
        WHERE p.group_id = ? AND p.is_active = 1
        ORDER BY p.joined_at ASC
      ''', [groupId]);

      return results.map((data) => GroupParticipant.fromMap(data)).toList();
    } catch (e) {
      developer.log('❌ [SupportGroupService] Error getting group members: $e');
      return [];
    }
  }

  /// Updates a member's role in a group
  Future<bool> updateMemberRole(
    String userId,
    String groupId,
    ParticipantRole newRole,
  ) async {
    try {
      final db = await LocalDatabaseService.database;

      await db.update(
        'support_group_participants',
        {'role': newRole.toString().split('.').last},
        where: 'group_id = ? AND user_id = ? AND is_active = ?',
        whereArgs: [groupId, userId, 1],
      );

      developer.log('✅ [SupportGroupService] Updated role for user $userId in group $groupId');
      return true;
    } catch (e) {
      developer.log('❌ [SupportGroupService] Error updating member role: $e');
      return false;
    }
  }

  // ============================================================================
  // INVITATION MANAGEMENT
  // ============================================================================

  /// Sends an invitation to join a group
  Future<String?> sendInvitation(
    String inviterId,
    String inviteeId,
    String groupId,
  ) async {
    try {
      final db = await LocalDatabaseService.database;

      // Check if inviter can moderate (only moderators can invite)
      if (!await canUserModerateGroup(inviterId, groupId)) {
        developer.log('⚠️ [SupportGroupService] User $inviterId cannot invite to group $groupId');
        return null;
      }

      // Check if invitation already exists
      final existing = await db.query(
        'support_group_invitations',
        where: 'group_id = ? AND invitee_id = ? AND status = ?',
        whereArgs: [groupId, inviteeId, 'pending'],
      );

      if (existing.isNotEmpty) {
        developer.log('⚠️ [SupportGroupService] Invitation already exists');
        return existing.first['id'] as String;
      }

      // Create invitation
      final invitationId = _uuid.v4();
      final invitationData = {
        'id': invitationId,
        'group_id': groupId,
        'inviter_id': inviterId,
        'invitee_id': inviteeId,
        'status': 'pending',
        'invited_at': DateTime.now().toIso8601String(),
      };

      await db.insert('support_group_invitations', invitationData);

      developer.log('✅ [SupportGroupService] Sent invitation to $inviteeId for group $groupId');

      // Send email notification (non-blocking - don't fail if email fails)
      _sendInvitationEmail(inviterId, inviteeId, groupId).catchError((error) {
        developer.log('⚠️ [SupportGroupService] Failed to send invitation email: $error');
      });

      return invitationId;
    } catch (e) {
      developer.log('❌ [SupportGroupService] Error sending invitation: $e');
      return null;
    }
  }

  /// Send invitation email notification (private helper method)
  Future<void> _sendInvitationEmail(
    String inviterId,
    String inviteeId,
    String groupId,
  ) async {
    try {
      final db = await LocalDatabaseService.database;

      // Get inviter details
      final inviterResult = await db.query('users', where: 'id = ?', whereArgs: [inviterId]);
      if (inviterResult.isEmpty) return;
      final inviterName = inviterResult.first['name'] as String? ?? 'A community member';

      // Get invitee details
      final inviteeResult = await db.query('users', where: 'id = ?', whereArgs: [inviteeId]);
      if (inviteeResult.isEmpty) return;
      final inviteeEmail = inviteeResult.first['email'] as String?;
      final inviteeName = inviteeResult.first['name'] as String? ?? 'User';

      if (inviteeEmail == null || inviteeEmail.isEmpty) return;

      // Get group details
      final group = await getGroup(groupId);
      if (group == null) return;

      // Send email
      final emailService = EmailNotificationService();
      await emailService.sendGroupInvitationEmail(
        recipientEmail: inviteeEmail,
        recipientName: inviteeName,
        inviterName: inviterName,
        groupName: group.name,
        groupDescription: group.description,
      );
    } catch (e) {
      developer.log('⚠️ [SupportGroupService] Email notification error: $e');
      // Don't rethrow - email is optional
    }
  }

  /// Accepts an invitation
  Future<bool> acceptInvitation(String invitationId) async {
    try {
      final db = await LocalDatabaseService.database;

      // Get invitation details
      final invitations = await db.query(
        'support_group_invitations',
        where: 'id = ?',
        whereArgs: [invitationId],
      );

      if (invitations.isEmpty) return false;

      final invitation = invitations.first;
      final groupId = invitation['group_id'] as String;
      final inviteeId = invitation['invitee_id'] as String;

      // Update invitation status
      await db.update(
        'support_group_invitations',
        {
          'status': 'accepted',
          'responded_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [invitationId],
      );

      // Add user to group as listener by default
      await joinGroup(inviteeId, groupId, ParticipantRole.listener);

      developer.log('✅ [SupportGroupService] Accepted invitation $invitationId');
      return true;
    } catch (e) {
      developer.log('❌ [SupportGroupService] Error accepting invitation: $e');
      return false;
    }
  }

  /// Rejects an invitation
  Future<bool> rejectInvitation(String invitationId) async {
    try {
      final db = await LocalDatabaseService.database;

      await db.update(
        'support_group_invitations',
        {
          'status': 'rejected',
          'responded_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [invitationId],
      );

      developer.log('✅ [SupportGroupService] Rejected invitation $invitationId');
      return true;
    } catch (e) {
      developer.log('❌ [SupportGroupService] Error rejecting invitation: $e');
      return false;
    }
  }

  /// Gets pending invitations for a user
  Future<List<GroupInvitation>> getUserInvitations(String userId) async {
    try {
      final db = await LocalDatabaseService.database;

      final results = await db.rawQuery('''
        SELECT i.*,
               u1.display_name as inviter_name,
               u2.display_name as invitee_name
        FROM support_group_invitations i
        LEFT JOIN users u1 ON i.inviter_id = u1.id
        LEFT JOIN users u2 ON i.invitee_id = u2.id
        WHERE i.invitee_id = ? AND i.status = ?
        ORDER BY i.invited_at DESC
      ''', [userId, 'pending']);

      return results.map((data) => GroupInvitation.fromMap(data)).toList();
    } catch (e) {
      developer.log('❌ [SupportGroupService] Error getting user invitations: $e');
      return [];
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Converts database row to SupportGroup model
  SupportGroup _supportGroupFromDb(Map<String, dynamic> data) {
    return SupportGroup(
      id: data['id'] as String,
      name: data['name'] as String,
      description: data['description'] as String? ?? '',
      type: GroupType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => GroupType.general,
      ),
      privacy: GroupPrivacy.values.firstWhere(
        (e) => e.toString().split('.').last == data['privacy'],
        orElse: () => GroupPrivacy.public,
      ),
      facilitatorId: data['facilitator_id'] as String?,
      memberIds: _decodeJsonList(data['member_ids'] as String?),
      moderatorIds: _decodeJsonList(data['moderator_ids'] as String?),
      createdAt: DateTime.parse(data['created_at'] as String? ?? DateTime.now().toIso8601String()),
      lastActivityAt: data['last_activity_at'] != null
          ? DateTime.parse(data['last_activity_at'] as String)
          : null,
      isActive: (data['is_active'] as int?) == 1,
      guidelines: _decodeJsonMap(data['guidelines'] as String?),
      maxMembers: data['max_members'] as int? ?? 50,
      tags: _decodeJsonList(data['tags'] as String?),
      isLive: (data['is_live'] as int?) == 1,
      hostName: data['host_name'] as String?,
      scheduledTime: data['scheduled_time'] != null
          ? DateTime.parse(data['scheduled_time'] as String)
          : null,
      agoraChannelName: data['agora_channel_name'] as String?,
    );
  }

  /// Decodes JSON string to list
  List<String> _decodeJsonList(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Decodes JSON string to map
  Map<String, String> _decodeJsonMap(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return {};
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value.toString()));
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  /// Gets invitation between user and group
  Future<GroupInvitation?> _getInvitation(String userId, String groupId) async {
    try {
      final db = await LocalDatabaseService.database;

      final results = await db.query(
        'support_group_invitations',
        where: 'group_id = ? AND invitee_id = ?',
        whereArgs: [groupId, userId],
        orderBy: 'invited_at DESC',
        limit: 1,
      );

      if (results.isEmpty) return null;

      return GroupInvitation.fromMap(results.first);
    } catch (e) {
      return null;
    }
  }
}
