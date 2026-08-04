import 'dart:math';

import 'package:flutter/material.dart';

/// A drag-and-drop jigsaw puzzle. The "picture" is a big emoji on a
/// gradient card so no extra image assets are needed — swap
/// [_PuzzlePicture] for `Image.asset(...)` later if you want real
/// artwork per theme.
class PuzzleGameScreen extends StatefulWidget {
  final String themeLabel;
  final String emoji;
  final List<Color> gradientColors;
  final int gridSize; // 2, 3 or 4
  final String levelLabel;

  const PuzzleGameScreen({
    super.key,
    required this.themeLabel,
    required this.emoji,
    required this.gradientColors,
    required this.gridSize,
    required this.levelLabel,
  });

  @override
  State<PuzzleGameScreen> createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends State<PuzzleGameScreen> {
  static const Color primaryBlue = Color(0xFF0F92CA);
  static const Color textDark = Color(0xFF213238);
  static const Color textMuted = Color(0xFF7C8C93);

  late int _total;
  late List<int?> _board; // slot index -> piece index (null if empty)
  late List<int> _tray; // shuffled piece indices waiting to be placed
  int _moves = 0;
  bool _showPeek = false;

  @override
  void initState() {
    super.initState();
    _setupPuzzle();
  }

  void _setupPuzzle() {
    _total = widget.gridSize * widget.gridSize;
    _board = List<int?>.filled(_total, null);
    _tray = List<int>.generate(_total, (i) => i)..shuffle(Random());
    _moves = 0;
  }

  bool get _isSolved => !_board.contains(null);

  void _onPieceDropped(int pieceIndex, int slotIndex) {
    setState(() {
      _tray.remove(pieceIndex);
      _board[slotIndex] = pieceIndex;
      _moves++;
    });
    if (_isSolved) {
      Future.delayed(const Duration(milliseconds: 250), _showWinDialog);
    }
  }

  void _useHint() {
    if (_tray.isEmpty) return;
    setState(() {
      final pieceIndex = _tray.first;
      _tray.removeAt(0);
      _board[pieceIndex] = pieceIndex;
      _moves++;
    });
    if (_isSolved) {
      Future.delayed(const Duration(milliseconds: 250), _showWinDialog);
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
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
              const Text('🎉', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 10),
              const Text(
                'Great job!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'You solved the ${widget.themeLabel} puzzle\nin $_moves moves!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: textMuted),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: widget.gradientColors.last),
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        setState(_setupPuzzle);
                      },
                      child: Text('Play again',
                          style: TextStyle(color: widget.gradientColors.last)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.gradientColors.last,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        Navigator.of(context).pop(true);
                      },
                      child: const Text('Choose another'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gridSize = widget.gridSize;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  _RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.emoji} ${widget.themeLabel}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                          ),
                        ),
                        Text(
                          '${widget.levelLabel} · ${gridSize}x$gridSize',
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  _RoundIconButton(
                    icon: Icons.refresh_rounded,
                    onTap: () => setState(_setupPuzzle),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onLongPressStart: (_) => setState(() => _showPeek = true),
                    onLongPressEnd: (_) => setState(() => _showPeek = false),
                    child: _RoundIconButton(
                      icon: Icons.visibility_rounded,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Hold 👁 to peek · drag pieces into place',
              style: TextStyle(fontSize: 11.5, color: textMuted),
            ),
            const SizedBox(height: 14),
            Expanded(
              flex: 5,
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final boardSize = min(
                      constraints.maxWidth - 32,
                      constraints.maxHeight - 16,
                    );
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: boardSize,
                          height: boardSize,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: widget.gradientColors.last.withOpacity(0.2),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: gridSize,
                              mainAxisSpacing: 3,
                              crossAxisSpacing: 3,
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
                        if (_showPeek)
                          Container(
                            width: boardSize,
                            height: boardSize,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: widget.gradientColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(widget.emoji,
                                style: const TextStyle(fontSize: 96)),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 6),
            if (_tray.isEmpty)
              const SizedBox(height: 90)
            else
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: _tray
                        .map((pieceIndex) => _TrayPiece(
                      pieceIndex: pieceIndex,
                      gridSize: gridSize,
                      gradientColors: widget.gradientColors,
                      emoji: widget.emoji,
                    ))
                        .toList(),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _tray.isEmpty ? null : _useHint,
                  icon: const Icon(Icons.lightbulb_rounded, size: 18),
                  label: const Text('Hint: place a piece for me'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: widget.gradientColors.last,
                    side: BorderSide(color: widget.gradientColors.last),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders the slice of the full picture that belongs at [row, col] out of
/// a [gridSize] x [gridSize] board, using the classic Align + widthFactor
/// clip trick — no real image asset required.
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
    // Alignment.x / .y run from -1 (left/top edge of the full picture) to
    // +1 (right/bottom edge). Each piece uses the slice of the picture
    // that corresponds to its row/col out of the gridSize x gridSize grid.
    final alignX = gridSize == 1 ? 0.0 : -1 + col * (2 / (gridSize - 1));
    final alignY = gridSize == 1 ? 0.0 : -1 + row * (2 / (gridSize - 1));

    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Whatever pixel size THIS piece actually renders at (a board
          // slot might be 90px, a tray piece 56px) becomes exactly
          // 1/gridSize of a full "virtual picture" canvas — so the full
          // picture is always canvasSize = pieceSize * gridSize, and the
          // OverflowBox below reveals only the correct 1/gridSize window
          // of it, in the right position.
          final pieceW = constraints.maxWidth;
          final pieceH = constraints.maxHeight;
          final canvasW = pieceW * gridSize;
          final canvasH = pieceH * gridSize;
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
              child: Text(
                emoji,
                style: TextStyle(fontSize: canvasW * 0.62),
              ),
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
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: _PuzzlePieceSlice(
          row: row,
          col: col,
          gridSize: gridSize,
          gradientColors: gradientColors,
          emoji: emoji,
        ),
      );
    }

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data == slotIndex,
      onAcceptWithDetails: (details) => onPieceDropped(details.data, slotIndex),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        final isRejecting = rejectedData.isNotEmpty;
        return Container(
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
  final int gridSize;
  final List<Color> gradientColors;
  final String emoji;

  const _TrayPiece({
    required this.pieceIndex,
    required this.gridSize,
    required this.gradientColors,
    required this.emoji,
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

    return Draggable<int>(
      data: pieceIndex,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(scale: 1.15, child: piece),
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
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: _PuzzleGameScreenState.primaryBlue, size: 20),
        ),
      ),
    );
  }
}