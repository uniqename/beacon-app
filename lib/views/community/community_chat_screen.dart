import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommunityChatScreen extends StatelessWidget {
  const CommunityChatScreen({super.key});

  static const _channels = [
    _Channel('General Support', Icons.forum, Color(0xFF1565C0),
        'A safe space to share, listen, and support one another.'),
    _Channel('Legal Questions', Icons.gavel, Color(0xFF283593),
        'Ask questions about your rights and legal options in Ghana.'),
    _Channel('Housing & Safety', Icons.home, Color(0xFFE65100),
        'Discuss shelter options, safe houses, and home safety strategies.'),
    _Channel('Healing & Recovery', Icons.self_improvement, Color(0xFF7B1FA2),
        'Share your healing journey and encourage others on theirs.'),
    _Channel('Financial Independence', Icons.account_balance_wallet,
        Color(0xFF00838F),
        'Talk about budgeting, savings, job skills, and financial freedom.'),
    _Channel('For Mothers', Icons.child_care, Color(0xFF2E7D32),
        'Support for mothers navigating safety planning with children.'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _channels.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _ChannelCard(channel: _channels[i]),
    );
  }
}

class _Channel {
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  const _Channel(this.name, this.icon, this.color, this.description);
}

class _ChannelCard extends StatelessWidget {
  final _Channel channel;
  const _ChannelCard({required this.channel});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _ChannelChatScreen(channel: channel),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: channel.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(channel.icon, color: channel.color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '# ${channel.name}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      channel.description,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Channel Chat Screen ──────────────────────────────────────────────────────

class _ChannelChatScreen extends StatefulWidget {
  final _Channel channel;
  const _ChannelChatScreen({required this.channel});

  @override
  State<_ChannelChatScreen> createState() => _ChannelChatScreenState();
}

class _ChannelChatScreenState extends State<_ChannelChatScreen> {
  final _compose = TextEditingController();
  final _scrollController = ScrollController();
  List<_ChatMsg> _messages = [];
  bool _isLoading = true;

  String get _storageKey => 'community_chat_${widget.channel.name}';

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _compose.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      setState(() {
        _messages = list
            .map((e) => _ChatMsg.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    }
    setState(() => _isLoading = false);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _send() async {
    final text = _compose.text.trim();
    if (text.isEmpty) return;
    _compose.clear();

    final msg = _ChatMsg(
      text: text,
      senderName: 'You',
      isSelf: true,
      time: DateTime.now(),
    );

    setState(() => _messages.add(msg));
    _scrollToBottom();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _storageKey, jsonEncode(_messages.map((m) => m.toJson()).toList()));
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('# ${widget.channel.name}'),
        backgroundColor: widget.channel.color,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Channel description banner
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: widget.channel.color.withValues(alpha: 0.08),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 14, color: widget.channel.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.channel.description,
                    style: TextStyle(
                        fontSize: 12, color: widget.channel.color),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildWelcome()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) =>
                            _buildBubble(_messages[i]),
                      ),
          ),
          _buildCompose(),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.channel.icon,
                size: 56,
                color: widget.channel.color.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'Welcome to # ${widget.channel.name}',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.channel.description,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Be the first to share something.',
              style: TextStyle(
                  color: widget.channel.color, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(_ChatMsg msg) {
    return Align(
      alignment:
          msg.isSelf ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: msg.isSelf
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!msg.isSelf)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Text(
                  msg.senderName,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: widget.channel.color),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: msg.isSelf
                    ? widget.channel.color
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(msg.isSelf ? 16 : 4),
                  bottomRight: Radius.circular(msg.isSelf ? 4 : 16),
                ),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: msg.isSelf ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
              child: Text(
                _formatTime(msg.time),
                style: const TextStyle(
                    fontSize: 10, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompose() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
              top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _compose,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Share a message...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.channel.color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _ChatMsg {
  final String text;
  final String senderName;
  final bool isSelf;
  final DateTime time;

  const _ChatMsg({
    required this.text,
    required this.senderName,
    required this.isSelf,
    required this.time,
  });

  factory _ChatMsg.fromJson(Map<String, dynamic> j) => _ChatMsg(
        text: j['text'] as String,
        senderName: j['sender_name'] as String? ?? 'Member',
        isSelf: j['is_self'] as bool? ?? false,
        time: DateTime.parse(j['time'] as String),
      );

  Map<String, dynamic> toJson() => {
        'text': text,
        'sender_name': senderName,
        'is_self': isSelf,
        'time': time.toIso8601String(),
      };
}
