import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../data/models/number/number.dart';
class NumberTraceScreen extends StatefulWidget {
  final NumberItem item;
  final bool isArabic;

  const NumberTraceScreen({
    super.key,
    required this.item,
    required this.isArabic,
  });

  @override
  State<NumberTraceScreen> createState() => _NumberTraceScreenState();
}

enum _CheckState { idle, checking, success, tryAgain }

class _NumberTraceScreenState extends State<NumberTraceScreen> {
  static const Color primaryBlue = Color(0xFF0F92CA);
  static const Color primaryBlueDark = Color(0xFF0B6E9B);

  final GlobalKey _guideKey = GlobalKey();
  final GlobalKey _drawKey = GlobalKey();

  final List<List<Offset>> _strokes = [];
  _CheckState _state = _CheckState.idle;

  void _onPanStart(DragStartDetails d) {
    setState(() {
      _strokes.add([d.localPosition]);
      _state = _CheckState.idle;
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() => _strokes.last.add(d.localPosition));
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _state = _CheckState.idle;
    });
  }

  Future<Uint8List?> _capturePixels(GlobalKey key) async {
    final boundary =
    key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData =
    await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _check() async {
    if (_strokes.isEmpty) return;
    setState(() => _state = _CheckState.checking);

    // Let the frame settle so the RepaintBoundaries have the latest paint.
    await Future.delayed(const Duration(milliseconds: 16));

    final guidePixels = await _capturePixels(_guideKey);
    final drawPixels = await _capturePixels(_drawKey);

    if (guidePixels == null ||
        drawPixels == null ||
        guidePixels.length != drawPixels.length) {
      setState(() => _state = _CheckState.tryAgain);
      return;
    }

    int guideOn = 0;
    int drawOn = 0;
    int overlapOn = 0;
    const threshold = 40; // alpha threshold to count a pixel as "ink"

    for (int i = 3; i < guidePixels.length; i += 4) {
      final g = guidePixels[i] > threshold;
      final d = drawPixels[i] > threshold;
      if (g) guideOn++;
      if (d) drawOn++;
      if (g && d) overlapOn++;
    }

    final coverage = guideOn == 0 ? 0.0 : overlapOn / guideOn;
    final accuracy = drawOn == 0 ? 0.0 : overlapOn / drawOn;

    final passed = coverage >= 0.45 && accuracy >= 0.35;

    if (!mounted) return;
    setState(() => _state = passed ? _CheckState.success : _CheckState.tryAgain);

    if (passed) {
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8FA),
      appBar: AppBar(
        title: Text(widget.isArabic ? 'اكتب الرقم' : 'Write the number'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text(
              item.word,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF213238),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.isArabic
                  ? 'تتبع الرقم بإصبعك'
                  : 'Trace the number with your finger',
              style: const TextStyle(fontSize: 13, color: Color(0xFF7C8C93)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE4EEF2), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Guide numeral (used both as visual guide and as
                        // the pixel mask to check against).
                        RepaintBoundary(
                          key: _guideKey,
                          child: Center(
                            child: Text(
                              item.symbol,
                              style: TextStyle(
                                fontSize: 220,
                                fontWeight: FontWeight.w800,
                                color: Colors.black.withOpacity(0.16),
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                        // User's drawing surface.
                        RepaintBoundary(
                          key: _drawKey,
                          child: GestureDetector(
                            onPanStart: _onPanStart,
                            onPanUpdate: _onPanUpdate,
                            child: CustomPaint(
                              painter: _StrokePainter(_strokes),
                              size: Size.infinite,
                            ),
                          ),
                        ),
                        if (_state == _CheckState.success)
                          _ResultOverlay(
                            icon: Icons.emoji_events_rounded,
                            color: const Color(0xFF35B24A),
                            label: widget.isArabic ? 'أحسنت!' : 'Great job!',
                          ),
                        if (_state == _CheckState.tryAgain)
                          _ResultOverlay(
                            icon: Icons.refresh_rounded,
                            color: const Color(0xFFE0A800),
                            label: widget.isArabic
                                ? 'حاول مرة أخرى'
                                : 'Try again',
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _clear,
                      icon: const Icon(Icons.cleaning_services_rounded),
                      label: Text(widget.isArabic ? 'مسح' : 'Clear'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryBlueDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                      _state == _CheckState.checking ? null : _check,
                      icon: _state == _CheckState.checking
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.check_rounded),
                      label: Text(widget.isArabic ? 'تحقق' : 'Check'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
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
}

class _StrokePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  _StrokePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F92CA)
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) {
        if (stroke.isNotEmpty) {
          canvas.drawCircle(stroke.first, paint.strokeWidth / 2, paint..style = PaintingStyle.fill);
          paint.style = PaintingStyle.stroke;
        }
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) => true;
}

class _ResultOverlay extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _ResultOverlay({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 14,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.95),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}