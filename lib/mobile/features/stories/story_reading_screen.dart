import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_ui.dart' show showAppSnack;
import '../../core/ui/kid_ui.dart'
    show
    KidBackground,
    KidButton,
    KidCard,
    KidColors,
    KidHeader,
    KidProgressBar,
    KidRoundButton;
import '../../data/providers/progress_provider.dart';
import '../science/fun_common.dart';
import 'story.dart';
import 'story_i18n.dart';

enum _ReadState { idle, playing, paused }

// ---------------------------------------------------------------------------
// Fonts: Fredoka (kid-friendly) for Latin, Noto Naskh for Arabic (Fredoka has
// no Arabic glyphs, and Naskh renders the tashkeel/harakat cleanly).
// ---------------------------------------------------------------------------

TextStyle _font(
    bool rtl, {
      double size = 15,
      Color color = KidColors.textDark,
      FontWeight weight = FontWeight.w600,
      double? height,
      double? letterSpacing,
    }) {
  if (rtl) {
    return GoogleFonts.notoNaskhArabic(
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: height,
    );
  }
  return GoogleFonts.fredoka(
    fontSize: size,
    color: color,
    fontWeight: weight,
    height: height,
    letterSpacing: letterSpacing,
  );
}

/// A sentence list + the indexes of sentences that end a paragraph
/// (used to add a longer, natural pause between paragraphs).
class _Flat {
  final List<String> sentences;
  final Set<int> paraEnds;
  const _Flat(this.sentences, this.paraEnds);
}

