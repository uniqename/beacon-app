import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/support_group.dart';
import '../../models/group_participant.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/support_group_service.dart';
import '../../constants/brand_colors.dart';
import 'audio_room_screen.dart';
import 'create_room_dialog.dart';
import 'invitations_screen.dart';

class SupportGroupsTab extends StatefulWidget {
  const SupportGroupsTab({super.key});

  @override
  State<SupportGroupsTab> createState() => _SupportGroupsTabState();
}

class _SupportGroupsTabState extends State<SupportGroupsTab> {
  final SupportGroupService _groupService = SupportGroupService();

  List<SupportGroup> _liveRooms = [];
  List<SupportGroup> _upcomingRooms = [];
  List<SupportGroup> _regularGroups = [];
  bool _isLoading = true;
  bool _canCreateRoom = false;
  int _pendingInvitationsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadGroups();
    _checkCreatePermission();
    _loadInvitationsCount();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load groups from database
      final liveGroups = await _groupService.getLiveGroups();
      final upcomingGroups = await _groupService.getUpcomingGroups();
      final ongoingGroups = await _groupService.getOngoingGroups();

      setState(() {
        _liveRooms = liveGroups;
        _upcomingRooms = upcomingGroups;
        _regularGroups = ongoingGroups;
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error loading groups: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadInvitationsCount() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser != null && !currentUser.isAnonymous) {
      final invitations = await _groupService.getUserInvitations(currentUser.id);
      setState(() {
        _pendingInvitationsCount = invitations.where((inv) => inv.isPending).length;
      });
    }
  }

