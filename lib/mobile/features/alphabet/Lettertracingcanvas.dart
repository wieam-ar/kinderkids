import 'package:flutter/material.dart';

/// A square canvas showing a faint guide letter that the child traces
/// over with a finger. Reports every stroke back via [onStrokesChanged]
/// so the parent screen can run the correctness check.
class LetterTracingCanvas extends StatefulWidget {
  final String letter;
  final TextStyle guideStyle;
  final double size;
  final ValueChanged<List<List<Offset>>> onStrokesChanged;

  const LetterTracingCanvas({
    super.key,
    required this.letter,
    required this.guideStyle,
    required this.onStrokesChanged,
    this.size = 260,
  });

  @override
  State<LetterTracingCanvas> createState() => LetterTracingCanvasState();
}

class LetterTracingCanvasState extends State<LetterTracingCanvas> {
  final List<List<Offset>> _strokes = [];

  /// Called from the parent (e.g. after Clear / Next) to reset the canvas.
  void clear() {
    setState(() => _strokes.clear());
    widget.onStrokesChanged(_strokes);
  }

  void _onPanStart(DragStartDetails details) {
    setState(() => _strokes.add([details.localPosition]));
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() => _strokes.last.add(details.localPosition));
    widget.onStrokesChanged(_strokes);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Faint guide letter underneath, so the kid traces on top.
            Center(
              child: Text(
                widget.letter,
                style: widget.guideStyle.copyWith(
                  color: Colors.black.withOpacity(0.12),
                ),
              ),
            ),
            GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _StrokesPainter(_strokes),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StrokesPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  _StrokesPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F92CA)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      for (var i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StrokesPainter oldDelegate) => true;
}