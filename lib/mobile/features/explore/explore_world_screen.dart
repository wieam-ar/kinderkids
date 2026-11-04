import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/ui/kid_ui.dart';
import '../../data/models/explore_model.dart';
import '../../data/providers/progress_provider.dart';
import '../science/science_lab_screen.dart';

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

/// Accent colours cycled across the topic cards.
const List<Color> _topicAccents = [
  Color(0xFF4FC3F7), // sky
  Color(0xFFFFB74D), // orange
  Color(0xFF81C784), // green
  Color(0xFFBA68C8), // purple
  Color(0xFFF06292), // pink
  Color(0xFFFFD54F), // sunny yellow
];

const Color _correctGreen = Color(0xFF35B24A);
const Color _wrongRed = Color(0xFFFF6B5E);

class ExploreWorldScreen extends StatefulWidget {
  const ExploreWorldScreen({super.key});

  @override
  State<ExploreWorldScreen> createState() => _ExploreWorldScreenState();
}

class _ExploreWorldScreenState extends State<ExploreWorldScreen> {
  /// Topics whose quiz stars were already collected this session — keeps
  /// the reward honest so the quiz cannot be farmed endlessly.
  final Set<String> _answeredTopicIds = {};

  void _showTopicQuiz(
      BuildContext context,
      ExploreTopic topic,
      String lang,
      Color accent,
      ) {
    final alreadyAnswered = _answeredTopicIds.contains(topic.id);
    final progress = Provider.of<ProgressProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final options = topic.getOptions(lang);
        String? selectedOptionText;
        bool? isCorrect;

        void handleSelect(
            void Function(void Function()) setModalState, QuizOption opt) {
          setModalState(() {
            selectedOptionText = opt.text;
            isCorrect = opt.isCorrect;
          });
          if (opt.isCorrect && !_answeredTopicIds.contains(topic.id)) {
            _answeredTopicIds.add(topic.id);
            progress.addStars(2);
            progress.incrementChallengeProgress('explore');
          }
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                decoration: BoxDecoration(
                  color: KidColors.cream,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: accent.withOpacity(0.9), width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.55),
                      offset: const Offset(0, 8),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: KidColors.lighten(accent, 0.38),
                              border: Border.all(color: accent, width: 3),
                            ),
                            child: Text(topic.emoji,
                                style: const TextStyle(fontSize: 26)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              topic.getTitle(lang),
                              style: _fredoka(
                                  size: 20, weight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        topic.getQuestion(lang),
                        style: _fredoka(
                            size: 17, weight: FontWeight.w700, height: 1.3),
                      ),
                      const SizedBox(height: 14),
                      ...options.map((opt) {
                        final selected = selectedOptionText == opt.text;
                        return _OptionTile(
                          text: opt.text,
                          selected: selected,
                          correct: opt.isCorrect,
                          accent: accent,
                          onTap: () => handleSelect(setModalState, opt),
                        );
                      }),
                      if (isCorrect == true)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: _correctGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: _correctGreen.withOpacity(0.5),
                                width: 2),
                          ),
                          child: Text(
                            alreadyAnswered
                                ? '🎉 Correct! (Stars already collected for this topic)'
                                : '🎉 Correct! Earned +2 Stars!',
                            style: _fredoka(
                                size: 14, color: _correctGreen),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _ChunkyPill(
                          label: 'Close',
                          color: accent,
                          onTap: () => Navigator.of(dialogCtx).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final lang = progress.profile.selectedLanguage;

    return Scaffold(
      body: KidBackground(
        colors: const [Color(0xFFD6EEFB), KidColors.cream],
        child: SafeArea(
          child: Column(
            children: [
              const KidHeader(
                title: 'Explore World',
                emoji: '🌍',
                subtitle: 'Animals, Nature & Mini Science!',
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                  children: [
                    // language switcher
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _LangChip('EN', 'en', lang, progress),
                        const SizedBox(width: 8),
                        _LangChip('AR', 'ar', lang, progress),
                        const SizedBox(width: 8),
                        _LangChip('FR', 'fr', lang, progress),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Science lab banner
                    _ScienceLabCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ScienceLabScreen()),
                      ),
                    ),
                    const SizedBox(height: 18),

                    for (int i = 0; i < exploreTopics.length; i++)
                      _TopicTile(
                        topic: exploreTopics[i],
                        lang: lang,
                        accent: _topicAccents[i % _topicAccents.length],
                        onQuiz: () => _showTopicQuiz(
                          context,
                          exploreTopics[i],
                          lang,
                          _topicAccents[i % _topicAccents.length],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------- science lab card

class _ScienceLabCard extends StatefulWidget {
  final VoidCallback onTap;
  const _ScienceLabCard({required this.onTap});

  @override
  State<_ScienceLabCard> createState() => _ScienceLabCardState();
}

class _ScienceLabCardState extends State<_ScienceLabCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const depth = 6.0;
    const base = Color(0xFF8B5CF6);
    final offset = _down ? 2.0 : depth;

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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              colors: [Color(0xFFB48CF2), base],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withOpacity(0.55), width: 3),
            boxShadow: [
              BoxShadow(
                color: KidColors.darken(base),
                offset: Offset(0, offset),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.25),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.7), width: 3),
                ),
                child: const Text('🔬', style: TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mini Science Lab',
                      style: _fredoka(
                          size: 18,
                          color: Colors.white,
                          weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sink/Float, Color Mixing & Sun Experiments',
                      style: _fredoka(
                          size: 12,
                          color: Colors.white.withOpacity(0.9),
                          weight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      offset: const Offset(0, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: base, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- topic tile

class _TopicTile extends StatelessWidget {
  final ExploreTopic topic;
  final String lang;
  final Color accent;
  final VoidCallback onQuiz;

  const _TopicTile({
    required this.topic,
    required this.lang,
    required this.accent,
    required this.onQuiz,
  });

  @override
  Widget build(BuildContext context) {
    const depth = 6.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12 + depth),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: accent.withOpacity(0.5), width: 3),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.55),
              offset: const Offset(0, depth),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [KidColors.lighten(accent, 0.3), accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.7), width: 3),
                  ),
                  child:
                  Text(topic.emoji, style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    topic.getTitle(lang),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _fredoka(size: 17, weight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 8),
                _ChunkyPill(
                  label: 'Quiz',
                  icon: Icons.help_outline_rounded,
                  color: accent,
                  onTap: onQuiz,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              topic.getDesc(lang),
              style: _fredoka(
                size: 13.5,
                color: KidColors.textMuted,
                weight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ quiz option

class _OptionTile extends StatelessWidget {
  final String text;
  final bool selected;
  final bool correct;
  final Color accent;
  final VoidCallback onTap;

  const _OptionTile({
    required this.text,
    required this.selected,
    required this.correct,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const depth = 4.0;
    final Color bg = selected
        ? (correct ? _correctGreen : _wrongRed)
        : Colors.white;
    final Color edge = selected
        ? KidColors.darken(bg)
        : accent.withOpacity(0.45);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10 + depth),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: edge, width: 3),
            boxShadow: [
              BoxShadow(
                color: edge,
                offset: const Offset(0, depth),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: _fredoka(
                    size: 15,
                    color: selected ? Colors.white : KidColors.textDark,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: Colors.white,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- small bits

/// Small chunky pill button that sinks when pressed.
class _ChunkyPill extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback onTap;

  const _ChunkyPill({
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
  });

  @override
  State<_ChunkyPill> createState() => _ChunkyPillState();
}

class _ChunkyPillState extends State<_ChunkyPill> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const depth = 4.0;
    final offset = _down ? 1.0 : depth;

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: KidColors.darken(widget.color),
                offset: Offset(0, offset),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white, size: 18),
                const SizedBox(width: 4),
              ],
              Text(
                widget.label,
                style: _fredoka(
                    size: 14, color: Colors.white, weight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final String code;
  final String currentLang;
  final ProgressProvider progress;

  const _LangChip(this.label, this.code, this.currentLang, this.progress);

  @override
  Widget build(BuildContext context) {
    final selected = code == currentLang;
    const accent = Color(0xFF29B6F6);

    return GestureDetector(
      onTap: () => progress.setLanguage(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? accent : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? KidColors.darken(accent) : Colors.grey.shade300,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color:
              selected ? KidColors.darken(accent) : Colors.grey.shade300,
              offset: const Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          label,
          style: _fredoka(
            size: 13,
            weight: FontWeight.w800,
            color: selected ? Colors.white : KidColors.textMuted,
          ),
        ),
      ),
    );
  }
}