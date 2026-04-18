import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/app_config_service.dart';
import 'article_reader_screen.dart';

// ─── Data model ─────────────────────────────────────────────────────────────

class EducationalContent {
  final String id;
  final String title;
  final String category;
  final String duration;
  final String description;

  /// If set, tapping opens this URL in the browser instead of the article reader.
  final String? url;

  /// 'all' | 'gh' | 'us'  — which region(s) should see this item.
  final String region;

  bool isFavorite;

  EducationalContent({
    required this.id,
    required this.title,
    required this.category,
    required this.duration,
    required this.description,
    this.url,
    this.region = 'all',
    this.isFavorite = false,
  });
}

// ─── Content catalogue ───────────────────────────────────────────────────────

final List<EducationalContent> catalogue = [
  // ── Universal ──────────────────────────────────────────────────────────────
  EducationalContent(
    id: 'understanding_dv',
    title: 'Understanding Domestic Violence',
    category: 'Education',
    duration: '5 min read',
    description:
        'Learn about the different types of domestic violence and how to recognise warning signs in a relationship.',
  ),
  EducationalContent(
    id: 'safety_plan',
    title: 'Creating Your Safety Plan',
    category: 'Safety',
    duration: '8 min read',
    description:
        'Step-by-step guide to developing a comprehensive safety plan for you and your family.',
  ),
  EducationalContent(
    id: 'self_care_crisis',
    title: 'Self-Care During Crisis',
    category: 'Wellness',
    duration: '6 min read',
    description:
        'Practical strategies to protect your mental health and build resilience during difficult times.',
  ),
  EducationalContent(
    id: 'healing_trauma',
    title: 'Healing from Trauma',
    category: 'Wellness',
    duration: '7 min read',
    description:
        'Understanding trauma responses and evidence-based approaches to recovery and healing.',
  ),
  EducationalContent(
    id: 'financial_independence',
    title: 'Building Financial Independence',
    category: 'Financial',
    duration: '10 min read',
    description:
        'Practical steps to build financial security and economic independence after leaving an abusive situation.',
  ),
  EducationalContent(
    id: 'children_trauma',
    title: 'Supporting Children Through Trauma',
    category: 'Parenting',
    duration: '7 min read',
    description:
        'How to help your children cope and heal from exposure to domestic violence.',
  ),
  EducationalContent(
    id: 'cycle_of_abuse',
    title: 'Understanding the Cycle of Abuse',
    category: 'Education',
    duration: '5 min read',
    description:
        'Recognise the tension–explosion–honeymoon cycle and why leaving can be so difficult.',
  ),
  EducationalContent(
    id: 'healthy_relationships',
    title: 'What a Healthy Relationship Looks Like',
    category: 'Education',
    duration: '4 min read',
    description:
        'Equality, respect, communication, and boundaries — the foundations of a safe partnership.',
  ),

  // ── Ghana-only ─────────────────────────────────────────────────────────────
  EducationalContent(
    id: 'legal_rights_gh',
    title: 'Your Legal Rights — DV Act 732',
    category: 'Legal',
    duration: '10 min read',
    description:
        "Understand your rights under Ghana's Domestic Violence Act 732 (2007), including protection orders and criminal remedies.",
    region: 'gh',
  ),
  EducationalContent(
    id: 'dovvsu_guide',
    title: 'How DOVVSU Can Help You',
    category: 'Resources',
    duration: '4 min read',
    description:
        'A guide to the Domestic Violence and Victim Support Unit — what to expect, how to file a report, and what support is available at police stations across Ghana.',
    region: 'gh',
  ),
  EducationalContent(
    id: 'ark_foundation',
    title: 'Shelter & Support in Ghana',
    category: 'Resources',
    duration: '3 min read',
    description:
        'Organisations providing shelter, legal aid, and counselling in Ghana — Ark Foundation, Oasis Ghana, WiLDAF, and more.',
    region: 'gh',
  ),
  EducationalContent(
    id: 'customary_law_gh',
    title: 'Traditional Practices & Your Rights',
    category: 'Legal',
    duration: '6 min read',
    description:
        'How Ghanaian customary law intersects with national DV legislation, and your rights within both systems.',
    region: 'gh',
  ),

  // ── US-only ─────────────────────────────────────────────────────────────────
  EducationalContent(
    id: 'legal_rights_us',
    title: 'Your Legal Rights — VAWA & State Laws',
    category: 'Legal',
    duration: '10 min read',
    description:
        'Understand your rights under the Violence Against Women Act (VAWA) and how state DV statutes protect you.',
    region: 'us',
  ),
  EducationalContent(
    id: 'protective_orders_us',
    title: 'Protective Orders & Restraining Orders',
    category: 'Legal',
    duration: '8 min read',
    description:
        'How to obtain an emergency protective order, what it covers, and what happens if the order is violated.',
    region: 'us',
  ),
  EducationalContent(
    id: 'immigrant_rights_us',
    title: 'Immigrant Survivor Rights',
    category: 'Legal',
    duration: '9 min read',
    description:
        'VAWA self-petition, U visas, T visas — immigration protections available to survivors regardless of status.',
    region: 'us',
  ),
  EducationalContent(
    id: 'finding_shelter_us',
    title: 'Finding Shelter & Housing Support',
    category: 'Resources',
    duration: '5 min read',
    description:
        'How to locate an emergency shelter, transitional housing, and rental assistance programmes near you.',
    region: 'us',
  ),
  EducationalContent(
    id: 'national_dv_hotline',
    title: 'National DV Hotline — 1-800-799-7233',
    category: 'Resources',
    duration: 'Call or text',
    description:
        '24/7 confidential support from trained advocates. Call 1-800-799-7233, text START to 88788, or chat online at thehotline.org.',
    url: 'https://www.thehotline.org',
    region: 'us',
  ),
  EducationalContent(
    id: 'rainn_us',
    title: 'RAINN — Sexual Assault Support',
    category: 'Resources',
    duration: 'Call 1-800-656-HOPE',
    description:
        'RAINN operates the National Sexual Assault Hotline and connects survivors to local resources across the United States.',
    url: 'https://www.rainn.org',
    region: 'us',
  ),
  EducationalContent(
    id: 'safety_tech_us',
    title: 'Technology Safety & Digital Privacy',
    category: 'Safety',
    duration: '6 min read',
    description:
        'How abusers use technology to monitor survivors, and steps to protect your privacy on your phone and online accounts.',
    region: 'us',
  ),
];

