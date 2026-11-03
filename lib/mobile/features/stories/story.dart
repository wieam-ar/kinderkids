/// Data model for a story, in 3 languages (English / Français / العربية).
/// Mirrors the JSON structure:
/// { "id": ..., "theme": ..., "title": ..., "text": ... }
/// plus optional "title_fr", "text_fr", "title_ar", "text_ar".
class Story {
  final int id;
  final String theme; // English key, also used for colors / icons
  final String title;
  final String text;
  final String titleFr;
  final String textFr;
  final String titleAr;
  final String textAr;

  const Story({
    required this.id,
    required this.theme,
    required this.title,
    required this.text,
    this.titleFr = '',
    this.textFr = '',
    this.titleAr = '',
    this.textAr = '',
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as int,
      theme: json['theme'] as String,
      title: json['title'] as String,
      text: json['text'] as String,
      titleFr: (json['title_fr'] as String?) ?? '',
      textFr: (json['text_fr'] as String?) ?? '',
      titleAr: (json['title_ar'] as String?) ?? '',
      textAr: (json['text_ar'] as String?) ?? '',
    );
  }

  /// [lang] is 'en', 'fr' or 'ar' (LabI18n.instance.lang.name).
  /// Falls back to English if a translation is missing.
  String titleFor(String lang) {
    if (lang == 'fr' && titleFr.isNotEmpty) return titleFr;
    if (lang == 'ar' && titleAr.isNotEmpty) return titleAr;
    return title;
  }

  String textFor(String lang) {
    if (lang == 'fr' && textFr.isNotEmpty) return textFr;
    if (lang == 'ar' && textAr.isNotEmpty) return textAr;
    return text;
  }
}

/// Splits a story text into paragraphs, and each paragraph into sentences
/// (used by the "read to me" feature to highlight the sentence being read).
List<List<String>> storyParagraphs(String text) {
  return text
      .split('\n\n')
      .map(_splitSentences)
      .where((p) => p.isNotEmpty)
      .toList();
}

List<String> _splitSentences(String p) {
  const enders = '.!?\u2026\u061F';
  const closers = '\u00BB\u201D"';
  final out = <String>[];
  var start = 0;
  var i = 0;
  while (i < p.length) {
    if (!enders.contains(p[i])) {
      i++;
      continue;
    }
    var j = i + 1;
    while (j < p.length && enders.contains(p[j])) {
      j++;
    }
    var k = j;
    // closing quote, possibly after one space (French:  ... gentillesse. \u00BB)
    if (k + 1 < p.length && p[k] == ' ' && closers.contains(p[k + 1])) k++;
    if (k < p.length && closers.contains(p[k])) k++;
    if (k >= p.length || p[k] == ' ') {
      final s = p.substring(start, k).trim();
      if (s.isNotEmpty) out.add(s);
      start = k;
    }
    i = k > i ? k : i + 1;
  }
  final rest = p.substring(start).trim();
  if (rest.isNotEmpty) out.add(rest);
  return out;
}

/// Age range this story pack targets (kept for reference / future filtering).
const String storiesAgeRange = '6-8';

