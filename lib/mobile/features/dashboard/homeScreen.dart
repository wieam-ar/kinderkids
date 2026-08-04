import 'package:flutter/material.dart';

import '../alphabet/alphabetScreen.dart';
import '../draw/Paintscreen.dart';
import '../draw/drawscreen.dart';
import '../math/mathexercice.dart';
import '../music/musicScreen.dart';
import '../numbers/numberscreen.dart';
import '../puzzle/PuzzleScreen.dart';
import '../stories/StoryReadingScreen.dart';
import '../vedio/vedioScreen.dart';
import 'Activity_detail.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // --- Design tokens (matches onboarding_screen.dart) -----------------
  static const Color primaryBlue = Color(0xFF0F92CA);
  static const Color primaryBlueDark = Color(0xFF0B6E9B);
  static const Color textDark = Color(0xFF213238);
  static const Color textMuted = Color(0xFF7C8C93);
  // ----------------------------------------------------------------------

  void _open(BuildContext context, ActivityDetailScreen screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Same safari themed background used on splash / onboarding /
          // activity screens, so the whole app feels consistent.
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Soft white wash so cards and text stay readable over the
          // artwork.
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _TopBar(),
                  const SizedBox(height: 18),
                  const _HeaderBanner(),
                  const SizedBox(height: 30),
                  const _SectionTitle(title: 'Discover our app'),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _DiscoverCard(
                          label: 'Story',
                          icon: Icons.menu_book_rounded,
                          bgColor: const Color(0xFFFCE4EC),
                          accentColor: const Color(0xFFE0507B),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const StoryReadingScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DiscoverCard(
                          label: 'Music',
                          icon: Icons.music_note_rounded,
                          bgColor: const Color(0xFFE2F7E6),
                          accentColor: const Color(0xFF35B24A),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const MusicScreen()),
                          ),
                        ),

                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DiscoverCard(

                          label: 'Videos',
                          icon: Icons.play_arrow_rounded,
                          bgColor: const Color(0xFFFDF3D9),
                          accentColor: const Color(0xFFE0A800),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const VideosScreen()),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const _SectionTitle(title: 'Exercises'),
                  const SizedBox(height: 14),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.35,
                    children: [
                      _ExerciseTile(
                        icon: Icons.palette_rounded,
                        label: 'Paint',
                        colors: const [Color(0xFFFF9D6C), Color(0xFFF25C54)],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PaintScreen()),
                        ),

                      ),
                      _ExerciseTile(
                        icon: Icons.edit_rounded,
                        label: 'Draw',
                        colors: const [Color(0xFF6FD3F7), Color(0xFF3AAAE0)],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DrawScreen()),
                        ),
                      ),
                      _ExerciseTile(
                        icon: Icons.calculate_rounded,
                        label: 'Math',
                        colors: const [Color(0xFFB48CF2), Color(0xFF8B5CF6)],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MathExerciseScreen()),
                        ),
                      ),
                      _ExerciseTile(
                        icon: Icons.extension_rounded,
                        label: 'Puzzle',
                        colors: const [Color(0xFF6EE7B7), Color(0xFF2FBF8F)],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PuzzleScreen()),
                        ),
                      ),
                      _ExerciseTile(
                        icon: Icons.abc_rounded,
                        label: 'Alphabet',
                        colors: const [Color(0xFFFFC15E), Color(0xFFF2994A)],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AlphabetScreen()),
                        ),
                      ),
                      _ExerciseTile(
                        icon: Icons.numbers_rounded,
                        label: 'Numbers',
                        colors: const [
                          Color(0xFF7CC5FF),
                          HomeScreen.primaryBlueDark
                        ],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NumberScreen()),
                        ),
                      ),
                    ],

                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple top bar: greeting + avatar + notification bell.
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [HomeScreen.primaryBlue, HomeScreen.primaryBlueDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: HomeScreen.primaryBlue.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text('🦁', style: TextStyle(fontSize: 22)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, Explorer! 👋',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: HomeScreen.textDark,
                ),
              ),
              Text(
                'Ready to learn and play?',
                style: TextStyle(
                  fontSize: 12.5,
                  color: HomeScreen.textMuted,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(Icons.notifications_rounded,
              color: HomeScreen.primaryBlue, size: 20),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: HomeScreen.textDark,
          ),
        ),
        Text(
          'See all',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: HomeScreen.primaryBlue,
          ),
        ),
      ],
    );
  }
}

/// Top banner image with a soft shadow, gradient scrim, and a decorative
/// cloud peeking out of the corner.
class _HeaderBanner extends StatelessWidget {
  const _HeaderBanner();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: HomeScreen.primaryBlue.withOpacity(0.2),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
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
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.white,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_rounded,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.0),
                          Colors.black.withOpacity(0.32),
                        ],
                        stops: const [0.55, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    bottom: 16,
                    right: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Let\'s go on an adventure!',
                          style: TextStyle(
                            fontSize: 16,
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
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -16,
          right: -12,
          child: Icon(
            Icons.cloud_rounded,
            size: 52,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}

class _DiscoverCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color accentColor;
  final VoidCallback onTap;

  const _DiscoverCard({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
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
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> colors;
  final VoidCallback onTap;

  const _ExerciseTile({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.last.withOpacity(0.3),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}