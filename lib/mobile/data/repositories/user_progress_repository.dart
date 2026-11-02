import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_challenge_model.dart';
import '../models/user_progress_model.dart';

class UserProgressRepository {
  static const String _keyProfile = 'kinderkids_user_profile_v1';
  static const String _keyDailyChallenges = 'kinderkids_daily_challenges_v1';
  static const String _keyLastChallengeDate = 'kinderkids_last_challenge_date';

  /// Per-day usage counters so parents get real daily screen-time numbers.
  static String _usageKeyFor(DateTime day) =>
      'kinderkids_usage_${day.toIso8601String().substring(0, 10)}';
  static String _extraKeyFor(DateTime day) =>
      'kinderkids_extra_minutes_${day.toIso8601String().substring(0, 10)}';

  DateTime get _today => DateTime.now();

  Future<UserProgressModel> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyProfile);
    if (raw == null) {
      final initial = UserProgressModel.initial();
      await saveProfile(initial);
      return initial;
    }
    try {
      return UserProgressModel.decode(raw);
    } catch (_) {
      return UserProgressModel.initial();
    }
  }

  Future<void> saveProfile(UserProgressModel profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfile, profile.encode());
  }

  Future<List<DailyChallenge>> loadDailyChallenges() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = prefs.getString(_keyLastChallengeDate);

    // If it's a new day, reset the daily challenges
    if (lastDate != todayStr) {
      await prefs.setString(_keyLastChallengeDate, todayStr);
      await saveDailyChallenges(defaultDailyChallenges);
      return defaultDailyChallenges;
    }

    final raw = prefs.getString(_keyDailyChallenges);
    if (raw == null) {
      await saveDailyChallenges(defaultDailyChallenges);
      return defaultDailyChallenges;
    }

    try {
      final List list = jsonDecode(raw) as List;
      return list
          .map((e) => DailyChallenge.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return defaultDailyChallenges;
    }
  }

  Future<void> saveDailyChallenges(List<DailyChallenge> challenges) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(challenges.map((c) => c.toJson()).toList());
    await prefs.setString(_keyDailyChallenges, raw);
  }

  Future<void> addSavedArtwork(String path) async {
    final profile = await loadProfile();
    final updatedPaths = List<String>.from(profile.savedArtworkPaths)
      ..add(path);
    await saveProfile(profile.copyWith(savedArtworkPaths: updatedPaths));
  }

  Future<void> removeSavedArtwork(String path) async {
    final profile = await loadProfile();
    final updatedPaths = List<String>.from(profile.savedArtworkPaths)
      ..remove(path);
    await saveProfile(profile.copyWith(savedArtworkPaths: updatedPaths));
  }

  /// Minutes the child has actively used the app today.
  Future<int> loadUsageMinutesToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_usageKeyFor(_today)) ?? 0;
  }

  Future<void> addUsageMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_usageKeyFor(_today)) ?? 0;
    await prefs.setInt(_usageKeyFor(_today), current + minutes);
  }

  /// Parent-approved extra play minutes for today.
  Future<int> loadExtraMinutesToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_extraKeyFor(_today)) ?? 0;
  }

  Future<void> addExtraMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_extraKeyFor(_today)) ?? 0;
    await prefs.setInt(_extraKeyFor(_today), current + minutes);
  }
}
