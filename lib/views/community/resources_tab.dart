import 'package:flutter/material.dart';
import '../../models/support_group.dart';

class ResourcesTab extends StatefulWidget {
  const ResourcesTab({super.key});

  @override
  State<ResourcesTab> createState() => _ResourcesTabState();
}

class _ResourcesTabState extends State<ResourcesTab> {
  final List<SupportResource> _resources = [
    SupportResource(
      id: '1',
      title: 'Creating a Safety Plan',
      content: '''
A safety plan is a personalized plan that helps you stay safe while in an abusive relationship, planning to leave, or after you've left. Here are key elements:

• Identify safe areas in your home where there are no weapons and multiple exits
• Keep important documents in a safe place away from home
• Have an emergency bag ready with essentials
• Identify trusted friends or family who can help
• Know the quickest routes out of your home
• Have a code word to signal for help

Remember: Your safety is the most important thing. Trust your instincts.
      ''',
      authorId: 'counselor1',
      authorName: 'Safety Counselor',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      tags: ['safety', 'planning', 'emergency'],
      isVerified: true,
      helpfulVotes: List.generate(23, (i) => 'user_$i'),
    ),
    SupportResource(
      id: '2',
      title: 'Understanding Trauma Responses',
      content: '''
Trauma affects everyone differently. Common responses include:

Fight: Confronting the threat directly
Flight: Trying to escape or run away
Freeze: Being unable to move or act
Fawn: Trying to please to avoid conflict

All responses are normal and protective. Healing takes time, and it's okay to:
• Feel confused or overwhelmed
• Have good days and bad days
• Need professional help
• Take things one day at a time

You are not broken. You are healing.
      ''',
      authorId: 'therapist1',
      authorName: 'Dr. Ama Osei',
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      tags: ['trauma', 'healing', 'psychology'],
      isVerified: true,
      helpfulVotes: List.generate(31, (i) => 'user_$i'),
    ),
    SupportResource(
      id: '3',
      title: 'Building Financial Independence',
      content: '''
Financial independence is crucial for freedom. Here are practical steps:

1. Open your own bank account if you don't have one
2. Keep important financial documents safe
3. Build credit in your own name
4. Learn about budgeting and saving
5. Explore job training programs
6. Connect with financial counseling services

Remember: Even small steps count. Every cedi saved is progress toward your independence.
      ''',
      authorId: 'advisor1',
      authorName: 'Financial Advisor',
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      tags: ['financial', 'independence', 'skills'],
      isVerified: true,
      helpfulVotes: List.generate(18, (i) => 'user_$i'),
    ),
    SupportResource(
      id: '4',
      title: 'Self-Care During Difficult Times',
      content: '''
Self-care isn't selfish - it's necessary for healing:

Physical Care:
• Get enough sleep when possible
• Eat nutritious meals
• Stay hydrated
• Move your body gently

Emotional Care:
• Practice deep breathing
• Write in a journal
• Listen to calming music
• Connect with supportive people

Remember: Healing isn't linear. Be patient and kind with yourself.
      ''',
      authorId: 'survivor1',
      authorName: 'A Fellow Survivor',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      tags: ['self-care', 'healing', 'wellness'],
      isVerified: false,
      helpfulVotes: List.generate(15, (i) => 'user_$i'),
    ),
  ];

  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final filteredResources = _getFilteredResources();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Educational Resources',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Knowledge and guidance from professionals and survivors',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 24),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: _selectedFilter == 'all',
                    onSelected: () => setState(() => _selectedFilter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Safety',
                    isSelected: _selectedFilter == 'safety',
                    onSelected: () => setState(() => _selectedFilter = 'safety'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Healing',
                    isSelected: _selectedFilter == 'healing',
                    onSelected: () => setState(() => _selectedFilter = 'healing'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Financial',
                    isSelected: _selectedFilter == 'financial',
                    onSelected: () => setState(() => _selectedFilter = 'financial'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Skills',
                    isSelected: _selectedFilter == 'skills',
                    onSelected: () => setState(() => _selectedFilter = 'skills'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Resources list
            Expanded(
              child: ListView.builder(
                itemCount: filteredResources.length,
                itemBuilder: (context, index) {
                  final resource = filteredResources[index];
                  return _ResourceCard(
                    resource: resource,
                    onRead: () => _readResource(resource),
                    onHelpful: () => _markHelpful(resource),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<SupportResource> _getFilteredResources() {
    if (_selectedFilter == 'all') {
      return _resources;
    }
    
    return _resources.where((resource) {
      return resource.tags.contains(_selectedFilter);
    }).toList();
  }

  void _readResource(SupportResource resource) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ResourceDetailSheet(resource: resource),
    );
  }

  void _markHelpful(SupportResource resource) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Marked as helpful'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }
}

class _ResourceCard extends StatelessWidget {
  final SupportResource resource;
  final VoidCallback onRead;
  final VoidCallback onHelpful;

  const _ResourceCard({
    required this.resource,
    required this.onRead,
    required this.onHelpful,
  });

  @override
  Widget build(BuildContext context) {
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
                  child: Text(
                    resource.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (resource.isVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: Colors.green[600], size: 12),
                        const SizedBox(width: 2),
                        Text(
                          'Verified',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Author and date
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  resource.authorName ?? 'Anonymous',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  _getDateText(resource.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Content preview
            Text(
              resource.content.length > 100
                  ? '${resource.content.substring(0, 100)}...'
                  : resource.content,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Tags
            if (resource.tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: resource.tags.map((tag) {
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

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRead,
                    icon: const Icon(Icons.read_more),
                    label: const Text('Read More'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onHelpful,
                  icon: const Icon(Icons.thumb_up_outlined),
                  label: Text('${resource.helpfulCount}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDateText(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _ResourceDetailSheet extends StatelessWidget {
  final SupportResource resource;

  const _ResourceDetailSheet({required this.resource});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
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

              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      resource.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (resource.isVerified)
                    Icon(Icons.verified, color: Colors.green[600]),
                ],
              ),

              const SizedBox(height: 8),

              // Author info
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    resource.authorName ?? 'Anonymous',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _getDateText(resource.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(
                    resource.content,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Marked as helpful'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: const Icon(Icons.thumb_up_outlined),
                      label: Text('Helpful (${resource.helpfulCount})'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Resource saved to your collection'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      },
                      icon: const Icon(Icons.bookmark_add),
                      label: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _getDateText(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}