/// Simple data model for a story, mirroring the provided JSON structure:
/// { "id": ..., "theme": ..., "title": ..., "text": ... }
class Story {
  final int id;
  final String theme;
  final String title;
  final String text;

  const Story({
    required this.id,
    required this.theme,
    required this.title,
    required this.text,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as int,
      theme: json['theme'] as String,
      title: json['title'] as String,
      text: json['text'] as String,
    );
  }
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
  ),
  const Story(
    id: 2,
    theme: 'Friendship',
    title: 'The New Crossing',
    text:
    'Two children, Lina and Sam, lived on opposite sides of a small river. They sometimes saw each other, but had never really talked. After a rainy night, the old bridge that connected them was destroyed.\n\n'
        'The next day, they both found themselves stuck on their own side. After timidly talking, they decided to build their own crossing. Lina brought old planks, Sam found strong ropes, and together they imagined a simple but sturdy bridge.\n\n'
        'While working, they discovered they had many things in common. Their bridge became a symbol: sometimes building something together brings people closer than a thousand words.',
  ),
  const Story(
    id: 3,
    theme: 'Adventure',
    title: 'The Map of Light Shards',
    text:
    'One morning, Max found a wrinkled map under a floorboard in the attic. It showed a lost island. Curious, he packed a bag and decided to follow the mysterious clue.\n\n'
        'The island he discovered glowed softly, as if the sand held sunlight within it. Guided by the map, Max walked between glowing fireflies and rocks that vibrated with the wind. An old guardian gave him a strange hint: \u201cThe true treasure appears when you listen to what the wind does not say.\u201d\n\n'
        'By observing carefully, Max found a cave full of colorful lanterns. He understood that the treasure was the beauty of the journey and the memories you bring back.',
  ),
  const Story(
    id: 4,
    theme: 'Learning',
    title: 'The Rainbow-Heart Dragon',
    text:
    'A little dragon lived in a peaceful valley. His skin changed color depending on his emotions: yellow for joy, purple for fear\u2026 One morning, he woke up completely gray.\n\n'
        'Troubled, he met Maya, a girl who loved to listen. Together, they talked about what he was feeling. She helped him name each emotion and paint a big chart to organize them.\n\n'
        'Slowly, his colors returned: a warm orange for courage found again, a soft blue for soothed sadness, a bright green for calm. The dragon learned that understanding his emotions helped him grow.',
  ),
  const Story(
    id: 5,
    theme: 'Magic',
    title: 'The Little Silver Key',
    text:
    'While searching in an old drawer, Elina found a shining key. As soon as she touched it, a tiny door appeared on the wall. Opening it, she entered a fragrant garden.\n\n'
        'Each new door revealed a different world: a square where words turned into music, a library where books whispered, a workshop where toys danced briefly before becoming still again.\n\n'
        'Elina realized that the key worked only when she opened her heart and paid attention. She decided to use this magic to learn and help those she met.',
  ),
  const Story(
    id: 6,
    theme: 'Nature',
    title: 'The Sleeping Guardian',
    text:
    'A strange melody drifted through the forest one morning. At the center of a clearing, a stone giant slowly awakened. The animals, frightened, hid.\n\n'
        'Noor, a curious little girl, approached gently and offered him a flower. Thanks to this simple gesture, the giant remembered his mission: to care for the trees, nourish the earth, and protect the forest\u2019s inhabitants.\n\n'
        'With help from the animals and Noor, he cleaned the clearing and planted young sprouts. From that day on, the forest echoed with his music again.',
  ),
  const Story(
    id: 7,
    theme: 'Robots / Technology',
    title: 'Robi and the Coded Chest',
    text:
    'Tom built a robot named Robi from spare parts he collected. Robi loved observing, learning, and asking questions. One morning, he found a metal box locked with a symbol-coded padlock.\n\n'
        'To open it, Robi had to solve several challenges: recognizing shapes, counting stars, and\u2014most importantly\u2014understanding what it means to be a friend. Tom helped him each time, and together they tested many ideas.\n\n'
        'Inside the chest, they discovered a set of tools to invent even more creations: a small notebook, a magnifying glass, and plans for new robots. Robi understood that technology is even more beautiful when it brings people together.',
  ),
  const Story(
    id: 8,
    theme: 'Sleep / Night',
    title: 'The Night that Cradled the Moon',
    text:
    'Every evening, Lila liked to greet the moon from her window. But one night, the moon seemed restless, spinning in the sky unable to settle.\n\n'
        'Lila went outside with her cat Mirou, brought an imaginary blanket, and hummed a lullaby. Curious neighbors lit small lamps and joined her.\n\n'
        'Soothed by these gentle gestures, the moon finally nestled calmly in the sky, as if in a bed of clouds. Lila fell asleep afterward, certain that a simple song can sometimes comfort a friend.',
  ),
  const Story(
    id: 9,
    theme: 'Emotions',
    title: 'The Journey of the Curious Thought',
    text:
    'Inside No\u00e9\'s mind, some ideas sometimes came to life and went exploring. One morning, one of them decided to meet the emotions.\n\n'
        'It met Joy, light like a golden butterfly; Sadness, like soft rain; Anger, blazing; and Fear, blowing a cold wind. Each explained what it needed: to be shared, listened to, expressed, or reassured.\n\n'
        'The thought returned to No\u00e9 and whispered: \u201cWhen you listen to me, I help you choose kindly.\u201d From then on, No\u00e9 learned to talk about his feelings and understand himself better.',
  ),
];