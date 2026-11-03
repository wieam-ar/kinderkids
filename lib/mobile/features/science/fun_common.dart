import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'lab_common.dart';
import 'lab_i18n.dart';

// Re-exported so the screens only need ONE import.
export 'lab_common.dart'
    show
        LabSfx,
        LabBurst,
        LabShake,
        LabLangBar,
        LabBackdrop,
        LabProgressPill,
        LabChunkyButton,
        showStageComplete,
        labDarken,
        labLighten;
export 'lab_i18n.dart' show LabI18n, LabLang;

// ---------------------------------------------------------------------------
// Texts for Draw / Color / Puzzle screens: [English, Français, العربية]
// The language itself is shared with the science lab (LabI18n).
// ---------------------------------------------------------------------------

const Map<String, List<String>> _funStrings = {
  // ---- Common ----
  'back': ["Back", "Retour", "رجوع"],
  'undo': ["Undo", "Annuler", "تراجع"],
  'redo': ["Redo", "Rétablir", "إعادة"],
  'clear': ["Clear", "Effacer", "مسح"],

  // ---- Draw ----
  'draw_title': ["Let's Draw!", "Dessinons !", "هيا نرسم!"],
  'draw_hint': [
    "Draw with your finger!",
    "Dessine avec ton doigt !",
    "ارسم بإصبعك!",
  ],
  'rainbow': ["Rainbow brush", "Pinceau arc-en-ciel", "فرشاة قوس قزح"],

  // ---- Color picker ----
  'paint_title': ["Let's Color!", "Coloriage !", "هيا نلوّن!"],
  'paint_sub': [
    "Tap a picture to color it!",
    "Touche un dessin pour le colorier !",
    "المس رسمة لتلوّنها!",
  ],
  // Titles of the coloring pictures (key = ci_ + title in lower case).
  // Add yours here; unknown titles just show the original text.
  'ci_cat': ["Cat", "Chat", "قطة"],
  'ci_dog': ["Dog", "Chien", "كلب"],
  'ci_fish': ["Fish", "Poisson", "سمكة"],
  'ci_butterfly': ["Butterfly", "Papillon", "فراشة"],
  'ci_flower': ["Flower", "Fleur", "زهرة"],
  'ci_house': ["House", "Maison", "منزل"],
  'ci_car': ["Car", "Voiture", "سيارة"],
  'ci_tree': ["Tree", "Arbre", "شجرة"],
  'ci_sun': ["Sun", "Soleil", "شمس"],
  'ci_rocket': ["Rocket", "Fusée", "صاروخ"],
  'ci_dinosaur': ["Dinosaur", "Dinosaure", "ديناصور"],
  'ci_elephant': ["Elephant", "Éléphant", "فيل"],
  'ci_lion': ["Lion", "Lion", "أسد"],
  'ci_bird': ["Bird", "Oiseau", "عصفور"],
  'ci_star': ["Star", "Étoile", "نجمة"],
  'ci_heart': ["Heart", "Cœur", "قلب"],
  'ci_rabbit': ["Rabbit", "Lapin", "أرنب"],
  'ci_turtle': ["Turtle", "Tortue", "سلحفاة"],
  'ci_apple': ["Apple", "Pomme", "تفاحة"],
  'ci_owl': ["Owl", "Hibou", "بومة"],
  'ci_bear': ["Bear", "Ours", "دب"],
  'ci_whale': ["Whale", "Baleine", "حوت"],
  'ci_duck': ["Duck", "Canard", "بطة"],
  'ci_unicorn': ["Unicorn", "Licorne", "حصان أحادي القرن"],

  // ---- Puzzle picker ----
  'pz_title': ["Puzzles", "Puzzles", "البازل"],
  'pz_sub': [
    "Pick a picture and a level!",
    "Choisis une image et un niveau !",
    "اختر صورة ومستوى!",
  ],
  'th_animals': ["Animals", "Animaux", "حيوانات"],
  'th_fruits': ["Fruits", "Fruits", "فواكه"],
  'th_ocean': ["Ocean", "Océan", "محيط"],
  'th_space': ["Space", "Espace", "فضاء"],
  'th_dinosaurs': ["Dinosaurs", "Dinosaures", "ديناصورات"],
  'th_vehicles': ["Vehicles", "Véhicules", "مركبات"],
  'th_insects': ["Insects", "Insectes", "حشرات"],
  'th_weather': ["Weather", "Météo", "الطقس"],
  'lv_easy': ["Easy", "Facile", "سهل"],
  'lv_medium': ["Medium", "Moyen", "متوسط"],
  'lv_hard': ["Hard", "Difficile", "صعب"],
  'pz_level': ["Puzzle level", "Niveau du puzzle", "مستوى البازل"],
  'pz_pieces_q': [
    "How many pieces?",
    "Combien de pièces ?",
    "كم عدد القطع؟",
  ],
  'pz_pieces': ["{n} pieces", "{n} pièces", "{n} قطعة"],

  // ---- Puzzle game ----
  'pz_peek_hint': [
    "Hold 👁 to peek · drag pieces into place",
    "Maintiens 👁 pour voir · glisse les pièces",
    "اضغط مطولًا على 👁 للنظر · اسحب القطع إلى مكانها",
  ],
  'pz_try': [
    "Not there! Try another spot.",
    "Pas ici ! Essaie une autre place.",
    "ليس هنا! جرّب مكانًا آخر.",
  ],
  'pz_good': ["Perfect fit! ✨", "Parfait ! ✨", "مكانها الصحيح! ✨"],
  'pz_hint_btn': [
    "Hint: place a piece for me",
    "Indice : place une pièce pour moi",
    "تلميح: ضع قطعة من أجلي",
  ],
  'pz_moves': ["{n} moves", "{n} coups", "{n} حركات"],
  'pz_great': ["Great job!", "Bravo !", "أحسنت!"],
  'pz_win': [
    "You solved the {theme} puzzle in {n} moves!",
    "Tu as résolu le puzzle {theme} en {n} coups !",
    "حللت بازل {theme} في {n} حركات!",
  ],
  'pz_next': ["What next?", "Et maintenant ?", "ماذا بعد؟"],
  'pz_again': ["Play again", "Rejouer", "العب مرة أخرى"],
  'pz_other': ["Choose another", "Choisir un autre", "اختر غيره"],
};

