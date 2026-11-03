import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../science/fun_common.dart';

/// Free-draw canvas: finger painting with sparkles, a rainbow brush,
/// undo/redo, a fading "clear" animation, in English / Français / العربية.
class DrawScreen extends StatefulWidget {
  const DrawScreen({super.key});

  @override
  State<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen>
    with TickerProviderStateMixin, FunLang<DrawScreen> {
  static const Color primaryBlue = Color(0xFF0F92CA);
  static const Color primaryBlueDark = Color(0xFF0B6E9B);
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
    Color(0xFFF2B5C4),
  ];

  static const List<Color> _rainbowColors = [
    Color(0xFFFF5252),
    Color(0xFFFFC542),
    Color(0xFF35B24A),
    Color(0xFF3AAAE0),
    Color(0xFF8B5CF6),
    Color(0xFFFF5252),
  ];

  final math.Random _rnd = math.Random();
  final List<_Stroke> _strokes = [];
  final List<_Stroke> _redoStack = [];
  _Stroke? _current;
  int? _pointer; // only one finger draws at a time

  Color _selectedColor = _palette[3];
  bool _rainbow = false;
  double _strokeWidth = 8;

  // Sparkle burst that follows the finger
  int _burst = 0;
  Offset _burstPos = Offset.zero;
  Color _burstColor = _palette[3];

  // "Clear" animation (the drawing fades away)
  late final AnimationController _clearC = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  bool _clearing = false;

  @override
  void dispose() {
    _clearC.dispose();
    super.dispose();
  }

  void _spark(Offset pos, Color color) {
    _burst++;
    _burstPos = pos;
    _burstColor = color;
  }

  // ---- Drawing (Listener so a single tap also draws a dot) ---------------

  void _onDown(PointerDownEvent e) {
    if (_pointer != null || _clearing) return;
    _pointer = e.pointer;
    final stroke = _Stroke(
      color: _selectedColor,
      width: _strokeWidth,
      rainbow: _rainbow,
      hue: _rnd.nextDouble() * 360,
      points: [e.localPosition],
    );
    setState(() {
      _current = stroke;
      _strokes.add(stroke);
      _redoStack.clear();
      _spark(e.localPosition, _rainbow ? Colors.pinkAccent : _selectedColor);
    });
    LabSfx.tap();
  }

  void _onMove(PointerMoveEvent e) {
    if (e.pointer != _pointer) return;
    setState(() => _current?.points.add(e.localPosition));
  }

  void _onUp(PointerEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    final s = _current;
    _current = null;
    if (s != null) {
      setState(() => _spark(s.points.last, s.rainbow ? Colors.amber : s.color));
    }
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    LabSfx.play('pop');
    LabSfx.tap();
    setState(() => _redoStack.add(_strokes.removeLast()));
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    LabSfx.play('pop');
    LabSfx.tap();
    setState(() => _strokes.add(_redoStack.removeLast()));
  }

  Future<void> _clear() async {
    if (_strokes.isEmpty || _clearing) return;
    _clearing = true;
    LabSfx.play('splash_big', volume: 0.7);
    LabSfx.soft();
    await _clearC.forward(from: 0);
    if (!mounted) return;
    setState(() {
      _redoStack.clear();
      _strokes.clear();
      _clearing = false;
    });
    _clearC.value = 0;
  }

  void _pickColor(Color c) {
    LabSfx.play('pop', volume: 0.7);
    LabSfx.tap();
    setState(() {
      _selectedColor = c;
      _rainbow = false;
    });
  }

  void _pickRainbow() {
    LabSfx.play('twinkle', volume: 0.8);
    LabSfx.tap();
    setState(() => _rainbow = true);
  }

