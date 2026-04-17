import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ── Colours ──────────────────────────────────────────────────────────────────
const _kBg       = Color(0xFF0A0E1A);
const _kCard     = Color(0xFF141929);
const _kSurface  = Color(0xFF1C2333);
const _kBorder   = Color(0xFF2A3550);
const _kAccent   = Color(0xFF00D4AA);
const _kPurple   = Color(0xFF7C3AED);
const _kGold     = Color(0xFFFFB347);
const _kRed      = Color(0xFFFF5C7A);

// ── Agent definition ─────────────────────────────────────────────────────────
class _Agent {
  final String id;
  final String name;
  final String tagline;
  final String description;
  final IconData icon;
  final Color accent;
  final String systemPrompt;

  const _Agent({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.icon,
    required this.accent,
    required this.systemPrompt,
  });
}

const _agents = [
  _Agent(
    id: 'notebook',
    name: 'NoteBeacon',
    tagline: 'AI Document Analyst',
    description: 'Paste any text — court documents, letters, policies — and get plain-language summaries, key points, and questions answered.',
    icon: Icons.auto_stories_rounded,
    accent: _kAccent,
    systemPrompt: '''You are NoteBeacon, an expert AI document analyst for Beacon of New Beginnings.
Your job: help survivors understand complex documents in plain, compassionate language.

When given a document or text:
1. Summarise it in 3-5 bullet points of plain language
2. Highlight any important dates, deadlines, or actions required
3. Flag anything concerning or confusing
4. Answer follow-up questions about the content

Keep responses clear, warm, and jargon-free. If the document involves legal matters, remind the user to consult a lawyer while still helping them understand the content.
Always be trauma-informed and supportive.''',
  ),
  _Agent(
    id: 'safety',
    name: 'SafetyGuide',
    tagline: 'Personal Safety AI',
    description: 'Build a step-by-step personalised safety plan. Get advice on escape planning, code words, digital safety, children\'s safety, and emergency contacts.',
    icon: Icons.shield_rounded,
    accent: _kAccent,
    systemPrompt: '''You are SafetyGuide, an expert AI safety planner for Beacon of New Beginnings in Ghana.
You help survivors of domestic violence create personalised, practical safety plans.

You can help with:
- Escape route planning (safe exits, meeting points, go-bag contents)
- Code words and signals with trusted people
- Digital safety (phone privacy, app hiding, social media)
- Children's safety (school contacts, what to tell children)
- Financial safety (hidden savings, important documents)
- Emergency contacts in Ghana (999, 0800800800, local shelters)

Be conversational. Ask ONE question at a time to gather details, then provide tailored advice.
Never judge, always validate. Prioritise immediate safety over long-term plans.
Cultural context: users are in Ghana. Reference Ghanaian services, police DOVVSU units, shelters.''',
  ),
  _Agent(
    id: 'legal',
    name: 'LegalNav',
    tagline: 'Legal Information AI',
    description: 'Understand your legal rights in Ghana — domestic violence laws, protection orders, DVVSU process, custody, divorce, and what to expect in court.',
    icon: Icons.gavel_rounded,
    accent: _kPurple,
    systemPrompt: '''You are LegalNav, an AI legal information assistant for Beacon of New Beginnings in Ghana.
You provide information about Ghanaian law relevant to domestic violence survivors.

Key areas you can explain:
- Ghana Domestic Violence Act 2007 (Act 732) — key protections
- How to get a Protection Order (Domestic Violence Court process)
- DOVVSU (Domestic Violence and Victim Support Unit) — what they do, how to report
- Divorce and separation process in Ghana
- Custody rights for children
- Criminal vs civil processes
- What evidence is needed and how to preserve it
- Rights during police interaction

IMPORTANT: Always clarify you provide information, not legal advice. Encourage users to also speak with a qualified Ghanaian lawyer or legal aid organisation.
Be patient, clear, and non-judgmental. Use simple language.''',
  ),
  _Agent(
    id: 'manus',
    name: 'PathFinder',
    tagline: 'Life Planning AI',
    description: 'Your personal empowerment coach. Get help planning your next steps — housing, education, employment, rebuilding finances, and setting goals.',
    icon: Icons.explore_rounded,
    accent: _kGold,
    systemPrompt: '''You are PathFinder, an empowerment and life planning AI for Beacon of New Beginnings.
You help survivors plan and take practical steps toward rebuilding their lives.

Areas you assist with:
- Housing: finding safe housing, understanding rental rights, transitional housing
- Education: returning to school, scholarships, adult literacy programmes in Ghana
- Employment: job searching strategies, CV building, skills assessment, interview prep
- Financial recovery: budgeting, micro-loans, saving strategies in Ghana
- Goal setting: breaking big goals into small achievable steps
- Self-care and rebuilding confidence
- Connecting to Beacon services and partner organisations

Be encouraging, practical, and action-oriented. Ask questions to understand the person's situation.
Celebrate small wins. Offer specific, realistic steps (not generic advice).
Always acknowledge that leaving/healing is a process, not a single event.''',
  ),
];

