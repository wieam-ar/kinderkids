import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Rasterizes a guide letter and a child's hand-drawn strokes into a
/// small boolean "ink" grid so the two can be compared cell-by-cell.
///
/// NOTE: this is a lightweight coverage heuristic, not real handwriting
/// recognition (OCR). It answers "did the kid roughly trace over the
/// letter shape", which is exactly what a tracing exercise needs,
/// without requiring any ML model or network call.
class LetterShapeMatcher {
  static const int canvasSize = 300;
  static const int gridSize = 22;

  /// Renders [text] with [style] into an off-screen image and returns a
  /// gridSize x gridSize boolean grid of "ink" cells.
  static Future<List<List<bool>>> rasterizeGlyph(
      String text,
      TextStyle style,
      ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, canvasSize.toDouble(), canvasSize.toDouble()),
    );

    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    final offset = Offset(
      (canvasSize - painter.width) / 2,
      (canvasSize - painter.height) / 2,
    );
    painter.paint(canvas, offset);

    final image = await recorder.endRecording().toImage(canvasSize, canvasSize);
    return _imageToGrid(image);
  }

  /// Renders the raw finger strokes (already scaled to canvasSize x
  /// canvasSize) into the same size grid.
  static Future<List<List<bool>>> rasterizeStrokes(
      List<List<Offset>> strokes,
      ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, canvasSize.toDouble(), canvasSize.toDouble()),
    );

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      for (var i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], paint);
      }
    }

    final image = await recorder.endRecording().toImage(canvasSize, canvasSize);
    return _imageToGrid(image);
  }

  static Future<List<List<bool>>> _imageToGrid(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final bytes = byteData!.buffer.asUint8List();

    final cell = canvasSize ~/ gridSize;
    final grid = List.generate(gridSize, (_) => List.filled(gridSize, false));

    for (var gy = 0; gy < gridSize; gy++) {
      for (var gx = 0; gx < gridSize; gx++) {
        var inkPixels = 0;
        var totalPixels = 0;
        for (var y = gy * cell; y < (gy + 1) * cell; y++) {
          for (var x = gx * cell; x < (gx + 1) * cell; x++) {
            final index = (y * canvasSize + x) * 4;
            if (index + 3 >= bytes.length) continue;
            totalPixels++;
            if (bytes[index + 3] > 40) inkPixels++; // alpha channel
          }
        }
        grid[gy][gx] = totalPixels > 0 && inkPixels / totalPixels > 0.15;
      }
    }
    return grid;
  }

  /// Compares a guide grid against a user grid.
  /// - recall: how much of the guide letter got covered by the child's ink
  /// - precision: how much of the child's ink actually landed on the letter
  static (double recall, double precision) compare(
      List<List<bool>> guide,
      List<List<bool>> user,
      ) {
    var guideOn = 0, userOn = 0, overlap = 0;
    for (var y = 0; y < gridSize; y++) {
      for (var x = 0; x < gridSize; x++) {
        if (guide[y][x]) guideOn++;
        if (user[y][x]) userOn++;
        if (guide[y][x] && user[y][x]) overlap++;
      }
    }
    final recall = guideOn == 0 ? 0.0 : overlap / guideOn;
    final precision = userOn == 0 ? 0.0 : overlap / userOn;
    return (recall, precision);
  }
}