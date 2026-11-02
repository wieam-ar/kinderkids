import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_ui.dart';
import '../../core/ui/parent_gate.dart';
import '../../data/models/daily_challenge_model.dart';
import '../../data/providers/progress_provider.dart';
import '../alphabet/alphabet_screen.dart';
import '../challenges/daily_challenges_screen.dart';
import '../draw/draw_screen.dart';
import '../draw/paint_screen.dart';
import '../math/mathexercice.dart';
import '../music/music_screen.dart';
import '../numbers/number_screen.dart';
import '../parent/parent_dashboard_screen.dart';
import '../puzzle/puzzle_screen.dart';
import '../science/science_lab_screen.dart';
import '../stories/story_reading_screen.dart';
import '../video/video_screen.dart';

class _DiscoverItem {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color accentColor;
  final WidgetBuilder builder;

  const _DiscoverItem({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.accentColor,
    required this.builder,
  });
}

class _ExerciseItem {
  final String label;
  final IconData icon;
  final List<Color> colors;
  final WidgetBuilder builder;

  const _ExerciseItem({
    required this.label,
    required this.icon,
    required this.colors,
    required this.builder,
  });
}

final List<_DiscoverItem> _discoverItems = [
  _DiscoverItem(
    label: 'Story',
    icon: Icons.menu_book_rounded,
    bgColor: const Color(0xFFFCE4EC),
    accentColor: const Color(0xFFE0507B),
    builder: (_) => const StoryReadingScreen(),
  ),
  _DiscoverItem(
    label: 'Music',
    icon: Icons.music_note_rounded,
    bgColor: const Color(0xFFE2F7E6),
    accentColor: AppColors.success,
    builder: (_) => const MusicScreen(),
  ),
  _DiscoverItem(
    label: 'Videos',
    icon: Icons.play_arrow_rounded,
    bgColor: const Color(0xFFFDF3D9),
    accentColor: const Color(0xFFE0A800),
    builder: (_) => const VideosScreen(),
  ),
];

final List<_ExerciseItem> _exerciseItems = [
  _ExerciseItem(
    label: 'Paint',
    icon: Icons.palette_rounded,
    colors: const [Color(0xFFFF9D6C), Color(0xFFF25C54)],
    builder: (_) => const PaintScreen(),
  ),
  _ExerciseItem(
    label: 'Draw',
    icon: Icons.edit_rounded,
    colors: const [Color(0xFF6FD3F7), Color(0xFF3AAAE0)],
    builder: (_) => const DrawScreen(),
  ),
  _ExerciseItem(
    label: 'Math',
    icon: Icons.calculate_rounded,
    colors: const [Color(0xFFB48CF2), AppColors.purple],
    builder: (_) => const MathExerciseScreen(),
  ),
  _ExerciseItem(
    label: 'Puzzle',
    icon: Icons.extension_rounded,
    colors: const [Color(0xFF6EE7B7), Color(0xFF2FBF8F)],
    builder: (_) => const PuzzleScreen(),
  ),
  _ExerciseItem(
    label: 'Alphabet',
    icon: Icons.abc_rounded,
    colors: const [Color(0xFFFFC15E), Color(0xFFF2994A)],
    builder: (_) => const AlphabetScreen(),
  ),
  _ExerciseItem(
    label: 'Numbers',
    icon: Icons.numbers_rounded,
    colors: const [Color(0xFF7CC5FF), AppColors.primaryDark],
    builder: (_) => const NumberScreen(),
  ),
];

final _ExerciseItem _scienceItem = _ExerciseItem(
  label: 'Science Lab',
  icon: Icons.science_rounded,
  colors: const [Color(0xFF7ED9C3), Color(0xFF2FBF8F)],
  builder: (_) => const ScienceLabScreen(),
);

