import 'dart:math';

import 'package:flutter/material.dart';

import 'story.dart';

/// Reading screen for the "Story" activity. Swipe or use the arrow
/// buttons to move between stories. No audio playback — the center
/// button instead lets the child mark a story as "read", with a fun
/// little celebration when they do.
class StoryReadingScreen extends StatefulWidget {
  final int initialIndex;

  const StoryReadingScreen({super.key, this.initialIndex = 0});

  @override
  State<StoryReadingScreen> createState() => _StoryReadingScreenState();
}

class _StoryReadingScreenState extends State<StoryReadingScreen>
    with TickerProviderStateMixin {
  late final PageController _controller =
  PageController(initialPage: widget.initialIndex);
  late int _currentIndex = widget.initialIndex;
  final Set<int> _readIds = {};

  // Gentle up/down bob for the illustration icon.
  late final AnimationController _bobController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  // Little celebration burst shown briefly when a story is marked read.
  late final AnimationController _celebrateController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  static const Color primaryPurple = Color(0xFF7B61FF);
  static const Color bgColor = Color(0xFFF7F5FC);

  static const List<String> _cheerMessages = [
    'Woohoo! 🎉',
    'You\'re on fire! 🔥',
    'Great job! ⭐',
    'Story master! 🏆',
    'Yay, well read! 🥳',
  ];

  static const Map<String, List<Color>> _themeColors = {
    'Animals': [Color(0xFFFFC98B), Color(0xFFF2994A)],
    'Friendship': [Color(0xFFFF9EC4), Color(0xFFE0507B)],
    'Adventure': [Color(0xFF6FE3D8), Color(0xFF16A5A0)],
    'Learning': [Color(0xFFB48CF2), Color(0xFF7B61FF)],
    'Magic': [Color(0xFFB79CFF), Color(0xFF6C4CD9)],
    'Nature': [Color(0xFF9CDB8C), Color(0xFF4CAF50)],
    'Robots / Technology': [Color(0xFF7CC5FF), Color(0xFF3AAAE0)],
    'Sleep / Night': [Color(0xFF8FA6FF), Color(0xFF4A5FCC)],
    'Emotions': [Color(0xFFFFD27C), Color(0xFFE0A800)],
  };

  static const Map<String, IconData> _themeIcons = {
    'Animals': Icons.pets_rounded,
    'Friendship': Icons.favorite_rounded,
    'Adventure': Icons.map_rounded,
    'Learning': Icons.auto_stories_rounded,
    'Magic': Icons.auto_awesome_rounded,
    'Nature': Icons.eco_rounded,
    'Robots / Technology': Icons.smart_toy_rounded,
    'Sleep / Night': Icons.nightlight_round,
    'Emotions': Icons.emoji_emotions_rounded,
  };

  static const Map<String, String> _themeEmoji = {
    'Animals': '🦊',
    'Friendship': '🤝',
    'Adventure': '🗺️',
    'Learning': '📚',
    'Magic': '✨',
    'Nature': '🌳',
    'Robots / Technology': '🤖',
    'Sleep / Night': '🌙',
    'Emotions': '🌈',
  };

  List<Color> _colorsFor(String theme) =>
      _themeColors[theme] ?? [primaryPurple, const Color(0xFF5A3FD6)];

  IconData _iconFor(String theme) => _themeIcons[theme] ?? Icons.menu_book_rounded;

  String _emojiFor(String theme) => _themeEmoji[theme] ?? '📖';

  void _goTo(int index) {
    if (index < 0 || index >= stories.length) return;
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _toggleRead(int id) {
    final bool willBeRead = !_readIds.contains(id);
    setState(() {
      if (willBeRead) {
        _readIds.add(id);
      } else {
        _readIds.remove(id);
      }
    });
    if (willBeRead) {
      _celebrateController.forward(from: 0);
      final message =
      _cheerMessages[Random().nextInt(_cheerMessages.length)];
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1100),
          backgroundColor: primaryPurple,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _bobController.dispose();
    _celebrateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = stories[_currentIndex];

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // --- Top bar ------------------------------------------------
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF213238), size: 18),
                      ),
                      const Expanded(
                        child: Text(
                          '📖 Reading Time',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF213238),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // --- Pages ------------------------------------------------------
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: stories.length,
                    onPageChanged: (i) => setState(() => _currentIndex = i),
                    itemBuilder: (context, index) {
                      final s = stories[index];
                      return _StoryPage(
                        story: s,
                        colors: _colorsFor(s.theme),
                        icon: _iconFor(s.theme),
                        emoji: _emojiFor(s.theme),
                        isRead: _readIds.contains(s.id),
                        bobController: _bobController,
                      );
                    },
                  ),
                ),

                // --- Bottom controls ---------------------------------------------
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _BouncyIconButton(
                            icon: Icons.arrow_back_rounded,
                            background: const Color(0xFFFFE1C2),
                            iconColor: const Color(0xFFE0964A),
                            onTap: () => _goTo(_currentIndex - 1),
                          ),
                          _BouncyIconButton(
                            icon: _readIds.contains(story.id)
                                ? Icons.check_rounded
                                : Icons.bookmark_add_rounded,
                            background: primaryPurple,
                            iconColor: Colors.white,
                            large: true,
                            onTap: () => _toggleRead(story.id),
                          ),
                          _BouncyIconButton(
                            icon: Icons.arrow_forward_rounded,
                            background: primaryPurple.withOpacity(0.15),
                            iconColor: primaryPurple,
                            onTap: () => _goTo(_currentIndex + 1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '${_currentIndex + 1} / ${stories.length} 🐾',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9AA6AB),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // --- Celebration burst overlay ------------------------------------
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _celebrateController,
                builder: (context, _) => _CelebrationBurst(
                  progress: _celebrateController.value,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryPage extends StatelessWidget {
  final Story story;
  final List<Color> colors;
  final IconData icon;
  final String emoji;
  final bool isRead;
  final AnimationController bobController;

  const _StoryPage({
    required this.story,
    required this.colors,
    required this.icon,
    required this.emoji,
    required this.isRead,
    required this.bobController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustrated theme card with a bouncing mascot icon
          Container(
            height: 210,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.last.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -20,
                  right: -20,
                  child: Icon(icon,
                      size: 140, color: Colors.white.withOpacity(0.18)),
                ),
                // A couple of floating sparkles for fun
                Positioned(
                  top: 30,
                  left: 30,
                  child: _Twinkle(controller: bobController, emoji: '✨'),
                ),
                Positioned(
                  bottom: 24,
                  right: 40,
                  child: _Twinkle(
                      controller: bobController, emoji: '⭐', reversed: true),
                ),
                Center(
                  child: AnimatedBuilder(
                    animation: bobController,
                    builder: (context, child) {
                      final double dy =
                          -6 * sin(bobController.value * pi * 2);
                      final double rot =
                          0.03 * sin(bobController.value * pi * 2);
                      return Transform.translate(
                        offset: Offset(0, dy),
                        child: Transform.rotate(angle: rot, child: child),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 74, color: Colors.white),
                        Text(emoji, style: const TextStyle(fontSize: 30)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$emoji ${story.theme}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (isRead)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🎉', style: TextStyle(fontSize: 13)),
                          SizedBox(width: 4),
                          Text(
                            'Read!',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF213238),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            story.title,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Color(0xFF213238),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            story.text,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.7,
              color: Color(0xFF5B6A70),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small floating emoji that gently twinkles (fades in/out and scales)
/// using the same shared bob controller so nothing extra needs disposing.
class _Twinkle extends StatelessWidget {
  final AnimationController controller;
  final String emoji;
  final bool reversed;

  const _Twinkle({
    required this.controller,
    required this.emoji,
    this.reversed = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final double t = reversed ? 1 - controller.value : controller.value;
        final double scale = 0.7 + 0.4 * sin(t * pi);
        final double opacity = 0.5 + 0.5 * sin(t * pi);
        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Text(emoji, style: const TextStyle(fontSize: 20)),
    );
  }
}

/// Bouncy button: scales down slightly on press for a playful tactile feel.
class _BouncyIconButton extends StatefulWidget {
  final IconData icon;
  final Color background;
  final Color iconColor;
  final bool large;
  final VoidCallback onTap;

  const _BouncyIconButton({
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.onTap,
    this.large = false,
  });

  @override
  State<_BouncyIconButton> createState() => _BouncyIconButtonState();
}

class _BouncyIconButtonState extends State<_BouncyIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final double size = widget.large ? 62 : 50;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.86 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Material(
          color: widget.background,
          shape: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(widget.icon,
                color: widget.iconColor, size: widget.large ? 28 : 22),
          ),
        ),
      ),
    );
  }
}

/// Confetti-ish little burst of emoji that pop up and fade away, shown
/// briefly when a story is marked as read.
class _CelebrationBurst extends StatelessWidget {
  final double progress; // 0 -> 1
  const _CelebrationBurst({required this.progress});

  static const List<String> _pieces = ['🎉', '⭐', '✨', '🎊', '💫'];

  @override
  Widget build(BuildContext context) {
    if (progress <= 0 || progress >= 1) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final rnd = Random(7); // fixed seed so pieces don't jump around

    return Stack(
      children: List.generate(10, (i) {
        final double startX = rnd.nextDouble() * screenWidth;
        final double drift = (rnd.nextDouble() - 0.5) * 60;
        final double delay = (i % 5) * 0.05;
        final double t = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
        final double dy = screenHeight * 0.55 * t;
        final double opacity = (1 - t).clamp(0.0, 1.0);
        final String emoji = _pieces[i % _pieces.length];

        return Positioned(
          left: startX + drift * t,
          bottom: screenHeight * 0.28 + dy,
          child: Opacity(
            opacity: opacity,
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
        );
      }),
    );
  }
}