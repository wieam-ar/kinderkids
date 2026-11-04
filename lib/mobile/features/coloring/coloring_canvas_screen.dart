import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';

import '../../core/ui/kid_ui.dart';
import 'coloring_item.dart';

TextStyle _fredoka({
  double size = 15,
  Color color = KidColors.textDark,
  FontWeight weight = FontWeight.w700,
}) =>
    GoogleFonts.fredoka(fontSize: size, fontWeight: weight, color: color);

/// Bucket-fill coloring page. Tap anywhere inside the outline artwork and
/// the enclosed region under your finger fills with the selected color —
/// the dark outline itself always stays put and blocks the fill.
class ColoringCanvasScreen extends StatefulWidget {
  final ColoringItem item;
  const ColoringCanvasScreen({super.key, required this.item});

  @override
  State<ColoringCanvasScreen> createState() => _ColoringCanvasScreenState();
}

class _ColoringCanvasScreenState extends State<ColoringCanvasScreen> {
  static const List<Color> _palette = [
    Color(0xFFE0507B),
    Color(0xFFFFC542),
    Color(0xFF35B24A),
    Color(0xFF3AAAE0),
    Color(0xFF3B4CCA),
    Color(0xFFE0247A),
    Color(0xFFF2994A),
    Color(0xFF2FBF8F),
    Color(0xFF8B5CF6),
    Color(0xFF8D5A3C),
  ];

  // Pixels stored as RGBA, 4 bytes/pixel, mutable.
  Uint8List? _pixels;
  Uint8List? _originalPixels;
  int _imgWidth = 0;
  int _imgHeight = 0;

  ui.Image? _displayImage; // decoded from _pixels, redrawn after each fill
  final List<Uint8List> _undoStack = [];
  final List<Uint8List> _redoStack = [];

  Color _selectedColor = _palette[3];
  bool _loading = true;
  bool _busy = false; // true while flood-filling, to ignore extra taps

  static const int _colorTolerance = 40; // 0-441, higher = fills more shades

  Color get _accent => widget.item.accentColor;

  @override
  void initState() {
    super.initState();
    _loadArtwork();
  }

