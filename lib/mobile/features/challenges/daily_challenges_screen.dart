import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_ui.dart';
import '../../data/models/daily_challenge_model.dart';
import '../../data/providers/progress_provider.dart';

class DailyChallengesScreen extends StatelessWidget {
  const DailyChallengesScreen({super.key});

  /// Ready-to-claim first, then in progress, then already claimed.
  static int _rank(DailyChallenge c) {
    if (c.isCompleted && !c.rewardClaimed) return 0;
    if (!c.isCompleted) return 1;
    return 2;
  }

  Future<void> _claim(
      BuildContext context,
      ProgressProvider progress,
      DailyChallenge challenge,
      ) async {
    final messenger = ScaffoldMessenger.of(context);
    await progress.claimChallengeReward(challenge.id);
    showAppSnack(
      messenger,
      '🎉 +${challenge.starReward} stars claimed!',
      color: AppColors.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final challenges = progress.dailyChallenges;

    final sorted = List<DailyChallenge>.of(challenges)
      ..sort((a, b) => _rank(a).compareTo(_rank(b)));
    final completed = challenges.where((c) => c.isCompleted).length;
    final claimable =
        challenges.where((c) => c.isCompleted && !c.rewardClaimed).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildAppBar(
        'Daily Challenges 🎯',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: StarsChip(stars: progress.profile.totalStars)),
          ),
        ],
      ),
      body: challenges.isEmpty
          ? const EmptyState(
        emoji: '🎯',
        title: 'No challenges today',
        message: 'Come back tomorrow for new challenges!',
      )
          : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SummaryCard(
            completed: completed,
            total: challenges.length,
            claimable: claimable,
          ),
          const SizedBox(height: 20),
          for (final c in sorted)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ChallengeCard(
                challenge: c,
                onClaim: () => _claim(context, progress, c),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int completed;
  final int total;
  final int claimable;

  const _SummaryCard({
    required this.completed,
    required this.total,
    required this.claimable,
  });

  @override
  Widget build(BuildContext context) {
    final allDone = total > 0 && completed == total;

    return GradientCard(
      colors: allDone
          ? const [Color(0xFF6EE7B7), Color(0xFF2FBF8F)]
          : const [Color(0xFF6FD3F7), AppColors.primary],
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Text(allDone ? '🏆' : '🎯', style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allDone
                      ? 'All challenges done!'
                      : '$completed of $total completed',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  claimable > 0
                      ? '🎁 $claimable reward${claimable == 1 ? '' : 's'} '
                      'waiting for you!'
                      : 'Finish exercises to earn bonus stars.',
                  style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final DailyChallenge challenge;
  final VoidCallback onClaim;

  const _ChallengeCard({required this.challenge, required this.onClaim});

  @override
  Widget build(BuildContext context) {
    final readyToClaim = challenge.isCompleted && !challenge.rewardClaimed;
    final ratio = challenge.progress.clamp(0.0, 1.0).toDouble();

    return SoftCard(
      borderColor: readyToClaim ? AppColors.star : null,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.tint,
            ),
            child: Text(
              challenge.iconEmoji,
              style: const TextStyle(fontSize: 26),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  challenge.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: ratio),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (_, value, __) => LinearProgressIndicator(
                      value: value,
                      minHeight: 7,
                      backgroundColor: AppColors.border,
                      color: challenge.isCompleted
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (challenge.rewardClaimed)
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 30,
            )
          else if (readyToClaim)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.star,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onPressed: onClaim,
              child: Text(
                'Claim ⭐${challenge.starReward}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            )
          else
            Text(
              '${challenge.currentCount}/${challenge.targetCount}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}