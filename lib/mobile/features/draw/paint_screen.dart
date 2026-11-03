import 'package:flutter/material.dart';

import '../coloring/coloring_canvas_screen.dart';
import '../coloring/coloring_item.dart';
import '../science/fun_common.dart';

/// "Let's Color!" picker: cards pop in one after another, float gently,
/// and zoom into the canvas. English / Français / العربية.
class PaintScreen extends StatefulWidget {
  const PaintScreen({super.key});

  @override
  State<PaintScreen> createState() => _PaintScreenState();
}

class _PaintScreenState extends State<PaintScreen> with FunLang<PaintScreen> {
  static const Color textDark = Color(0xFF213238);
  static const Color textMuted = Color(0xFF7C8C93);

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
        backgroundColor: const Color(0xFFF6F9FB),
        body: Stack(
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
                  _buildTopBar(context),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                        childAspectRatio: 0.92,
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
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          FunRoundButton(
            icon: Icons.arrow_back_rounded,
            color: textDark,
            tooltip: tr('back'),
            onTap: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Column(
              children: [
                FunBounce(
                  amplitude: 3,
                  child: Text(
                    '${tr('paint_title')} 🎨',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                    ),
                  ),
                ),
                Text(
                  tr('paint_sub'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 42), // balances the back button
        ],
      ),
    );
  }
}

class _ColoringPickerCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return FunPressable(
      onTap: onTap,
      pressedScale: 0.94,
      child: Container(
        decoration: BoxDecoration(
          color: item.bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: item.accentColor.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(10),
                  width: double.infinity,
                  child: FunBounce(
                    amplitude: 4,
                    seconds: 2.4,
                    phase: (index * 0.17) % 1.0,
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
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: item.accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}