bool funHas(String key) => _funStrings.containsKey(key);

/// Translates [key] in the current language. Use {name} placeholders.
String ft(String key, [Map<String, String>? args]) {
  final row = _funStrings[key];
  String s = row == null ? key : row[LabI18n.instance.lang.index];
  if (args != null) {
    args.forEach((k, v) {
      s = s.replaceAll('{$k}', v);
    });
  }
  return s;
}

bool _langLoaded = false;

/// Makes a State rebuild when the language changes + gives it [tr] and [dir].
mixin FunLang<T extends StatefulWidget> on State<T> {
  LabI18n get i18n => LabI18n.instance;

  String tr(String key, [Map<String, String>? args]) => ft(key, args);

  TextDirection get dir => i18n.direction;

  @override
  void initState() {
    super.initState();
    i18n.addListener(_funLangChanged);
    if (!_langLoaded) {
      _langLoaded = true;
      i18n.load();
    }
  }

  void _funLangChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    i18n.removeListener(_funLangChanged);
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Animation building blocks
// ---------------------------------------------------------------------------

/// Pops in with a springy bounce (after [delayMs]) when first shown.
class FunPopIn extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const FunPopIn({super.key, required this.child, this.delayMs = 0});

  @override
  State<FunPopIn> createState() => _FunPopInState();
}

class _FunPopInState extends State<FunPopIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    final total = widget.delayMs + 700;
    final start = widget.delayMs / total;
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: total),
    );
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _c,
        curve: Interval(start, 1.0, curve: Curves.elasticOut),
      ),
    );
    _fade = CurvedAnimation(
      parent: _c,
      curve: Interval(start, math.min(1.0, start + 0.25), curve: Curves.easeOut),
    );
    _slide = CurvedAnimation(
      parent: _c,
      curve: Interval(start, 1.0, curve: Curves.easeOutCubic),
    );
    _c.forward();
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
      builder: (context, child) => Opacity(
        opacity: _fade.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - _slide.value)),
          child: Transform.scale(scale: _scale.value, child: child),
        ),
      ),
    );
  }
}

/// Endless gentle floating up and down.
class FunBounce extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final double seconds;
  final double phase; // 0..1, so a group does not move in sync

  const FunBounce({
    super.key,
    required this.child,
    this.amplitude = 5,
    this.seconds = 2.2,
    this.phase = 0,
  });

  @override
  State<FunBounce> createState() => _FunBounceState();
}

class _FunBounceState extends State<FunBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (widget.seconds * 1000).round()),
  );

  @override
  void initState() {
    super.initState();
    _c.value = widget.phase.clamp(0.0, 1.0);
    _c.repeat(reverse: true);
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
      builder: (context, child) => Transform.translate(
        offset: Offset(
          0,
          -widget.amplitude * Curves.easeInOut.transform(_c.value),
        ),
        child: child,
      ),
    );
  }
}

/// Shrinks a little while pressed, then springs back.
class FunPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;
  final double pressedScale;

  const FunPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.pressedScale = 0.93,
  });

  @override
  State<FunPressable> createState() => _FunPressableState();
}

class _FunPressableState extends State<FunPressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: widget.onTap,
      onLongPressStart: widget.onLongPressStart == null
          ? null
          : (_) {
              setState(() => _down = true);
              widget.onLongPressStart!();
            },
      onLongPressEnd: widget.onLongPressEnd == null
          ? null
          : (_) {
              setState(() => _down = false);
              widget.onLongPressEnd!();
            },
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Small round white icon button (back / undo / redo / clear ...).
class FunRoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;
  final Color color;
  final String? tooltip;
  final double size;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;

  const FunRoundButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.enabled = true,
    this.color = const Color(0xFF0F92CA),
    this.tooltip,
    this.size = 42,
    this.onLongPressStart,
    this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    Widget btn = Opacity(
      opacity: enabled ? 1 : 0.35,
      child: FunPressable(
        onTap: enabled ? onTap : null,
        onLongPressStart: enabled ? onLongPressStart : null,
        onLongPressEnd: enabled ? onLongPressEnd : null,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, size: size * 0.48, color: color),
        ),
      ),
    );
    if (tooltip != null) btn = Tooltip(message: tooltip!, child: btn);
    return btn;
  }
}
