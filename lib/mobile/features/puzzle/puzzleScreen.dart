import 'package:flutter/material.dart';
import 'package:kinderkids/mobile/features/puzzle/puzzlegame.dart';


/// Puzzle picker screen: lets kids pick a theme (lots of choices!) and
/// then a difficulty level, so there are plenty of puzzles to play.
///
/// Same visual language as HomeScreen (background artwork + soft white
/// wash, rounded cards, playful colors).
class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  // --- Design tokens (matches HomeScreen) --------------------------------
  static const Color primaryBlue = Color(0xFF0F92CA);
  static const Color primaryBlueDark = Color(0xFF0B6E9B);
  static const Color textDark = Color(0xFF213238);
  static const Color textMuted = Color(0xFF7C8C93);
  // ------------------------------------------------------------------------

  /// Session-only record of which "theme|level" combos have been solved,
  /// so kids get a little ✓ badge for puzzles they've already completed.
  final Set<String> _completed = {};

  static const List<_PuzzleTheme> _themes = [
    _PuzzleTheme('Animals', '🦁', [Color(0xFFFFC15E), Color(0xFFF2994A)]),
    _PuzzleTheme('Fruits', '🍎', [Color(0xFFFF9D6C), Color(0xFFF25C54)]),
    _PuzzleTheme('Ocean', '🐠', [Color(0xFF6FD3F7), Color(0xFF3AAAE0)]),
    _PuzzleTheme('Space', '🚀', [Color(0xFFB48CF2), Color(0xFF8B5CF6)]),
    _PuzzleTheme('Dinosaurs', '🦕', [Color(0xFF6EE7B7), Color(0xFF2FBF8F)]),
    _PuzzleTheme('Vehicles', '🚗', [Color(0xFF7CC5FF), primaryBlueDark]),
    _PuzzleTheme('Insects', '🐞', [Color(0xFFFF8FA3), Color(0xFFE0507B)]),
    _PuzzleTheme('Weather', '⛅', [Color(0xFFFFE08A), Color(0xFFE0A800)]),
  ];

  static const List<_PuzzleLevel> _levels = [
    _PuzzleLevel('Easy', 2, '🟢'),
    _PuzzleLevel('Medium', 3, '🟡'),
    _PuzzleLevel('Hard', 4, '🔴'),
  ];

  void _pickLevel(BuildContext context, _PuzzleTheme theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _LevelSheet(
        theme: theme,
        levels: _levels,
        completed: _completed,
        onLevelChosen: (level) async {
          Navigator.of(sheetContext).pop();
          final solved = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => PuzzleGameScreen(
                themeLabel: theme.label,
                emoji: theme.emoji,
                gradientColors: theme.colors,
                gridSize: level.gridSize,
                levelLabel: level.label,
              ),
            ),
          );
          if (solved == true) {
            setState(() {
              _completed.add('${theme.label}|${level.label}');
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                              'Puzzles 🧩',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: textDark,
                              ),
                            ),
                            Text(
                              'Pick a picture and a level!',
                              style: TextStyle(fontSize: 12.5, color: textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    itemCount: _themes.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.95,
                    ),
                    itemBuilder: (context, index) {
                      final theme = _themes[index];
                      final solvedCount = _levels
                          .where((l) => _completed.contains('${theme.label}|${l.label}'))
                          .length;
                      return _ThemeCard(
                        theme: theme,
                        solvedCount: solvedCount,
                        totalLevels: _levels.length,
                        onTap: () => _pickLevel(context, theme),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PuzzleTheme {
  final String label;
  final String emoji;
  final List<Color> colors;
  const _PuzzleTheme(this.label, this.emoji, this.colors);
}

class _PuzzleLevel {
  final String label;
  final int gridSize;
  final String badge;
  const _PuzzleLevel(this.label, this.gridSize, this.badge);
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
          child: Icon(icon, color: _PuzzleScreenState.primaryBlue, size: 20),
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final _PuzzleTheme theme;
  final int solvedCount;
  final int totalLevels;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.theme,
    required this.solvedCount,
    required this.totalLevels,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
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
                child: Text(theme.emoji, style: const TextStyle(fontSize: 46)),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 14,
                child: Text(
                  theme.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              if (solvedCount > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '✓ $solvedCount/$totalLevels',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: theme.colors.last,
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
    return Container(
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
              Text(theme.emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 10),
              Text(
                '${theme.label} puzzle',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _PuzzleScreenState.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'How many pieces?',
            style: TextStyle(fontSize: 13, color: _PuzzleScreenState.textMuted),
          ),
          const SizedBox(height: 16),
          ...levels.map((level) {
            final pieces = level.gridSize * level.gridSize;
            final isDone = completed.contains('${theme.label}|${level.label}');
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: const Color(0xFFF4F7F8),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onLevelChosen(level),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Text(level.badge, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                level.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                  color: _PuzzleScreenState.textDark,
                                ),
                              ),
                              Text(
                                '${level.gridSize} x ${level.gridSize} — $pieces pieces',
                                style: TextStyle(
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
                          Icon(Icons.chevron_right_rounded,
                              color: _PuzzleScreenState.textMuted, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}