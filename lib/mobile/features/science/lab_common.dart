import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../core/ui/app_ui.dart';
import 'lab_i18n.dart';

// ---------------------------------------------------------------------------
// Sound + voice + haptics
// Needs: audioplayers, flutter_tts, assets/sounds/*.wav
// ---------------------------------------------------------------------------

class LabSfx {
  LabSfx._();

  static bool enabled = true;
  static final Map<String, AudioPlayer> _players = {};

  static const _names = [
    'pop',
    'ding',
    'win',
    'nope',
    'water_fill',
    'splash_small',
    'splash_big',
    'splash_key',
    'squeak',
    'bubbles',
    'bloop',
    'thud',
    'drip',
    'throw',
    'collide',
    'splat',
    'mix',
    'spin',
    'day',
    'night',
    'twinkle',
  ];

  static Future<void> preload() async {
    try {
      await AudioCache.instance.loadAll(
        _names.map((n) => 'sounds/$n.wav').toList(),
      );
    } catch (_) {}
  }

  static Future<void> play(String name, {double volume = 1.0}) async {
    if (!enabled) return;
    try {
      final player = _players.putIfAbsent(name, () {
        final p = AudioPlayer();
        p.setPlayerMode(PlayerMode.lowLatency);
        p.setReleaseMode(ReleaseMode.stop);
        return p;
      });
      await player.stop();
      await player.play(AssetSource('sounds/$name.wav'), volume: volume);
    } catch (_) {
      // Sound is a bonus: never crash the lab because of audio.
    }
  }

  // ---- Voice (text to speech) in the current language ----
  static final FlutterTts _tts = FlutterTts();
  static String? _ttsLocale;

