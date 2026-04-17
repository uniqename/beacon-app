import 'dart:async';
import 'dart:developer' as developer;
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../../constants/brand_colors.dart';
import '../../models/support_group.dart';
import '../../models/group_participant.dart';
import '../../services/audio_room_service.dart';
import '../../services/support_group_service.dart';
import '../../services/agora_token_service.dart';
import '../../services/auth_service.dart';
import 'report_dialog.dart';

/// Clubhouse-style audio room screen for real-time support group sessions
///
/// Features:
/// - Live audio communication
/// - Stage (speakers) and Audience (listeners) sections
/// - Speaking indicators with Vibrant Orange pulse animation
/// - Role-based controls (facilitator, moderator, speaker, listener)
/// - Raise hand to request speaking permission
class AudioRoomScreen extends StatefulWidget {
  final SupportGroup group;

  const AudioRoomScreen({
    super.key,
    required this.group,
  });

  @override
  State<AudioRoomScreen> createState() => _AudioRoomScreenState();
}

class _AudioRoomScreenState extends State<AudioRoomScreen> with TickerProviderStateMixin {
  final AudioRoomService _audioService = AudioRoomService();
  final SupportGroupService _groupService = SupportGroupService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  StreamSubscription? _participantsSubscription;
  StreamSubscription? _audioStateSubscription;
  StreamSubscription? _speakingUsersSubscription;
  StreamSubscription? _errorSubscription;

  Map<int, RoomParticipant> _participants = {};
  AudioRoomState? _audioState;
  Set<int> _speakingUsers = {};
  bool _isLoading = true;
  bool _hasRaisedHand = false;
  bool _audioUnavailable = false;
  bool _screenShareGranted = false;
  String? _errorMessage;

  // Screen sharing
  StreamSubscription? _screenShareSubscription;
  bool _isScreenSharing = false;
  int? _remoteScreenSharingUid;

  // YouTube streaming
  bool _isYouTubeStreaming = false;
  String? _youtubeStreamKey;

