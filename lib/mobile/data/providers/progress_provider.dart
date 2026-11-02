import 'package:flutter/foundation.dart';

import '../models/adventure_model.dart';
import '../models/daily_challenge_model.dart';
import '../models/reward_item_model.dart';
import '../models/user_progress_model.dart';
import '../repositories/user_progress_repository.dart';

class ProgressProvider extends ChangeNotifier {
  final UserProgressRepository _repo = UserProgressRepository();

  UserProgressModel _profile = UserProgressModel.initial();
  List<DailyChallenge> _dailyChallenges = [];
  List<LearningWorld> _worlds = defaultLearningWorlds;
  List<RewardItem> _shopItems = defaultShopItems;
  bool _isLoading = true;

  // Daily screen-time tracking (persisted per day in the repository).
  int _usageMinutesToday = 0;
  int _extraMinutesToday = 0;

  UserProgressModel get profile => _profile;
  List<DailyChallenge> get dailyChallenges => _dailyChallenges;
  List<LearningWorld> get worlds => _worlds;
  List<RewardItem> get shopItems => _shopItems;
  bool get isLoading => _isLoading;
  int get usageMinutesToday => _usageMinutesToday;
  int get extraMinutesToday => _extraMinutesToday;

  /// True when the parent-set daily limit is positive and fully used.
  bool get isScreenTimeExceeded {
    final limit = _profile.screenTimeLimitMinutes;
    if (limit <= 0) return false;
    return _usageMinutesToday >= limit + _extraMinutesToday;
  }

  /// Minutes left today (null when the parent set no limit).
  int? get screenTimeMinutesRemaining {
    final limit = _profile.screenTimeLimitMinutes;
    if (limit <= 0) return null;
    final remaining = limit + _extraMinutesToday - _usageMinutesToday;
    return remaining < 0 ? 0 : remaining;
  }

  ProgressProvider() {
    _init();
  }

  Future<void> _init() async {
    _profile = await _repo.loadProfile();
    _dailyChallenges = await _repo.loadDailyChallenges();
    _usageMinutesToday = await _repo.loadUsageMinutesToday();
    _extraMinutesToday = await _repo.loadExtraMinutesToday();
    _syncShopWithProfile();
    _syncWorldsWithProfile();
    _isLoading = false;
    notifyListeners();
  }

  /// Called once per minute the child actively uses the app.
  Future<void> addUsageMinute() async {
    _usageMinutesToday += 1;
    await _repo.addUsageMinutes(1);
    notifyListeners();
  }

  /// Parent-approved extra play time for today.
  Future<void> grantExtraMinutes(int minutes) async {
    _extraMinutesToday += minutes;
    await _repo.addExtraMinutes(minutes);
    notifyListeners();
  }

  void _syncShopWithProfile() {
    _shopItems = defaultShopItems.map((item) {
      final isUnlocked = _profile.unlockedShopItemIds.contains(item.id);
      final isEquipped = (_profile.equippedCostumeId == item.id) ||
          (_profile.equippedThemeId == item.id);
      return item.copyWith(isUnlocked: isUnlocked, isEquipped: isEquipped);
    }).toList();
  }

  void _syncWorldsWithProfile() {
    _worlds = defaultLearningWorlds.map((world) {
      final updatedLevels = world.levels.map((level) {
        final key = '${world.id}_lvl_${level.levelNumber}';
        final earned = _profile.worldStars[key] ?? 0;
        final completed = earned > 0;
        final unlocked = level.levelNumber == 1 ||
            _profile.totalStars >= level.requiredStars;
        return level.copyWith(
          isUnlocked: unlocked,
          isCompleted: completed,
          starsEarned: earned,
        );
      }).toList();

      return LearningWorld(
        id: world.id,
        name: world.name,
        emoji: world.emoji,
        gradientColors: world.gradientColors,
        levels: updatedLevels,
      );
    }).toList();
  }

  Future<void> addStars(int count) async {
    final newStars = _profile.totalStars + count;
    _profile = _profile.copyWith(totalStars: newStars);
    await _repo.saveProfile(_profile);
    _syncWorldsWithProfile();
    notifyListeners();
  }

