import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/number/number.dart';
import '../../data/providers/progress_provider.dart';

class NumberTraceScreen extends StatefulWidget {
  final NumberItem item;
  final bool isArabic;

  /// true إلا كان الرقم مكتوب من قبل (باش ما نعطيوش stars مرة أخرى)
  final bool alreadyCompleted;

  const NumberTraceScreen({
    super.key,
    required this.item,
    required this.isArabic,
    this.alreadyCompleted = false,
  });

  @override
  State<NumberTraceScreen> createState() => _NumberTraceScreenState();
}

enum _CheckState { idle, checking, success, tryAgain }

enum _Reason { none, tooLittle, incomplete, offTrack }

class _NumberTraceScreenState extends State<NumberTraceScreen> {
  static const Color primaryBlue = Color(0xFF0F92CA);
  static const Color primaryBlueDark = Color(0xFF0B6E9B);

  // ---- Checking config ----
  static const int _grid = 160; // resolution dyal mask (160x160)
  static const double _minCoverage = 0.80; // % men rqam ghadi ytghta
  static const double _minAccuracy = 0.85; // % men rssem ghadi yb9a fl rqam
  static const double _minLengthFactor = 0.8; // min length * side

  final List<List<Offset>> _strokes = [];
  _CheckState _state = _CheckState.idle;
  _Reason _reason = _Reason.none;
  double _side = 0;

  bool get _locked =>
      _state == _CheckState.checking || _state == _CheckState.success;

  // ---------------- Drawing ----------------

  void _onPanStart(DragStartDetails d) {
    if (_locked) return;
    setState(() {
      _strokes.add([_clamp(d.localPosition)]);
      _state = _CheckState.idle;
      _reason = _Reason.none;
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_locked || _strokes.isEmpty) return;
    setState(() => _strokes.last.add(_clamp(d.localPosition)));
  }

  Offset _clamp(Offset o) => Offset(
    o.dx.clamp(0.0, _side),
    o.dy.clamp(0.0, _side),
  );

  void _clear() {
    if (_locked) return;
    setState(() {
      _strokes.clear();
      _state = _CheckState.idle;
      _reason = _Reason.none;
    });
  }

  void _undo() {
    if (_locked || _strokes.isEmpty) return;
    setState(() {
      _strokes.removeLast();
      _state = _CheckState.idle;
      _reason = _Reason.none;
    });
  }

  // ---------------- Checking ----------------

  double get _inkLength {
    double total = 0;
    for (final s in _strokes) {
      for (int i = 1; i < s.length; i++) {
        total += (s[i] - s[i - 1]).distance;
      }
    }
    return total;
  }

  Future<Uint8List> _rasterize(void Function(Canvas c) draw) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(_grid / _side);
    draw(canvas);
    final picture = recorder.endRecording();
    final image = await picture.toImage(_grid, _grid);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!.buffer.asUint8List();
  }

