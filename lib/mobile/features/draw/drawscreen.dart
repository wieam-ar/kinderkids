import 'package:flutter/material.dart';

/// Free-draw canvas screen — kids can doodle with their finger, pick a
/// color, change brush size, undo/redo strokes, and clear the page.
///
/// Visual language matches HomeScreen / ActivityDetailScreen: same blue
/// accent, rounded 20-24 radius cards, soft shadows.
class DrawScreen extends StatefulWidget {
  const DrawScreen({super.key});

  @override
  State<DrawScreen> createState() => _DrawScreenState();
}

class _DrawScreenState extends State<DrawScreen> {
  // --- Design tokens (matches HomeScreen) --------------------------------
  static const Color primaryBlue = Color(0xFF0F92CA);
  static const Color primaryBlueDark = Color(0xFF0B6E9B);
  static const Color textDark = Color(0xFF213238);
  // -------------------------------------------------------------------------

  static const List<Color> _palette = [
    Color(0xFFE0507B), // pink/red
    Color(0xFFFFC542), // yellow
    Color(0xFF35B24A), // green
    Color(0xFF3AAAE0), // light blue
    Color(0xFF3B4CCA), // dark blue
    Color(0xFFE0247A), // magenta
    Color(0xFFF2994A), // orange
    Color(0xFF2FBF8F), // teal
    Color(0xFF8B5CF6), // purple
    Color(0xFFF2B5C4), // soft pink
  ];

  final List<_Stroke> _strokes = [];
  final List<_Stroke> _redoStack = [];
  _Stroke? _currentStroke;

  Color _selectedColor = _palette[3];
  double _strokeWidth = 8;

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentStroke = _Stroke(
        color: _selectedColor,
        width: _strokeWidth,
        points: [details.localPosition],
      );
      _strokes.add(_currentStroke!);
      _redoStack.clear();
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentStroke?.points.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _currentStroke = null;
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() {
      _redoStack.add(_strokes.removeLast());
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    setState(() {
      _strokes.add(_redoStack.removeLast());
    });
  }

  void _clear() {
    if (_strokes.isEmpty) return;
    setState(() {
      _redoStack.clear();
      _strokes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            const SizedBox(height: 8),
            Expanded(child: _buildCanvas()),
            _buildBottomPanel(),
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
          _RoundIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Let\'s Draw!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),
          ),
          _RoundIconButton(
            icon: Icons.undo_rounded,
            onTap: _undo,
            enabled: _strokes.isNotEmpty,
          ),
          const SizedBox(width: 8),
          _RoundIconButton(
            icon: Icons.redo_rounded,
            onTap: _redo,
            enabled: _redoStack.isNotEmpty,
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
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: CustomPaint(
            painter: _DrawingPainter(strokes: _strokes),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
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
          // Brush size row
          Row(
            children: [
              const Icon(Icons.brush_rounded, color: primaryBlue, size: 20),
              const SizedBox(width: 10),
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
              _RoundIconButton(
                icon: Icons.delete_outline_rounded,
                onTap: _clear,
                enabled: _strokes.isNotEmpty,
                color: const Color(0xFFE0507B),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Color palette row
          SizedBox(
            height: 42,
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
                    width: selected ? 42 : 34,
                    height: selected ? 42 : 34,
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
        ],
      ),
    );
  }
}

class _Stroke {
  final Color color;
  final double width;
  final List<Offset> points;

  _Stroke({required this.color, required this.width, required this.points});
}

class _DrawingPainter extends CustomPainter {
  final List<_Stroke> strokes;

  _DrawingPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.length == 1) {
        // A single tap: draw a dot.
        canvas.drawCircle(stroke.points.first, stroke.width / 2,
            paint..style = PaintingStyle.fill);
        continue;
      }

      final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}

/// Small round icon button reused for back / undo / redo / clear actions.
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
              color: color ?? _DrawScreenState.primaryBlue,
            ),
          ),
        ),
      ),
    );
  }
}