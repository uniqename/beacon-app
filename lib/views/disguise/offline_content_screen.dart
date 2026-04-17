import 'package:flutter/material.dart';

class OfflineContentScreen extends StatefulWidget {
  const OfflineContentScreen({super.key});

  @override
  State<OfflineContentScreen> createState() => _OfflineContentScreenState();
}

class _OfflineContentScreenState extends State<OfflineContentScreen> {
  final List<OfflineContent> _downloadedContent = [];
  final List<OfflineContent> _availableContent = [
    OfflineContent(
      id: '1',
      title: 'Creating a Safety Plan',
      type: 'Article',
      category: 'Safety',
      size: '2.5 MB',
      description: 'Step-by-step guide to creating a comprehensive safety plan',
      isDownloaded: false,
    ),
    OfflineContent(
      id: '2',
      title: 'Recognizing Abuse Patterns',
      type: 'Article',
      category: 'Education',
      size: '1.8 MB',
      description: 'Understanding different types of domestic violence',
      isDownloaded: false,
    ),
    OfflineContent(
      id: '3',
      title: 'Legal Rights in Ghana',
      type: 'Guide',
      category: 'Legal',
      size: '3.2 MB',
      description: 'Your rights under the Domestic Violence Act 732',
      isDownloaded: false,
    ),
    OfflineContent(
      id: '4',
      title: 'Self-Care During Crisis',
      type: 'Article',
      category: 'Wellness',
      size: '1.5 MB',
      description: 'Managing stress and maintaining mental health',
      isDownloaded: false,
    ),
    OfflineContent(
      id: '5',
      title: 'Emergency Resource Contacts',
      type: 'Directory',
      category: 'Resources',
      size: '0.8 MB',
      description: 'Shelters, hotlines, and support services in Ghana',
      isDownloaded: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Offline Content'),
          backgroundColor: Colors.indigo[700],
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.cloud_download), text: 'Available'),
              Tab(icon: Icon(Icons.offline_pin), text: 'Downloaded'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAvailableTab(),
            _buildDownloadedTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableTab() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.indigo[50],
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.indigo[700]),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Download content to access when you\'re offline. All content is encrypted.',
                  style: TextStyle(color: Colors.indigo[900], fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _availableContent.length,
            itemBuilder: (context, index) {
              final content = _availableContent[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getCategoryColor(content.category),
                    child: Icon(_getCategoryIcon(content.category), color: Colors.white, size: 20),
                  ),
                  title: Text(content.title, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text(content.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(content.type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(width: 8),
                          Text(content.size, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.download, color: Colors.indigo[700]),
                    onPressed: () => _downloadContent(content),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadedTab() {
    return _downloadedContent.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No offline content', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                SizedBox(height: 8),
                Text('Download content from the Available tab', style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _downloadedContent.length,
            itemBuilder: (context, index) {
              final content = _downloadedContent[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: Icon(Icons.offline_pin, color: Colors.green[700]),
                  ),
                  title: Text(content.title, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${content.type} • ${content.size}'),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'open', child: Text('Open')),
                      PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') _deleteContent(content);
                    },
                  ),
                  onTap: () => _openContent(content),
                ),
              );
            },
          );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'safety':
        return Colors.red;
      case 'education':
        return Colors.blue;
      case 'legal':
        return Colors.purple;
      case 'wellness':
        return Colors.green;
      case 'resources':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'safety':
        return Icons.security;
      case 'education':
        return Icons.school;
      case 'legal':
        return Icons.gavel;
      case 'wellness':
        return Icons.favorite;
      case 'resources':
        return Icons.contact_phone;
      default:
        return Icons.article;
    }
  }

  void _downloadContent(OfflineContent content) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Downloading...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Downloading ${content.title}'),
          ],
        ),
      ),
    );

    // Simulate download
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pop(context);
      setState(() {
        content.isDownloaded = true;
        _downloadedContent.add(content);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${content.title} downloaded'),
          action: SnackBarAction(label: 'View', onPressed: () => _openContent(content)),
        ),
      );
    });
  }

  void _openContent(OfflineContent content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(content.title),
            backgroundColor: Colors.indigo[700],
          ),
          body: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(content.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(content.type, style: TextStyle(color: Colors.grey[600])),
                SizedBox(height: 24),
                Text(content.description),
                SizedBox(height: 16),
                Text('[Content would be displayed here]', style: TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteContent(OfflineContent content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Content'),
        content: Text('Remove ${content.title} from offline storage?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                content.isDownloaded = false;
                _downloadedContent.remove(content);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Content deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class OfflineContent {
  final String id;
  final String title;
  final String type;
  final String category;
  final String size;
  final String description;
  bool isDownloaded;

  OfflineContent({
    required this.id,
    required this.title,
    required this.type,
    required this.category,
    required this.size,
    required this.description,
    this.isDownloaded = false,
  });
}