  Future<void> _check() async {
    if (_strokes.isEmpty || _locked || _side <= 0) return;

    // 1) Kteb bzzaf chwiya? (kayna 7ta nokta/khorbacha sghira)
    if (_inkLength < _side * _minLengthFactor) {
      setState(() {
        _state = _CheckState.tryAgain;
        _reason = _Reason.tooLittle;
      });
      return;
    }

    setState(() => _state = _CheckState.checking);

    final side = _side;
    final symbol = widget.item.symbol;
    final fontSize = _glyphFontSize(side);

    final drawW = side * 0.07; // l'épaisseur dyal rssem
    final wideW = side * 0.13; // l'épaisseur li kanst3mlo l coverage
    final tolW = side * 0.09; // tolerance 7wal rqam

    final guide = await _rasterize((c) {
      _paintGlyph(c, Size(side, side), symbol, fontSize, Colors.black);
    });

    final tolerance = await _rasterize((c) {
      _paintGlyph(c, Size(side, side), symbol, fontSize, Colors.black);
      _paintGlyph(c, Size(side, side), symbol, fontSize, Colors.black,
          outlineWidth: tolW);
    });

    final drawn = await _rasterize((c) => paintStrokes(c, _strokes, drawW));
    final wide = await _rasterize((c) => paintStrokes(c, _strokes, wideW));

    int guideOn = 0, guideCovered = 0, drawnOn = 0, drawnInside = 0;
    const t = 100;

    for (int i = 3; i < guide.length; i += 4) {
      final g = guide[i] > t;
      final tol = tolerance[i] > t;
      final d = drawn[i] > t;
      final w = wide[i] > t;

      if (g) {
        guideOn++;
        if (w) guideCovered++;
      }
      if (d) {
        drawnOn++;
        if (tol) drawnInside++;
      }
    }

    final coverage = guideOn == 0 ? 0.0 : guideCovered / guideOn;
    final accuracy = drawnOn == 0 ? 0.0 : drawnInside / drawnOn;

    final passed = coverage >= _minCoverage && accuracy >= _minAccuracy;

    if (!mounted) return;

    if (!passed) {
      setState(() {
        _state = _CheckState.tryAgain;
        _reason =
        accuracy < _minAccuracy ? _Reason.offTrack : _Reason.incomplete;
      });
      return;
    }

    setState(() {
      _state = _CheckState.success;
      _reason = _Reason.none;
    });

    if (!widget.alreadyCompleted) {
      final progress = Provider.of<ProgressProvider>(context, listen: false);
      progress.addStars(1);
      progress.incrementChallengeProgress('math');
    }

    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) Navigator.of(context).pop(true);
  }

  // ---------------- UI ----------------

  String get _overlayLabel {
    final ar = widget.isArabic;
    switch (_state) {
      case _CheckState.success:
        return ar ? 'أحسنت!' : 'Great job!';
      case _CheckState.tryAgain:
        switch (_reason) {
          case _Reason.tooLittle:
            return ar ? 'اكتب الرقم كاملاً' : 'Write the whole number';
          case _Reason.incomplete:
            return ar ? 'أكمل الرقم' : 'Cover the whole number';
          case _Reason.offTrack:
            return ar ? 'ابقَ فوق الرقم' : 'Stay on the number';
          case _Reason.none:
            return ar ? 'حاول مرة أخرى' : 'Try again';
        }
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final ar = widget.isArabic;
    final canCheck = _strokes.isNotEmpty && !_locked;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8FA),
      appBar: AppBar(
        title: Text(ar ? 'اكتب الرقم' : 'Write the number'),
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
              ar ? 'تتبع الرقم بإصبعك' : 'Trace the number with your finger',
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
                      border: Border.all(
                        color: _state == _CheckState.success
                            ? const Color(0xFF35B24A)
                            : _state == _CheckState.tryAgain
                            ? const Color(0xFFE0A800)
                            : const Color(0xFFE4EEF2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        _side = constraints.maxWidth;
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            CustomPaint(
                              painter: _GuidePainter(
                                symbol: item.symbol,
                                fontSize: _glyphFontSize(_side),
                              ),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: _onPanStart,
                              onPanUpdate: _onPanUpdate,
                              child: CustomPaint(
                                painter: _StrokePainter(
                                  _strokes,
                                  _side * 0.07,
                                  _state == _CheckState.success
                                      ? const Color(0xFF35B24A)
                                      : primaryBlue,
                                ),
                                size: Size.infinite,
                              ),
                            ),
                            if (_state == _CheckState.success)
                              _ResultOverlay(
                                icon: Icons.emoji_events_rounded,
                                color: const Color(0xFF35B24A),
                                label: _overlayLabel,
                              ),
                            if (_state == _CheckState.tryAgain)
                              _ResultOverlay(
                                icon: Icons.refresh_rounded,
                                color: const Color(0xFFE0A800),
                                label: _overlayLabel,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Row(
                children: [
                  _SquareButton(
                    icon: Icons.undo_rounded,
                    onTap: _strokes.isEmpty || _locked ? null : _undo,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _strokes.isEmpty || _locked ? null : _clear,
                      icon: const Icon(Icons.cleaning_services_rounded),
                      label: Text(ar ? 'مسح' : 'Clear'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryBlueDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: canCheck ? _check : null,
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
                      label: Text(ar ? 'تحقق' : 'Check'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                        primaryBlue.withOpacity(0.35),
                        disabledForegroundColor: Colors.white70,
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

// ======================= Shared drawing helpers =======================

double _glyphFontSize(double side) => side * 0.78;

/// Kayrssem rqam f wst canvas. Nafs fonction kat-st3mlha l UI w l mask,
/// bach ykono identiques 100%.
void _paintGlyph(
    Canvas canvas,
    Size size,
    String symbol,
    double fontSize,
    Color color, {
      double? outlineWidth,
    }) {
  final style = outlineWidth == null
      ? TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.w800,
    color: color,
    height: 1,
  )
      : TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.w800,
    height: 1,
    foreground: Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = outlineWidth
      ..strokeJoin = StrokeJoin.round
      ..color = color,
  );

  final tp = TextPainter(
    text: TextSpan(text: symbol, style: style),
    textDirection: TextDirection.ltr,
  )..layout();

  tp.paint(
    canvas,
    Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2),
  );
}

void paintStrokes(
    Canvas canvas,
    List<List<Offset>> strokes,
    double width, [
      Color color = Colors.black,
    ]) {
  final line = Paint()
    ..color = color
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;
  final dot = Paint()
    ..color = color
    ..style = PaintingStyle.fill;

  for (final stroke in strokes) {
    if (stroke.isEmpty) continue;
    if (stroke.length < 2) {
      canvas.drawCircle(stroke.first, width / 2, dot);
      continue;
    }
    final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
    for (int i = 1; i < stroke.length; i++) {
      path.lineTo(stroke[i].dx, stroke[i].dy);
    }
    canvas.drawPath(path, line);
  }
}

class _GuidePainter extends CustomPainter {
  final String symbol;
  final double fontSize;

  _GuidePainter({required this.symbol, required this.fontSize});

  @override
  void paint(Canvas canvas, Size size) {
    // outline خفيف + fill باش يبان الرقم مزيان
    _paintGlyph(canvas, size, symbol, fontSize, const Color(0xFFE3EDF1),
        outlineWidth: size.width * 0.012);
    _paintGlyph(canvas, size, symbol, fontSize, const Color(0xFFD5E4EA));
  }

  @override
  bool shouldRepaint(covariant _GuidePainter old) =>
      old.symbol != symbol || old.fontSize != fontSize;
}

class _StrokePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final double width;
  final Color color;

  _StrokePainter(this.strokes, this.width, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    paintStrokes(canvas, strokes, math.max(width, 6), color);
  }

  @override
  bool shouldRepaint(covariant _StrokePainter old) => true;
}

// ======================= Small widgets =======================

class _SquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _SquareButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled
                  ? const Color(0xFF0B6E9B).withOpacity(0.5)
                  : const Color(0xFFE4EEF2),
            ),
          ),
          child: Icon(
            icon,
            color: enabled ? const Color(0xFF0B6E9B) : const Color(0xFFB8C6CC),
          ),
        ),
      ),
    );
  }
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
      child: IgnorePointer(
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
      ),
    );
  }
}