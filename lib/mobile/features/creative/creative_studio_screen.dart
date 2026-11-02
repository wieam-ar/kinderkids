import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_ui.dart';
import '../../data/providers/progress_provider.dart';
import '../draw/draw_screen.dart';
import '../draw/paint_screen.dart';
import 'artwork_gallery_screen.dart';

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
    colors: const [Color(0xFFB48CF2), AppColors.purple],
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Creative Studio 🎨',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          'Draw, color and save your artwork!',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'My Gallery',
                    onPressed: () =>
                        _open(context, (_) => const ArtworkGalleryScreen()),
                    icon: const Icon(
                      Icons.photo_library_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const _GallerySummary(),
              const SizedBox(height: 22),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: _studioItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, i) {
                    final item = _studioItems[i];
                    return FadeSlideIn(
                      index: i,
                      child: _StudioTile(
                        item: item,
                        onTap: () => _open(context, item.builder),
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

class _GallerySummary extends StatelessWidget {
  const _GallerySummary();

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

    return SoftCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Text('🖼️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          StarsChip(stars: stars),
        ],
      ),
    );
  }
}

class _StudioTile extends StatelessWidget {
  final _StudioItem item;
  final VoidCallback onTap;

  const _StudioTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      colors: item.colors,
      padding: const EdgeInsets.all(20),
      onTap: onTap,
      child: Row(
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 44)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white,
            size: 18,
          ),
        ],
      ),
    );
  }
}