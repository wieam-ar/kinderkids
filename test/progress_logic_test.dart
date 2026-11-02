import 'package:flutter_test/flutter_test.dart';
import 'package:kinderkids/mobile/data/models/daily_challenge_model.dart';
import 'package:kinderkids/mobile/data/models/reward_item_model.dart';
import 'package:kinderkids/mobile/data/models/user_progress_model.dart';
import 'package:kinderkids/mobile/data/providers/progress_provider.dart';
import 'package:kinderkids/mobile/data/repositories/user_progress_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserProgressModel', () {
    test('initial profile has expected defaults', () {
      final profile = UserProgressModel.initial();
      expect(profile.nickname, 'Explorer');
      expect(profile.totalStars, greaterThan(0));
      expect(profile.savedArtworkPaths, isEmpty);
    });

    test('encode/decode round trip preserves data', () {
      final profile = UserProgressModel(
        nickname: 'Lina',
        avatarEmoji: '🐼',
        totalStars: 42,
        earnedBadges: ['math_hero'],
        worldStars: {'alphabet_world': 5},
        unlockedShopItemIds: {'avatar_lion', 'hat_party'},
        equippedCostumeId: 'avatar_lion',
        equippedThemeId: 'theme_ocean',
        savedArtworkPaths: ['drawing_1', 'drawing_2'],
        screenTimeLimitMinutes: 30,
        soundEffectsEnabled: false,
        selectedLanguage: 'ar',
      );

      final decoded = UserProgressModel.decode(profile.encode());

      expect(decoded.nickname, 'Lina');
      expect(decoded.avatarEmoji, '🐼');
      expect(decoded.totalStars, 42);
      expect(decoded.worldStars['alphabet_world'], 5);
      expect(decoded.unlockedShopItemIds.contains('hat_party'), isTrue);
      expect(decoded.savedArtworkPaths.length, 2);
      expect(decoded.screenTimeLimitMinutes, 30);
      expect(decoded.soundEffectsEnabled, isFalse);
      expect(decoded.selectedLanguage, 'ar');
    });

    test('decoding corrupt JSON falls back gracefully', () {
      // The repository swallows decode errors and resets to defaults; the
      // model itself must throw so the repository catch can do its job.
      expect(
        () => UserProgressModel.decode('not-json{'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('UserProgressRepository', () {
    test('loadProfile creates and persists initial profile', () async {
      final repo = UserProgressRepository();
      final profile = await repo.loadProfile();

      expect(profile.nickname, 'Explorer');

      // Second load must come back identical (persisted now).
      final reloaded = await UserProgressRepository().loadProfile();
      expect(reloaded.totalStars, profile.totalStars);
      expect(reloaded.nickname, profile.nickname);
    });

    test('saveProfile persists changes', () async {
      final repo = UserProgressRepository();
      final profile = await repo.loadProfile();
      await repo.saveProfile(profile.copyWith(nickname: 'Zombie Hunter'));

      final reloaded = await UserProgressRepository().loadProfile();
      expect(reloaded.nickname, 'Zombie Hunter');
    });

    test('addSavedArtwork / removeSavedArtwork persist', () async {
      final repo = UserProgressRepository();

      await repo.addSavedArtwork('art.png');
      var profile = await UserProgressRepository().loadProfile();
      expect(profile.savedArtworkPaths, contains('art.png'));

      await repo.removeSavedArtwork('art.png');
      profile = await UserProgressRepository().loadProfile();
      expect(profile.savedArtworkPaths, isNot(contains('art.png')));
    });

    test('daily challenges start fresh and reset each new day', () async {
      final prefs = SharedPreferences.getInstance();

      // First load of a new day: fresh defaults.
      final first = await UserProgressRepository().loadDailyChallenges();
      expect(first.length, defaultDailyChallenges.length);

      // Simulate partial progress for the stored day.
      final progressed =
          first.map((c) => c.copyWith(currentCount: c.targetCount)).toList();
      await (await prefs).setString(
        'kinderkids_last_challenge_date',
        DateTime.now().toIso8601String().substring(0, 10),
      );
      await UserProgressRepository().saveDailyChallenges(progressed);

      final sameDay = await UserProgressRepository().loadDailyChallenges();
      expect(sameDay.first.isCompleted, isTrue);

      // Pretend the stored day is in the past → reset happens.
      await (await prefs)
          .setString('kinderkids_last_challenge_date', '2000-01-01');
      final nextDay = await UserProgressRepository().loadDailyChallenges();
      expect(nextDay.first.currentCount, 0);
      expect(nextDay.every((c) => !c.isCompleted), isTrue);
    });
  });

  group('ProgressProvider', () {
    Future<ProgressProvider> readyProvider() async {
      final provider = ProgressProvider();
      // _init() is async; let the repository futures complete.
      for (var i = 0; i < 20 && provider.isLoading; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      return provider;
    }

    test('addStars increases and persists total stars', () async {
      final provider = await readyProvider();
      final before = provider.profile.totalStars;

      await provider.addStars(7);
      expect(provider.profile.totalStars, before + 7);

      final persisted = await UserProgressRepository().loadProfile();
      expect(persisted.totalStars, before + 7);
    });

    test('incrementChallengeProgress completes a challenge at target',
        () async {
      final provider = await readyProvider();
      final math =
          provider.dailyChallenges.firstWhere((c) => c.category == 'math');
      final target = math.targetCount;

      for (var i = 0; i < target; i++) {
        await provider.incrementChallengeProgress('math');
      }

      final updated =
          provider.dailyChallenges.firstWhere((c) => c.category == 'math');
      expect(updated.isCompleted, isTrue);
      expect(updated.progress, 1.0);

      // Over-completion is not allowed beyond target: no growth after done.
      await provider.incrementChallengeProgress('math');
      final after =
          provider.dailyChallenges.firstWhere((c) => c.category == 'math');
      expect(after.currentCount, updated.currentCount);
    });

    test('claimChallengeReward pays stars exactly once', () async {
      final provider = await readyProvider();
      final challenge =
          provider.dailyChallenges.firstWhere((c) => c.category == 'math');
      final target = challenge.targetCount;

      for (var i = 0; i < target; i++) {
        await provider.incrementChallengeProgress('math');
      }
      final starsBefore = provider.profile.totalStars;

      await provider.claimChallengeReward(challenge.id);
      expect(provider.profile.totalStars, starsBefore + challenge.starReward);

      final claimed =
          provider.dailyChallenges.firstWhere((c) => c.category == 'math');
      expect(claimed.rewardClaimed, isTrue);

      // Claiming again must not pay twice.
      await provider.claimChallengeReward(challenge.id);
      expect(provider.profile.totalStars, starsBefore + challenge.starReward);
    });

    test('buyAndEquipShopItem fails when unaffordable', () async {
      final provider = await readyProvider();
      final tooExpensive = const RewardItem(
        id: 'test_dragon',
        title: 'Golden Dragon',
        subtitle: 'A legendary pet',
        emoji: '🐉',
        category: 'costume',
        starPrice: 999999,
      );

      final result = await provider.buyAndEquipShopItem(tooExpensive);
      expect(result, isFalse);
      expect(
        provider.profile.unlockedShopItemIds.contains('test_dragon'),
        isFalse,
      );
    });

    test('buyAndEquipShopItem deducts stars and equips', () async {
      final provider = await readyProvider();
      final starsBefore = provider.profile.totalStars;
      final affordable = const RewardItem(
        id: 'test_avatar_fox',
        title: 'Clever Fox',
        subtitle: 'Super smart explorer',
        emoji: '🦊',
        category: 'avatar',
        starPrice: 5,
      );

      final result = await provider.buyAndEquipShopItem(affordable);
      expect(result, isTrue);
      expect(provider.profile.totalStars, starsBefore - 5);
      expect(provider.profile.equippedCostumeId, 'test_avatar_fox');
      expect(provider.profile.avatarEmoji, '🦊');

      // Equipping an already-owned item never costs stars again.
      final starsNow = provider.profile.totalStars;
      final equipAgain = await provider.buyAndEquipShopItem(affordable);
      expect(equipAgain, isTrue);
      expect(provider.profile.totalStars, starsNow);
    });

    test('addArtwork persists paths and counts draw challenge', () async {
      final provider = await readyProvider();

      await provider.addArtwork('painting_1.png');

      expect(provider.profile.savedArtworkPaths, contains('painting_1.png'));
      final drawChallenge =
          provider.dailyChallenges.firstWhere((c) => c.category == 'draw');
      expect(drawChallenge.currentCount, 1);
    });

    test('screen-time usage tracking works', () async {
      final provider = await readyProvider();
      final limit = provider.profile.screenTimeLimitMinutes;

      // Not exceeded at start.
      expect(provider.isScreenTimeExceeded, isFalse);
      expect(provider.screenTimeMinutesRemaining, limit);

      // Track minutes up to the limit.
      for (var i = 0; i < limit; i++) {
        await provider.addUsageMinute();
      }
      expect(provider.usageMinutesToday, limit);
      expect(provider.isScreenTimeExceeded, isTrue);
      expect(provider.screenTimeMinutesRemaining, 0);

      // Parent grant reopens play time.
      await provider.grantExtraMinutes(15);
      expect(provider.isScreenTimeExceeded, isFalse);
      expect(provider.screenTimeMinutesRemaining, 15);

      // Usage is persisted across provider instances.
      final second = await readyProvider();
      expect(second.usageMinutesToday, limit);
      expect(second.extraMinutesToday, 15);
    });
  });
}
