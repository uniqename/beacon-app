import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class DevotionalVideo {
  final String id;
  final String title;
  final String speaker;
  final String description;
  final String duration;
  final String videoUrl;
  final Color thumbnailColor;
  final String date;
  final String category;

  const DevotionalVideo({
    required this.id,
    required this.title,
    required this.speaker,
    required this.description,
    required this.duration,
    required this.videoUrl,
    required this.thumbnailColor,
    required this.date,
    required this.category,
  });
}

// ---------------------------------------------------------------------------
// Sample data
// ---------------------------------------------------------------------------

const List<DevotionalVideo> _devotionals = [
  DevotionalVideo(
    id: 'dv001',
    title: 'Finding Strength in Weakness',
    speaker: 'Pastor Emmanuel',
    description:
        'A powerful message about discovering God\'s strength when we feel at our weakest. '
        'Learn how vulnerability opens the door to divine power and healing.',
    duration: '4 min',
    videoUrl: '',
    thumbnailColor: Color(0xFF7B2D8B),
    date: 'March 2026',
    category: 'Healing',
  ),
  DevotionalVideo(
    id: 'dv002',
    title: 'Walking in Your New Beginning',
    speaker: 'Sister Grace',
    description:
        'Every step forward is a step into the life God has prepared for you. '
        'This devotional walks you through embracing a fresh start with faith and courage.',
    duration: '7 min',
    videoUrl: '',
    thumbnailColor: Color(0xFF00D4AA),
    date: 'March 2026',
    category: 'New Beginnings',
  ),
  DevotionalVideo(
    id: 'dv003',
    title: 'You Are Not Alone',
    speaker: 'Rev. Dr. Ama Mensah',
    description:
        'In your darkest moments, there is One who walks beside you. '
        'This message brings comfort to those who feel isolated and forgotten.',
    duration: '5 min',
    videoUrl: '',
    thumbnailColor: Color(0xFF1A6B9A),
    date: 'March 2026',
    category: 'Support',
  ),
  DevotionalVideo(
    id: 'dv004',
    title: 'Restoring Your Identity',
    speaker: 'Pastor Daniel',
    description:
        'Trauma can strip away your sense of self. Discover how God restores your true '
        'identity — beloved, worthy, and whole — beyond what others have done to you.',
    duration: '8 min',
    videoUrl: '',
    thumbnailColor: Color(0xFFFFB347),
    date: 'March 2026',
    category: 'Identity',
  ),
  DevotionalVideo(
    id: 'dv005',
    title: 'The Power of Forgiveness',
    speaker: 'Sister Abena',
    description:
        'Forgiveness is not condoning what happened — it is releasing yourself from the '
        'prison of bitterness. A gentle, honest exploration of healing through letting go.',
    duration: '6 min',
    videoUrl: '',
    thumbnailColor: Color(0xFFE74C6F),
    date: 'March 2026',
    category: 'Healing',
  ),
  DevotionalVideo(
    id: 'dv006',
    title: 'From Victim to Victor',
    speaker: 'Guest Speaker',
    description:
        'Your story does not end where the pain began. This empowering message calls you '
        'to rise above your circumstances and walk boldly into the victory prepared for you.',
    duration: '10 min',
    videoUrl: '',
    thumbnailColor: Color(0xFF2ECC71),
    date: 'March 2026',
    category: 'Empowerment',
  ),
];

// ---------------------------------------------------------------------------
// Color constants
// ---------------------------------------------------------------------------

const Color _bgColor = Color(0xFF0A0E1A);
const Color _cardColor = Color(0xFF141929);
const Color _accentColor = Color(0xFF00D4AA);
const Color _goldColor = Color(0xFFFFB347);

// ---------------------------------------------------------------------------
// VideoListScreen (main screen)
// ---------------------------------------------------------------------------

