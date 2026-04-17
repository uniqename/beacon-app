import 'package:flutter/material.dart';

class ArticleReaderScreen extends StatefulWidget {
  final String articleId;
  final String title;
  final String category;

  const ArticleReaderScreen({
    super.key,
    required this.articleId,
    required this.title,
    required this.category,
  });

  @override
  State<ArticleReaderScreen> createState() => _ArticleReaderScreenState();
}

class _ArticleReaderScreenState extends State<ArticleReaderScreen> {
  bool _isFavorite = false;
  double _fontSize = 16;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Article'),
        backgroundColor: Colors.indigo[600],
        actions: [
          IconButton(
            icon: Icon(Icons.text_decrease),
            onPressed: () {
              if (_fontSize > 12) setState(() => _fontSize -= 2);
            },
          ),
          IconButton(
            icon: Icon(Icons.text_increase),
            onPressed: () {
              if (_fontSize < 24) setState(() => _fontSize += 2);
            },
          ),
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(value: 'share', child: Text('Share')),
              PopupMenuItem(value: 'download', child: Text('Download for Offline')),
              PopupMenuItem(value: 'report', child: Text('Report Issue')),
            ],
            onSelected: (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$value feature coming soon')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.indigo[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.category.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[700],
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text('8 min read', style: TextStyle(color: Colors.grey[600])),
                SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text('Updated Jan 2025', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            SizedBox(height: 24),
            Divider(),
            SizedBox(height: 24),
            Text(
              _getArticleContent(),
              style: TextStyle(fontSize: _fontSize, height: 1.6),
            ),
            SizedBox(height: 32),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber[700]),
                      SizedBox(width: 12),
                      Text(
                        'Need Support?',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'If you\'re in immediate danger, call the Ghana Domestic Violence Hotline: 999 or 191',
                    style: TextStyle(color: Colors.amber[900]),
                  ),
                  SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/emergency_contacts');
                    },
                    icon: Icon(Icons.phone),
                    label: Text('View Emergency Contacts'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            Text(
              'Related Articles',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ..._getRelatedArticles().map((article) => Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(Icons.article, color: Colors.indigo[600]),
                    title: Text(article['title']!),
                    subtitle: Text('${article['category']} • ${article['duration']}'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to related article
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }

  String _getArticleContent() {
    return '''Domestic violence is a serious issue that affects many families in Ghana. Understanding the signs and knowing your options is the first step toward safety.

What is Domestic Violence?

Domestic violence is a pattern of behavior used to gain or maintain power and control over an intimate partner or family member. It can take many forms:

• Physical abuse: Hitting, slapping, pushing, or any form of physical harm
• Emotional abuse: Insults, threats, intimidation, or isolation
• Economic abuse: Controlling finances or preventing employment
• Sexual abuse: Any unwanted sexual activity or coercion

Recognizing the Signs

It's important to recognize the warning signs of an abusive relationship:

1. Your partner is extremely jealous or possessive
2. You feel afraid of your partner
3. Your partner controls where you go or who you see
4. You've been threatened or intimidated
5. Your partner blames you for their abusive behavior

The Cycle of Violence

Many abusive relationships follow a predictable pattern:

1. Tension Building: Minor incidents occur, victim walks on eggshells
2. Acute Violence: A serious incident of abuse occurs
3. Honeymoon Phase: Abuser apologizes, promises to change
4. Calm: Period of relative peace before tension builds again

Understanding this cycle can help you recognize patterns in your relationship.

Your Legal Rights in Ghana

Ghana's Domestic Violence Act 732 (2007) provides protection for victims:

• Defines domestic violence broadly
• Provides for protection orders
• Makes domestic violence a criminal offense
• Establishes specialized domestic violence courts

You have the right to:
• Report abuse to the police
• Seek a protection order
• Access shelters and support services
• Pursue criminal charges against your abuser

Taking Action

If you're experiencing domestic violence:

1. Prioritize your safety
2. Document incidents (photos, medical records, witness statements)
3. Create a safety plan
4. Reach out for help - you don't have to face this alone
5. Know your legal options

Remember: The abuse is not your fault. You deserve to be safe and respected.

Where to Get Help

• Ghana Domestic Violence Hotline: 999 or 191
• Domestic Violence and Victim Support Unit (DOVVSU): Available at all police stations
• Women in Law & Development in Africa (WiLDAF-Ghana): Legal assistance
• Ark Foundation Ghana: Shelter and support services

Your safety and well-being matter. Reach out for support today.''';
  }

  List<Map<String, String>> _getRelatedArticles() {
    return [
      {
        'title': 'Creating Your Safety Plan',
        'category': 'Safety',
        'duration': '8 min read',
      },
      {
        'title': 'Legal Rights Under DV Act 732',
        'category': 'Legal',
        'duration': '10 min read',
      },
      {
        'title': 'Supporting Children Through Trauma',
        'category': 'Parenting',
        'duration': '7 min read',
      },
    ];
  }
}
