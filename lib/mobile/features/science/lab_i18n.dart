import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Languages of the science lab. The order matters: it matches the order of
/// the texts in [_strings] ([en, fr, ar]).
enum LabLang { en, fr, ar }

class LabI18n extends ChangeNotifier {
  LabI18n._();
  static final LabI18n instance = LabI18n._();

  static const String _prefKey = 'lab_lang';

  LabLang _lang = LabLang.en;
  LabLang get lang => _lang;
  bool get isRtl => _lang == LabLang.ar;
  TextDirection get direction => isRtl ? TextDirection.rtl : TextDirection.ltr;

  /// Language code used by the text-to-speech engine.
  String get ttsLocale {
    switch (_lang) {
      case LabLang.fr:
        return 'fr-FR';
      case LabLang.ar:
        return 'ar-SA';
      case LabLang.en:
        return 'en-US';
    }
  }

  /// Loads the saved language (or the phone language the first time).
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      LabLang next = _lang;
      if (saved != null) {
        for (final l in LabLang.values) {
          if (l.name == saved) next = l;
        }
      } else {
        final code =
            WidgetsBinding.instance.platformDispatcher.locale.languageCode;
        if (code == 'fr') next = LabLang.fr;
        if (code == 'ar') next = LabLang.ar;
      }
      if (next != _lang) {
        _lang = next;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setLang(LabLang l) async {
    if (l == _lang) return;
    _lang = l;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, l.name);
    } catch (_) {}
  }

  /// Translates [key]. Use {name} placeholders with [args].
  String t(String key, [Map<String, String>? args]) {
    final row = _strings[key];
    String s = row == null ? key : row[_lang.index];
    if (args != null) {
      args.forEach((k, v) {
        s = s.replaceAll('{$k}', v);
      });
    }
    return s;
  }
}