  Future<void> _loadArtwork() async {
    final data = await rootBundle.load(widget.item.assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final pixels = Uint8List.fromList(byteData!.buffer.asUint8List());

    setState(() {
      _imgWidth = image.width;
      _imgHeight = image.height;
      _pixels = pixels;
      _originalPixels = Uint8List.fromList(pixels);
      _displayImage = image;
      _loading = false;
    });
  }

  Future<ui.Image> _decodeImage(Uint8List pixels, int w, int h) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      w,
      h,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  int _pixelIndex(int x, int y) => (y * _imgWidth + x) * 4;

  bool _colorsMatch(Uint8List px, int idxA, int r, int g, int b) {
    final dr = px[idxA] - r;
    final dg = px[idxA + 1] - g;
    final db = px[idxA + 2] - b;
    return (dr * dr + dg * dg + db * db) <= _colorTolerance * _colorTolerance;
  }

  /// Scanline stack-based flood fill — fast enough to run on the main
  /// isolate for typical coloring-book image sizes (a few hundred px).
  void _floodFill(Uint8List px, int startX, int startY, Color fill) {
    final w = _imgWidth, h = _imgHeight;
    final startIdx = _pixelIndex(startX, startY);
    final targetR = px[startIdx];
    final targetG = px[startIdx + 1];
    final targetB = px[startIdx + 2];

    final fillR = (fill.r * 255).round().clamp(0, 255);
    final fillG = (fill.g * 255).round().clamp(0, 255);
    final fillB = (fill.b * 255).round().clamp(0, 255);

    // Already this color, or the tap landed on a dark outline: do nothing.
    if (_colorsMatch(px, startIdx, fillR, fillG, fillB)) return;
    final luminance = 0.299 * targetR + 0.587 * targetG + 0.114 * targetB;
    if (luminance < 60) return; // treat dark lines as walls, never fillable

    bool matches(int x, int y) {
      final idx = _pixelIndex(x, y);
      return _colorsMatch(px, idx, targetR, targetG, targetB);
    }

    void setColor(int x, int y) {
      final idx = _pixelIndex(x, y);
      px[idx] = fillR;
      px[idx + 1] = fillG;
      px[idx + 2] = fillB;
      px[idx + 3] = 255;
    }

    final stack = <List<int>>[
      [startX, startY]
    ];

    while (stack.isNotEmpty) {
      final p = stack.removeLast();
      int x = p[0], y = p[1];
      if (x < 0 || x >= w || y < 0 || y >= h) continue;
      if (!matches(x, y)) continue;

      // Walk left/right to find the extent of this matching scanline span.
      int xl = x;
      while (xl - 1 >= 0 && matches(xl - 1, y)) {
        xl--;
      }
      int xr = x;
      while (xr + 1 < w && matches(xr + 1, y)) {
        xr++;
      }

      bool spanAbove = false;
      bool spanBelow = false;
      for (int i = xl; i <= xr; i++) {
        setColor(i, y);

        if (y > 0) {
          final above = matches(i, y - 1);
          if (above && !spanAbove) {
            stack.add([i, y - 1]);
            spanAbove = true;
          } else if (!above) {
            spanAbove = false;
          }
        }
        if (y < h - 1) {
          final below = matches(i, y + 1);
          if (below && !spanBelow) {
            stack.add([i, y + 1]);
            spanBelow = true;
          } else if (!below) {
            spanBelow = false;
          }
        }
      }
    }
  }

  Future<void> _handleTapAtImageCoords(int x, int y) async {
    if (_pixels == null || _busy) return;
    setState(() => _busy = true);

    // Snapshot for undo before mutating.
    _undoStack.add(Uint8List.fromList(_pixels!));
    _redoStack.clear();

    _floodFill(_pixels!, x, y, _selectedColor);
    final newImage = await _decodeImage(_pixels!, _imgWidth, _imgHeight);

    if (!mounted) return;
    setState(() {
      _displayImage = newImage;
      _busy = false;
    });
  }

  Future<void> _restoreFrom(Uint8List snapshot) async {
    final image = await _decodeImage(snapshot, _imgWidth, _imgHeight);
    if (!mounted) return;
    setState(() => _displayImage = image);
  }

  Future<void> _undo() async {
    if (_undoStack.isEmpty || _pixels == null) return;
    _redoStack.add(Uint8List.fromList(_pixels!));
    final previous = _undoStack.removeLast();
    _pixels = Uint8List.fromList(previous);
    await _restoreFrom(_pixels!);
  }

  Future<void> _redo() async {
    if (_redoStack.isEmpty || _pixels == null) return;
    _undoStack.add(Uint8List.fromList(_pixels!));
    final next = _redoStack.removeLast();
    _pixels = Uint8List.fromList(next);
    await _restoreFrom(_pixels!);
  }

  Future<void> _reset() async {
    if (_originalPixels == null) return;
    _undoStack.add(Uint8List.fromList(_pixels!));
    _redoStack.clear();
    _pixels = Uint8List.fromList(_originalPixels!);
    await _restoreFrom(_pixels!);
  }

  // ---- UI ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KidBackground(
        colors: [widget.item.bgColor, KidColors.cream],
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 4),
              Expanded(child: _buildCanvasArea()),
              _buildPalette(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          _RoundIconButton(
            icon: Icons.arrow_back_rounded,
            color: KidColors.textDark,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.item.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _fredoka(size: 22, weight: FontWeight.w800),
            ),
          ),
          _RoundIconButton(
            icon: Icons.undo_rounded,
            color: _accent,
            onTap: _undo,
            enabled: _undoStack.isNotEmpty,
          ),
          const SizedBox(width: 8),
          _RoundIconButton(
            icon: Icons.redo_rounded,
            color: _accent,
            onTap: _redo,
            enabled: _redoStack.isNotEmpty,
          ),
          const SizedBox(width: 8),
          _RoundIconButton(
            icon: Icons.replay_rounded,
            onTap: _reset,
            color: const Color(0xFFE0507B),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasArea() {
    if (_loading || _displayImage == null) {
      return Center(
        child: CircularProgressIndicator(color: _accent, strokeWidth: 5),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _accent.withOpacity(0.8), width: 4),
          boxShadow: [
            BoxShadow(
              color: _accent.withOpacity(0.5),
              offset: const Offset(0, 6),
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: AspectRatio(
            aspectRatio: _imgWidth / _imgHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapUp: (details) {
                    final scaleX = _imgWidth / constraints.maxWidth;
                    final scaleY = _imgHeight / constraints.maxHeight;
                    final x = (details.localPosition.dx * scaleX)
                        .clamp(0, _imgWidth - 1)
                        .toInt();
                    final y = (details.localPosition.dy * scaleY)
                        .clamp(0, _imgHeight - 1)
                        .toInt();
                    _handleTapAtImageCoords(x, y);
                  },
                  child: CustomPaint(
                    painter: _ImagePainter(image: _displayImage!),
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPalette() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _accent.withOpacity(0.4), width: 3),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.4),
            offset: const Offset(0, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: SizedBox(
        height: 52,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _palette.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final color = _palette[index];
            final selected = color == _selectedColor;
            return Center(
              child: GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOutBack,
                  width: selected ? 46 : 36,
                  height: selected ? 46 : 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? KidColors.textDark : Colors.white,
                      width: selected ? 3.5 : 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: KidColors.darken(color),
                        offset: Offset(0, selected ? 4 : 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ImagePainter extends CustomPainter {
  final ui.Image image;
  _ImagePainter({required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    final src =
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(
        image, src, dst, Paint()..filterQuality = FilterQuality.low);
  }

  @override
  bool shouldRepaint(covariant _ImagePainter oldDelegate) =>
      oldDelegate.image != image;
}

/// Round 3D button reused for back / undo / redo / reset actions.
class _RoundIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final Color color;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    required this.color,
    this.enabled = true,
  });

  @override
  State<_RoundIconButton> createState() => _RoundIconButtonState();
}

class _RoundIconButtonState extends State<_RoundIconButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const depth = 4.0;
    final on = widget.enabled;
    final color = on ? widget.color : Colors.grey.shade300;
    final offset = (_down && on) ? 1.0 : depth;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: on ? (_) => setState(() => _down = true) : null,
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: on ? widget.onTap : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: depth),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          transform: Matrix4.translationValues(0, depth - offset, 0),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border:
            Border.all(color: Colors.white.withOpacity(0.6), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: on ? KidColors.darken(color) : Colors.grey.shade400,
                offset: Offset(0, offset),
                blurRadius: 0,
              ),
            ],
          ),
          child: Icon(widget.icon,
              color: on ? Colors.white : Colors.grey.shade500, size: 24),
        ),
      ),
    );
  }
}