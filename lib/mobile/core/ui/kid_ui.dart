import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design system "enfant": couleurs vives, font Fredoka (ronde),
/// cards et boutons 3D (chunky), animations douces.
/// Tous les noms commencent par Kid* باش ما يتعارضوش مع app_ui.dart.

// ---------------------------------------------------------------- colors

class KidColors {
  KidColors._();

  static const Color blue = Color(0xFF0F92CA);
  static const Color blueDark = Color(0xFF0B6E9B);
  static const Color sky = Color(0xFFBDE9FF);
  static const Color cream = Color(0xFFFFF8E7);

  static const Color yellow = Color(0xFFFFC542);
  static const Color orange = Color(0xFFFF9D4D);
  static const Color coral = Color(0xFFFF6B6B);
  static const Color pink = Color(0xFFFF8FB8);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color mint = Color(0xFF2FBF8F);
  static const Color green = Color(0xFF35B24A);

  static const Color textDark = Color(0xFF2A3B47);
  static const Color textMuted = Color(0xFF7C8C93);

  /// Palette pour varier les cards (tiles, activités...).
  static const List<Color> rainbow = [
    blue,
    coral,
    yellow,
    mint,
    purple,
    pink,
    orange,
  ];

  /// Version plus sombre d'une couleur (pour l'ombre 3D des boutons).
  static Color darken(Color c, [double amount = 0.18]) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Version plus claire (pour fonds de cards).
  static Color lighten(Color c, [double amount = 0.32]) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}

// ------------------------------------------------------------------ text

class KidText {
  KidText._();

  static TextStyle title({
    double size = 24,
    Color color = KidColors.textDark,
  }) =>
      GoogleFonts.fredoka(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle body({
    double size = 15,
    Color color = KidColors.textDark,
    FontWeight weight = FontWeight.w500,
  }) =>
      GoogleFonts.fredoka(
        fontSize: size,
        fontWeight: weight,
        color: color,
      );

  static TextStyle muted({double size = 13}) => GoogleFonts.fredoka(
    fontSize: size,
    fontWeight: FontWeight.w500,
    color: KidColors.textMuted,
  );
}

// ------------------------------------------------------------ background

/// Fond ludique: dégradé ciel -> crème + bulles de couleur.
class KidBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;

  const KidBackground({super.key, required this.child, this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors ?? const [KidColors.sky, KidColors.cream],
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -50, right: -40, child: _bubble(KidColors.yellow, 170)),
          Positioned(top: 120, left: -60, child: _bubble(KidColors.pink, 150)),
          Positioned(
              bottom: -60, right: -30, child: _bubble(KidColors.mint, 200)),
          Positioned(
              bottom: 140, left: -40, child: _bubble(KidColors.purple, 120)),
          Positioned.fill(child: child),
        ],
      ),
    );
  }

  Widget _bubble(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.22),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- pressable

/// Petit effet "rebond" quand on appuie (scale + haptic léger).
class KidPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  const KidPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.94,
  });

  @override
  State<KidPressable> createState() => _KidPressableState();
}

class _KidPressableState extends State<KidPressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTap: enabled
          ? () {
        HapticFeedback.selectionClick();
        widget.onTap!();
      }
          : null,
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ------------------------------------------------------------------ card

/// Card blanche arrondie avec "épaisseur" 3D colorée en dessous.
class KidCard extends StatelessWidget {
  final Widget child;
  final Color accent;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  const KidCard({
    super.key,
    required this.child,
    this.accent = KidColors.blue,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(16),
    this.radius = 28,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: accent.withOpacity(0.28), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.30),
            offset: const Offset(0, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return KidPressable(onTap: onTap, child: card);
  }
}

/// Card colorée (dégradé) pour les tuiles d'activités.
class KidGradientCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  const KidGradientCard({
    super.key,
    required this.child,
    required this.color,
    this.padding = const EdgeInsets.all(18),
    this.radius = 28,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [KidColors.lighten(color, 0.08), color],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.55), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: KidColors.darken(color),
            offset: const Offset(0, 7),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return KidPressable(onTap: onTap, child: card);
  }
}

// ---------------------------------------------------------------- button

