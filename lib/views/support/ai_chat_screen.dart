import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/chat_service.dart';
import 'dart:async';

class AiChatScreen extends StatefulWidget {
  final String userId;

  const AiChatScreen({super.key, required this.userId});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _conversationId;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSendingMessage = false;
  bool _isTyping = false; // AI typing indicator
  bool _isEscalated = false;
  bool _isEmergency = false;
  Timer? _refreshTimer;
  int _aiMessageCount = 0; // track how many AI messages shown

  @override
  void initState() {
    super.initState();
    _initializeChat();
    // Auto-refresh messages every 5 seconds to catch human responses
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_conversationId != null && mounted) {
        _loadMessages(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);

    try {
      developer.log('🔍 [AIChat] Initializing chat for user: ${widget.userId}');
      // Check if user has existing active conversation
      final conversations = await _chatService.getUserConversations(widget.userId);
      developer.log('🔍 [AIChat] Found ${conversations.length} conversations');
      final activeConversations = conversations.where((c) => c['status'] == 'active').toList();

      if (activeConversations.isNotEmpty) {
        // Use existing conversation
        _conversationId = activeConversations.first['id'] as String;
        _isEscalated = (activeConversations.first['escalated_to_human'] as int) == 1;
        developer.log('✅ [AIChat] Using existing conversation: $_conversationId');
      } else {
        // Start new conversation
        developer.log('🔍 [AIChat] Starting new conversation...');
        _conversationId = await _chatService.startConversation(widget.userId);
        developer.log('✅ [AIChat] New conversation created: $_conversationId');
      }

      await _loadMessages();
    } catch (e, stack) {
      developer.log('❌ [AIChat] ERROR initializing chat: $e');
      developer.log('   Stack: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing chat: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      if (_conversationId != null) {
        final messages = await _chatService.getMessages(_conversationId!);
        // Check escalation status
        final conversations = await _chatService.getUserConversations(widget.userId);
        final currentConv = conversations.firstWhere(
          (c) => c['id'] == _conversationId,
          orElse: () => {'escalated_to_human': 0},
        );

        if (mounted) {
          setState(() {
            _messages = messages.reversed.toList(); // Reverse to show latest at bottom
            _isEscalated = (currentConv['escalated_to_human'] as int) == 1;
            _isLoading = false;
          });

          // Auto-scroll to bottom
          if (_scrollController.hasClients) {
            Future.delayed(const Duration(milliseconds: 100), () {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        }
      }
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendMessage({bool isEmergency = false}) async {
    final message = _messageController.text.trim();
    if (message.isEmpty && !isEmergency) return;

    if (_conversationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat not initialized. Please restart.')),
      );
      return;
    }

    setState(() {
      _isSendingMessage = true;
      _isTyping = true;
    });
    _messageController.clear();

    try {
      final response = await _chatService.sendMessage(
        conversationId: _conversationId!,
        userId: widget.userId,
        message: isEmergency ? 'EMERGENCY: I need immediate help' : message,
        isEmergency: isEmergency,
      );

      if (response['escalated'] == true) {
        setState(() {
          _isEscalated = true;
          _isEmergency = response['emergency'] == true;
        });
      }

      if (response['is_ai_response'] == true) {
        setState(() => _aiMessageCount++);
      }

      await _loadMessages();

      if (mounted && response['escalated'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEmergency
                  ? 'Emergency flagged! A counselor will respond immediately.'
                  : 'Connected to human support. A counselor will respond soon.',
            ),
            backgroundColor: _isEmergency ? Colors.red : Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
          _isTyping = false;
        });
      }
    }
  }

  Future<void> _requestHumanSupport() async {
    if (_conversationId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person, color: Colors.blue),
            SizedBox(width: 8),
            Text('Request Human Support'),
          ],
        ),
        content: const Text(
          'Would you like to speak with a human counselor? This will prioritize your conversation for immediate human response.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Yes, Connect Me'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _chatService.requestHumanSupport(_conversationId!, widget.userId);
        setState(() => _isEscalated = true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connected to human support. A counselor will respond shortly.'),
              backgroundColor: Colors.green,
            ),
          );
        }

