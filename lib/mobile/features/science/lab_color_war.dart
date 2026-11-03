import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'lab_common.dart';

enum _Paint {
  red('red', Colors.red, Colors.white),
  yellow('yellow', Colors.yellow, Colors.black87),
  blue('blue', Colors.blue, Colors.white);

  final String key;
  final Color color;
  final Color foreground;

  const _Paint(this.key, this.color, this.foreground);
}

class _MixResult {
  final Color color;
  final String key; // orange / green / purple, or the paint key if same
  final bool isMix;

  const _MixResult(this.color, this.key, this.isMix);
}

class _Splat {
  final Color color;
  final double x; // 0..1
  final double y; // 0..1
  final double r;
  final int seed;

  const _Splat(this.color, this.x, this.y, this.r, this.seed);
}

class ColorWarLab extends StatefulWidget {
  const ColorWarLab({super.key});

  @override
  State<ColorWarLab> createState() => _ColorWarLabState();
}

class _ColorWarLabState extends State<ColorWarLab>
    with TickerProviderStateMixin, LabLangListener<ColorWarLab> {
  static const double _h = 300;
  static const double _floorH = 56;
  static const double _shooter = 64;
  static const double _blobby = 100;
  static const double _hitY = 78; // where the two balloons collide

  late final AnimationController _fight = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  late final AnimationController _idle =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat();
  late final AnimationController _splatC = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );

  final math.Random _rnd = math.Random();

  _Paint? _first;
  _Paint? _second;
  Color? _blobColor;
  _MixResult? _result;
  final Set<String> _found = {};
  final List<_Splat> _splats = [];

  bool _fighting = false;
  bool _finishing = false;
  bool _lastNew = false;
  int _expr = 0; // blobby face
  int _jelly = 0;
  int _leftTick = 0;
  int _rightTick = 0;
  int _boom = 0;
  int _shake = 0;

  String Function() _say = () => '';
  Color _sayColor = Colors.blueGrey;

  @override
  void initState() {
    super.initState();
    _say = () => tr('war_hint0');
  }

  @override
  void dispose() {
    LabSfx.stopSpeech();
    _fight.dispose();
    _idle.dispose();
    _splatC.dispose();
    super.dispose();
  }

  _MixResult _mix(_Paint a, _Paint b) {
    if (a == b) return _MixResult(a.color, a.key, false);
    final pair = {a, b};
    if (pair.containsAll({_Paint.red, _Paint.yellow})) {
      return const _MixResult(Colors.orange, 'orange', true);
    }
    if (pair.containsAll({_Paint.blue, _Paint.yellow})) {
      return const _MixResult(Colors.green, 'green', true);
    }
    return const _MixResult(Colors.purple, 'purple', true);
  }

  void _pick(_Paint p) {
    if (_fighting) return;
    LabSfx.tap();

    // First fighter (or a new round)
    if (_first == null || _second != null) {
      LabSfx.play('pop');
      LabSfx.speak(tr('col_${p.key}'));
      setState(() {
        _first = p;
        _second = null;
        _result = null;
        _blobColor = null;
        _lastNew = false;
        _expr = 0;
        _leftTick++;
        _say = () => tr('war_hint1');
        _sayColor = Colors.blueGrey;
      });
      return;
    }

    _startFight(_first!, p);
  }

  void _startFight(_Paint a, _Paint b) {
    final result = _mix(a, b);
    final isNew = result.isMix && !_found.contains(result.key);

    setState(() {
      _second = b;
      _rightTick++;
      _fighting = true;
      _expr = 1;
      _say = () => tr('war_fight', {
            'a': tr('col_${a.key}'),
            'b': tr('col_${b.key}'),
          });
      _sayColor = Colors.deepOrange;
    });

    _fight.forward(from: 0);
    LabSfx.play('throw');
    LabSfx.soft();
    LabSfx.speak(_say());

    // Collision of the two paint balloons
    Future.delayed(const Duration(milliseconds: 760), () {
      if (!mounted) return;
      setState(() => _boom++);
      LabSfx.play('collide');
      LabSfx.hard();
    });

    // The mixed paint falls on Blobby
    Future.delayed(const Duration(milliseconds: 1180), () {
      if (!mounted) return;
      setState(() {
        _blobColor = result.color;
        _result = result;
        _jelly++;
        _lastNew = isNew;
        if (isNew) _found.add(result.key);
        _expr = result.isMix ? 2 : 3;
        if (!result.isMix) _shake++;
        _addSplat(result.color);
        final all = _found.length == 3;
        if (!result.isMix) {
          _say = () => tr('war_same', {'a': tr('col_${result.key}')});
          _sayColor = Colors.deepOrange;
        } else if (isNew && all) {
          _say = () => tr('war_master');
          _sayColor = Colors.amber.shade700;
        } else {
          _say = () =>
              (isNew ? tr('war_new') : '') + tr('war_${result.key}');
          _sayColor = isNew ? Colors.green : result.color;
        }
      });
      LabSfx.play('splat');
      if (result.isMix) {
        LabSfx.play('mix');
        LabSfx.hard();
      } else {
        LabSfx.play('nope');
        LabSfx.soft();
      }
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) LabSfx.speak(_say());
      });
      if (isNew) {
        Future.delayed(const Duration(milliseconds: 650), () {
          if (!mounted) return;
          if (_found.length == 3) {
            _finishStage();
          } else {
            LabSfx.play('ding');
          }
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 1550), () {
      if (mounted) setState(() => _fighting = false);
    });
  }

  void _addSplat(Color color) {
    double x;
    double y;
    int guard = 0;
    do {
      x = 0.08 + _rnd.nextDouble() * 0.84;
      y = 0.1 + _rnd.nextDouble() * 0.5;
      guard++;
    } while ((x - 0.5).abs() < 0.2 && y > 0.3 && guard < 12);
    _splats.add(_Splat(color, x, y, 26 + _rnd.nextDouble() * 22, _rnd.nextInt(9999)));
    if (_splats.length > 9) _splats.removeAt(0);
    _splatC.forward(from: 0);
  }

  Future<void> _finishStage() async {
    if (_finishing) return;
    _finishing = true;
    await Future.delayed(const Duration(milliseconds: 3200));
    if (!mounted) return;
    await showStageComplete(context, emoji: '🎨', message: tr('war_done'));
    _finishing = false;
    if (!mounted) return;
    _clearAll();
  }

  void _reset() {
    LabSfx.play('pop');
    LabSfx.tap();
    LabSfx.stopSpeech();
    _clearAll();
  }

  void _clearAll() {
    setState(() {
      _first = null;
      _second = null;
      _result = null;
      _blobColor = null;
      _found.clear();
      _splats.clear();
      _lastNew = false;
      _fighting = false;
      _expr = 0;
      _say = () => tr('war_hint0');
      _sayColor = Colors.blueGrey;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LabProgressPill(
          value: _found.length / 3,
          label: tr('war_mixes', {'n': '${_found.length}'}),
          color: Colors.pink,
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: _h,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, c) {
                return AnimatedBuilder(
                  animation: Listenable.merge([_fight, _idle, _splatC]),
                  builder: (context, _) => _arena(c.maxWidth),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 2,
          children: [
            for (final p in _Paint.values)
              LabChunkyButton(
                color: p.color,
                foreground: p.foreground,
                onTap: _fighting ? null : () => _pick(p),
                child: Text('💧 ${tr('col_${p.key}')}'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        LabMascotBubble(text: _say(), color: _sayColor),
        TextButton.icon(
          onPressed: (_first == null && _found.isEmpty) || _fighting
              ? null
              : _reset,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(tr('start_over')),
        ),
      ],
    );
  }

  // squash & stretch of the shooters while throwing
  double _shooterScale(double v) {
    if (v <= 0 || v >= 0.35) return 1.0;
    if (v < 0.08) return 1 - v / 0.08 * 0.16;
    if (v < 0.2) return 0.84 + (v - 0.08) / 0.12 * 0.36;
    return 1.2 - (v - 0.2) / 0.15 * 0.2;
  }

  Widget _arena(double w) {
    final v = _fight.value;
    final idle = math.sin(_idle.value * 2 * math.pi);
    final floorY = _h - _floorH;
    final leftX = w * 0.15;
    final rightX = w * 0.85;
    final midX = w * 0.5;
    final shooterTop = floorY - _shooter + 10;
    final blobTop = floorY - _blobby + 8;

    // Balloons flying to the middle
    final flyP = ((v - 0.08) / 0.39).clamp(0.0, 1.0);
    final showBalloons = v > 0.08 && v < 0.5;
    Offset balloonPos(double fromX, double toX, double p) {
      final e = Curves.easeIn.transform(p);
      final x = fromX + (toX - fromX) * e;
      final yStart = shooterTop + 10;
      final y = yStart + (_hitY - yStart) * e - 70 * math.sin(math.pi * p);
      return Offset(x, y);
    }

    // Mixed paint falling on Blobby
    final dropP = ((v - 0.5) / 0.28).clamp(0.0, 1.0);
    final showDrop = v >= 0.5 && v < 0.79;
    final dropY = _hitY + (blobTop + 14 - _hitY) * Curves.easeIn.transform(dropP);

    final mixColor = (_first != null && _second != null)
        ? _mix(_first!, _second!).color
        : Colors.purple;

    return LabShake(
      trigger: _boom,
      strength: 6,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Wall + floor
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF6E5), Color(0xFFFFE3F0)],
                ),
              ),
            ),
          ),
          // Splats stay on the wall
          Positioned.fill(
            child: CustomPaint(
              painter: _SplatsPainter(
                _splats,
                Curves.easeOutBack.transform(_splatC.value).clamp(0.0, 1.3),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _floorH,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF9CCC65), Color(0xFF7CB342)],
                ),
              ),
            ),
          ),

          // VS banner
          Positioned(
            left: midX - 40,
            top: 6,
            width: 80,
            child: IgnorePointer(
              child: AnimatedScale(
                scale: _fighting && v < 0.5 ? 1 : 0,
                duration: const Duration(milliseconds: 450),
                curve: Curves.elasticOut,
                child: const Text(
                  'VS ⚡',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFE53935),
                  ),
                ),
              ),
            ),
          ),

          // Left fighter
          _shooterWidget(
            x: leftX,
            top: shooterTop + idle * 2,
            color: _first?.color,
            tick: _leftTick,
            scale: _shooterScale(v),
            look: 1,
            label: _first == null ? null : tr('col_${_first!.key}'),
          ),
          // Right fighter
          _shooterWidget(
            x: rightX,
            top: shooterTop - idle * 2,
            color: _second?.color,
            tick: _rightTick,
            scale: _shooterScale(v),
            look: -1,
            label: _second == null ? null : tr('col_${_second!.key}'),
          ),

          // Blobby (the target)
          Positioned(
            left: midX - _blobby / 2,
            top: blobTop + idle * 3,
            width: _blobby,
            height: _blobby,
            child: LabShake(
              trigger: _shake,
              child: TweenAnimationBuilder<double>(
                key: ValueKey<int>(_jelly),
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.elasticOut,
                builder: (context, k, child) {
                  final sx = _jelly == 0 ? 1.0 : 1.35 - 0.35 * k;
                  final sy = _jelly == 0 ? 1.0 : 0.65 + 0.35 * k;
                  return Transform(
                    alignment: Alignment.bottomCenter,
                    transform: Matrix4.diagonal3Values(sx, sy, 1),
                    child: child,
                  );
                },
                child: LabBlob(
                  color: _blobColor,
                  size: _blobby,
                  expression: _expr,
                  glow: _blobColor != null,
                ),
              ),
            ),
          ),

          // Flying balloons (with a small trail)
          if (showBalloons) ...[
            for (var k = 3; k >= 0; k--) ...[
              _balloon(
                balloonPos(leftX, midX - 12, (flyP - k * 0.07).clamp(0.0, 1.0)),
                _first?.color ?? Colors.red,
                k == 0 ? 30 : 30 - k * 6.0,
                k == 0 ? 1.0 : 0.35 - k * 0.07,
              ),
              _balloon(
                balloonPos(rightX, midX + 12, (flyP - k * 0.07).clamp(0.0, 1.0)),
                _second?.color ?? Colors.blue,
                k == 0 ? 30 : 30 - k * 6.0,
                k == 0 ? 1.0 : 0.35 - k * 0.07,
              ),
            ],
          ],

          // Mixed paint drop
          if (showDrop)
            _balloon(
              Offset(midX, dropY),
              _result?.color ?? mixColor,
              30 + 8 * dropP,
              1.0,
            ),

          // Explosion at the collision point
          Positioned(
            left: midX - 120,
            top: _hitY - 120,
            width: 240,
            height: 240,
            child: LabBurst(
              trigger: _boom,
              colors: [
                _first?.color ?? Colors.red,
                _second?.color ?? Colors.blue,
                mixColor,
                Colors.white,
              ],
              count: 38,
              distance: 100,
              gravity: 90,
              size: 6.5,
              duration: const Duration(milliseconds: 1000),
            ),
          ),
        ],
      ),
    );
  }

  Widget _balloon(Offset pos, Color color, double size, double opacity) {
    return Positioned(
      left: pos.dx - size / 2,
      top: pos.dy - size / 2,
      width: size,
      height: size,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.4, -0.4),
              colors: [labLighten(color, 0.25), color],
            ),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.45), blurRadius: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shooterWidget({
    required double x,
    required double top,
    required Color? color,
    required int tick,
    required double scale,
    required double look,
    required String? label,
  }) {
    final awake = color != null;
    return Positioned(
      left: x - 40,
      top: top - 4,
      width: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 18,
            child: AnimatedOpacity(
              opacity: awake ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              child: const Text('💤', style: TextStyle(fontSize: 15)),
            ),
          ),
          TweenAnimationBuilder<double>(
            key: ValueKey<int>(tick),
            tween: Tween<double>(begin: tick == 0 ? 1.0 : 0.6, end: 1.0),
            duration: const Duration(milliseconds: 650),
            curve: Curves.elasticOut,
            builder: (context, s, child) => Transform.scale(
              scale: s * scale,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
            child: LabBlob(
              color: color,
              size: _shooter,
              expression: awake ? (_fighting ? 1 : 0) : 4,
              look: look,
              glow: awake,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black38, blurRadius: 3)],
            ),
          ),
        ],
      ),
    );
  }
}

