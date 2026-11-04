import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_ui.dart';
import '../../core/ui/kid_ui.dart';
import '../../data/models/adventure_model.dart';
import '../../data/providers/progress_provider.dart';
import '../alphabet/alphabet_screen.dart';
import '../draw/paint_screen.dart';
import '../math/mathexercice.dart';
import '../numbers/number_screen.dart';
import '../puzzle/puzzle_screen.dart';
import '../stories/story_reading_screen.dart';

TextStyle _fredoka({
  double size = 15,
  Color color = KidColors.textDark,
  FontWeight weight = FontWeight.w700,
  double? letterSpacing,
}) =>
    GoogleFonts.fredoka(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
    );

const Color _starGold = Color(0xFFFFB300);
const Color _doneGreen = Color(0xFF35B24A);

class LearningAdventureScreen extends StatelessWidget {
  const LearningAdventureScreen({super.key});

  void _openWorldSheet(BuildContext context, LearningWorld world) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WorldLevelsSheet(worldId: world.id, fallback: world),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final worlds = progress.worlds;

    return Scaffold(
      body: KidBackground(
        colors: const [Color(0xFFD5F5DF), KidColors.cream],
        child: SafeArea(
          child: Column(
            children: [
              const KidHeader(
                title: 'My Adventure Map',
                emoji: '🗺️',
                subtitle: 'Explore worlds and earn stars!',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _StarsPill(stars: progress.profile.totalStars),
                ),
              ),
              Expanded(
                child: worlds.isEmpty
                    ? const EmptyState(
                  emoji: '🗺️',
                  title: 'No worlds yet',
                  message: 'New adventures are on their way!',
                )
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
                  itemCount: worlds.length,
                  itemBuilder: (context, index) {
                    final world = worlds[index];
                    final leftAligned = index.isEven;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Column(
                        children: [
                          Align(
                            alignment: leftAligned
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: _WorldCardNode(
                              world: world,
                              stage: index + 1,
                              onTap: () =>
                                  _openWorldSheet(context, world),
                            ),
                          ),
                          if (index < worlds.length - 1)
                            _ConnectorPath(
                              leftToRight: leftAligned,
                              color: world.gradientColors.last,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- stars pill

class _StarsPill extends StatelessWidget {
  final int stars;
  const _StarsPill({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _starGold, width: 3),
        boxShadow: [
          BoxShadow(
            color: _starGold.withOpacity(0.55),
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⭐', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Text('$stars', style: _fredoka(size: 18, weight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- world card

class _WorldCardNode extends StatefulWidget {
  final LearningWorld world;
  final int stage;
  final VoidCallback onTap;

  const _WorldCardNode({
    required this.world,
    required this.stage,
    required this.onTap,
  });

  @override
  State<_WorldCardNode> createState() => _WorldCardNodeState();
}

class _WorldCardNodeState extends State<_WorldCardNode> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const depth = 7.0;
    final world = widget.world;
    final levelsDone = world.levels.where((l) => l.isCompleted).length;
    final levelsTotal = world.levels.length;
    final offset = _down ? 2.0 : depth;

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.72,
      child: GestureDetector(
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: world.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border:
              Border.all(color: Colors.white.withOpacity(0.55), width: 3),
              boxShadow: [
                BoxShadow(
                  color: KidColors.darken(world.gradientColors.last),
                  offset: Offset(0, offset),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.28),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.7), width: 3),
                  ),
                  child: Text(world.emoji, style: const TextStyle(fontSize: 32)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WORLD ${widget.stage}',
                        style: _fredoka(
                          size: 11,
                          color: Colors.white.withOpacity(0.85),
                          weight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        world.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _fredoka(
                            size: 18,
                            color: Colors.white,
                            weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '⭐ ${world.currentStars} / ${world.totalStarsPossible}'
                            '  •  $levelsDone/$levelsTotal levels',
                        style: _fredoka(
                            size: 12,
                            color: Colors.white.withOpacity(0.92),
                            weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(end: world.progressRatio),
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutCubic,
                            builder: (_, value, __) => Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: value.clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
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
      ),
    );
  }
}

/// Dashed S-curve between two world cards that draws itself on first build.
class _ConnectorPath extends StatelessWidget {
  final bool leftToRight;
  final Color color;

  const _ConnectorPath({required this.leftToRight, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      width: double.infinity,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOut,
        builder: (_, t, __) => CustomPaint(
          painter: _PathPainter(
            leftToRight: leftToRight,
            color: color.withOpacity(0.6),
            progress: t,
          ),
        ),
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  final bool leftToRight;
  final Color color;
  final double progress;

  const _PathPainter({
    required this.leftToRight,
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Card centers sit at 36% and 64% of the width (cards are 72% wide).
    final startX = size.width * (leftToRight ? 0.36 : 0.64);
    final endX = size.width * (leftToRight ? 0.64 : 0.36);

    final path = Path()
      ..moveTo(startX, 0)
      ..cubicTo(startX, size.height * 0.5, endX, size.height * 0.5, endX,
          size.height);

    const dash = 9.0;
    const gap = 8.0;
    for (final metric in path.computeMetrics()) {
      final limit = metric.length * progress;
      var distance = 0.0;
      while (distance < limit) {
        final end = math.min(distance + dash, limit);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) =>
      old.progress != progress ||
          old.color != color ||
          old.leftToRight != leftToRight;
}

// ------------------------------------------------------------ levels sheet

class _WorldLevelsSheet extends StatelessWidget {
  final String worldId;
  final LearningWorld fallback;

  const _WorldLevelsSheet({required this.worldId, required this.fallback});

  /// Maps each level to its real activity. Returns null when none exists yet.
  Widget? _activityFor(LearningWorld world, WorldLevel level) {
    switch (world.id) {
      case 'alphabet_world':
        return const AlphabetScreen();
      case 'number_kingdom':
        return level.title.contains('Addition')
            ? const MathExerciseScreen()
            : const NumberScreen();
      case 'colors_shapes':
        return const PaintScreen();
      case 'puzzle_island':
        return const PuzzleScreen();
      case 'story_forest':
        return const StoryReadingScreen();
      default:
        return null;
    }
  }

  /// Opens the activity. Stars are only earned from real progress inside it,
  /// so the level is completed from the star gain measured on return.
  Future<void> _playLevel(
      BuildContext context,
      LearningWorld world,
      WorldLevel level,
      ) async {
    final messenger = ScaffoldMessenger.of(context);
    final progress = context.read<ProgressProvider>();

    final activity = _activityFor(world, level);
    if (activity == null) {
      showAppSnack(messenger, '🚧 This level is coming soon!');
      return;
    }

    final starsBefore = progress.profile.totalStars;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => activity),
    );

    final gained = progress.profile.totalStars - starsBefore;
    if (gained <= 0) return;

    final levelStars = gained.clamp(1, 3);
    await progress.completeLevel(world.id, level.levelNumber, levelStars);
    showAppSnack(
      messenger,
      '🎉 Level ${level.levelNumber} practiced — '
          'earned $levelStars star${levelStars == 1 ? '' : 's'}!',
      color: world.gradientColors.last,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watching keeps the sheet in sync after the child finishes an activity.
    final progress = context.watch<ProgressProvider>();
    final world = progress.worlds.firstWhere(
          (w) => w.id == worldId,
      orElse: () => fallback,
    );
    final accent = world.gradientColors.last;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
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
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: world.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.7), width: 3),
                ),
                child: Text(world.emoji, style: const TextStyle(fontSize: 30)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(world.name,
                        style: _fredoka(size: 21, weight: FontWeight.w800)),
                    Text(
                      'Levels & Challenges',
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
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: world.levels.length,
              itemBuilder: (context, i) => _LevelTile(
                level: world.levels[i],
                accent: accent,
                onTap: () => _playLevel(context, world, world.levels[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelTile extends StatefulWidget {
  final WorldLevel level;
  final Color accent;
  final VoidCallback onTap;

  const _LevelTile({
    required this.level,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_LevelTile> createState() => _LevelTileState();
}

class _LevelTileState extends State<_LevelTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const depth = 5.0;
    final level = widget.level;
    final unlocked = level.isUnlocked;
    final done = level.isCompleted;
    final accent = unlocked ? (done ? _doneGreen : widget.accent) : Colors.grey;
    final offset = (_down && unlocked) ? 2.0 : depth;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: unlocked ? (_) => setState(() => _down = true) : null,
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: unlocked ? widget.onTap : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          transform: Matrix4.translationValues(0, depth - offset, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: unlocked
                ? (done ? KidColors.lighten(_doneGreen, 0.5) : Colors.white)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accent.withOpacity(unlocked ? 0.5 : 0.35),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(unlocked ? 0.5 : 0.3),
                offset: Offset(0, offset),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: unlocked ? accent : Colors.grey.shade300,
                  boxShadow: [
                    BoxShadow(
                      color: unlocked
                          ? KidColors.darken(accent)
                          : Colors.grey.shade400,
                      offset: const Offset(0, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  '${level.levelNumber}',
                  style: _fredoka(
                      size: 19, color: Colors.white, weight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.title,
                      style: _fredoka(
                        size: 16,
                        weight: FontWeight.w800,
                        color: unlocked
                            ? KidColors.textDark
                            : Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      level.description,
                      style: _fredoka(
                          size: 12.5,
                          color: KidColors.textMuted,
                          weight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (done)
                const Icon(Icons.check_circle_rounded,
                    color: _doneGreen, size: 30)
              else if (!unlocked)
                const Icon(Icons.lock_rounded, color: Colors.grey, size: 22)
              else
                Icon(Icons.play_circle_fill_rounded,
                    color: widget.accent, size: 34),
            ],
          ),
        ),
      ),
    );
  }
}