void _open(BuildContext context, WidgetBuilder builder) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: builder));
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _openParentArea(BuildContext context) async {
    final unlocked = await ParentGate.verify(context);
    if (!unlocked || !context.mounted) return;
    _open(context, (_) => const ParentDashboardScreen());
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final profile = progress.profile;

    return Scaffold(
      body: ScreenBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeSlideIn(
                  child: _TopBar(
                    nickname: profile.nickname,
                    avatarEmoji: profile.avatarEmoji,
                    stars: profile.totalStars,
                    onParentTap: () => _openParentArea(context),
                  ),
                ),
                const SizedBox(height: 18),
                const FadeSlideIn(index: 1, child: _HeaderBanner()),
                const SizedBox(height: 24),
                FadeSlideIn(
                  index: 2,
                  child: _DailyChallengeStrip(
                    challenges: progress.dailyChallenges,
                  ),
                ),
                const SizedBox(height: 26),
                const SectionTitle('Discover our app'),
                const SizedBox(height: 14),
                FadeSlideIn(
                  index: 3,
                  child: Row(
                    children: [
                      for (var i = 0; i < _discoverItems.length; i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        Expanded(
                          child: _DiscoverCard(
                            item: _discoverItems[i],
                            onTap: () =>
                                _open(context, _discoverItems[i].builder),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const SectionTitle('Exercises'),
                const SizedBox(height: 14),
                FadeSlideIn(
                  index: 4,
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.35,
                    children: [
                      for (final item in _exerciseItems)
                        _ExerciseTile(
                          item: item,
                          onTap: () => _open(context, item.builder),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                FadeSlideIn(
                  index: 5,
                  child: SizedBox(
                    height: 84,
                    child: _ExerciseTile(
                      item: _scienceItem,
                      wide: true,
                      onTap: () => _open(context, _scienceItem.builder),
                    ),
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

class _TopBar extends StatelessWidget {
  final String nickname;
  final String avatarEmoji;
  final int stars;
  final VoidCallback onParentTap;

  const _TopBar({
    required this.nickname,
    required this.avatarEmoji,
    required this.stars,
    required this.onParentTap,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: AppShadows.glow(AppColors.primary, 0.3),
          ),
          child: Text(avatarEmoji, style: const TextStyle(fontSize: 22)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_greeting, $nickname! 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const Text(
                'Ready to learn and play?',
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        StarsChip(stars: stars),
        const SizedBox(width: 6),
        IconButton(
          tooltip: 'Parents area',
          onPressed: onParentTap,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.9),
          ),
          icon: const Icon(
            Icons.lock_rounded,
            size: 20,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  const _HeaderBanner();

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      pressedScale: 0.98,
      onTap: () => _open(context, (_) => const StoryReadingScreen()),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadows.glow(AppColors.primary, 0.2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/header_kids.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.white,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.image_rounded,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.0),
                        Colors.black.withOpacity(0.4),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Let's go on an adventure!",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'New stories added this week',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
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

class _DailyChallengeStrip extends StatelessWidget {
  final List<DailyChallenge> challenges;

  const _DailyChallengeStrip({required this.challenges});

  @override
  Widget build(BuildContext context) {
    final total = challenges.length;
    final completed = challenges.where((c) => c.isCompleted).length;
    final claimable =
        challenges.where((c) => c.isCompleted && !c.rewardClaimed).length;

    return SoftCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _open(context, (_) => const DailyChallengesScreen()),
      child: Row(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Daily Challenges',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Text(
                      '$completed / $total done',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: total == 0 ? 0 : completed / total),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (_, value, __) => LinearProgressIndicator(
                      value: value,
                      minHeight: 7,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  claimable > 0
                      ? '🎁 $claimable reward${claimable == 1 ? '' : 's'} ready to claim!'
                      : 'Complete exercises to earn bonus stars!',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: claimable > 0 ? FontWeight.w800 : FontWeight.w500,
                    color: claimable > 0
                        ? AppColors.starDark
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _DiscoverCard extends StatelessWidget {
  final _DiscoverItem item;
  final VoidCallback onTap;

  const _DiscoverCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: item.bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: AppShadows.glow(item.accentColor, 0.2),
              ),
              child: Icon(item.icon, color: item.accentColor, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: item.accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final _ExerciseItem item;
  final VoidCallback onTap;
  final bool wide;

  const _ExerciseTile({
    required this.item,
    required this.onTap,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = Icon(item.icon, color: Colors.white, size: wide ? 36 : 32);
    final label = Text(
      item.label,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: wide ? 16 : 12.5,
      ),
    );

    return GradientCard(
      colors: item.colors,
      radius: 20,
      onTap: onTap,
      child: wide
          ? Row(
        children: [
          icon,
          const SizedBox(width: 14),
          Expanded(child: label),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: Colors.white, size: 16),
        ],
      )
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [icon, const SizedBox(height: 6), label],
      ),
    );
  }
}