import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/ui/kid_ui.dart';
import '../../data/models/onboarding/onboarding_data.dart';

TextStyle _fredoka({
  double size = 15,
  Color color = KidColors.textDark,
  FontWeight weight = FontWeight.w700,
  double? height,
}) =>
    GoogleFonts.fredoka(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );

/// Accent colour for each onboarding page (cycles if there are more pages).
const List<Color> _pageAccents = [
  Color(0xFF29B6F6), // sky blue
  Color(0xFFFFB74D), // orange
  Color(0xFF66BB6A), // green
  Color(0xFFBA68C8), // purple
  Color(0xFFF06292), // pink
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  Color get _accent => _pageAccents[_currentPage % _pageAccents.length];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  void _goNext() {
    if (_currentPage < onboardingItems.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _goBack() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _finishOnboarding() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isFirstPage = _currentPage == 0;
    final bool isLastPage = _currentPage == onboardingItems.length - 1;
    final accent = _accent;

    return Scaffold(
      backgroundColor: KidColors.cream,
      body: Stack(
        children: [
          // Safari themed background (sun, clouds, trees, birds, grass)
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Soft cream wash so text/cards stay readable over the artwork
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    KidColors.cream.withOpacity(0.0),
                    KidColors.cream.withOpacity(0.6),
                    KidColors.cream.withOpacity(0.97),
                  ],
                  stops: const [0.0, 0.5, 0.82],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Skip pill
                Padding(
                  padding: const EdgeInsets.only(right: 18, top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: isLastPage ? 0 : 1,
                        child: IgnorePointer(
                          ignoring: isLastPage,
                          child: _SkipPill(onTap: _finishOnboarding),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: onboardingItems.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, index) {
                      final item = onboardingItems[index];
                      return _OnboardingPage(
                        title: item.title,
                        description: item.description,
                        lottiePath: item.lottiePath,
                        accent: _pageAccents[index % _pageAccents.length],
                      );
                    },
                  ),
                ),

                SmoothPageIndicator(
                  controller: _controller,
                  count: onboardingItems.length,
                  effect: ExpandingDotsEffect(
                    dotColor: accent.withOpacity(0.25),
                    activeDotColor: accent,
                    dotHeight: 12,
                    dotWidth: 12,
                    expansionFactor: 3,
                    spacing: 8,
                  ),
                ),

                const SizedBox(height: 18),

                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  child: isFirstPage
                      ? _ChunkyButton(
                    label: 'Get Started',
                    icon: Icons.arrow_forward_rounded,
                    color: accent,
                    onTap: _goNext,
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ChunkyButton(
                        label: 'Back',
                        icon: Icons.arrow_back_rounded,
                        iconFirst: true,
                        color: Colors.white,
                        labelColor: KidColors.textMuted,
                        borderColor: accent.withOpacity(0.4),
                        expand: false,
                        width: 124,
                        onTap: _goBack,
                      ),
                      _ChunkyButton(
                        label: isLastPage ? 'Start' : 'Next',
                        icon: isLastPage
                            ? Icons.rocket_launch_rounded
                            : Icons.arrow_forward_rounded,
                        color: isLastPage ? KidColors.green : accent,
                        expand: false,
                        width: 150,
                        onTap: _goNext,
                      ),
                    ],
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

// ------------------------------------------------------------------ page

class _OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final String lottiePath;
  final Color accent;

  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.lottiePath,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    const depth = 8.0;

    return Column(
      children: [
        Expanded(
          flex: 5,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.85, end: 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                width: 268,
                height: 268,
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: accent.withOpacity(0.85), width: 6),
                  boxShadow: [
                    // chunky "pressed-in-3D" shadow, same trick as music tiles
                    BoxShadow(
                      color: accent.withOpacity(0.55),
                      offset: const Offset(0, depth),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Lottie.asset(
                  lottiePath,
                  fit: BoxFit.contain,
                  repeat: true,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.pets_rounded,
                    size: 90,
                    color: accent.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: _fredoka(
                    size: 28,
                    weight: FontWeight.w800,
                    color: KidColors.darken(accent),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: accent.withOpacity(0.3), width: 2),
                  ),
                  child: Text(
                    description,
                    textAlign: TextAlign.center,
                    style: _fredoka(
                      size: 15,
                      weight: FontWeight.w500,
                      color: KidColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// --------------------------------------------------------------- buttons

class _SkipPill extends StatelessWidget {
  final VoidCallback onTap;
  const _SkipPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              offset: const Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Skip',
                style: _fredoka(
                    size: 14,
                    color: KidColors.textMuted,
                    weight: FontWeight.w700)),
            const SizedBox(width: 2),
            const Icon(Icons.fast_forward_rounded,
                size: 18, color: KidColors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Chunky 3D button that sinks when pressed (same feel as the music tiles).
class _ChunkyButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color labelColor;
  final Color? borderColor;
  final bool expand;
  final bool iconFirst;
  final double width;
  final VoidCallback onTap;

  const _ChunkyButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.labelColor = Colors.white,
    this.borderColor,
    this.expand = true,
    this.iconFirst = false,
    this.width = 150,
  });

  @override
  State<_ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<_ChunkyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const depth = 6.0;
    final offset = _down ? 2.0 : depth;
    final shadow = widget.borderColor != null
        ? widget.borderColor!
        : KidColors.darken(widget.color);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.iconFirst) ...[
          Icon(widget.icon, color: widget.labelColor, size: 22),
          const SizedBox(width: 6),
        ],
        Text(
          widget.label,
          style: _fredoka(
              size: 18, color: widget.labelColor, weight: FontWeight.w800),
        ),
        if (!widget.iconFirst) ...[
          const SizedBox(width: 6),
          Icon(widget.icon, color: widget.labelColor, size: 22),
        ],
      ],
    );

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
          height: 58,
          width: widget.expand ? double.infinity : widget.width,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(29),
            border: widget.borderColor != null
                ? Border.all(color: widget.borderColor!, width: 3)
                : Border.all(color: Colors.white.withOpacity(0.55), width: 3),
            boxShadow: [
              BoxShadow(
                color: shadow,
                offset: Offset(0, offset),
                blurRadius: 0,
              ),
            ],
          ),
          child: content,
        ),
      ),
    );
  }
}