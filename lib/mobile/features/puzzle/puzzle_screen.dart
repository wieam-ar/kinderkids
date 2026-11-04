import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/ui/kid_ui.dart';
import '../../data/providers/progress_provider.dart';
import '../science/fun_common.dart';
import 'puzzle_game.dart';

TextStyle _fredoka({
  double size = 15,
  Color color = KidColors.textDark,
  FontWeight weight = FontWeight.w700,
}) =>
    GoogleFonts.fredoka(fontSize: size, fontWeight: weight, color: color);

/// Puzzle picker: pick a theme, then a level. English / Français / العربية.
class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> with FunLang<PuzzleScreen> {
  static const Color primaryBlue = Color(0xFF0F92CA);
  static const Color primaryBlueDark = Color(0xFF0B6E9B);

  /// Solved "themeId|levelId" combos (ids, not translated labels, so the
  /// ✓ badges stay correct when the language changes).
  final Set<String> _completed = {};

  static const List<_PuzzleTheme> _themes = [
    _PuzzleTheme('animals', '🦁', [Color(0xFFFFC15E), Color(0xFFF2994A)]),
    _PuzzleTheme('fruits', '🍎', [Color(0xFFFF9D6C), Color(0xFFF25C54)]),
    _PuzzleTheme('ocean', '🐠', [Color(0xFF6FD3F7), Color(0xFF3AAAE0)]),
    _PuzzleTheme('space', '🚀', [Color(0xFFB48CF2), Color(0xFF8B5CF6)]),
    _PuzzleTheme('dinosaurs', '🦕', [Color(0xFF6EE7B7), Color(0xFF2FBF8F)]),
    _PuzzleTheme('vehicles', '🚗', [Color(0xFF7CC5FF), primaryBlueDark]),
    _PuzzleTheme('insects', '🐞', [Color(0xFFFF8FA3), Color(0xFFE0507B)]),
    _PuzzleTheme('weather', '⛅', [Color(0xFFFFE08A), Color(0xFFE0A800)]),
  ];

  static const List<_PuzzleLevel> _levels = [
    _PuzzleLevel('easy', 2, '🟢'),
    _PuzzleLevel('medium', 3, '🟡'),
    _PuzzleLevel('hard', 4, '🔴'),
  ];

  @override
  void initState() {
    super.initState();
    LabSfx.preload();
  }

