
enum GroupType { general, survivors, mothers, legal, healing, skills }

enum GroupPrivacy { public, private, anonymous }

class SupportGroup {
  final String id;
  final String name;
  final String description;
  final GroupType type;
  final GroupPrivacy privacy;
  final String? facilitatorId;
  final List<String> memberIds;
  final List<String> moderatorIds;
  final DateTime createdAt;
  final DateTime? lastActivityAt;
  final bool isActive;
  final Map<String, String> guidelines;
  final int maxMembers;
  final List<String> tags;
  final bool isLive;
  final String? hostName;
  final DateTime? scheduledTime;
  final String? agoraChannelName;

  const SupportGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.privacy,
    this.facilitatorId,
    this.memberIds = const [],
    this.moderatorIds = const [],
    required this.createdAt,
    this.lastActivityAt,
    this.isActive = true,
    this.guidelines = const {},
    this.maxMembers = 50,
    this.tags = const [],
    this.isLive = false,
    this.hostName,
    this.scheduledTime,
    this.agoraChannelName,
  });

  factory SupportGroup.fromMap(Map<String, dynamic> data) {
    return SupportGroup(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: GroupType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => GroupType.general,
      ),
      privacy: GroupPrivacy.values.firstWhere(
        (e) => e.toString().split('.').last == data['privacy'],
        orElse: () => GroupPrivacy.public,
      ),
      facilitatorId: data['facilitatorId'],
      memberIds: data['memberIds'] != null
          ? List<String>.from(data['memberIds'])
          : [],
      moderatorIds: data['moderatorIds'] != null
          ? List<String>.from(data['moderatorIds'])
          : [],
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      lastActivityAt: data['lastActivityAt'] != null
          ? DateTime.parse(data['lastActivityAt'])
          : null,
      isActive: data['isActive'] ?? true,
      guidelines: data['guidelines'] != null
          ? Map<String, String>.from(data['guidelines'])
          : {},
      maxMembers: data['maxMembers'] ?? 50,
      tags: data['tags'] != null
          ? List<String>.from(data['tags'])
          : [],
      isLive: data['isLive'] ?? false,
      hostName: data['hostName'],
      scheduledTime: data['scheduledTime'] != null
          ? DateTime.parse(data['scheduledTime'])
          : null,
      agoraChannelName: data['agoraChannelName'] ?? data['agora_channel_name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'privacy': privacy.toString().split('.').last,
      'facilitatorId': facilitatorId,
      'memberIds': memberIds,
      'moderatorIds': moderatorIds,
      'createdAt': createdAt.toIso8601String(),
      'lastActivityAt': lastActivityAt?.toIso8601String(),
      'isActive': isActive,
      'guidelines': guidelines,
      'maxMembers': maxMembers,
      'tags': tags,
      'isLive': isLive,
      'hostName': hostName,
      'scheduledTime': scheduledTime?.toIso8601String(),
      'agoraChannelName': agoraChannelName,
    };
  }

  bool get isFull => memberIds.length >= maxMembers;
  
  int get memberCount => memberIds.length;

  String get typeDisplayName {
    switch (type) {
      case GroupType.general:
        return 'General Support';
      case GroupType.survivors:
        return 'Survivors Circle';
      case GroupType.mothers:
        return 'Mothers Support';
      case GroupType.legal:
        return 'Legal Guidance';
      case GroupType.healing:
        return 'Healing Journey';
      case GroupType.skills:
        return 'Skills & Employment';
    }
  }

  /// Helper method to check if a user is the facilitator of this group
  bool isUserFacilitator(String userId) => facilitatorId == userId;

  /// Helper method to check if a user is a moderator of this group
  bool isUserModerator(String userId) => moderatorIds.contains(userId);

  /// Helper method to check if a user can speak in this group
  /// (facilitators and moderators can always speak)
  bool canUserSpeak(String userId) =>
      isUserFacilitator(userId) || isUserModerator(userId);

  /// Helper method to check if a user has moderation privileges
  bool canUserModerate(String userId) =>
      isUserFacilitator(userId) || isUserModerator(userId);

  /// Helper method to check if a user is a member of this group
  bool isUserMember(String userId) =>
      memberIds.contains(userId) ||
      isUserFacilitator(userId) ||
      isUserModerator(userId);

  /// Returns true if this is a scheduled group (has a scheduled time in the future)
  bool get isScheduled =>
      scheduledTime != null && scheduledTime!.isAfter(DateTime.now());

  /// Returns true if this is an ongoing group (not live, not scheduled)
  bool get isOngoing => !isLive && !isScheduled;

  /// Returns countdown to scheduled time if applicable
  Duration? get timeUntilScheduled {
    if (scheduledTime == null) return null;
    final now = DateTime.now();
    if (scheduledTime!.isBefore(now)) return null;
    return scheduledTime!.difference(now);
  }

  /// Returns formatted countdown string (e.g., "in 2h", "in 30m")
  String? get scheduledCountdown {
    final duration = timeUntilScheduled;
    if (duration == null) return null;

    final minutes = duration.inMinutes;
    if (minutes < 60) {
      return 'in ${minutes}m';
    }
    final hours = duration.inHours;
    if (hours < 24) {
      return 'in ${hours}h';
    }
    final days = duration.inDays;
    return 'in ${days}d';
  }

  /// Creates a copy with updated fields
  SupportGroup copyWith({
    String? id,
    String? name,
    String? description,
    GroupType? type,
    GroupPrivacy? privacy,
    String? facilitatorId,
    List<String>? memberIds,
    List<String>? moderatorIds,
    DateTime? createdAt,
    DateTime? lastActivityAt,
    bool? isActive,
    Map<String, String>? guidelines,
    int? maxMembers,
    List<String>? tags,
    bool? isLive,
    String? hostName,
    DateTime? scheduledTime,
    String? agoraChannelName,
  }) {
    return SupportGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      privacy: privacy ?? this.privacy,
      facilitatorId: facilitatorId ?? this.facilitatorId,
      memberIds: memberIds ?? this.memberIds,
      moderatorIds: moderatorIds ?? this.moderatorIds,
      createdAt: createdAt ?? this.createdAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      isActive: isActive ?? this.isActive,
      guidelines: guidelines ?? this.guidelines,
      maxMembers: maxMembers ?? this.maxMembers,
      tags: tags ?? this.tags,
      isLive: isLive ?? this.isLive,
      hostName: hostName ?? this.hostName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      agoraChannelName: agoraChannelName ?? this.agoraChannelName,
    );
  }
}

