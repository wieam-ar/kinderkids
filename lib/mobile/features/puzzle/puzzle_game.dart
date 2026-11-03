import 'dart:math';

import 'package:flutter/material.dart';

import '../science/fun_common.dart';

/// A drag-and-drop jigsaw puzzle with snap animations, sparkles, sounds and
/// 3 languages. The "picture" is a big emoji on a gradient card.
///
/// Pops with `true` if the child solved the puzzle at least once, so the
/// picker can give the stars (even if the child used "Play again").
class PuzzleGameScreen extends StatefulWidget {
  final String themeId; // animals, fruits, ...
  final String emoji;
  final List<Color> gradientColors;
  final int gridSize; // 2, 3 or 4
  final String levelId; // easy, medium, hard

  const PuzzleGameScreen({
    super.key,
    required this.themeId,
    required this.emoji,
    required this.gradientColors,
    required this.gridSize,
    required this.levelId,
  });

  @override
  State<PuzzleGameScreen> createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends State<PuzzleGameScreen>
    with TickerProviderStateMixin, FunLang<PuzzleGameScreen> {
  static const Color textDark = Color(0xFF213238);
  static const Color textMuted = Color(0xFF7C8C93);

  late int _total;
  late List<int?> _board; // slot index -> piece index (null if empty)
  late List<int> _tray; // shuffled piece indices waiting to be placed
  int _moves = 0;
  int _round = 0; // changes on every new game (re-plays the tray animation)
  bool _showPeek = false;
  bool _solvedOnce = false;
  bool _celebrating = false;

  int _burst = 0;
  int _lastSlot = 0;
  int _shake = 0;
  String _msgKey = 'pz_peek_hint';

  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  Color get _accent => widget.gradientColors.last;

  @override
  void initState() {
    super.initState();
    LabSfx.preload();
    _setupPuzzle();
    _idle.repeat();
  }

  @override
  void dispose() {
    _idle.dispose();
    LabSfx.stopSpeech();
    super.dispose();
  }

  void _setupPuzzle() {
    _total = widget.gridSize * widget.gridSize;
    _board = List<int?>.filled(_total, null);
    _tray = List<int>.generate(_total, (i) => i)..shuffle(Random());
    _moves = 0;
    _round++;
    _celebrating = false;
    _showPeek = false;
    _msgKey = 'pz_peek_hint';
  }

  bool get _isSolved => !_board.contains(null);
  int get _placed => _board.where((p) => p != null).length;

  void _exit() => Navigator.of(context).pop(_solvedOnce);

  void _flashMsg(String key) {
    setState(() => _msgKey = key);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted && _msgKey == key) setState(() => _msgKey = 'pz_peek_hint');
    });
  }

  // ---- Game actions --------------------------------------------------------

  void _onPieceDropped(int pieceIndex, int slotIndex) {
    setState(() {
      _tray.remove(pieceIndex);
      _board[slotIndex] = pieceIndex;
      _moves++;
      _lastSlot = slotIndex;
      _burst++;
    });
    LabSfx.play('ding');
    LabSfx.soft();
    if (_isSolved) {
      _celebrate();
    } else {
      _flashMsg('pz_good');
    }
  }

  void _onPieceMissed() {
    LabSfx.play('nope', volume: 0.7);
    LabSfx.soft();
    setState(() => _shake++);
    _flashMsg('pz_try');
  }

  void _useHint() {
    if (_tray.isEmpty) return;
    setState(() {
      final pieceIndex = _tray.first;
      _tray.removeAt(0);
      _board[pieceIndex] = pieceIndex;
      _moves++;
      _lastSlot = pieceIndex;
      _burst++;
    });
    LabSfx.play('twinkle');
    LabSfx.tap();
    if (_isSolved) _celebrate();
  }

  void _peekFlash() {
    LabSfx.play('twinkle', volume: 0.6);
    setState(() => _showPeek = true);
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) setState(() => _showPeek = false);
    });
  }

  Future<void> _celebrate() async {
    if (_celebrating) return;
    _celebrating = true;
    _solvedOnce = true;
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    await showStageComplete(
      context,
      emoji: '🧩',
      message: tr('pz_win', {
        'theme': tr('th_${widget.themeId}'),
        'n': '$_moves',
      }),
    );
    if (!mounted) return;
    _showNextDialog();
  }

  void _showNextDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Directionality(
        textDirection: dir,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.3, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (context, s, child) =>
                      Transform.scale(scale: s, child: child),
                  child: const Text('🎉', style: TextStyle(fontSize: 56)),
                ),
                const SizedBox(height: 10),
                Text(
                  tr('pz_great'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tr('pz_next'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13.5, color: textMuted),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: LabChunkyButton(
                        color: Colors.white,
                        shadowColor: Colors.grey.shade300,
                        borderColor: _accent,
                        foreground: _accent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 12),
                        onTap: () {
                          LabSfx.play('pop');
                          Navigator.of(dialogContext).pop();
                          setState(_setupPuzzle);
                        },
                        child: Center(
                          child: Text(tr('pz_again'),
                              textAlign: TextAlign.center),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LabChunkyButton(
                        color: _accent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 12),
                        onTap: () {
                          LabSfx.play('pop');
                          Navigator.of(dialogContext).pop();
                          _exit();
                        },
                        child: Center(
                          child: Text(tr('pz_other'),
                              textAlign: TextAlign.center),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- UI ------------------------------------------------------------------

  Color get _msgColor {
    switch (_msgKey) {
      case 'pz_try':
        return Colors.redAccent;
      case 'pz_good':
        return const Color(0xFF35B24A);
      default:
        return textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gridSize = widget.gridSize;
    final placed = _placed;
    final movesText = tr('pz_moves', {'n': '$_moves'});
    final subtitle =
        '${tr('lv_${widget.levelId}')} · ${gridSize}x$gridSize · $movesText';

    return Directionality(
      textDirection: dir,
      child: WillPopScope(
        onWillPop: () async {
          _exit();
          return false;
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF6F9FA),
          body: Stack(
            children: [
              Positioned.fill(
                child: LabBackdrop(
                  color: _accent,
                  emojis: [widget.emoji, '🧩', '⭐'],
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          FunRoundButton(
                            icon: Icons.arrow_back_rounded,
                            tooltip: tr('back'),
                            onTap: _exit,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.emoji} ${tr('th_${widget.themeId}')}',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: textDark,
                                  ),
                                ),
                                Text(
                                  subtitle,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FunRoundButton(
                            icon: Icons.refresh_rounded,
                            onTap: () {
                              LabSfx.play('pop');
                              setState(_setupPuzzle);
                            },
                          ),
                          const SizedBox(width: 8),
                          FunRoundButton(
                            icon: Icons.visibility_rounded,
                            onTap: _peekFlash,
                            onLongPressStart: () =>
                                setState(() => _showPeek = true),
                            onLongPressEnd: () =>
                                setState(() => _showPeek = false),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: LabProgressPill(
                        value: placed / _total,
                        label: '$placed/$_total',
                        color: _accent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 20,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          tr(_msgKey),
                          key: ValueKey<String>(_msgKey),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _msgColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      flex: 5,
                      child: Center(child: _buildBoard(gridSize)),
                    ),
                    const SizedBox(height: 6),
                    if (_tray.isEmpty)
                      const SizedBox(height: 90)
                    else
                      Expanded(
                        flex: 3,
                        child: LabShake(
                          trigger: _shake,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: SingleChildScrollView(
                              child: SizedBox(
                                width: double.infinity,
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    for (var i = 0; i < _tray.length; i++)
                                      _TrayPiece(
                                        key: ValueKey<String>(
                                            '$_round-${_tray[i]}'),
                                        pieceIndex: _tray[i],
                                        order: i,
                                        gridSize: gridSize,
                                        gradientColors: widget.gradientColors,
                                        emoji: widget.emoji,
                                        idle: _idle,
                                        onStart: () {
                                          LabSfx.play('pop', volume: 0.6);
                                          LabSfx.tap();
                                        },
                                        onMissed: _onPieceMissed,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: LabChunkyButton(
                          color: _accent,
                          onTap: _tray.isEmpty ? null : _useHint,
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lightbulb_rounded,
                                    size: 18, color: Colors.white),
                                const SizedBox(width: 8),
                                Flexible(child: Text(tr('pz_hint_btn'))),
                              ],
                            ),
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
      ),
    );
  }

  Widget _buildBoard(int gridSize) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = min(
          constraints.maxWidth - 32,
          constraints.maxHeight - 16,
        );
        const pad = 6.0;
        const gap = 3.0;
        final cell = (boardSize - pad * 2 - gap * (gridSize - 1)) / gridSize;
        final cx = pad + (_lastSlot % gridSize) * (cell + gap) + cell / 2;
        final cy = pad + (_lastSlot ~/ gridSize) * (cell + gap) + cell / 2;

        // The picture slices assume left-to-right, so the board is always LTR
        // (even in Arabic), otherwise the picture would come out mirrored.
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: boardSize,
                height: boardSize,
                padding: const EdgeInsets.all(pad),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withOpacity(0.2),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridSize,
                    mainAxisSpacing: gap,
                    crossAxisSpacing: gap,
                  ),
                  itemCount: _total,
                  itemBuilder: (context, slotIndex) {
                    return _PuzzleSlot(
                      slotIndex: slotIndex,
                      gridSize: gridSize,
                      placedPiece: _board[slotIndex],
                      gradientColors: widget.gradientColors,
                      emoji: widget.emoji,
                      onPieceDropped: _onPieceDropped,
                    );
                  },
                ),
              ),
              // Peek: the full picture fades in / out
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    opacity: _showPeek ? 1 : 0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: widget.gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.emoji,
                        style: TextStyle(fontSize: boardSize * 0.5),
                      ),
                    ),
                  ),
                ),
              ),
              // Sparkles where the last piece landed
              Positioned(
                left: cx - 90,
                top: cy - 90,
                width: 180,
                height: 180,
                child: LabBurst(
                  trigger: _burst,
                  colors: [
                    ...widget.gradientColors,
                    Colors.white,
                    Colors.amber,
                  ],
                  count: 16,
                  distance: 54,
                  gravity: 24,
                  size: 4.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Renders the slice of the full picture that belongs at [row, col] out of
/// a [gridSize] x [gridSize] board (Align + OverflowBox trick).
class _PuzzlePieceSlice extends StatelessWidget {
  final int row;
  final int col;
  final int gridSize;
  final List<Color> gradientColors;
  final String emoji;

  const _PuzzlePieceSlice({
    required this.row,
    required this.col,
    required this.gridSize,
    required this.gradientColors,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final alignX = gridSize == 1 ? 0.0 : -1 + col * (2 / (gridSize - 1));
    final alignY = gridSize == 1 ? 0.0 : -1 + row * (2 / (gridSize - 1));

    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final canvasW = constraints.maxWidth * gridSize;
          final canvasH = constraints.maxHeight * gridSize;
          return OverflowBox(
            maxWidth: canvasW,
            maxHeight: canvasH,
            minWidth: canvasW,
            minHeight: canvasH,
            alignment: Alignment(alignX, alignY),
            child: Container(
              width: canvasW,
              height: canvasH,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: TextStyle(fontSize: canvasW * 0.62)),
            ),
          );
        },
      ),
    );
  }
}

class _PuzzleSlot extends StatelessWidget {
  final int slotIndex;
  final int gridSize;
  final int? placedPiece;
  final List<Color> gradientColors;
  final String emoji;
  final void Function(int pieceIndex, int slotIndex) onPieceDropped;

  const _PuzzleSlot({
    required this.slotIndex,
    required this.gridSize,
    required this.placedPiece,
    required this.gradientColors,
    required this.emoji,
    required this.onPieceDropped,
  });

  @override
  Widget build(BuildContext context) {
    final row = slotIndex ~/ gridSize;
    final col = slotIndex % gridSize;

    if (placedPiece != null) {
      // The piece "snaps" into place with a springy pop.
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 1.35, end: 1.0),
        duration: const Duration(milliseconds: 650),
        curve: Curves.elasticOut,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: _PuzzlePieceSlice(
            row: row,
            col: col,
            gridSize: gridSize,
            gradientColors: gradientColors,
            emoji: emoji,
          ),
        ),
      );
    }

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data == slotIndex,
      onAcceptWithDetails: (details) => onPieceDropped(details.data, slotIndex),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        final isRejecting = rejectedData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isHovering
                ? gradientColors.last.withOpacity(0.18)
                : const Color(0xFFF0F3F4),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isRejecting
                  ? Colors.redAccent.withOpacity(0.6)
                  : isHovering
                  ? gradientColors.last
                  : Colors.grey.shade300,
              width: isHovering || isRejecting ? 2 : 1,
            ),
          ),
        );
      },
    );
  }
}