  Future<void> updateNickname(String newName) async {
    _profile = _profile.copyWith(nickname: newName);
    await _repo.saveProfile(_profile);
    notifyListeners();
  }

  Future<void> completeLevel(String worldId, int levelNum, int stars) async {
    final key = '${worldId}_lvl_$levelNum';
    final previousStars = _profile.worldStars[key] ?? 0;
    if (stars > previousStars) {
      final diff = stars - previousStars;
      final updatedWorldStars = Map<String, int>.from(_profile.worldStars);
      updatedWorldStars[key] = stars;
      _profile = _profile.copyWith(
        worldStars: updatedWorldStars,
        totalStars: _profile.totalStars + diff,
      );
      await _repo.saveProfile(_profile);
      _syncWorldsWithProfile();
      notifyListeners();
    }
  }

  Future<void> incrementChallengeProgress(String category,
      [int amount = 1]) async {
    bool changed = false;
    _dailyChallenges = _dailyChallenges.map((c) {
      if (c.category == category && !c.isCompleted) {
        changed = true;
        return c.copyWith(currentCount: c.currentCount + amount);
      }
      return c;
    }).toList();

    if (changed) {
      await _repo.saveDailyChallenges(_dailyChallenges);
      notifyListeners();
    }
  }

  Future<void> claimChallengeReward(String challengeId) async {
    final challenge = _dailyChallenges.firstWhere((c) => c.id == challengeId);
    if (challenge.isCompleted && !challenge.rewardClaimed) {
      _dailyChallenges = _dailyChallenges.map((c) {
        if (c.id == challengeId) return c.copyWith(rewardClaimed: true);
        return c;
      }).toList();

      await _repo.saveDailyChallenges(_dailyChallenges);
      await addStars(challenge.starReward);
    }
  }

  Future<bool> buyAndEquipShopItem(RewardItem item) async {
    if (_profile.unlockedShopItemIds.contains(item.id)) {
      // Already unlocked, just equip
      _equipItem(item);
      return true;
    }

    if (_profile.totalStars >= item.starPrice) {
      final newStars = _profile.totalStars - item.starPrice;
      final updatedUnlocked = Set<String>.from(_profile.unlockedShopItemIds)
        ..add(item.id);
      _profile = _profile.copyWith(
        totalStars: newStars,
        unlockedShopItemIds: updatedUnlocked,
      );

      _equipItem(item);
      await _repo.saveProfile(_profile);
      notifyListeners();
      return true;
    }
    return false;
  }

  void _equipItem(RewardItem item) {
    if (item.category == 'avatar' || item.category == 'costume') {
      _profile = _profile.copyWith(
        equippedCostumeId: item.id,
        avatarEmoji: item.emoji,
      );
    } else if (item.category == 'theme') {
      _profile = _profile.copyWith(equippedThemeId: item.id);
    }
    _syncShopWithProfile();
    _repo.saveProfile(_profile);
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _profile = _profile.copyWith(selectedLanguage: lang);
    await _repo.saveProfile(_profile);
    notifyListeners();
  }

  Future<void> updateScreenTimeLimit(int minutes) async {
    _profile = _profile.copyWith(screenTimeLimitMinutes: minutes);
    await _repo.saveProfile(_profile);
    notifyListeners();
  }

  Future<void> toggleSoundEffects(bool enabled) async {
    _profile = _profile.copyWith(soundEffectsEnabled: enabled);
    await _repo.saveProfile(_profile);
    notifyListeners();
  }

  Future<void> addArtwork(String path) async {
    await _repo.addSavedArtwork(path);
    _profile = await _repo.loadProfile();
    await incrementChallengeProgress('draw');
    notifyListeners();
  }

  Future<void> removeArtwork(String path) async {
    await _repo.removeSavedArtwork(path);
    _profile = await _repo.loadProfile();
    notifyListeners();
  }

  Future<void> resetAllProgress() async {
    _profile = UserProgressModel.initial();
    _dailyChallenges = defaultDailyChallenges;
    await _repo.saveProfile(_profile);
    await _repo.saveDailyChallenges(_dailyChallenges);
    _syncShopWithProfile();
    _syncWorldsWithProfile();
    notifyListeners();
  }
}
