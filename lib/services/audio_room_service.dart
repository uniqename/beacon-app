import 'dart:developer' as developer;
import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:rxdart/rxdart.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for managing real-time audio rooms using Agora RTC
///
/// Handles Agora engine initialization, channel operations, audio controls,
/// and participant state management for support group audio rooms.
class AudioRoomService {
  // Singleton pattern
  static final AudioRoomService _instance = AudioRoomService._internal();
  factory AudioRoomService() => _instance;
  AudioRoomService._internal();

  // Agora RTC Engine
  RtcEngine? _engine;

  // Current room state
  String? _currentChannelName;
  String? _currentUserId;
  bool _isInRoom = false;
  bool _isMuted = false;
  ClientRoleType _currentRole = ClientRoleType.clientRoleAudience;

  // Participant tracking
  final _participantsController = BehaviorSubject<Map<int, RoomParticipant>>.seeded({});
  final Map<int, RoomParticipant> _participants = {};

  // Audio state tracking
  final _audioStateController = BehaviorSubject<AudioRoomState>();
  final _speakingUsersController = BehaviorSubject<Set<int>>.seeded({});
  final Set<int> _speakingUsers = {};

  // Error handling
  final _errorController = StreamController<String>.broadcast();

  // Screen sharing state
  bool _isScreenSharing = false;
  int? _remoteScreenSharingUid;
  final _screenShareUidController = BehaviorSubject<int?>.seeded(null);

  // YouTube streaming state
  bool _isYouTubeStreaming = false;
  String? _activeYouTubeUrl;

  // Last initialization error — readable by screen after initialize() returns false
  String? _lastError;
  String? get lastError => _lastError;

  /// Stream of current participants in the room
  Stream<Map<int, RoomParticipant>> get participantsStream => _participantsController.stream;

  /// Stream of audio room state changes
  Stream<AudioRoomState> get audioStateStream => _audioStateController.stream;

  /// Stream of users currently speaking
  Stream<Set<int>> get speakingUsersStream => _speakingUsersController.stream;

  /// Stream of errors
  Stream<String> get errorStream => _errorController.stream;

  /// Current participants map
  Map<int, RoomParticipant> get participants => Map.unmodifiable(_participants);

  /// Whether currently in a room
  bool get isInRoom => _isInRoom;

  /// Whether local audio is muted
  bool get isMuted => _isMuted;

  /// Current participant count
  int get participantCount => _participants.length;

  /// Current channel name
  String? get currentChannelName => _currentChannelName;

  /// Current role
  ClientRoleType get currentRole => _currentRole;

  /// Whether user can speak (broadcaster role)
  bool get canSpeak => _currentRole == ClientRoleType.clientRoleBroadcaster;

  /// Stream of the UID currently sharing their screen (null = no share, 0 = local)
  Stream<int?> get screenShareStream => _screenShareUidController.stream;

  /// Whether local user is sharing their screen
  bool get isScreenSharing => _isScreenSharing;

  /// UID of remote user sharing their screen (null if none)
  int? get remoteScreenSharingUid => _remoteScreenSharingUid;

  /// Whether currently streaming to YouTube
  bool get isYouTubeStreaming => _isYouTubeStreaming;

  /// Direct engine access for AgoraVideoView widgets
  RtcEngine? get engine => _engine;