// ─── Screen ──────────────────────────────────────────────────────────────────

class ContentLibraryScreen extends StatefulWidget {
  const ContentLibraryScreen({super.key});

  @override
  State<ContentLibraryScreen> createState() => _ContentLibraryScreenState();
}

class _ContentLibraryScreenState extends State<ContentLibraryScreen> {
  String _selectedCategory = 'All';

  List<EducationalContent> get _regionContent {
    final orgKey = AppConfigService.instance.config.orgKey;
    return catalogue
        .where((c) => c.region == 'all' || c.region == orgKey)
        .toList();
  }

  List<String> get _categories {
    final cats = <String>{'All'};
    for (final c in _regionContent) {
      cats.add(c.category);
    }
    return cats.toList();
  }

  List<EducationalContent> get _filtered {
    if (_selectedCategory == 'All') return _regionContent;
    return _regionContent
        .where((c) => c.category == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = AppConfigService.instance.config;
    final isUs = cfg.orgKey == 'us';
    final accentColor = isUs ? const Color(0xFF1E4D8C) : Colors.indigo[700]!;

    if (_categories.isNotEmpty &&
        !_categories.contains(_selectedCategory)) {
      _selectedCategory = 'All';
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Educational Content',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: accentColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Region banner
          Container(
            width: double.infinity,
            color: accentColor.withValues(alpha: 0.08),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text(isUs ? '🇺🇸' : '🇬🇭', style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isUs
                        ? 'Showing US resources & legal information'
                        : 'Showing Ghana resources & legal information',
                    style: TextStyle(
                        fontSize: 12,
                        color: accentColor,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Category chips
          SizedBox(
            height: 58,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat,
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                isSelected ? Colors.white : Colors.grey[700])),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = cat),
                    backgroundColor: Colors.white,
                    selectedColor: accentColor,
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                        color: isSelected
                            ? accentColor
                            : Colors.grey[300]!),
                  ),
                );
              },
            ),
          ),

          // Content list
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.article_outlined,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('No content in this category',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[500])),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) =>
                        _buildCard(_filtered[index], accentColor),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(EducationalContent content, Color accentColor) {
    final catColor = _catColor(content.category);
    final hasUrl = content.url != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () => _open(content),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      content.category,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: catColor),
                    ),
                  ),
                  if (hasUrl) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_in_new,
                              size: 10, color: Colors.blue[700]),
                          const SizedBox(width: 3),
                          Text('External link',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.blue[700])),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() {
                      content.isFavorite = !content.isFavorite;
                    }),
                    child: Icon(
                      content.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color:
                          content.isFavorite ? Colors.red : Colors.grey[400],
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                content.title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, height: 1.3),
              ),
              const SizedBox(height: 6),
              Text(
                content.description,
                style:
                    TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.45),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    hasUrl ? Icons.link : Icons.access_time,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(content.duration,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500])),
                  const Spacer(),
                  Text(
                    hasUrl ? 'Visit →' : 'Read →',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accentColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(EducationalContent content) async {
    if (content.url != null) {
      final uri = Uri.parse(content.url!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Could not open ${content.url}'),
                backgroundColor: Colors.red),
          );
        }
      }
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArticleReaderScreen(content: content),
      ),
    );
  }

  Color _catColor(String category) {
    switch (category) {
      case 'Education':
        return Colors.blue[700]!;
      case 'Safety':
        return Colors.red[700]!;
      case 'Legal':
        return Colors.purple[700]!;
      case 'Wellness':
        return Colors.green[700]!;
      case 'Financial':
        return Colors.orange[700]!;
      case 'Parenting':
        return Colors.pink[700]!;
      case 'Resources':
        return Colors.teal[700]!;
      default:
        return Colors.grey[600]!;
    }
  }
}
