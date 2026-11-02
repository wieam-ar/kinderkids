import 'package:flutter/material.dart';

/// Single source of truth for colors used across all screens.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0F92CA);
  static const Color primaryDark = Color(0xFF0B6E9B);
  static const Color textDark = Color(0xFF213238);
  static const Color textMuted = Color(0xFF7C8C93);
  static const Color background = Color(0xFFF7FAFC);
  static const Color tint = Color(0xFFE9F4F8);
  static const Color border = Color(0xFFE4EEF2);
  static const Color star = Color(0xFFFFC15E);
  static const Color starDark = Color(0xFFDC9C10);
  static const Color success = Color(0xFF35B24A);
  static const Color danger = Color(0xFFFF6B5E);
  static const Color purple = Color(0xFF8B5CF6);
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft([double opacity = 0.06]) => [
        BoxShadow(
          color: Colors.black.withOpacity(opacity),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> glow(Color color, [double opacity = 0.35]) => [
        BoxShadow(
          color: color.withOpacity(opacity),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];
}

/// Standard white app bar used by every secondary screen.
AppBar buildAppBar(String title, {List<Widget> actions = const []}) {
  return AppBar(
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
    ),
    centerTitle: false,
    backgroundColor: Colors.white,
    foregroundColor: AppColors.textDark,
    elevation: 0,
    scrolledUnderElevation: 1,
    actions: actions,
  );
}

/// Pill showing the star balance (animates when the number changes).
class StarsChip extends StatelessWidget {
  final int stars;
  final bool large;

  const StarsChip({super.key, required this.stars, this.large = false});

  @override
  Widget build(BuildContext context) {
    final fontSize = large ? 16.0 : 13.0;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical: large ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.star,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.glow(Colors.orange, 0.25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('⭐ ', style: TextStyle(fontSize: fontSize)),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: stars.toDouble()),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) => Text(
              '${value.round()}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontSize: fontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// White rounded card with soft shadow, optionally tappable.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final Color? borderColor;
  final VoidCallback? onTap;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.color = Colors.white,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: 1.5),
        boxShadow: AppShadows.soft(),
      ),
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(radius),
                onTap: onTap,
                child: content,
              ),
            ),
    );
  }
}

/// Scale-down feedback on press, used for big tappable tiles.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.96,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? widget.pressedScale : 1,
          duration: const Duration(milliseconds: 110),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Gradient card with glow, the base of every colorful tile in the app.
class GradientCard extends StatelessWidget {
  final List<Color> colors;
  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final EdgeInsetsGeometry padding;

  const GradientCard({
    super.key,
    required this.colors,
    required this.child,
    this.onTap,
    this.radius = 24,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: AppShadows.glow(colors.last),
        ),
        child: child,
      ),
    );
  }
}

/// Splash background image with a white fade, safe if the asset is missing.
class ScreenBackground extends StatelessWidget {
  final Widget child;

  const ScreenBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/splash_background.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: AppColors.tint),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.5),
                  Colors.white.withOpacity(0.85),
                  Colors.white.withOpacity(0.97),
                ],
                stops: const [0.0, 0.35, 0.65],
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionTitle(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: AppColors.textDark,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Fade + slide-up entrance. Later [index] values appear slightly later.
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int index;

  const FadeSlideIn({super.key, required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 90),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 24 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}

class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String message;

  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a floating snackbar, replacing any snackbar already visible.
void showAppSnack(
  ScaffoldMessengerState messenger,
  String message, {
  Color? color,
}) {
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
      ),
    );
}
