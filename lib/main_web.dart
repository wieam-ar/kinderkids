// main_web.dart
// KinderKids — a bright, bouncy, kid-first landing page built in Flutter.
// Run with: flutter run -d chrome  (or `flutter build web`)

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

void main() => runApp(const KinderKidsApp());

// ---------------------------------------------------------------------------
// Palette — loud, candy-bright, high-contrast. This is FOR kids, not adults.
// ---------------------------------------------------------------------------
class Palette {
  static const sun = Color(0xFFFFC93C);
  static const orange = Color(0xFFFF8A3D);
  static const pink = Color(0xFFFF5C8A);
  static const purple = Color(0xFF9B5DE5);
  static const blue = Color(0xFF3FA9F5);
  static const teal = Color(0xFF2EC4B6);
  static const green = Color(0xFF6BCB4C);
  static const cream = Color(0xFFFFF7E6);
  static const ink = Color(0xFF2B2242);

  static const rainbow = [sun, orange, pink, purple, blue, teal, green];
}

class KinderKidsApp extends StatelessWidget {
  const KinderKidsApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KinderKids — Math Safari!',
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.trackpad,
        },
      ),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Palette.cream,
        fontFamily: 'Arial',
      ),
      home: const HomePage(),
    );
  }
}

// ---------------------------------------------------------------------------
// HOME PAGE
// ---------------------------------------------------------------------------
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const FloatingShapesBackground(),
          SingleChildScrollView(
            child: Column(
              children: [
                const KKNavBar(),
                const HeroSection(),
                const StatsStrip(),
                const AdventuresSection(),
                const MascotBanner(),
                const TestimonialsSection(),
                const FinalCTASection(),
                const KKFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated floating background shapes — stars, circles, triangles bobbing
// ---------------------------------------------------------------------------
class FloatingShapesBackground extends StatefulWidget {
  const FloatingShapesBackground({super.key});
  @override
  State<FloatingShapesBackground> createState() => _FloatingShapesBackgroundState();
}

class _FloatingShapesBackgroundState extends State<FloatingShapesBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final _rand = Random(7);
  late final List<_ShapeSpec> _shapes;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
    _shapes = List.generate(18, (i) {
      return _ShapeSpec(
        dx: _rand.nextDouble(),
        dy: _rand.nextDouble(),
        size: 14 + _rand.nextDouble() * 26,
        color: Palette.rainbow[i % Palette.rainbow.length].withOpacity(0.25),
        phase: _rand.nextDouble() * pi * 2,
        emoji: ['⭐', '🍌', '🐾', '🔵', '🔺', '❤️'][i % 6],
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return IgnorePointer(
          child: LayoutBuilder(builder: (context, constraints) {
            return SizedBox(
              width: constraints.maxWidth,
              height: 2400,
              child: Stack(
                children: _shapes.map((s) {
                  final bob = sin((_c.value * 2 * pi) + s.phase) * 14;
                  return Positioned(
                    left: s.dx * constraints.maxWidth,
                    top: s.dy * 2400 + bob,
                    child: Text(s.emoji, style: TextStyle(fontSize: s.size)),
                  );
                }).toList(),
              ),
            );
          }),
        );
      },
    );
  }
}

class _ShapeSpec {
  final double dx, dy, size, phase;
  final Color color;
  final String emoji;
  _ShapeSpec({
    required this.dx,
    required this.dy,
    required this.size,
    required this.color,
    required this.phase,
    required this.emoji,
  });
}

// ---------------------------------------------------------------------------
// NAV BAR
// ---------------------------------------------------------------------------
class KKNavBar extends StatelessWidget {
  const KKNavBar({super.key});
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 720;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          const Text('🦁', style: TextStyle(fontSize: 34)),
          const SizedBox(width: 10),
          const Text(
            'KinderKids',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Palette.ink,
            ),
          ),
          const Spacer(),
          if (!isMobile) ...[
            _NavLink('Games'),
            _NavLink('Why Us'),
            _NavLink('Stories'),
            const SizedBox(width: 12),
          ],
          BouncyButton(
            color: Palette.pink,
            label: '▶ Play Free!',
            onTap: () {},
            small: true,
          ),
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String text;
  const _NavLink(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Palette.ink,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HERO — huge headline, bouncing lion, wiggly CTA button
// ---------------------------------------------------------------------------
class HeroSection extends StatefulWidget {
  const HeroSection({super.key});
  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 900;
    final mascot = AnimatedBuilder(
      animation: _bounce,
      builder: (context, child) {
        final lift = -18 * Curves.easeInOut.transform(_bounce.value);
        final rotate = 0.04 * sin(_bounce.value * pi);
        return Transform.translate(
          offset: Offset(0, lift),
          child: Transform.rotate(angle: rotate, child: child),
        );
      },
      child: const Text('🦁', style: TextStyle(fontSize: 190)),
    );

    final textBlock = Column(
      crossAxisAlignment: wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        const BubbleTag(text: '🎉 A MATH SAFARI FOR KIDS 3–9'),
        const SizedBox(height: 18),
        Text(
          'Let\'s go on a\nNUMBER ADVENTURE!',
          textAlign: wide ? TextAlign.left : TextAlign.center,
          style: const TextStyle(
            fontSize: 52,
            height: 1.05,
            fontWeight: FontWeight.w900,
            color: Palette.ink,
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: 480,
          child: Text(
            'Hop, count and giggle your way through addition, subtraction '
                'and more — with Léo the Lion cheering every answer, right or wrong!',
            textAlign: wide ? TextAlign.left : TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Palette.ink,
            ),
          ),
        ),
        const SizedBox(height: 26),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: wide ? WrapAlignment.start : WrapAlignment.center,
          children: [
            BouncyButton(color: Palette.orange, label: '🚀 Start Playing!', onTap: () {}),
            BouncyButton(color: Colors.white, textColor: Palette.ink, label: '🎬 Watch Léo', onTap: () {}),
          ],
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 60),
      child: wide
          ? Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: textBlock),
          Expanded(child: Center(child: mascot)),
        ],
      )
          : Column(
        children: [
          textBlock,
          const SizedBox(height: 20),
          mascot,
        ],
      ),
    );
  }
}

