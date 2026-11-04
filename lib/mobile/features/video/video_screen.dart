import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/ui/kid_ui.dart';
import '../../data/models/video/video.dart';
import 'video_player_screen.dart';

TextStyle _fredoka({
  double size = 15,
  Color color = KidColors.textDark,
  FontWeight weight = FontWeight.w700,
}) =>
    GoogleFonts.fredoka(fontSize: size, fontWeight: weight, color: color);

/// Videos activity: grid of big colourful cards.
/// Tapping a card opens [VideoPlayerScreen].
class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  /// videos watched (kept for this session)
  final Set<String> _watched = {};

  void _openVideo(VideoItem video) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoPlayerScreen(
          video: video,
          onWatched: () {
            if (mounted) setState(() => _watched.add(video.file));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final columns = width >= 600 ? 3 : 2;

    return Scaffold(
      body: KidBackground(
        colors: const [Color(0xFFE4DAFB), KidColors.cream],
        child: SafeArea(
          child: Column(
            children: [
              const KidHeader(
                title: 'Video Time',
                emoji: '🎬',
                subtitle: 'Pick a video to watch & learn',
              ),
              if (videoItems.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _WatchedPill(
                      watched: _watched.length,
                      total: videoItems.length,
                    ),
                  ),
                ),
              Expanded(
                child: videoItems.isEmpty
                    ? Center(
                  child: Text(
                    '🎞️\nNo videos yet',
                    textAlign: TextAlign.center,
                    style: _fredoka(
                      size: 20,
                      color: KidColors.textMuted,
                      weight: FontWeight.w700,
                    ),
                  ),
                )
                    : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                  itemCount: videoItems.length,
                  gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.82,
                  ),
                  itemBuilder: (context, index) {
                    final video = videoItems[index];
                    final delayIndex = index > 6 ? 6 : index;
                    return _AnimatedEntry(
                      delayMs: delayIndex * 80,
                      child: _VideoCard(
                        video: video,
                        watched: _watched.contains(video.file),
                        onTap: () => _openVideo(video),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------- watched pill

class _WatchedPill extends StatelessWidget {
  final int watched;
  final int total;
  const _WatchedPill({required this.watched, required this.total});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF35B24A);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: green.withOpacity(0.6), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: green.withOpacity(0.45),
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Text(
        '$watched/$total ✅',
        style: _fredoka(size: 14, weight: FontWeight.w800),
      ),
    );
  }
}

/// Fade + slide on entry, with a delay.
class _AnimatedEntry extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const _AnimatedEntry({required this.child, required this.delayMs});

  @override
  State<_AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<_AnimatedEntry> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.08),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// -------------------------------------------------------------- video card

class _VideoCard extends StatefulWidget {
  final VideoItem video;
  final bool watched;
  final VoidCallback onTap;

  const _VideoCard({
    required this.video,
    required this.watched,
    required this.onTap,
  });

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const depth = 7.0;
    final colors =
    widget.video.colors.map((c) => Color(c)).toList(growable: false);
    final gradient = colors.length > 1 ? colors : [colors.first, colors.first];
    final accent = colors.last;
    final offset = _down ? 2.0 : depth;

    return Semantics(
      button: true,
      label: 'Play ${widget.video.title}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.only(bottom: depth),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            transform: Matrix4.translationValues(0, depth - offset, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border:
              Border.all(color: Colors.white.withOpacity(0.6), width: 3),
              boxShadow: [
                BoxShadow(
                  color: KidColors.darken(accent),
                  offset: Offset(0, offset),
                  blurRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // emoji watermark
                  Positioned(
                    bottom: -18,
                    right: -14,
                    child: Text(
                      widget.video.emoji,
                      style: TextStyle(
                        fontSize: 90,
                        color: Colors.white.withOpacity(0.16),
                      ),
                    ),
                  ),
                  // big play button
                  Align(
                    alignment: const Alignment(0, -0.25),
                    child: Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            offset: const Offset(0, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: accent,
                        size: 42,
                      ),
                    ),
                  ),
                  // emoji badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.7), width: 2),
                      ),
                      child: Text(
                        widget.video.emoji,
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  // watched badge
                  if (widget.watched)
                    const Positioned(
                      top: 10,
                      right: 10,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.check_rounded,
                          color: Color(0xFF35B24A),
                          size: 22,
                        ),
                      ),
                    ),
                  // title / subtitle
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.video.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _fredoka(
                              size: 16.5,
                              color: Colors.white,
                              weight: FontWeight.w800),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          widget.video.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _fredoka(
                            size: 12.5,
                            color: Colors.white.withOpacity(0.92),
                            weight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}