  /// Initialize Agora RTC Engine
  ///
  /// Must be called before joining any rooms. Pass the Agora App ID from .env.
  /// On failure, the reason is available via [lastError].
  Future<bool> initialize(String appId) async {
    _lastError = null;
    try {
      if (_engine != null) {
        developer.log('AudioRoomService: Engine already initialized');
        return true;
      }

      if (appId.isEmpty) {
        _lastError = 'Agora App ID not configured. Check your .env file.';
        return false;
      }

      // Permission is pre-checked by the screen before calling initialize().
      // This is a final safety-net in case the engine is called directly.
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        _lastError = micStatus.isPermanentlyDenied
            ? 'Microphone access is off for Beacon.\n\nGo to Settings → Beacon → Microphone and turn it ON, then tap Retry.'
            : 'Microphone permission required. Tap Retry and allow microphone access.';
        return false;
      }

      // Create RTC engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        audioScenario: AudioScenarioType.audioScenarioChatroom,
      ));

      // Register event handlers
      _registerEventHandlers();

      // Configure audio and video (video needed for screen sharing)
      await _engine!.enableAudio();
      await _engine!.enableVideo();
      await _engine!.muteLocalVideoStream(true); // camera off by default
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileMusicStandardStereo,
        scenario: AudioScenarioType.audioScenarioChatroom,
      );

      // Enable audio volume indication (for speaking indicators)
      await _engine!.enableAudioVolumeIndication(
        interval: 200,
        smooth: 3,
        reportVad: true,
      );

      developer.log('AudioRoomService: Initialized successfully');
      return true;
    } catch (e) {
      developer.log('AudioRoomService: Initialization error: $e');
      _lastError = 'Audio engine error: $e';
      return false;
    }
  }

  /// Register Agora event handlers
  void _registerEventHandlers() {
    if (_engine == null) return;

    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        developer.log('AudioRoomService: Joined channel ${connection.channelId}');
        _isInRoom = true;
        _updateAudioState();
      },
      onLeaveChannel: (connection, stats) {
        developer.log('AudioRoomService: Left channel');
        _isInRoom = false;
        _participants.clear();
        _speakingUsers.clear();
        _participantsController.add({});
        _speakingUsersController.add({});
        _updateAudioState();
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        developer.log('AudioRoomService: User $remoteUid joined');
        _participants[remoteUid] = RoomParticipant(
          uid: remoteUid,
          isSpeaking: false,
          audioLevel: 0,
          isMuted: false,
        );
        _participantsController.add(Map.from(_participants));
      },
      onUserOffline: (connection, remoteUid, reason) {
        developer.log('AudioRoomService: User $remoteUid left (reason: $reason)');
        _participants.remove(remoteUid);
        _speakingUsers.remove(remoteUid);
        _participantsController.add(Map.from(_participants));
        _speakingUsersController.add(Set.from(_speakingUsers));
      },
      onAudioVolumeIndication: (connection, speakers, speakerNumber, totalVolume) {
        // Update speaking state and audio levels
        final wasEmpty = _speakingUsers.isEmpty;
        _speakingUsers.clear();

        for (final speaker in speakers) {
          if (speaker.uid == 0) {
            // Local user
            if (speaker.volume! > 10) {
              _speakingUsers.add(0);
            }
          } else {
            // Remote user
            final participant = _participants[speaker.uid];
            if (participant != null) {
              _participants[speaker.uid!] = participant.copyWith(
                audioLevel: speaker.volume,
                isSpeaking: speaker.volume! > 10,
              );

              if (speaker.volume! > 10) {
                _speakingUsers.add(speaker.uid!);
              }
            }
          }
        }

        if (wasEmpty != _speakingUsers.isEmpty || speakerNumber > 0) {
          _participantsController.add(Map.from(_participants));
          _speakingUsersController.add(Set.from(_speakingUsers));
        }
      },
      onRemoteAudioStateChanged: (connection, remoteUid, state, reason, elapsed) {
        final participant = _participants[remoteUid];
        if (participant != null) {
          final isMuted = state == RemoteAudioState.remoteAudioStateStopped;

          _participants[remoteUid] = participant.copyWith(isMuted: isMuted);
          _participantsController.add(Map.from(_participants));
        }
      },
      onError: (err, msg) {
        developer.log('AudioRoomService: Error $err - $msg');
        _errorController.add('Audio error: $msg');
      },
      onRemoteVideoStateChanged: (connection, remoteUid, state, reason, elapsed) {
        if (state == RemoteVideoState.remoteVideoStateDecoding) {
          _remoteScreenSharingUid = remoteUid;
          _screenShareUidController.add(remoteUid);
          developer.log('AudioRoomService: Remote user $remoteUid started screen share');
        } else if (state == RemoteVideoState.remoteVideoStateStopped &&
            _remoteScreenSharingUid == remoteUid) {
          _remoteScreenSharingUid = null;
          _screenShareUidController.add(null);
          developer.log('AudioRoomService: Remote user $remoteUid stopped screen share');
        }
      },
      onClientRoleChanged: (connection, oldRole, newRole, newRoleOptions) {
        developer.log('AudioRoomService: Role changed from $oldRole to $newRole');
        _currentRole = newRole;
        _updateAudioState();
      },
    ));
  }

  /// Join an audio room
  ///
  /// [channelName] - Unique identifier for the room
  /// [userId] - User ID (converted to int for Agora)
  /// [joinAsSpeaker] - If true, join as broadcaster (can speak), else audience (listen only)
  /// [token] - Optional Agora token for secure channels
  Future<bool> joinRoom({
    required String channelName,
    required String userId,
    required bool joinAsSpeaker,
    String? token,
  }) async {
    try {
      if (_engine == null) {
        _errorController.add('Audio engine not initialized');
        return false;
      }

      if (_isInRoom) {
        developer.log('AudioRoomService: Already in a room, leaving first');
        await leaveRoom();
      }


      // Convert string userId to int (Agora requires int UIDs)
      final uid = userId.hashCode.abs();

      // Set client role
      final role = joinAsSpeaker
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience;

      await _engine!.setClientRole(role: role);
      _currentRole = role;

      // Join channel with correct role
      await _engine!.joinChannel(
        token: token ?? '',
        channelId: channelName,
        uid: uid,
        options: ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: role,
          autoSubscribeAudio: true,
          publishMicrophoneTrack: joinAsSpeaker,
        ),
      );

      _currentChannelName = channelName;
      _currentUserId = userId;
      _isMuted = false;

      developer.log('AudioRoomService: Joining room $channelName as ${joinAsSpeaker ? "speaker" : "listener"}');
      return true;
    } catch (e) {
      developer.log('AudioRoomService: Error joining room: $e');
      _errorController.add('Failed to join room: $e');
      return false;
    }
  }

  /// Leave the current audio room
  Future<void> leaveRoom() async {
    try {
      if (_engine == null || !_isInRoom) return;

      if (_isScreenSharing) await stopScreenShare();
      if (_isYouTubeStreaming) await stopYouTubeStream();

      await _engine!.leaveChannel();

      _currentChannelName = null;
      _currentUserId = null;
      _isInRoom = false;
      _isMuted = false;
      _isScreenSharing = false;
      _remoteScreenSharingUid = null;
      _isYouTubeStreaming = false;
      _activeYouTubeUrl = null;
      _participants.clear();
      _speakingUsers.clear();

      _participantsController.add({});
      _speakingUsersController.add({});
      _screenShareUidController.add(null);
      _updateAudioState();

      developer.log('AudioRoomService: Left room');
    } catch (e) {
      developer.log('AudioRoomService: Error leaving room: $e');
      _errorController.add('Failed to leave room: $e');
    }
  }

  /// Switch role between speaker (broadcaster) and listener (audience)
  Future<bool> switchRole(bool isSpeaker) async {
    try {
      if (_engine == null || !_isInRoom) {
        _errorController.add('Not in a room');
        return false;
      }

      final role = isSpeaker
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience;

      await _engine!.setClientRole(role: role);
      _currentRole = role;

      // If becoming a listener, mute automatically
      if (!isSpeaker) {
        await muteLocalAudio();
      }

      _updateAudioState();
      developer.log('AudioRoomService: Switched to ${isSpeaker ? "speaker" : "listener"}');
      return true;
    } catch (e) {
      developer.log('AudioRoomService: Error switching role: $e');
      _errorController.add('Failed to switch role: $e');
      return false;
    }
  }

  /// Mute local audio (stop sending audio to room)
  Future<void> muteLocalAudio() async {
    try {
      if (_engine == null || !_isInRoom) return;

      await _engine!.muteLocalAudioStream(true);
      _isMuted = true;
      _speakingUsers.remove(0); // Remove self from speaking users
      _speakingUsersController.add(Set.from(_speakingUsers));
      _updateAudioState();

      developer.log('AudioRoomService: Muted local audio');
    } catch (e) {
      developer.log('AudioRoomService: Error muting: $e');
      _errorController.add('Failed to mute: $e');
    }
  }

  /// Unmute local audio (start sending audio to room)
  Future<void> unmuteLocalAudio() async {
    try {
      if (_engine == null || !_isInRoom) return;

      if (_currentRole != ClientRoleType.clientRoleBroadcaster) {
        _errorController.add('Cannot unmute as listener');
        return;
      }

      await _engine!.muteLocalAudioStream(false);
      _isMuted = false;
      _updateAudioState();

      developer.log('AudioRoomService: Unmuted local audio');
    } catch (e) {
      developer.log('AudioRoomService: Error unmuting: $e');
      _errorController.add('Failed to unmute: $e');
    }
  }

  /// Toggle mute state
  Future<void> toggleMute() async {
    if (_isMuted) {
      await unmuteLocalAudio();
    } else {
      await muteLocalAudio();
    }
  }

  /// Start "presenting" mode — enables camera video so the facilitator
  /// can show their face/materials to the room. Full screen-capture requires
  /// a native broadcast extension (iOS) or MediaProjection service (Android)
  /// which are not yet configured. Camera-presenting works on all devices.
  Future<bool> startScreenShare() async {
    try {
      if (_engine == null || !_isInRoom) {
        _errorController.add('Join a room first before presenting');
        return false;
      }

      // Request camera permission for presenter mode
      final camStatus = await Permission.camera.status;
      if (camStatus.isPermanentlyDenied) {
        _errorController.add('Camera permission permanently denied.\nGo to Settings → Beacon → Camera and turn it ON.');
        return false;
      }
      final camPermission = await Permission.camera.request();
      if (!camPermission.isGranted) {
        _errorController.add('Camera permission is required for presenter mode.');
        return false;
      }

      // Promote to broadcaster if needed
      if (_currentRole != ClientRoleType.clientRoleBroadcaster) {
        await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
        _currentRole = ClientRoleType.clientRoleBroadcaster;
      }

      // Enable camera video for presenting
      await _engine!.enableLocalVideo(true);
      await _engine!.muteLocalVideoStream(false);
      await _engine!.updateChannelMediaOptions(const ChannelMediaOptions(
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        publishScreenCaptureVideo: false,
      ));

      _isScreenSharing = true;
      _screenShareUidController.add(0);
      developer.log('AudioRoomService: Presenter mode started (camera video)');
      return true;
    } catch (e) {
      developer.log('AudioRoomService: Presenter mode error: $e');
      _errorController.add('Could not start presenter mode: $e');
      return false;
    }
  }

  /// Stop presenting (camera video off)
  Future<void> stopScreenShare() async {
    try {
      if (_engine == null) return;

      await _engine!.muteLocalVideoStream(true);
      await _engine!.enableLocalVideo(false);
      await _engine!.updateChannelMediaOptions(const ChannelMediaOptions(
        publishCameraTrack: false,
        publishMicrophoneTrack: true,
        publishScreenCaptureVideo: false,
      ));

      _isScreenSharing = false;
      _screenShareUidController.add(null);
      developer.log('AudioRoomService: Screen sharing stopped');
    } catch (e) {
      developer.log('AudioRoomService: Error stopping screen share: $e');
      _errorController.add('Failed to stop screen share: $e');
    }
  }

  /// Stream the session to YouTube via Agora RTMP push.
  ///
  /// Requires Agora Media Push enabled in Agora Console.
  /// [streamKey] — from YouTube Studio → Go Live → Stream → Stream key
  Future<bool> startYouTubeStream(String streamKey) async {
    try {
      if (_engine == null || !_isInRoom) return false;

      _activeYouTubeUrl = 'rtmp://a.rtmp.youtube.com/live2/$streamKey';
      final uid = _currentUserId?.hashCode.abs() ?? 0;

      final transcoding = LiveTranscoding(
        width: 1280,
        height: 720,
        videoBitrate: 1500,
        videoFramerate: 15,
        audioSampleRate: AudioSampleRateType.audioSampleRate44100,
        audioBitrate: 128,
        audioChannels: 2,
        transcodingUsers: [
          TranscodingUser(
            uid: uid,
            x: 0,
            y: 0,
            width: 1280,
            height: 720,
            zOrder: 0,
            alpha: 1.0,
          ),
        ],
      );

      await _engine!.startRtmpStreamWithTranscoding(
        url: _activeYouTubeUrl!,
        transcoding: transcoding,
      );

      _isYouTubeStreaming = true;
      developer.log('AudioRoomService: YouTube stream started');
      return true;
    } catch (e) {
      developer.log('AudioRoomService: YouTube stream error: $e');
      _errorController.add('YouTube stream failed: $e');
      return false;
    }
  }

  /// Stop YouTube RTMP stream
  Future<void> stopYouTubeStream() async {
    try {
      if (_engine == null || _activeYouTubeUrl == null) return;
      await _engine!.stopRtmpStream(_activeYouTubeUrl!);
      _isYouTubeStreaming = false;
      _activeYouTubeUrl = null;
      developer.log('AudioRoomService: YouTube stream stopped');
    } catch (e) {
      developer.log('AudioRoomService: Error stopping YouTube stream: $e');
      _errorController.add('Failed to stop YouTube stream: $e');
    }
  }

  /// Adjust playback volume for all remote users
  ///
  /// [volume] - Volume level (0-100)
  Future<void> adjustPlaybackVolume(int volume) async {
    try {
      if (_engine == null) return;

      final clampedVolume = volume.clamp(0, 100);
      await _engine!.adjustPlaybackSignalVolume(clampedVolume);

      developer.log('AudioRoomService: Adjusted playback volume to $clampedVolume');
    } catch (e) {
      developer.log('AudioRoomService: Error adjusting volume: $e');
    }
  }

  /// Adjust recording volume for local audio
  ///
  /// [volume] - Volume level (0-100)
  Future<void> adjustRecordingVolume(int volume) async {
    try {
      if (_engine == null) return;

      final clampedVolume = volume.clamp(0, 100);
      await _engine!.adjustRecordingSignalVolume(clampedVolume);

      developer.log('AudioRoomService: Adjusted recording volume to $clampedVolume');
    } catch (e) {
      developer.log('AudioRoomService: Error adjusting recording volume: $e');
    }
  }

  /// Enable/disable speaker phone
  Future<void> setSpeakerphone(bool enabled) async {
    try {
      if (_engine == null) return;

      await _engine!.setEnableSpeakerphone(enabled);
      developer.log('AudioRoomService: Speakerphone ${enabled ? "enabled" : "disabled"}');
    } catch (e) {
      developer.log('AudioRoomService: Error setting speakerphone: $e');
    }
  }

  /// Mute a specific remote participant (moderator action)
  ///
  /// Note: This mutes the participant locally for all users in the room.
  /// In Agora, moderators can adjust playback volume for specific users.
  /// [uid] - The participant's UID to mute
  Future<bool> muteRemoteParticipant(int uid) async {
    try {
      if (_engine == null || !_isInRoom) {
        _errorController.add('Not in a room');
        return false;
      }

      // Adjust playback volume to 0 for this specific user
      await _engine!.adjustUserPlaybackSignalVolume(uid: uid, volume: 0);

      // Update local participant state
      final participant = _participants[uid];
      if (participant != null) {
        _participants[uid] = participant.copyWith(isMuted: true);
        _participantsController.add(Map.from(_participants));
      }

      developer.log('AudioRoomService: Muted remote participant $uid');
      return true;
    } catch (e) {
      developer.log('AudioRoomService: Error muting remote participant: $e');
      _errorController.add('Failed to mute participant: $e');
      return false;
    }
  }

  /// Unmute a specific remote participant (moderator action)
  ///
  /// [uid] - The participant's UID to unmute
  Future<bool> unmuteRemoteParticipant(int uid) async {
    try {
      if (_engine == null || !_isInRoom) {
        _errorController.add('Not in a room');
        return false;
      }

      // Restore playback volume to 100 for this specific user
      await _engine!.adjustUserPlaybackSignalVolume(uid: uid, volume: 100);

      // Update local participant state
      final participant = _participants[uid];
      if (participant != null) {
        _participants[uid] = participant.copyWith(isMuted: false);
        _participantsController.add(Map.from(_participants));
      }

      developer.log('AudioRoomService: Unmuted remote participant $uid');
      return true;
    } catch (e) {
      developer.log('AudioRoomService: Error unmuting remote participant: $e');
      _errorController.add('Failed to unmute participant: $e');
      return false;
    }
  }

  /// Remove a participant from the room (moderator action)
  ///
  /// Note: In Agora, you can't directly kick users from the client side.
  /// This method removes them from the local participant list and mutes them.
  /// For production, implement server-side removal via token revocation.
  /// [uid] - The participant's UID to remove
  Future<bool> removeParticipant(int uid) async {
    try {
      if (_engine == null || !_isInRoom) {
        _errorController.add('Not in a room');
        return false;
      }

      // Mute them first (immediate feedback)
      await muteRemoteParticipant(uid);

      // Remove from local participant list
      _participants.remove(uid);
      _speakingUsers.remove(uid);
      _participantsController.add(Map.from(_participants));
      _speakingUsersController.add(Set.from(_speakingUsers));

      developer.log('AudioRoomService: Removed participant $uid from room');
      return true;
    } catch (e) {
      developer.log('AudioRoomService: Error removing participant: $e');
      _errorController.add('Failed to remove participant: $e');
      return false;
    }
  }

  /// Update and broadcast audio state
  void _updateAudioState() {
    _audioStateController.add(AudioRoomState(
      isInRoom: _isInRoom,
      isMuted: _isMuted,
      canSpeak: _currentRole == ClientRoleType.clientRoleBroadcaster,
      participantCount: _participants.length,
      channelName: _currentChannelName,
    ));
  }

  /// Force-release the engine without closing streams.
  /// Call this before retrying initialize() after a failure.
  Future<void> resetEngine() async {
    try {
      if (_isInRoom) await leaveRoom();
      await _engine?.release();
      _engine = null;
      _lastError = null;
      developer.log('AudioRoomService: Engine reset');
    } catch (e) {
      developer.log('AudioRoomService: resetEngine error: $e');
      _engine = null;
    }
  }

  /// Dispose the service and release resources
  Future<void> dispose() async {
    try {
      if (_isInRoom) {
        await leaveRoom();
      }

      await _engine?.release();
      _engine = null;

      await _participantsController.close();
      await _audioStateController.close();
      await _speakingUsersController.close();
      await _screenShareUidController.close();
      await _errorController.close();

      developer.log('AudioRoomService: Disposed');
    } catch (e) {
      developer.log('AudioRoomService: Error disposing: $e');
    }
  }
}