class GroupMessage {
  final String id;
  final String groupId;
  final String senderId;
  final String? senderDisplayName;
  final String content;
  final DateTime sentAt;
  final bool isAnonymous;
  final List<String> supportedBy;
  final bool isModerated;
  final String? moderatorNote;

  const GroupMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    this.senderDisplayName,
    required this.content,
    required this.sentAt,
    this.isAnonymous = false,
    this.supportedBy = const [],
    this.isModerated = false,
    this.moderatorNote,
  });

  factory GroupMessage.fromMap(Map<String, dynamic> data) {
    return GroupMessage(
      id: data['id'] ?? '',
      groupId: data['groupId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderDisplayName: data['senderDisplayName'],
      content: data['content'] ?? '',
      sentAt: DateTime.parse(data['sentAt'] ?? DateTime.now().toIso8601String()),
      isAnonymous: data['isAnonymous'] ?? false,
      supportedBy: data['supportedBy'] != null 
          ? List<String>.from(data['supportedBy']) 
          : [],
      isModerated: data['isModerated'] ?? false,
      moderatorNote: data['moderatorNote'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'senderId': senderId,
      'senderDisplayName': senderDisplayName,
      'content': content,
      'sentAt': sentAt.toIso8601String(),
      'isAnonymous': isAnonymous,
      'supportedBy': supportedBy,
      'isModerated': isModerated,
      'moderatorNote': moderatorNote,
    };
  }

  int get supportCount => supportedBy.length;
}

class SupportResource {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String? authorName;
  final DateTime createdAt;
  final List<String> tags;
  final bool isVerified;
  final List<String> helpfulVotes;

  const SupportResource({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    this.authorName,
    required this.createdAt,
    this.tags = const [],
    this.isVerified = false,
    this.helpfulVotes = const [],
  });

  factory SupportResource.fromMap(Map<String, dynamic> data) {
    return SupportResource(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'],
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      tags: data['tags'] != null 
          ? List<String>.from(data['tags']) 
          : [],
      isVerified: data['isVerified'] ?? false,
      helpfulVotes: data['helpfulVotes'] != null 
          ? List<String>.from(data['helpfulVotes']) 
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
      'isVerified': isVerified,
      'helpfulVotes': helpfulVotes,
    };
  }

  int get helpfulCount => helpfulVotes.length;
}