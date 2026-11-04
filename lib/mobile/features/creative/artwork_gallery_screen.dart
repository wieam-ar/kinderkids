import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_ui.dart';
import '../../core/ui/kid_ui.dart';
import '../../data/providers/progress_provider.dart';

TextStyle _fredoka({
  double size = 15,
  Color color = KidColors.textDark,
  FontWeight weight = FontWeight.w700,
  double? height,
}) =>
    GoogleFonts.fredoka(
        fontSize: size, fontWeight: weight, color: color, height: height);

const Color _purple = Color(0xFF8B5CF6);
const Color _danger = Color(0xFFFF6B5E);

/// Accent colours cycled around the drawing frames.
const List<Color> _frameAccents = [
  Color(0xFF4FC3F7),
  Color(0xFFFFB74D),
  Color(0xFF81C784),
  Color(0xFFBA68C8),
  Color(0xFFF06292),
  Color(0xFFFFD54F),
];

class ArtworkGalleryScreen extends StatelessWidget {
  const ArtworkGalleryScreen({super.key});

  Future<void> _confirmDelete(
      BuildContext context,
      ProgressProvider progress,
      String path,
      ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: BoxDecoration(
            color: KidColors.cream,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _danger, width: 4),
            boxShadow: [
              BoxShadow(
                color: _danger.withOpacity(0.5),
                offset: const Offset(0, 8),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🗑️', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text('Delete this drawing?',
                  textAlign: TextAlign.center,
                  style: _fredoka(size: 20, weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text("You won't be able to get it back.",
                  textAlign: TextAlign.center,
                  style: _fredoka(
                      size: 14,
                      color: KidColors.textMuted,
                      weight: FontWeight.w500)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _ChunkyButton(
                      label: 'Keep it',
                      color: KidColors.green,
                      onTap: () => Navigator.of(dialogCtx).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ChunkyButton(
                      label: 'Delete',
                      color: _danger,
                      onTap: () => Navigator.of(dialogCtx).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true) return;

    await progress.removeArtwork(path);
    showAppSnack(messenger, '🗑️ Drawing deleted');
  }

  void _openViewer(BuildContext context, String path, int number) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ArtworkViewer(path: path, number: number),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final savedPaths = progress.profile.savedArtworkPaths;

    return Scaffold(
      body: KidBackground(
        colors: const [Color(0xFFE9DEFC), KidColors.cream],
        child: SafeArea(
          child: Column(
            children: [
              const KidHeader(
                title: 'My Gallery',
                emoji: '🖼️',
                subtitle: 'All your saved drawings',
              ),
              Expanded(
                child: savedPaths.isEmpty
                    ? const EmptyState(
                  emoji: '🎨',
                  title: 'No saved drawings yet!',
                  message:
                  'Go to Creative Studio and draw something awesome!',
                )
                    : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                  itemCount: savedPaths.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.88,
                  ),
                  itemBuilder: (context, index) {
                    final path = savedPaths[index];
                    return _ArtworkCard(
                      path: path,
                      number: index + 1,
                      accent:
                      _frameAccents[index % _frameAccents.length],
                      onOpen: () =>
                          _openViewer(context, path, index + 1),
                      onDelete: () =>
                          _confirmDelete(context, progress, path),
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

/// Shows the saved image when it can be read, otherwise a brush placeholder.
Widget _artworkImage(String path, {BoxFit fit = BoxFit.cover, int? cacheWidth}) {
  final placeholder = Center(
    child: Icon(Icons.brush_rounded, size: 48, color: Colors.blue.shade300),
  );
  if (kIsWeb) return placeholder;
  return Image.file(
    File(path),
    fit: fit,
    cacheWidth: cacheWidth,
    errorBuilder: (_, __, ___) => placeholder,
  );
}

class _ArtworkCard extends StatefulWidget {
  final String path;
  final int number;
  final Color accent;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _ArtworkCard({
    required this.path,
    required this.number,
    required this.accent,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  State<_ArtworkCard> createState() => _ArtworkCardState();
}

class _ArtworkCardState extends State<_ArtworkCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const depth = 6.0;
    final accent = widget.accent;
    final offset = _down ? 2.0 : depth;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onOpen,
      child: Padding(
        padding: const EdgeInsets.only(bottom: depth),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          transform: Matrix4.translationValues(0, depth - offset, 0),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: accent.withOpacity(0.6), width: 3),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.55),
                offset: Offset(0, offset),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: KidColors.lighten(accent, 0.45)),
                      Hero(
                        tag: widget.path,
                        child: _artworkImage(widget.path, cacheWidth: 500),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: widget.onDelete,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: _danger, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: _danger.withOpacity(0.5),
                                  offset: const Offset(0, 3),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.delete_rounded,
                                color: _danger, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Drawing #${widget.number}',
                style: _fredoka(
                    size: 14,
                    color: KidColors.darken(accent),
                    weight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ viewer

class _ArtworkViewer extends StatelessWidget {
  final String path;
  final int number;

  const _ArtworkViewer({required this.path, required this.number});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14121F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14121F),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text('Drawing #$number',
            style: _fredoka(size: 20, color: Colors.white, weight: FontWeight.w800)),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Hero(
            tag: path,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _artworkImage(path, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- button

class _ChunkyButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ChunkyButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<_ChunkyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const depth = 5.0;
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
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: KidColors.darken(widget.color),
                offset: Offset(0, offset),
                blurRadius: 0,
              ),
            ],
          ),
          child: Text(widget.label,
              style: _fredoka(
                  size: 15, color: Colors.white, weight: FontWeight.w800)),
        ),
      ),
    );
  }
}