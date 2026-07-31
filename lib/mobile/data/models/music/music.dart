/// Simple model for a kids song. `file` is the filename inside
/// assets/audios/, e.g. 'macdonald.mp3'.
class Song {
  final String id;
  final String title;
  final String subtitle;
  final String file;
  final String emoji;
  final List<int> colors; // ARGB ints, kept simple so this file has no
  // Flutter import and can be reused anywhere.

  const Song({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.file,
    required this.emoji,
    required this.colors,
  });
}

/// Songs matching the files found in assets/audios/.
final List<Song> songs = [
  const Song(
    id: 'macdonald',
    title: 'Old MacDonald Had a Farm',
    subtitle: 'Sing along with the animals',
    file: 'macdonald.mp3',
    emoji: '🐮',
    colors: [0xFF9CDB8C, 0xFF4CAF50],
  ),
  const Song(
    id: 'shark',
    title: 'Baby Shark',
    subtitle: 'Doo doo doo doo doo doo',
    file: 'shark.mp3',
    emoji: '🦈',
    colors: [0xFF7CC5FF, 0xFF3AAAE0],
  ),
  const Song(
    id: 'shoulders',
    title: 'Head, Shoulders, Knees & Toes',
    subtitle: 'A fun action song',
    file: 'shoulders.mp3',
    emoji: '🙆',
    colors: [0xFFFFC98B, 0xFFF2994A],
  ),
  const Song(
    id: 'twinkle',
    title: 'Twinkle Twinkle Little Star',
    subtitle: 'A gentle bedtime classic',
    file: 'twinkle.mp3',
    emoji: '⭐',
    colors: [0xFFB79CFF, 0xFF6C4CD9],
  ),
  const Song(
    id: 'wheels',
    title: 'The Wheels on the Bus',
    subtitle: 'Round and round we go',
    file: 'wheels.mp3',
    emoji: '🚌',
    colors: [0xFFFF9EC4, 0xFFE0507B],
  ),
];