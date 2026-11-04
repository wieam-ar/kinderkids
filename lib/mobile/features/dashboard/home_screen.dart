import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/ui/kid_ui.dart';
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

// ---------------------------------------------------------------- data

class _HomeItem {
  final String label;
  final String emoji;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;

  const _HomeItem({
    required this.label,
    required this.emoji,
    required this.icon,
    required this.color,
    required this.builder,
  });
}

final List<_HomeItem> _discoverItems = [
  _HomeItem(
    label: 'Story',
    emoji: '📖',
    icon: Icons.menu_book_rounded,
    color: const Color(0xFFFF7BA9),
    builder: (_) => const StoryReadingScreen(),
  ),
  _HomeItem(
    label: 'Music',
    emoji: '🎵',
    icon: Icons.music_note_rounded,
    color: const Color(0xFF4CCB7A),
    builder: (_) => const MusicScreen(),
  ),
  _HomeItem(
    label: 'Videos',
    emoji: '🎬',
    icon: Icons.play_arrow_rounded,
    color: const Color(0xFFFFB82E),
    builder: (_) => const VideosScreen(),
  ),
];

final List<_HomeItem> _playItems = [
  _HomeItem(
    label: 'Paint',
    emoji: '🎨',
    icon: Icons.palette_rounded,
    color: const Color(0xFFFF7A59),
    builder: (_) => const PaintScreen(),
  ),
  _HomeItem(
    label: 'Draw',
    emoji: '✏️',
    icon: Icons.edit_rounded,
    color: const Color(0xFF3AAAE0),
    builder: (_) => const DrawScreen(),
  ),
  _HomeItem(
    label: 'Math',
    emoji: '➗',
    icon: Icons.calculate_rounded,
    color: KidColors.purple,
    builder: (_) => const MathExerciseScreen(),
  ),
  _HomeItem(
    label: 'Puzzle',
    emoji: '🧩',
    icon: Icons.extension_rounded,
    color: const Color(0xFF2FBF8F),
    builder: (_) => const PuzzleScreen(),
  ),
  _HomeItem(
    label: 'Alphabet',
    emoji: '🔤',
    icon: Icons.abc_rounded,
    color: const Color(0xFFF2994A),
    builder: (_) => const AlphabetScreen(),
  ),
  _HomeItem(
    label: 'Numbers',
    emoji: '🔢',
    icon: Icons.numbers_rounded,
    color: KidColors.blue,
    builder: (_) => const NumberScreen(),
  ),
];

final _HomeItem _scienceItem = _HomeItem(
  label: 'Science Lab',
  emoji: '🔬',
  icon: Icons.science_rounded,
  color: const Color(0xFF26B5A0),
  builder: (_) => const ScienceLabScreen(),
);

// ------------------------------------------------------------- helpers

TextStyle _fredoka({
  double size = 15,
  Color color = KidColors.textDark,
  FontWeight weight = FontWeight.w700,
}) =>
    GoogleFonts.fredoka(fontSize: size, fontWeight: weight, color: color);

/// Ouvre un écran avec haptic + transition douce.
void _open(BuildContext context, WidgetBuilder builder) {
  HapticFeedback.selectionClick();
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, _, __) => builder(ctx),
      transitionsBuilder: (_, animation, __, child) {
        final curved =
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

/// Section title style "kid": emoji + texte + petite ligne colorée.
class _SectionHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.emoji,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 8),
        Text(title, style: _fredoka(size: 22, weight: FontWeight.w800)),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: color.withOpacity(0.25),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bouton 3D "bonbon" : dégradé, bordure blanche, ombre pleine qui
/// s'écrase quand on appuie (même style que le gros chiffre des Numbers).
class _ChunkyTile extends StatefulWidget {
  final Color color;
  final double radius;
  final VoidCallback onTap;
  final Widget child;
  final String semanticLabel;

  const _ChunkyTile({
    required this.color,
    required this.onTap,
    required this.child,
    required this.semanticLabel,
    this.radius = 28,
  });

  @override
  State<_ChunkyTile> createState() => _ChunkyTileState();
}

