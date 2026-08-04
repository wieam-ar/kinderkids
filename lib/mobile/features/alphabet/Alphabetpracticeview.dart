import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/alphabet/alpha.dart';
import 'Lettershapematcher.dart';
import 'Lettertracingcanvas.dart';

/// One independent practice sequence (used once for Arabic, once for
/// English). Each instance keeps its own index / strokes / feedback so
/// the two parts never interfere with each other.
class AlphabetPracticeView extends StatefulWidget {
  final List<AlphabetLetter> letters;
  final bool isArabic;

  const AlphabetPracticeView({
    super.key,
    required this.letters,
    required this.isArabic,
  });

  @override
  State<AlphabetPracticeView> createState() => _AlphabetPracticeViewState();
}

class _AlphabetPracticeViewState extends State<AlphabetPracticeView>
    with AutomaticKeepAliveClientMixin {
  static const double _canvasWidgetSize = 260;

  final _player = AudioPlayer();
  final _canvasKey = GlobalKey<LetterTracingCanvasState>();

  int _index = 0;
  List<List<Offset>> _currentStrokes = [];
  bool _checking = false;
  String? _feedback; // null | 'good' | 'retry'

  AlphabetLetter get _letter => widget.letters[_index];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _playCurrentSound();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _playCurrentSound() async {
    try {
      await _player.stop();
      await _player.play(UrlSource(_letter.soundUrl));
    } catch (_) {
      // No network / playback issue: the tracing exercise still works
      // fine without sound, so we just skip it silently.
    }
  }

  TextStyle get _guideStyle => GoogleFonts.poppins(
    fontSize: 150,
    fontWeight: FontWeight.w700,
  );

  Future<void> _checkLetter() async {
    if (_currentStrokes.isEmpty || _checking) return;
    setState(() => _checking = true);

    final guideGrid = await LetterShapeMatcher.rasterizeGlyph(
      _letter.character,
      _guideStyle,
    );

    // Strokes were captured on a _canvasWidgetSize canvas; scale them up
    // to the matcher's internal raster size before comparing.
    const scale = LetterShapeMatcher.canvasSize / _canvasWidgetSize;
    final scaledStrokes = _currentStrokes
        .map((stroke) => stroke.map((p) => p * scale).toList())
        .toList();

    final userGrid = await LetterShapeMatcher.rasterizeStrokes(scaledStrokes);
    final (recall, precision) = LetterShapeMatcher.compare(guideGrid, userGrid);

    // Tuned so a rough-but-honest trace passes, scribbles don't.
    final isCorrect = recall >= 0.45 && precision >= 0.25;

    if (!mounted) return;
    setState(() {
      _checking = false;
      _feedback = isCorrect ? 'good' : 'retry';
    });

    if (isCorrect) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) _goToNext();
    }
  }

  void _goToNext() {
    if (_index >= widget.letters.length - 1) {
      _showDoneDialog();
      return;
    }
    setState(() {
      _index++;
      _currentStrokes = [];
      _feedback = null;
    });
    _canvasKey.currentState?.clear();
    _playCurrentSound();
  }

  void _restart() {
    setState(() {
      _index = 0;
      _currentStrokes = [];
      _feedback = null;
    });
    _canvasKey.currentState?.clear();
    _playCurrentSound();
  }

  void _showDoneDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(widget.isArabic ? '🎉 مبروك!' : '🎉 Great job!'),
        content: Text(
          widget.isArabic
              ? 'خلصتي جميع الحروف العربية!'
              : 'You finished the whole English alphabet!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restart();
            },
            child: Text(widget.isArabic ? 'أعد المحاولة' : 'Restart'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(widget.isArabic ? 'خروج' : 'Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final progress = (_index + 1) / widget.letters.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.black12,
              color: const Color(0xFF0F92CA),
            ),
          ),
          const SizedBox(height: 6),
          Text('${_index + 1} / ${widget.letters.length}'),
          const SizedBox(height: 18),

          // Big letter + play-sound button.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _letter.character,
                style: _guideStyle.copyWith(fontSize: 64, color: Colors.black87),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: _playCurrentSound,
                icon: const Icon(Icons.volume_up_rounded, size: 30),
                color: const Color(0xFF0F92CA),
              ),
            ],
          ),
          Text(
            _letter.pronunciation,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),
          const SizedBox(height: 20),

          LetterTracingCanvas(
            key: _canvasKey,
            letter: _letter.character,
            guideStyle: _guideStyle,
            size: _canvasWidgetSize,
            onStrokesChanged: (s) => _currentStrokes = s,
          ),
          const SizedBox(height: 14),

          SizedBox(
            height: 22,
            child: _feedback == 'good'
                ? const Text('✅ Bravo!',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                : _feedback == 'retry'
                ? Text(
              widget.isArabic ? '🙂 حاول مرة أخرى' : '🙂 Try again',
              style: const TextStyle(
                  color: Colors.orange, fontWeight: FontWeight.bold),
            )
                : null,
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  _canvasKey.currentState?.clear();
                  setState(() {
                    _currentStrokes = [];
                    _feedback = null;
                  });
                },
                icon: const Icon(Icons.refresh_rounded),
                label: Text(widget.isArabic ? 'امسح' : 'Clear'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _checking ? null : _checkLetter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F92CA),
                  foregroundColor: Colors.white,
                ),
                icon: _checking
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.check_rounded),
                label: Text(widget.isArabic ? 'تحقق' : 'Check'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}