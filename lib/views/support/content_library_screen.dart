import 'package:flutter/material.dart';

class ContentLibraryScreen extends StatefulWidget {
  const ContentLibraryScreen({super.key});

  @override
  State<ContentLibraryScreen> createState() => _ContentLibraryScreenState();
}

class _ContentLibraryScreenState extends State<ContentLibraryScreen> {
  String _selectedCategory = 'All';

  final List<EducationalContent> _allContent = [
    EducationalContent(
      id: '1',
      title: 'Understanding Domestic Violence',
      category: 'Education',
      duration: '5 min read',
      description: 'Learn about the different types of domestic violence and how to recognize them.',
      isFavorite: false,
    ),
    EducationalContent(
      id: '2',
      title: 'Creating Your Safety Plan',
      category: 'Safety',
      duration: '8 min read',
      description: 'Step-by-step guide to developing a comprehensive safety plan for you and your family.',
      isFavorite: true,
    ),
    EducationalContent(
      id: '3',
      title: 'Legal Rights in Ghana - DV Act 732',
      category: 'Legal',
      duration: '10 min read',
      description: 'Understand your legal rights under Ghana\'s Domestic Violence Act 732.',
      isFavorite: false,
    ),
    EducationalContent(
      id: '4',
      title: 'Self-Care During Crisis',
      category: 'Wellness',
      duration: '6 min read',
      description: 'Practical self-care strategies to maintain your mental health during difficult times.',
      isFavorite: false,
    ),
    EducationalContent(
      id: '5',
      title: 'Financial Independence Guide',
      category: 'Financial',
      duration: '12 min read',
      description: 'Building financial security and independence for your future.',
      isFavorite: false,
    ),
    EducationalContent(
      id: '6',
      title: 'Supporting Children Through Trauma',
      category: 'Parenting',
      duration: '7 min read',
      description: 'How to help your children cope and heal from witnessing domestic violence.',
      isFavorite: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final categories = ['All', 'Education', 'Safety', 'Legal', 'Wellness', 'Financial', 'Parenting'];
    final filteredContent = _selectedCategory == 'All'
        ? _allContent
        : _allContent.where((c) => c.category == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Educational Content'),
        backgroundColor: Colors.indigo[600],
        actions: [
          IconButton(
            icon: Icon(Icons.favorite),
            onPressed: () {
              // Navigate to favorites
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = category);
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Colors.indigo[100],
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: filteredContent.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.article, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No content in this category', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: filteredContent.length,
                    itemBuilder: (context, index) {
                      final content = filteredContent[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () => _openContent(content),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(content.category).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        content.category,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _getCategoryColor(content.category),
                                        ),
                                      ),
                                    ),
                                    Spacer(),
                                    IconButton(
                                      icon: Icon(
                                        content.isFavorite ? Icons.favorite : Icons.favorite_border,
                                        color: content.isFavorite ? Colors.red : Colors.grey,
                                      ),
                                      onPressed: () => _toggleFavorite(content),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Text(
                                  content.title,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  content.description,
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                    SizedBox(width: 4),
                                    Text(
                                      content.duration,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Education':
        return Colors.blue;
      case 'Safety':
        return Colors.red;
      case 'Legal':
        return Colors.purple;
      case 'Wellness':
        return Colors.green;
      case 'Financial':
        return Colors.orange;
      case 'Parenting':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  void _toggleFavorite(EducationalContent content) {
    setState(() {
      content.isFavorite = !content.isFavorite;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(content.isFavorite ? 'Added to favorites' : 'Removed from favorites'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _openContent(EducationalContent content) {
    Navigator.pushNamed(context, '/article', arguments: content);
  }
}

class EducationalContent {
  final String id;
  final String title;
  final String category;
  final String duration;
  final String description;
  bool isFavorite;

  EducationalContent({
    required this.id,
    required this.title,
    required this.category,
    required this.duration,
    required this.description,
    this.isFavorite = false,
  });
}
