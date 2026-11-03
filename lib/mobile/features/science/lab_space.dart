import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'lab_common.dart';

class _Star {
  final double x;
  final double y;
  final double size;
  final double phase;

  const _Star(this.x, this.y, this.size, this.phase);
}

class _Planet {
  final String key;
  final double radius; // orbit radius around the Sun
  final int speed; // laps per animation cycle (must be an integer)
  final double base;
  final double size;
  final Color c1;
  final Color c2;

  const _Planet(
      this.key,
      this.radius,
      this.speed,
      this.base,
      this.size,
      this.c1,
      this.c2,
      );
}

class SpaceLab extends StatefulWidget {
  const SpaceLab({super.key});

  @override
  State<SpaceLab> createState() => _SpaceLabState();
}

class _SpaceLabState extends State<SpaceLab>
    with TickerProviderStateMixin, LabLangListener<SpaceLab> {
  static const double _h = 310;
  static const double _earthR = 58;
  static const double _sunR = 52;

  late final AnimationController _t =
  AnimationController(vsync: this, duration: const Duration(seconds: 14))
    ..repeat();
  late final AnimationController _spinC = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  late final List<_Star> _stars = _makeStars();

  double _spinFrom = 0;
  double _spinTo = 0;
  bool _night = false;
  bool _busy = false;
  bool _cycleDone = false;
  int _cycles = 0;
  int _burst = 0;
  int _earthTap = 0;
  int _tapBurst = 0;
  Offset _tapPos = Offset.zero;
  String _msgKey = 'space_hint';

  List<_Star> _makeStars() {
    final r = math.Random(7);
    return List.generate(
      28,
          (i) => _Star(
        r.nextDouble(),
        r.nextDouble(),
        0.8 + r.nextDouble() * 1.6,
        r.nextDouble() * math.pi * 2,
      ),
    );
  }

  @override
  void dispose() {
    LabSfx.stopSpeech();
    _t.dispose();
    _spinC.dispose();
    super.dispose();
  }

  double get _spin {
    final k = Curves.easeInOutCubic.transform(_spinC.value);
    return _spinFrom + (_spinTo - _spinFrom) * k;
  }

  void _spinEarth() {
    if (_busy) return;
    _busy = true;
    final goingNight = !_night;
    final quarters = goingNight ? 1 : 3;
    final ms = 700 * quarters;

    setState(() => _earthTap++);
    _spinFrom = _spinTo;
    _spinTo = _spinFrom + quarters * math.pi / 2;
    _spinC.duration = Duration(milliseconds: ms);
    _spinC.forward(from: 0);

    LabSfx.play('spin');
    LabSfx.soft();

    Future.delayed(Duration(milliseconds: ms), () {
      if (!mounted) return;
      setState(() {
        _night = goingNight;
        _busy = false;
        _cycles++;
        _burst++;
        _msgKey = _night ? 'space_night' : 'space_day';
      });
      LabSfx.play(_night ? 'night' : 'day');
      LabSfx.hard();
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) LabSfx.speak(tr(_msgKey));
      });

      // One full night + day cycle completes the stage
      if (_cycles >= 2 && !_cycleDone) {
        _cycleDone = true;
        Future.delayed(const Duration(milliseconds: 4800), () async {
          if (!mounted) return;
          await showStageComplete(
            context,
            emoji: '🌍',
            message: tr('space_done'),
          );
          if (!mounted) return;
          setState(() {
            _cycles = 0;
            _cycleDone = false;
          });
        });
      }
    });
  }

  void _poke(String key, Offset pos) {
    setState(() {
      _msgKey = 'fact_$key';
      _tapPos = pos;
      _tapBurst++;
    });
    LabSfx.play('twinkle');
    LabSfx.tap();
    LabSfx.speak(tr('fact_$key'));
  }

  Color get _msgColor {
    switch (_msgKey) {
      case 'space_day':
        return Colors.orange;
      case 'space_night':
        return Colors.indigo;
      case 'space_hint':
        return Colors.blueGrey;
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LabProgressPill(
          value: _cycles / 2,
          label: '$_cycles/2',
          color: Colors.deepPurple,
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
                  animation: Listenable.merge([_t, _spinC]),
                  builder: (context, _) => _scene(c.maxWidth),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        LabMascotBubble(
          text: tr(_msgKey),
          color: _msgColor,
          mascot: '👨‍🚀',
        ),
        const SizedBox(height: 8),
        LabChunkyButton(
          color: _night ? Colors.indigo : Colors.deepPurple,
          onTap: _busy ? null : _spinEarth,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sync_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('${tr('spin')} 🌍'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _scene(double w) {
    final t = _t.value;
    final spin = _spin;

    final sunC = const Offset(34, _h / 2);
    final orbitR = w * 0.56 - 34;
    final marsR = math.min(orbitR + 78, w - 34 - 22);
    final wob = 0.1 * math.sin(t * 2 * math.pi);
    final earthC = sunC + Offset(orbitR * math.cos(wob), orbitR * math.sin(wob));

    // The "You" pin lives on the Earth surface and turns with it
    final pinLon = -math.pi / 4 + spin;
    final sinL = math.sin(pinLon);
    final cosL = math.cos(pinLon);
    const pinLat = 0.35;
    final pinPos = Offset(
      earthC.dx + _earthR * math.cos(pinLat) * sinL,
      earthC.dy - _earthR * math.sin(pinLat),
    );
    final pinOpacity = ((cosL - 0.05) / 0.3).clamp(0.0, 1.0);
    final dayNow = sinL < 0; // the sun is on the left side of the Earth

    final planets = <_Planet>[
      const _Planet('mercury', 78, 4, 1.0, 14, Color(0xFFD7D7D7), Color(0xFF757575)),
      const _Planet('venus', 108, 3, 3.0, 22, Color(0xFFFFE082), Color(0xFFFF8F00)),
      _Planet('mars', marsR, 1, 5.6, 20, const Color(0xFFFFAB91), const Color(0xFFBF360C)),
    ];

    // Moon orbiting the Earth
    final phi = t * 2 * math.pi * 3;
    final moonPos = earthC + Offset(math.cos(phi) * (_earthR + 32), math.sin(phi) * 24);
    final moonFront = math.sin(phi) > 0;
    final moonSize = 18 * (0.85 + 0.2 * math.sin(phi));

    Widget moon() => Positioned(
      left: moonPos.dx - 22,
      top: moonPos.dy - 22,
      width: 44,
      height: 44,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _poke('moon', moonPos),
        child: Center(
          child: Container(
            width: moonSize,
            height: moonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.4, -0.4),
                colors: [Color(0xFFF5F5F5), Color(0xFF9E9E9E)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.35),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Space
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0B1033), Color(0xFF2A1B5E)],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(painter: _StarsPainter(_stars, t)),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _OrbitsPainter(sunC, [78, 108, orbitR, marsR]),
          ),
        ),

        // Sun (tap me!)
        Positioned(
          left: sunC.dx - 78,
          top: sunC.dy - 78,
          width: 156,
          height: 156,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _poke('sun', sunC),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: t * 2 * math.pi,
                  child: CustomPaint(
                    size: const Size(156, 156),
                    painter: const _SunRaysPainter(),
                  ),
                ),
                Transform.scale(
                  scale: 1 + 0.035 * math.sin(t * 2 * math.pi * 5),
                  child: const LabBlob(
                    color: Color(0xFFFFC107),
                    size: _sunR * 2,
                    expression: 2,
                    glow: true,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Small planets orbiting the Sun
        for (final p in planets) _planetWidget(p, sunC, t),

        if (!moonFront) moon(),

        // Earth
        Positioned(
          left: earthC.dx - _earthR - 8,
          top: earthC.dy - _earthR - 8,
          width: _earthR * 2 + 16,
          height: _earthR * 2 + 16,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _busy ? null : _spinEarth,
            child: TweenAnimationBuilder<double>(
              key: ValueKey<int>(_earthTap),
              tween: Tween<double>(begin: _earthTap == 0 ? 1.0 : 0.88, end: 1.0),
              duration: const Duration(milliseconds: 700),
              curve: Curves.elasticOut,
              builder: (context, s, child) =>
                  Transform.scale(scale: s, child: child),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: CustomPaint(painter: _EarthPainter(spin)),
              ),
            ),
          ),
        ),

        // "You" pin
        Positioned(
          left: pinPos.dx - 13,
          top: pinPos.dy - 28,
          child: IgnorePointer(
            child: Opacity(
              opacity: pinOpacity,
              child: const Text('📍', style: TextStyle(fontSize: 26)),
            ),
          ),
        ),

        if (moonFront) moon(),

        // What you see from the pin
        PositionedDirectional(
          end: 10,
          top: 10,
          child: IgnorePointer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: dayNow
                          ? [Colors.lightBlue.shade300, Colors.lightBlue.shade100]
                          : [Colors.indigo.shade900, Colors.indigo.shade500],
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Text(
                      dayNow ? '☀️' : '🌙',
                      key: ValueKey<bool>(dayNow),
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '📍 ${tr('you')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 3)],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Sparkles when the Earth stops turning
        Positioned(
          left: earthC.dx - 130,
          top: earthC.dy - 130,
          width: 260,
          height: 260,
          child: LabBurst(
            trigger: _burst,
            colors: _night
                ? [Colors.white, Colors.yellow.shade200, Colors.purple.shade100]
                : [Colors.yellow, Colors.orangeAccent, Colors.white],
            count: 22,
            distance: 95,
            gravity: 8,
            size: 4.5,
            duration: const Duration(milliseconds: 1000),
          ),
        ),
        // Sparkles where you tapped a planet / the sun / the moon
        Positioned(
          left: _tapPos.dx - 70,
          top: _tapPos.dy - 70,
          width: 140,
          height: 140,
          child: LabBurst(
            trigger: _tapBurst,
            colors: [Colors.yellow, Colors.white, Colors.orangeAccent],
            count: 12,
            distance: 45,
            gravity: 0,
            size: 3.5,
          ),
        ),
      ],
    );
  }

  Widget _planetWidget(_Planet p, Offset sunC, double t) {
    final a = p.base + t * 2 * math.pi * p.speed;
    final pos = sunC + Offset(math.cos(a), math.sin(a)) * p.radius;
    return Positioned(
      left: pos.dx - 22,
      top: pos.dy - 22,
      width: 44,
      height: 44,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _poke(p.key, pos),
        child: Center(
          child: Container(
            width: p.size,
            height: p.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.4, -0.4),
                colors: [p.c1, p.c2],
              ),
              boxShadow: [
                BoxShadow(color: p.c1.withOpacity(0.5), blurRadius: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painters
// ---------------------------------------------------------------------------

class _StarsPainter extends CustomPainter {
  final List<_Star> stars;
  final double t;

  const _StarsPainter(this.stars, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      final op = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * 2 * math.pi * 7 + s.phase));
      final paint = Paint()..color = Colors.white.withOpacity(op);
      final p = Offset(s.x * size.width, s.y * size.height);
      canvas.drawCircle(p, s.size, paint);
      if (s.size > 1.9) {
        final line = Paint()
          ..color = Colors.white.withOpacity(op * 0.8)
          ..strokeWidth = 1;
        canvas.drawLine(p + const Offset(-4, 0), p + const Offset(4, 0), line);
        canvas.drawLine(p + const Offset(0, -4), p + const Offset(0, 4), line);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter old) => old.t != t;
}

class _OrbitsPainter extends CustomPainter {
  final Offset center;
  final List<double> radii;

  const _OrbitsPainter(this.center, this.radii);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final r in radii) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitsPainter old) =>
      old.center != center || old.radii.join() != radii.join();
}

class _SunRaysPainter extends CustomPainter {
  const _SunRaysPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..color = const Color(0xFFFFB300)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 14; i++) {
      final a = i / 14 * 2 * math.pi;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + d * 62, c + d * (i.isEven ? 76 : 70), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SunRaysPainter old) => false;
}

class _EarthPainter extends CustomPainter {
  final double spin;

  const _EarthPainter(this.spin);

  // lon, lat, width, height (fractions of the radius)
  static const List<(double, double, double, double)> _continents = [
    (0.2, 0.45, 0.55, 0.32),
    (1.3, 0.05, 0.42, 0.52),
    (2.5, 0.55, 0.5, 0.28),
    (3.7, -0.25, 0.58, 0.4),
    (4.8, 0.25, 0.4, 0.5),
    (5.7, -0.6, 0.4, 0.22),
    (0.8, -0.55, 0.3, 0.2),
  ];

  static const List<(double, double, double, double)> _clouds = [
    (0.6, 0.2, 0.5, 0.12),
    (2.1, -0.3, 0.45, 0.1),
    (3.4, 0.6, 0.5, 0.11),
    (4.9, -0.1, 0.55, 0.12),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final rect = Rect.fromCircle(center: c, radius: r);

    // Atmosphere glow
    canvas.drawCircle(
      c,
      r + 1,
      Paint()
        ..color = Colors.lightBlueAccent.withOpacity(0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );

    canvas.save();
    canvas.clipPath(Path()..addOval(rect));

    // Ocean
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.3),
          radius: 1.0,
          colors: [Color(0xFF4FC3F7), Color(0xFF1565C0)],
        ).createShader(rect),
    );

    // Continents (they turn with the Earth)
    final land = Paint()..color = const Color(0xFF43A047);
    for (final k in _continents) {
      final l = k.$1 + spin;
      final cl = math.cos(l);
      if (cl < -0.15) continue;
      final x = c.dx + r * math.cos(k.$2) * math.sin(l);
      final y = c.dy - r * math.sin(k.$2);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: k.$3 * r * (0.35 + 0.65 * math.max(cl, 0)),
          height: k.$4 * r * 1.6,
        ),
        land,
      );
    }

    // Polar caps
    final ice = Paint()..color = Colors.white.withOpacity(0.92);
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(0, -r * 0.93), width: r, height: r * 0.3),
      ice,
    );
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(0, r * 0.93), width: r, height: r * 0.26),
      ice,
    );

    // Clouds (turn a little faster)
    final cloud = Paint()..color = Colors.white.withOpacity(0.5);
    for (final k in _clouds) {
      final l = k.$1 + spin * 1.25;
      final cl = math.cos(l);
      if (cl < 0) continue;
      final x = c.dx + r * math.cos(k.$2) * math.sin(l);
      final y = c.dy - r * math.sin(k.$2);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: k.$3 * r * (0.3 + 0.7 * cl),
          height: k.$4 * r * 1.4,
        ),
        cloud,
      );
    }

    // Night side (the Sun is on the left)
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: [0.34, 0.64],
          colors: [Color(0x00000000), Color(0xB0050A30)],
        ).createShader(rect),
    );

    canvas.restore();

    // Rim
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Colors.lightBlueAccent.withOpacity(0.6),
    );
  }

  @override
  bool shouldRepaint(covariant _EarthPainter old) => old.spin != spin;
}