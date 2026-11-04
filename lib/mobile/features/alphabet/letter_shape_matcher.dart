import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Why a tracing attempt did (not) pass.
enum TraceVerdict { success, tooLittle, offLetter, missingParts }

class TraceResult {
  final TraceVerdict verdict;

  /// 0..1, how "complete" the tracing looks (used for the live progress bar).
  final double progress;

  const TraceResult(this.verdict, this.progress);

  bool get passed => verdict == TraceVerdict.success;

  static const empty = TraceResult(TraceVerdict.tooLittle, 0);
}

/// Rasterizes [draw] into a res x res mask (1 = ink, 0 = empty).
/// [logicalSize] is the size of the drawing area in logical pixels.
Future<Uint8List> _rasterAlpha(
    double logicalSize,
    int res,
    void Function(Canvas canvas) draw,
    ) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, res.toDouble(), res.toDouble()),
  );
  canvas.scale(res / logicalSize);
  draw(canvas);

  final picture = recorder.endRecording();
  final image = await picture.toImage(res, res);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  picture.dispose();

  final rgba = data!.buffer.asUint8List();
  final mask = Uint8List(res * res);
  for (var i = 0; i < mask.length; i++) {
    if (rgba[i * 4 + 3] > 40) mask[i] = 1;
  }
  return mask;
}

/// A letter drawn centered and scaled to fit a square of [size] px.
/// The very same object is used to paint the visible guide AND to build the
/// mask used for checking, so what the child sees is exactly what is checked.
class GlyphGuide {
  final String character;
  final double size;

  final TextPainter _painter;
  final Offset _origin;
  final Offset _inkCenter;
  final double _scale;

  GlyphGuide._(
      this.character,
      this.size,
      this._painter,
      this._origin,
      this._inkCenter,
      this._scale,
      );

  static const int _probeRes = 130;

  static Future<GlyphGuide> create({
    required String character,
    required TextStyle style,
    required double size,
    TextDirection direction = TextDirection.ltr,
  }) async {
    final painter = TextPainter(
      text: TextSpan(
        text: character,
        style: style.copyWith(color: Colors.black),
      ),
      textDirection: direction,
    )..layout();

    final origin = Offset(
      (size - painter.width) / 2,
      (size - painter.height) / 2,
    );

    // Measure the real ink bounds so the glyph can be centered and scaled
    // properly (line boxes are never centered on the visible shape).
    final probe = await _rasterAlpha(
      size,
      _probeRes,
          (c) => painter.paint(c, origin),
    );

    var minX = _probeRes, minY = _probeRes, maxX = -1, maxY = -1;
    for (var y = 0; y < _probeRes; y++) {
      for (var x = 0; x < _probeRes; x++) {
        if (probe[y * _probeRes + x] == 0) continue;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }

    var center = Offset(size / 2, size / 2);
    var scale = 1.0;
    if (maxX >= 0) {
      final k = size / _probeRes;
      final inkW = (maxX - minX + 1) * k;
      final inkH = (maxY - minY + 1) * k;
      center = Offset((minX + maxX + 1) / 2 * k, (minY + maxY + 1) / 2 * k);
      scale = (size * 0.72 / (inkW > inkH ? inkW : inkH)).clamp(0.5, 1.8);
    }

    return GlyphGuide._(character, size, painter, origin, center, scale);
  }

  void paint(Canvas canvas) {
    canvas.save();
    canvas.translate(size / 2, size / 2);
    canvas.scale(_scale);
    canvas.translate(-_inkCenter.dx, -_inkCenter.dy);
    _painter.paint(canvas, _origin);
    canvas.restore();
  }
}

/// Compares the child's strokes against a [GlyphGuide].
///
/// - **coverage**: how much of the letter is covered by the child's ink
///   (with a tolerance so a wobbly trace still counts).
/// - **precision**: how much of the child's ink is on the letter
///   (with a tolerance) -> scribbles outside the letter fail.
/// - **parts**: every significant separate part of the letter (dots,
///   detached strokes) must be traced too.
class LetterMatcher {
  static const int res = 130;
  static const double strokeWidth = 14; // logical px, shared with painters
  static const int _tolerance = 6; // grid cells (~12 logical px at 260)

  static const double minCoverage = 0.80;
  static const double minPrecision = 0.65;
  static const double minPartCoverage = 0.50;

  final GlyphGuide guide;
  final Uint8List _guideMask;
  final Uint8List _guideNear;
  final Int32List _labels;
  final List<int> _areas;
  final Set<int> _significant;
  final int _guideArea;