  void _pickLevel(BuildContext context, _PuzzleTheme theme) {
    LabSfx.play('pop');
    LabSfx.tap();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _LevelSheet(
        theme: theme,
        levels: _levels,
        completed: _completed,
        onLevelChosen: (level) async {
          Navigator.of(sheetContext).pop();
          final solved = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => PuzzleGameScreen(
                themeId: theme.id,
                emoji: theme.emoji,
                gradientColors: theme.colors,
                gridSize: level.gridSize,
                levelId: level.id,
              ),
            ),
          );
          if (!mounted) return;
          if (solved == true) {
            setState(() => _completed.add('${theme.id}|${level.id}'));
            // Feed the learning-progress system.
            // ignore: use_build_context_synchronously
            final progress =
            Provider.of<ProgressProvider>(context, listen: false);
            progress.addStars(5);
            progress.incrementChallengeProgress('puzzle');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _themes.length * _levels.length;

    return Directionality(
      textDirection: dir,
      child: Scaffold(
        backgroundColor: KidColors.cream,
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/splash_background.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: KidColors.cream),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      KidColors.cream.withOpacity(0.6),
                      KidColors.cream.withOpacity(0.9),
                      KidColors.cream.withOpacity(0.98),
                    ],
                    stops: const [0.0, 0.3, 0.6],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KidHeader(
                    title: tr('pz_title'),
                    emoji: '🧩',
                    subtitle: tr('pz_sub'),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: LabLangBar(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: LabProgressPill(
                      value: _completed.length / total,
                      label: '${_completed.length}/$total 🧩',
                      color: primaryBlue,
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                      itemCount: _themes.length,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.92,
                      ),
                      itemBuilder: (context, index) {
                        final theme = _themes[index];
                        final solvedCount = _levels
                            .where((l) =>
                            _completed.contains('${theme.id}|${l.id}'))
                            .length;
                        return FunPopIn(
                          delayMs: index * 70,
                          child: _ThemeCard(
                            theme: theme,
                            index: index,
                            solvedCount: solvedCount,
                            totalLevels: _levels.length,
                            onTap: () => _pickLevel(context, theme),
                          ),
                        );
                      },
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

class _PuzzleTheme {
  final String id;
  final String emoji;
  final List<Color> colors;
  const _PuzzleTheme(this.id, this.emoji, this.colors);
}

class _PuzzleLevel {
  final String id;
  final int gridSize;
  final String badge;
  const _PuzzleLevel(this.id, this.gridSize, this.badge);
}

// -------------------------------------------------------------- theme card

class _ThemeCard extends StatefulWidget {
  final _PuzzleTheme theme;
  final int index;
  final int solvedCount;
  final int totalLevels;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.theme,
    required this.index,
    required this.solvedCount,
    required this.totalLevels,
    required this.onTap,
  });

  @override
  State<_ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends State<_ThemeCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const depth = 7.0;
    final theme = widget.theme;
    final solvedCount = widget.solvedCount;
    final allDone = solvedCount == widget.totalLevels;
    final offset = _down ? 2.0 : depth;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: depth),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          transform: Matrix4.translationValues(0, depth - offset, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: theme.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border:
            Border.all(color: Colors.white.withOpacity(0.55), width: 3),
            boxShadow: [
              BoxShadow(
                color: KidColors.darken(theme.colors.last),
                offset: Offset(0, offset),
                blurRadius: 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              Align(
                alignment: const Alignment(0, -0.25),
                child: Container(
                  width: 84,
                  height: 84,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.28),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.7), width: 3),
                  ),
                  child: FunBounce(
                    amplitude: 6,
                    seconds: 1.8,
                    phase: (widget.index * 0.14) % 1.0,
                    child:
                    Text(theme.emoji, style: const TextStyle(fontSize: 44)),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 14,
                child: Text(
                  ft('th_${theme.id}'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _fredoka(
                      size: 17, color: Colors.white, weight: FontWeight.w800),
                ),
              ),
              if (solvedCount > 0)
                PositionedDirectional(
                  top: 10,
                  end: 10,
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey<int>(solvedCount),
                    tween: Tween<double>(begin: 0.3, end: 1.0),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    builder: (context, s, child) =>
                        Transform.scale(scale: s, child: child),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                        allDone ? const Color(0xFFFFF3B0) : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            offset: const Offset(0, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Text(
                        allDone
                            ? '🏆 $solvedCount/${widget.totalLevels}'
                            : '✓ $solvedCount/${widget.totalLevels}',
                        style: _fredoka(
                            size: 12,
                            color: theme.colors.last,
                            weight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- level sheet

/// Bottom sheet shown when a theme is tapped: choose Easy / Medium / Hard.
class _LevelSheet extends StatelessWidget {
  final _PuzzleTheme theme;
  final List<_PuzzleLevel> levels;
  final Set<String> completed;
  final ValueChanged<_PuzzleLevel> onLevelChosen;

  const _LevelSheet({
    required this.theme,
    required this.levels,
    required this.completed,
    required this.onLevelChosen,
  });

  Color _levelColor(String id) {
    switch (id) {
      case 'easy':
        return const Color(0xFF35B24A);
      case 'medium':
        return const Color(0xFFFFB300);
      default:
        return const Color(0xFFFF6B5E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = theme.colors.last;
    return Directionality(
      textDirection: LabI18n.instance.direction,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        decoration: BoxDecoration(
          color: KidColors.cream,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
          border: Border(top: BorderSide(color: accent, width: 5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: theme.colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.7), width: 3),
                  ),
                  child: FunBounce(
                    amplitude: 4,
                    child:
                    Text(theme.emoji, style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${ft('th_${theme.id}')} · ${ft('pz_level')}',
                        style: _fredoka(size: 20, weight: FontWeight.w800),
                      ),
                      Text(
                        ft('pz_pieces_q'),
                        style: _fredoka(
                            size: 13,
                            color: KidColors.textMuted,
                            weight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            for (var i = 0; i < levels.length; i++)
              FunPopIn(
                delayMs: 80 * i,
                child: _LevelRow(
                  level: levels[i],
                  color: _levelColor(levels[i].id),
                  isDone: completed.contains('${theme.id}|${levels[i].id}'),
                  onTap: () {
                    LabSfx.tap();
                    onLevelChosen(levels[i]);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LevelRow extends StatefulWidget {
  final _PuzzleLevel level;
  final Color color;
  final bool isDone;
  final VoidCallback onTap;

  const _LevelRow({
    required this.level,
    required this.color,
    required this.isDone,
    required this.onTap,
  });

  @override
  State<_LevelRow> createState() => _LevelRowState();
}

class _LevelRowState extends State<_LevelRow> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const depth = 5.0;
    final level = widget.level;
    final color = widget.color;
    final pieces = level.gridSize * level.gridSize;
    final offset = _down ? 2.0 : depth;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10 + depth - 5),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          transform: Matrix4.translationValues(0, depth - offset, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isDone ? KidColors.lighten(color, 0.5) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: color.withOpacity(widget.isDone ? 0.9 : 0.45),
                width: 3),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                offset: Offset(0, offset),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: KidColors.lighten(color, 0.5),
                ),
                child: Text(level.badge, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ft('lv_${level.id}'),
                      style: _fredoka(size: 17, weight: FontWeight.w800),
                    ),
                    Text(
                      '${level.gridSize} x ${level.gridSize} — ${ft('pz_pieces', {'n': '$pieces'})}',
                      style: _fredoka(
                          size: 12.5,
                          color: KidColors.textMuted,
                          weight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isDone ? const Color(0xFF35B24A) : color,
                  boxShadow: [
                    BoxShadow(
                      color: KidColors.darken(
                          widget.isDone ? const Color(0xFF35B24A) : color),
                      offset: const Offset(0, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  widget.isDone
                      ? Icons.check_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}