/// Reading screen for the "Story" activity.
///  - 3 languages (English / Français / العربية), stories included
///  - "Read to me": sentence-by-sentence read-aloud with highlight.
///    Tap any sentence to hear it.
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

  late final AnimationController _bobController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  late final AnimationController _celebrateController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  static const Color primaryPurple = Color(0xFF7B61FF);

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

  // ---- Text size (readability) ---------------------------------------------

  static const List<double> _textScales = [0.9, 1.0, 1.2, 1.4];
  int _sizeIdx = 1;
  double get _textScale => _textScales[_sizeIdx];

  void _cycleTextSize() {
    LabSfx.play('pop', volume: 0.6);
    LabSfx.tap();
    setState(() => _sizeIdx = (_sizeIdx + 1) % _textScales.length);
  }

  // ---- Read aloud ----------------------------------------------------------

  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;
  int _session = 0; // changes to cancel a running read-aloud loop
  _ReadState _rs = _ReadState.idle;
  int _active = -1; // index of the sentence being read (-1 = title / none)
  bool _slow = true; // slow reading is better for small kids

  final Map<String, List<List<String>>> _cache = {};
  final Map<String, Map<String, String>?> _voiceByLocale = {};

  List<List<String>> _paragraphsOf(Story s) {
    final lang = i18n.lang.name;
    return _cache.putIfAbsent(
      '${s.id}-$lang',
          () => storyParagraphs(s.textFor(lang)),
    );
  }

  _Flat _flatten(Story s) {
    final sentences = <String>[];
    final ends = <int>{};
    for (final p in _paragraphsOf(s)) {
      sentences.addAll(p);
      ends.add(sentences.length - 1);
    }
    return _Flat(sentences, ends);
  }

  double get _rate {
    final base = _slow ? 0.34 : 0.46;
    return i18n.lang == LabLang.ar ? base - 0.03 : base;
  }

  /// Cleans a sentence before it is sent to the voice engine: quotes, guillemets,
  /// ellipsis and dashes are read badly (or spelled out) by several engines.
  String _speakable(String s) {
    return s
        .replaceAll('\u00A0', ' ')
        .replaceAll('\u202F', ' ')
        .replaceAll('\u2019', "'")
        .replaceAll(RegExp('[«»\u201C\u201D"]'), '')
        .replaceAll('\u2026', ', ')
        .replaceAll(RegExp(r'\s*[\u2014\u2013]\s*'), ', ')
        .replaceAll('\u0640', '') // arabic tatweel
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Picks the best installed voice for [locale] (premium / enhanced / neural
  /// first, exact region first, robotic "compact" voices last).
  Future<Map<String, String>?> _findBestVoice(String locale) async {
    final raw = await _tts.getVoices;
    if (raw is! List) return null;
    final want = locale.replaceAll('_', '-').toLowerCase();
    final lang = want.split('-').first;

    Map<String, String>? best;
    var bestScore = -1000;
    for (final v in raw) {
      if (v is! Map) continue;
      final name = '${v['name'] ?? ''}';
      final loc = '${v['locale'] ?? ''}';
      final locN = loc.replaceAll('_', '-').toLowerCase();
      if (name.isEmpty || !locN.startsWith(lang)) continue;

      final n = name.toLowerCase();
      var score = 0;
      if (locN == want) score += 100;
      if (n.contains('premium')) {
        score += 60;
      } else if (n.contains('enhanced')) {
        score += 50;
      }
      if (n.contains('neural') || n.contains('wavenet')) score += 45;
      if (n.contains('network')) score += 30;
      if (n.contains('compact') || n.contains('espeak')) score -= 40;

      if (score > bestScore) {
        bestScore = score;
        best = {'name': name, 'locale': loc};
      }
    }
    return best;
  }

  Future<void> _applyBestVoice(String locale) async {
    try {
      if (!_voiceByLocale.containsKey(locale)) {
        _voiceByLocale[locale] = await _findBestVoice(locale);
      }
      final v = _voiceByLocale[locale];
      if (v != null) await _tts.setVoice(v);
    } catch (_) {}
  }

  Future<bool> _prepareTts() async {
    try {
      if (!_ttsReady) {
        await _tts.awaitSpeakCompletion(true);
        await _tts.setPitch(1.05);
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
      await _applyBestVoice(locale);
      await _tts.setSpeechRate(_rate);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _startReading({int from = 0, bool withTitle = true}) async {
    final story = stories[_currentIndex];
    final flat = _flatten(story);
    if (flat.sentences.isEmpty) return;

    final session = ++_session;
    LabSfx.stopSpeech();
    try {
      await _tts.stop();
    } catch (_) {}
    if (!await _prepareTts()) return;
    if (!mounted || session != _session) return;

    final readTitle = withTitle && from == 0;
    setState(() {
      _rs = _ReadState.playing;
      _active = readTitle ? -1 : from;
    });

    final lang = i18n.lang.name;
    try {
      if (readTitle) {
        await _tts.speak(_speakable(story.titleFor(lang)));
        if (!mounted || session != _session) return;
        await Future.delayed(const Duration(milliseconds: 450));
        if (!mounted || session != _session) return;
      }
      for (var i = from; i < flat.sentences.length; i++) {
        if (!mounted || session != _session) return;
        setState(() => _active = i);

        final text = _speakable(flat.sentences[i]);
        if (text.isEmpty) continue;

        try {
          await _tts.setSpeechRate(_rate);
        } catch (_) {}
        final sw = Stopwatch()..start();
        await _tts.speak(text);
        if (!mounted || session != _session) return;

        // If the engine returned at once (no voice?), keep a natural pace.
        if (sw.elapsedMilliseconds < 250) {
          await Future.delayed(
            Duration(milliseconds: (text.length * 55).clamp(600, 6000)),
          );
          if (!mounted || session != _session) return;
        }

        // Natural breathing pause: longer between paragraphs.
        if (i < flat.sentences.length - 1) {
          final ms = flat.paraEnds.contains(i)
              ? (_slow ? 750 : 480)
              : (_slow ? 240 : 130);
          await Future.delayed(Duration(milliseconds: ms));
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
      _startReading(from: _active < 0 ? 0 : _active, withTitle: _active < 0);
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
    final progress = Provider.of<ProgressProvider>(context, listen: false);
    progress.addStars(2);
    progress.incrementChallengeProgress('story');
    _toast(st('st_cheer${Random().nextInt(5)}'));
  }

  void _toggleRead(int id) {
    LabSfx.tap();
    if (_readIds.contains(id)) {
      setState(() => _readIds.remove(id));
    } else {
      _markRead(id);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    showAppSnack(ScaffoldMessenger.of(context), message);
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
    final rtl = dir == TextDirection.rtl;
    final themeColors = _colorsFor(story.theme);
    final playing = _rs == _ReadState.playing;

    final playLabel = playing
        ? st('st_pause')
        : _rs == _ReadState.paused
        ? st('st_resume')
        : st('st_play');

    return Directionality(
      textDirection: dir,
      child: Scaffold(
        body: KidBackground(
          colors: [
            Color.lerp(themeColors.first, Colors.white, 0.62)!,
            KidColors.cream,
          ],
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    KidHeader(
                      title: st('st_title'),
                      emoji: '📖',
                      subtitle: '${_currentIndex + 1} / ${stories.length}',
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: LabLangBar(),
                    ),

                    // --- Pages ------------------------------------------------
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
                            speaking: current && playing,
                            titleActive: current && playing && _active == -1,
                            activeSentence: current ? _active : -1,
                            textScale: _textScale,
                            onTapSentence: (i) {
                              if (current) {
                                _startReading(from: i, withTitle: false);
                              }
                            },
                          );
                        },
                      ),
                    ),

                    // --- Bottom controls -------------------------------------
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryPurple.withOpacity(0.14),
                            blurRadius: 18,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              KidRoundButton(
                                icon: Icons.arrow_back_rounded,
                                color: KidColors.orange,
                                tooltip: 'Previous',
                                onTap: () => _goTo(_currentIndex - 1),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: KidButton(
                                  label: playLabel,
                                  icon: playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: playing
                                      ? KidColors.orange
                                      : KidColors.purple,
                                  expand: true,
                                  onPressed: _onPlayTap,
                                ),
                              ),
                              const SizedBox(width: 12),
                              KidRoundButton(
                                icon: Icons.arrow_forward_rounded,
                                color: KidColors.purple,
                                tooltip: 'Next',
                                onTap: () => _goTo(_currentIndex + 1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _PillChip(
                                rtl: rtl,
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
                              _PillChip(
                                rtl: rtl,
                                label: '🔠 ${(_textScale * 100).round()}%',
                                active: false,
                                onTap: _cycleTextSize,
                              ),
                              _PillChip(
                                rtl: rtl,
                                label: isRead
                                    ? '✅ ${st('st_read_done')}'
                                    : '⭐ ${st('st_read_btn')}',
                                active: isRead,
                                onTap: () => _toggleRead(story.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // --- Celebration burst overlay --------------------------------
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
  final bool titleActive;
  final int activeSentence; // flat index, -1 = none
  final double textScale;
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
    required this.titleActive,
    required this.activeSentence,
    required this.textScale,
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
      _taps.add(TapGestureRecognizer()..onTap = () => widget.onTapSentence(i));
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
    final accent = widget.colors.last;
    final dark = labDarken(accent, 0.12);
    final scale = widget.textScale;

    // NOTE: the active sentence must NOT change font weight/size, otherwise the
    // text re-wraps on every sentence and the page "jumps" while reading.
    final baseStyle = _font(
      rtl,
      size: (rtl ? 22 : 19) * scale,
      height: rtl ? 2.0 : 1.75,
      weight: FontWeight.w500,
      letterSpacing: rtl ? null : 0.2,
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
            backgroundColor: accent.withOpacity(0.22),
            color: dark,
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

    // Reading progress (sentence being read / total).
    final total = _sentenceCount;
    final double progress = widget.activeSentence >= 0 && total > 0
        ? ((widget.activeSentence + 1) / total).clamp(0.0, 1.0).toDouble()
        : (widget.isRead ? 1.0 : 0.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FunPopIn(child: _buildHero()),
          const SizedBox(height: 16),

          // --- Title (lights up while it is being read) ----------------------
          FunPopIn(
            delayMs: 100,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: widget.titleActive
                    ? accent.withOpacity(0.22)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                widget.title,
                style: _font(
                  rtl,
                  size: (rtl ? 30 : 26),
                  weight: FontWeight.w800,
                  height: rtl ? 1.6 : 1.25,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // --- Progress -------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: KidProgressBar(value: progress, height: 10, color: accent),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Icon(Icons.touch_app_rounded,
                    size: 15, color: accent.withOpacity(0.9)),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    st('st_tap_hint'),
                    style: _font(
                      rtl,
                      size: rtl ? 13 : 12,
                      weight: FontWeight.w500,
                      color: accent.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // --- The "book page" -------------------------------------------------
          KidCard(
            accent: accent,
            radius: 28,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: paragraphWidgets,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    final colors = widget.colors;
    final bob = widget.bobController;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      height: 176,
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
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            PositionedDirectional(
              top: -20,
              end: -20,
              child: Icon(widget.icon,
                  size: 140, color: Colors.white.withOpacity(0.18)),
            ),
            PositionedDirectional(
              top: 44,
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
                  final double pulse = widget.speaking
                      ? 1 + 0.07 * sin(bob.value * pi * 4)
                      : 1.0;
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
                    Icon(widget.icon, size: 70, color: Colors.white),
                    Text(widget.emoji, style: const TextStyle(fontSize: 30)),
                  ],
                ),
              ),
            ),
            PositionedDirectional(
              top: 14,
              start: 14,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.28),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.emoji} ${widget.themeLabel}',
                  style: _font(
                    rtl,
                    size: 12.5,
                    weight: FontWeight.w700,
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
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text(
                        st('st_read_done'),
                        style: _font(
                          rtl,
                          size: 12,
                          weight: FontWeight.w800,
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small widgets
// ---------------------------------------------------------------------------

class _PillChip extends StatelessWidget {
  final String label;
  final bool active;
  final bool rtl;
  final VoidCallback onTap;

  const _PillChip({
    required this.label,
    required this.active,
    required this.rtl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7B61FF);
    const green = Color(0xFF35B24A);
    return FunPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? green : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active ? green : const Color(0xFFE1DAF5),
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: _font(
            rtl,
            size: 13,
            weight: FontWeight.w700,
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