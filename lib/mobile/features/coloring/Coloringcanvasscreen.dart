import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'Coloringitem.dart';

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
  static const Color primaryBlue = Color(0xFF0F92CA);
  static const Color textDark = Color(0xFF213238);

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

    final byteData =
    await image.toByteData(format: ui.ImageByteFormat.rawRgba);
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

    final fillR = fill.red, fillG = fill.green, fillB = fill.blue;

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
      while (xl - 1 >= 0 && matches(xl - 1, y)) xl--;
      int xr = x;
      while (xr + 1 < w && matches(xr + 1, y)) xr++;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            const SizedBox(height: 4),
            Expanded(child: _buildCanvasArea()),
            _buildPalette(),
          ],
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
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.item.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),
          ),
          _RoundIconButton(
            icon: Icons.undo_rounded,
            onTap: _undo,
            enabled: _undoStack.isNotEmpty,
          ),
          const SizedBox(width: 8),
          _RoundIconButton(
            icon: Icons.redo_rounded,
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
      return const Center(
        child: CircularProgressIndicator(color: primaryBlue),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
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
                    final x =
                    (details.localPosition.dx * scaleX).clamp(0, _imgWidth - 1).toInt();
                    final y =
                    (details.localPosition.dy * scaleY).clamp(0, _imgHeight - 1).toInt();
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
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _palette.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final color = _palette[index];
            final selected = color == _selectedColor;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: selected ? 44 : 36,
                height: selected ? 44 : 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: selected ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(selected ? 0.45 : 0.25),
                      blurRadius: selected ? 10 : 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
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
    canvas.drawImageRect(image, src, dst, Paint()..filterQuality = FilterQuality.low);
  }

  @override
  bool shouldRepaint(covariant _ImagePainter oldDelegate) =>
      oldDelegate.image != image;
}

/// Small round icon button reused for back / undo / redo / reset actions.
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final Color? color;

  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.enabled = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 20,
              color: color ?? _ColoringCanvasScreenState.primaryBlue,
            ),
          ),
        ),
      ),
    );
  }
}