class ScienceExperiment {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final String category;
  final String description;
  final List<String> steps;
  final String interactiveType; // 'sink_float', 'color_mix', 'day_night'
  final String quizQuestion;
  final List<String> quizOptions;
  final int correctIndex;

  const ScienceExperiment({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.category,
    required this.description,
    required this.steps,
    required this.interactiveType,
    required this.quizQuestion,
    required this.quizOptions,
    required this.correctIndex,
  });
}

final List<ScienceExperiment> scienceExperiments = [
  const ScienceExperiment(
    id: 'exp_sink_float',
    title: 'Sink or Float?',
    subtitle: 'Discover density with water',
    emoji: '⚓',
    category: 'physics',
    description:
        'Heavy dense objects sink down to the bottom, while light airy objects float on top of water!',
    steps: [
      'Fill a clear bowl with clean water.',
      'Pick an apple, a rock, a key, and a rubber duck.',
      'Guess which ones will float and test them!'
    ],
    interactiveType: 'sink_float',
    quizQuestion: 'Which object will FLOAT on top of water?',
    quizOptions: ['Heavy Rock', 'Rubber Duck 🦆', 'Metal Coin'],
    correctIndex: 1,
  ),
  const ScienceExperiment(
    id: 'exp_color_mix',
    title: 'Color Mixing Magic',
    subtitle: 'Combine primary colors',
    emoji: '🎨',
    category: 'chemistry',
    description:
        'Red, Yellow and Blue are primary colors. Mixing them creates magic new secondary colors!',
    steps: [
      'Mix Red and Yellow to get Orange!',
      'Mix Blue and Yellow to get Green!',
      'Mix Red and Blue to get Purple!'
    ],
    interactiveType: 'color_mix',
    quizQuestion: 'What color do you get when you mix RED + BLUE?',
    quizOptions: ['Green', 'Purple 💜', 'Yellow'],
    correctIndex: 1,
  ),
  const ScienceExperiment(
    id: 'exp_day_night',
    title: 'Day & Night Cycle',
    subtitle: 'Earth spinning around the Sun',
    emoji: '☀️',
    category: 'astronomy',
    description:
        'Our Earth spins around every 24 hours. The side facing the Sun gets Day, and the dark side gets Night!',
    steps: [
      'The Sun lights up one side of the Earth.',
      'As Earth turns away, the sky turns dark and stars appear!',
      'Good morning Sun, goodnight Moon!'
    ],
    interactiveType: 'day_night',
    quizQuestion: 'Why does night happen?',
    quizOptions: [
      'Earth turns away from Sun 🌙',
      'The Sun goes to sleep',
      'Clouds cover everything'
    ],
    correctIndex: 0,
  ),
];
