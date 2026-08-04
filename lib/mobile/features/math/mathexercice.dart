import 'dart:math';
import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------
/// Math mini-game screen — "Safari Math Trail"
/// ---------------------------------------------------------------------
/// Design concept (see design tokens below): the app already uses a
/// safari/savanna world (lion avatar, giraffe/hippo mascots, jungle
/// background). Instead of a generic sky-blue quiz, this screen leans
/// into that world: a warm sand-and-savanna palette, a "stepping-stone
/// trail" as the progress indicator (each stone = one question, filled
/// in as the child answers), color-coded skill badges per question type,
/// and a lion companion that reacts to right/wrong answers with short
/// Darija/Arabic encouragement.
///
/// Six question types rotate randomly so the exercise stays varied,
/// while every question still uses only small numbers (1-10) and simple
/// operations — appropriate for kids aged 3 to 9:
///   1. Addition            3 + 4 = ?
///   2. Subtraction         8 - 3 = ?
///   3. Missing number      3 + ? = 7
///   4. Counting             🍌🍌🍌 → how many?
///   5. Small multiplication 2 × 3 = ?  (factors 2-5 only)
///   6. Number order          the number right after / before 5
///
/// Usage: replace the generic ActivityDetailScreen for the "Math" card:
///   onTap: () => Navigator.of(context).push(
///     MaterialPageRoute(builder: (_) => const MathExerciseScreen()),
///   ),
class MathExerciseScreen extends StatefulWidget {
  final int totalQuestions;
  const MathExerciseScreen({super.key, this.totalQuestions = 8});

  @override
  State<MathExerciseScreen> createState() => _MathExerciseScreenState();
}

// --- Design tokens ------------------------------------------------------
// Savanna palette: warm sand base, deep jungle text, and a distinct
// accent color per question "skill" so the trail of badges also tells
// the child (and a watching parent) what kind of question is coming.
class _Palette {
  static const Color sand = Color(0xFFFBF1DC);
  static const Color sandDeep = Color(0xFFF3E1B8);
  static const Color jungleDeep = Color(0xFF1F5D4C);
  static const Color textDark = Color(0xFF213238);
  static const Color textMuted = Color(0xFF7C8C93);

  static const Color addition = Color(0xFF4CAF7D); // leaf green
  static const Color subtraction = Color(0xFFF2994A); // sunset orange
  static const Color missing = Color(0xFFE0507B); // berry pink
  static const Color counting = Color(0xFF4FB6E8); // river blue
  static const Color multiply = Color(0xFF8B5CF6); // plum purple
  static const Color order = Color(0xFFD9A441); // dune gold

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
  final List<String> _rightPhrases = ['زوينة! 🌟', 'برافو عليك!', 'قوي بزاف!', 'خطيرة!'];
  final List<String> _wrongPhrases = ['قريب! حاول عاود', 'يالله، مرة أخرى', 'ماشي هي، عاود الكرة'];
  final List<String> _emojiPool = ['🍌', '🍎', '🍊', '🐘', '🦋', '🐢', '⭐'];