/// All stories, embedded directly so no JSON asset loading/parsing is
/// needed at runtime. If you later want to load this from
/// assets/stories.json instead, just decode it with json.decode and map
/// each item through Story.fromJson.
final List<Story> stories = [
  const Story(
    id: 1,
    theme: 'Animals',
    title: 'The Fox and the Sky Dream',
    text:
    'Riki was a young fox who spent his mornings watching the birds glide through the sky. He secretly dreamed of doing the same. The forest animals often reminded him, gently laughing, that foxes stayed on the ground.\n\n'
        'One day, he met an old owl perched on a twisted branch. She told him that flying wasn\u2019t always a matter of wings, but of ideas and courage. With a frog who knew the winds, a quick squirrel, and a clever crow, Riki imagined a hot-air balloon made of braided leaves and a stitched-together balloon.\n\n'
        'When it took off, all the animals held their breath. Riki rose slowly into the air. He then understood that flying meant following his dream and accepting the help of others to make it real.',
    titleFr: "Le renard et le rêve du ciel",
    textFr:
    "Riki était un jeune renard qui passait ses matins à regarder les oiseaux planer dans le ciel. Il rêvait en secret de faire pareil. Les animaux de la forêt lui rappelaient souvent, en riant gentiment, que les renards restent sur le sol.\n\n"
        "Un jour, il rencontra une vieille chouette perchée sur une branche tordue. Elle lui dit que voler n'était pas toujours une question d'ailes, mais d'idées et de courage. Avec une grenouille qui connaissait les vents, un écureuil rapide et un corbeau malin, Riki imagina une montgolfière faite de feuilles tressées et d'une enveloppe cousue.\n\n"
        "Quand elle décolla, tous les animaux retinrent leur souffle. Riki s'éleva lentement dans les airs. Il comprit alors que voler, c'était suivre son rêve et accepter l'aide des autres pour le rendre réel.",
    titleAr: "الثعلب وحلم السماء",
    textAr:
    "كان ريكي ثعلبًا صغيرًا يقضي صباحاته وهو يراقب الطيور تنساب في السماء. كان يحلم سرًّا أن يفعل مثلها. وكانت حيوانات الغابة تذكّره دائمًا، وهي تضحك بلطف، بأن الثعالب تبقى على الأرض.\n\n"
        "في يوم من الأيام، قابل بومة عجوزًا تقف على غصن ملتوٍ. قالت له إن الطيران ليس دائمًا مسألة أجنحة، بل أفكار وشجاعة. ومع ضفدع يعرف الرياح، وسنجاب سريع، وغراب ذكي، تخيّل ريكي منطادًا مصنوعًا من أوراق مضفورة وبالون مخيَّط.\n\n"
        "وحين انطلق المنطاد، حبست كل الحيوانات أنفاسها. ارتفع ريكي ببطء في الهواء. وعندها فهم أن الطيران يعني اتباع الحلم وقبول مساعدة الآخرين ليصبح حقيقة.",
  ),
  const Story(
    id: 2,
    theme: 'Friendship',
    title: 'The New Crossing',
    text:
    'Two children, Lina and Sam, lived on opposite sides of a small river. They sometimes saw each other, but had never really talked. After a rainy night, the old bridge that connected them was destroyed.\n\n'
        'The next day, they both found themselves stuck on their own side. After timidly talking, they decided to build their own crossing. Lina brought old planks, Sam found strong ropes, and together they imagined a simple but sturdy bridge.\n\n'
        'While working, they discovered they had many things in common. Their bridge became a symbol: sometimes building something together brings people closer than a thousand words.',
    titleFr: "La nouvelle traversée",
    textFr:
    "Deux enfants, Lina et Sam, vivaient de chaque côté d'une petite rivière. Il leur arrivait de se voir, mais ils ne s'étaient jamais vraiment parlé. Après une nuit de pluie, le vieux pont qui les reliait fut détruit.\n\n"
        "Le lendemain, ils se retrouvèrent tous les deux bloqués de leur côté. Après avoir parlé timidement, ils décidèrent de construire leur propre passage. Lina apporta de vieilles planches, Sam trouva de solides cordes, et ensemble ils imaginèrent un pont simple mais robuste.\n\n"
        "En travaillant, ils découvrirent qu'ils avaient beaucoup de choses en commun. Leur pont devint un symbole : parfois, construire quelque chose ensemble rapproche les gens plus que mille mots.",
    titleAr: "العبور الجديد",
    textAr:
    "كان طفلان، لينا وسام، يعيشان على ضفتين متقابلتين لنهر صغير. كانا يريان بعضهما أحيانًا، لكنهما لم يتحدثا قط حقًّا. وبعد ليلة ماطرة، انهار الجسر القديم الذي كان يربط بينهما.\n\n"
        "في اليوم التالي، وجد كلاهما نفسه عالقًا على ضفته. وبعد حديث خجول، قررا أن يبنيا معبرهما الخاص. أحضرت لينا ألواحًا قديمة، ووجد سام حبالًا قوية، وتخيّلا معًا جسرًا بسيطًا لكنه متين.\n\n"
        "وأثناء العمل، اكتشفا أن بينهما أشياء كثيرة مشتركة. وصار جسرهما رمزًا: فأحيانًا يقرّب بناء شيء ما معًا بين الناس أكثر من ألف كلمة.",
  ),
  const Story(
    id: 3,
    theme: 'Adventure',
    title: 'The Map of Light Shards',
    text:
    'One morning, Max found a wrinkled map under a floorboard in the attic. It showed a lost island. Curious, he packed a bag and decided to follow the mysterious clue.\n\n'
        'The island he discovered glowed softly, as if the sand held sunlight within it. Guided by the map, Max walked between glowing fireflies and rocks that vibrated with the wind. An old guardian gave him a strange hint: \u201cThe true treasure appears when you listen to what the wind does not say.\u201d\n\n'
        'By observing carefully, Max found a cave full of colorful lanterns. He understood that the treasure was the beauty of the journey and the memories you bring back.',
    titleFr: "La carte des éclats de lumière",
    textFr:
    "Un matin, Max trouva une carte froissée sous une latte du plancher du grenier. Elle montrait une île perdue. Curieux, il prépara un sac et décida de suivre l'indice mystérieux.\n\n"
        "L'île qu'il découvrit brillait doucement, comme si le sable cachait de la lumière du soleil. Guidé par la carte, Max marcha entre des lucioles scintillantes et des rochers qui vibraient au vent. Un vieux gardien lui donna un étrange indice : « Le vrai trésor apparaît quand tu écoutes ce que le vent ne dit pas. »\n\n"
        "En observant attentivement, Max trouva une grotte pleine de lanternes colorées. Il comprit que le trésor, c'était la beauté du voyage et les souvenirs qu'on en rapporte.",
    titleAr: "خريطة شظايا الضوء",
    textAr:
    "في صباح أحد الأيام، وجد ماكس خريطة مجعّدة تحت لوح خشبي في العلّيّة. كانت تُظهر جزيرة ضائعة. بدافع الفضول، حزم حقيبته وقرر أن يتبع الدليل الغامض.\n\n"
        "كانت الجزيرة التي اكتشفها تتوهّج بلطف، كأن الرمال تخبّئ في داخلها ضوء الشمس. وبهدي من الخريطة، مشى ماكس بين اليراعات المتلألئة وصخور تهتزّ مع الريح. وأعطاه حارس عجوز تلميحًا غريبًا: «يظهر الكنز الحقيقي حين تُصغي إلى ما لا تقوله الريح.»\n\n"
        "وبالملاحظة الدقيقة، عثر ماكس على كهف مليء بالفوانيس الملونة. وفهم أن الكنز هو جمال الرحلة والذكريات التي تعود بها.",
  ),
  const Story(
    id: 4,
    theme: 'Learning',
    title: 'The Rainbow-Heart Dragon',
    text:
    'A little dragon lived in a peaceful valley. His skin changed color depending on his emotions: yellow for joy, purple for fear\u2026 One morning, he woke up completely gray.\n\n'
        'Troubled, he met Maya, a girl who loved to listen. Together, they talked about what he was feeling. She helped him name each emotion and paint a big chart to organize them.\n\n'
        'Slowly, his colors returned: a warm orange for courage found again, a soft blue for soothed sadness, a bright green for calm. The dragon learned that understanding his emotions helped him grow.',
    titleFr: "Le dragon cœur-arc-en-ciel",
    textFr:
    "Un petit dragon vivait dans une vallée paisible. Sa peau changeait de couleur selon ses émotions : jaune pour la joie, violet pour la peur… Un matin, il se réveilla complètement gris.\n\n"
        "Troublé, il rencontra Maya, une fillette qui aimait écouter. Ensemble, ils parlèrent de ce qu'il ressentait. Elle l'aida à nommer chaque émotion et à peindre un grand tableau pour les ranger.\n\n"
        "Peu à peu, ses couleurs revinrent : un orange chaleureux pour le courage retrouvé, un bleu doux pour la tristesse apaisée, un vert éclatant pour le calme. Le dragon apprit que comprendre ses émotions l'aidait à grandir.",
    titleAr: "التنين ذو قلب قوس القزح",
    textAr:
    "عاش تنين صغير في وادٍ هادئ. كان لون جلده يتغيّر بحسب مشاعره: أصفر للفرح، وبنفسجي للخوف… وفي صباح أحد الأيام، استيقظ وقد صار رماديًّا تمامًا.\n\n"
        "وبعد أن اضطرب، قابل مايا، فتاة تحب الإصغاء. وتحدّثا معًا عمّا يشعر به. ساعدته على تسمية كل شعور، ورسمت معه لوحة كبيرة لتنظيمها.\n\n"
        "وببطء، عادت ألوانه: برتقالي دافئ للشجاعة التي وجدها من جديد، وأزرق ناعم للحزن الذي هدأ، وأخضر مشرق للسكينة. وتعلّم التنين أن فهم مشاعره يساعده على النمو.",
  ),
  const Story(
    id: 5,
    theme: 'Magic',
    title: 'The Little Silver Key',
    text:
    'While searching in an old drawer, Elina found a shining key. As soon as she touched it, a tiny door appeared on the wall. Opening it, she entered a fragrant garden.\n\n'
        'Each new door revealed a different world: a square where words turned into music, a library where books whispered, a workshop where toys danced briefly before becoming still again.\n\n'
        'Elina realized that the key worked only when she opened her heart and paid attention. She decided to use this magic to learn and help those she met.',
    titleFr: "La petite clé d'argent",
    textFr:
    "En fouillant dans un vieux tiroir, Elina trouva une clé brillante. Dès qu'elle la toucha, une minuscule porte apparut sur le mur. En l'ouvrant, elle entra dans un jardin parfumé.\n\n"
        "Chaque nouvelle porte révélait un monde différent : une place où les mots se transformaient en musique, une bibliothèque où les livres chuchotaient, un atelier où les jouets dansaient un instant avant de redevenir immobiles.\n\n"
        "Elina comprit que la clé ne fonctionnait que lorsqu'elle ouvrait son cœur et faisait attention. Elle décida d'utiliser cette magie pour apprendre et aider ceux qu'elle rencontrait.",
    titleAr: "المفتاح الفضي الصغير",
    textAr:
    "وبينما كانت إيلينا تبحث في درج قديم، وجدت مفتاحًا لامعًا. وما إن لمسته حتى ظهر باب صغير على الجدار. فتحته ودخلت حديقة عطرة.\n\n"
        "كان كل باب جديد يكشف عالَمًا مختلفًا: ساحة تتحول فيها الكلمات إلى موسيقى، ومكتبة تهمس فيها الكتب، وورشة ترقص فيها الألعاب لحظات قبل أن تسكن من جديد.\n\n"
        "أدركت إيلينا أن المفتاح لا يعمل إلا حين تفتح قلبها وتنتبه. وقررت أن تستخدم هذا السحر لتتعلم وتساعد من تقابلهم.",
  ),
  const Story(
    id: 6,
    theme: 'Nature',
    title: 'The Sleeping Guardian',
    text:
    'A strange melody drifted through the forest one morning. At the center of a clearing, a stone giant slowly awakened. The animals, frightened, hid.\n\n'
        'Noor, a curious little girl, approached gently and offered him a flower. Thanks to this simple gesture, the giant remembered his mission: to care for the trees, nourish the earth, and protect the forest\u2019s inhabitants.\n\n'
        'With help from the animals and Noor, he cleaned the clearing and planted young sprouts. From that day on, the forest echoed with his music again.',
    titleFr: "Le gardien endormi",
    textFr:
    "Une étrange mélodie flotta dans la forêt un matin. Au centre d'une clairière, un géant de pierre s'éveilla lentement. Les animaux, effrayés, se cachèrent.\n\n"
        "Noor, une petite fille curieuse, s'approcha doucement et lui offrit une fleur. Grâce à ce simple geste, le géant se souvint de sa mission : prendre soin des arbres, nourrir la terre et protéger les habitants de la forêt.\n\n"
        "Avec l'aide des animaux et de Noor, il nettoya la clairière et planta de jeunes pousses. Dès ce jour, la forêt résonna de nouveau de sa musique.",
    titleAr: "الحارس النائم",
    textAr:
    "تسلّل لحن غريب بين أشجار الغابة ذات صباح. وفي وسط مساحة مفتوحة، استيقظ عملاق من الحجر ببطء. فاختبأت الحيوانات خائفة.\n\n"
        "اقتربت نور، وهي طفلة فضولية، منه بهدوء وقدّمت له زهرة. وبفضل هذا التصرف البسيط، تذكّر العملاق مهمته: أن يعتني بالأشجار، ويغذّي الأرض، ويحمي سكان الغابة.\n\n"
        "وبمساعدة الحيوانات ونور، نظّف المكان وزرع براعم صغيرة. ومنذ ذلك اليوم، عادت الغابة تردّد صدى موسيقاه.",
  ),
  const Story(
    id: 7,
    theme: 'Robots / Technology',
    title: 'Robi and the Coded Chest',
    text:
    'Tom built a robot named Robi from spare parts he collected. Robi loved observing, learning, and asking questions. One morning, he found a metal box locked with a symbol-coded padlock.\n\n'
        'To open it, Robi had to solve several challenges: recognizing shapes, counting stars, and\u2014most importantly\u2014understanding what it means to be a friend. Tom helped him each time, and together they tested many ideas.\n\n'
        'Inside the chest, they discovered a set of tools to invent even more creations: a small notebook, a magnifying glass, and plans for new robots. Robi understood that technology is even more beautiful when it brings people together.',
    titleFr: "Robi et le coffre codé",
    textFr:
    "Tom construisit un robot nommé Robi avec des pièces de récupération. Robi aimait observer, apprendre et poser des questions. Un matin, il trouva une boîte en métal fermée par un cadenas à symboles.\n\n"
        "Pour l'ouvrir, Robi devait relever plusieurs défis : reconnaître des formes, compter des étoiles et, surtout, comprendre ce que veut dire être un ami. Tom l'aida à chaque fois, et ensemble ils essayèrent beaucoup d'idées.\n\n"
        "Dans le coffre, ils découvrirent des outils pour inventer encore plus de créations : un petit carnet, une loupe et des plans pour de nouveaux robots. Robi comprit que la technologie est encore plus belle quand elle rapproche les gens.",
    titleAr: "روبي والصندوق المشفّر",
    textAr:
    "صنع توم روبوتًا اسمه روبي من قطع احتياطية جمعها. كان روبي يحب الملاحظة والتعلّم وطرح الأسئلة. وفي صباح أحد الأيام، وجد صندوقًا معدنيًّا مغلقًا بقفل برموز.\n\n"
        "ولفتحه، كان على روبي أن يحلّ عدة تحدّيات: التعرّف على الأشكال، وعدّ النجوم، وفهم معنى أن تكون صديقًا، وهذا هو الأهم. وساعده توم في كل مرة، وجرّبا معًا أفكارًا كثيرة.\n\n"
        "وفي داخل الصندوق، اكتشفا أدوات لاختراع المزيد من الابتكارات: دفتر صغير، وعدسة مكبّرة، ومخططات لروبوتات جديدة. وفهم روبي أن التكنولوجيا تكون أجمل حين تقرّب بين الناس.",
  ),
  const Story(
    id: 8,
    theme: 'Sleep / Night',
    title: 'The Night that Cradled the Moon',
    text:
    'Every evening, Lila liked to greet the moon from her window. But one night, the moon seemed restless, spinning in the sky unable to settle.\n\n'
        'Lila went outside with her cat Mirou, brought an imaginary blanket, and hummed a lullaby. Curious neighbors lit small lamps and joined her.\n\n'
        'Soothed by these gentle gestures, the moon finally nestled calmly in the sky, as if in a bed of clouds. Lila fell asleep afterward, certain that a simple song can sometimes comfort a friend.',
    titleFr: "La nuit qui berça la lune",
    textFr:
    "Chaque soir, Lila aimait saluer la lune depuis sa fenêtre. Mais une nuit, la lune semblait agitée, tournant dans le ciel sans arriver à se poser.\n\n"
        "Lila sortit avec son chat Mirou, apporta une couverture imaginaire et fredonna une berceuse. Des voisins curieux allumèrent de petites lampes et se joignirent à elle.\n\n"
        "Apaisée par ces gestes tendres, la lune finit par se blottir tranquillement dans le ciel, comme dans un lit de nuages. Lila s'endormit ensuite, certaine qu'une simple chanson peut parfois consoler un ami.",
    titleAr: "الليلة التي هدهدت القمر",
    textAr:
    "في كل مساء، كانت ليلى تحب أن تحيّي القمر من نافذتها. لكن في إحدى الليالي بدا القمر قلقًا، يدور في السماء ولا يستطيع أن يستقر.\n\n"
        "خرجت ليلى مع قطتها ميرو، وأحضرت بطانية خيالية، ودندنت أنشودة النوم. وأشعل الجيران الفضوليون مصابيح صغيرة وانضمّوا إليها.\n\n"
        "وبعد أن هدأ القمر بهذه اللفتات الرقيقة، استقر أخيرًا في السماء بهدوء، كأنه في فراش من الغيوم. ونامت ليلى بعد ذلك، واثقة بأن أغنية بسيطة قد تواسي صديقًا أحيانًا.",
  ),
  const Story(
    id: 9,
    theme: 'Emotions',
    title: 'The Journey of the Curious Thought',
    text:
    'Inside No\u00e9\'s mind, some ideas sometimes came to life and went exploring. One morning, one of them decided to meet the emotions.\n\n'
        'It met Joy, light like a golden butterfly; Sadness, like soft rain; Anger, blazing; and Fear, blowing a cold wind. Each explained what it needed: to be shared, listened to, expressed, or reassured.\n\n'
        'The thought returned to No\u00e9 and whispered: \u201cWhen you listen to me, I help you choose kindly.\u201d From then on, No\u00e9 learned to talk about his feelings and understand himself better.',
    titleFr: "Le voyage de la pensée curieuse",
    textFr:
    "Dans l'esprit de Noé, certaines idées prenaient parfois vie et partaient explorer. Un matin, l'une d'elles décida d'aller à la rencontre des émotions.\n\n"
        "Elle rencontra la Joie, légère comme un papillon doré ; la Tristesse, comme une pluie douce ; la Colère, flamboyante ; et la Peur, qui soufflait un vent froid. Chacune expliqua ce dont elle avait besoin : être partagée, écoutée, exprimée ou rassurée.\n\n"
        "La pensée retourna auprès de Noé et lui murmura : « Quand tu m'écoutes, je t'aide à choisir avec gentillesse. » Dès lors, Noé apprit à parler de ses sentiments et à mieux se comprendre.",
    titleAr: "رحلة الفكرة الفضولية",
    textAr:
    "داخل عقل نوح، كانت بعض الأفكار تدبّ فيها الحياة أحيانًا وتخرج لتستكشف. وفي صباح أحد الأيام، قررت إحداها أن تلتقي بالمشاعر.\n\n"
        "التقت بالفرح، خفيفًا كفراشة ذهبية؛ وبالحزن، كمطر ناعم؛ وبالغضب، متّقدًا كاللهب؛ وبالخوف، ينفخ ريحًا باردة. وشرح كلٌّ منهم ما يحتاج إليه: أن يُشارَك، أو يُسمَع، أو يُعبَّر عنه، أو يُطمأَن.\n\n"
        "وعادت الفكرة إلى نوح وهمست له: «حين تصغي إليّ، أساعدك على الاختيار بلطف.» ومنذ ذلك الحين، تعلّم نوح أن يتحدث عن مشاعره وأن يفهم نفسه أفضل.",
  ),
];