class VideoListScreen extends StatelessWidget {
  const VideoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        elevation: 0,
        title: const Text(
          'Video Devotionals',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: _accentColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      body: Column(
        children: [
          // Header banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _accentColor.withValues(alpha: 0.15),
                  _bgColor,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.play_circle_outline,
                    color: _accentColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Spirit-filled Messages',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_devotionals.length} devotionals available',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: _devotionals.length,
              itemBuilder: (context, index) {
                final d = _devotionals[index];
                return _DevotionalCard(
                  devotional: d,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _VideoPlayerScreen(devotional: d),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Devotional card
// ---------------------------------------------------------------------------

class _DevotionalCard extends StatelessWidget {
  final DevotionalVideo devotional;
  final VoidCallback onTap;

  const _DevotionalCard({required this.devotional, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colored left accent bar
            Container(
              width: 5,
              height: double.infinity,
              constraints: const BoxConstraints(minHeight: 110),
              decoration: BoxDecoration(
                color: devotional.thumbnailColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            devotional.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Duration badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _goldColor.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _goldColor.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            devotional.duration,
                            style: const TextStyle(
                              color: _goldColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // Speaker
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 13,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          devotional.speaker,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Description
                    Text(
                      devotional.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Bottom row: category chip + play hint
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: devotional.thumbnailColor
                                .withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            devotional.category,
                            style: TextStyle(
                              color: devotional.thumbnailColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.play_circle_fill,
                          color: _accentColor.withValues(alpha: 0.8),
                          size: 22,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Watch',
                          style: TextStyle(
                            color: _accentColor.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _VideoPlayerScreen (private StatefulWidget)
// ---------------------------------------------------------------------------

class _VideoPlayerScreen extends StatefulWidget {
  final DevotionalVideo devotional;

  const _VideoPlayerScreen({required this.devotional});

  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    if (widget.devotional.videoUrl.isNotEmpty) {
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.devotional.videoUrl),
    );

    _controller!.addListener(_onPlayerUpdate);

    await _controller!.initialize();

    if (mounted) {
      setState(() {
        _isInitialized = true;
        _duration = _controller!.value.duration;
      });
    }
  }

  void _onPlayerUpdate() {
    if (!mounted) return;
    setState(() {
      _isPlaying = _controller!.value.isPlaying;
      _position = _controller!.value.position;
      _duration = _controller!.value.duration;
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _controller?.removeListener(_onPlayerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    if (_isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
  }

  Widget _buildComingSoonPlaceholder() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.devotional.thumbnailColor.withValues(alpha: 0.7),
            widget.devotional.thumbnailColor.withValues(alpha: 0.25),
            _cardColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 52,
            color: Colors.white.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 14),
          const Text(
            'Coming Soon',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Video content will be available soon.\nCheck back after the next app update.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (!_isInitialized) {
      return Container(
        width: double.infinity,
        height: 220,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: _accentColor),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),

          // Controls bar
          Container(
            color: const Color(0xFF0D0D0D),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                // Progress indicator
                VideoProgressIndicator(
                  _controller!,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: _accentColor,
                    bufferedColor: Color(0xFF3A3A3A),
                    backgroundColor: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 6),

                // Time + play/pause row
                Row(
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: _accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDuration(_duration),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.devotional;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          d.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video area or coming soon placeholder
            d.videoUrl.isEmpty
                ? _buildComingSoonPlaceholder()
                : _buildVideoPlayer(),

            // Details section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: d.thumbnailColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      d.category,
                      style: TextStyle(
                        color: d.thumbnailColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Title
                  Text(
                    d.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Speaker + duration row
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 16,
                        color: _accentColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        d.speaker,
                        style: const TextStyle(
                          color: _accentColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.access_time,
                        size: 15,
                        color: _goldColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        d.duration,
                        style: const TextStyle(
                          color: _goldColor,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        d.date,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Divider
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),

                  const SizedBox(height: 18),

                  // Description heading
                  const Text(
                    'About This Message',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Description body
                  Text(
                    d.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      height: 1.65,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Encouragement card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _accentColor.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.favorite_outline,
                          color: _accentColor,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You are seen, you are loved, and you are not alone on this journey.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