  // NOTE: these were previously declared `late` and only assigned inside
  // initState(). That pattern breaks if a State object survives a hot
  // reload from before this field existed (or before initState ran),
  // throwing LateInitializationError on the next build(). Giving them
  // safe default values up front makes the screen resilient to that,
  // with zero behavior change in normal (non-hot-reload) use, since
  // initState() still overwrites them immediately on first build.
  List<bool?> _trail = [];
  int _index = 0;
  _Question? _question;
  int? _selected;
  bool _locked = false;
  bool _finished = false;
  int get _score => _trail.where((r) => r == true).length;
  String _mascotPhrase = 'يالله نلعبو!';

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
      final offset = _rng.nextInt(9) - 4; // -4..4
      final candidate = correct + offset;
      if (candidate >= min && candidate != correct) options.add(candidate);
    }
    // fallback fill, in case the range was too tight
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
    style: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.5,
      color: color ?? _Palette.textDark,
    ),
  );

  _Question _addition() {
    final a = _rng.nextInt(9) + 1;
    final b = _rng.nextInt(9) + 1;
    final answer = a + b;
    return _Question(
      type: _QType.addition,
      promptBuilder: (_) => _equationText('$a + $b = ؟'),
      answer: answer,
      options: _distractors(answer),
      accent: _Palette.addition,
      badgeLabel: 'جمع',
      badgeIcon: Icons.add_rounded,
    );
  }

  _Question _subtraction() {
    final a = _rng.nextInt(9) + 2; // 2..10
    final b = _rng.nextInt(a); // 0..a-1
    final answer = a - b;
    return _Question(
      type: _QType.subtraction,
      promptBuilder: (_) => _equationText('$a - $b = ؟'),
      answer: answer,
      options: _distractors(answer),
      accent: _Palette.subtraction,
      badgeLabel: 'طرح',
      badgeIcon: Icons.remove_rounded,
    );
  }

  _Question _missingNumber() {
    final a = _rng.nextInt(7) + 1; // 1..7
    final missing = _rng.nextInt(7) + 1; // 1..7
    final c = a + missing;
    return _Question(
      type: _QType.missing,
      promptBuilder: (_) => _equationText('$a + ؟ = $c'),
      answer: missing,
      options: _distractors(missing, min: 0),
      accent: _Palette.missing,
      badgeLabel: 'الرقم الناقص',
      badgeIcon: Icons.help_outline_rounded,
    );
  }

  _Question _counting() {
    final count = _rng.nextInt(8) + 2; // 2..9
    final emoji = _emojiPool[_rng.nextInt(_emojiPool.length)];
    return _Question(
      type: _QType.counting,
      promptBuilder: (_) => Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: List.generate(
          count,
              (i) => Text(emoji, style: const TextStyle(fontSize: 28)),
        ),
      ),
      answer: count,
      options: _distractors(count, min: 1),
      accent: _Palette.counting,
      badgeLabel: 'عد',
      badgeIcon: Icons.pin_rounded,
    );
  }

  _Question _multiply() {
    final a = _rng.nextInt(4) + 2; // 2..5
    final b = _rng.nextInt(4) + 2; // 2..5
    final answer = a * b;
    return _Question(
      type: _QType.multiply,
      promptBuilder: (_) => _equationText('$a × $b = ؟'),
      answer: answer,
      options: _distractors(answer),
      accent: _Palette.multiply,
      badgeLabel: 'ضرب',
      badgeIcon: Icons.close_rounded,
    );
  }

  _Question _order() {
    final n = _rng.nextInt(9) + 1; // 1..9
    final after = _rng.nextBool();
    final answer = after ? n + 1 : n - 1;
    final prompt = after ? 'الرقم لي كيجي من بعد $n' : 'الرقم لي كيجي قبل $n';
    return _Question(
      type: _QType.order,
      promptBuilder: (_) => Text(
        '$prompt ؟',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: _Palette.textDark,
        ),
      ),
      answer: answer,
      options: _distractors(answer, min: 0),
      accent: _Palette.order,
      badgeLabel: 'ترتيب الأرقام',
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
      _mascotPhrase = 'يالله نلعبو!';
      _question = _buildQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Defensive fallback: normally initState() has already set _question
    // by the time build() runs. This only triggers in the rare hot-reload
    // edge case where a State object survives a reload without initState
    // re-running (e.g. this screen was already mounted before you reloaded).
    if (_question == null) {
      return const Scaffold(
        backgroundColor: _Palette.sand,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final question = _question!;

    return Scaffold(
      backgroundColor: _Palette.sand,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_Palette.sand, _Palette.sandDeep],
                ),
              ),
            ),
          ),
          // Faint dune silhouette along the bottom, echoing the app's
          // savanna world without needing extra image assets.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 120,
            child: CustomPaint(painter: _DunePainter()),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _RoundIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
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
                  _StoneTrail(trail: _trail, current: _index, finished: _finished),
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
        ],
      ),
    );
  }
}

/// Stepping-stone progress trail — the app's signature element for this
/// screen. Each stone is one question: hollow while pending, green when
/// answered correctly, coral when missed, and the current stone sits
/// slightly larger with a lion "footprint" beneath it.
class _StoneTrail extends StatelessWidget {
  final List<bool?> trail;
  final int current;
  final bool finished;

