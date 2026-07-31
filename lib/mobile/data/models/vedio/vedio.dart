/// Simple model for an educational video. `file` is the filename inside
/// assets/videos/, e.g. 'alphabet.mp4'.
class VideoItem {
  final String id;
  final String title;
  final String subtitle;
  final String file;
  final String emoji;
  final List<int> colors; // gradient, ARGB ints

  const VideoItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.file,
    required this.emoji,
    required this.colors,
  });
}

/// Videos matching the files found in assets/videos/.
final List<VideoItem> videoItems = [
  const VideoItem(
    id: 'alphabet',
    title: 'The Alphabet',
    subtitle: 'Learn your ABCs',
    file: 'alphabet.mp4',
    emoji: '🔤',
    colors: [0xFFFFC15E, 0xFFF2994A],
  ),
  const VideoItem(
    id: 'animal',
    title: 'Amazing Animals',
    subtitle: 'Meet creatures big and small',
    file: 'animal.mp4',
    emoji: '🦁',
    colors: [0xFFFF9D6C, 0xFFF25C54],
  ),
  const VideoItem(
    id: 'fruits',
    title: 'Yummy Fruits',
    subtitle: 'Discover fruits from A to Z',
    file: 'fruits.mp4',
    emoji: '🍎',
    colors: [0xFFFF9EC4, 0xFFE0507B],
  ),
  const VideoItem(
    id: 'matth',
    title: 'Fun with Math',
    subtitle: 'Counting made easy',
    file: 'matth.mp4',
    emoji: '➕',
    colors: [0xFFB48CF2, 0xFF8B5CF6],
  ),
  const VideoItem(
    id: 'numbers',
    title: 'Numbers 1-10',
    subtitle: 'Count along with us',
    file: 'numbers.mp4',
    emoji: '🔢',
    colors: [0xFF7CC5FF, 0xFF3AAAE0],
  ),
  const VideoItem(
    id: 'vegetables',
    title: 'Healthy Veggies',
    subtitle: 'Explore the veggie patch',
    file: 'vegetables.mp4',
    emoji: '🥦',
    colors: [0xFF6EE7B7, 0xFF2FBF8F],
  ),
];