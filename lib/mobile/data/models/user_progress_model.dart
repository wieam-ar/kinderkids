import 'dart:convert';

/// Data model representing the child's overall profile, stars, badges,
/// unlocked customization items, and screen time settings.
class UserProgressModel {
  final String nickname;
  final String avatarEmoji;
  final int totalStars;
  final List<String>
      earnedBadges; // e.g. 'first_step', 'math_hero', 'story_teller'
  final Map<String, int> worldStars; // worldId -> stars earned
  final Set<String> unlockedShopItemIds;
  final String equippedCostumeId;
  final String equippedThemeId;
  final List<String> savedArtworkPaths;
  final int screenTimeLimitMinutes; // 0 = unlimited
  final bool soundEffectsEnabled;
  final String selectedLanguage; // 'en', 'ar', 'fr'

  const UserProgressModel({
    required this.nickname,
    required this.avatarEmoji,
    required this.totalStars,
    required this.earnedBadges,
    required this.worldStars,
    required this.unlockedShopItemIds,
    required this.equippedCostumeId,
    required this.equippedThemeId,
    required this.savedArtworkPaths,
    required this.screenTimeLimitMinutes,
    required this.soundEffectsEnabled,
    required this.selectedLanguage,
  });

  factory UserProgressModel.initial() {
    return const UserProgressModel(
      nickname: 'Explorer',
      avatarEmoji: '🦁',
      totalStars: 25, // default starting bonus for fun
      earnedBadges: ['first_step', 'welcome_explorer'],
      worldStars: {
        'alphabet_world': 3,
        'number_kingdom': 2,
      },
      unlockedShopItemIds: {'avatar_lion', 'theme_safari'},
      equippedCostumeId: 'avatar_lion',
      equippedThemeId: 'theme_safari',
      savedArtworkPaths: [],
      screenTimeLimitMinutes: 45,
      soundEffectsEnabled: true,
      selectedLanguage: 'en',
    );
  }

  UserProgressModel copyWith({
    String? nickname,
    String? avatarEmoji,
    int? totalStars,
    List<String>? earnedBadges,
    Map<String, int>? worldStars,
    Set<String>? unlockedShopItemIds,
    String? equippedCostumeId,
    String? equippedThemeId,
    List<String>? savedArtworkPaths,
    int? screenTimeLimitMinutes,
    bool? soundEffectsEnabled,
    String? selectedLanguage,
  }) {
    return UserProgressModel(
      nickname: nickname ?? this.nickname,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      totalStars: totalStars ?? this.totalStars,
      earnedBadges: earnedBadges ?? this.earnedBadges,
      worldStars: worldStars ?? this.worldStars,
      unlockedShopItemIds: unlockedShopItemIds ?? this.unlockedShopItemIds,
      equippedCostumeId: equippedCostumeId ?? this.equippedCostumeId,
      equippedThemeId: equippedThemeId ?? this.equippedThemeId,
      savedArtworkPaths: savedArtworkPaths ?? this.savedArtworkPaths,
      screenTimeLimitMinutes:
          screenTimeLimitMinutes ?? this.screenTimeLimitMinutes,
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nickname': nickname,
      'avatarEmoji': avatarEmoji,
      'totalStars': totalStars,
      'earnedBadges': earnedBadges,
      'worldStars': worldStars,
      'unlockedShopItemIds': unlockedShopItemIds.toList(),
      'equippedCostumeId': equippedCostumeId,
      'equippedThemeId': equippedThemeId,
      'savedArtworkPaths': savedArtworkPaths,
      'screenTimeLimitMinutes': screenTimeLimitMinutes,
      'soundEffectsEnabled': soundEffectsEnabled,
      'selectedLanguage': selectedLanguage,
    };
  }

  factory UserProgressModel.fromJson(Map<String, dynamic> json) {
    return UserProgressModel(
      nickname: json['nickname'] as String? ?? 'Explorer',
      avatarEmoji: json['avatarEmoji'] as String? ?? '🦁',
      totalStars: json['totalStars'] as int? ?? 25,
      earnedBadges:
          List<String>.from(json['earnedBadges'] as List? ?? ['first_step']),
      worldStars: Map<String, int>.from(json['worldStars'] as Map? ?? {}),
      unlockedShopItemIds: Set<String>.from(
          json['unlockedShopItemIds'] as List? ?? ['avatar_lion']),
      equippedCostumeId: json['equippedCostumeId'] as String? ?? 'avatar_lion',
      equippedThemeId: json['equippedThemeId'] as String? ?? 'theme_safari',
      savedArtworkPaths:
          List<String>.from(json['savedArtworkPaths'] as List? ?? []),
      screenTimeLimitMinutes: json['screenTimeLimitMinutes'] as int? ?? 45,
      soundEffectsEnabled: json['soundEffectsEnabled'] as bool? ?? true,
      selectedLanguage: json['selectedLanguage'] as String? ?? 'en',
    );
  }

  String encode() => jsonEncode(toJson());

  factory UserProgressModel.decode(String raw) =>
      UserProgressModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
