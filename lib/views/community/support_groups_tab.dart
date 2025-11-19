import 'package:flutter/material.dart';
import '../../models/support_group.dart';

class SupportGroupsTab extends StatefulWidget {
  const SupportGroupsTab({super.key});

  @override
  State<SupportGroupsTab> createState() => _SupportGroupsTabState();
}

class _SupportGroupsTabState extends State<SupportGroupsTab> {
  final List<SupportGroup> _groups = [
    SupportGroup(
      id: '1',
      name: 'Survivors Circle',
      description: 'A safe space for survivors to share experiences and support each other on their healing journey.',
      type: GroupType.survivors,
      privacy: GroupPrivacy.private,
      memberIds: List.generate(12, (i) => 'member_$i'),
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastActivityAt: DateTime.now().subtract(const Duration(hours: 2)),
      tags: ['healing', 'support', 'survivors'],
      guidelines: {
        'respect': 'Treat all members with respect and kindness',
        'confidentiality': 'What is shared here, stays here',
        'no_judgment': 'This is a judgment-free zone',
      },
    ),
    SupportGroup(
      id: '2',
      name: 'Mothers Supporting Mothers',
      description: 'Support group for mothers who have experienced domestic violence, focusing on child safety and healing.',
      type: GroupType.mothers,
      privacy: GroupPrivacy.private,
      memberIds: List.generate(8, (i) => 'mom_$i'),
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      lastActivityAt: DateTime.now().subtract(const Duration(hours: 5)),
      tags: ['mothers', 'children', 'safety'],
    ),
    SupportGroup(
      id: '3',
      name: 'Healing Through Art',
      description: 'Express yourself through creative activities and find healing through artistic expression.',
      type: GroupType.healing,
      privacy: GroupPrivacy.public,
      memberIds: List.generate(15, (i) => 'artist_$i'),
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      lastActivityAt: DateTime.now().subtract(const Duration(hours: 1)),
      tags: ['healing', 'art', 'creativity', 'therapy'],
    ),
    SupportGroup(
      id: '4',
      name: 'Skills & Independence',
      description: 'Learn new skills, discuss job opportunities, and build financial independence together.',
      type: GroupType.skills,
      privacy: GroupPrivacy.public,
      memberIds: List.generate(20, (i) => 'learner_$i'),
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      lastActivityAt: DateTime.now().subtract(const Duration(minutes: 30)),
      tags: ['skills', 'employment', 'independence', 'financial'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                        'Connect with others who understand your journey',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showGroupGuidelines(context),
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'Community Guidelines',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Account requirement notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_circle, color: Colors.orange[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Required',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[800],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'You MUST create a secure account to view and join support groups. This protects your privacy and ensures a safe environment for all members.',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      icon: Icon(Icons.person_add),
                      label: Text('Create Account Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Safety notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.blue[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Safe Space Promise',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All groups are moderated by trained professionals. You can participate anonymously.',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Groups list
            Expanded(
              child: ListView.builder(
                itemCount: _groups.length,
                itemBuilder: (context, index) {
                  final group = _groups[index];
                  return _GroupCard(
                    group: group,
                    onJoin: () => _joinGroup(group),
                    onView: () => _viewGroup(group),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupGuidelines(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Community Guidelines'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('1. Respect & Kindness',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Treat all members with respect and compassion.'),
              SizedBox(height: 12),
              Text('2. Confidentiality',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('What is shared in groups stays in groups.'),
              SizedBox(height: 12),
              Text('3. No Judgment',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('This is a safe, judgment-free space for healing.'),
              SizedBox(height: 12),
              Text('4. Professional Support',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('All groups are facilitated by trained professionals.'),
              SizedBox(height: 12),
              Text('5. Anonymous Participation',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('You can choose to participate anonymously.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _joinGroup(SupportGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Join ${group.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Would you like to join this support group?'),
            const SizedBox(height: 16),
            if (group.privacy == GroupPrivacy.private) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.orange[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This is a private group. Your request will be reviewed.',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Checkbox(
                  value: false,
                  onChanged: (value) {},
                ),
                const Expanded(
                  child: Text(
                    'I want to participate anonymously',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    group.privacy == GroupPrivacy.private
                        ? 'Join request sent. You\'ll be notified when approved.'
                        : 'Successfully joined ${group.name}!',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  void _viewGroup(SupportGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.account_circle, color: Colors.orange[600]),
            SizedBox(width: 12),
            Expanded(child: Text('Account Required')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To view and participate in "${group.name}", you need to create a secure account.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, size: 16, color: Colors.orange[600]),
                      SizedBox(width: 8),
                      Text(
                        'Why accounts are required:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Protects member privacy and safety\n'
                    '• Enables secure communication\n'
                    '• Allows anonymous participation\n'
                    '• Ensures professional moderation',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Maybe Later'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/register');
            },
            icon: Icon(Icons.person_add, size: 16),
            label: Text('Create Account'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final SupportGroup group;
  final VoidCallback onJoin;
  final VoidCallback onView;

  const _GroupCard({
    required this.group,
    required this.onJoin,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = group.lastActivityAt != null &&
        DateTime.now().difference(group.lastActivityAt!).inHours < 24;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              group.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isActive) ...[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Active',
                              style: TextStyle(
                                color: Colors.green[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        group.typeDisplayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (group.privacy == GroupPrivacy.private)
                      Icon(Icons.lock, color: Colors.grey[500], size: 16),
                    if (group.privacy == GroupPrivacy.anonymous)
                      Icon(Icons.visibility_off, color: Colors.grey[500], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${group.memberCount}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.people, color: Colors.grey[500], size: 16),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              group.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 12),

            // Tags
            if (group.tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: group.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Activity info
            if (group.lastActivityAt != null) ...[
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    _getLastActivityText(group.lastActivityAt!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Action buttons
            Row(
              children: [
                if (group.memberCount < group.maxMembers)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onJoin,
                      icon: const Icon(Icons.add),
                      label: const Text('Join'),
                    ),
                  )
                else
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.people),
                      label: const Text('Full'),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.visibility),
                    label: const Text('View'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getLastActivityText(DateTime lastActivity) {
    final diff = DateTime.now().difference(lastActivity);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}