import 'package:flutter/material.dart';
import 'share_story_screen.dart';

class SuccessStoriesTab extends StatefulWidget {
  const SuccessStoriesTab({super.key});

  @override
  State<SuccessStoriesTab> createState() => _SuccessStoriesTabState();
}

class _SuccessStoriesTabState extends State<SuccessStoriesTab> {
  final List<SuccessStory> _stories = [
    SuccessStory(
      id: '1',
      title: 'Finding My Voice Again',
      excerpt: 'After years of silence, I learned to speak up for myself and help others do the same.',
      content: '''
For years, I believed the voice in my head that told me I wasn't worth anything. I stayed silent, thinking that was safer. But silence wasn't protecting me—it was shrinking me.

The turning point came when I walked into Beacon of New Beginnings for the first time. I was scared, broken, and sure that no one would understand. But the counselor looked at me and said, "Your story matters, and so do you."

It took months of therapy and support groups to even whisper my truth. But slowly, I found my voice. I learned that my experiences, while painful, had given me strength I didn't know I had.

Today, I facilitate support groups myself. I see the same fear in new members' eyes that I once carried. And I get to be the person who tells them: "Your story matters, and so do you."

If you're reading this and still finding your voice, know that it's there. It's been there all along, waiting for the right moment to emerge. Trust yourself. You are stronger than you know.
      ''',
      authorName: 'Akosua M.',
      submittedAt: DateTime.now().subtract(const Duration(days: 20)),
      category: 'Healing Journey',
      isAnonymous: false,
      likes: 47,
      isInspiring: true,
    ),
    SuccessStory(
      id: '2',
      title: 'Building a New Life, One Day at a Time',
      excerpt: 'From shelter to independence—how I built a stable life for me and my children.',
      content: '''
Three years ago, I arrived at the emergency shelter with nothing but my two children and the clothes on our backs. I was terrified, exhausted, and had no idea how I would survive as a single mother.

The shelter staff didn't just give us a roof—they gave us hope. They helped me enroll in a job training program while my children attended the on-site daycare. For the first time in years, I could focus on learning without worrying about their safety.

The computer skills course changed everything. I discovered I had a talent for data entry and customer service. Six months later, I got my first full-time job. It wasn't glamorous, but it was mine.

With help from the financial counseling program, I learned to budget and save. Last month, I signed the lease on our first apartment. My children each have their own room, and we have a small garden where we grow vegetables together.

I won't lie—some days are still hard. But we're building something beautiful together. My kids see their mother working, thriving, and creating a stable home. That's the greatest gift I could give them.

To anyone still in the early days of their journey: take it one day at a time. Every small step forward is progress. You're building a new life, and it's going to be beautiful.
      ''',
      authorName: 'A Proud Mother',
      submittedAt: DateTime.now().subtract(const Duration(days: 35)),
      category: 'Independence',
      isAnonymous: true,
      likes: 92,
      isInspiring: true,
    ),
    SuccessStory(
      id: '3',
      title: 'From Survivor to Advocate',
      excerpt: 'How I turned my pain into purpose and became an advocate for others.',
      content: '''
Five years ago, I thought my life was over. I had lost everything—my confidence, my sense of self, my belief that I deserved better. I felt completely alone.

But I wasn't alone. The Beacon of New Beginnings team showed me that I was part of a community of survivors who understood exactly what I was going through. In group therapy, I met women who had walked similar paths. Their strength inspired me to find my own.

As I healed, I realized that my experiences had given me something valuable: the ability to truly understand and help others in similar situations. I decided to study social work, with support from the education assistance program.

It wasn't easy—going back to school while working and healing from trauma. But every class felt like I was reclaiming my power. Every assignment was proof that I was more than what had happened to me.

Today, I work as a victim advocate. I get to be the person who sits with someone in the hospital, who helps them understand their legal options, who reminds them that they deserve safety and love.

My pain has become my purpose. The worst chapters of my life led me to the work I was meant to do. I'm grateful for the journey, even the difficult parts, because they brought me here.

If you're in the darkness right now, please know: this is not the end of your story. You have so much purpose ahead of you. Your healing will light the way for others.
      ''',
      authorName: 'Sarah K.',
      submittedAt: DateTime.now().subtract(const Duration(days: 8)),
      category: 'Career & Purpose',
      isAnonymous: false,
      likes: 73,
      isInspiring: true,
    ),
    SuccessStory(
      id: '4',
      title: 'Learning to Trust Again',
      excerpt: 'How I opened my heart to love and friendship after betrayal.',
      content: '''
Trust was the hardest thing to rebuild. After being betrayed by someone who was supposed to protect me, I put walls around my heart so high that no one could get in.

I was safe, but I was also lonely. I watched other people form friendships and relationships, and I wondered if I would ever feel that connection again.

In therapy, I learned that my walls weren't protecting me anymore—they were imprisoning me. My counselor helped me understand that I could be cautious without being closed off completely.

The first person I learned to trust was my support group facilitator. She was consistent, kind, and never pushed me beyond my comfort zone. Slowly, I began to trust the other group members too.

Then came my neighbor, who always said hello and never asked intrusive questions. Then my coworker, who covered for me when I had therapy appointments. Little by little, I let people in.

Last year, I started dating someone I met through a friend. It was terrifying, but I had learned to listen to my instincts. I could tell the difference between healthy nervousness and genuine red flags.

Trust isn't all-or-nothing. It's something you build slowly, brick by brick. And when you build it consciously, with good people, it's stronger than anything that came before.

I have a circle of people now who care about me. Real friends who celebrate my wins and support me through challenges. I never thought I'd have this again, but here I am, surrounded by love.
      ''',
      authorName: 'Anonymous Survivor',
      submittedAt: DateTime.now().subtract(const Duration(days: 50)),
      category: 'Relationships',
      isAnonymous: true,
      likes: 38,
      isInspiring: true,
    ),
  ];

  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final filteredStories = _getFilteredStories();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Success Stories',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Inspiring journeys of healing, growth, and empowerment',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 24),

            // Inspiration banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[100]!, Colors.pink[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Colors.purple[600],
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your story could inspire others',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Share your journey of healing and growth',
                    style: TextStyle(
                      color: Colors.purple[700],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _shareStory(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[600],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Share Your Story'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Category filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CategoryChip(
                    label: 'All',
                    isSelected: _selectedCategory == 'All',
                    onSelected: () => setState(() => _selectedCategory = 'All'),
                  ),
                  const SizedBox(width: 8),
                  _CategoryChip(
                    label: 'Healing Journey',
                    isSelected: _selectedCategory == 'Healing Journey',
                    onSelected: () => setState(() => _selectedCategory = 'Healing Journey'),
                  ),
                  const SizedBox(width: 8),
                  _CategoryChip(
                    label: 'Independence',
                    isSelected: _selectedCategory == 'Independence',
                    onSelected: () => setState(() => _selectedCategory = 'Independence'),
                  ),
                  const SizedBox(width: 8),
                  _CategoryChip(
                    label: 'Career & Purpose',
                    isSelected: _selectedCategory == 'Career & Purpose',
                    onSelected: () => setState(() => _selectedCategory = 'Career & Purpose'),
                  ),
                  const SizedBox(width: 8),
                  _CategoryChip(
                    label: 'Relationships',
                    isSelected: _selectedCategory == 'Relationships',
                    onSelected: () => setState(() => _selectedCategory = 'Relationships'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Stories list
            Expanded(
              child: ListView.builder(
                itemCount: filteredStories.length,
                itemBuilder: (context, index) {
                  final story = filteredStories[index];
                  return _StoryCard(
                    story: story,
                    onRead: () => _readStory(story),
                    onLike: () => _likeStory(story),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<SuccessStory> _getFilteredStories() {
    if (_selectedCategory == 'All') {
      return _stories;
    }
    
    return _stories.where((story) {
      return story.category == _selectedCategory;
    }).toList();
  }

  void _shareStory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShareStoryScreen(),
      ),
    );
  }

  void _readStory(SuccessStory story) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _StoryDetailSheet(story: story),
    );
  }

  void _likeStory(SuccessStory story) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you for your support!'),
        backgroundColor: Colors.pink,
      ),
    );
  }
}