class BubbleTag extends StatelessWidget {
  final String text;
  const BubbleTag({super.key, required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Palette.sun,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Palette.ink, width: 2.5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 13,
          letterSpacing: 0.5,
          color: Palette.ink,
        ),
      ),
    );
  }
}

// A big, chunky, wobble-on-hover button — the opposite of a subtle pill.
class BouncyButton extends StatefulWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  final bool small;
  const BouncyButton({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
    this.textColor = Colors.white,
    this.small = false,
  });
  @override
  State<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<BouncyButton> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hover ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.elasticOut,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.small ? 20 : 30,
              vertical: widget.small ? 12 : 18,
            ),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Palette.ink, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Palette.ink.withOpacity(0.25),
                  offset: const Offset(0, 5),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.textColor,
                fontWeight: FontWeight.w900,
                fontSize: widget.small ? 15 : 19,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// STATS STRIP — big friendly numbers, like a scoreboard
// ---------------------------------------------------------------------------
class StatsStrip extends StatelessWidget {
  const StatsStrip({super.key});
  @override
  Widget build(BuildContext context) {
    final stats = [
      ('6', 'Fun Games'),
      ('1000+', 'Happy Kids'),
      ('2', 'Languages'),
      ('0', 'Boring Bits'),
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: Palette.purple,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Palette.ink, width: 3),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        runSpacing: 16,
        children: stats
            .map((s) => SizedBox(
          width: 150,
          child: Column(
            children: [
              Text(s.$1,
                  style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
              Text(s.$2,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.9))),
            ],
          ),
        ))
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ADVENTURES — six colorful game cards, each an animal + operation
// ---------------------------------------------------------------------------
class AdventuresSection extends StatelessWidget {
  const AdventuresSection({super.key});
  @override
  Widget build(BuildContext context) {
    final games = [
      _Game('➕', 'Addition Island', Palette.green, '🐘'),
      _Game('➖', 'Subtraction Cave', Palette.orange, '🦍'),
      _Game('❓', 'Mystery Number', Palette.pink, '🦊'),
      _Game('🔢', 'Counting Beach', Palette.blue, '🐢'),
      _Game('✖️', 'Multiply Jungle', Palette.purple, '🐒'),
      _Game('↔️', 'Order Trail', Palette.sun, '🦜'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          const BubbleTag(text: '🗺️ PICK YOUR ADVENTURE'),
          const SizedBox(height: 14),
          const Text(
            'Six Wild Games to Play!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 36, fontWeight: FontWeight.w900, color: Palette.ink),
          ),
          const SizedBox(height: 30),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: games.map((g) => GameCard(game: g)).toList(),
          ),
        ],
      ),
    );
  }
}