class _TrayPiece extends StatelessWidget {
  final int pieceIndex;
  final int order;
  final int gridSize;
  final List<Color> gradientColors;
  final String emoji;
  final Animation<double> idle;
  final VoidCallback onStart;
  final VoidCallback onMissed;

  const _TrayPiece({
    super.key,
    required this.pieceIndex,
    required this.order,
    required this.gridSize,
    required this.gradientColors,
    required this.emoji,
    required this.idle,
    required this.onStart,
    required this.onMissed,
  });

  @override
  Widget build(BuildContext context) {
    final row = pieceIndex ~/ gridSize;
    final col = pieceIndex % gridSize;
    const size = 56.0;

    final piece = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: size,
        height: size,
        child: _PuzzlePieceSlice(
          row: row,
          col: col,
          gridSize: gridSize,
          gradientColors: gradientColors,
          emoji: emoji,
        ),
      ),
    );

    final draggable = Draggable<int>(
      data: pieceIndex,
      onDragStarted: onStart,
      onDraggableCanceled: (_, __) => onMissed(),
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(scale: 1.2, child: piece),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: piece),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: piece,
      ),
    );

    // Pieces pop in one by one, then wiggle gently ("pick me!").
    return FunPopIn(
      delayMs: min(order, 8) * 50,
      child: AnimatedBuilder(
        animation: idle,
        child: draggable,
        builder: (context, child) {
          final t = idle.value * 2 * pi + pieceIndex * 0.9;
          return Transform.translate(
            offset: Offset(0, sin(t) * 2.5),
            child: Transform.rotate(angle: sin(t * 0.9) * 0.05, child: child),
          );
        },
      ),
    );
  }
}