import 'package:flutter/material.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  _HelpScreenState createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Getting Started',
    'Services',
    'Community',
    'Safety',
    'Privacy',
    'Technical',
  ];

  final List<FAQItem> _faqItems = [
    FAQItem(
      category: 'Getting Started',
      question: 'How do I create an account?',
      answer: 'You can create an account by tapping "Sign Up" on the welcome screen. You\'ll need to provide an email address and create a secure password. We also offer anonymous browsing for immediate access to resources.',
    ),
    FAQItem(
      category: 'Getting Started',
      question: 'What is anonymous mode?',
      answer: 'Anonymous mode allows you to access many features without creating an account. Your privacy is completely protected, though some community features require account creation for safety reasons.',
    ),
    FAQItem(
      category: 'Services',
      question: 'How do I find services near me?',
      answer: 'Use the Services tab to browse available support options. You can filter by type of help needed (emergency, shelter, legal, counseling, etc.) and the app will show resources matched to your location.',
    ),
    FAQItem(
      category: 'Services',
      question: 'Are the services really free?',
      answer: 'Yes! All services provided through Beacon of New Beginnings are completely free. We believe everyone deserves access to support regardless of their financial situation.',
    ),
    FAQItem(
      category: 'Services',
      question: 'How do I contact a service provider?',
      answer: 'Each service listing includes contact information. You can call directly, send an email through the app, or visit in person during listed hours. Emergency services are available 24/7.',
    ),
    FAQItem(
      category: 'Community',
      question: 'Why do I need an account for support groups?',
      answer: 'Support groups require accounts to ensure a safe, moderated environment. This helps us verify members, maintain privacy, and provide professional oversight while allowing anonymous participation within groups.',
    ),
    FAQItem(
      category: 'Community',
      question: 'Can I share my story anonymously?',
      answer: 'Absolutely! You can choose to share your story anonymously when submitting. We review all stories to ensure they\'re inspiring and safe for our community before publication.',
    ),
    FAQItem(
      category: 'Safety',
      question: 'Is this app safe to use?',
      answer: 'Yes. We use industry-standard security measures to protect your information. The app can be quickly closed if needed, and we never store sensitive personal details on your device.',
    ),
    FAQItem(
      category: 'Safety',
      question: 'What if someone sees me using this app?',
      answer: 'The app has a discrete icon and can be quickly closed. You can also use anonymous mode to avoid creating account traces. If you\'re in immediate danger, use the emergency features or call 911.',
    ),
    FAQItem(
      category: 'Safety',
      question: 'How do I quickly close the app?',
      answer: 'You can close the app normally, or use the Quick Exit feature in your profile settings. The app is designed to close completely without leaving traces in your recent apps.',
    ),
    FAQItem(
      category: 'Privacy',
      question: 'What information do you collect?',
      answer: 'We only collect information necessary to provide services. For anonymous users, we collect no personal data. For account holders, we store email, chosen name, and any information you voluntarily share.',
    ),
    FAQItem(
      category: 'Privacy',
      question: 'Do you share my information?',
      answer: 'Never. We do not share, sell, or distribute any user information. The only exception is if required by law enforcement with proper legal documentation, and we\'ll notify you if legally permitted.',
    ),
    FAQItem(
      category: 'Technical',
      question: 'The app isn\'t working properly. What should I do?',
      answer: 'First, try closing and reopening the app. If problems persist, check for app updates in your device\'s app store. You can also send feedback through the profile menu with details about the issue.',
    ),
    FAQItem(
      category: 'Technical',
      question: 'How do I update the app?',
      answer: 'App updates are available through your device\'s app store. We recommend enabling automatic updates to ensure you have the latest features and security improvements.',
    ),
    FAQItem(
      category: 'Technical',
      question: 'Can I use this app offline?',
      answer: 'Some features work offline, including emergency contact information and previously loaded content. However, most services require an internet connection to provide up-to-date information.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Help & FAQ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal[600],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildIntroSection(),
          _buildCategoryFilter(),
          Expanded(child: _buildFAQList()),
        ],
      ),
    );
  }

  Widget _buildIntroSection() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal[100]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: Colors.teal[600], size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Here to Help',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[800],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Find answers to common questions about using the Beacon app, accessing services, and protecting your privacy.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.teal[700],
              height: 1.4,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.support_agent, color: Colors.teal[600], size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Can\'t find what you\'re looking for? Contact our support team anytime.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.teal[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          
          return Container(
            margin: EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Colors.teal[100],
              checkmarkColor: Colors.teal[600],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFAQList() {
    final filteredItems = _selectedCategory == 'All' 
        ? _faqItems 
        : _faqItems.where((item) => item.category == _selectedCategory).toList();

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _FAQCard(item: item);
      },
    );
  }
}

class FAQItem {
  final String category;
  final String question;
  final String answer;

  const FAQItem({
    required this.category,
    required this.question,
    required this.answer,
  });
}

class _FAQCard extends StatefulWidget {
  final FAQItem item;

  const _FAQCard({required this.item});

  @override
  _FAQCardState createState() => _FAQCardState();
}

class _FAQCardState extends State<_FAQCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.item.question,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                widget.item.category,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
            trailing: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.teal[600],
            ),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
          if (_isExpanded) ...[
            Divider(height: 1),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                widget.item.answer,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}