  const _StoneTrail({required this.trail, required this.current, required this.finished});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Row(
        children: List.generate(trail.length, (i) {
          final result = trail[i];
          final bool isCurrent = !finished && i == current;
          Color fill;
          Widget? child;
          if (result == true) {
            fill = _Palette.correct;
            child = const Icon(Icons.check_rounded, size: 14, color: Colors.white);
          } else if (result == false) {
            fill = _Palette.wrong;
            child = const Icon(Icons.close_rounded, size: 14, color: Colors.white);
          } else {
            fill = Colors.white;
          }
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: isCurrent ? 14 : 10,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(20),
                  border: result == null
                      ? Border.all(color: _Palette.jungleDeep.withOpacity(0.25), width: 1.4)
                      : null,
                  boxShadow: isCurrent
                      ? [
                    BoxShadow(
                      color: _Palette.jungleDeep.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                      : null,
                ),
                alignment: Alignment.center,
                child: child == null
                    ? null
                    : SizedBox(height: 10, child: FittedBox(child: child)),
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

  const _SkillBadge({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

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
        const SizedBox(height: 14),
        // Lion companion + speech bubble reacting to the last answer.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                mascotPhrase,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _Palette.textDark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('🦁', style: TextStyle(fontSize: 34)),
          ],
        ),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: question.accent.withOpacity(0.35), width: 1.6),
            boxShadow: [
              BoxShadow(
                color: question.accent.withOpacity(0.15),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(child: question.promptBuilder(context)),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: question.options.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.9,
            ),
            itemBuilder: (context, index) {
              final value = question.options[index];
              // Small alternating tilt on each stone for a hand-placed,
              // non-grid feel — the one deliberate aesthetic risk here.
              final double tilt = (index.isEven ? -1 : 1) * (2.5 + (index % 3));
              return Transform.rotate(
                angle: tilt * pi / 180,
                child: _AnswerStone(
                  value: value,
                  isSelected: selected == value,
                  isCorrect: value == question.answer,
                  revealed: locked,
                  accent: question.accent,
                  onTap: () => onTap(value),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AnswerStone extends StatelessWidget {
  final int value;
  final bool isSelected;
  final bool isCorrect;
  final bool revealed;
  final Color accent;
  final VoidCallback onTap;

  const _AnswerStone({
    required this.value,
    required this.isSelected,
    required this.isCorrect,
    required this.revealed,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.white;
    Color fg = _Palette.textDark;
    Color border = accent.withOpacity(0.25);

    if (revealed && isSelected) {
      bg = isCorrect ? _Palette.correct : _Palette.wrong;
      fg = Colors.white;
      border = Colors.transparent;
    } else if (revealed && isCorrect) {
      bg = _Palette.correct.withOpacity(0.14);
      fg = _Palette.correct;
      border = _Palette.correct.withOpacity(0.4);
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(22),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.12),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border, width: 1.6),
          ),
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: fg),
          ),
        ),
      ),
    );
  }
}

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(great ? '🏆' : '🦁', style: const TextStyle(fontSize: 60)),
          const SizedBox(height: 14),
          Text(
            great ? 'زوين بزاف!' : 'مجهود مزيان!',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _Palette.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'جاوبتي صحيح على $score من $total',
            style: TextStyle(fontSize: 14, color: _Palette.textMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 26),
          ElevatedButton(
            onPressed: onRestart,
            style: ElevatedButton.styleFrom(
              backgroundColor: _Palette.jungleDeep,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 14),
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            child: const Text('عاود اللعب', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onExit,
            child: Text(
              'رجوع للأنشطة',
              style: TextStyle(color: _Palette.textMuted, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: _Palette.textDark, size: 18),
      ),
    );
  }
}

/// Soft dune silhouette painted along the bottom edge — a light nod to
/// the app's savanna backdrop without requiring an extra image asset.
class _DunePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _Palette.jungleDeep.withOpacity(0.08);
    final path = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.22, size.height * 0.2, size.width * 0.48, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.8, size.width, size.height * 0.35)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}