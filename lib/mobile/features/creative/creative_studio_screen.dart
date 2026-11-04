import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_ui.dart';
import '../../core/ui/kid_ui.dart';
import '../../data/providers/progress_provider.dart';
import '../draw/draw_screen.dart';
import '../draw/paint_screen.dart';
import 'artwork_gallery_screen.dart';

TextStyle _fredoka({
  double size = 15,
  Color color = KidColors.textDark,
  FontWeight weight = FontWeight.w700,
}) =>
    GoogleFonts.fredoka(fontSize: size, fontWeight: weight, color: color);

const Color _purple = Color(0xFF8B5CF6);

class _StudioItem {
  final String title;
  final String subtitle;
  final String emoji;
  final List<Color> colors;
  final WidgetBuilder builder;

  const _StudioItem({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.colors,
    required this.builder,
  });
}

final List<_StudioItem> _studioItems = [
  _StudioItem(
    title: 'Freehand Draw',
    subtitle: 'Doodle with colorful brushes & eraser',
    emoji: '✏️',
    colors: const [Color(0xFF6FD3F7), Color(0xFF3AAAE0)],
    builder: (_) => const DrawScreen(),
  ),
  _StudioItem(
    title: 'Coloring Book',
    subtitle: 'Bucket fill outline pictures',
    emoji: '🎨',
    colors: const [Color(0xFFFF9D6C), Color(0xFFF25C54)],
    builder: (_) => const PaintScreen(),
  ),
  _StudioItem(
    title: 'My Gallery',
    subtitle: 'See all your saved drawings',
    emoji: '🖼️',
    colors: const [Color(0xFFB48CF2), _purple],
    builder: (_) => const ArtworkGalleryScreen(),
  ),
];

class CreativeStudioScreen extends StatelessWidget {
  const CreativeStudioScreen({super.key});

  void _open(BuildContext context, WidgetBuilder builder) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: builder));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KidBackground(
        colors: const [Color(0xFFFFE6D2), KidColors.cream],
        child: SafeArea(
          child: Column(
            children: [
              const KidHeader(
                title: 'Creative Studio',
                emoji: '🎨',
                subtitle: 'Draw, color and save your artwork!',
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                  children: [
                    _GallerySummary(
                      onOpenGallery: () => _open(
                          context, (_) => const ArtworkGalleryScreen()),
                    ),
                    const SizedBox(height: 20),
                    for (var i = 0; i < _studioItems.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FadeSlideIn(
                          index: i,
                          child: _StudioTile(
                            item: _studioItems[i],
                            onTap: () =>
                                _open(context, _studioItems[i].builder),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------- gallery summary

class _GallerySummary extends StatelessWidget {
  final VoidCallback onOpenGallery;
  const _GallerySummary({required this.onOpenGallery});

  @override
  Widget build(BuildContext context) {
    // Rebuild only when these two values change.
    final artworkCount = context.select<ProgressProvider, int>(
          (p) => p.profile.savedArtworkPaths.length,
    );
    final stars = context.select<ProgressProvider, int>(
          (p) => p.profile.totalStars,
    );

    final message = artworkCount == 0
        ? 'No artworks yet — start drawing!'
        : '$artworkCount saved artwork${artworkCount == 1 ? '' : 's'} '
        'in your gallery';

    const depth = 5.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: depth),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: _purple.withOpacity(0.35), width: 3),
          boxShadow: [
            BoxShadow(
              color: _purple.withOpacity(0.4),
              offset: const Offset(0, depth),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('🖼️', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: _fredoka(size: 13.5, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text('$stars',
                          style: _fredoka(
                              size: 14,
                              color: const Color(0xFFE09A00),
                              weight: FontWeight.w800)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'My Gallery',
              child: KidRoundButton(
                icon: Icons.photo_library_rounded,
                color: _purple,
                onTap: onOpenGallery,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- studio tile

class _StudioTile extends StatefulWidget {
  final _StudioItem item;
  final VoidCallback onTap;

  const _StudioTile({required this.item, required this.onTap});

  @override
  State<_StudioTile> createState() => _StudioTileState();
}

class _StudioTileState extends State<_StudioTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const depth = 7.0;
    final item = widget.item;
    final offset = _down ? 2.0 : depth;

    return GestureDetector(
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: item.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border:
            Border.all(color: Colors.white.withOpacity(0.55), width: 3),
            boxShadow: [
              BoxShadow(
                color: KidColors.darken(item.colors.last),
                offset: Offset(0, offset),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.28),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.7), width: 3),
                ),
                child: Text(item.emoji, style: const TextStyle(fontSize: 34)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: _fredoka(
                          size: 20,
                          color: Colors.white,
                          weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: _fredoka(
                          size: 12.5,
                          color: Colors.white.withOpacity(0.92),
                          weight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      offset: const Offset(0, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Icon(Icons.play_arrow_rounded,
                    color: item.colors.last, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}