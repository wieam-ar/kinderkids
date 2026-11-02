class QuizOption {
  final String text;
  final bool isCorrect;
  const QuizOption(this.text, this.isCorrect);
}

class ExploreTopic {
  final String id;
  final String titleEn;
  final String titleAr;
  final String titleFr;
  final String category; // 'animals', 'weather', 'transport', 'body', 'veggies'
  final String emoji;
  final String descEn;
  final String descAr;
  final String descFr;
  final String quizQuestionEn;
  final String quizQuestionAr;
  final String quizQuestionFr;
  final List<QuizOption> optionsEn;
  final List<QuizOption> optionsAr;
  final List<QuizOption> optionsFr;

  const ExploreTopic({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.titleFr,
    required this.category,
    required this.emoji,
    required this.descEn,
    required this.descAr,
    required this.descFr,
    required this.quizQuestionEn,
    required this.quizQuestionAr,
    required this.quizQuestionFr,
    required this.optionsEn,
    required this.optionsAr,
    required this.optionsFr,
  });

  String getTitle(String lang) {
    switch (lang) {
      case 'ar':
        return titleAr;
      case 'fr':
        return titleFr;
      default:
        return titleEn;
    }
  }

  String getDesc(String lang) {
    switch (lang) {
      case 'ar':
        return descAr;
      case 'fr':
        return descFr;
      default:
        return descEn;
    }
  }

  String getQuestion(String lang) {
    switch (lang) {
      case 'ar':
        return quizQuestionAr;
      case 'fr':
        return quizQuestionFr;
      default:
        return quizQuestionEn;
    }
  }

  List<QuizOption> getOptions(String lang) {
    switch (lang) {
      case 'ar':
        return optionsAr;
      case 'fr':
        return optionsFr;
      default:
        return optionsEn;
    }
  }
}