class _Game {
  final String symbol, name, animal;
  final Color color;
  _Game(this.symbol, this.name, this.color, this.animal);
}

class GameCard extends StatefulWidget {
  final _Game game;
  const GameCard({super.key, required this.game});
  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover ? -10 : 0, 0)
          ..rotateZ(_hover ? -0.02 : 0),
        width: 220,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: widget.game.color,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Palette.ink, width: 3),
          boxShadow: [
            BoxShadow(
              color: Palette.ink.withOpacity(0.3),
              offset: Offset(0, _hover ? 10 : 5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(widget.game.animal, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 6),
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Palette.ink, width: 2.5),
              ),
              child: Text(widget.game.symbol, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 12),
            Text(
              widget.game.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MASCOT BANNER — Léo talking, speech-bubble style, dark contrast band
// ---------------------------------------------------------------------------
class MascotBanner extends StatelessWidget {
  const MascotBanner({super.key});
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 800;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Palette.ink,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Flex(
        direction: wide ? Axis.horizontal : Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🦁', style: TextStyle(fontSize: 90)),
          const SizedBox(width: 20, height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '"Yes! You got it! Wach ntouma jahzin bach nkemlo l-mغamra? '
                    'Come on — every question is a new stone on our trail!" 🐾',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Palette.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TESTIMONIALS — parent quotes in big comic bubbles
// ---------------------------------------------------------------------------
class TestimonialsSection extends StatelessWidget {
  const TestimonialsSection({super.key});
  @override
  Widget build(BuildContext context) {
    final quotes = [
      ('Salma B.', '"My daughter BEGS to play the lion game every night!"', Palette.pink),
      ('Youssef K.', '"He finally gets math — and he\'s laughing the whole time."', Palette.teal),
      ('Imane R.', '"No ads, no stress. Just happy little wins."', Palette.orange),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
      child: Column(
        children: [
          const Text(
            'Loved by Parents 💛',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Palette.ink),
          ),
          const SizedBox(height: 26),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: quotes.map((q) {
              return Container(
                width: 260,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: q.$3.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: q.$3, width: 3),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.$2,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Palette.ink)),
                    const SizedBox(height: 12),
                    Text('— ${q.$1}',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: q.$3)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FINAL CTA — huge rainbow burst
// ---------------------------------------------------------------------------
class FinalCTASection extends StatelessWidget {
  const FinalCTASection({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      padding: const EdgeInsets.symmetric(vertical: 54, horizontal: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Palette.pink, Palette.orange, Palette.sun],
        ),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Palette.ink, width: 3),
      ),
      child: Column(
        children: [
          const Text('🎈🦁🎈', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 14),
          const Text(
            'Ready for Your\nFirst Adventure?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 22),
          BouncyButton(color: Colors.white, textColor: Palette.pink, label: '🚀 Get KinderKids Free', onTap: () {}),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FOOTER
// ---------------------------------------------------------------------------
class KKFooter extends StatelessWidget {
  const KKFooter({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          const Text('🦁 KinderKids', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Palette.ink)),
          const SizedBox(height: 8),
          Text('© 2026 KinderKids · Made with 💛 for little explorers',
              style: TextStyle(fontSize: 13, color: Palette.ink.withOpacity(0.6))),
        ],
      ),
    );
  }
}