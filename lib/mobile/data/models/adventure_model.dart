import 'package:flutter/material.dart';

class WorldLevel {
  final int levelNumber;
  final String title;
  final String description;
  final int requiredStars;
  final bool isUnlocked;
  final bool isCompleted;
  final int starsEarned; // 0..3

  const WorldLevel({
    required this.levelNumber,
    required this.title,
    required this.description,
    required this.requiredStars,
    this.isUnlocked = false,
    this.isCompleted = false,
    this.starsEarned = 0,
  });

  WorldLevel copyWith({
    bool? isUnlocked,
    bool? isCompleted,
    int? starsEarned,
  }) {
    return WorldLevel(
      levelNumber: levelNumber,
      title: title,
      description: description,
      requiredStars: requiredStars,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isCompleted: isCompleted ?? this.isCompleted,
      starsEarned: starsEarned ?? this.starsEarned,
    );
  }
}

class LearningWorld {
  final String id;
  final String name;
  final String emoji;
  final List<Color> gradientColors;
  final List<WorldLevel> levels;

  const LearningWorld({
    required this.id,
    required this.name,
    required this.emoji,
    required this.gradientColors,
    required this.levels,
  });

  int get totalStarsPossible => levels.length * 3;
  int get currentStars => levels.fold(0, (sum, l) => sum + l.starsEarned);
  double get progressRatio => levels.isEmpty
      ? 0
      : levels.where((l) => l.isCompleted).length / levels.length;
}

final List<LearningWorld> defaultLearningWorlds = [
  const LearningWorld(
    id: 'alphabet_world',
    name: 'Alphabet World',
    emoji: '🔤',
    gradientColors: [Color(0xFFFFC15E), Color(0xFFF2994A)],
    levels: [
      WorldLevel(
        levelNumber: 1,
        title: 'Trace A & B',
        description: 'Learn the first letters of the alphabet!',
        requiredStars: 0,
        isUnlocked: true,
        isCompleted: true,
        starsEarned: 3,
      ),
      WorldLevel(
        levelNumber: 2,
        title: 'Trace C & D',
        description: 'Discover Cat and Dog!',
        requiredStars: 2,
        isUnlocked: true,
        isCompleted: true,
        starsEarned: 2,
      ),
      WorldLevel(
        levelNumber: 3,
        title: 'Vowels Master',
        description: 'Trace A, E, I, O, U',
        requiredStars: 5,
        isUnlocked: true,
      ),
      WorldLevel(
        levelNumber: 4,
        title: 'Alphabet Challenge',
        description: 'Complete the whole alphabet sequence!',
        requiredStars: 10,
      ),
    ],
  ),
  const LearningWorld(
    id: 'number_kingdom',
    name: 'Number Kingdom',
    emoji: '🔢',
    gradientColors: [Color(0xFF7CC5FF), Color(0xFF0B6E9B)],
    levels: [
      WorldLevel(
        levelNumber: 1,
        title: 'Count 1 to 5',
        description: 'Trace digits 1, 2, 3, 4, 5',
        requiredStars: 0,
        isUnlocked: true,
        isCompleted: true,
        starsEarned: 3,
      ),
      WorldLevel(
        levelNumber: 2,
        title: 'Count 6 to 10',
        description: 'Trace digits 6, 7, 8, 9, 10',
        requiredStars: 3,
        isUnlocked: true,
      ),
      WorldLevel(
        levelNumber: 3,
        title: 'Addition Basics',
        description: 'Simple 1 + 1 counting exercises',
        requiredStars: 8,
      ),
    ],
  ),
  const LearningWorld(
    id: 'colors_shapes',
    name: 'Colors & Shapes',
    emoji: '🟢',
    gradientColors: [Color(0xFFFF9D6C), Color(0xFFF25C54)],
    levels: [
      WorldLevel(
        levelNumber: 1,
        title: 'Primary Colors',
        description: 'Identify Red, Blue & Yellow',
        requiredStars: 0,
        isUnlocked: true,
      ),
      WorldLevel(
        levelNumber: 2,
        title: 'Basic Shapes',
        description: 'Circle, Square & Triangle',
        requiredStars: 4,
      ),
    ],
  ),
  const LearningWorld(
    id: 'puzzle_island',
    name: 'Puzzle Island',
    emoji: '🧩',
    gradientColors: [Color(0xFF6EE7B7), Color(0xFF2FBF8F)],
    levels: [
      WorldLevel(
        levelNumber: 1,
        title: 'Animal Jigsaw 2x2',
        description: 'Assemble the lion puzzle',
        requiredStars: 0,
        isUnlocked: true,
      ),
      WorldLevel(
        levelNumber: 2,
        title: 'Ocean Jigsaw 3x3',
        description: 'Assemble the fish puzzle',
        requiredStars: 6,
      ),
    ],
  ),
  const LearningWorld(
    id: 'story_forest',
    name: 'Story Forest',
    emoji: '📖',
    gradientColors: [Color(0xFFB48CF2), Color(0xFF8B5CF6)],
    levels: [
      WorldLevel(
        levelNumber: 1,
        title: 'The Fox Dream',
        description: 'Read story 1',
        requiredStars: 0,
        isUnlocked: true,
      ),
      WorldLevel(
        levelNumber: 2,
        title: 'The New Bridge',
        description: 'Read story 2',
        requiredStars: 5,
      ),
    ],
  ),
];
