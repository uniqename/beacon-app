import 'package:flutter/material.dart';

class ChatListScreen extends StatefulWidget {
  final String userId;

  const ChatListScreen({super.key, required this.userId});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final List<ChatConversation> _conversations = [
    ChatConversation(
      id: '1',
      counselorName: 'Dr. Ama Mensah',
      counselorRole: 'Trauma Counselor',
      lastMessage: 'How have you been feeling since our last session?',
      timestamp: DateTime.now().subtract(Duration(hours: 2)),
      unreadCount: 2,
      isOnline: true,
    ),
    ChatConversation(
      id: '2',
      counselorName: 'Legal Aid Ghana',
      counselorRole: 'Legal Support',
      lastMessage: 'I can help you understand your legal rights under the DV Act.',
      timestamp: DateTime.now().subtract(Duration(days: 1)),
      unreadCount: 0,
      isOnline: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Support Chat'),
        backgroundColor: Colors.teal[600],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.teal[50],
            child: Row(
              children: [
                Icon(Icons.lock, color: Colors.teal[700], size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'All conversations are encrypted and confidential',
                    style: TextStyle(color: Colors.teal[900], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _conversations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No conversations yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                        SizedBox(height: 8),
                        Text('Start a chat with a counselor or support service', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      return ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.teal[100],
                              child: Text(
                                conversation.counselorName[0],
                                style: TextStyle(color: Colors.teal[700], fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (conversation.isOnline)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                conversation.counselorName,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              _formatTimestamp(conversation.timestamp),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              conversation.counselorRole,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            SizedBox(height: 4),
                            Text(
                              conversation.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: conversation.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        trailing: conversation.unreadCount > 0
                            ? Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.teal[600],
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  conversation.unreadCount.toString(),
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              )
                            : null,
                        isThreeLine: true,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/chat',
                          arguments: conversation,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewChatDialog,
        icon: Icon(Icons.add),
        label: Text('New Chat'),
        backgroundColor: Colors.teal[600],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m';
      }
      return '${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  void _showNewChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start New Conversation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.psychology, color: Colors.purple),
              title: Text('Trauma Counselor'),
              subtitle: Text('Professional counseling support'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Starting chat with counselor...')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.gavel, color: Colors.blue),
              title: Text('Legal Support'),
              subtitle: Text('Legal advice and guidance'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Starting chat with legal support...')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.phone, color: Colors.red),
              title: Text('Crisis Hotline'),
              subtitle: Text('24/7 emergency support'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Connecting to hotline...')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class ChatConversation {
  final String id;
  final String counselorName;
  final String counselorRole;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;
  final bool isOnline;

  ChatConversation({
    required this.id,
    required this.counselorName,
    required this.counselorRole,
    required this.lastMessage,
    required this.timestamp,
    this.unreadCount = 0,
    this.isOnline = false,
  });
}