class _ChunkyTileState extends State<_ChunkyTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const depth = 7.0;
    final offset = _down ? 2.0 : depth;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [KidColors.lighten(widget.color, 0.08), widget.color],
              ),
              borderRadius: BorderRadius.circular(widget.radius),
              border:
              Border.all(color: Colors.white.withOpacity(0.6), width: 3),
              boxShadow: [
                BoxShadow(
                  color: KidColors.darken(widget.color),
                  offset: Offset(0, offset),
                  blurRadius: 0,
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- screen

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
      body: KidBackground(
        colors: const [Color(0xFFDDEBFF), KidColors.cream],
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopBar(
                  nickname: profile.nickname,
                  avatarEmoji: profile.avatarEmoji,
                  stars: profile.totalStars,
                  onParentTap: () => _openParentArea(context),
                ),
                const SizedBox(height: 18),
                const _HeroBanner(),
                const SizedBox(height: 20),
                _DailyChallengeCard(challenges: progress.dailyChallenges),
                const SizedBox(height: 26),
                const _SectionHeader(
                  emoji: '🌈',
                  title: 'Discover',
                  color: Color(0xFFFF7BA9),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (var i = 0; i < _discoverItems.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(
                        child: _DiscoverTile(
                          item: _discoverItems[i],
                          onTap: () =>
                              _open(context, _discoverItems[i].builder),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                const _SectionHeader(
                  emoji: '🎮',
                  title: 'Learn & Play',
                  color: KidColors.purple,
                ),
                const SizedBox(height: 14),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.15,
                  children: [
                    for (final item in _playItems)
                      _PlayTile(
                        item: item,
                        onTap: () => _open(context, item.builder),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 100,
                  child: _PlayTile(
                    item: _scienceItem,
                    wide: true,
                    onTap: () => _open(context, _scienceItem.builder),
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

// ---------------------------------------------------------------- top bar

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
          width: 58,
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [KidColors.lighten(KidColors.purple, 0.08), KidColors.purple],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.7), width: 3),
            boxShadow: [
              BoxShadow(
                color: KidColors.darken(KidColors.purple),
                offset: const Offset(0, 5),
                blurRadius: 0,
              ),
            ],
          ),
          child: Text(avatarEmoji, style: const TextStyle(fontSize: 28)),
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
                style: _fredoka(size: 18, weight: FontWeight.w800),
              ),
              Text(
                'Ready to learn and play?',
                style: _fredoka(
                  size: 13.5,
                  color: KidColors.textMuted,
                  weight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        KidStarsChip(stars: stars),
        const SizedBox(width: 8),
        KidRoundButton(
          icon: Icons.lock_rounded,
          color: KidColors.textMuted,
          tooltip: 'Parents area',
          onTap: onParentTap,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- hero

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFF7BA9);

    return _ChunkyTile(
      color: accent,
      radius: 32,
      semanticLabel: "Let's go on an adventure! Open stories",
      onTap: () => _open(context, (_) => const StoryReadingScreen()),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(29),
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
                      Colors.black.withOpacity(0.55),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 70,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Let's go on an adventure!",
                      style: _fredoka(
                        size: 22,
                        color: Colors.white,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to read a story 📖',
                      style: _fredoka(
                        size: 14,
                        color: Colors.white.withOpacity(0.95),
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 14,
                bottom: 14,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: KidColors.darken(accent),
                        offset: const Offset(0, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 30,
                    color: accent,
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

// ---------------------------------------------------------------- daily

class _DailyChallengeCard extends StatelessWidget {
  final List<DailyChallenge> challenges;

  const _DailyChallengeCard({required this.challenges});

  @override
  Widget build(BuildContext context) {
    final total = challenges.length;
    final completed = challenges.where((c) => c.isCompleted).length;
    final claimable =
        challenges.where((c) => c.isCompleted && !c.rewardClaimed).length;
    const accent = KidColors.orange;

    return GestureDetector(
      onTap: () => _open(context, (_) => const DailyChallengesScreen()),
      child: KidCard(
        accent: accent,
        radius: 28,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withOpacity(0.5), width: 2),
              ),
              child: const Text('🎯', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Daily Challenges',
                          style: _fredoka(size: 17, weight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        '$completed/$total',
                        style: _fredoka(
                          size: 15,
                          color: KidColors.darken(accent, 0.12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  KidProgressBar(
                    value: total == 0 ? 0 : completed / total,
                    height: 12,
                    color: completed == total && total > 0
                        ? KidColors.green
                        : accent,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    claimable > 0
                        ? '🎁 $claimable reward${claimable == 1 ? '' : 's'} ready to claim!'
                        : 'Complete exercises to earn bonus stars!',
                    style: _fredoka(
                      size: 13,
                      weight:
                      claimable > 0 ? FontWeight.w700 : FontWeight.w500,
                      color: claimable > 0
                          ? KidColors.darken(accent, 0.15)
                          : KidColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                color: KidColors.textMuted, size: 28),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- tiles

class _DiscoverTile extends StatelessWidget {
  final _HomeItem item;
  final VoidCallback onTap;

  const _DiscoverTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _ChunkyTile(
      color: item.color,
      radius: 26,
      semanticLabel: item.label,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.28),
                shape: BoxShape.circle,
              ),
              child: Text(item.emoji, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: _fredoka(
                size: 16,
                color: Colors.white,
                weight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayTile extends StatelessWidget {
  final _HomeItem item;
  final VoidCallback onTap;
  final bool wide;

  const _PlayTile({
    required this.item,
    required this.onTap,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      width: wide ? 60 : 56,
      height: wide ? 60 : 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.28),
        shape: BoxShape.circle,
      ),
      child: Text(item.emoji, style: TextStyle(fontSize: wide ? 32 : 30)),
    );

    final label = Text(
      item.label,
      style: _fredoka(
        size: wide ? 20 : 17,
        color: Colors.white,
        weight: FontWeight.w800,
      ),
    );

    return _ChunkyTile(
      color: item.color,
      semanticLabel: item.label,
      onTap: onTap,
      child: wide
          ? Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            bubble,
            const SizedBox(width: 14),
            Expanded(child: label),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 20),
          ],
        ),
      )
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [bubble, const SizedBox(height: 6), label],
      ),
    );
  }
}