final List<ExploreTopic> exploreTopics = [
  const ExploreTopic(
    id: 'lion',
    titleEn: 'King Lion',
    titleAr: 'الأسد ملك الغابة',
    titleFr: 'Le Lion Majestueux',
    category: 'animals',
    emoji: '🦁',
    descEn:
        'Lions live in savannas and roar loudly so everyone knows they are strong!',
    descAr: 'يعيش الأسد في السافانا ويزأر بصوت عالٍ ليُعلم الجميع بقوته!',
    descFr:
        'Le lion vit dans la savane et rugit très fort pour montrer sa force !',
    quizQuestionEn: 'Where do lions live?',
    quizQuestionAr: 'أين يعيش الأسد؟',
    quizQuestionFr: 'Où vit le lion ?',
    optionsEn: [
      QuizOption('Savanna', true),
      QuizOption('Ocean', false),
      QuizOption('Igloo', false),
    ],
    optionsAr: [
      QuizOption('السافانا', true),
      QuizOption('المحيط', false),
      QuizOption('كوخ الجليد', false),
    ],
    optionsFr: [
      QuizOption('Dans la savane', true),
      QuizOption('Dans l\'océan', false),
      QuizOption('Dans un igloo', false),
    ],
  ),
  const ExploreTopic(
    id: 'rainbow',
    titleEn: 'Sunny Rainbow',
    titleAr: 'قوس قزح الجميل',
    titleFr: 'L\'Arc-en-ciel',
    category: 'weather',
    emoji: '🌈',
    descEn:
        'Rainbows appear when sunlight shines through drops of rain in the sky!',
    descAr: 'يظهر قوس قزح عندما تشرق الشمس بين قطرات المطر في السماء!',
    descFr:
        'L\'arc-en-ciel apparaît quand le soleil brille à travers la pluie !',
    quizQuestionEn: 'What creates a rainbow?',
    quizQuestionAr: 'ما الذي يصنع قوس قزح؟',
    quizQuestionFr: 'Qu\'est-ce qui crée un arc-en-ciel ?',
    optionsEn: [
      QuizOption('Sunlight & Rain', true),
      QuizOption('Night Wind', false),
      QuizOption('Snowballs', false),
    ],
    optionsAr: [
      QuizOption('الشمس والمطر', true),
      QuizOption('رياح الليل', false),
      QuizOption('كرات الثلج', false),
    ],
    optionsFr: [
      QuizOption('Soleil et pluie', true),
      QuizOption('Vent de nuit', false),
      QuizOption('Boules de neige', false),
    ],
  ),
  const ExploreTopic(
    id: 'rocket',
    titleEn: 'Space Rocket',
    titleAr: 'صاروخ الفضاء',
    titleFr: 'La Fusée Spatiale',
    category: 'transport',
    emoji: '🚀',
    descEn:
        'Rockets fly super fast up into space to explore distant planets and the moon!',
    descAr: 'تطير الصوارخ بسرعة فائقة نحو الفضاء لاستكشاف الكواكب والقمر!',
    descFr:
        'Les fusées volent très vite vers l\'espace pour explorer les planètes !',
    quizQuestionEn: 'Where do rockets travel to?',
    quizQuestionAr: 'إلى أين تسافر الصواريخ؟',
    quizQuestionFr: 'Où voyagent les fusées ?',
    optionsEn: [
      QuizOption('Outer Space', true),
      QuizOption('Undersea', false),
      QuizOption('Underground', false),
    ],
    optionsAr: [
      QuizOption('الفضاء الخارجي', true),
      QuizOption('تحت البحر', false),
      QuizOption('تحت الأرض', false),
    ],
    optionsFr: [
      QuizOption('L\'espace', true),
      QuizOption('Sous la mer', false),
      QuizOption('Sous terre', false),
    ],
  ),
  const ExploreTopic(
    id: 'heart',
    titleEn: 'Human Heart',
    titleAr: 'القلب العجيب',
    titleFr: 'Le Cœur',
    category: 'body',
    emoji: '🫀',
    descEn:
        'Your heart beats inside your chest like a little drum, pumping blood to all your body!',
    descAr: 'ينبض قلبك داخل صدرك مثل الطبل الصغير ليزود جسمك بالدورة الدموية!',
    descFr:
        'Ton cœur bat dans ta poitrine comme un petit tambour pour faire circuler le sang !',
    quizQuestionEn: 'What does the heart do?',
    quizQuestionAr: 'ماذا يفعل القلب؟',
    quizQuestionFr: 'Que fait le cœur ?',
    optionsEn: [
      QuizOption('Beats & Pumps Blood', true),
      QuizOption('Blinks Eyes', false),
      QuizOption('Grows Nails', false),
    ],
    optionsAr: [
      QuizOption('ينبض ويوصل الدم', true),
      QuizOption('يرمش بالعين', false),
      QuizOption('ينمي الأظافر', false),
    ],
    optionsFr: [
      QuizOption('Bat et fait circuler le sang', true),
      QuizOption('Fait cligner les yeux', false),
      QuizOption('Fait pousser les ongles', false),
    ],
  ),
  const ExploreTopic(
    id: 'broccoli',
    titleEn: 'Healthy Broccoli',
    titleAr: 'البروكلي الصحي',
    titleFr: 'Le Brocoli',
    category: 'veggies',
    emoji: '🥦',
    descEn:
        'Broccoli looks like tiny green trees and is packed with vitamins to make you strong!',
    descAr:
        'يشبه البروكلي أشجاراً خضراء صغيرة وهو مليء بالفيتامينات التي تجعلك قوياً!',
    descFr:
        'Le brocoli ressemble à de petits arbres verts et te donne plein de vitamines !',
    quizQuestionEn: 'Why is broccoli good for us?',
    quizQuestionAr: 'لماذا البروكلي مفيد لنا؟',
    quizQuestionFr: 'Pourquoi le brocoli est bon pour nous ?',
    optionsEn: [
      QuizOption('Packed with Vitamins', true),
      QuizOption('Makes us sleep', false),
      QuizOption('Tastes like candy', false),
    ],
    optionsAr: [
      QuizOption('مليء بالفيتامينات', true),
      QuizOption('يجعلنا ننام', false),
      QuizOption('طعمه كالحلوى', false),
    ],
    optionsFr: [
      QuizOption('Plein de vitamines', true),
      QuizOption('Fait dormir', false),
      QuizOption('Goût de bonbon', false),
    ],
  ),
];
