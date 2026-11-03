import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import '../../data/providers/progress_provider.dart';
import '../science/fun_common.dart';
import 'story.dart';
import 'story_i18n.dart';

enum _ReadState { idle, playing, paused }

/// Reading screen for the "Story" activity.
///  - 3 languages (English / Français / العربية), stories included
///  - "Read to me": the phone reads the story aloud, sentence by sentence,
///    and the sentence being read lights up. Tap any sentence to hear it.
///  - Finishing a story (listening or marking it) gives stars + confetti.
class StoryReadingScreen extends StatefulWidget {
  final int initialIndex;

  const StoryReadingScreen({super.key, this.initialIndex = 0});

  @override
  State<StoryReadingScreen> createState() => _StoryReadingScreenState();
}

class _StoryReadingScreenState extends State<StoryReadingScreen>
    with TickerProviderStateMixin, FunLang<StoryReadingScreen> {
  late int _currentIndex = widget.initialIndex.clamp(0, stories.length - 1);
  late final PageController _controller =
  PageController(initialPage: _currentIndex);
  final Set<int> _readIds = {};

  // Gentle up/down bob for the illustration + glow of the play button.
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

  IconData _iconFor(String theme) =>
      _themeIcons[theme] ?? Icons.menu_book_rounded;

  String _emojiFor(String theme) => _themeEmoji[theme] ?? '📖';

  // ---- Read aloud ----------------------------------------------------------

  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;
  int _session = 0; // changes to cancel a running read-aloud loop
  _ReadState _rs = _ReadState.idle;
  int _active = -1; // index of the sentence being read (-1 = none / title)
  bool _slow = true; // slow reading is better for small kids

  final Map<String, List<List<String>>> _cache = {};

  List<List<String>> _paragraphsOf(Story s) {
    final lang = i18n.lang.name;
    return _cache.putIfAbsent(
      '${s.id}-$lang',
          () => storyParagraphs(s.textFor(lang)),
    );
  }

  double get _rate {
    final base = _slow ? 0.32 : 0.45;
    return i18n.lang == LabLang.ar ? base - 0.03 : base;
  }

  Future<bool> _prepareTts() async {
    try {
      if (!_ttsReady) {
        await _tts.awaitSpeakCompletion(true);
        await _tts.setPitch(1.1);
        await _tts.setVolume(1.0);
        _ttsReady = true;
      }
      final locale = i18n.ttsLocale;
      try {
        final ok = await _tts.isLanguageAvailable(locale);
        if (ok == false || ok == 0) {
          _toast(st('st_no_voice'));
          return false;
        }
      } catch (_) {}
      await _tts.setLanguage(locale);
      await _tts.setSpeechRate(_rate);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _startReading({int from = 0}) async {
    final story = stories[_currentIndex];
    final sentences = _paragraphsOf(story).expand((p) => p).toList();
    if (sentences.isEmpty) return;

    final session = ++_session;
    LabSfx.stopSpeech();
    if (!await _prepareTts()) return;
    if (!mounted || session != _session) return;

    setState(() {
      _rs = _ReadState.playing;
      _active = from == 0 ? -1 : from;
    });

    final lang = i18n.lang.name;
    try {
      if (from == 0) {
        await _tts.speak(story.titleFor(lang)); // the title first
        if (!mounted || session != _session) return;
      }
      for (var i = from; i < sentences.length; i++) {
        if (!mounted || session != _session) return;
        setState(() => _active = i);
        try {
          await _tts.setSpeechRate(_rate);
        } catch (_) {}
        final sw = Stopwatch()..start();
        await _tts.speak(sentences[i]);
        // If the engine returned at once (no voice?), keep a natural pace.
        if (mounted && session == _session && sw.elapsedMilliseconds < 250) {
          await Future.delayed(
            Duration(milliseconds: (sentences[i].length * 55).clamp(600, 6000)),
          );
        }
      }
    } catch (_) {}

    if (!mounted || session != _session) return;
    _finishedReading(story);
  }

  Future<void> _pause() async {
    _session++;
    if (mounted) setState(() => _rs = _ReadState.paused);
    try {
      await _tts.stop();
    } catch (_) {}
  }

  void _stopReading() {
    _session++;
    try {
      _tts.stop();
    } catch (_) {}
    if (mounted && (_rs != _ReadState.idle || _active != -1)) {
      setState(() {
        _rs = _ReadState.idle;
        _active = -1;
      });
    }
  }

  void _onPlayTap() {
    LabSfx.tap();
    if (_rs == _ReadState.playing) {
      _pause();
    } else if (_rs == _ReadState.paused) {
      _startReading(from: _active < 0 ? 0 : _active);
    } else {
      _startReading();
    }
  }

  void _finishedReading(Story story) {
    setState(() {
      _rs = _ReadState.idle;
      _active = -1;
    });
    if (!_readIds.contains(story.id)) {
      _markRead(story.id);
    } else {
      _celebrateController.forward(from: 0);
      LabSfx.play('ding');
    }
  }

  // ---- Read marks / rewards ------------------------------------------------

  void _markRead(int id) {
    setState(() => _readIds.add(id));
    _celebrateController.forward(from: 0);
    LabSfx.play('win', volume: 0.8);
    LabSfx.hard();
    // Feed the learning-progress system: star reward + one story
    // challenge step for each story the child reads.
    final progress = Provider.of<ProgressProvider>(context, listen: false);
    progress.addStars(2);
    progress.incrementChallengeProgress('story');
    _toast(st('st_cheer${Random().nextInt(5)}'), cheer: true);
  }

  void _toggleRead(int id) {
    LabSfx.tap();
    if (_readIds.contains(id)) {
      setState(() => _readIds.remove(id));
    } else {
      _markRead(id);
    }
  }

  void _toast(String message, {bool cheer = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        duration: Duration(milliseconds: cheer ? 1300 : 2200),
        backgroundColor: primaryPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
    );
  }

  void _goTo(int index) {
    if (index < 0 || index >= stories.length) return;
    LabSfx.play('pop', volume: 0.7);
    LabSfx.tap();
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  // ---- Lifecycle -----------------------------------------------------------

  void _onLangChanged() => _stopReading();

  @override
  void initState() {
    super.initState();
    LabSfx.preload();
    i18n.addListener(_onLangChanged);
  }

  @override
  void dispose() {
    i18n.removeListener(_onLangChanged);
    _session++;
    try {
      _tts.stop();
    } catch (_) {}
    _controller.dispose();
    _bobController.dispose();
    _celebrateController.dispose();
    super.dispose();
  }

  // ---- UI ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final story = stories[_currentIndex];
    final isRead = _readIds.contains(story.id);

    final playLabel = _rs == _ReadState.playing
        ? st('st_pause')
        : _rs == _ReadState.paused
        ? st('st_resume')
        : st('st_play');

    return Directionality(
      textDirection: dir,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // --- Top bar ----------------------------------------------
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                    child: Row(
                      children: [
                        FunRoundButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          color: const Color(0xFF213238),
                          size: 40,
                          tooltip: tr('back'),
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Text(
                            '📖 ${st('st_title')}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF213238),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: LabLangBar(),
                  ),

                  // --- Pages --------------------------------------------------
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: stories.length,
                      onPageChanged: (i) {
                        _stopReading();
                        setState(() => _currentIndex = i);
                      },
                      itemBuilder: (context, index) {
                        final s = stories[index];
                        final current = index == _currentIndex;
                        return _StoryPage(
                          key: ValueKey<String>('${s.id}-${i18n.lang.name}'),
                          title: s.titleFor(i18n.lang.name),
                          paragraphs: _paragraphsOf(s),
                          themeLabel: storyThemeLabel(s.theme),
                          colors: _colorsFor(s.theme),
                          icon: _iconFor(s.theme),
                          emoji: _emojiFor(s.theme),
                          isRead: _readIds.contains(s.id),
                          bobController: _bobController,
                          speaking: current && _rs == _ReadState.playing,
                          activeSentence: current ? _active : -1,
                          onTapSentence: (i) {
                            if (current) _startReading(from: i);
                          },
                        );
                      },
                    ),
                  ),

                  // --- Bottom controls ----------------------------------------
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 6, 24, 12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: _BouncyIconButton(
                                icon: Icons.arrow_back_rounded,
                                background: const Color(0xFFFFE1C2),
                                iconColor: const Color(0xFFE0964A),
                                onTap: () => _goTo(_currentIndex - 1),
                              ),
                            ),
                            _PlayButton(
                              playing: _rs == _ReadState.playing,
                              pulse: _bobController,
                              label: playLabel,
                              onTap: _onPlayTap,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: _BouncyIconButton(
                                icon: Icons.arrow_forward_rounded,
                                background: primaryPurple.withOpacity(0.15),
                                iconColor: primaryPurple,
                                onTap: () => _goTo(_currentIndex + 1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _PillChip(
                              label: _slow
                                  ? '🐢 ${st('st_slow')}'
                                  : '🐇 ${st('st_normal')}',
                              active: false,
                              onTap: () {
                                LabSfx.play('pop', volume: 0.6);
                                LabSfx.tap();
                                setState(() => _slow = !_slow);
                              },
                            ),
                            const SizedBox(width: 10),
                            _PillChip(
                              label: isRead
                                  ? '✅ ${st('st_read_done')}'
                                  : '⭐ ${st('st_read_btn')}',
                              active: isRead,
                              onTap: () => _toggleRead(story.id),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
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

              // --- Celebration burst overlay ----------------------------------
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// One story page
// ---------------------------------------------------------------------------

class _StoryPage extends StatefulWidget {
  final String title;
  final List<List<String>> paragraphs;
  final String themeLabel;
  final List<Color> colors;
  final IconData icon;
  final String emoji;
  final bool isRead;
  final AnimationController bobController;
  final bool speaking;
  final int activeSentence; // flat index, -1 = none
  final ValueChanged<int> onTapSentence;

  const _StoryPage({
    super.key,
    required this.title,
    required this.paragraphs,
    required this.themeLabel,
    required this.colors,
    required this.icon,
    required this.emoji,
    required this.isRead,
    required this.bobController,
    required this.speaking,
    required this.activeSentence,
    required this.onTapSentence,
  });

  @override
  State<_StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<_StoryPage> {
  final List<TapGestureRecognizer> _taps = [];
  late List<GlobalKey> _paraKeys;
  int _lastPara = -1;

  int get _sentenceCount =>
      widget.paragraphs.fold<int>(0, (sum, p) => sum + p.length);

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() {
    for (final t in _taps) {
      t.dispose();
    }
    _taps.clear();
    for (var i = 0; i < _sentenceCount; i++) {
      _taps.add(TapGestureRecognizer()
        ..onTap = () => widget.onTapSentence(i));
    }
    _paraKeys = List.generate(widget.paragraphs.length, (_) => GlobalKey());
  }

  @override
  void didUpdateWidget(covariant _StoryPage old) {
    super.didUpdateWidget(old);
    if (!identical(old.paragraphs, widget.paragraphs)) _setup();
    if (widget.activeSentence != old.activeSentence &&
        widget.activeSentence >= 0) {
      final p = _paragraphOf(widget.activeSentence);
      if (p != _lastPara) {
        _lastPara = p;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || p >= _paraKeys.length) return;
          final ctx = _paraKeys[p].currentContext;
          if (ctx != null) {
            Scrollable.ensureVisible(
              ctx,
              alignment: 0.2,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeInOut,
            );
          }
        });
      }
    }
  }

  @override
  void dispose() {
    for (final t in _taps) {
      t.dispose();
    }
    super.dispose();
  }

  int _paragraphOf(int flat) {
    var left = flat;
    for (var p = 0; p < widget.paragraphs.length; p++) {
      if (left < widget.paragraphs[p].length) return p;
      left -= widget.paragraphs[p].length;
    }
    return widget.paragraphs.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final dark = labDarken(widget.colors.last, 0.12);

    final baseStyle = TextStyle(
      fontSize: rtl ? 19 : 17.5,
      height: rtl ? 2.0 : 1.8,
      color: const Color(0xFF4A5A60),
    );

    var flat = 0;
    final paragraphWidgets = <Widget>[];
    for (var p = 0; p < widget.paragraphs.length; p++) {
      final sentences = widget.paragraphs[p];
      final spans = <InlineSpan>[];
      for (var j = 0; j < sentences.length; j++) {
        final idx = flat++;
        final active = idx == widget.activeSentence;
        spans.add(TextSpan(
          text: sentences[j],
          recognizer: _taps[idx],
          style: active
              ? TextStyle(
            backgroundColor: widget.colors.last.withOpacity(0.2),
            color: dark,
            fontWeight: FontWeight.w800,
          )
              : null,
        ));
        if (j < sentences.length - 1) spans.add(const TextSpan(text: ' '));
      }
      paragraphWidgets.add(
        FunPopIn(
          delayMs: 200 + p * 110,
          child: Padding(
            key: _paraKeys[p],
            padding: const EdgeInsets.only(bottom: 14),
            child: Text.rich(TextSpan(children: spans), style: baseStyle),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FunPopIn(child: _buildCard()),
          const SizedBox(height: 20),
          FunPopIn(
            delayMs: 100,
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF213238),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.touch_app_rounded,
                  size: 14, color: widget.colors.last.withOpacity(0.8)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  st('st_tap_hint'),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: widget.colors.last.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...paragraphWidgets,
        ],
      ),
    );
  }

  Widget _buildCard() {
    final colors = widget.colors;
    final bob = widget.bobController;
    return Container(
      height: 200,
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
          PositionedDirectional(
            top: -20,
            end: -20,
            child: Icon(widget.icon,
                size: 140, color: Colors.white.withOpacity(0.18)),
          ),
          PositionedDirectional(
            top: 40,
            start: 30,
            child: _Twinkle(controller: bob, emoji: '✨'),
          ),
          PositionedDirectional(
            bottom: 24,
            end: 40,
            child: _Twinkle(controller: bob, emoji: '⭐', reversed: true),
          ),
          Center(
            child: AnimatedBuilder(
              animation: bob,
              builder: (context, child) {
                final double dy = -6 * sin(bob.value * pi * 2);
                final double rot = 0.03 * sin(bob.value * pi * 2);
                // The mascot "talks" (pulses) while the story is read.
                final double pulse =
                widget.speaking ? 1 + 0.07 * sin(bob.value * pi * 4) : 1.0;
                return Transform.translate(
                  offset: Offset(0, dy),
                  child: Transform.rotate(
                    angle: rot,
                    child: Transform.scale(scale: pulse, child: child),
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 74, color: Colors.white),
                  Text(widget.emoji, style: const TextStyle(fontSize: 30)),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            top: 14,
            start: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${widget.emoji} ${widget.themeLabel}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (widget.isRead)
            PositionedDirectional(
              bottom: 14,
              start: 14,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      st('st_read_done'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF213238),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.speaking)
            PositionedDirectional(
              top: 14,
              end: 14,
              child: AnimatedBuilder(
                animation: bob,
                builder: (context, child) => Opacity(
                  opacity: 0.6 + 0.4 * sin(bob.value * pi * 2).abs(),
                  child: child,
                ),
                child: const Text('🔊', style: TextStyle(fontSize: 22)),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Controls
// ---------------------------------------------------------------------------

/// Big "Read to me" button that glows while the story is being read.
class _PlayButton extends StatelessWidget {
  final bool playing;
  final Animation<double> pulse;
  final String label;
  final VoidCallback onTap;

  const _PlayButton({
    required this.playing,
    required this.pulse,
    required this.label,
    required this.onTap,
  });

  static const Color purple = Color(0xFF7B61FF);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: pulse,
          builder: (context, child) {
            final glow =
            playing ? 6 + 8 * (0.5 + 0.5 * sin(pulse.value * pi * 2)) : 0.0;
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: purple.withOpacity(0.38),
                    blurRadius: 14 + glow,
                    spreadRadius: glow / 2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: child,
            );
          },
          child: FunPressable(
            onTap: onTap,
            pressedScale: 0.9,
            child: Container(
              width: 78,
              height: 78,
              decoration: const BoxDecoration(
                color: purple,
                shape: BoxShape.circle,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  key: ValueKey<bool>(playing),
                  color: Colors.white,
                  size: 44,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: purple,
          ),
        ),
      ],
    );
  }
}

class _PillChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PillChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7B61FF);
    return FunPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF35B24A) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active ? const Color(0xFF35B24A) : const Color(0xFFE1DAF5),
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: active ? Colors.white : purple,
          ),
        ),
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
class _BouncyIconButton extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color iconColor;
  final VoidCallback onTap;

  const _BouncyIconButton({
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FunPressable(
      onTap: onTap,
      pressedScale: 0.86,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }
}

/// Confetti-ish little burst of emoji that pop up and fade away, shown
/// briefly when a story is read.
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