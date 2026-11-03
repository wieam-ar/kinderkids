import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/providers/progress_provider.dart';
import '../science/fun_common.dart';
import 'puzzle_game.dart';

/// Puzzle picker: pick a theme, then a level. English / Français / العربية.
class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> with FunLang<PuzzleScreen> {
  static const Color primaryBlue = Color(0xFF0F92CA);
  static const Color primaryBlueDark = Color(0xFF0B6E9B);
  static const Color textDark = Color(0xFF213238);
  static const Color textMuted = Color(0xFF7C8C93);

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
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/splash_background.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.white),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.55),
                      Colors.white.withOpacity(0.85),
                      Colors.white.withOpacity(0.97),
                    ],
                    stops: const [0.0, 0.35, 0.65],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Row(
                      children: [
                        FunRoundButton(
                          icon: Icons.arrow_back_rounded,
                          tooltip: tr('back'),
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${tr('pz_title')} 🧩',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: textDark,
                                ),
                              ),
                              Text(
                                tr('pz_sub'),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
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
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      itemCount: _themes.length,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.95,
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

class _ThemeCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final allDone = solvedCount == totalLevels;
    return FunPressable(
      onTap: onTap,
      pressedScale: 0.94,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: theme.colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colors.last.withOpacity(0.32),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: FunBounce(
                amplitude: 7,
                seconds: 1.8,
                phase: (index * 0.14) % 1.0,
                child: Text(theme.emoji, style: const TextStyle(fontSize: 46)),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: Text(
                ft('th_${theme.id}'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
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
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: allDone ? const Color(0xFFFFF3B0) : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      allDone ? '🏆 $solvedCount/$totalLevels' : '✓ $solvedCount/$totalLevels',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: theme.colors.last,
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: LabI18n.instance.direction,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FunBounce(
                  amplitude: 5,
                  child: Text(theme.emoji, style: const TextStyle(fontSize: 30)),
                ),
                const SizedBox(width: 10),
                Text(
                  '${ft('th_${theme.id}')} · ${ft('pz_level')}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _PuzzleScreenState.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              ft('pz_pieces_q'),
              style: const TextStyle(
                fontSize: 13,
                color: _PuzzleScreenState.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < levels.length; i++)
              FunPopIn(
                delayMs: 80 * i,
                child: _levelRow(levels[i]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _levelRow(_PuzzleLevel level) {
    final pieces = level.gridSize * level.gridSize;
    final isDone = completed.contains('${theme.id}|${level.id}');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FunPressable(
        onTap: () {
          LabSfx.tap();
          onLevelChosen(level);
        },
        pressedScale: 0.97,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7F8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDone
                  ? const Color(0xFF35B24A).withOpacity(0.5)
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Text(level.badge, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ft('lv_${level.id}'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: _PuzzleScreenState.textDark,
                      ),
                    ),
                    Text(
                      '${level.gridSize} x ${level.gridSize} — ${ft('pz_pieces', {'n': '$pieces'})}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _PuzzleScreenState.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDone)
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF35B24A), size: 22)
              else
                const Icon(Icons.chevron_right_rounded,
                    color: _PuzzleScreenState.textMuted, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}