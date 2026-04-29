import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/local_database_service.dart';
import '../../services/chat_service.dart';

class AdminInquiryManagementScreen extends StatefulWidget {
  const AdminInquiryManagementScreen({super.key});

  @override
  State<AdminInquiryManagementScreen> createState() => _AdminInquiryManagementScreenState();
}

class _AdminInquiryManagementScreenState extends State<AdminInquiryManagementScreen> {
  List<Map<String, dynamic>> _allTickets = [];
  List<Map<String, dynamic>> _filteredTickets = [];
  bool _isLoading = true;
  String _selectedStatus = 'all';
  String _selectedPriority = 'all';

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);

    try {
      final tickets = await LocalDatabaseService.getAllInquiryTickets();

      // Sort by priority (high first) and created_at (newest first)
      tickets.sort((a, b) {
        // First priority by priority level
        final priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
        final priorityCompare = (priorityOrder[a['priority']] ?? 3)
            .compareTo(priorityOrder[b['priority']] ?? 3);

        if (priorityCompare != 0) return priorityCompare;

        // Then by date (newest first)
        final dateA = DateTime.parse(a['created_at'] as String);
        final dateB = DateTime.parse(b['created_at'] as String);
        return dateB.compareTo(dateA);
      });

      setState(() {
        _allTickets = tickets;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tickets: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredTickets = _allTickets.where((ticket) {
        final statusMatch = _selectedStatus == 'all' || ticket['status'] == _selectedStatus;
        final priorityMatch = _selectedPriority == 'all' || ticket['priority'] == _selectedPriority;
        return statusMatch && priorityMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _allTickets.where((t) => t['status'] == 'pending').length;
    final emergencyCount = _allTickets.where((t) => t['priority'] == 'high').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Inquiries'),
        backgroundColor: const Color(0xFFF0562D),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTickets,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: _buildStatChip(
                    'Total',
                    _allTickets.length.toString(),
                    Colors.blue,
                    Icons.inbox,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatChip(
                    'Pending',
                    pendingCount.toString(),
                    Colors.orange,
                    Icons.pending_actions,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatChip(
                    'Emergency',
                    emergencyCount.toString(),
                    Colors.red,
                    Icons.emergency,
                  ),
                ),
              ],
            ),
          ),

          // Filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Status')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                      DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedStatus = value!);
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Priority')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedPriority = value!);
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Tickets List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTickets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No tickets found',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'All inquiries have been handled',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTickets,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredTickets.length,
                          itemBuilder: (context, index) {
                            final ticket = _filteredTickets[index];
                            return _buildTicketCard(ticket);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final createdAt = DateTime.parse(ticket['created_at'] as String);
    final priority = ticket['priority'] as String;
    final status = ticket['status'] as String;
    final isEmergency = priority == 'high';

    Color priorityColor;
    switch (priority) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      default:
        priorityColor = Colors.blue;
    }

    Color statusColor;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        break;
      case 'resolved':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isEmergency ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isEmergency
            ? const BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _viewTicketDetails(ticket),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  if (isEmergency) ...[
                    const Icon(Icons.emergency, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      ticket['subject'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isEmergency ? Colors.red[900] : Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      status.toUpperCase().replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                ticket['description'] as String,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),

              const SizedBox(height: 12),

              // Footer Row
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'User: ${ticket['user_id']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    timeago.format(createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      priority.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: priorityColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _viewTicketDetails(Map<String, dynamic> ticket) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketDetailScreen(ticket: ticket),
      ),
    );

    // Reload tickets after viewing
    _loadTickets();
  }
}

// Ticket Detail Screen
class TicketDetailScreen extends StatefulWidget {
  final Map<String, dynamic> ticket;

  const TicketDetailScreen({super.key, required this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final TextEditingController _responseController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String _currentStatus = '';

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.ticket['status'] as String;
    _loadConversation();
  }

  @override
  void dispose() {
    _responseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversation() async {
    setState(() => _isLoading = true);

    try {
      final conversationId = widget.ticket['conversation_id'] as String;
      final messages = await _chatService.getMessages(conversationId);

      setState(() {
        _messages = messages.reversed.toList();
        _isLoading = false;
      });

      // Auto-scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading conversation: $e')),
        );
      }
    }
  }

  Future<void> _sendResponse() async {
    final response = _responseController.text.trim();
    if (response.isEmpty) return;

    setState(() => _isSending = true);
    _responseController.clear();

    try {
      final conversationId = widget.ticket['conversation_id'] as String;

      // Save admin response as chat message
      await LocalDatabaseService.saveChatMessage(
        conversationId,
        'admin_counselor',
        response,
      );

      // Update ticket status to in_progress if pending
      if (_currentStatus == 'pending') {
        await LocalDatabaseService.updateInquiryTicketStatus(
          widget.ticket['id'] as String,
          'in_progress',
        );
        setState(() => _currentStatus = 'in_progress');
      }

      // Update conversation response time
      await LocalDatabaseService.updateConversationResponseTime(conversationId);

      await _loadConversation();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Response sent to user'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending response: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _updateTicketStatus(String newStatus) async {
    try {
      await LocalDatabaseService.updateInquiryTicketStatus(
        widget.ticket['id'] as String,
        newStatus,
      );

      setState(() => _currentStatus = newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ticket marked as ${newStatus.replaceAll('_', ' ')}'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // If resolved, close conversation
      if (newStatus == 'resolved') {
        final conversationId = widget.ticket['conversation_id'] as String;
        await _chatService.closeConversation(conversationId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final priority = widget.ticket['priority'] as String;
    final isEmergency = priority == 'high';
    final createdAt = DateTime.parse(widget.ticket['created_at'] as String);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Details'),
        backgroundColor: isEmergency ? Colors.red[700] : const Color(0xFFF0562D),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _updateTicketStatus,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pending',
                child: Text('Mark as Pending'),
              ),
              const PopupMenuItem(
                value: 'in_progress',
                child: Text('Mark as In Progress'),
              ),
              const PopupMenuItem(
                value: 'resolved',
                child: Text('Mark as Resolved'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Ticket Info Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: isEmergency ? Colors.red[50] : Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isEmergency)
                      const Icon(Icons.emergency, color: Colors.red, size: 24),
                    if (isEmergency) const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.ticket['subject'] as String,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isEmergency ? Colors.red[900] : Colors.black87,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(
                        _currentStatus.toUpperCase().replaceAll('_', ' '),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: _currentStatus == 'resolved'
                          ? Colors.green[100]
                          : _currentStatus == 'in_progress'
                              ? Colors.blue[100]
                              : Colors.orange[100],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.ticket['description'] as String,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Created ${timeago.format(createdAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: priority == 'high'
                            ? Colors.red[100]
                            : priority == 'medium'
                                ? Colors.orange[100]
                                : Colors.blue[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PRIORITY: ${priority.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: priority == 'high'
                              ? Colors.red
                              : priority == 'medium'
                                  ? Colors.orange
                                  : Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Conversation Messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final senderId = message['sender_id'] as String;
                      final isUser = senderId != 'ai_assistant' && senderId != 'admin_counselor';
                      final isAI = senderId == 'ai_assistant';
                      final timestamp = DateTime.parse(message['timestamp'] as String);

                      return _buildMessageBubble(
                        message: message['message'] as String,
                        isUser: isUser,
                        isAI: isAI,
                        timestamp: timestamp,
                      );
                    },
                  ),
          ),

          // Sending indicator
          if (_isSending)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[100],
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isEmergency ? Colors.red[700] : const Color(0xFFF0562D),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Sending response...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),

          // Response Input (only if not resolved)
          if (_currentStatus != 'resolved')
            Container(
              padding: const EdgeInsets.all(16),
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
                  Expanded(
                    child: TextField(
                      controller: _responseController,
                      decoration: InputDecoration(
                        hintText: 'Type your response as admin counselor...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      enabled: !_isSending,
                      onSubmitted: (_) => _sendResponse(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: isEmergency ? Colors.red[700] : const Color(0xFFF0562D),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _isSending ? null : _sendResponse,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String message,
    required bool isUser,
    required bool isAI,
    required DateTime timestamp,
  }) {
    final isAdmin = !isUser && !isAI;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: isAI ? Colors.purple[100] : Colors.green[100],
              radius: 16,
              child: Icon(
                isAI ? Icons.psychology : Icons.support_agent,
                size: 18,
                color: isAI ? Colors.purple[700] : Colors.green[700],
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isUser)
                  Text(
                    isAI ? 'AI Assistant' : 'Admin Counselor',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isAI ? Colors.purple[700] : Colors.green[700],
                    ),
                  ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser
                        ? Colors.blue[700]
                        : isAI
                            ? Colors.grey[200]
                            : Colors.green[50],
                    border: isAdmin ? Border.all(color: Colors.green) : null,
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
