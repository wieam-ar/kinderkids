import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ui/app_ui.dart';
import '../../data/models/science_model.dart';

// ---------------------------------------------------------------------------
// Sound + haptics
// Needs: audioplayers in pubspec.yaml + assets/sounds/*.wav
// ---------------------------------------------------------------------------

class LabSfx {
  LabSfx._();

  static bool enabled = true;
  static final Map<String, AudioPlayer> _players = {};

  static const _names = [
    'pop',
    'splash',
    'sink',
    'boing',
    'ding',
    'win',
    'mix',
    'nope',
    'day',
    'night',
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

Color _darken(Color c, [double amount = 0.16]) {
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
      .toColor();
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ScienceLabScreen extends StatefulWidget {
  const ScienceLabScreen({super.key});

  @override
  State<ScienceLabScreen> createState() => _ScienceLabScreenState();
}

class _ScienceLabScreenState extends State<ScienceLabScreen> {
  int _selectedIndex = 0;
  bool _soundOn = LabSfx.enabled;

  @override
  void initState() {
    super.initState();
    LabSfx.preload();
  }

  Widget _buildLab(String type) {
    switch (type) {
      case 'sink_float':
        return const _SinkFloatLab();
      case 'color_mix':
        return const _ColorMixLab();
      default:
        return const _DayNightLab();
    }
  }

  @override
  Widget build(BuildContext context) {
    final experiments = scienceExperiments;

    if (experiments.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: buildAppBar('Mini Science Lab 🔬'),
        body: const EmptyState(
          emoji: '🔬',
          title: 'No experiments yet',
          message: 'New experiments are on their way!',
        ),
      );
    }

    final selected = _selectedIndex.clamp(0, experiments.length - 1);
    final exp = experiments[selected];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildAppBar('Mini Science Lab 🔬'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: experiments.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, idx) {
                    final e = experiments[idx];
                    final isSelected = idx == selected;
                    return ChoiceChip(
                      label: Text('${e.emoji} ${e.title}'),
                      selected: isSelected,
                      showCheckmark: false,
                      selectedColor: AppColors.purple,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) {
                        if (idx != selected) {
                          LabSfx.play('pop');
                          LabSfx.tap();
                        }
                        setState(() => _selectedIndex = idx);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exp.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          exp.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: _soundOn ? 'Mute' : 'Unmute',
                    onPressed: () {
                      setState(() {
                        _soundOn = !_soundOn;
                        LabSfx.enabled = _soundOn;
                      });
                      if (_soundOn) LabSfx.play('pop');
                    },
                    icon: Icon(
                      _soundOn
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      color: _soundOn ? AppColors.purple : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SoftCard(
                  radius: 24,
                  child: SizedBox(
                    width: double.infinity,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.08, 0),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey<String>(exp.interactiveType),
                        child: Center(
                          child: SingleChildScrollView(
                            child: _buildLab(exp.interactiveType),
                          ),
                        ),
                      ),
                    ),
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

// ---------------------------------------------------------------------------
// Shared "Duolingo-style" building blocks
// ---------------------------------------------------------------------------

/// 3D chunky button: presses down when tapped.
class _ChunkyButton extends StatefulWidget {
  final Widget child;
  final Color color;
  final Color? shadowColor;
  final Color foreground;
  final Color? borderColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;

  const _ChunkyButton({
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
  State<_ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<_ChunkyButton> {
  static const double _depth = 5;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final base = enabled ? widget.color : Colors.grey.shade300;
    final shadow =
    enabled ? (widget.shadowColor ?? _darken(base)) : Colors.grey.shade400;
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

/// Animated progress bar with a label (like the lesson progress bar).
class _ProgressPill extends StatelessWidget {
  final double value;
  final String label;
  final Color color;

  const _ProgressPill({
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
                minHeight: 12,
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

/// Feedback banner that pops in with a bounce when the text changes.
class _FactPill extends StatelessWidget {
  final String text;
  final Color color;

  const _FactPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: Container(
        key: ValueKey<String>(text),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: _darken(color, 0.12),
          ),
        ),
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final double spin;
  final Color color;

  const _Particle(this.angle, this.speed, this.size, this.spin, this.color);
}

/// Particle burst (splash, sparkles, bubbles, confetti).
/// Change [trigger] to fire it. Draws around the center of its box.
class _Burst extends StatefulWidget {
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

  const _Burst({
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
  State<_Burst> createState() => _BurstState();
}

class _BurstState extends State<_Burst> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: widget.duration);
  final math.Random _rnd = math.Random();
  List<_Particle> _ps = const [];

  @override
  void didUpdateWidget(covariant _Burst oldWidget) {
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

/// Horizontal shake (used for "wrong" feedback).
class _Shake extends StatefulWidget {
  final int trigger;
  final Widget child;

  const _Shake({required this.trigger, required this.child});

  @override
  State<_Shake> createState() => _ShakeState();
}

class _ShakeState extends State<_Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void didUpdateWidget(covariant _Shake oldWidget) {
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
        final dx = math.sin(t * math.pi * 6) * 9 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Sink or Float
// ---------------------------------------------------------------------------

class _FloatItem {
  final String emoji;
  final String label;
  final bool floats;
  final String fact;

  const _FloatItem(this.emoji, this.label, this.floats, this.fact);
}

const List<_FloatItem> _floatItems = [
  _FloatItem('🦆', 'Rubber Duck', true, '🦆 Floats! It is light for its size.'),
  _FloatItem('🪨', 'Rock', false, '🪨 Sinks! It is heavy for its size.'),
  _FloatItem('🍎', 'Apple', true, '🍎 Floats! It has tiny air pockets inside.'),
  _FloatItem('🔑', 'Key', false, '🔑 Sinks! Metal is heavy for its size.'),
];

class _SinkFloatLab extends StatefulWidget {
  const _SinkFloatLab();

  @override
  State<_SinkFloatLab> createState() => _SinkFloatLabState();
}

class _SinkFloatLabState extends State<_SinkFloatLab>
    with SingleTickerProviderStateMixin {
  static const double _areaHeight = 240;
  static const double _waterHeight = 150;
  static const double _box = 56;
  static const List<double> _xs = [0.14, 0.38, 0.62, 0.86];

  late final AnimationController _wave =
  AnimationController(vsync: this, duration: const Duration(seconds: 3))
    ..repeat();

  final Set<int> _inWater = {};
  final Set<int> _tested = {};
  final List<int> _splash = List<int>.filled(_floatItems.length, 0);
  final List<int> _bubbles = List<int>.filled(_floatItems.length, 0);
  int _confetti = 0;
  int? _last;
  bool _celebrated = false;
  bool _won = false;

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  void _toggle(int i) {
    final item = _floatItems[i];
    final entering = !_inWater.contains(i);

    setState(() {
      _won = false;
      if (entering) {
        _inWater.add(i);
        _tested.add(i);
        _splash[i]++;
        _last = i;
      } else {
        _inWater.remove(i);
        _last = null;
      }
    });

    if (!entering) {
      LabSfx.play('pop');
      LabSfx.tap();
      return;
    }

    LabSfx.play('splash');
    LabSfx.soft();

    Future.delayed(const Duration(milliseconds: 420), () {
      if (!mounted || !_inWater.contains(i)) return;
      if (item.floats) {
        LabSfx.play('boing', volume: 0.8);
      } else {
        LabSfx.play('sink', volume: 0.8);
        setState(() => _bubbles[i]++);
      }
    });

    if (_tested.length == _floatItems.length && !_celebrated) {
      _celebrated = true;
      Future.delayed(const Duration(milliseconds: 1100), () {
        if (!mounted) return;
        setState(() {
          _confetti++;
          _won = true;
        });
        LabSfx.play('win');
        LabSfx.hard();
      });
    }
  }

  void _reset() {
    LabSfx.play('pop');
    LabSfx.tap();
    setState(() {
      _inWater.clear();
      _tested.clear();
      _last = null;
      _celebrated = false;
      _won = false;
    });
  }

  String get _message {
    if (_won) return '🏆 Amazing! You tested all ${_floatItems.length} items!';
    if (_last != null) return _floatItems[_last!].fact;
    return 'Tap an item to drop it in the water! 💧';
  }

  Color get _messageColor {
    if (_won) return Colors.amber.shade700;
    if (_last != null) {
      return _floatItems[_last!].floats ? Colors.green : Colors.blue;
    }
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ProgressPill(
          value: _tested.length / _floatItems.length,
          label: '${_tested.length}/${_floatItems.length}',
          color: Colors.lightBlue,
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 4,
          children: [
            for (var i = 0; i < _floatItems.length; i++)
              _ChunkyButton(
                color: _inWater.contains(i) ? AppColors.primary : Colors.white,
                shadowColor:
                _inWater.contains(i) ? null : Colors.grey.shade300,
                borderColor: _inWater.contains(i) ? null : Colors.grey.shade300,
                foreground:
                _inWater.contains(i) ? Colors.white : AppColors.textDark,
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                onTap: () => _toggle(i),
                child: Text('${_floatItems[i].emoji} ${_floatItems[i].label}'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: _areaHeight,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              const surfaceY = _areaHeight - _waterHeight - 3;
              const floatTop = surfaceY - _box / 2 + 2;
              const sinkTop = _areaHeight - _box - 4;

              return AnimatedBuilder(
                animation: _wave,
                builder: (context, _) {
                  final phase = _wave.value * 2 * math.pi;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Back water
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: _waterHeight + 8,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(24),
                          ),
                          child: CustomPaint(
                            painter: _WavePainter(
                              phase: phase,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.lightBlue.shade100,
                                  Colors.lightBlue.shade300,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Items
                      for (var i = 0; i < _floatItems.length; i++)
                        _buildItem(i, w, phase, floatTop, sinkTop),
                      // Front water (items look submerged)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: _waterHeight + 8,
                        child: IgnorePointer(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(24),
                            ),
                            child: CustomPaint(
                              painter: _WavePainter(
                                phase: phase + 1.8,
                                amplitude: 4,
                                color: Colors.lightBlue.withOpacity(0.28),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Splashes + bubbles
                      for (var i = 0; i < _floatItems.length; i++) ...[
                        Positioned(
                          left: w * _xs[i] - 100,
                          top: surfaceY - 100,
                          width: 200,
                          height: 200,
                          child: _Burst(
                            trigger: _splash[i],
                            colors: [
                              Colors.lightBlue.shade200,
                              Colors.white,
                              Colors.lightBlue.shade400,
                            ],
                            count: 14,
                            distance: 60,
                            gravity: 55,
                            size: 4.5,
                            angleStart: -math.pi * 0.9,
                            angleEnd: -math.pi * 0.1,
                          ),
                        ),
                        Positioned(
                          left: w * _xs[i] - 100,
                          top: surfaceY + 60 - 100,
                          width: 200,
                          height: 200,
                          child: _Burst(
                            trigger: _bubbles[i],
                            colors: [Colors.white, Colors.lightBlue.shade50],
                            count: 7,
                            distance: 55,
                            gravity: -30,
                            size: 5,
                            angleStart: -math.pi * 0.8,
                            angleEnd: -math.pi * 0.2,
                            hollow: true,
                            duration: const Duration(milliseconds: 1100),
                          ),
                        ),
                      ],
                      // Confetti
                      Positioned.fill(
                        child: _Burst(
                          trigger: _confetti,
                          colors: const [
                            Colors.pink,
                            Colors.amber,
                            Colors.lightBlue,
                            Colors.green,
                            Colors.purple,
                          ],
                          count: 44,
                          distance: 150,
                          gravity: 140,
                          size: 7,
                          confetti: true,
                          duration: const Duration(milliseconds: 1500),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _FactPill(text: _message, color: _messageColor),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: _tested.isEmpty ? null : _reset,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Start over'),
        ),
      ],
    );
  }

  Widget _buildItem(
      int i,
      double w,
      double phase,
      double floatTop,
      double sinkTop,
      ) {
    final item = _floatItems[i];
    final inW = _inWater.contains(i);

    double dy;
    double tilt;
    if (!inW) {
      // Idle hover invites a tap.
      dy = math.sin(phase * 2 + i * 1.3) * 2.5;
      tilt = 0;
    } else if (item.floats) {
      dy = math.sin(phase + i * 1.7) * 3;
      tilt = math.sin(phase + i) * 0.14;
    } else {
      dy = 0;
      tilt = math.sin(phase * 2 + i) * 0.05;
    }

    return AnimatedPositioned(
      duration: Duration(
        milliseconds: inW ? (item.floats ? 1100 : 850) : 500,
      ),
      curve: inW
          ? (item.floats ? Curves.elasticOut : Curves.easeInCubic)
          : Curves.easeOutBack,
      left: w * _xs[i] - _box / 2,
      top: inW ? (item.floats ? floatTop : sinkTop) : 4,
      width: _box,
      height: _box,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _toggle(i),
        child: Center(
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Transform.rotate(
              angle: tilt,
              child: Text(item.emoji, style: const TextStyle(fontSize: 44)),
            ),
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double phase;
  final double amplitude;
  final double frequency;
  final Color? color;
  final Gradient? gradient;

  const _WavePainter({
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
  bool shouldRepaint(covariant _WavePainter old) => old.phase != phase;
}

// ---------------------------------------------------------------------------
// Color Mixing
// ---------------------------------------------------------------------------

enum _Paint {
  red(Colors.red, 'Red', Colors.white),
  yellow(Colors.yellow, 'Yellow', Colors.black87),
  blue(Colors.blue, 'Blue', Colors.white);

  final Color color;
  final String label;
  final Color foreground;

  const _Paint(this.color, this.label, this.foreground);
}

class _MixResult {
  final Color color;
  final String label;
  final String? key; // null = same color (nothing new to discover)

  const _MixResult(this.color, this.label, [this.key]);
}

class _ColorMixLab extends StatefulWidget {
  const _ColorMixLab();

  @override
  State<_ColorMixLab> createState() => _ColorMixLabState();
}

class _ColorMixLabState extends State<_ColorMixLab> {
  _Paint? _first;
  _Paint? _second;
  _MixResult? _result;

  final Set<String> _found = {};
  bool _lastNew = false;

  int _firstTick = 0;
  int _secondTick = 0;
  int _resultTick = 0;
  int _burst = 0;
  int _shake = 0;
  int _bigBurst = 0;

  _MixResult _mix(_Paint a, _Paint b) {
    if (a == b) {
      return _MixResult(a.color, '${a.label} + ${b.label} = still ${a.label}!');
    }
    final pair = {a, b};
    if (pair.containsAll({_Paint.red, _Paint.yellow})) {
      return const _MixResult(
        Colors.orange,
        'Red + Yellow = ORANGE! 🍊',
        'orange',
      );
    }
    if (pair.containsAll({_Paint.blue, _Paint.yellow})) {
      return const _MixResult(
        Colors.green,
        'Blue + Yellow = GREEN! 🥦',
        'green',
      );
    }
    return const _MixResult(Colors.purple, 'Red + Blue = PURPLE! 💜', 'purple');
  }

  void _pick(_Paint paint) {
    LabSfx.tap();

    // Third tap starts a fresh mix.
    if (_first == null || _second != null) {
      LabSfx.play('pop');
      setState(() {
        _first = paint;
        _second = null;
        _result = null;
        _lastNew = false;
        _firstTick++;
      });
      return;
    }

    final result = _mix(_first!, paint);
    final isNew = result.key != null && !_found.contains(result.key);
    if (isNew) _found.add(result.key!);
    final allFound = _found.length == 3;

    setState(() {
      _second = paint;
      _secondTick++;
      _result = result;
      _resultTick++;
      _lastNew = isNew;
      if (result.key == null) {
        _shake++;
      } else {
        _burst++;
      }
    });

    if (result.key == null) {
      LabSfx.play('nope');
      LabSfx.soft();
      return;
    }

    LabSfx.play('mix');
    LabSfx.hard();

    if (isNew) {
      Future.delayed(const Duration(milliseconds: 380), () {
        if (!mounted) return;
        if (allFound) {
          setState(() => _bigBurst++);
          LabSfx.play('win');
        } else {
          LabSfx.play('ding');
        }
      });
    }
  }

  void _reset() {
    LabSfx.play('pop');
    LabSfx.tap();
    setState(() {
      _first = null;
      _second = null;
      _result = null;
      _lastNew = false;
    });
  }

  String get _label {
    if (_result != null) {
      if (_lastNew && _found.length == 3) {
        return '🏆 Color Master! You found all 3 mixes!';
      }
      if (_lastNew) return '🎉 New color! ${_result!.label}';
      return _result!.label;
    }
    if (_first != null) return 'Now pick a second color!';
    return 'Tap 2 colors to mix!';
  }

  Color get _labelColor {
    if (_result != null) {
      if (_result!.key == null) return Colors.orange;
      if (_lastNew && _found.length == 3) return Colors.amber.shade700;
      if (_lastNew) return Colors.green;
      return _result!.color;
    }
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ProgressPill(
              value: _found.length / 3,
              label: '${_found.length}/3 mixes',
              color: Colors.purple,
            ),
            const SizedBox(height: 16),
            _FactPill(text: _label, color: _labelColor),
            const SizedBox(height: 22),
            _Shake(
              trigger: _shake,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PopBlob(color: _first?.color, size: 64, tick: _firstTick),
                  const _Operator('+'),
                  _PopBlob(color: _second?.color, size: 64, tick: _secondTick),
                  const _Operator('='),
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        _PopBlob(
                          color: _result?.color,
                          size: 90,
                          tick: _resultTick,
                          glow: true,
                        ),
                        Positioned(
                          left: -55,
                          top: -55,
                          width: 200,
                          height: 200,
                          child: _Burst(
                            trigger: _burst,
                            colors: [
                              _result?.color ?? Colors.purple,
                              Colors.white,
                              (_result?.color ?? Colors.purple).withOpacity(0.6),
                            ],
                            count: 18,
                            distance: 70,
                            gravity: 30,
                            size: 5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 4,
              children: [
                for (final paint in _Paint.values)
                  _ChunkyButton(
                    color: paint.color,
                    foreground: paint.foreground,
                    onTap: () => _pick(paint),
                    child: Text('💧 ${paint.label}'),
                  ),
              ],
            ),
            TextButton.icon(
              onPressed: _first == null ? null : _reset,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Start over'),
            ),
          ],
        ),
        // Big celebration when all 3 mixes are found
        Positioned.fill(
          child: _Burst(
            trigger: _bigBurst,
            colors: const [
              Colors.pink,
              Colors.amber,
              Colors.lightBlue,
              Colors.green,
              Colors.purple,
              Colors.orange,
            ],
            count: 50,
            distance: 170,
            gravity: 150,
            size: 7,
            confetti: true,
            duration: const Duration(milliseconds: 1600),
          ),
        ),
      ],
    );
  }
}

class _Operator extends StatelessWidget {
  final String symbol;

  const _Operator(this.symbol);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        symbol,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

/// Color blob that pops in with a springy bounce whenever [tick] changes.
class _PopBlob extends StatelessWidget {
  final Color? color;
  final double size;
  final int tick;
  final bool glow;

  const _PopBlob({
    required this.color,
    required this.size,
    required this.tick,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    final fill = color ?? Colors.grey.shade200;
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(tick),
      tween: Tween<double>(begin: color == null ? 1.0 : 0.3, end: 1.0),
      duration: const Duration(milliseconds: 650),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: color == null
              ? Border.all(color: Colors.grey.shade300, width: 2)
              : null,
          boxShadow: glow && color != null
              ? [
            BoxShadow(
              color: fill.withOpacity(0.45),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ]
              : null,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Day & Night
// ---------------------------------------------------------------------------

class _DayNightLab extends StatefulWidget {
  const _DayNightLab();

  @override
  State<_DayNightLab> createState() => _DayNightLabState();
}

class _DayNightLabState extends State<_DayNightLab>
    with SingleTickerProviderStateMixin {
  static const List<Alignment> _stars = [
    Alignment(-0.85, -0.8),
    Alignment(-0.45, -0.45),
    Alignment(-0.1, -0.85),
    Alignment(0.3, -0.5),
    Alignment(0.55, -0.9),
    Alignment(0.9, -0.4),
    Alignment(0.05, -0.15),
    Alignment(-0.9, -0.1),
  ];

  late final AnimationController _t =
  AnimationController(vsync: this, duration: const Duration(seconds: 14))
    ..repeat();

  bool _isDay = true;
  double _turns = 0;
  int _burst = 0;
  int _earthPop = 0;

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  void _spinEarth() {
    setState(() {
      _isDay = !_isDay;
      _turns += 0.5;
      _earthPop++;
    });
    LabSfx.play(_isDay ? 'day' : 'night');
    LabSfx.hard();

    // Sparkles pop when the sun / moon arrives.
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) setState(() => _burst++);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _isDay
                    ? [Colors.lightBlue.shade300, Colors.lightBlue.shade100]
                    : [Colors.indigo.shade900, Colors.indigo.shade600],
              ),
            ),
            child: Stack(
              children: [
                // Twinkling stars
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 600),
                  opacity: _isDay ? 0 : 1,
                  child: SizedBox.expand(
                    child: AnimatedBuilder(
                      animation: _t,
                      builder: (context, _) => Stack(
                        children: [
                          for (var i = 0; i < _stars.length; i++)
                            Align(
                              alignment: _stars[i],
                              child: Opacity(
                                opacity: (0.45 +
                                    0.55 *
                                        (0.5 +
                                            0.5 *
                                                math.sin(
                                                  _t.value *
                                                      2 *
                                                      math.pi *
                                                      7 +
                                                      i * 1.3,
                                                )))
                                    .clamp(0.0, 1.0),
                                child: Text(
                                  i.isEven ? '✨' : '⭐',
                                  style: TextStyle(
                                    fontSize: 14.0 + (i % 3) * 4,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Drifting clouds
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 600),
                  opacity: _isDay ? 1 : 0,
                  child: SizedBox.expand(
                    child: AnimatedBuilder(
                      animation: _t,
                      builder: (context, _) => Stack(
                        children: [
                          for (var j = 0; j < 2; j++)
                            Align(
                              alignment: Alignment(
                                -1.3 + ((_t.value + j * 0.5) % 1.0) * 2.6,
                                j == 0 ? -0.65 : -0.15,
                              ),
                              child: Text(
                                '☁️',
                                style: TextStyle(fontSize: 38.0 - j * 8),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Sun
                AnimatedAlign(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeInOutBack,
                  alignment: _isDay
                      ? const Alignment(0.65, -0.4)
                      : const Alignment(0.65, 2.4),
                  child: GestureDetector(
                    onTap: _spinEarth,
                    child: const Text('☀️', style: TextStyle(fontSize: 52)),
                  ),
                ),
                // Moon
                AnimatedAlign(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeInOutBack,
                  alignment: _isDay
                      ? const Alignment(-0.65, 2.4)
                      : const Alignment(-0.65, -0.4),
                  child: GestureDetector(
                    onTap: _spinEarth,
                    child: const Text('🌙', style: TextStyle(fontSize: 48)),
                  ),
                ),
                // Hill (sun / moon rise from behind it)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    height: 34,
                    decoration: BoxDecoration(
                      color: _isDay
                          ? Colors.green.shade400
                          : Colors.green.shade900,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.elliptical(220, 34),
                      ),
                    ),
                  ),
                ),
                // Sparkles
                Align(
                  alignment: _isDay
                      ? const Alignment(0.65, -0.4)
                      : const Alignment(-0.65, -0.4),
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: _Burst(
                      trigger: _burst,
                      colors: _isDay
                          ? [
                        Colors.yellow,
                        Colors.orangeAccent,
                        Colors.white,
                      ]
                          : [
                        Colors.white,
                        Colors.yellow.shade200,
                        Colors.purple.shade100,
                      ],
                      count: 16,
                      distance: 62,
                      gravity: 10,
                      size: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _spinEarth,
          child: TweenAnimationBuilder<double>(
            key: ValueKey<int>(_earthPop),
            tween: Tween<double>(begin: 0.7, end: 1.0),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: AnimatedRotation(
              turns: _turns,
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeInOut,
              child: const Text('🌍', style: TextStyle(fontSize: 44)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _FactPill(
          text: _isDay
              ? '☀️ Day Time! Your side of Earth faces the Sun.'
              : '🌙 Night Time! Your side turned away from the Sun. ✨',
          color: _isDay ? Colors.orange : Colors.indigo,
        ),
        const SizedBox(height: 12),
        _ChunkyButton(
          color: _isDay ? AppColors.primary : Colors.indigo,
          onTap: _spinEarth,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.sync_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Spin Earth 🌍'),
            ],
          ),
        ),
      ],
    );
  }
}