class _SplatsPainter extends CustomPainter {
  final List<_Splat> splats;
  final double lastScale;

  const _SplatsPainter(this.splats, this.lastScale);

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < splats.length; i++) {
      final s = splats[i];
      final isLast = i == splats.length - 1;
      final k = isLast ? lastScale : 1.0;
      final rnd = math.Random(s.seed);
      final center = Offset(size.width * s.x, size.height * s.y);
      final paint = Paint()..color = s.color.withOpacity(0.82);

      canvas.drawCircle(center, s.r * k, paint);
      // lumpy edges
      for (var j = 0; j < 5; j++) {
        final a = rnd.nextDouble() * math.pi * 2;
        canvas.drawCircle(
          center + Offset(math.cos(a), math.sin(a)) * s.r * 0.7 * k,
          s.r * (0.35 + rnd.nextDouble() * 0.25) * k,
          paint,
        );
      }
      // flying droplets
      for (var j = 0; j < 7; j++) {
        final a = rnd.nextDouble() * math.pi * 2;
        final d = s.r * (1.2 + rnd.nextDouble() * 0.8) * k;
        canvas.drawCircle(
          center + Offset(math.cos(a), math.sin(a)) * d,
          2 + rnd.nextDouble() * 4,
          paint,
        );
      }
      // a drip running down
      final dripX = center.dx + (rnd.nextDouble() - 0.5) * s.r;
      final dripLen = s.r * (0.8 + rnd.nextDouble() * 0.8) * k;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(dripX - 3, center.dy, 6, dripLen),
          const Radius.circular(3),
        ),
        paint,
      );
      canvas.drawCircle(Offset(dripX, center.dy + dripLen), 4.5, paint);
      // shine
      canvas.drawCircle(
        center + Offset(-s.r * 0.3, -s.r * 0.3) * k,
        s.r * 0.12 * k,
        Paint()..color = Colors.white.withOpacity(0.45),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SplatsPainter old) =>
      old.lastScale != lastScale || old.splats.length != splats.length;
}