class SuccessStory {
  final String id;
  final String title;
  final String excerpt;
  final String content;
  final String authorName;
  final DateTime submittedAt;
  final String category;
  final bool isAnonymous;
  final int likes;
  final bool isInspiring;

  const SuccessStory({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.content,
    required this.authorName,
    required this.submittedAt,
    required this.category,
    this.isAnonymous = false,
    this.likes = 0,
    this.isInspiring = false,
  });
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.purple[100],
      checkmarkColor: Colors.purple[600],
    );
  }
}

class _StoryCard extends StatelessWidget {
  final SuccessStory story;
  final VoidCallback onRead;
  final VoidCallback onLike;

  const _StoryCard({
    required this.story,
    required this.onRead,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with inspiration badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    story.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (story.isInspiring)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.orange[600], size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'Inspiring',
                          style: TextStyle(
                            color: Colors.orange[600],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Author and date
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  story.isAnonymous ? 'Anonymous Survivor' : story.authorName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    story.category,
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Excerpt
            Text(
              story.excerpt,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: Colors.grey[700],
              ),
            ),

            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onRead,
                    icon: const Icon(Icons.auto_stories),
                    label: const Text('Read Story'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onLike,
                  icon: const Icon(Icons.favorite_border),
                  label: Text('${story.likes}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryDetailSheet extends StatelessWidget {
  final SuccessStory story;

  const _StoryDetailSheet({required this.story});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      story.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (story.isInspiring)
                    Icon(Icons.auto_awesome, color: Colors.orange[600]),
                ],
              ),

              const SizedBox(height: 8),

              // Author and category
              Row(
                children: [
                  Text(
                    story.isAnonymous ? 'Anonymous Survivor' : story.authorName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('•', style: TextStyle(color: Colors.grey[500])),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      story.category,
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(
                    story.content,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.8,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Thank you for your support!'),
                            backgroundColor: Colors.pink,
                          ),
                        );
                      },
                      icon: const Icon(Icons.favorite_border),
                      label: Text('${story.likes} people found this inspiring'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}