import 'dart:async';
import 'dart:developer' as developer;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'local_database_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  GenerativeModel? _model;
  final Map<String, Timer> _escalationTimers = {};
  final Duration _escalationTimeout = const Duration(minutes: 10);

  // Initialize Gemini AI
  void initialize() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      developer.log('Warning: GEMINI_API_KEY not found in .env file');
      return;
    }

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system('''
You are a compassionate AI counselor for "Beacon of New Beginnings",
a domestic violence support organization in Ghana. Your role is to:

1. Provide emotional support and validation to survivors
2. Listen actively and respond with empathy
3. Offer information about available resources and safety planning
4. NEVER minimize their experiences or blame them
5. Encourage professional help when needed
6. Recognize crisis situations and recommend emergency services
7. Be culturally sensitive to Ghanaian context
8. Keep responses concise (2-4 sentences) but warm

Important guidelines:
- If someone is in immediate danger, strongly urge them to call 999 (Ghana Emergency) or go to a safe place
- Never give legal, medical, or therapeutic advice - refer to professionals
- Validate feelings: "It's understandable to feel...", "You're not alone...", "What you experienced is not okay..."
- Empower: "You deserve safety and respect", "You have options", "We're here to support you"
- Be trauma-informed: avoid triggering questions about details unless they volunteer

Available resources you can mention:
- Ghana Emergency Services: 999
- Domestic Violence Hotline: 0800800800 (24/7)
- Beacon of New Beginnings Support Center
- Local shelters and legal aid services

Always maintain confidentiality and remind users that their safety is the priority.
'''),
    );
  }

  // Start a new conversation
  Future<String> startConversation(String userId) async {
    final conversationId = await LocalDatabaseService.createConversation(userId);
    _startEscalationTimer(conversationId);
    return conversationId;
  }

  // Send a message and get AI response
  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String userId,
    required String message,
    bool isEmergency = false,
  }) async {
    // Save user message
    await LocalDatabaseService.saveChatMessage(
      conversationId,
      userId,
      message,
    );

    // Check if conversation is escalated
    final conversation = await LocalDatabaseService.getConversation(conversationId);
    if (conversation != null && conversation['escalated_to_human'] == 1) {
      // Already escalated, save auto-response message
      final autoResponse = 'Your message has been received. A human counselor will respond as soon as possible. You can continue sharing, and a counselor will read everything when they connect.';

      await LocalDatabaseService.saveChatMessage(
        conversationId,
        'ai_assistant',
        autoResponse,
      );

      return {
        'success': true,
        'message': autoResponse,
        'is_ai_response': false,
        'escalated': true,
      };
    }

    // If emergency, escalate immediately
    if (isEmergency) {
      await _escalateToHuman(conversationId, userId, isEmergency: true);

      final emergencyResponse = '🚨 Your emergency has been flagged. A counselor will respond immediately. If you\'re in immediate danger, please call 999 or contact emergency services.';

      await LocalDatabaseService.saveChatMessage(
        conversationId,
        'ai_assistant',
        emergencyResponse,
      );

      return {
        'success': true,
        'message': emergencyResponse,
        'is_ai_response': false,
        'escalated': true,
        'emergency': true,
      };
    }

    // Get AI response
    try {
      if (_model == null) {
        initialize();
      }

      String aiResponse;

      if (_model != null) {
        // Get conversation history for context
        final messages = await LocalDatabaseService.getChatMessages(conversationId);
        final conversationHistory = messages
            .map((msg) => '${msg['sender_id'] == userId ? 'User' : 'Assistant'}: ${msg['message']}')
            .join('\n');

        final prompt = '''
Previous conversation:
$conversationHistory

User's latest message: $message

Respond with empathy and support. Keep it brief (2-4 sentences).
''';

        final content = [Content.text(prompt)];
        final response = await _model!.generateContent(content);
        aiResponse = response.text ?? _offlineResponse(message);
      } else {
        // Offline intelligent fallback — no API key needed
        aiResponse = _offlineResponse(message);
      }

      // Save AI response
      await LocalDatabaseService.saveChatMessage(
        conversationId,
        'ai_assistant',
        aiResponse,
      );

      // Update last response timestamp
      await LocalDatabaseService.updateConversationResponseTime(conversationId);

      // Reset escalation timer
      _resetEscalationTimer(conversationId);

      return {
        'success': true,
        'message': aiResponse,
        'is_ai_response': true,
        'escalated': false,
      };
    } catch (e) {
      developer.log('Error generating AI response: $e');

      // Offline fallback instead of immediate escalation
      final fallbackResponse = _offlineResponse(message);

      await LocalDatabaseService.saveChatMessage(
        conversationId,
        'ai_assistant',
        fallbackResponse,
      );

      await LocalDatabaseService.updateConversationResponseTime(conversationId);
      _resetEscalationTimer(conversationId);

      return {
        'success': true,
        'message': fallbackResponse,
        'is_ai_response': true,
        'escalated': false,
      };
    }
  }

  /// Context-aware offline AI response for when Gemini API key is not configured.
  String _offlineResponse(String message) {
    final lower = message.toLowerCase();

    // Emergency keywords
    if (_containsAny(lower, ['danger', 'kill', 'hurt me', 'hit me', 'emergency', 'help me now', 'dying', 'bleeding', 'weapon', 'gun', 'knife'])) {
      return '🚨 Your safety is the top priority right now. If you are in immediate danger, please call 999 (Ghana Emergency) or go to the nearest safe place immediately. You are not alone — we are here with you. Tap "Emergency" to connect with a counselor right now.';
    }

    // Sadness / crying / depression
    if (_containsAny(lower, ['sad', 'cry', 'crying', 'depressed', 'hopeless', 'worthless', 'can\'t go on', 'give up', 'tired of life'])) {
      return 'I hear you, and I want you to know that what you\'re feeling is valid. Being in a dark place is incredibly hard, but you reached out today — that shows real strength. Can you tell me a little more about what\'s been happening? I\'m here to listen without judgment.';
    }

    // Abuse / violence
    if (_containsAny(lower, ['abuse', 'abused', 'hit', 'beat', 'slap', 'punch', 'violence', 'violent', 'hurt by', 'hurt me', 'forced'])) {
      return 'What you\'re describing is not okay, and it is never your fault. You deserve to be safe and treated with dignity. Beacon of New Beginnings is here to support you — we can help with safety planning, counseling, and connecting you with shelter if needed. Would you like to know more about your options?';
    }

    // Fear / scared / leaving
    if (_containsAny(lower, ['scared', 'afraid', 'fear', 'leave', 'leaving', 'run', 'escape', 'trapped', 'stuck'])) {
      return 'Feeling scared and trapped is one of the most painful experiences. Your feelings are completely understandable. When you\'re ready, we can help you create a safety plan to protect yourself. You don\'t have to make any decisions right now — just know that you have options, and we\'ll support you every step of the way.';
    }

    // Children / kids
    if (_containsAny(lower, ['child', 'children', 'kids', 'baby', 'daughter', 'son', 'custody'])) {
      return 'Your concern for your children shows how much you love them. Keeping children safe during difficult family situations is something we can help with. Beacon has resources including legal guidance on custody, child safety planning, and family counseling. What would be most helpful for you right now?';
    }

    // Shelter / housing
    if (_containsAny(lower, ['shelter', 'house', 'home', 'nowhere to go', 'homeless', 'place to stay'])) {
      return 'Finding a safe place to stay is a priority, and you\'ve come to the right place. Beacon of New Beginnings works with partner shelters across Ghana that provide safe, confidential housing for survivors and their children. Would you like help connecting with one near you?';
    }

    // Legal help
    if (_containsAny(lower, ['legal', 'lawyer', 'court', 'police', 'report', 'arrest', 'restraining', 'divorce'])) {
      return 'You have legal rights and protections available to you. Beacon partners with legal aid organizations that can help you understand your options — including filing reports, restraining orders, and family court proceedings at no cost to you. A support team member can connect you with the right legal resource. Would you like that?';
    }

    // Counseling / mental health
    if (_containsAny(lower, ['counselor', 'therapy', 'mental', 'anxiety', 'trauma', 'ptsd', 'nightmare', 'flashback'])) {
      return 'What you\'ve experienced can have deep emotional effects — trauma responses like anxiety, nightmares, and flashbacks are real and treatable. Beacon offers confidential counseling sessions with trained professionals who specialize in domestic violence recovery. Would you like to be connected with a counselor?';
    }

    // Greeting / starting
    if (_containsAny(lower, ['hello', 'hi', 'hey', 'good morning', 'good evening', 'i need help', 'help', 'please'])) {
      return 'Hello, and welcome to Beacon of New Beginnings. I\'m your confidential AI support guide. I\'m here to listen, provide information, and connect you with the right resources — whether that\'s counseling, legal help, shelter, or just someone to talk to. How are you feeling today, and what brings you here?';
    }

    // Gratitude
    if (_containsAny(lower, ['thank', 'thanks', 'appreciate'])) {
      return 'You\'re very welcome. Reaching out takes courage, and I\'m honoured you trusted Beacon. Please remember: you can talk to us anytime, and if you\'d prefer to speak directly with a human counselor, just tap "Talk to Support Team" below.';
    }

    // Default empathetic response
    final responses = [
      'Thank you for sharing that with me. I\'m here and I\'m listening. Can you tell me more about what you\'re going through? Every detail you feel comfortable sharing helps me understand how to support you best.',
      'I hear you. What you\'re feeling matters, and you deserve support. You\'ve already taken a brave step by reaching out. Would you like to tell me more, or would you prefer to speak with a human counselor from our team?',
      'That sounds really difficult, and I want you to know you don\'t have to face it alone. Beacon is here to help in whatever way you need — information, counseling, shelter, or just someone to listen. What would feel most helpful right now?',
      'I\'m here with you. Please take your time — there\'s no rush. If you\'d like more immediate human support, you can tap "Talk to Support Team" at any point and a volunteer or counselor will respond as soon as possible.',
    ];

    final index = message.length % responses.length;
    return responses[index];
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  // Start escalation timer (10 minutes)
  void _startEscalationTimer(String conversationId) {
    _cancelEscalationTimer(conversationId);

    _escalationTimers[conversationId] = Timer(_escalationTimeout, () async {
      // Check if there's been any human response
      final conversation = await LocalDatabaseService.getConversation(conversationId);
      if (conversation != null && conversation['escalated_to_human'] == 0) {
        // No human response in 10 minutes, escalate
        final userId = conversation['user_id'] as String;
        await _escalateToHuman(conversationId, userId);
      }
    });
  }

  // Reset escalation timer
  void _resetEscalationTimer(String conversationId) {
    _startEscalationTimer(conversationId);
  }

  // Cancel escalation timer
  void _cancelEscalationTimer(String conversationId) {
    _escalationTimers[conversationId]?.cancel();
    _escalationTimers.remove(conversationId);
  }

  // Escalate to human counselor
  Future<void> _escalateToHuman(
    String conversationId,
    String userId, {
    bool isEmergency = false,
  }) async {
    // Mark conversation as escalated
    await LocalDatabaseService.escalateConversation(conversationId);

    // Create inquiry ticket
    final messages = await LocalDatabaseService.getChatMessages(conversationId);
    final lastMessages = messages.take(5).map((m) => m['message']).join('\n');

    final ticketId = await LocalDatabaseService.createInquiryTicket(
      conversationId: conversationId,
      userId: userId,
      subject: isEmergency ? 'EMERGENCY: Immediate Assistance Needed' : 'User Requires Human Support',
      description: '''
User has been waiting for human assistance.

Recent conversation:
$lastMessages

${isEmergency ? 'PRIORITY: EMERGENCY FLAGGED BY USER' : 'Escalated after 10 minutes of AI-only conversation.'}
''',
      priority: isEmergency ? 'high' : 'medium',
    );

    // Create email notification
    final adminEmail = dotenv.env['ADMIN_EMAIL'] ?? 'admin@beaconnewbeginnings.org';
    await LocalDatabaseService.createEmailNotification(
      inquiryId: ticketId,
      recipientEmail: adminEmail,
      subject: isEmergency ? '🚨 EMERGENCY: Chat Support Needed Immediately' : 'New Support Chat Inquiry',
      body: '''
A user requires human assistance in the chat system.

Ticket ID: $ticketId
Priority: ${isEmergency ? 'HIGH - EMERGENCY' : 'Medium'}
Conversation ID: $conversationId
Time: ${DateTime.now()}

${isEmergency ? 'USER HAS FLAGGED THIS AS AN EMERGENCY. Please respond immediately.' : 'User has been waiting for more than 10 minutes. Please log in to the admin dashboard to respond.'}

Recent conversation:
$lastMessages

Log in to the Beacon Admin Dashboard to respond: https://beaconnewbeginnings.org/admin
''',
    );

    // Cancel escalation timer
    _cancelEscalationTimer(conversationId);

    developer.log('Conversation $conversationId escalated to human. Ticket: $ticketId');
  }

  // Get conversation messages
  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    return await LocalDatabaseService.getChatMessages(conversationId);
  }

  // Get all user conversations
  Future<List<Map<String, dynamic>>> getUserConversations(String userId) async {
    return await LocalDatabaseService.getUserConversations(userId);
  }

  // Close conversation
  Future<void> closeConversation(String conversationId) async {
    _cancelEscalationTimer(conversationId);
    await LocalDatabaseService.closeConversation(conversationId);
  }

  // Manual escalation (user requests human)
  Future<void> requestHumanSupport(String conversationId, String userId) async {
    await _escalateToHuman(conversationId, userId);
  }

  // Flag as emergency
  Future<void> flagEmergency(String conversationId, String userId) async {
    await _escalateToHuman(conversationId, userId, isEmergency: true);
  }

  // Dispose
  void dispose() {
    for (var timer in _escalationTimers.values) {
      timer.cancel();
    }
    _escalationTimers.clear();
  }
}