/// Gros bouton 3D: s'enfonce quand on appuie.
class KidButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool expand;
  final bool loading;

  const KidButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = KidColors.blue,
    this.expand = false,
    this.loading = false,
  });

  @override
  State<KidButton> createState() => _KidButtonState();
}

class _KidButtonState extends State<KidButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final base = enabled ? widget.color : Colors.grey.shade400;
    final shadow = KidColors.darken(base);
    const depth = 5.0;

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        else if (widget.icon != null)
          Icon(widget.icon, color: Colors.white, size: 22),
        if (widget.loading || widget.icon != null) const SizedBox(width: 8),
        Text(
          widget.label,
          style: KidText.title(size: 16, color: Colors.white),
        ),
      ],
    );

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTap: enabled
          ? () {
        HapticFeedback.lightImpact();
        widget.onPressed!();
      }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        margin: EdgeInsets.only(top: _down ? depth : 0),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: shadow,
              offset: Offset(0, _down ? 0 : depth),
              blurRadius: 0,
            ),
          ],
        ),
        child: content,
      ),
    );
  }
}

/// Petit bouton rond 3D (retour, undo, son...).
class KidRoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final double size;
  final String? tooltip;

  const KidRoundButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color = KidColors.blue,
    this.size = 46,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final c = enabled ? color : Colors.grey.shade400;
    final button = KidPressable(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: c.withOpacity(0.35), width: 2.5),
          boxShadow: [
            BoxShadow(
              color: c.withOpacity(0.30),
              offset: const Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Icon(icon, color: c, size: size * 0.5),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

// ---------------------------------------------------------------- header

/// En-tête commun: bouton retour + titre + emoji (+ widget à droite).
class KidHeader extends StatelessWidget {
  final String title;
  final String? emoji;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onBack;
  final bool showBack;

  const KidHeader({
    super.key,
    required this.title,
    this.emoji,
    this.subtitle,
    this.trailing,
    this.onBack,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          if (showBack) ...[
            KidRoundButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  emoji == null ? title : '$title $emoji',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KidText.title(size: 24),
                ),
                if (subtitle != null)
                  Text(subtitle!, style: KidText.muted(size: 13)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ----------------------------------------------------------- small stuff

/// Pill jaune avec les étoiles de l'enfant.
class KidStarsChip extends StatelessWidget {
  final int stars;

  const KidStarsChip({super.key, required this.stars});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1C2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KidColors.yellow, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFE8A91A),
            offset: Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⭐', style: TextStyle(fontSize: 15)),
          const SizedBox(width: 5),
          Text(
            '$stars',
            style: KidText.title(size: 15, color: const Color(0xFF8A5B00)),
          ),
        ],
      ),
    );
  }
}

/// Barre de progression épaisse et animée.
class KidProgressBar extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  final double height;

  const KidProgressBar({
    super.key,
    required this.value,
    this.color = KidColors.blue,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(height),
        border: Border.all(color: color.withOpacity(0.25), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: v,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [KidColors.lighten(color, 0.12), color],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Segmented tab (Arabic / English) style enfant.
class KidSegmentedTabs extends StatelessWidget {
  final TabController controller;
  final List<String> labels;
  final Color color;

  const KidSegmentedTabs({
    super.key,
    required this.controller,
    required this.labels,
    this.color = KidColors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.25), width: 2.5),
      ),
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          return Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => controller.animateTo(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: controller.index == i ? color : Colors.transparent,
                        borderRadius: BorderRadius.circular(17),
                        boxShadow: controller.index == i
                            ? [
                          BoxShadow(
                            color: KidColors.darken(color),
                            offset: const Offset(0, 3),
                            blurRadius: 0,
                          ),
                        ]
                            : const [],
                      ),
                      child: Text(
                        labels[i],
                        style: KidText.title(
                          size: 16,
                          color: controller.index == i
                              ? Colors.white
                              : KidColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Apparition douce (fade + slide) avec délai selon l'index.
class KidPopIn extends StatefulWidget {
  final Widget child;
  final int index;

  const KidPopIn({super.key, required this.child, this.index = 0});

  @override
  State<KidPopIn> createState() => _KidPopInState();
}

class _KidPopInState extends State<KidPopIn> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    final delay = (widget.index.clamp(0, 8)) * 70;
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOut,
      child: AnimatedScale(
        scale: _visible ? 1 : 0.85,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}