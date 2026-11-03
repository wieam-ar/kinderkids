import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'lab_common.dart';

class _FloatItem {
  final String id;
  final String emoji;
  final bool floats;
  final String dropSfx; // sound when it hits the water
  final String afterSfx; // sound right after (squeak, bubbles...)

  const _FloatItem(
    this.id,
    this.emoji,
    this.floats,
    this.dropSfx,
    this.afterSfx,
  );
}

const List<_FloatItem> _items = [
  _FloatItem('duck', '🦆', true, 'splash_small', 'squeak'),
  _FloatItem('rock', '🪨', false, 'splash_big', 'bubbles'),
  _FloatItem('apple', '🍎', true, 'splash_small', 'bloop'),
  _FloatItem('key', '🔑', false, 'splash_key', 'bubbles'),
];

class SinkFloatLab extends StatefulWidget {
  const SinkFloatLab({super.key});

  @override
  State<SinkFloatLab> createState() => _SinkFloatLabState();
}

class _SinkFloatLabState extends State<SinkFloatLab>
    with SingleTickerProviderStateMixin, LabLangListener<SinkFloatLab> {
  static const double _areaH = 330;
  static const double _shelfY = 60;
  static const double _tankTop = 100;
  static const double _surfaceY = 126;
  static const double _box = 56;
  static const double _sandH = 26;
  static const List<double> _xs = [0.14, 0.38, 0.62, 0.86];

  static const double _shelfTop = 4;
  static const double _fallTop = _surfaceY - _box + 10;
  static const double _floatTop = _surfaceY - _box / 2 + 6;
  static const double _sinkTop = _areaH - _box - _sandH + 10;

  static const Color _sandColor = Color(0xFFEBCB8B);

  late final AnimationController _t =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))
        ..repeat();

  // 0 = on the shelf, 1 = falling, 2 = in the water
  final List<int> _stage = List<int>.filled(_items.length, 0);
  final Set<int> _tested = {};
  final List<int> _splash = List<int>.filled(_items.length, 0);
  final List<int> _bubbles = List<int>.filled(_items.length, 0);
  final List<int> _dust = List<int>.filled(_items.length, 0);
  final List<bool> _showReact = List<bool>.filled(_items.length, false);
  int? _last;
  bool _celebrated = false;

  @override
  void dispose() {
    LabSfx.stopSpeech();
    _t.dispose();
    super.dispose();
  }

  void _toggle(int i) {
    final item = _items[i];
    if (_stage[i] == 1) return;

    // Take the item out of the water
    if (_stage[i] == 2) {
      setState(() {
        _stage[i] = 0;
        _last = null;
        _showReact[i] = false;
      });
      LabSfx.play('drip');
      LabSfx.tap();
      return;
    }

    // Drop it: it falls first, then hits the water
    setState(() => _stage[i] = 1);
    LabSfx.tap();

    Future.delayed(const Duration(milliseconds: 270), () {
      if (!mounted) return;
      setState(() {
        _stage[i] = 2;
        _tested.add(i);
        _splash[i]++;
        _last = i;
      });
      LabSfx.play(item.dropSfx);
      LabSfx.soft();

      // The voice reads the fact
      Future.delayed(const Duration(milliseconds: 380), () {
        if (mounted && _stage[i] == 2) LabSfx.speak(tr('fact_${item.id}'));
      });

      // Squeak / bubbles + reaction
      Future.delayed(const Duration(milliseconds: 320), () {
        if (!mounted || _stage[i] != 2) return;
        LabSfx.play(item.afterSfx);
        setState(() {
          if (!item.floats) _bubbles[i]++;
          _showReact[i] = true;
        });
        Future.delayed(const Duration(milliseconds: 1700), () {
          if (mounted) setState(() => _showReact[i] = false);
        });
      });

      // Heavy items land on the sand
      if (!item.floats) {
        Future.delayed(const Duration(milliseconds: 1250), () {
          if (!mounted || _stage[i] != 2) return;
          LabSfx.play('thud');
          LabSfx.soft();
          setState(() => _dust[i]++);
        });
      }

      _checkDone();
    });
  }

  void _checkDone() {
    if (_tested.length == _items.length && !_celebrated) {
      _celebrated = true;
      Future.delayed(const Duration(milliseconds: 4200), () async {
        if (!mounted) return;
        await showStageComplete(
          context,
          emoji: '🏆',
          message: tr('sink_done'),
        );
        if (!mounted) return;
        _clearAll();
      });
    }
  }

  void _reset() {
    LabSfx.play('pop');
    LabSfx.tap();
    LabSfx.stopSpeech();
    _clearAll();
  }

  void _clearAll() {
    setState(() {
      for (var i = 0; i < _items.length; i++) {
        _stage[i] = 0;
        _showReact[i] = false;
      }
      _tested.clear();
      _last = null;
      _celebrated = false;
    });
  }

  String get _message =>
      _last != null ? tr('fact_${_items[_last!].id}') : tr('sink_hint');

  Color get _messageColor {
    if (_last == null) return Colors.blueGrey;
    return _items[_last!].floats ? Colors.green : Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LabProgressPill(
          value: _tested.length / _items.length,
          label: '${_tested.length}/${_items.length}',
          color: Colors.lightBlue,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: _areaH,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              return AnimatedBuilder(
                animation: _t,
                builder: (context, _) => _scene(w),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        LabMascotBubble(text: _message, color: _messageColor),
        const SizedBox(height: 2),
        TextButton.icon(
          onPressed: _tested.isEmpty ? null : _reset,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(tr('start_over')),
        ),
      ],
    );
  }

  Widget _scene(double w) {
    final t = _t.value;
    final phase = t * 4 * math.pi; // 2 loops per controller cycle
    const tankRadius = BorderRadius.only(
      topLeft: Radius.circular(10),
      topRight: Radius.circular(10),
      bottomLeft: Radius.circular(30),
      bottomRight: Radius.circular(30),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // --- Wooden shelf + labels ---
        Positioned(
          left: 4,
          right: 4,
          top: _shelfY,
          height: 12,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFB5772F),
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(color: Color(0xFF8A5622), offset: Offset(0, 3)),
              ],
            ),
          ),
        ),
        for (var i = 0; i < _items.length; i++)
          Positioned(
            left: w * _xs[i] - 40,
            top: _shelfY + 15,
            width: 80,
            child: Text(
              tr('item_${_items[i].id}'),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF7A5A2E),
              ),
            ),
          ),

        // --- Tank: air, back water, sand ---
        Positioned(
          left: 0,
          right: 0,
          top: _tankTop,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.lightBlue.shade50.withOpacity(0.7),
              borderRadius: tankRadius,
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: _surfaceY - 6,
          bottom: 0,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
            child: CustomPaint(
              painter: LabWavePainter(
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
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: _sandH,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_sandColor, Color(0xFFD9B26A)],
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(12),
                bottom: Radius.circular(30),
              ),
            ),
          ),
        ),

        // --- Seaweed, shell, fish, bubbles ---
        for (final x in const [0.05, 0.5, 0.93])
          Positioned(
            left: w * x - 20,
            bottom: _sandH - 10,
            child: Transform.rotate(
              angle: math.sin(phase + x * 7) * 0.14,
              alignment: Alignment.bottomCenter,
              child: const Text('🌿', style: TextStyle(fontSize: 40)),
            ),
          ),
        Positioned(
          left: w * 0.27,
          bottom: 4,
          child: const Text('🐚', style: TextStyle(fontSize: 18)),
        ),
        Positioned(
          left: w * 0.74,
          bottom: 3,
          child: const Text('🐚', style: TextStyle(fontSize: 14)),
        ),
        _fish('🐠', 1, 0.0, 175, w, t),
        _fish('🐟', 2, 1.7, 232, w, t),
        _fish('🐡', 1, 3.3, 205, w, t),
        Positioned(
          left: 0,
          right: 0,
          top: _surfaceY,
          bottom: 0,
          child: IgnorePointer(
            child: CustomPaint(painter: _AmbientBubblesPainter(t)),
          ),
        ),

        // --- Items ---
        for (var i = 0; i < _items.length; i++) _buildItem(i, w, phase),

        // --- Front water (items look submerged) ---
        Positioned(
          left: 0,
          right: 0,
          top: _surfaceY - 6,
          bottom: 0,
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
              child: CustomPaint(
                painter: LabWavePainter(
                  phase: phase + 1.8,
                  amplitude: 4,
                  color: Colors.lightBlue.withOpacity(0.26),
                ),
              ),
            ),
          ),
        ),

        // --- Glass ---
        Positioned(
          left: 0,
          right: 0,
          top: _tankTop,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: tankRadius,
                border: Border.all(
                  color: Colors.white.withOpacity(0.9),
                  width: 4,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 12,
          top: _tankTop + 16,
          width: 6,
          height: 80,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.45),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),

        // --- Splash / bubbles / dust ---
        for (var i = 0; i < _items.length; i++) ...[
          Positioned(
            left: w * _xs[i] - 100,
            top: _surfaceY - 100,
            width: 200,
            height: 200,
            child: LabBurst(
              trigger: _splash[i],
              colors: [
                Colors.lightBlue.shade200,
                Colors.white,
                Colors.lightBlue.shade400,
              ],
              count: _items[i].id == 'rock' ? 22 : 14,
              distance: _items[i].id == 'rock' ? 85 : 60,
              gravity: 60,
              size: 4.5,
              angleStart: -math.pi * 0.9,
              angleEnd: -math.pi * 0.1,
            ),
          ),
          Positioned(
            left: w * _xs[i] - 100,
            top: _surfaceY + 70 - 100,
            width: 200,
            height: 200,
            child: LabBurst(
              trigger: _bubbles[i],
              colors: [Colors.white, Colors.lightBlue.shade50],
              count: 8,
              distance: 60,
              gravity: -30,
              size: 5,
              angleStart: -math.pi * 0.8,
              angleEnd: -math.pi * 0.2,
              hollow: true,
              duration: const Duration(milliseconds: 1200),
            ),
          ),
          Positioned(
            left: w * _xs[i] - 100,
            top: _areaH - _sandH - 100,
            width: 200,
            height: 200,
            child: LabBurst(
              trigger: _dust[i],
              colors: const [_sandColor, Color(0xFFD9B26A), Colors.white],
              count: 10,
              distance: 34,
              gravity: 24,
              size: 4,
              angleStart: -math.pi * 0.95,
              angleEnd: -math.pi * 0.05,
              duration: const Duration(milliseconds: 700),
            ),
          ),
        ],

        // --- Reactions ---
        for (var i = 0; i < _items.length; i++)
          Positioned(
            left: w * _xs[i] + 12,
            top: (_items[i].floats ? _floatTop : _sinkTop) - 12,
            child: IgnorePointer(
              child: AnimatedScale(
                scale: _showReact[i] ? 1 : 0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                child: Text(
                  _items[i].floats ? '😄' : '😲',
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _fish(String emoji, int k, double p, double y, double w, double t) {
    final a = t * 2 * math.pi * k + p;
    final x = w * (0.5 + 0.36 * math.sin(a)) - 14;
    final movingRight = math.cos(a) > 0;
    return Positioned(
      left: x,
      top: y + math.sin(a * 2) * 6,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(movingRight ? -1.0 : 1.0, 1.0, 1.0),
        child: Text(emoji, style: const TextStyle(fontSize: 26)),
      ),
    );
  }

  Widget _buildItem(int i, double w, double phase) {
    final item = _items[i];
    final stage = _stage[i];

    double top;
    Duration dur;
    Curve curve;
    double dy;
    double tilt;

    if (stage == 0) {
      top = _shelfTop;
      dur = const Duration(milliseconds: 450);
      curve = Curves.easeOutBack;
      dy = math.sin(phase + i * 1.3) * 2.5; // idle hover invites a tap
      tilt = 0;
    } else if (stage == 1) {
      top = _fallTop;
      dur = const Duration(milliseconds: 270);
      curve = Curves.easeInQuad;
      dy = 0;
      tilt = i.isEven ? 0.35 : -0.35;
    } else if (item.floats) {
      top = _floatTop;
      dur = const Duration(milliseconds: 900);
      curve = Curves.elasticOut;
      dy = math.sin(phase + i * 1.7) * 3;
      tilt = math.sin(phase + i) * 0.14;
    } else {
      top = _sinkTop;
      dur = const Duration(milliseconds: 1100);
      curve = Curves.easeInOutSine;
      dy = 0;
      tilt = math.sin(phase + i) * 0.05;
    }

    return AnimatedPositioned(
      duration: dur,
      curve: curve,
      left: w * _xs[i] - _box / 2,
      top: top,
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

class _AmbientBubblesPainter extends CustomPainter {
  final double t;

  const _AmbientBubblesPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white.withOpacity(0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    for (var i = 0; i < 10; i++) {
      final speed = 1 + i % 3;
      final x = size.width * ((i * 0.37 + 0.08) % 1.0) +
          math.sin(t * 2 * math.pi * 3 + i) * 6;
      final y = size.height * (1 - ((t * speed + i * 0.13) % 1.0));
      final r = 2.0 + (i % 4) * 1.5;
      canvas.drawCircle(Offset(x, y), r, stroke);
      canvas.drawCircle(
        Offset(x - r * 0.3, y - r * 0.3),
        r * 0.22,
        Paint()..color = Colors.white.withOpacity(0.8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientBubblesPainter old) => old.t != t;
}
