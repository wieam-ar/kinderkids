import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/video/video.dart';
import 'video_player_screen.dart';

/// Videos activity: grid dyal cards kbar w mlawnin.
/// Tap 3la card kay7el [VideoPlayerScreen].
class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  static const Color bgTop = Color(0xFFF8F9FC);
  static const Color bgBottom = Color(0xFFDBEEF6);
  static const Color textDark = Color(0xFF213238);
  static const Color textMuted = Color(0xFF7C8C93);

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  /// videos li tchafo (tsjjlo f session)
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [VideosScreen.bgTop, VideosScreen.bgBottom],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -40,
              child: _GlowBlob(color: const Color(0xFF7B61FF), size: 220),
            ),
            Positioned(
              bottom: -80,
              left: -60,
              child: _GlowBlob(color: const Color(0xFFE0507B), size: 240),
            ),
            SafeArea(
              child: Column(
                children: [
                  // --- Top bar ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 20, 0),
                    child: Row(
                      children: [
                        _BackButton(onTap: () => Navigator.of(context).pop()),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            '🎬 Video Time',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: VideosScreen.textDark,
                            ),
                          ),
                        ),
                        if (videoItems.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_watched.length}/${videoItems.length} ✅',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: VideosScreen.textDark,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Pick a video to watch & learn',
                        style: TextStyle(
                          fontSize: 15,
                          color: VideosScreen.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Grid ---
                  Expanded(
                    child: videoItems.isEmpty
                        ? const Center(
                      child: Text(
                        '🎞️\nNo videos yet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: VideosScreen.textMuted,
                        ),
                      ),
                    )
                        : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: videoItems.length,
                      gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.85,
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
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: Colors.black26,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: VideosScreen.textDark,
            ),
          ),
        ),
      ),
    );
  }
}

/// Fade + slide f dkhoul, b delay.
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
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors =
    widget.video.colors.map((c) => Color(c)).toList(growable: false);

    return Semantics(
      button: true,
      label: 'Play ${widget.video.title}',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.last.withOpacity(0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
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
                  // play button kbir
                  Align(
                    alignment: const Alignment(0, -0.3),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.7),
                          width: 1.6,
                        ),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                  // emoji badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.28),
                        borderRadius: BorderRadius.circular(14),
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
                      top: 12,
                      right: 12,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.check_rounded,
                          color: Color(0xFF35B24A),
                          size: 20,
                        ),
                      ),
                    ),
                  // title / subtitle
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.video.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.video.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.92),
                            fontWeight: FontWeight.w600,
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

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(0.35), color.withOpacity(0.0)],
          ),
        ),
      ),
    );
  }
}