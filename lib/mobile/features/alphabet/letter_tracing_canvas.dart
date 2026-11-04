import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'letter_shape_matcher.dart';

/// Square canvas showing a faint guide letter that the child traces with a
/// finger. After every finished stroke (and on clear / undo) it reports the
/// strokes through [onStrokesChanged].
///
/// Drawing starts the instant the finger touches the screen and wins the
/// gesture arena immediately, so a parent scroll view or TabBarView never
/// steals the gesture while the child is drawing.
class LetterTracingCanvas extends StatefulWidget {
  final GlyphGuide? guide;
  final double size;
  final bool enabled;
  final Color borderColor;
  final Color inkColor;
  final ValueChanged<List<List<Offset>>> onStrokesChanged;

  const LetterTracingCanvas({
    super.key,
    required this.guide,
    required this.onStrokesChanged,
    this.size = 280,
    this.enabled = true,
    this.borderColor = Colors.black12,
    this.inkColor = const Color(0xFF0F92CA),
  });

  @override
  State<LetterTracingCanvas> createState() => LetterTracingCanvasState();
}

class LetterTracingCanvasState extends State<LetterTracingCanvas> {
  List<List<Offset>> _strokes = [];
  bool _drawing = false;

  bool get hasStrokes => _strokes.isNotEmpty;

  void clear() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes = []);
    _notify();
  }

  void undo() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes = _strokes.sublist(0, _strokes.length - 1));
    _notify();
  }

  @override
  void didUpdateWidget(covariant LetterTracingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    // New letter -> blank page (the parent already reset its own state).
    if (oldWidget.guide != widget.guide) {
      _strokes = [];
      _drawing = false;
    }
  }

  void _notify() {
    widget.onStrokesChanged(
      _strokes.map((s) => List<Offset>.unmodifiable(s)).toList(),
    );
  }

  Offset _clamp(Offset p) => Offset(
    p.dx.clamp(0.0, widget.size),
    p.dy.clamp(0.0, widget.size),
  );

  void _onStart(Offset p) {
    if (!widget.enabled) return;
    _drawing = true;
    setState(() => _strokes.add([_clamp(p)]));
  }

  void _onMove(Offset p) {
    if (!_drawing || _strokes.isEmpty) return;
    final point = _clamp(p);
    if ((point - _strokes.last.last).distance < 1.5) return;
    setState(() => _strokes.last.add(point));
  }

  void _onEnd() {
    if (!_drawing) return;
    _drawing = false;
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final guide = widget.guide;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: widget.borderColor, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: guide == null
            ? const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        )
            : RawGestureDetector(
          behavior: HitTestBehavior.opaque,
          gestures: {
            _DrawGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<
                _DrawGestureRecognizer>(
                  () => _DrawGestureRecognizer(),
                  (r) {
                r
                  ..onStart = _onStart
                  ..onMove = _onMove
                  ..onEnd = _onEnd;
              },
            ),
          },
          child: CustomPaint(
            size: Size.square(widget.size),
            painter: _CanvasPainter(
              guide: guide,
              strokes: _strokes,
              inkColor: widget.inkColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// Wins the gesture arena on pointer-down (no touch slop) and tracks a single
/// pointer. This blocks scrolling / tab swiping while the child draws.
class _DrawGestureRecognizer extends OneSequenceGestureRecognizer {
  ValueChanged<Offset>? onStart;
  ValueChanged<Offset>? onMove;
  VoidCallback? onEnd;

  int? _active;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (_active != null) return;
    _active = event.pointer;
    startTrackingPointer(event.pointer, event.transform);
    resolve(GestureDisposition.accepted);
    onStart?.call(event.localPosition);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _active) return;
    if (event is PointerMoveEvent) {
      onMove?.call(event.localPosition);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _active = null;
      stopTrackingPointer(event.pointer);
      onEnd?.call();
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  String get debugDescription => 'letter draw';
}

class _CanvasPainter extends CustomPainter {
  final GlyphGuide guide;
  final List<List<Offset>> strokes;
  final Color inkColor;

  _CanvasPainter({
    required this.guide,
    required this.strokes,
    required this.inkColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Light dashed middle lines, like a handwriting notebook.
    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.06)
      ..strokeWidth = 1.5;
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(x + 5, size.height / 2),
        linePaint,
      );
      canvas.drawLine(
        Offset(size.width / 2, x),
        Offset(size.width / 2, x + 5),
        linePaint,
      );
    }

    // Guide letter in soft gray.
    canvas.saveLayer(
      Offset.zero & size,
      Paint()
        ..colorFilter = ColorFilter.mode(
          Colors.black.withOpacity(0.14),
          BlendMode.srcIn,
        ),
    );
    guide.paint(canvas);
    canvas.restore();

    // Child's strokes.
    LetterMatcher.drawStrokes(
      canvas,
      strokes,
      LetterMatcher.strokePaint(inkColor.withOpacity(0.9)),
    );
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter old) => true;
}