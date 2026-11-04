import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/ui/kid_ui.dart';
import '../coloring/coloring_canvas_screen.dart';
import '../coloring/coloring_item.dart';
import '../science/fun_common.dart';

TextStyle _fredoka({
  double size = 15,
  Color color = KidColors.textDark,
  FontWeight weight = FontWeight.w700,
}) =>
    GoogleFonts.fredoka(fontSize: size, fontWeight: weight, color: color);

/// "Let's Color!" picker: cards pop in one after another, float gently,
/// and zoom into the canvas. English / Français / العربية.
class PaintScreen extends StatefulWidget {
  const PaintScreen({super.key});

  @override
  State<PaintScreen> createState() => _PaintScreenState();
}

class _PaintScreenState extends State<PaintScreen> with FunLang<PaintScreen> {
  @override
  void initState() {
    super.initState();
    LabSfx.preload();
  }

  /// Translated title of a picture (falls back to the original title).
  String _itemTitle(ColoringItem item) {
    var slug = item.title
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final key = 'ci_$slug';
    return funHas(key) ? tr(key) : item.title;
  }

  void _open(ColoringItem item) {
    LabSfx.play('pop');
    LabSfx.tap();
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => ColoringCanvasScreen(item: item),
        transitionsBuilder: (_, anim, __, child) {
          final c = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: c,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(c),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: dir,
      child: Scaffold(
        body: KidBackground(
          colors: const [Color(0xFFFFE0EC), KidColors.cream],
          child: Stack(
            children: [
              const Positioned.fill(
                child: LabBackdrop(
                  color: Colors.pink,
                  emojis: ['🎨', '🖍️', '🌈', '✏️', '🖌️'],
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    KidHeader(
                      title: tr('paint_title'),
                      emoji: '🎨',
                      subtitle: tr('paint_sub'),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 6, 16, 0),
                      child: LabLangBar(),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: kColoringItems.length,
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.88,
                        ),
                        itemBuilder: (context, index) {
                          final item = kColoringItems[index];
                          return FunPopIn(
                            delayMs: index < 8 ? index * 70 : 0,
                            child: _ColoringPickerCard(
                              item: item,
                              title: _itemTitle(item),
                              index: index,
                              onTap: () => _open(item),
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
      ),
    );
  }
}

class _ColoringPickerCard extends StatefulWidget {
  final ColoringItem item;
  final String title;
  final int index;
  final VoidCallback onTap;

  const _ColoringPickerCard({
    required this.item,
    required this.title,
    required this.index,
    required this.onTap,
  });

  @override
  State<_ColoringPickerCard> createState() => _ColoringPickerCardState();
}

class _ColoringPickerCardState extends State<_ColoringPickerCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const depth = 6.0;
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: item.bgColor,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
                color: item.accentColor.withOpacity(0.7), width: 3),
            boxShadow: [
              BoxShadow(
                color: item.accentColor.withOpacity(0.55),
                offset: Offset(0, offset),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: item.accentColor.withOpacity(0.25), width: 2),
                  ),
                  child: FunBounce(
                    amplitude: 4,
                    seconds: 2.4,
                    phase: (widget.index * 0.17) % 1.0,
                    child: Image.asset(
                      item.assetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.image_rounded,
                        color: item.accentColor.withOpacity(0.4),
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _fredoka(
                  size: 15,
                  color: item.accentColor,
                  weight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}