// [English, Français, العربية]
const Map<String, List<String>> _strings = {
  // ---- Screen ----
  'app_title': [
    "Mini Science Lab",
    "Mini Labo de Sciences",
    "مختبر العلوم الصغير",
  ],
  'tab_sink': ["Sink or Float", "Couler ou flotter", "يغرق أم يطفو"],
  'tab_color': ["Color War", "Guerre des couleurs", "حرب الألوان"],
  'tab_space': ["Day & Night", "Jour et nuit", "الليل والنهار"],
  'desc_sink': [
    "Drop things in the water. Do they sink or float?",
    "Lance des objets dans l'eau. Ils coulent ou ils flottent ?",
    "ارمِ الأشياء في الماء. هل تغرق أم تطفو؟",
  ],
  'desc_color': [
    "Two colors fight! What new color is born?",
    "Deux couleurs se battent ! Quelle nouvelle couleur naît ?",
    "لونان يتقاتلان! أي لون جديد يولد؟",
  ],
  'desc_space': [
    "Spin the Earth and see day turn into night.",
    "Fais tourner la Terre et vois le jour devenir nuit.",
    "أدِر الأرض وشاهد النهار يتحول إلى ليل.",
  ],
  'listen': ["Listen", "Écouter", "استمع"],
  'mute': ["Mute", "Couper le son", "كتم الصوت"],
  'unmute': ["Unmute", "Activer le son", "تشغيل الصوت"],
  'start_over': ["Start over", "Recommencer", "ابدأ من جديد"],
  'cont': ["CONTINUE", "CONTINUER", "متابعة"],
  'stage_title': [
    "Stage complete!",
    "Niveau terminé !",
    "أحسنت! أكملت المرحلة!",
  ],

  // ---- Sink or Float ----
  'sink_hint': [
    "Tap an item to drop it in the water!",
    "Touche un objet pour le lancer dans l'eau !",
    "المس شيئًا لترميه في الماء!",
  ],
  'item_duck': ["Duck", "Canard", "بطة"],
  'item_rock': ["Rock", "Rocher", "صخرة"],
  'item_apple': ["Apple", "Pomme", "تفاحة"],
  'item_key': ["Key", "Clé", "مفتاح"],
  'fact_duck': [
    "Floats! The duck is light for its size.",
    "Il flotte ! Le canard est léger pour sa taille.",
    "تطفو! البطة خفيفة بالنسبة لحجمها.",
  ],
  'fact_rock': [
    "Sinks! The rock is heavy for its size.",
    "Il coule ! Le rocher est lourd pour sa taille.",
    "تغرق! الصخرة ثقيلة بالنسبة لحجمها.",
  ],
  'fact_apple': [
    "Floats! The apple has tiny air pockets inside.",
    "Elle flotte ! La pomme a de petites poches d'air.",
    "تطفو! في التفاحة جيوب هواء صغيرة.",
  ],
  'fact_key': [
    "Sinks! Metal is heavy for its size.",
    "Elle coule ! Le métal est lourd pour sa taille.",
    "يغرق! المعدن ثقيل بالنسبة لحجمه.",
  ],
  'sink_done': [
    "You tested all 4 items. Great job, little scientist!",
    "Tu as testé les 4 objets. Bravo, petit scientifique !",
    "جرّبت الأشياء الأربعة. أحسنت يا عالمنا الصغير!",
  ],

  // ---- Color War ----
  'col_red': ["Red", "Rouge", "أحمر"],
  'col_yellow': ["Yellow", "Jaune", "أصفر"],
  'col_blue': ["Blue", "Bleu", "أزرق"],
  'col_orange': ["Orange", "Orange", "برتقالي"],
  'col_green': ["Green", "Vert", "أخضر"],
  'col_purple': ["Purple", "Violet", "بنفسجي"],
  'war_hint0': [
    "Pick the first fighter!",
    "Choisis le premier combattant !",
    "اختر المقاتل الأول!",
  ],
  'war_hint1': [
    "Now pick the second fighter!",
    "Maintenant, choisis le deuxième !",
    "الآن اختر المقاتل الثاني!",
  ],
  'war_fight': [
    "{a} versus {b}... FIGHT!",
    "{a} contre {b}... COMBAT !",
    "{a} ضد {b}... هيا نقاتل!",
  ],
  'war_orange': [
    "Red and Yellow made ORANGE! 🍊",
    "Rouge et jaune font ORANGE ! 🍊",
    "الأحمر والأصفر يصنعان البرتقالي! 🍊",
  ],
  'war_green': [
    "Blue and Yellow made GREEN! 🥦",
    "Bleu et jaune font VERT ! 🥦",
    "الأزرق والأصفر يصنعان الأخضر! 🥦",
  ],
  'war_purple': [
    "Red and Blue made PURPLE! 💜",
    "Rouge et bleu font VIOLET ! 💜",
    "الأحمر والأزرق يصنعان البنفسجي! 💜",
  ],
  'war_same': [
    "{a} and {a}... still {a}! Try two different colors.",
    "{a} et {a}... toujours {a} ! Essaie deux couleurs différentes.",
    "{a} و{a}... ما زال {a}! جرّب لونين مختلفين.",
  ],
  'war_new': ["New color! ", "Nouvelle couleur ! ", "لون جديد! "],
  'war_master': [
    "Color Master! You found all 3 mixes!",
    "Maître des couleurs ! Tu as trouvé les 3 mélanges !",
    "سيد الألوان! وجدت الخلطات الثلاث!",
  ],
  'war_done': [
    "You found all 3 color mixes. You are a Color Master!",
    "Tu as trouvé les 3 mélanges de couleurs. Tu es un maître des couleurs !",
    "وجدت خلطات الألوان الثلاث. أنت سيد الألوان!",
  ],
  'war_mixes': ["{n}/3 mixes", "{n}/3 mélanges", "{n}/3 خلطات"],

  // ---- Day & Night ----
  'space_hint': [
    "Tap the Earth to spin it! Tap the planets too.",
    "Touche la Terre pour la faire tourner ! Touche aussi les planètes.",
    "المس الأرض لتدور! والمس الكواكب أيضًا.",
  ],
  'space_day': [
    "Day time! Your side of Earth faces the Sun.",
    "C'est le jour ! Ton côté de la Terre fait face au Soleil.",
    "إنه النهار! جانبك من الأرض يواجه الشمس.",
  ],
  'space_night': [
    "Night time! Your side turned away from the Sun.",
    "C'est la nuit ! Ton côté s'est éloigné du Soleil.",
    "إنه الليل! جانبك ابتعد عن الشمس.",
  ],
  'spin': ["Spin Earth", "Tourner la Terre", "أدِر الأرض"],
  'you': ["You", "Toi", "أنت"],
  'fact_sun': [
    "The Sun is a giant star. It gives us light and heat!",
    "Le Soleil est une étoile géante. Il nous donne lumière et chaleur !",
    "الشمس نجمة عملاقة. تعطينا الضوء والدفء!",
  ],
  'fact_mercury': [
    "Mercury is the smallest planet, and the closest to the Sun!",
    "Mercure est la plus petite planète, et la plus proche du Soleil !",
    "عطارد أصغر الكواكب، وأقربها إلى الشمس!",
  ],
  'fact_venus': [
    "Venus is the hottest planet!",
    "Vénus est la planète la plus chaude !",
    "الزهرة هي أسخن الكواكب!",
  ],
  'fact_mars': [
    "Mars is the red planet!",
    "Mars est la planète rouge !",
    "المريخ هو الكوكب الأحمر!",
  ],
  'fact_moon': [
    "The Moon travels around the Earth!",
    "La Lune tourne autour de la Terre !",
    "القمر يدور حول الأرض!",
  ],
  'space_done': [
    "You watched a full day and night cycle. Well done!",
    "Tu as vu un jour et une nuit complets. Bien joué !",
    "شاهدت دورة كاملة من النهار والليل. أحسنت!",
  ],
};