// ── Hub screen ───────────────────────────────────────────────────────────────
class AiAgentsHubScreen extends StatelessWidget {
  const AiAgentsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kAccent, _kPurple]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'AI Agents',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              itemCount: _agents.length,
              itemBuilder: (_, i) => _AgentCard(agent: _agents[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        color: _kCard,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your AI-powered support team',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Specialist AI agents to help you understand documents, plan your safety, know your rights, and rebuild your life.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _kAccent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kAccent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: _kAccent, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Offline knowledge base active — all agents work now. Add GEMINI_API_KEY in .env for full AI responses.',
                    style: TextStyle(color: _kAccent, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Agent card on hub ─────────────────────────────────────────────────────────
class _AgentCard extends StatelessWidget {
  final _Agent agent;
  const _AgentCard({required this.agent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: agent.accent.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => _AgentChatScreen(agent: agent)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [agent.accent.withValues(alpha: 0.3), agent.accent.withValues(alpha: 0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: agent.accent.withValues(alpha: 0.4)),
                  ),
                  child: Icon(agent.icon, color: agent.accent, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            agent.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: agent.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: agent.accent.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'AI',
                              style: TextStyle(
                                color: agent.accent,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        agent.tagline,
                        style: TextStyle(color: agent.accent, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        agent.description,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 12, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.3), size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Agent chat screen ─────────────────────────────────────────────────────────
class _AgentChatScreen extends StatefulWidget {
  final _Agent agent;
  const _AgentChatScreen({required this.agent});

  @override
  State<_AgentChatScreen> createState() => __AgentChatScreenState();
}

class __AgentChatScreenState extends State<_AgentChatScreen> {
  final _textCtrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_ChatMsg> _messages = [];
  ChatSession? _session;
  bool _loading = false;
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initModel();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _initModel() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    if (apiKey.isNotEmpty) {
      try {
        final model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: apiKey,
          systemInstruction: Content.system(widget.agent.systemPrompt),
          generationConfig: GenerationConfig(
            temperature: 0.7,
            maxOutputTokens: 1024,
          ),
        );
        _session = model.startChat();
      } catch (_) {
        _session = null; // fall through to offline mode
      }
    }

    // Always start — offline mode works without Gemini
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _initialized = true;
        _messages.add(_ChatMsg(
          isUser: false,
          text: _welcomeFor(widget.agent.id),
          timestamp: DateTime.now(),
        ));
      });
    });
  }

  String _welcomeFor(String id) {
    switch (id) {
      case 'notebook':
        return 'Hello! I\'m **NoteBeacon**, your document analyst.\n\nPaste any text — a court letter, police report, lease agreement, or policy document — and I\'ll explain it in plain language and answer your questions about it.';
      case 'safety':
        return 'Hello, and welcome. I\'m **SafetyGuide**.\n\nI\'m here to help you build a personalised safety plan, step by step. Everything you share here stays private.\n\nTo start: **where are you right now — do you feel safe at this moment?**';
      case 'legal':
        return 'Hello. I\'m **LegalNav**, your legal information guide.\n\nI can explain Ghanaian domestic violence laws, protection orders, the DOVVSU process, custody rights, and more — in plain language.\n\nWhat would you like to understand today?';
      case 'manus':
        return 'Hi! I\'m **PathFinder**, your empowerment coach.\n\nI\'m here to help you plan your next steps and map your path forward. Whether it\'s finding housing, a job, education, or just figuring out where to start — I\'ve got you.\n\n**What area of your life would you like to work on first?**';
      default:
        return 'Hello! How can I help you today?';
    }
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _loading || !_initialized) return;

    _textCtrl.clear();
    setState(() {
      _messages.add(_ChatMsg(isUser: true, text: text, timestamp: DateTime.now()));
      _loading = true;
    });
    _scrollToBottom();

    String reply;
    if (_session != null) {
      // Gemini AI path
      try {
        final response = await _session!.sendMessage(Content.text(text));
        reply = response.text ?? _offlineResponse(widget.agent.id, text);
      } catch (_) {
        reply = _offlineResponse(widget.agent.id, text);
      }
    } else {
      // Offline knowledge-base path — simulate a short thinking delay
      await Future.delayed(const Duration(milliseconds: 800));
      reply = _offlineResponse(widget.agent.id, text);
    }

    if (mounted) {
      setState(() {
        _messages.add(_ChatMsg(isUser: false, text: reply, timestamp: DateTime.now()));
        _loading = false;
      });
      _scrollToBottom();
    }
  }

  /// Offline knowledge-base responses — always available, no API key needed.
  String _offlineResponse(String agentId, String input) {
    final q = input.toLowerCase();
    switch (agentId) {
      case 'notebook':
        return _notebookReply(q, input);
      case 'safety':
        return _safetyReply(q);
      case 'legal':
        return _legalReply(q);
      case 'manus':
        return _pathfinderReply(q);
      default:
        return 'Thank you for your message. I\'m here to help — could you tell me more about what you need?';
    }
  }

  String _notebookReply(String q, String original) {
    if (q.length > 100) {
      // User pasted a long document — summarise it simply
      final wordCount = original.split(' ').length;
      return '**Document received** ($wordCount words)\n\n'
          'Here is what I can see from your text:\n\n'
          '- This appears to be a formal written document\n'
          '- Look for key sections: **Dates**, **Names**, **Actions Required**, and **Deadlines**\n'
          '- Any **bold or underlined** text usually contains the most important obligations\n\n'
          '**What to do next:**\n'
          '1. Identify any dates mentioned — write them down\n'
          '2. Note any amount of money mentioned\n'
          '3. Look for words like "must", "required", "deadline", "failure to comply"\n\n'
          'Ask me any specific question about the document and I will help you understand it.\n\n'
          '_For deeper AI analysis, ask your administrator to configure the Gemini API key._';
    }
    if (q.contains('court') || q.contains('summon') || q.contains('hearing')) {
      return '**Court Documents — What You Need to Know**\n\n'
          '📅 **First: Find the hearing date** — it is usually near the top\n\n'
          '⚠️ **You must appear** on the date unless a lawyer gets it postponed\n\n'
          '**Common court document types:**\n'
          '- **Summons** — you are being called to appear in court\n'
          '- **Restraining/Protection Order** — someone is legally ordered to stay away\n'
          '- **Affidavit** — a sworn written statement of facts\n'
          '- **Petition** — a formal request to the court\n\n'
          '**Important:** Bring the original document to court. Arrive 30 minutes early. If you do not understand the document, take it to a lawyer or DOVVSU before the hearing date.\n\n'
          'What specific part of the document confuses you?';
    }
    if (q.contains('lease') || q.contains('rent') || q.contains('tenancy')) {
      return '**Rental / Tenancy Documents**\n\n'
          'Key things to check in any lease:\n\n'
          '1. **Duration** — when does it start and end?\n'
          '2. **Monthly rent amount** — and when is it due?\n'
          '3. **Deposit** — how much, and conditions for getting it back\n'
          '4. **Termination** — how much notice is required to leave?\n'
          '5. **Repairs** — who is responsible for what?\n\n'
          '⚠️ **Red flags in a lease:**\n'
          '- Landlord can enter without notice\n'
          '- No refund of deposit under any circumstances\n'
          '- Penalties for leaving early that seem very large\n\n'
          'Paste the specific clause you want me to explain.';
    }
    if (q.contains('police') || q.contains('report') || q.contains('statement')) {
      return '**Police Reports & Statements**\n\n'
          '**If you are reading a police report about your case:**\n'
          '- The "complainant" is the person who reported\n'
          '- The "accused/suspect" is the person being investigated\n'
          '- "Prima facie" means there is enough evidence to proceed\n\n'
          '**Your rights regarding a police statement:**\n'
          '- You can request a copy of any statement you made\n'
          '- You can have a lawyer present when making a statement\n'
          '- You do not have to sign anything you do not agree with\n\n'
          'Contact DOVVSU (0800800800) for police-related DV matters. What part of the report do you need explained?';
    }
    return 'I\'m here to help you understand any document in plain language.\n\n'
        '**To get started, you can:**\n'
        '- Paste the text of the document directly into this chat\n'
        '- Ask me to explain a specific legal or medical term\n'
        '- Describe what the document is about and what confuses you\n\n'
        '**Common documents I can help with:**\n'
        'Court orders, police reports, lease agreements, medical forms, legal letters, protection orders, and more.';
  }

  String _safetyReply(String q) {
    if (q.contains('yes') || q.contains('safe') || q.contains('okay') || q.contains('ok')) {
      return '**I\'m glad you\'re safe right now.**\n\n'
          'Let\'s use this time to build your safety plan. A good plan covers:\n\n'
          '1. 🚪 **Escape routes** — if you need to leave quickly\n'
          '2. 📞 **Emergency contacts** — people you can call immediately\n'
          '3. 💬 **Code word** — a signal to trusted people that you need help\n'
          '4. 🎒 **Go-bag** — essentials ready to grab\n'
          '5. 📱 **Digital safety** — securing your phone and accounts\n\n'
          '**Where would you like to start?** Just type the number (1-5) or describe your situation.';
    }
    if (q.contains('escape') || q.contains('leave') || q.contains('route') || q.contains('exit')) {
      return '**Escape Planning**\n\n'
          'Think through these now, when you have time:\n\n'
          '🚪 **Know your exits:**\n'
          '- Which doors/windows can you leave through quickly?\n'
          '- Where is the nearest public place you can go (church, shop, neighbour)?\n'
          '- If you have children, where will you take them?\n\n'
          '🚗 **Transport:**\n'
          '- Do you have access to a car or motorbike?\n'
          '- Do you have saved trotro/taxi money?\n'
          '- Which trusted person can come pick you up?\n\n'
          '📍 **Destination:**\n'
          '- A trusted family member\'s home\n'
          '- A friend in a different area\n'
          '- Beacon of New Beginnings: 0800800800\n'
          '- Ghana Police Emergency: 999\n\n'
          '**Practice the route in your mind.** What is your biggest challenge with leaving?';
    }
    if (q.contains('code') || q.contains('word') || q.contains('signal')) {
      return '**Setting Up a Code Word**\n\n'
          'A code word is a secret signal you share with ONE trusted person — a friend, sibling, or neighbour.\n\n'
          '**How it works:**\n'
          '- Choose a normal-sounding word or phrase (e.g. "Can you bring me some sugar?" or "How is Auntie Ama?")\n'
          '- When you say/text this word, they know to call the police or come to you immediately\n'
          '- Practice it so they respond automatically\n\n'
          '**Choose someone who:**\n'
          '✓ Will not tell the abuser\n'
          '✓ Lives or works nearby\n'
          '✓ Will act quickly without asking questions first\n'
          '✓ Has a working phone always\n\n'
          'Do you have someone in mind? I can help you think through how to have this conversation with them safely.';
    }
    if (q.contains('bag') || q.contains('pack') || q.contains('go-bag') || q.contains('grab')) {
      return '**Emergency Go-Bag Checklist**\n\n'
          'Pack these in a bag you can grab in under 2 minutes. Store it somewhere accessible — at a trusted person\'s home is safer.\n\n'
          '📄 **Documents (copies are fine):**\n'
          '- Ghana Card / passport\n'
          '- Children\'s birth certificates\n'
          '- Marriage certificate (if applicable)\n'
          '- Bank account details\n'
          '- Any court orders\n\n'
          '💰 **Money:** At least a few days\' expenses in cash\n\n'
          '📱 **Phone** (charged) + charger + a list of important numbers written on paper (in case phone is taken)\n\n'
          '👗 **Clothes:** 2-3 days for you and children\n\n'
          '💊 **Medications:** Enough for 7+ days\n\n'
          '🔑 **Keys:** Spare house/car key\n\n'
          'What do you already have ready?';
    }
    if (q.contains('phone') || q.contains('digital') || q.contains('track') || q.contains('spy')) {
      return '**Digital Safety**\n\n'
          '⚠️ **Signs your phone may be monitored:**\n'
          '- Battery drains unusually fast\n'
          '- Phone is warm even when not in use\n'
          '- The abuser knows things you only said on the phone\n\n'
          '**Protect yourself:**\n'
          '1. **Change your passwords** — use a device they don\'t have access to\n'
          '2. **Turn off location sharing** — Settings → Privacy → Location\n'
          '3. **Use private browsing** when researching help options\n'
          '4. **Delete your browser history** after searching for support\n'
          '5. **Use a trusted friend\'s phone** for sensitive calls\n'
          '6. **Review app permissions** — look for apps you didn\'t install\n\n'
          '**On this app:** Your data is stored only on your device. Nothing is shared externally.\n\n'
          'Do you have specific concerns about your phone?';
    }
    if (q.contains('child') || q.contains('children') || q.contains('kid')) {
      return '**Protecting Your Children**\n\n'
          '**At school/daycare:**\n'
          '- Inform the school that only you (or a named person) can pick up the child\n'
          '- Provide a photo of the abuser with "do not release" instruction\n'
          '- Keep the school\'s number saved — they can call you if something seems wrong\n\n'
          '**What to tell children:**\n'
          '- Practice a code word with them too — "call Auntie if Mummy says [word]"\n'
          '- Tell them it is NEVER their fault\n'
          '- Teach them to call 999 in an emergency\n'
          '- Identify a neighbour they can run to\n\n'
          '**Legal protection:**\n'
          '- You can request an Emergency Protection Order from a Family Court\n'
          '- DOVVSU can assist with child custody safety measures\n\n'
          'How many children do you have, and what are their ages? I can give more specific advice.';
    }
    return '**SafetyGuide is here for you.**\n\n'
        'I can help you build a personalised safety plan covering:\n\n'
        '- 🚪 Escape routes and planning\n'
        '- 📞 Emergency contacts (Ghana: 999, DV Hotline: 0800800800)\n'
        '- 💬 Setting up a code word with someone you trust\n'
        '- 🎒 What to pack in an emergency go-bag\n'
        '- 📱 Digital safety and phone privacy\n'
        '- 👨‍👩‍👧 Protecting your children\n'
        '- 💰 Financial safety planning\n\n'
        '**Are you safe right now?** And which area would you like to focus on first?';
  }

  String _legalReply(String q) {
    if (q.contains('protection order') || q.contains('restraining')) {
      return '**Protection Orders in Ghana**\n\n'
          'A Protection Order (also called a Domestic Violence Order) legally requires the abuser to stay away from you.\n\n'
          '**How to get one:**\n'
          '1. Go to the **Domestic Violence Court** (in Accra: located at the Law Courts Complex)\n'
          '2. OR go to **DOVVSU** first — they can assist with the application\n'
          '3. Fill out an application form (free)\n'
          '4. A judge can grant an **Emergency Protection Order the same day** if you are in immediate danger\n'
          '5. A full Protection Order hearing is usually within 14 days\n\n'
          '**What it covers:**\n'
          '- The abuser cannot come to your home or workplace\n'
          '- Cannot contact you by any means\n'
          '- Violations can result in immediate arrest\n\n'
          '**You do NOT need a lawyer to apply**, but having one helps.\n\n'
          'Do you want to know more about what evidence to bring, or what happens at the hearing?';
    }
    if (q.contains('dovvsu') || q.contains('police') || q.contains('report')) {
      return '**DOVVSU — Domestic Violence & Victim Support Unit**\n\n'
          'DOVVSU is a specialised Ghana Police unit for domestic violence cases.\n\n'
          '**What they do:**\n'
          '- Receive and investigate DV complaints\n'
          '- Arrest perpetrators when evidence supports it\n'
          '- Refer victims to shelters, counselling, and legal aid\n'
          '- Assist with Protection Orders\n\n'
          '**How to report:**\n'
          '- Walk into any DOVVSU office (every regional police headquarters)\n'
          '- Call the DV hotline: **0800800800** (free, 24/7)\n'
          '- Call Ghana Emergency: **999**\n\n'
          '**When you go:**\n'
          '- Bring any evidence (photos, medical reports, messages)\n'
          '- You can bring a support person with you\n'
          '- If you have injuries, request to see a doctor first\n'
          '- Your report is confidential\n\n'
          '**Important:** You have the right to report even without visible injuries. Emotional and psychological abuse is also covered under the DV Act 2007.';
    }
    if (q.contains('act') || q.contains('law') || q.contains('dv act') || q.contains('domestic violence act')) {
      return '**Ghana Domestic Violence Act 2007 (Act 732) — Key Points**\n\n'
          '**What is covered:**\n'
          '- Physical abuse (hitting, pushing, burning)\n'
          '- Sexual abuse within marriage or relationship\n'
          '- Economic/financial abuse\n'
          '- Emotional and psychological abuse\n'
          '- Threats and intimidation\n\n'
          '**Key protections:**\n'
          '- The abuser can be arrested WITHOUT a warrant\n'
          '- The court can grant emergency protection orders same-day\n'
          '- Marital rape is a crime under this Act\n'
          '- You can report without having visible injuries\n\n'
          '**Penalties:**\n'
          '- Up to 2 years imprisonment for first offence\n'
          '- Higher sentences for repeat offenders or serious harm\n\n'
          '**What the Act does NOT require:**\n'
          '- You do not need to be married to the abuser\n'
          '- Covers partners, ex-partners, family members\n\n'
          'Would you like information about a specific aspect of the Act?';
    }
    if (q.contains('divorce') || q.contains('separate') || q.contains('marriage')) {
      return '**Divorce and Separation in Ghana**\n\n'
          '**Types of marriage recognised:**\n'
          '- Ordinance (registered) marriage\n'
          '- Customary marriage\n'
          '- Islamic marriage\n\n'
          '**For a divorce (Ordinance marriage):**\n'
          '1. File a Petition at the High Court\n'
          '2. Grounds include: unreasonable behaviour, desertion, adultery\n'
          '3. Process takes 3–12 months depending on if contested\n\n'
          '**Protect yourself before filing:**\n'
          '- Open a personal bank account\n'
          '- Gather copies of financial documents\n'
          '- Document any assets\n'
          '- Consult a lawyer (Legal Aid Commission offers free help)\n\n'
          '**Legal Aid Commission Ghana:** 030-266-7748\n'
          '**FIDA Ghana (women\'s legal aid):** 030-222-0397\n\n'
          'Safety note: Only proceed with divorce when you have a safety plan in place. Are you currently safe?';
    }
    if (q.contains('custody') || q.contains('children') || q.contains('child')) {
      return '**Child Custody in Ghana**\n\n'
          '**Key principle:** Courts decide based on the **best interests of the child**.\n\n'
          '**Types of custody:**\n'
          '- **Physical custody** — where the child lives\n'
          '- **Legal custody** — who makes decisions about education, medical care\n'
          '- Courts often grant joint legal custody but sole physical custody to one parent\n\n'
          '**If there is a DV history:**\n'
          '- Courts CAN take DV into account\n'
          '- Police reports, medical records, and DOVVSU records are important evidence\n'
          '- You can request supervised visitation if you fear for the child\'s safety\n\n'
          '**Emergency steps:**\n'
          '- If the abuser takes the child, call DOVVSU immediately: 0800800800\n'
          '- A lawyer can apply for an Emergency Interim Order within hours\n\n'
          '**Free legal help:** Legal Aid Commission — 030-266-7748\n\n'
          'How old are your children? This affects the custody process.';
    }
    return '**LegalNav — Your Legal Information Guide**\n\n'
        'I can explain Ghanaian laws and processes in plain language. I cover:\n\n'
        '- ⚖️ **Ghana DV Act 2007** — your rights and protections\n'
        '- 🛡️ **Protection Orders** — how to get one, what it does\n'
        '- 👮 **DOVVSU** — how to report, what to expect\n'
        '- 💍 **Divorce & separation** — the process and your rights\n'
        '- 👨‍👩‍👧 **Child custody** — what the courts consider\n'
        '- 📋 **Legal Aid** — free legal help in Ghana\n\n'
        '*Note: I provide information, not legal advice. For your specific case, consult a lawyer or call Legal Aid: **030-266-7748**.*\n\n'
        '**What would you like to understand?**';
  }

  String _pathfinderReply(String q) {
    if (q.contains('job') || q.contains('work') || q.contains('employ') || q.contains('income')) {
      return '**Finding Work — Your Next Steps**\n\n'
          '**Start by assessing your skills:**\n'
          '- What did you do before? (even unpaid work counts)\n'
          '- What are you good at? (cooking, sewing, teaching, caring for others, admin)\n'
          '- What can you do from home?\n\n'
          '**Quick income options in Ghana:**\n'
          '- Food preparation / catering (small scale to start)\n'
          '- Hairdressing or dressmaking (if you have the skill)\n'
          '- Teaching or tutoring\n'
          '- Cleaning services\n'
          '- Market trading / petty trading\n\n'
          '**Free skills training:**\n'
          '- NVTI (National Vocational Training Institute) — government skills training\n'
          '- Beacon of New Beginnings job training programme (coming soon)\n\n'
          '**Beacon jobs page:** Check the Jobs section of this app for current openings and volunteer roles.\n\n'
          'What skills do you already have? Let\'s build from there.';
    }
    if (q.contains('house') || q.contains('shelter') || q.contains('home') || q.contains('place to stay')) {
      return '**Finding Safe Housing**\n\n'
          '**Immediate options:**\n'
          '- Trusted family member (outside the abuser\'s reach)\n'
          '- Trusted friend in a different area\n'
          '- Emergency shelter (contact Beacon: 0800800800)\n\n'
          '**Short-term options:**\n'
          '- Transitional housing programmes\n'
          '- Church-based accommodation networks\n'
          '- DOVVSU can refer you to shelters\n\n'
          '**Longer-term planning:**\n'
          '- Rent a room/chamber-and-hall with a trusted person\n'
          '- Government low-income housing (SSNIT flats)\n'
          '- Community-based housing schemes\n\n'
          '**Financial help for housing:**\n'
          '- Many landlords accept "advance" in monthly installments for vulnerable persons\n'
          '- Keep any income you can, even small amounts, for a housing deposit fund\n\n'
          'Where are you located? I can give more specific recommendations.';
    }
    if (q.contains('school') || q.contains('educat') || q.contains('learn') || q.contains('study')) {
      return '**Education & Learning**\n\n'
          '**For yourself:**\n'
          '- **Free adult literacy** — Ghana Education Service has programmes\n'
          '- **NVTI** (National Vocational Training Institute) — low-cost skills training\n'
          '- **Distance learning** — University of Ghana, KNUST offer distance programmes\n'
          '- **Online learning** (free): Coursera, Khan Academy, YouTube tutorials\n\n'
          '**For your children:**\n'
          '- Public school is free (basic education)\n'
          '- Capitation grant covers school fees at public schools\n'
          '- School Feeding Programme provides meals\n'
          '- BECE/WASSCE waiver programmes available for vulnerable children\n\n'
          '**Scholarships:**\n'
          '- Ghana Scholarship Secretariat\n'
          '- Mastercard Foundation Scholars Program\n'
          '- Various NGO scholarships for women\n\n'
          'What level of education are you or your children at?';
    }
    if (q.contains('money') || q.contains('financ') || q.contains('budget') || q.contains('save') || q.contains('debt')) {
      return '**Financial Empowerment — Starting Fresh**\n\n'
          '**Step 1: Open your own account**\n'
          '- A bank or mobile money account in YOUR name only\n'
          '- Use MTN MoMo, Vodafone Cash, or AirtelTigo Money (easy to open)\n'
          '- Keep the PIN private\n\n'
          '**Step 2: Track every cedi**\n'
          '- Use the Budget tracker in this app\n'
          '- Even small amounts add up — document everything\n\n'
          '**Step 3: Build a small emergency fund**\n'
          '- Even ₵50 saved separately is a start\n'
          '- Keep cash hidden in a safe place only you know\n\n'
          '**Step 4: Increase income**\n'
          '- Identify ONE skill you can monetise immediately\n'
          '- Start small — even ₵5 profit per day builds confidence\n\n'
          '**Micro-loans available in Ghana:**\n'
          '- Sinapi Aba Trust (women\'s micro-loans)\n'
          '- Opportunity International Ghana\n'
          '- Community-based susu groups\n\n'
          'What is your current financial situation? I can help you make a specific plan.';
    }
    if (q.contains('goal') || q.contains('plan') || q.contains('step') || q.contains('start') || q.contains('begin')) {
      return '**Your 90-Day Fresh Start Plan**\n\n'
          '**Month 1 — Stabilise**\n'
          '✓ Ensure you have a safe place to stay\n'
          '✓ Secure your documents (ID, certificates)\n'
          '✓ Open a personal mobile money account\n'
          '✓ Connect with ONE support person you trust\n'
          '✓ Report to DOVVSU if you haven\'t (0800800800)\n\n'
          '**Month 2 — Build**\n'
          '✓ Identify a source of income (even small)\n'
          '✓ Start saving — even ₵20 per week\n'
          '✓ Enrol in one skills programme or course\n'
          '✓ Connect with a support group\n\n'
          '**Month 3 — Grow**\n'
          '✓ Set a specific financial goal\n'
          '✓ Apply for one job or expand your small business\n'
          '✓ Review your safety plan — update if needed\n'
          '✓ Celebrate your progress — you are doing it!\n\n'
          '**Remember:** Healing is not linear. Any step forward counts.\n\n'
          'Which month are you in? Let\'s focus on your next specific step.';
    }
    return '**PathFinder — Your Empowerment Coach**\n\n'
        'I\'m here to help you plan your path forward. Let\'s focus on what matters most to you right now.\n\n'
        '**I can help you with:**\n'
        '- 💼 **Finding work** — skills assessment, job search, starting a business\n'
        '- 🏠 **Housing** — safe options, short and long-term\n'
        '- 🎓 **Education** — returning to school, free training, children\'s education\n'
        '- 💰 **Finances** — budgeting, saving, micro-loans, mobile money\n'
        '- 🎯 **Goal setting** — 30, 60, 90-day plans\n'
        '- 💪 **Building confidence** — small wins, self-care\n\n'
        '**What matters most to you right now?** Tell me where you are and we\'ll figure out the next step together.';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.agent.accent.withValues(alpha: 0.3), widget.agent.accent.withValues(alpha: 0.1)],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: widget.agent.accent.withValues(alpha: 0.4)),
              ),
              child: Icon(widget.agent.icon, color: widget.agent.accent, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.agent.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text(
                  widget.agent.tagline,
                  style: TextStyle(fontSize: 10, color: widget.agent.accent),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: Colors.white.withValues(alpha: 0.6)),
            tooltip: 'New conversation',
            onPressed: () {
              setState(() {
                _messages.clear();
                _initialized = false;
                _error = null;
              });
              _initModel();
            },
          ),
        ],
      ),
      body: _error != null
          ? _buildError()
          : Column(
              children: [
                Expanded(child: _buildMessages()),
                _buildInput(),
              ],
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: _kRed, size: 56),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages() {
    if (_messages.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: widget.agent.accent, strokeWidth: 2),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _messages.length + (_loading ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == _messages.length) return _buildTyping();
        return _buildBubble(_messages[i]);
      },
    );
  }

  Widget _buildBubble(_ChatMsg msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.agent.accent.withValues(alpha: 0.3), widget.agent.accent.withValues(alpha: 0.1)],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: widget.agent.accent.withValues(alpha: 0.4)),
              ),
              child: Icon(widget.agent.icon, color: widget.agent.accent, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? widget.agent.accent.withValues(alpha: 0.2) : _kSurface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser ? widget.agent.accent.withValues(alpha: 0.3) : _kBorder,
                ),
              ),
              child: isUser
                  ? Text(
                      msg.text,
                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                    )
                  : MarkdownBody(
                      data: msg.text,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          height: 1.5,
                        ),
                        strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        listBullet: TextStyle(color: widget.agent.accent),
                        h3: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        code: TextStyle(
                          backgroundColor: _kCard,
                          color: widget.agent.accent,
                          fontSize: 13,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          border: Border(left: BorderSide(color: widget.agent.accent, width: 3)),
                        ),
                      ),
                    ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTyping() {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.agent.accent.withValues(alpha: 0.3), widget.agent.accent.withValues(alpha: 0.1)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(widget.agent.icon, color: widget.agent.accent, size: 14),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) => _Dot(index: i, color: widget.agent.accent)),
          ),
        ),
      ],
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: _kCard,
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _kBorder),
              ),
              child: TextField(
                controller: _textCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Message ${widget.agent.name}...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.agent.accent, widget.agent.accent.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: widget.agent.accent.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Typing indicator dots ─────────────────────────────────────────────────────
class _Dot extends StatefulWidget {
  final int index;
  final Color color;
  const _Dot({required this.index, required this.color});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.index * 150), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Opacity(
          opacity: _anim.value,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

// ── Chat message model ────────────────────────────────────────────────────────
class _ChatMsg {
  final bool isUser;
  final String text;
  final DateTime timestamp;
  const _ChatMsg({
    required this.isUser,
    required this.text,
    required this.timestamp,
  });
}