  // Current user info
  String? _currentUserId;
  ParticipantRole? _currentUserRole;
  GroupParticipant? _currentParticipant;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeRoom();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeRoom() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser == null || currentUser.isAnonymous) {
        _showError('User not logged in');
        return;
      }

      _currentUserId = currentUser.id;

      // Check if user can join this group
      final canJoin = await _groupService.canUserJoinGroup(currentUser.id, widget.group.id);
      if (!canJoin) {
        _showError('You do not have permission to join this group');
        if (mounted) Navigator.of(context).pop();
        return;
      }

      // Determine user's role in the group
      final isFacilitator = widget.group.isUserFacilitator(currentUser.id);
      final isModerator = widget.group.isUserModerator(currentUser.id);

      _currentUserRole = isFacilitator
          ? ParticipantRole.facilitator
          : isModerator
              ? ParticipantRole.moderator
              : ParticipantRole.listener;

      // Join the group in database
      await _groupService.joinGroup(
        currentUser.id,
        widget.group.id,
        _currentUserRole!,
      );

      // Initialize Agora + join channel
      await _initAudioAndJoin();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      developer.log('AudioRoomScreen: Error initializing room: $e');
      if (mounted) {
        setState(() {
          _audioUnavailable = true;
          _errorMessage = 'Room error: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Initialise Agora engine and join the channel.
  /// Can be called independently for retry without re-doing DB operations.
  Future<void> _initAudioAndJoin() async {
    if (_currentUserId == null) return;

    // ── Step 1: Request microphone permission FIRST ─────────────────────────
    // This MUST happen before any Agora calls so iOS registers the permission
    // and it appears in Settings → Beacon → Microphone.
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      if (mounted) {
        setState(() {
          _audioUnavailable = true;
          _errorMessage = micStatus.isPermanentlyDenied
              ? 'Microphone access is turned off for Beacon.\n\nTap "Open Settings" → find Microphone → turn it ON → come back and tap Retry.'
              : 'Beacon needs microphone access for audio rooms.\n\nTap Retry and allow microphone when the dialog appears.';
        });
      }
      return;
    }

    // ── Step 2: Verify App ID ───────────────────────────────────────────────
    final agoraAppId = dotenv.env['AGORA_APP_ID'] ?? '';
    if (agoraAppId.isEmpty) {
      if (mounted) setState(() { _audioUnavailable = true; _errorMessage = 'AGORA_APP_ID not configured in .env'; });
      return;
    }

    // ── Step 3: Initialize Agora engine ────────────────────────────────────
    final initialized = await _audioService.initialize(agoraAppId);
    if (!initialized) {
      if (mounted) {
        setState(() {
          _audioUnavailable = true;
          _errorMessage = _audioService.lastError ?? 'Agora engine failed to initialize';
        });
      }
      return;
    }

    // Engine is up — set up stream listeners
    _setupAudioSubscriptions();

    // Fetch token (optional — works without one when App Certificate is disabled)
    String? token;
    final tokenServerUrl = dotenv.env['AGORA_TOKEN_SERVER_URL'] ?? '';
    if (tokenServerUrl.isNotEmpty) {
      try {
        final tokenService = AgoraTokenService(tokenServerUrl: tokenServerUrl);
        token = await tokenService.fetchToken(
          channelName: widget.group.agoraChannelName ?? widget.group.id,
          userId: _currentUserId!,
          role: _currentUserRole == ParticipantRole.listener ? 'listener' : 'speaker',
        );
        developer.log('AudioRoomScreen: Token ${token != null ? "fetched" : "null — using no-token mode"}');
      } catch (e) {
        developer.log('AudioRoomScreen: Token fetch exception: $e — continuing without token');
      }
    }

    final joinAsSpeaker = _currentUserRole != ParticipantRole.listener;
    final joined = await _audioService.joinRoom(
      channelName: widget.group.agoraChannelName ?? widget.group.id,
      userId: _currentUserId!,
      joinAsSpeaker: joinAsSpeaker,
      token: token,
    );

    if (!joined && mounted) {
      setState(() {
        _audioUnavailable = true;
        _errorMessage = 'Failed to join audio channel. Check your Agora App Certificate setting in the Agora Console.';
      });
    }
  }

  /// Wire up all reactive stream subscriptions to the AudioRoomService.
  void _setupAudioSubscriptions() {
    _participantsSubscription?.cancel();
    _audioStateSubscription?.cancel();
    _speakingUsersSubscription?.cancel();
    _errorSubscription?.cancel();
    _screenShareSubscription?.cancel();

    _participantsSubscription = _audioService.participantsStream.listen((participants) {
      if (mounted) setState(() => _participants = participants);
    });
    _audioStateSubscription = _audioService.audioStateStream.listen((state) {
      if (mounted) setState(() => _audioState = state);
    });
    _speakingUsersSubscription = _audioService.speakingUsersStream.listen((users) {
      if (mounted) setState(() => _speakingUsers = users);
    });
    _errorSubscription = _audioService.errorStream.listen((error) {
      if (mounted) _showError(error);
    });
    _screenShareSubscription = _audioService.screenShareStream.listen((uid) {
      if (mounted) setState(() => _remoteScreenSharingUid = uid);
    });
  }

  /// Retry audio after a permission fix or transient failure.
  Future<void> _retryAudio() async {
    if (!mounted) return;
    setState(() {
      _audioUnavailable = false;
      _errorMessage = null;
    });
    // Reset engine so initialize() runs fresh (not the cached null-engine path)
    await _audioService.resetEngine();
    await _initAudioAndJoin();
  }

  void _showError(String message) {
    developer.log('AudioRoomScreen: $message');
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _isLoading = false;
        _audioUnavailable = true;
      });
    }
  }

  Future<void> _leaveRoom() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Room?'),
        content: const Text('Are you sure you want to leave this support group session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: BeaconColors.vibrantOrange,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (shouldLeave == true) {
      await _audioService.leaveRoom();
      if (_currentUserId != null) {
        await _groupService.leaveGroup(_currentUserId!, widget.group.id);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  bool get _canCloseRoom {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userType = authService.currentUser?.userType;
    return _currentUserRole == ParticipantRole.facilitator ||
        userType?.toString().split('.').last == 'admin';
  }

  /// Close the room entirely — marks it offline in DB, disconnects, pops.
  Future<void> _closeRoom() async {
    final shouldClose = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Room?'),
        content: const Text(
          'This will end the session for everyone and remove the room from the live list. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Close Room'),
          ),
        ],
      ),
    );

    if (shouldClose == true) {
      await _audioService.leaveRoom();
      await _groupService.closeRoom(widget.group.id);
      if (_currentUserId != null) {
        await _groupService.leaveGroup(_currentUserId!, widget.group.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Room closed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _toggleMute() async {
    await _audioService.toggleMute();
  }

  Future<void> _raiseHand() async {
    setState(() {
      _hasRaisedHand = !_hasRaisedHand;
    });

    if (_hasRaisedHand) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hand raised! The facilitator will invite you to speak.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.info_outline, color: Theme.of(ctx).colorScheme.onSurface),
              title: Text('Room Guidelines', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(ctx);
                _showGuidelines();
              },
            ),
            if (_currentUserRole == ParticipantRole.facilitator ||
                _currentUserRole == ParticipantRole.moderator)
              ListTile(
                leading: Icon(Icons.admin_panel_settings, color: BeaconColors.vibrantOrange),
                title: Text('Moderator Controls', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showModeratorControls();
                },
              ),
            if (_currentUserRole == ParticipantRole.facilitator ||
                _currentUserRole == ParticipantRole.moderator)
              ListTile(
                leading: Icon(
                  Icons.live_tv,
                  color: _isYouTubeStreaming ? Colors.red : Theme.of(ctx).colorScheme.onSurface,
                ),
                title: Text(
                  _isYouTubeStreaming ? '🔴 Stop YouTube Live' : 'Go Live on YouTube',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  if (_isYouTubeStreaming) {
                    _audioService.stopYouTubeStream();
                    setState(() => _isYouTubeStreaming = false);
                  } else {
                    _showYouTubeStreamDialog();
                  }
                },
              ),
            if (_canCloseRoom)
              ListTile(
                leading: const Icon(Icons.stop_circle, color: Colors.red),
                title: const Text('Close Room', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _closeRoom();
                },
              ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.red),
              title: Text('Report Issue', style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(ctx);
                _reportIssue();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showGuidelines() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Room Guidelines'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: widget.group.guidelines.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle,
                      color: BeaconColors.softSageGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${entry.key}: ${entry.value}',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showModeratorControls() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: BeaconColors.vibrantOrange, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Moderator Controls',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Participant list
              Text(
                'Active Participants',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              if (_participants.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No other participants',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                )
              else
                ...List.generate(_participants.length, (index) {
                  final participant = _participants.values.elementAt(index);
                  return _buildModeratorParticipantCard(participant);
                }),

              const SizedBox(height: 20),

              // End session button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    final shouldEnd = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('End Session?'),
                        content: const Text(
                          'Are you sure you want to end this session for everyone?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('End Session'),
                          ),
                        ],
                      ),
                    );

                    if (shouldEnd == true) {
                      await _audioService.leaveRoom();
                      await _groupService.closeRoom(widget.group.id);
                      if (_currentUserId != null) {
                        await _groupService.leaveGroup(_currentUserId!, widget.group.id);
                      }
                      if (mounted) {
                        Navigator.of(context).pop(); // close bottom sheet
                        Navigator.of(context).pop(); // leave screen
                      }
                    }
                  },
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text('End Session for All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeratorParticipantCard(RoomParticipant participant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: BeaconColors.softSageGreen.withValues(alpha: 0.2),
            child: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User ${participant.uid}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  participant.isMuted ? 'Muted' : 'Speaking',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              // Toggle mute state for this participant
              final success = participant.isMuted
                  ? await _audioService.unmuteRemoteParticipant(participant.uid)
                  : await _audioService.muteRemoteParticipant(participant.uid);

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(participant.isMuted
                        ? 'Participant unmuted'
                        : 'Participant muted'),
                    backgroundColor: BeaconColors.softSageGreen,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: Icon(
              participant.isMuted ? Icons.mic_off : Icons.mic,
              color: BeaconColors.vibrantOrange,
            ),
          ),
          IconButton(
            onPressed: () async {
              // Confirm before removing
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Remove Participant'),
                  content: const Text(
                    'Are you sure you want to remove this participant from the room?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                final success =
                    await _audioService.removeParticipant(participant.uid);

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Participant removed from room'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.remove_circle, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleScreenShare() async {
    if (_isScreenSharing) {
      await _audioService.stopScreenShare();
      if (mounted) setState(() => _isScreenSharing = false);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Starting presenter mode — your camera will be visible to the room'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.blue,
          ),
        );
      }
      final success = await _audioService.startScreenShare();
      if (mounted) {
        if (success) {
          setState(() => _isScreenSharing = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Presenter mode on — room can see your camera'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not start presenter mode. Make sure you are connected to the room and camera permission is granted.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  void _showYouTubeStreamDialog() {
    final controller = TextEditingController(text: _youtubeStreamKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Go Live on YouTube'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Get your stream key from:\nYouTube Studio → Go Live → Stream → Stream key',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'YouTube Stream Key',
                hintText: 'xxxx-xxxx-xxxx-xxxx-xxxx',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final key = controller.text.trim();
              if (key.isEmpty) return;
              Navigator.pop(ctx);
              _youtubeStreamKey = key;
              final success = await _audioService.startYouTubeStream(key);
              if (mounted) {
                if (success) {
                  setState(() => _isYouTubeStreaming = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔴 Live on YouTube!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Stream failed — check your key and try again'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Go Live'),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenShareView() {
    final channelId = _audioService.currentChannelName ?? '';
    final engine = _audioService.engine;
    if (engine == null) return const SizedBox.shrink();

    return Container(
      height: 220,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BeaconColors.vibrantOrange, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            if (_isScreenSharing)
              AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: engine,
                  canvas: const VideoCanvas(
                    uid: 0,
                    sourceType: VideoSourceType.videoSourceScreen,
                  ),
                ),
              )
            else if (_remoteScreenSharingUid != null)
              AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: engine,
                  canvas: VideoCanvas(uid: _remoteScreenSharingUid),
                  connection: RtcConnection(channelId: channelId),
                ),
              )
            else
              const Center(
                child: Text(
                  'Screen share starting...',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isYouTubeStreaming ? Colors.red : BeaconColors.vibrantOrange,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _isScreenSharing
                      ? (_isYouTubeStreaming ? '🔴 LIVE · Your Screen' : '📺 Your Screen')
                      : '📺 Screen Share',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reportIssue() {
    if (_currentUserId == null) return;

    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        groupId: widget.group.id,
        sessionId: null, // Can be tracked if we store session IDs
        reporterId: _currentUserId!,
        reportedUserId: null, // Can be specified if reporting specific user
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _participantsSubscription?.cancel();
    _audioStateSubscription?.cancel();
    _speakingUsersSubscription?.cancel();
    _errorSubscription?.cancel();
    _screenShareSubscription?.cancel();
    _audioService.leaveRoom();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: BeaconColors.vibrantOrange),
              const SizedBox(height: 16),
              Text(
                'Joining room...',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final totalParticipants = _participants.length + 1; // +1 for self
    final duration = _audioState?.isInRoom == true
        ? _formatDuration(DateTime.now().difference(DateTime.now()))
        : '0:00';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: BeaconColors.vibrantOrange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _leaveRoom,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.group.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${widget.group.typeDisplayName} • $totalParticipants participant${totalParticipants != 1 ? "s" : ""}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          if (_canCloseRoom)
            IconButton(
              icon: const Icon(Icons.stop_circle, color: Colors.white),
              tooltip: 'Close Room',
              onPressed: _closeRoom,
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                duration,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Audio unavailable banner
            if (_audioUnavailable)
              Container(
                width: double.infinity,
                color: Colors.red[900],
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.mic_off, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Audio unavailable',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _retryAudio,
                          icon: const Icon(Icons.refresh, size: 14),
                          label: const Text('Retry', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => openAppSettings(),
                          icon: const Icon(Icons.settings, size: 14),
                          label: const Text('Open Settings', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Room content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stage section (speakers)
                    _buildSectionHeader('🎙️ STAGE', Colors.orange),
                    const SizedBox(height: 16),
                    _buildSpeakersGrid(),

                    const SizedBox(height: 32),

                    // Audience section (listeners)
                    _buildSectionHeader('👥 AUDIENCE', BeaconColors.softSageGreen),
                    const SizedBox(height: 16),
                    _buildAudienceGrid(),
                  ],
                ),
              ),
            ),

            // Screen share view (shown when local or remote share is active)
            if (_isScreenSharing || (_remoteScreenSharingUid != null && _remoteScreenSharingUid != 0))
              _buildScreenShareView(),

            // Bottom controls
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeakersGrid() {
    // Show host/facilitator card even if they haven't joined audio yet
    final speakers = <Widget>[];

    // Add facilitator card
    if (widget.group.hostName != null && widget.group.hostName!.isNotEmpty) {
      speakers.add(
        _buildParticipantCard(
          name: widget.group.hostName!,
          role: 'Facilitator',
          isSpeaking: false,
          isLarge: true,
        ),
      );
    }

    // Add other participants who are speaking or are moderators/speakers
    // Filter participants who can speak (broadcasters in Agora)
    final speakingParticipants = _participants.values.where((p) {
      // Consider them speakers if they're speaking or have high audio level
      return p.isSpeaking || p.audioLevel > 10;
    }).toList();

    for (final participant in speakingParticipants) {
      speakers.add(
        _buildParticipantCard(
          name: 'User ${participant.uid}',
          role: 'Speaker',
          isSpeaking: _speakingUsers.contains(participant.uid),
          isLarge: true,
        ),
      );
    }

    if (speakers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No speakers yet',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: speakers,
    );
  }

  Widget _buildAudienceGrid() {
    // Filter participants who are listening (not actively speaking)
    final listeners = _participants.values.where((p) {
      // Listeners are those not speaking and with low audio level
      return !p.isSpeaking && p.audioLevel <= 10;
    }).toList();

    if (listeners.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Be the first to join the audience!',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: listeners.map((participant) {
        return _buildParticipantCard(
          name: 'User ${participant.uid}',
          role: 'Listener',
          isSpeaking: false,
          isLarge: false,
        );
      }).toList(),
    );
  }

  Widget _buildParticipantCard({
    required String name,
    required String role,
    required bool isSpeaking,
    required bool isLarge,
  }) {
    final size = isLarge ? 100.0 : 70.0;

    return SizedBox(
      width: isLarge ? 110 : 80,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSpeaking
                        ? BeaconColors.vibrantOrange
                        : BeaconColors.softSageGreen,
                    width: isSpeaking ? 3 * _pulseAnimation.value : 2,
                  ),
                  color: Colors.white,
                  boxShadow: isSpeaking
                      ? [
                          BoxShadow(
                            color: BeaconColors.vibrantOrange.withValues(alpha: 0.4),
                            blurRadius: 12 * _pulseAnimation.value,
                            spreadRadius: 2 * _pulseAnimation.value,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Icon(
                    role == 'Facilitator'
                        ? Icons.star
                        : role == 'Moderator'
                            ? Icons.shield
                            : Icons.person,
                    size: isLarge ? 40 : 28,
                    color: isSpeaking
                        ? BeaconColors.vibrantOrange
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: isLarge ? 14 : 12,
              fontWeight: isLarge ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (isLarge) ...[
            const SizedBox(height: 2),
            Text(
              role,
              style: TextStyle(
                color: BeaconColors.softSageGreen,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool get _canScreenShare =>
      _currentUserRole == ParticipantRole.facilitator ||
      _currentUserRole == ParticipantRole.moderator ||
      _screenShareGranted;

  Widget _buildBottomControls() {
    final isMuted = _audioState?.isMuted ?? true;
    final canSpeak = _audioState?.canSpeak ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Leave button
          _buildControlButton(
            icon: Icons.exit_to_app,
            label: 'Leave',
            color: Colors.red,
            onPressed: _leaveRoom,
          ),

          // Raise hand (only for listeners)
          if (!canSpeak)
            _buildControlButton(
              icon: _hasRaisedHand ? Icons.back_hand : Icons.back_hand_outlined,
              label: 'Raise Hand',
              color: _hasRaisedHand ? BeaconColors.vibrantOrange : Theme.of(context).colorScheme.onSurface,
              onPressed: _raiseHand,
            ),

          // Mute/Unmute (only for speakers)
          if (canSpeak)
            _buildControlButton(
              icon: isMuted ? Icons.mic_off : Icons.mic,
              label: isMuted ? 'Unmute' : 'Mute',
              color: isMuted ? Colors.red : BeaconColors.vibrantOrange,
              onPressed: _toggleMute,
            ),

          // Present (camera video) — facilitators/moderators or granted users only
          if (_canScreenShare)
            _buildControlButton(
              icon: _isScreenSharing ? Icons.videocam_off : Icons.present_to_all,
              label: _isScreenSharing ? 'Stop' : 'Present',
              color: _isScreenSharing ? Colors.red : BeaconColors.softSageGreen,
              onPressed: _audioUnavailable
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fix the audio issue first, then tap Retry in the banner above before presenting.'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  : _toggleScreenShare,
            ),

          // More options
          _buildControlButton(
            icon: Icons.more_horiz,
            label: 'More',
            color: Theme.of(context).colorScheme.onSurface,
            onPressed: _showMoreOptions,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
