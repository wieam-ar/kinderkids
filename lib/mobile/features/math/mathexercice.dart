import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/ui/kid_ui.dart';
import '../../data/providers/progress_provider.dart';

TextStyle _fredoka({
  double size = 15,
  Color color = KidColors.textDark,
  FontWeight weight = FontWeight.w700,
}) =>
    GoogleFonts.fredoka(fontSize: size, fontWeight: weight, color: color);

class MathExerciseScreen extends StatefulWidget {
  final int totalQuestions;
  const MathExerciseScreen({super.key, this.totalQuestions = 8});

  @override
  State<MathExerciseScreen> createState() => _MathExerciseScreenState();
}

class _Palette {
  static const Color addition = Color(0xFF4CAF7D);
  static const Color subtraction = Color(0xFFF2994A);
  static const Color missing = Color(0xFFE0507B);
  static const Color counting = Color(0xFF3AAAE0);
  static const Color multiply = Color(0xFF8B5CF6);
  static const Color order = Color(0xFFE0A800);

  static const Color correct = Color(0xFF4CAF7D);
  static const Color wrong = Color(0xFFFF6B5E);
}

enum _QType { addition, subtraction, missing, counting, multiply, order }

class _Question {
  final _QType type;
  final Widget Function(BuildContext) promptBuilder;
  final int answer;
  final List<int> options;
  final Color accent;
  final String badgeLabel;
  final IconData badgeIcon;

  _Question({
    required this.type,
    required this.promptBuilder,
    required this.answer,
    required this.options,
    required this.accent,
    required this.badgeLabel,
    required this.badgeIcon,
  });
}

class _MathExerciseScreenState extends State<MathExerciseScreen> {
  final Random _rng = Random();
  final List<String> _rightPhrases = [
    'Great job! 🌟',
    'Well done!',
    'Super smart!',
    'Awesome!'
  ];
  final List<String> _wrongPhrases = [
    'So close! Try again',
    "Let's try once more",
    'Not quite, try again'
  ];
  final List<String> _emojiPool = ['🍌', '🍎', '🍊', '🐘', '🦋', '🐢', '⭐'];

  List<bool?> _trail = [];
  int _index = 0;
  _Question? _question;
  int? _selected;
  bool _locked = false;
  bool _finished = false;
  int get _score => _trail.where((r) => r == true).length;
  String _mascotPhrase = "Let's play!";

  @override
  void initState() {
    super.initState();
    _index = 0;
    _trail = List<bool?>.filled(widget.totalQuestions, null);
    _question = _buildQuestion();
  }

  // --- Question generation ----------------------------------------------

  _Question _buildQuestion() {
    final types = _QType.values;
    final type = types[_rng.nextInt(types.length)];
    switch (type) {
      case _QType.addition:
        return _addition();
      case _QType.subtraction:
        return _subtraction();
      case _QType.missing:
        return _missingNumber();
      case _QType.counting:
        return _counting();
      case _QType.multiply:
        return _multiply();
      case _QType.order:
        return _order();
    }
  }

  List<int> _distractors(int correct, {int min = 0}) {
    final Set<int> options = {correct};
    int guard = 0;
    while (options.length < 6 && guard < 50) {
      guard++;
      final offset = _rng.nextInt(9) - 4;
      final candidate = correct + offset;
      if (candidate >= min && candidate != correct) options.add(candidate);
    }
    int extra = correct + min + 1;
    while (options.length < 6) {
      if (extra != correct && extra >= min) options.add(extra);
      extra++;
    }
    final list = options.toList()..shuffle(_rng);
    return list;
  }

  Widget _equationText(String text, {Color? color}) => Text(
    text,
    style: _fredoka(
      size: 40,
      weight: FontWeight.w800,
      color: color ?? KidColors.textDark,
    ),
  );

  _Question _addition() {
    final a = _rng.nextInt(9) + 1;
    final b = _rng.nextInt(9) + 1;
    final answer = a + b;
    return _Question(
      type: _QType.addition,
      promptBuilder: (_) => _equationText('$a + $b = ?'),
      answer: answer,
      options: _distractors(answer),
      accent: _Palette.addition,
      badgeLabel: 'Addition',
      badgeIcon: Icons.add_rounded,
    );
  }

  _Question _subtraction() {
    final a = _rng.nextInt(9) + 2;
    final b = _rng.nextInt(a);
    final answer = a - b;
    return _Question(
      type: _QType.subtraction,
      promptBuilder: (_) => _equationText('$a - $b = ?'),
      answer: answer,
      options: _distractors(answer),
      accent: _Palette.subtraction,
      badgeLabel: 'Subtraction',
      badgeIcon: Icons.remove_rounded,
    );
  }