/// Represents a participant in an audio room
class RoomParticipant {
  final int uid;
  final bool isSpeaking;
  final int audioLevel;
  final bool isMuted;

  const RoomParticipant({
    required this.uid,
    required this.isSpeaking,
    required this.audioLevel,
    required this.isMuted,
  });

  RoomParticipant copyWith({
    int? uid,
    bool? isSpeaking,
    int? audioLevel,
    bool? isMuted,
  }) {
    return RoomParticipant(
      uid: uid ?? this.uid,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      audioLevel: audioLevel ?? this.audioLevel,
      isMuted: isMuted ?? this.isMuted,
    );
  }

  @override
  String toString() {
    return 'RoomParticipant(uid: $uid, speaking: $isSpeaking, level: $audioLevel, muted: $isMuted)';
  }
}

/// Current state of the audio room
class AudioRoomState {
  final bool isInRoom;
  final bool isMuted;
  final bool canSpeak;
  final int participantCount;
  final String? channelName;

  const AudioRoomState({
    required this.isInRoom,
    required this.isMuted,
    required this.canSpeak,
    required this.participantCount,
    this.channelName,
  });

  @override
  String toString() {
    return 'AudioRoomState(inRoom: $isInRoom, muted: $isMuted, canSpeak: $canSpeak, participants: $participantCount)';
  }
}