        await _loadMessages();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _flagEmergency() async {
    if (_conversationId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.emergency, color: Colors.red),
            SizedBox(width: 8),
            Text('Flag Emergency'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you in immediate danger?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'If you are in immediate danger:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Call 999 (Ghana Emergency Services)'),
                  Text('• Call 0800800800 (DV Hotline 24/7)'),
                  Text('• Go to a safe location'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Flagging as emergency will alert our team immediately.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Flag as Emergency'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _sendMessage(isEmergency: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Support Chat'),
        backgroundColor: Colors.purple[700],
        actions: [
          if (!_isEscalated)
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'Request Human Support',
              onPressed: _requestHumanSupport,
            ),
        ],
      ),
      body: Column(
        children: [
          // Escalation Status Banner
          if (_isEscalated)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isEmergency ? Colors.red[100] : Colors.orange[100],
                border: Border(
                  bottom: BorderSide(
                    color: _isEmergency ? Colors.red : Colors.orange,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEmergency ? Icons.emergency : Icons.person,
                    color: _isEmergency ? Colors.red[700] : Colors.orange[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isEmergency
                          ? '🚨 EMERGENCY - Human counselor alerted'
                          : '👤 Connected to human support',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isEmergency ? Colors.red[900] : Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Safety Resources Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.purple[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🆘 Emergency Resources',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildQuickResourceChip('Emergency: 999', Icons.phone, Colors.red),
                    _buildQuickResourceChip('DV Hotline: 0800800800', Icons.support_agent, Colors.orange),
                  ],
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Start a conversation',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'You\'re speaking with our AI counselor. A human counselor is available 24/7 if needed.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isUser = message['sender_id'] != 'ai_assistant';
                          final timestamp = DateTime.parse(message['timestamp'] as String);

                          return _buildMessageBubble(
                            message: message['message'] as String,
                            isUser: isUser,
                            timestamp: timestamp,
                          );
                        },
                      ),
          ),

          // AI typing indicator
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.purple[100],
                    radius: 14,
                    child: Icon(Icons.psychology, size: 16, color: Colors.purple[700]),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _dot(0),
                        const SizedBox(width: 3),
                        _dot(150),
                        const SizedBox(width: 3),
                        _dot(300),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // "Talk to a person" nudge after 2+ AI exchanges
          if (!_isEscalated && !_isTyping && _aiMessageCount >= 2)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: Colors.orange[700], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Not getting the help you need? A human counselor is available.',
                      style: TextStyle(fontSize: 12, color: Colors.orange[900]),
                    ),
                  ),
                  TextButton(
                    onPressed: _requestHumanSupport,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text('Talk to Person',
                        style: TextStyle(
                            color: Colors.orange[800],
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Emergency Button
                IconButton(
                  icon: const Icon(Icons.emergency, color: Colors.red),
                  tooltip: 'Flag Emergency',
                  onPressed: _isSendingMessage ? null : _flagEmergency,
                ),

                // Text Input
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: _isEscalated
                          ? 'Counselor will respond soon...'
                          : 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    enabled: !_isSendingMessage,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),

                const SizedBox(width: 8),

                // Send Button
                CircleAvatar(
                  backgroundColor: Colors.purple[700],
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _isSendingMessage ? null : () => _sendMessage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: Duration(milliseconds: 500 + delayMs),
      curve: Curves.easeInOut,
      builder: (_, v, __) => Opacity(
        opacity: v,
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: Colors.grey[500],
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickResourceChip(String label, IconData icon, Color color) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: const TextStyle(fontSize: 10),
      ),
      padding: const EdgeInsets.all(4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildMessageBubble({
    required String message,
    required bool isUser,
    required DateTime timestamp,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: Colors.purple[100],
              radius: 16,
              child: Icon(Icons.psychology, size: 18, color: Colors.purple[700]),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.purple[700] : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeago.format(timestamp),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.blue[100],
              radius: 16,
              child: Icon(Icons.person, size: 18, color: Colors.blue[700]),
            ),
          ],
        ],
      ),
    );
  }
}