  _Question _missingNumber() {
    final a = _rng.nextInt(7) + 1;
    final missing = _rng.nextInt(7) + 1;
    final c = a + missing;
    return _Question(
      type: _QType.missing,
      promptBuilder: (_) => _equationText('$a + ? = $c'),
      answer: missing,
      options: _distractors(missing, min: 0),
      accent: _Palette.missing,
      badgeLabel: 'Missing Number',
      badgeIcon: Icons.help_outline_rounded,
    );
  }

  _Question _counting() {
    final count = _rng.nextInt(8) + 2;
    final emoji = _emojiPool[_rng.nextInt(_emojiPool.length)];
    return _Question(
      type: _QType.counting,
      promptBuilder: (_) => Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: List.generate(
          count,
              (i) => Text(emoji, style: const TextStyle(fontSize: 30)),
        ),
      ),
      answer: count,
      options: _distractors(count, min: 1),
      accent: _Palette.counting,
      badgeLabel: 'Counting',
      badgeIcon: Icons.pin_rounded,
    );
  }

  _Question _multiply() {
    final a = _rng.nextInt(4) + 2;
    final b = _rng.nextInt(4) + 2;
    final answer = a * b;
    return _Question(
      type: _QType.multiply,
      promptBuilder: (_) => _equationText('$a × $b = ?'),
      answer: answer,
      options: _distractors(answer),
      accent: _Palette.multiply,
      badgeLabel: 'Multiplication',
      badgeIcon: Icons.close_rounded,
    );
  }

  _Question _order() {
    final n = _rng.nextInt(9) + 1;
    final after = _rng.nextBool();
    final answer = after ? n + 1 : n - 1;
    final prompt =
    after ? 'What number comes after $n' : 'What number comes before $n';
    return _Question(
      type: _QType.order,
      promptBuilder: (_) => Text(
        '$prompt?',
        textAlign: TextAlign.center,
        style: _fredoka(size: 26, weight: FontWeight.w800),
      ),
      answer: answer,
      options: _distractors(answer, min: 0),
      accent: _Palette.order,
      badgeLabel: 'Number Order',
      badgeIcon: Icons.swap_horiz_rounded,
    );
  }

  // --- Interaction --------------------------------------------------------

  void _onOptionTap(int value) {
    if (_locked || _question == null) return;
    final bool isCorrect = value == _question!.answer;
    setState(() {
      _selected = value;
      _locked = true;
      _trail[_index] = isCorrect;
      _mascotPhrase = isCorrect
          ? _rightPhrases[_rng.nextInt(_rightPhrases.length)]
          : _wrongPhrases[_rng.nextInt(_wrongPhrases.length)];
    });

    if (isCorrect) {
      final progress = Provider.of<ProgressProvider>(context, listen: false);
      progress.addStars(1);
      progress.incrementChallengeProgress('math');
    }

    Future.delayed(const Duration(milliseconds: 750), () {
      if (!mounted) return;
      if (_index + 1 >= widget.totalQuestions) {
        setState(() => _finished = true);
      } else {
        setState(() {
          _index++;
          _selected = null;
          _locked = false;
          _question = _buildQuestion();
        });
      }
    });
  }

  void _restart() {
    setState(() {
      _index = 0;
      _trail = List<bool?>.filled(widget.totalQuestions, null);
      _selected = null;
      _locked = false;
      _finished = false;
      _mascotPhrase = "Let's play!";
      _question = _buildQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_question == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final question = _question!;

    return Scaffold(
      body: KidBackground(
        colors: const [Color(0xFFE6DBFF), KidColors.cream],
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    KidRoundButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      color: KidColors.purple,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    if (!_finished)
                      _SkillBadge(
                        label: question.badgeLabel,
                        icon: question.badgeIcon,
                        color: question.accent,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _StoneTrail(
                    trail: _trail, current: _index, finished: _finished),
                Expanded(
                  child: _finished
                      ? _ResultView(
                    score: _score,
                    total: widget.totalQuestions,
                    onRestart: _restart,
                    onExit: () => Navigator.of(context).pop(),
                  )
                      : _QuestionCard(
                    question: question,
                    selected: _selected,
                    locked: _locked,
                    onTap: _onOptionTap,
                    mascotPhrase: _mascotPhrase,
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

// ---------------------------------------------------------- progress trail

class _StoneTrail extends StatelessWidget {
  final List<bool?> trail;
  final int current;
  final bool finished;

  const _StoneTrail(
      {required this.trail, required this.current, required this.finished});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Row(
        children: List.generate(trail.length, (i) {
          final result = trail[i];
          final bool isCurrent = !finished && i == current;
          Color fill;
          Widget? child;
          if (result == true) {
            fill = _Palette.correct;
            child =
            const Icon(Icons.check_rounded, size: 16, color: Colors.white);
          } else if (result == false) {
            fill = _Palette.wrong;
            child =
            const Icon(Icons.close_rounded, size: 16, color: Colors.white);
          } else {
            fill = isCurrent
                ? KidColors.purple.withOpacity(0.35)
                : Colors.white.withOpacity(0.9);
          }
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: isCurrent ? 22 : 16,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: result == null
                          ? KidColors.purple.withOpacity(0.4)
                          : Colors.white.withOpacity(0.7),
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: child == null
                      ? null
                      : FittedBox(
                      child: Padding(
                          padding: const EdgeInsets.all(1), child: child)),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SkillBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SkillBadge(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.55), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: KidColors.darken(color, 0.12)),
          const SizedBox(width: 6),
          Text(label,
              style: _fredoka(size: 14, color: KidColors.darken(color, 0.12))),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------- question card

class _QuestionCard extends StatelessWidget {
  final _Question question;
  final int? selected;
  final bool locked;
  final ValueChanged<int> onTap;
  final String mascotPhrase;

  const _QuestionCard({
    required this.question,
    required this.selected,
    required this.locked,
    required this.onTap,
    required this.mascotPhrase,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale:
                CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Container(
                key: ValueKey(mascotPhrase),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: question.accent.withOpacity(0.5), width: 2),
                ),
                child: Text(mascotPhrase, style: _fredoka(size: 14)),
              ),
            ),
            const SizedBox(width: 8),
            const Text('🦁', style: TextStyle(fontSize: 36)),
          ],
        ),
        const SizedBox(height: 16),
        KidCard(
          accent: question.accent,
          radius: 32,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
          child: SizedBox(
            width: double.infinity,
            child: Center(child: question.promptBuilder(context)),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: question.options.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 6,
              crossAxisSpacing: 14,
              childAspectRatio: 1.9,
            ),
            itemBuilder: (context, index) {
              final value = question.options[index];
              return _AnswerTile(
                value: value,
                isSelected: selected == value,
                isCorrect: value == question.answer,
                revealed: locked,
                accent: question.accent,
                onTap: () => onTap(value),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AnswerTile extends StatefulWidget {
  final int value;
  final bool isSelected;
  final bool isCorrect;
  final bool revealed;
  final Color accent;
  final VoidCallback onTap;

  const _AnswerTile({
    required this.value,
    required this.isSelected,
    required this.isCorrect,
    required this.revealed,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_AnswerTile> createState() => _AnswerTileState();
}

class _AnswerTileState extends State<_AnswerTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const depth = 6.0;

    Color color = widget.accent;
    if (widget.revealed && widget.isSelected) {
      color = widget.isCorrect ? _Palette.correct : _Palette.wrong;
    } else if (widget.revealed && widget.isCorrect) {
      color = _Palette.correct;
    } else if (widget.revealed) {
      color = widget.accent.withOpacity(0.45);
    }

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
          duration: const Duration(milliseconds: 120),
          transform: Matrix4.translationValues(0, depth - offset, 0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [KidColors.lighten(color, 0.08), color],
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 3),
            boxShadow: [
              BoxShadow(
                color: KidColors.darken(color),
                offset: Offset(0, offset),
                blurRadius: 0,
              ),
            ],
          ),
          child: Text(
            '${widget.value}',
            style: _fredoka(
                size: 30, color: Colors.white, weight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- result

class _ResultView extends StatelessWidget {
  final int score;
  final int total;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  const _ResultView({
    required this.score,
    required this.total,
    required this.onRestart,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final bool great = score >= (total * 0.7);
    return Center(
      child: KidCard(
        accent: KidColors.purple,
        radius: 32,
        padding: const EdgeInsets.fromLTRB(26, 28, 26, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(great ? '🏆' : '🦁', style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 8),
            Text(great ? 'Awesome job!' : 'Nice effort!',
                style: _fredoka(size: 26, weight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'You got $score out of $total right',
              style: _fredoka(
                  size: 15,
                  color: KidColors.textMuted,
                  weight: FontWeight.w600),
            ),
            const SizedBox(height: 22),
            KidButton(
              label: 'Play Again',
              icon: Icons.replay_rounded,
              color: KidColors.purple,
              expand: true,
              onPressed: onRestart,
            ),
            const SizedBox(height: 14),
            KidButton(
              label: 'Back to Activities',
              icon: Icons.check_rounded,
              color: KidColors.green,
              expand: true,
              onPressed: onExit,
            ),
          ],
        ),
      ),
    );
  }
}