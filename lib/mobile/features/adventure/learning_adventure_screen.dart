import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_ui.dart';
import '../../data/models/adventure_model.dart';
import '../../data/providers/progress_provider.dart';
import '../alphabet/alphabet_screen.dart';
import '../draw/paint_screen.dart';
import '../math/mathexercice.dart';
import '../numbers/number_screen.dart';
import '../puzzle/puzzle_screen.dart';
import '../stories/story_reading_screen.dart';

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
      body: ScreenBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Adventure Map 🗺️',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            'Explore worlds and earn stars!',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StarsChip(stars: progress.profile.totalStars, large: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: worlds.isEmpty
                    ? const EmptyState(
                  emoji: '🗺️',
                  title: 'No worlds yet',
                  message: 'New adventures are on their way!',
                )
                    : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  itemCount: worlds.length,
                  itemBuilder: (context, index) {
                    final world = worlds[index];
                    final leftAligned = index.isEven;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
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

class _WorldCardNode extends StatelessWidget {
  final LearningWorld world;
  final int stage;
  final VoidCallback onTap;

  const _WorldCardNode({
    required this.world,
    required this.stage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final levelsDone = world.levels.where((l) => l.isCompleted).length;
    final levelsTotal = world.levels.length;

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.72,
      child: GradientCard(
        colors: world.gradientColors,
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.25),
              ),
              child: Text(world.emoji, style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WORLD $stage',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    world.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '⭐ ${world.currentStars} / ${world.totalStarsPossible}'
                        '  •  $levelsDone/$levelsTotal levels',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: world.progressRatio),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (_, value, __) => LinearProgressIndicator(
                        value: value,
                        backgroundColor: Colors.white24,
                        color: Colors.white,
                        minHeight: 6,
                      ),
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

/// Dashed S-curve between two world cards that draws itself on first build.
class _ConnectorPath extends StatelessWidget {
  final bool leftToRight;
  final Color color;

  const _ConnectorPath({required this.leftToRight, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: double.infinity,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOut,
        builder: (_, t, __) => CustomPaint(
          painter: _PathPainter(
            leftToRight: leftToRight,
            color: color.withOpacity(0.55),
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
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Card centers sit at 36% and 64% of the width (cards are 72% wide).
    final startX = size.width * (leftToRight ? 0.36 : 0.64);
    final endX = size.width * (leftToRight ? 0.64 : 0.36);

    final path = Path()
      ..moveTo(startX, 0)
      ..cubicTo(startX, size.height * 0.5, endX, size.height * 0.5, endX,
          size.height);

    const dash = 8.0;
    const gap = 7.0;
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

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
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
              Text(world.emoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      world.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const Text(
                      'Levels & Challenges',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: world.levels.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _LevelTile(
                level: world.levels[i],
                accent: world.gradientColors.last,
                onTap: () => _playLevel(context, world, world.levels[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final WorldLevel level;
  final Color accent;
  final VoidCallback onTap;

  const _LevelTile({
    required this.level,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = level.isUnlocked;

    return Material(
      color: unlocked ? const Color(0xFFF6F9FA) : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: unlocked ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: unlocked ? accent : Colors.grey.shade300,
                ),
                child: Text(
                  '${level.levelNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: unlocked
                            ? AppColors.textDark
                            : Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      level.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (level.isCompleted)
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 26)
              else if (!unlocked)
                const Icon(Icons.lock_rounded, color: Colors.grey, size: 20)
              else
                Icon(Icons.play_circle_fill_rounded, color: accent, size: 30),
            ],
          ),
        ),
      ),
    );
  }
}