  Future<void> _checkCreatePermission() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    // Any verified (non-anonymous) user can create a support room.
    if (currentUser != null && !currentUser.isAnonymous) {
      setState(() {
        _canCreateRoom = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    final isLoggedIn = currentUser != null && !currentUser.isAnonymous;

    return Scaffold(
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: BeaconColors.vibrantOrange,
              ),
            )
          : CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Support Groups',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Connect live with others who understand',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isLoggedIn) ...[
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const InvitationsScreen(),
                                  ),
                                );
                                // Refresh count after returning
                                _loadInvitationsCount();
                              },
                              icon: const Icon(Icons.mail_outline),
                              tooltip: 'Invitations',
                            ),
                            if (_pendingInvitationsCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: BeaconColors.vibrantOrange,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$_pendingInvitationsCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      IconButton(
                        onPressed: () => _showCommunityGuidelines(context),
                        icon: const Icon(Icons.info_outline),
                        tooltip: 'Community Guidelines',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Account requirement notice for anonymous users
                  if (!isLoggedIn) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange[400]!, Colors.orange[600]!],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.account_circle,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Account Required',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Create a secure account to join live rooms and connect with others',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.95),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pushNamed(context, '/register'),
                              icon: const Icon(Icons.person_add),
                              label: const Text('Create Free Account'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.orange[700],
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
                    const SizedBox(height: 16),
                  ],

                  // Safety Promise
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.verified_user, color: Colors.green[700], size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Safe & Professional',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[900],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'All rooms moderated by trained professionals',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Live Rooms Section
          if (_liveRooms.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'LIVE NOW',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _LiveRoomCard(
                    group: _liveRooms[index],
                    onTap: () => _joinLiveRoom(_liveRooms[index]),
                  ),
                  childCount: _liveRooms.length,
                ),
              ),
            ),
          ],

          // Upcoming Rooms Section
          if (_upcomingRooms.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.grey[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'UPCOMING SESSIONS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey[700],
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _UpcomingRoomCard(
                    group: _upcomingRooms[index],
                    onTap: () => _viewRoomDetails(_upcomingRooms[index]),
                  ),
                  childCount: _upcomingRooms.length,
                ),
              ),
            ),
          ],

          // Regular Groups Section
          if (_regularGroups.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  children: [
                    Icon(Icons.groups, color: Colors.grey[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'ONGOING GROUPS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey[700],
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _RegularGroupCard(
                    group: _regularGroups[index],
                    onTap: () => _viewRoomDetails(_regularGroups[index]),
                  ),
                  childCount: _regularGroups.length,
                ),
              ),
            ),
          ],

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100), // Extra space for FAB
          ),
        ],
      ),
      floatingActionButton: _canCreateRoom && isLoggedIn
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateRoomDialog(currentUser),
              backgroundColor: BeaconColors.vibrantOrange,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Create Room'),
              elevation: 4,
            )
          : null,
    );
  }

  Future<void> _showCreateRoomDialog(AppUser currentUser) async {
    final createdGroup = await showDialog<SupportGroup>(
      context: context,
      builder: (context) => CreateRoomDialog(currentUser: currentUser),
    );

    if (createdGroup != null) {
      // Refresh groups list
      await _loadGroups();

      // If it's a live room, navigate to it immediately
      if (createdGroup.isLive && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AudioRoomScreen(group: createdGroup),
          ),
        );
      }
    }
  }


  void _showCommunityGuidelines(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Text(
                      'Community Guidelines',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Creating a safe and supportive environment for everyone',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    _buildGuidelineItem(
                      Icons.favorite,
                      'Respect & Kindness',
                      'Treat all members with respect, compassion, and understanding.',
                      Colors.pink,
                    ),
                    _buildGuidelineItem(
                      Icons.lock,
                      'Confidentiality',
                      'What is shared in groups stays in groups. Protect everyone\'s privacy.',
                      Colors.blue,
                    ),
                    _buildGuidelineItem(
                      Icons.block,
                      'No Judgment',
                      'This is a judgment-free space. Everyone\'s journey is unique.',
                      Colors.purple,
                    ),
                    _buildGuidelineItem(
                      Icons.verified_user,
                      'Professional Moderation',
                      'All rooms are facilitated by trained professionals for your safety.',
                      Colors.green,
                    ),
                    _buildGuidelineItem(
                      Icons.visibility_off,
                      'Anonymous Participation',
                      'You can choose to participate anonymously to protect your identity.',
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuidelineItem(IconData icon, String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _joinLiveRoom(SupportGroup group) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    final isLoggedIn = currentUser != null && !currentUser.isAnonymous;

    if (!isLoggedIn) {
      _showAccountRequired(context);
      return;
    }

    // Show Clubhouse-style join dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LiveRoomJoinSheet(group: group),
    );
  }

  void _viewRoomDetails(SupportGroup group) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    final isLoggedIn = currentUser != null && !currentUser.isAnonymous;

    if (!isLoggedIn) {
      _showAccountRequired(context);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RoomDetailsSheet(group: group),
    );
  }

  void _showAccountRequired(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.account_circle, color: Colors.orange[600], size: 28),
            const SizedBox(width: 12),
            const Expanded(child: Text('Account Required')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To join live rooms and connect with others, you need a secure account.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Account Benefits:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildBenefit('Join live support rooms'),
                  _buildBenefit('Connect with trained professionals'),
                  _buildBenefit('Participate anonymously'),
                  _buildBenefit('Access exclusive resources'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/register');
            },
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Create Account'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.check, color: Colors.green[700], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// Live Room Card Widget
class _LiveRoomCard extends StatelessWidget {
  final SupportGroup group;
  final VoidCallback onTap;

  const _LiveRoomCard({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [BeaconColors.vibrantOrange, BeaconColors.vibrantOrange.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: BeaconColors.vibrantOrange.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${group.memberIds.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  group.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  group.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                      child: const Icon(Icons.person, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Hosted by ${group.hostName ?? 'Moderator'}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Upcoming Room Card Widget
class _UpcomingRoomCard extends StatelessWidget {
  final SupportGroup group;
  final VoidCallback onTap;

  const _UpcomingRoomCard({required this.group, required this.onTap});

  String _getTimeUntil() {
    if (group.scheduledTime == null) return '';
    final diff = group.scheduledTime!.difference(DateTime.now());
    if (diff.inMinutes < 60) {
      return 'Starts in ${diff.inMinutes}min';
    } else if (diff.inHours < 24) {
      return 'Starts in ${diff.inHours}h';
    } else {
      return 'Starts in ${diff.inDays}d';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule, size: 14, color: Colors.orange[700]),
                        const SizedBox(width: 4),
                        Text(
                          _getTimeUntil(),
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (group.privacy == GroupPrivacy.private)
                    Icon(Icons.lock, size: 16, color: Colors.grey[600]),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                group.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                group.description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.grey[200],
                    child: Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    group.hostName ?? 'Moderator',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${group.memberIds.length} interested',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Regular Group Card Widget
class _RegularGroupCard extends StatelessWidget {
  final SupportGroup group;
  final VoidCallback onTap;

  const _RegularGroupCard({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      group.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (group.privacy == GroupPrivacy.private)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, size: 12, color: Colors.grey[700]),
                          const SizedBox(width: 4),
                          Text(
                            'Private',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                group.description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (group.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: group.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${group.memberIds.length} members',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Live Room Join Sheet
class _LiveRoomJoinSheet extends StatefulWidget {
  final SupportGroup group;

  const _LiveRoomJoinSheet({required this.group});

  @override
  State<_LiveRoomJoinSheet> createState() => _LiveRoomJoinSheetState();
}

class _LiveRoomJoinSheetState extends State<_LiveRoomJoinSheet> {
  bool _joinAsListener = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [BeaconColors.vibrantOrange, BeaconColors.vibrantOrange.withValues(alpha: 0.85)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.mic, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.group.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.group.memberIds.length} people listening',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: RadioGroup<bool>(
              groupValue: _joinAsListener,
              onChanged: (value) => setState(() => _joinAsListener = value!),
              child: Column(
              children: [
                Row(
                  children: [
                    Radio<bool>(
                      value: true,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Join as Listener',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Listen to the conversation (mic off)',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Radio<bool>(
                      value: false,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Join as Speaker',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Participate in the conversation (mic on)',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to AudioRoomScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AudioRoomScreen(group: widget.group),
                  ),
                );
              },
              icon: Icon(_joinAsListener ? Icons.headset : Icons.mic),
              label: const Text('Join Room'),
              style: ElevatedButton.styleFrom(
                backgroundColor: BeaconColors.vibrantOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }
}

// Room Details Sheet
class _RoomDetailsSheet extends StatefulWidget {
  final SupportGroup group;

  const _RoomDetailsSheet({required this.group});

  @override
  State<_RoomDetailsSheet> createState() => _RoomDetailsSheetState();
}

class _RoomDetailsSheetState extends State<_RoomDetailsSheet> {
  final SupportGroupService _groupService = SupportGroupService();
  bool _isJoining = false;

  Future<void> _joinGroup() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null || currentUser.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to join groups'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      // Check if user can join
      final canJoin = await _groupService.canUserJoinGroup(currentUser.id, widget.group.id);

      if (!canJoin && widget.group.privacy == GroupPrivacy.private) {
        // For private groups, user needs invitation
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('This is a private group. Contact the facilitator for an invitation.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Join the group in database
      final success = await _groupService.joinGroup(
        currentUser.id,
        widget.group.id,
        ParticipantRole.listener,
      );

      if (success && mounted) {
        Navigator.pop(context);

        // If it's a live room, navigate to it
        if (widget.group.isLive) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AudioRoomScreen(group: widget.group),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully joined ${widget.group.name}!'),
              backgroundColor: BeaconColors.softSageGreen,
            ),
          );
        }
      }
    } catch (e) {
      developer.log('Error joining group: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join group: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.group.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (widget.group.privacy == GroupPrivacy.private)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 12, color: Colors.grey[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Private',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${widget.group.memberIds.length} members',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'About',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              widget.group.description,
              style: TextStyle(color: Colors.grey[700], height: 1.5),
            ),
            if (widget.group.guidelines.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Group Guidelines',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),
              ...widget.group.guidelines.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, size: 20, color: Colors.green[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(color: Colors.grey[700], height: 1.4),
                      ),
                    ),
                  ],
                ),
              )),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isJoining ? null : _joinGroup,
                icon: _isJoining
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.group_add),
                label: Text(
                  _isJoining
                      ? 'Joining...'
                      : (widget.group.privacy == GroupPrivacy.private
                          ? 'Request to Join'
                          : 'Join Group'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BeaconColors.vibrantOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
