import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/ui/kid_ui.dart';
import '../science/fun_common.dart';

TextStyle _fredoka({
  double size = 15,
  Color color = KidColors.textDark,
  FontWeight weight = FontWeight.w700,
}) =>
    GoogleFonts.fredoka(fontSize: size, fontWeight: weight, color: color);

/// Free-draw canvas: finger painting with sparkles, a rainbow brush,
/// undo/redo, a fading "clear" animation, in English / Français / العربية.
class DrawScreen extends StatefulWidget {
  const DrawScreen({super.key});

  @override
  State<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen>
    with TickerProviderStateMixin, FunLang<DrawScreen> {
  static const Color primaryBlue = Color(0xFF3AAAE0);
  static const Color clearRed = Color(0xFFE0507B);

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
        body: KidBackground(
          colors: const [Color(0xFFD6EEFB), KidColors.cream],
          child: Stack(
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
                    const SizedBox(height: 10),
                    Expanded(
                        child: FunPopIn(delayMs: 60, child: _buildCanvas())),
                    FunPopIn(delayMs: 180, child: _buildBottomPanel()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          _RoundBtn(
            icon: Icons.arrow_back_rounded,
            tooltip: tr('back'),
            color: const Color(0xFF213238),
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FunBounce(
              amplitude: 3,
              child: Text(
                '${tr('draw_title')} ✏️',
                textAlign: TextAlign.center,
                style: _fredoka(size: 22, weight: FontWeight.w800),
              ),
            ),
          ),
          _RoundBtn(
            icon: Icons.undo_rounded,
            tooltip: tr('undo'),
            color: primaryBlue,
            onTap: _undo,
            enabled: _strokes.isNotEmpty && !_clearing,
          ),
          const SizedBox(width: 8),
          _RoundBtn(
            icon: Icons.redo_rounded,
            tooltip: tr('redo'),
            color: primaryBlue,
            onTap: _redo,
            enabled: _redoStack.isNotEmpty && !_clearing,
          ),
        ],
      ),
    );
  }

  Widget _buildCanvas() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: primaryBlue.withOpacity(0.8), width: 4),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.5),
              offset: const Offset(0, 6),
              blurRadius: 0,
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
                              style: _fredoka(
                                size: 17,
                                weight: FontWeight.w800,
                                color: KidColors.textDark.withOpacity(0.35),
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
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: primaryBlue.withOpacity(0.4), width: 3),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.4),
            offset: const Offset(0, 5),
            blurRadius: 0,
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
                width: 34,
                height: 34,
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
              const SizedBox(width: 6),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 10,
                    trackShape: const RoundedRectSliderTrackShape(),
                    thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 10),
                    overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 18),
                    activeTrackColor: primaryBlue,
                    inactiveTrackColor: primaryBlue.withOpacity(0.2),
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    min: 3,
                    max: 26,
                    value: _strokeWidth,
                    onChanged: (v) => setState(() => _strokeWidth = v),
                  ),
                ),
              ),
              _RoundBtn(
                icon: Icons.delete_outline_rounded,
                tooltip: tr('clear'),
                onTap: _clear,
                enabled: _strokes.isNotEmpty && !_clearing,
                color: clearRed,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _palette.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final isRainbow = index == _palette.length;
                final selected = isRainbow
                    ? _rainbow
                    : (!_rainbow && _palette[index] == _selectedColor);
                final size = selected ? 46.0 : 36.0;
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
                              color: selected
                                  ? KidColors.textDark
                                  : Colors.white,
                              width: selected ? 3.5 : 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isRainbow
                                    ? Colors.pink.shade300
                                    : KidColors.darken(color),
                                offset: Offset(0, selected ? 4 : 3),
                                blurRadius: 0,
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

// ------------------------------------------------------------ round button

/// Round 3D button that sinks when pressed; greys out when disabled.
class _RoundBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  const _RoundBtn({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  @override
  State<_RoundBtn> createState() => _RoundBtnState();
}

class _RoundBtnState extends State<_RoundBtn> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const depth = 4.0;
    final on = widget.enabled;
    final color = on ? widget.color : Colors.grey.shade300;
    final offset = (_down && on) ? 1.0 : depth;

    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
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
      ),
    );
  }
}

// ----------------------------------------------------------------- painter

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