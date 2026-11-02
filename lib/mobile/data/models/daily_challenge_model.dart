class DailyChallenge {
  final String id;
  final String title;
  final String subtitle;
  final String iconEmoji;
  final String category; // 'alphabet', 'math', 'puzzle', 'story', 'draw'
  final int targetCount;
  final int currentCount;
  final int starReward;
  final bool isCompleted;
  final bool rewardClaimed;

  const DailyChallenge({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconEmoji,
    required this.category,
    required this.targetCount,
    this.currentCount = 0,
    required this.starReward,
    this.isCompleted = false,
    this.rewardClaimed = false,
  });

  double get progress =>
      targetCount == 0 ? 1.0 : (currentCount / targetCount).clamp(0.0, 1.0);

  DailyChallenge copyWith({
    int? currentCount,
    bool? isCompleted,
    bool? rewardClaimed,
  }) {
    final updatedCount = currentCount ?? this.currentCount;
    final updatedCompleted = isCompleted ?? (updatedCount >= targetCount);
    return DailyChallenge(
      id: id,
      title: title,
      subtitle: subtitle,
      iconEmoji: iconEmoji,
      category: category,
      targetCount: targetCount,
      currentCount: updatedCount,
      starReward: starReward,
      isCompleted: updatedCompleted,
      rewardClaimed: rewardClaimed ?? this.rewardClaimed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'iconEmoji': iconEmoji,
        'category': category,
        'targetCount': targetCount,
        'currentCount': currentCount,
        'starReward': starReward,
        'isCompleted': isCompleted,
        'rewardClaimed': rewardClaimed,
      };

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      iconEmoji: json['iconEmoji'] as String,
      category: json['category'] as String,
      targetCount: json['targetCount'] as int,
      currentCount: json['currentCount'] as int? ?? 0,
      starReward: json['starReward'] as int,
      isCompleted: json['isCompleted'] as bool? ?? false,
      rewardClaimed: json['rewardClaimed'] as bool? ?? false,
    );
  }
}

final List<DailyChallenge> defaultDailyChallenges = [
  const DailyChallenge(
    id: 'dc_alphabet',
    title: 'Trace 3 Letters',
    subtitle: 'Practice your ABCs in Alphabet World',
    iconEmoji: 'ðŸ”¤',
    category: 'alphabet',
    targetCount: 3,
    starReward: 5,
  ),
  const DailyChallenge(
    id: 'dc_math',
    title: 'Solve 5 Math Questions',
    subtitle: 'Show off your smart counting skills',
    iconEmoji: 'âž•',
    category: 'math',
    targetCount: 5,
    starReward: 10,
  ),
  const DailyChallenge(
    id: 'dc_puzzle',
    title: 'Complete 1 Puzzle',
    subtitle: 'Piece together any theme puzzle',
    iconEmoji: 'ðŸ§©',
    category: 'puzzle',
    targetCount: 1,
    currentCount: 0,
    starReward: 8,
  ),
  const DailyChallenge(
    id: 'dc_story',
    title: 'Read 1 Story',
    subtitle: 'Enjoy a story in Reading Time',
    iconEmoji: 'ðŸ“–',
    category: 'story',
    targetCount: 1,
    currentCount: 0,
    starReward: 5,
  ),
  const DailyChallenge(
    id: 'dc_draw',
    title: 'Create 2 Drawings',
    subtitle: 'Save new artwork in Creative Studio',
    iconEmoji: '🎨',
    category: 'draw',
    targetCount: 2,
    currentCount: 0,
    starReward: 6,
  ),
  const DailyChallenge(
    id: 'dc_explore',
    title: 'Explore 3 Topics',
    subtitle: 'Answer quizzes in Explore the World',
    iconEmoji: '🌍',
    category: 'explore',
    targetCount: 3,
    currentCount: 0,
    starReward: 8,
  ),
  const DailyChallenge(
    id: 'dc_music',
    title: 'Listen to 2 Songs',
    subtitle: 'Play and sing along in Music Time',
    iconEmoji: '🎵',
    category: 'music',
    targetCount: 2,
    currentCount: 0,
    starReward: 5,
  ),
];
