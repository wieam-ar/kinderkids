import '../science/lab_i18n.dart';

// [English, Français, العربية]  (the language is shared with the whole app)
const Map<String, List<String>> _storyStrings = {
  'st_title': ["Reading Time", "Heure de lecture", "وقت القراءة"],
  'st_play': ["Read to me", "Lis-moi l'histoire", "اقرأ لي"],
  'st_pause': ["Pause", "Pause", "إيقاف مؤقت"],
  'st_resume': ["Continue", "Continuer", "تابع"],
  'st_slow': ["Slow", "Lent", "بطيء"],
  'st_normal': ["Normal", "Normal", "عادي"],
  'st_read_btn': ["I read it!", "Je l'ai lu !", "قرأتها!"],
  'st_read_done': ["Read!", "Lu !", "تمت القراءة!"],
  'st_tap_hint': [
    "Tap a sentence to hear it",
    "Touche une phrase pour l'écouter",
    "المس جملة لتسمعها",
  ],
  'st_no_voice': [
    "This voice is not installed on your phone.",
    "Cette voix n'est pas installée sur ton téléphone.",
    "هذا الصوت غير مثبّت على هاتفك.",
  ],
  'st_cheer0': ["Woohoo! 🎉", "Youhou ! 🎉", "هيييه! 🎉"],
  'st_cheer1': ["You're on fire! 🔥", "Tu es en feu ! 🔥", "أنت رائع! 🔥"],
  'st_cheer2': ["Great job! ⭐", "Bravo ! ⭐", "أحسنت! ⭐"],
  'st_cheer3': ["Story master! 🏆", "Maître des histoires ! 🏆", "بطل القصص! 🏆"],
  'st_cheer4': [
    "Yay, well read! 🥳",
    "Hourra, bien lu ! 🥳",
    "رائع، قراءة ممتازة! 🥳",
  ],

  // Themes
  'sth_animals': ["Animals", "Animaux", "حيوانات"],
  'sth_friendship': ["Friendship", "Amitié", "صداقة"],
  'sth_adventure': ["Adventure", "Aventure", "مغامرة"],
  'sth_learning': ["Learning", "Apprentissage", "تعلّم"],
  'sth_magic': ["Magic", "Magie", "سحر"],
  'sth_nature': ["Nature", "Nature", "طبيعة"],
  'sth_robots': ["Robots / Technology", "Robots / Technologie", "روبوتات وتكنولوجيا"],
  'sth_sleep': ["Sleep / Night", "Sommeil / Nuit", "النوم والليل"],
  'sth_emotions': ["Emotions", "Émotions", "مشاعر"],
};

String st(String key, [Map<String, String>? args]) {
  final row = _storyStrings[key];
  String s = row == null ? key : row[LabI18n.instance.lang.index];
  if (args != null) {
    args.forEach((k, v) {
      s = s.replaceAll('{$k}', v);
    });
  }
  return s;
}

/// Translated name of a story theme (falls back to the English name).
String storyThemeLabel(String theme) {
  const map = {
    'Animals': 'sth_animals',
    'Friendship': 'sth_friendship',
    'Adventure': 'sth_adventure',
    'Learning': 'sth_learning',
    'Magic': 'sth_magic',
    'Nature': 'sth_nature',
    'Robots / Technology': 'sth_robots',
    'Sleep / Night': 'sth_sleep',
    'Emotions': 'sth_emotions',
  };
  final key = map[theme];
  return key == null ? theme : st(key);
}
