import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../constants/brand_colors.dart';
import '../../models/group_invitation.dart';
import '../../models/support_group.dart';
import '../../services/support_group_service.dart';
import '../../services/auth_service.dart';

/// Screen for managing support group invitations
///
/// Displays pending, accepted, and rejected invitations.
/// Users can accept or reject pending invitations.
class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> with SingleTickerProviderStateMixin {
  final SupportGroupService _groupService = SupportGroupService();

  late TabController _tabController;
  List<GroupInvitation> _pendingInvitations = [];
  List<GroupInvitation> _respondedInvitations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInvitations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInvitations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;

      if (currentUser != null && !currentUser.isAnonymous) {
        final allInvitations = await _groupService.getUserInvitations(currentUser.id);

        setState(() {
          _pendingInvitations = allInvitations
              .where((inv) => inv.status == InvitationStatus.pending)
              .toList();
          _respondedInvitations = allInvitations
              .where((inv) => inv.status != InvitationStatus.pending)
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error loading invitations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptInvitation(GroupInvitation invitation) async {
    try {
      final success = await _groupService.acceptInvitation(invitation.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitation accepted! You can now join the group.'),
            backgroundColor: BeaconColors.softSageGreen,
          ),
        );

        // Refresh invitations
        await _loadInvitations();
      }
    } catch (e) {
      developer.log('Error accepting invitation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept invitation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectInvitation(GroupInvitation invitation) async {
    try {
      final success = await _groupService.rejectInvitation(invitation.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation declined'),
            backgroundColor: Colors.grey,
          ),
        );

        // Refresh invitations
        await _loadInvitations();
      }
    } catch (e) {
      developer.log('Error rejecting invitation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline invitation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: BeaconColors.vibrantOrange,
        elevation: 0,
        title: const Text(
          'Group Invitations',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pending'),
                  if (_pendingInvitations.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_pendingInvitations.length}',
                        style: TextStyle(
                          color: BeaconColors.vibrantOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'History'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: BeaconColors.vibrantOrange,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPendingTab(),
                _buildHistoryTab(),
              ],
            ),
    );
  }

  Widget _buildPendingTab() {
    if (_pendingInvitations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mail_outline,
              size: 80,
              color: BeaconColors.deepCharcoal.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No pending invitations',
              style: TextStyle(
                color: BeaconColors.deepCharcoal.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ll see invitations to private groups here',
              style: TextStyle(
                color: BeaconColors.deepCharcoal.withValues(alpha: 0.4),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: BeaconColors.vibrantOrange,
      onRefresh: _loadInvitations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingInvitations.length,
        itemBuilder: (context, index) {
          return _buildPendingInvitationCard(_pendingInvitations[index]);
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_respondedInvitations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: BeaconColors.deepCharcoal.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No invitation history',
              style: TextStyle(
                color: BeaconColors.deepCharcoal.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _respondedInvitations.length,
      itemBuilder: (context, index) {
        return _buildHistoryInvitationCard(_respondedInvitations[index]);
      },
    );
  }

  Widget _buildPendingInvitationCard(GroupInvitation invitation) {
    return FutureBuilder<SupportGroup?>(
      future: _groupService.getGroup(invitation.groupId),
      builder: (context, snapshot) {
        final group = snapshot.data;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: BeaconColors.vibrantOrange.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: BeaconColors.vibrantOrange.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: BeaconColors.vibrantOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.mail,
                        color: BeaconColors.vibrantOrange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Group Invitation',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            timeago.format(invitation.invitedAt),
                            style: TextStyle(
                              color: BeaconColors.deepCharcoal.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (invitation.isExpired)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Expiring',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Group info
                if (group != null) ...[
                  Text(
                    group.name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    group.description,
                    style: TextStyle(
                      color: BeaconColors.deepCharcoal.withValues(alpha: 0.7),
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoChip(
                        icon: Icons.category,
                        label: group.typeDisplayName,
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        icon: Icons.people,
                        label: '${group.memberCount} members',
                      ),
                    ],
                  ),
                ] else ...[
                  const CircularProgressIndicator(),
                ],

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _rejectInvitation(invitation),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: BeaconColors.deepCharcoal,
                          side: BorderSide(color: BeaconColors.deepCharcoal.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _acceptInvitation(invitation),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BeaconColors.vibrantOrange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Accept'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryInvitationCard(GroupInvitation invitation) {
    final isAccepted = invitation.status == InvitationStatus.accepted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BeaconColors.deepCharcoal.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isAccepted
                    ? BeaconColors.softSageGreen.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isAccepted ? Icons.check_circle : Icons.cancel,
                color: isAccepted ? BeaconColors.softSageGreen : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<SupportGroup?>(
                    future: _groupService.getGroup(invitation.groupId),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data?.name ?? 'Loading...',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAccepted ? 'Accepted' : 'Declined',
                    style: TextStyle(
                      color: isAccepted
                          ? BeaconColors.softSageGreen
                          : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    timeago.format(invitation.respondedAt ?? invitation.invitedAt),
                    style: TextStyle(
                      color: BeaconColors.deepCharcoal.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: BeaconColors.softSageGreen.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: BeaconColors.softSageGreen,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