  LetterMatcher._(
      this.guide,
      this._guideMask,
      this._guideNear,
      this._labels,
      this._areas,
      this._significant,
      this._guideArea,
      );

  static Future<LetterMatcher> create(GlyphGuide guide) async {
    final mask = await _rasterAlpha(guide.size, res, guide.paint);
    final near = _dilate(mask, _tolerance);

    var area = 0;
    for (final v in mask) {
      area += v;
    }

    // Connected components (4-neighbourhood).
    final labels = Int32List(res * res);
    final areas = <int>[0];
    final stack = <int>[];
    var next = 1;
    for (var i = 0; i < mask.length; i++) {
      if (mask[i] == 0 || labels[i] != 0) continue;
      final label = next++;
      var count = 0;
      labels[i] = label;
      stack.add(i);
      while (stack.isNotEmpty) {
        final c = stack.removeLast();
        count++;
        final x = c % res, y = c ~/ res;
        void visit(int nx, int ny) {
          if (nx < 0 || ny < 0 || nx >= res || ny >= res) return;
          final n = ny * res + nx;
          if (mask[n] == 1 && labels[n] == 0) {
            labels[n] = label;
            stack.add(n);
          }
        }

        visit(x - 1, y);
        visit(x + 1, y);
        visit(x, y - 1);
        visit(x, y + 1);
      }
      areas.add(count);
    }

    final minArea = (area * 0.01).round().clamp(10, 1 << 30);
    final significant = <int>{
      for (var l = 1; l < areas.length; l++)
        if (areas[l] >= minArea) l,
    };

    return LetterMatcher._(guide, mask, near, labels, areas, significant, area);
  }

  /// Square dilation by [r] cells (separable, O(n * r)).
  static Uint8List _dilate(Uint8List src, int r) {
    final tmp = Uint8List(res * res);
    final out = Uint8List(res * res);
    for (var y = 0; y < res; y++) {
      for (var x = 0; x < res; x++) {
        if (src[y * res + x] == 0) continue;
        final from = x - r < 0 ? 0 : x - r;
        final to = x + r >= res ? res - 1 : x + r;
        for (var nx = from; nx <= to; nx++) {
          tmp[y * res + nx] = 1;
        }
      }
    }
    for (var y = 0; y < res; y++) {
      for (var x = 0; x < res; x++) {
        if (tmp[y * res + x] == 0) continue;
        final from = y - r < 0 ? 0 : y - r;
        final to = y + r >= res ? res - 1 : y + r;
        for (var ny = from; ny <= to; ny++) {
          out[ny * res + x] = 1;
        }
      }
    }
    return out;
  }

  /// Shared by the on-screen painter and the matcher so both see the same ink.
  static Paint strokePaint(Color color) => Paint()
    ..color = color
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  static void drawStrokes(
      Canvas canvas,
      List<List<Offset>> strokes,
      Paint paint,
      ) {
    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        // A simple tap = a dot (important for letters with dots).
        canvas.drawPoints(ui.PointMode.points, [stroke.first], paint);
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  Future<TraceResult> evaluate(List<List<Offset>> strokes) async {
    if (strokes.every((s) => s.isEmpty) || _guideArea == 0) {
      return TraceResult.empty;
    }

    final user = await _rasterAlpha(
      guide.size,
      res,
          (c) => drawStrokes(c, strokes, strokePaint(Colors.black)),
    );
    final userNear = _dilate(user, _tolerance);

    var userArea = 0, userOnLetter = 0, covered = 0;
    final hit = List<int>.filled(_areas.length, 0);

    for (var i = 0; i < user.length; i++) {
      if (user[i] == 1) {
        userArea++;
        if (_guideNear[i] == 1) userOnLetter++;
      }
      if (_guideMask[i] == 1 && userNear[i] == 1) {
        covered++;
        hit[_labels[i]]++;
      }
    }

    if (userArea == 0) return TraceResult.empty;

    final coverage = covered / _guideArea;
    final precision = userOnLetter / userArea;

    var missingPart = false;
    for (final l in _significant) {
      if (hit[l] / _areas[l] < minPartCoverage) {
        missingPart = true;
        break;
      }
    }

    final precisionFactor = (precision / minPrecision).clamp(0.0, 1.0);
    final progress = (coverage * precisionFactor).clamp(0.0, 0.97);

    if (precision < minPrecision) {
      return TraceResult(TraceVerdict.offLetter, progress);
    }
    if (coverage < minCoverage) {
      return TraceResult(TraceVerdict.tooLittle, progress);
    }
    if (missingPart) {
      return TraceResult(TraceVerdict.missingParts, progress);
    }
    return const TraceResult(TraceVerdict.success, 1);
  }
}