  /// Removes emojis so the voice does not try to read them.
  static String _clean(String text) {
    return text
        .replaceAll(
          RegExp(
            r'[\u{1F000}-\u{1FFFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}]',
            unicode: true,
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static Future<void> speak(String text) async {
    if (!enabled) return;
    try {
      final i18n = LabI18n.instance;
      if (_ttsLocale != i18n.ttsLocale) {
        await _tts.setLanguage(i18n.ttsLocale);
        await _tts.setSpeechRate(i18n.lang == LabLang.ar ? 0.42 : 0.45);
        await _tts.setPitch(1.15);
        await _tts.setVolume(1.0);
        _ttsLocale = i18n.ttsLocale;
      }
      final clean = _clean(text);
      if (clean.isEmpty) return;
      await _tts.stop();
      await _tts.speak(clean);
    } catch (_) {}
  }

  static void stopSpeech() {
    try {
      _tts.stop();
    } catch (_) {}
  }

  static void tap() {
    if (enabled) HapticFeedback.selectionClick();
  }

  static void soft() {
    if (enabled) HapticFeedback.lightImpact();
  }

  static void hard() {
    if (enabled) HapticFeedback.mediumImpact();
  }
}

Color labDarken(Color c, [double amount = 0.16]) {
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
      .toColor();
}

Color labLighten(Color c, [double amount = 0.2]) {
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
      .toColor();
}

/// Makes a State rebuild when the language changes.
mixin LabLangListener<T extends StatefulWidget> on State<T> {
  LabI18n get i18n => LabI18n.instance;

  String tr(String key, [Map<String, String>? args]) => i18n.t(key, args);

  @override
  void initState() {
    super.initState();
    i18n.addListener(_langChanged);
  }

  void _langChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    i18n.removeListener(_langChanged);
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Chunky 3D button
// ---------------------------------------------------------------------------

class LabChunkyButton extends StatefulWidget {
  final Widget child;
  final Color color;
  final Color? shadowColor;
  final Color foreground;
  final Color? borderColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;

  const LabChunkyButton({
    super.key,
    required this.child,
    required this.color,
    required this.onTap,
    this.shadowColor,
    this.foreground = Colors.white,
    this.borderColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.radius = 18,
  });

  @override
  State<LabChunkyButton> createState() => _LabChunkyButtonState();
}

class _LabChunkyButtonState extends State<LabChunkyButton> {
  static const double _depth = 5;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final base = enabled ? widget.color : Colors.grey.shade300;
    final shadow = enabled
        ? (widget.shadowColor ?? labDarken(base))
        : Colors.grey.shade400;
    final fg = enabled ? widget.foreground : Colors.grey.shade600;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        margin: EdgeInsets.only(
          top: _down ? _depth : 0,
          bottom: _down ? 0 : _depth,
        ),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(widget.radius),
          border: widget.borderColor == null
              ? null
              : Border.all(color: widget.borderColor!, width: 2),
          boxShadow: _down
              ? const []
              : [BoxShadow(color: shadow, offset: const Offset(0, _depth))],
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progress bar
// ---------------------------------------------------------------------------

class LabProgressPill extends StatelessWidget {
  final double value;
  final String label;
  final Color color;

  const LabProgressPill({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 14,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mascot with speech bubble (the text is typed while the voice reads it)
// ---------------------------------------------------------------------------

class LabMascotBubble extends StatelessWidget {
  final String text;
  final Color color;
  final String mascot;

  const LabMascotBubble({
    super.key,
    required this.text,
    required this.color,
    this.mascot = '🦉',
  });

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final dark = labDarken(color, 0.14);
    final fill = Color.alphaBlend(color.withOpacity(0.13), Colors.white);
    final style = TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 15,
      height: 1.25,
      color: dark,
    );
    final runes = text.runes.toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TweenAnimationBuilder<double>(
          key: ValueKey<String>('m$text'),
          tween: Tween<double>(begin: 0.7, end: 1.0),
          duration: const Duration(milliseconds: 650),
          curve: Curves.elasticOut,
          builder: (context, s, child) => Transform.scale(
            scale: s,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
          child: Text(mascot, style: const TextStyle(fontSize: 50)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color, width: 2),
                ),
                child: TweenAnimationBuilder<int>(
                  key: ValueKey<String>(text),
                  tween: IntTween(begin: 0, end: runes.length),
                  duration: Duration(
                    milliseconds: (runes.length * 26).clamp(250, 1800),
                  ),
                  builder: (context, n, _) => Stack(
                    children: [
                      Opacity(opacity: 0, child: Text(text, style: style)),
                      Text(
                        String.fromCharCodes(runes.take(n)),
                        style: style,
                      ),
                    ],
                  ),
                ),
              ),
              PositionedDirectional(
                start: -7,
                bottom: 14,
                child: Transform.rotate(
                  angle: rtl ? -math.pi / 4 : math.pi / 4,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: fill,
                      border: Border(
                        left: rtl
                            ? BorderSide.none
                            : BorderSide(color: color, width: 2),
                        right: rtl
                            ? BorderSide(color: color, width: 2)
                            : BorderSide.none,
                        bottom: BorderSide(color: color, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Particle burst (splash, sparkles, bubbles, dust, confetti)
// ---------------------------------------------------------------------------

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final double spin;
  final Color color;

  const _Particle(this.angle, this.speed, this.size, this.spin, this.color);
}

/// Change [trigger] to fire it. Draws around the center of its box.
class LabBurst extends StatefulWidget {
  final int trigger;
  final List<Color> colors;
  final int count;
  final double distance;
  final double gravity;
  final double size;
  final double angleStart;
  final double angleEnd;
  final bool hollow;
  final bool confetti;
  final Duration duration;

  const LabBurst({
    super.key,
    required this.trigger,
    required this.colors,
    this.count = 14,
    this.distance = 60,
    this.gravity = 40,
    this.size = 5,
    this.angleStart = 0,
    this.angleEnd = math.pi * 2,
    this.hollow = false,
    this.confetti = false,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<LabBurst> createState() => _LabBurstState();
}

class _LabBurstState extends State<LabBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  final math.Random _rnd = math.Random();
  List<_Particle> _ps = const [];

  @override
  void didUpdateWidget(covariant LabBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) {
      _ps = List.generate(widget.count, (i) {
        return _Particle(
          widget.angleStart +
              _rnd.nextDouble() * (widget.angleEnd - widget.angleStart),
          0.45 + _rnd.nextDouble() * 0.55,
          widget.size * (0.6 + _rnd.nextDouble() * 0.8),
          _rnd.nextDouble() * math.pi * 2,
          widget.colors[_rnd.nextInt(widget.colors.length)],
        );
      });
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _BurstPainter(
            particles: _ps,
            progress: _c.value,
            distance: widget.distance,
            gravity: widget.gravity,
            hollow: widget.hollow,
            confetti: widget.confetti,
          ),
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final double distance;
  final double gravity;
  final bool hollow;
  final bool confetti;

  const _BurstPainter({
    required this.particles,
    required this.progress,
    required this.distance,
    required this.gravity,
    required this.hollow,
    required this.confetti,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty || progress <= 0 || progress >= 1) return;
    final center = size.center(Offset.zero);
    final out = Curves.easeOutCubic.transform(progress);
    final opacity = (1 - math.pow(progress, 2.2)).toDouble().clamp(0.0, 1.0);

    for (final p in particles) {
      final dx = math.cos(p.angle) * distance * p.speed * out;
      final dy = math.sin(p.angle) * distance * p.speed * out +
          gravity * progress * progress;
      final pos = center + Offset(dx, dy);
      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..style = hollow ? PaintingStyle.stroke : PaintingStyle.fill
        ..strokeWidth = 1.6;
      final r = p.size * (1 - progress * 0.4);

      if (confetti) {
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(p.spin + progress * 8);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: r * 1.6, height: r),
            const Radius.circular(2),
          ),
          paint,
        );
        canvas.restore();
      } else {
        canvas.drawCircle(pos, r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) =>
      old.progress != progress || old.particles != particles;
}

// ---------------------------------------------------------------------------
// Shake
// ---------------------------------------------------------------------------

class LabShake extends StatefulWidget {
  final int trigger;
  final Widget child;
  final double strength;

  const LabShake({
    super.key,
    required this.trigger,
    required this.child,
    this.strength = 9,
  });

  @override
  State<LabShake> createState() => _LabShakeState();
}

class _LabShakeState extends State<LabShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void didUpdateWidget(covariant LabShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) _c.forward(from: 0);
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
      child: widget.child,
      builder: (context, child) {
        final t = _c.value;
        final dx = math.sin(t * math.pi * 6) * widget.strength * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Blob character with a face (used by the Color War and the Sun)
// expression: 0 idle, 1 surprised, 2 happy, 3 sad, 4 sleeping
// ---------------------------------------------------------------------------

class LabBlob extends StatelessWidget {
  final Color? color;
  final double size;
  final int expression;
  final double look; // -1 (left) .. 1 (right)
  final bool glow;

  const LabBlob({
    super.key,
    required this.color,
    required this.size,
    this.expression = 0,
    this.look = 0,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    final fill = color ?? Colors.grey.shade300;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.5),
          radius: 0.95,
          colors: [labLighten(fill, 0.14), fill],
        ),
        boxShadow: [
          BoxShadow(
            color: fill.withOpacity(glow ? 0.55 : 0.3),
            blurRadius: glow ? 22 : 8,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: CustomPaint(painter: _FacePainter(expression, look)),
    );
  }
}

class _FacePainter extends CustomPainter {
  final int expression;
  final double look;

  const _FacePainter(this.expression, this.look);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = size.center(Offset.zero);
    final dark = const Color(0xFF3A1F2B);
    final stroke = Paint()
      ..color = dark
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.035
      ..strokeCap = StrokeCap.round;
    final fillDark = Paint()..color = dark;

    // Shine
    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(-s * 0.24, -s * 0.3),
        width: s * 0.22,
        height: s * 0.12,
      ),
      Paint()..color = Colors.white.withOpacity(0.4),
    );

    final eyeL = c + Offset(-s * 0.19, -s * 0.06);
    final eyeR = c + Offset(s * 0.19, -s * 0.06);

    if (expression == 4) {
      // Closed eyes + flat mouth (sleeping)
      for (final e in [eyeL, eyeR]) {
        canvas.drawArc(
          Rect.fromCenter(center: e, width: s * 0.2, height: s * 0.12),
          0.1,
          math.pi - 0.2,
          false,
          stroke,
        );
      }
      canvas.drawLine(
        c + Offset(-s * 0.08, s * 0.2),
        c + Offset(s * 0.08, s * 0.2),
        stroke,
      );
      return;
    }

    for (final e in [eyeL, eyeR]) {
      canvas.drawCircle(e, s * 0.115, Paint()..color = Colors.white);
      canvas.drawCircle(
        e + Offset(look * s * 0.04, expression == 3 ? s * 0.03 : 0),
        s * (expression == 1 ? 0.04 : 0.062),
        fillDark,
      );
    }

    switch (expression) {
      case 1: // surprised "O"
        canvas.drawOval(
          Rect.fromCenter(
            center: c + Offset(0, s * 0.24),
            width: s * 0.11,
            height: s * 0.15,
          ),
          fillDark,
        );
        break;
      case 2: // happy: open smile + blush
        final path = Path()
          ..addArc(
            Rect.fromCenter(
              center: c + Offset(0, s * 0.13),
              width: s * 0.36,
              height: s * 0.3,
            ),
            0,
            math.pi,
          )
          ..close();
        canvas.drawPath(path, fillDark);
        canvas.drawOval(
          Rect.fromCenter(
            center: c + Offset(0, s * 0.265),
            width: s * 0.16,
            height: s * 0.08,
          ),
          Paint()..color = const Color(0xFFFF7F9E),
        );
        for (final dx in [-0.31, 0.31]) {
          canvas.drawCircle(
            c + Offset(s * dx, s * 0.1),
            s * 0.06,
            Paint()..color = const Color(0xFFFF6F91).withOpacity(0.5),
          );
        }
        break;
      case 3: // sad
        canvas.drawArc(
          Rect.fromCenter(
            center: c + Offset(0, s * 0.3),
            width: s * 0.26,
            height: s * 0.16,
          ),
          math.pi + 0.2,
          math.pi - 0.4,
          false,
          stroke,
        );
        break;
      default: // idle smile
        canvas.drawArc(
          Rect.fromCenter(
            center: c + Offset(0, s * 0.14),
            width: s * 0.3,
            height: s * 0.2,
          ),
          0.2,
          math.pi - 0.4,
          false,
          stroke,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _FacePainter old) =>
      old.expression != expression || old.look != look;
}

// ---------------------------------------------------------------------------
// Wave painter (water)
// ---------------------------------------------------------------------------

class LabWavePainter extends CustomPainter {
  final double phase;
  final double amplitude;
  final double frequency;
  final Color? color;
  final Gradient? gradient;

  const LabWavePainter({
    required this.phase,
    this.amplitude = 5,
    this.frequency = 2,
    this.color,
    this.gradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 4) {
      final y = amplitude +
          amplitude *
              math.sin(x / size.width * 2 * math.pi * frequency + phase);
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();

    final paint = Paint();
    if (gradient != null) {
      paint.shader = gradient!.createShader(Offset.zero & size);
    } else {
      paint.color = color ?? Colors.blue;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LabWavePainter old) => old.phase != phase;
}

// ---------------------------------------------------------------------------
// Screen-level widgets: card, backdrop, tabs, language bar
// ---------------------------------------------------------------------------

class LabCard extends StatelessWidget {
  final Color color;
  final Widget child;

  const LabCard({super.key, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withOpacity(0.35), width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Soft colored background with emojis floating up and down.
class LabBackdrop extends StatefulWidget {
  final Color color;
  final List<String> emojis;

  const LabBackdrop({super.key, required this.color, required this.emojis});

  @override
  State<LabBackdrop> createState() => _LabBackdropState();
}

class _LabBackdropState extends State<LabBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 24))
        ..repeat();

  static const int _count = 12;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [widget.color.withOpacity(0.22), Colors.white],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          return AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              return Stack(
                children: [
                  for (var i = 0; i < _count; i++)
                    Positioned(
                      left: ((i * 0.173 + 0.05) % 1.0) * c.maxWidth +
                          math.sin(_c.value * 2 * math.pi * 2 + i) * 14,
                      top: (1 -
                              ((_c.value * (1 + i % 2) + i / _count) % 1.0)) *
                          (c.maxHeight + 40) -
                          30,
                      child: Opacity(
                        opacity: 0.22,
                        child: Text(
                          widget.emojis[i % widget.emojis.length],
                          style: TextStyle(fontSize: 20.0 + (i % 4) * 7),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class LabTabButton extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const LabTabButton({
    super.key,
    required this.emoji,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LabChunkyButton(
      color: selected ? color : Colors.white,
      shadowColor: selected ? labDarken(color, 0.18) : Colors.grey.shade300,
      borderColor: selected ? null : Colors.grey.shade300,
      foreground: selected ? Colors.white : AppColors.textDark,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      radius: 18,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: selected ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 450),
            curve: Curves.elasticOut,
            child: Text(emoji, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class LabLangBar extends StatelessWidget {
  const LabLangBar({super.key});

  static const _items = [
    (LabLang.en, '🇬🇧', 'English'),
    (LabLang.fr, '🇫🇷', 'Français'),
    (LabLang.ar, '🇲🇦', 'العربية'),
  ];

  @override
  Widget build(BuildContext context) {
    final i18n = LabI18n.instance;
    return AnimatedBuilder(
      animation: i18n,
      builder: (context, _) {
        return Row(
          children: [
            for (final item in _items) ...[
              Expanded(
                child: LabChunkyButton(
                  color: i18n.lang == item.$1
                      ? const Color(0xFF7C4DFF)
                      : Colors.white,
                  shadowColor: i18n.lang == item.$1
                      ? const Color(0xFF5B34CC)
                      : Colors.grey.shade300,
                  borderColor:
                      i18n.lang == item.$1 ? null : Colors.grey.shade300,
                  foreground: i18n.lang == item.$1
                      ? Colors.white
                      : AppColors.textDark,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                  radius: 14,
                  onTap: () {
                    LabSfx.stopSpeech();
                    LabSfx.play('pop');
                    LabSfx.tap();
                    i18n.setLang(item.$1);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.$2, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          item.$3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (item != _items.last) const SizedBox(width: 8),
            ],
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Stage complete: water rises from the bottom of the screen, then a
// congratulation card pops in. Usable from any screen:
//   await showStageComplete(context, emoji: '🏆', message: '...');
// ---------------------------------------------------------------------------

Future<void> showStageComplete(
  BuildContext context, {
  required String emoji,
  required String message,
  String? title,
}) {
  LabSfx.stopSpeech();
  LabSfx.play('water_fill');
  LabSfx.soft();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (context, _, __) => Directionality(
      textDirection: LabI18n.instance.direction,
      child: _StageCompleteView(
        emoji: emoji,
        title: title ?? LabI18n.instance.t('stage_title'),
        message: message,
      ),
    ),
  );
}

class _StageCompleteView extends StatefulWidget {
  final String emoji;
  final String title;
  final String message;

  const _StageCompleteView({
    required this.emoji,
    required this.title,
    required this.message,
  });

  @override
  State<_StageCompleteView> createState() => _StageCompleteViewState();
}

class _StageCompleteViewState extends State<_StageCompleteView>
    with TickerProviderStateMixin {
  late final AnimationController _rise = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2300),
  );
  late final AnimationController _wave =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat();
  late final AnimationController _card = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  int _confetti = 0;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _runIn();
  }

  Future<void> _runIn() async {
    await _rise.forward();
    if (!mounted) return;
    LabSfx.play('win');
    LabSfx.hard();
    setState(() => _confetti++);
    _card.forward();
    LabSfx.speak('${widget.title} ${widget.message}');
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    LabSfx.play('pop');
    LabSfx.tap();
    LabSfx.stopSpeech();
    await _card.reverse();
    if (!mounted) return;
    await _rise.reverse(); // the water drains away
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _rise.dispose();
    _wave.dispose();
    _card.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = math.min(MediaQuery.of(context).size.width - 48, 340.0);

    return WillPopScope(
      onWillPop: () async => false,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([_rise, _wave]),
                builder: (context, _) => CustomPaint(
                  painter: _RisingWaterPainter(
                    level: Curves.easeInOut.transform(_rise.value),
                    phase: _wave.value * 2 * math.pi,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: LabBurst(
                trigger: _confetti,
                colors: const [
                  Colors.pink,
                  Colors.amber,
                  Colors.white,
                  Colors.green,
                  Colors.purple,
                  Colors.orange,
                ],
                count: 60,
                distance: 190,
                gravity: 170,
                size: 8,
                confetti: true,
                duration: const Duration(milliseconds: 1700),
              ),
            ),
            Center(
              child: ScaleTransition(
                scale: CurvedAnimation(parent: _card, curve: Curves.elasticOut),
                child: FadeTransition(
                  opacity: _card,
                  child: Container(
                    width: width,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.emoji, style: const TextStyle(fontSize: 64)),
                        const SizedBox(height: 8),
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: LabChunkyButton(
                            color: Colors.green,
                            onTap: _close,
                            child: Center(
                              child: Text(
                                '${LabI18n.instance.t('cont')} ✨',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RisingWaterPainter extends CustomPainter {
  final double level; // 0 = empty, 1 = screen full
  final double phase;

  const _RisingWaterPainter({required this.level, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    if (level <= 0) return;
    final base = size.height * (1 - level * 1.12);

    void wave(double amp, double ph, double freq, Paint paint) {
      final path = Path()..moveTo(0, size.height + 2);
      for (double x = 0; x <= size.width + 4; x += 4) {
        final y =
            base + amp * math.sin(x / size.width * 2 * math.pi * freq + ph);
        path.lineTo(x, y);
      }
      path.lineTo(size.width + 4, size.height + 2);
      path.close();
      canvas.drawPath(path, paint);
    }

    wave(
      16,
      phase + 1.5,
      1.5,
      Paint()..color = Colors.lightBlue.shade200.withOpacity(0.92),
    );
    wave(
      12,
      phase,
      2,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.lightBlue.shade400, Colors.blue.shade700],
        ).createShader(
          Rect.fromLTWH(0, base - 20, size.width, size.height - base + 20),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _RisingWaterPainter old) =>
      old.level != level || old.phase != phase;
}
