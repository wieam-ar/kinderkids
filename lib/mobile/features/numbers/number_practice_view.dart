import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/ui/kid_ui.dart';
import '../../data/models/number/number.dart';
import '../../data/providers/progress_provider.dart';
import '../alphabet/letter_shape_matcher.dart';
import '../alphabet/letter_tracing_canvas.dart';
class NumberPracticeView extends StatefulWidget {
  final List<NumberItem> numbers;
  final bool isArabic;
  final Color accent;

  const NumberPracticeView({
    super.key,
    required this.numbers,
    required this.isArabic,
    this.accent = KidColors.purple,
  });

  @override
  State<NumberPracticeView> createState() => _NumberPracticeViewState();
}

class _NumberPracticeViewState extends State<NumberPracticeView>
    with AutomaticKeepAliveClientMixin {
  static const double _canvasSize = 280;
  static const Color _green = KidColors.green;
  static const Color _orange = KidColors.orange;

  final _canvasKey = GlobalKey<LetterTracingCanvasState>();

  /// Numbers li tcompletaw: ma kaynch farming dyal stars.
  final Set<int> _rewarded = {};

  int _index = 0;
  GlyphGuide? _guide;
  LetterMatcher? _matcher;

  List<List<Offset>> _strokes = const [];
  double _progress = 0;
  TraceVerdict? _verdict;
  bool _checking = false;
  bool _success = false;

  int _prepareToken = 0;
  int _evalToken = 0;

  Color get _accent => widget.accent;
  NumberItem get _item => widget.numbers[_index];
  bool get _isLast => _index >= widget.numbers.length - 1;

  String _t(String ar, String en) => widget.isArabic ? ar : en;

  /// Police du glyphe tracé (doit rester identique pour le matcher).
  TextStyle get _style => widget.isArabic
      ? GoogleFonts.cairo(fontSize: 160, fontWeight: FontWeight.w700)
      : GoogleFonts.poppins(fontSize: 160, fontWeight: FontWeight.w600);

  /// Police des textes d'interface (Fredoka n'a pas l'arabe -> Cairo).
  TextStyle _ui({
    double size = 15,
    Color color = KidColors.textDark,
    FontWeight weight = FontWeight.w700,
  }) =>
      widget.isArabic
          ? GoogleFonts.cairo(fontSize: size, fontWeight: weight, color: color)
          : GoogleFonts.fredoka(
          fontSize: size, fontWeight: weight, color: color);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.numbers.isNotEmpty) _prepareNumber();
  }

  // ---------------------------------------------------------------- logic

  Future<void> _prepareNumber() async {
    final token = ++_prepareToken;
    final style = _style;
    final symbol = _item.symbol;

    setState(() {
      _guide = null;
      _matcher = null;
    });

    try {
      await GoogleFonts.pendingFonts([style]);
    } catch (_) {
      // Offline: system font, khdam b7al b7al.
    }

    final guide = await GlyphGuide.create(
      character: symbol,
      style: style,
      size: _canvasSize,
      direction: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
    );
    final matcher = await LetterMatcher.create(guide);

    if (!mounted || token != _prepareToken) return;
    setState(() {
      _guide = guide;
      _matcher = matcher;
    });
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.numbers.length) return;
    _evalToken++;
    setState(() {
      _index = index;
      _strokes = const [];
      _progress = 0;
      _verdict = null;
      _checking = false;
      _success = false;
    });
    _prepareNumber();
  }

  Future<TraceResult?> _evaluate() async {
    final matcher = _matcher;
    if (matcher == null) return null;
    final token = ++_evalToken;
    final result = await matcher.evaluate(_strokes);
    if (!mounted || token != _evalToken || matcher != _matcher) return null;
    setState(() => _progress = result.progress);
    return result;
  }

  /// Kat-tconada mn canvas mora kol stroke / clear / undo.
  /// Trace s7i7 = accepté automatiquement.
  Future<void> _onStrokesChanged(List<List<Offset>> strokes) async {
    if (_success) return;
    _strokes = strokes;

    if (strokes.isEmpty) {
      _evalToken++;
      setState(() {
        _progress = 0;
        _verdict = null;
      });
      return;
    }

    setState(() => _verdict = null);
    final result = await _evaluate();
    if (result != null && result.passed) _onSuccess();
  }

  Future<void> _onCheckPressed() async {
    if (_checking || _success) return;

    if (_strokes.isEmpty) {
      setState(() => _verdict = TraceVerdict.tooLittle);
      return;
    }

    setState(() => _checking = true);
    final result = await _evaluate();
    if (!mounted) return;
    setState(() => _checking = false);
    if (result == null) return;

    if (result.passed) {
      _onSuccess();
    } else {
      HapticFeedback.lightImpact();
      setState(() => _verdict = result.verdict);
    }
  }

  Future<void> _onSuccess() async {
    if (_success || !mounted) return;
    final index = _index;

    setState(() {
      _success = true;
      _verdict = null;
      _progress = 1;
      _checking = false;
    });
    HapticFeedback.mediumImpact();

    // 1 star + 1 challenge step l kol rqam, awel merra ghir.
    if (_rewarded.add(index)) {
      final progress = Provider.of<ProgressProvider>(context, listen: false);
      progress.addStars(1);
      progress.incrementChallengeProgress('math');
    }

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted || _index != index) return;

    if (index >= widget.numbers.length - 1) {
      _showDoneDialog();
    } else {
      _goTo(index + 1);
    }
  }

  void _showDoneDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        child: KidCard(
          accent: _accent,
          radius: 32,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 8),
              Text(_t('مبروك!', 'Great job!'),
                  style: _ui(size: 26, weight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                _t('أنهيت جميع الأرقام!', 'You finished all the numbers!'),
                textAlign: TextAlign.center,
                style: _ui(size: 15, color: KidColors.textMuted),
              ),
              const SizedBox(height: 22),
              KidButton(
                label: _t('أعد المحاولة', 'Restart'),
                icon: Icons.replay_rounded,
                color: _accent,
                expand: true,
                onPressed: () {
                  Navigator.of(dialogCtx).pop();
                  _goTo(0);
                },
              ),
              const SizedBox(height: 14),
              KidButton(
                label: _t('خروج', 'Done'),
                icon: Icons.check_rounded,
                color: KidColors.green,
                expand: true,
                onPressed: () => Navigator.of(dialogCtx).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ UI

  String _verdictText(TraceVerdict verdict) {
    switch (verdict) {
      case TraceVerdict.offLetter:
        return _t('حاول أن تبقى فوق الرقم الرمادي',
            'Stay on top of the gray number');
      case TraceVerdict.missingParts:
        return _t('لا تنسَ الأجزاء الصغيرة', "Don't forget the small parts");
      case TraceVerdict.tooLittle:
        return _t('أكمل التتبّع على كامل الرقم',
            'Keep going, trace the whole number');
      case TraceVerdict.success:
        return '';
    }
  }

  Widget _buildFeedback() {
    late final String text;
    late final String emoji;
    late final Color color;

    if (_success) {
      text = _t('أحسنت!', 'Bravo!');
      emoji = '🎉';
      color = _green;
    } else if (_verdict != null) {
      text = _verdictText(_verdict!);
      emoji = '💪';
      color = _orange;
    } else {
      text = _t('تتبّع الرقم بإصبعك', 'Trace the number with your finger');
      emoji = '👆';
      color = _accent;
    }

    return SizedBox(
      height: 52,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: Container(
            key: ValueKey(text),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.5), width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 17)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: _ui(size: 14, color: KidColors.darken(color, 0.12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.numbers.isEmpty) {
      return const Center(child: Text('—'));
    }

    final total = widget.numbers.length;
    final side = math.min(_canvasSize, MediaQuery.of(context).size.width - 96);
    final borderColor = _success
        ? _green
        : (_verdict != null ? _orange : _accent.withOpacity(0.35));
    final canDraw = _guide != null && !_success;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Column(
        children: [
          // Overall progress + counter + stars of this session.
          Row(
            children: [
              Expanded(
                child: KidProgressBar(
                  value: (_index + 1) / total,
                  color: _accent,
                ),
              ),
              const SizedBox(width: 10),
              Text('${_index + 1}/$total',
                  style: _ui(size: 14, color: KidColors.textMuted)),
              const SizedBox(width: 8),
              KidStarsChip(stars: _rewarded.length),
            ],
          ),
          const SizedBox(height: 16),

          // Previous | big number | next.
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                KidRoundButton(
                  icon: Icons.chevron_left_rounded,
                  color: _accent,
                  onTap: _index > 0 ? () => _goTo(_index - 1) : null,
                ),
                const SizedBox(width: 14),
                Container(
                  width: 112,
                  height: 112,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [KidColors.lighten(_accent, 0.08), _accent],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.6), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: KidColors.darken(_accent),
                        offset: const Offset(0, 7),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: CurvedAnimation(
                          parent: anim, curve: Curves.easeOutBack),
                      child: child,
                    ),
                    child: Text(
                      _item.symbol,
                      key: ValueKey(_item.symbol),
                      style: _style.copyWith(
                          fontSize: 66, color: Colors.white, height: 1.1),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                KidRoundButton(
                  icon: Icons.chevron_right_rounded,
                  color: _accent,
                  onTap: !_isLast ? () => _goTo(_index + 1) : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Le mot du nombre (one, two... / واحد، اثنان...).
          Text(
            _item.word,
            textAlign: TextAlign.center,
            style: _ui(size: 20, color: KidColors.textDark),
          ),
          const SizedBox(height: 18),

          // Tracing canvas (scaled down on very small screens).
          SizedBox(
            width: side,
            height: side,
            child: FittedBox(
              child: LetterTracingCanvas(
                key: _canvasKey,
                guide: _guide,
                size: _canvasSize,
                enabled: canDraw,
                borderColor: borderColor,
                inkColor: _accent,
                onStrokesChanged: _onStrokesChanged,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Live progress bar.
          SizedBox(
            width: side,
            child: KidProgressBar(
              value: _progress,
              height: 12,
              color: (_success || _progress >= LetterMatcher.minCoverage)
                  ? _green
                  : _accent,
            ),
          ),
          const SizedBox(height: 10),

          _buildFeedback(),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              KidRoundButton(
                icon: Icons.undo_rounded,
                color: _accent,
                tooltip: _t('تراجع', 'Undo'),
                onTap: canDraw && _strokes.isNotEmpty
                    ? () => _canvasKey.currentState?.undo()
                    : null,
              ),
              const SizedBox(width: 12),
              KidRoundButton(
                icon: Icons.delete_sweep_rounded,
                color: KidColors.coral,
                tooltip: _t('امسح', 'Clear'),
                onTap: canDraw && _strokes.isNotEmpty
                    ? () => _canvasKey.currentState?.clear()
                    : null,
              ),
              const SizedBox(width: 16),
              KidButton(
                label: _t('تحقق', 'Check'),
                icon: Icons.check_rounded,
                color: _green,
                loading: _checking,
                onPressed: canDraw && !_checking ? _onCheckPressed : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}