  // ---- UI ----------------------------------------------------------------

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
                color: primaryBlue,
                emojis: ['✏️', '🖍️', '🎨', '⭐', '🌈'],
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
                  const SizedBox(height: 8),
                  Expanded(child: FunPopIn(delayMs: 60, child: _buildCanvas())),
                  FunPopIn(delayMs: 180, child: _buildBottomPanel()),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          FunRoundButton(
            icon: Icons.arrow_back_rounded,
            tooltip: tr('back'),
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FunBounce(
              amplitude: 3,
              child: Text(
                '${tr('draw_title')} ✏️',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
            ),
          ),
          FunRoundButton(
            icon: Icons.undo_rounded,
            tooltip: tr('undo'),
            onTap: _undo,
            enabled: _strokes.isNotEmpty && !_clearing,
          ),
          const SizedBox(width: 8),
          FunRoundButton(
            icon: Icons.redo_rounded,
            tooltip: tr('redo'),
            onTap: _redo,
            enabled: _redoStack.isNotEmpty && !_clearing,
          ),
        ],
      ),
    );
  }

  Widget _buildCanvas() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _onDown,
          onPointerMove: _onMove,
          onPointerUp: _onUp,
          onPointerCancel: _onUp,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedBuilder(
                animation: _clearC,
                builder: (context, _) => CustomPaint(
                  painter: _DrawingPainter(
                    strokes: _strokes,
                    opacity: 1 - Curves.easeIn.transform(_clearC.value),
                  ),
                  size: Size.infinite,
                ),
              ),
              // Hint that fades away when the child starts drawing
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 350),
                    opacity: _strokes.isEmpty ? 1 : 0,
                    child: Center(
                      child: FunBounce(
                        amplitude: 10,
                        seconds: 1.6,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🎨', style: TextStyle(fontSize: 54)),
                            const SizedBox(height: 6),
                            Text(
                              tr('draw_hint'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: textDark.withOpacity(0.35),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Sparkles
              Positioned(
                left: _burstPos.dx - 80,
                top: _burstPos.dy - 80,
                width: 160,
                height: 160,
                child: LabBurst(
                  trigger: _burst,
                  colors: [_burstColor, Colors.white, Colors.amber.shade300],
                  count: 9,
                  distance: 36,
                  gravity: 16,
                  size: 3.4,
                  duration: const Duration(milliseconds: 650),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    final previewColor = _selectedColor;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Live brush preview
              SizedBox(
                width: 30,
                height: 30,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    width: _strokeWidth.clamp(4.0, 28.0),
                    height: _strokeWidth.clamp(4.0, 28.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _rainbow ? null : previewColor,
                      gradient: _rainbow
                          ? const SweepGradient(colors: _rainbowColors)
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: primaryBlue,
                    inactiveTrackColor: primaryBlue.withOpacity(0.15),
                    thumbColor: primaryBlueDark,
                    overlayColor: primaryBlue.withOpacity(0.15),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    min: 3,
                    max: 26,
                    value: _strokeWidth,
                    onChanged: (v) => setState(() => _strokeWidth = v),
                  ),
                ),
              ),
              FunRoundButton(
                icon: Icons.delete_outline_rounded,
                tooltip: tr('clear'),
                onTap: _clear,
                enabled: _strokes.isNotEmpty && !_clearing,
                color: const Color(0xFFE0507B),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _palette.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final isRainbow = index == _palette.length;
                final selected = isRainbow
                    ? _rainbow
                    : (!_rainbow && _palette[index] == _selectedColor);
                final size = selected ? 42.0 : 34.0;
                final color = isRainbow ? Colors.pinkAccent : _palette[index];

                return FunPopIn(
                  delayMs: 40 * index,
                  // Center: the list gives a tight height, which would
                  // squash the dots into ovals.
                  child: Center(
                    child: Tooltip(
                      message: isRainbow ? tr('rainbow') : '',
                      child: FunPressable(
                        onTap: isRainbow
                            ? _pickRainbow
                            : () => _pickColor(_palette[index]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutBack,
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            color: isRainbow ? null : color,
                            gradient: isRainbow
                                ? const SweepGradient(colors: _rainbowColors)
                                : null,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: selected ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(selected ? 0.5 : 0.25),
                                blurRadius: selected ? 10 : 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: isRainbow
                              ? const Center(
                            child: Text('🌈',
                                style: TextStyle(fontSize: 16)),
                          )
                              : null,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Stroke {
  final Color color;
  final double width;
  final bool rainbow;
  final double hue;
  final List<Offset> points;

  _Stroke({
    required this.color,
    required this.width,
    required this.rainbow,
    required this.hue,
    required this.points,
  });

  Color rainbowAt(int i, double opacity) =>
      HSVColor.fromAHSV(opacity, (hue + i * 7) % 360, 0.85, 0.95).toColor();
}

class _DrawingPainter extends CustomPainter {
  final List<_Stroke> strokes;
  final double opacity;

  _DrawingPainter({required this.strokes, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final pts = stroke.points;
      if (pts.isEmpty) continue;

      final paint = Paint()
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      // A single tap: draw a dot.
      if (pts.length == 1) {
        final dot = Paint()
          ..color = stroke.rainbow
              ? stroke.rainbowAt(0, opacity)
              : stroke.color.withOpacity(opacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pts.first, stroke.width / 2, dot);
        continue;
      }

      if (stroke.rainbow) {
        for (var i = 1; i < pts.length; i++) {
          paint.color = stroke.rainbowAt(i, opacity);
          canvas.drawLine(pts[i - 1], pts[i], paint);
        }
        continue;
      }

      paint.color = stroke.color.withOpacity(opacity);
      // Smooth curve through the middle of each segment.
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length - 1; i++) {
        final mid = Offset(
          (pts[i].dx + pts[i + 1].dx) / 2,
          (pts[i].dy + pts[i + 1].dy) / 2,
        );
        path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
      }
      path.lineTo(pts.last.dx, pts.last.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}