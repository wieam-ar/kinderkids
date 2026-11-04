import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_ui.dart';
import '../../core/ui/kid_ui.dart';
import '../../data/models/daily_challenge_model.dart';
import '../../data/providers/progress_provider.dart';

TextStyle _fredoka({
  double size = 15,
  Color color = KidColors.textDark,
  FontWeight weight = FontWeight.w700,
}) =>
    GoogleFonts.fredoka(fontSize: size, fontWeight: weight, color: color);

const Color _starGold = Color(0xFFFFB300);
const Color _doneGreen = Color(0xFF35B24A);

/// Accent colours cycled across the challenge cards.
const List<Color> _accents = [
  Color(0xFF4FC3F7),
  Color(0xFFFFB74D),
  Color(0xFFBA68C8),
  Color(0xFFF06292),
  Color(0xFF81C784),
  Color(0xFFFFD54F),
];

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
      body: KidBackground(
        colors: const [Color(0xFFD6EEFB), KidColors.cream],
        child: SafeArea(
          child: Column(
            children: [
              const KidHeader(
                title: 'Daily Challenges',
                emoji: '🎯',
                subtitle: 'Finish them to earn bonus stars!',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _StarsPill(stars: progress.profile.totalStars),
                ),
              ),
              Expanded(
                child: challenges.isEmpty
                    ? const EmptyState(
                  emoji: '🎯',
                  title: 'No challenges today',
                  message: 'Come back tomorrow for new challenges!',
                )
                    : ListView(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                  children: [
                    _SummaryCard(
                      completed: completed,
                      total: challenges.length,
                      claimable: claimable,
                    ),
                    const SizedBox(height: 18),
                    for (var i = 0; i < sorted.length; i++)
                      _ChallengeCard(
                        challenge: sorted[i],
                        accent: _accents[i % _accents.length],
                        onClaim: () =>
                            _claim(context, progress, sorted[i]),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- stars pill

class _StarsPill extends StatelessWidget {
  final int stars;
  const _StarsPill({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _starGold, width: 3),
        boxShadow: [
          BoxShadow(
            color: _starGold.withOpacity(0.55),
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⭐', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Text('$stars',
              style: _fredoka(size: 18, weight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------- summary card

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
    const depth = 7.0;
    final allDone = total > 0 && completed == total;
    final colors = allDone
        ? const [Color(0xFF6EE7B7), Color(0xFF2FBF8F)]
        : const [Color(0xFF6FD3F7), Color(0xFF3AAAE0)];

    return Padding(
      padding: const EdgeInsets.only(bottom: depth),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withOpacity(0.55), width: 3),
          boxShadow: [
            BoxShadow(
              color: KidColors.darken(colors.last),
              offset: const Offset(0, depth),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.28),
                border:
                Border.all(color: Colors.white.withOpacity(0.7), width: 3),
              ),
              child: Text(allDone ? '🏆' : '🎯',
                  style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    allDone
                        ? 'All challenges done!'
                        : '$completed of $total completed',
                    style: _fredoka(
                        size: 19, color: Colors.white, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    claimable > 0
                        ? '🎁 $claimable reward${claimable == 1 ? '' : 's'} '
                        'waiting for you!'
                        : 'Finish exercises to earn bonus stars.',
                    style: _fredoka(
                        size: 13,
                        color: Colors.white.withOpacity(0.92),
                        weight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------- challenge card

class _ChallengeCard extends StatelessWidget {
  final DailyChallenge challenge;
  final Color accent;
  final VoidCallback onClaim;

  const _ChallengeCard({
    required this.challenge,
    required this.accent,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    const depth = 6.0;
    final readyToClaim = challenge.isCompleted && !challenge.rewardClaimed;
    final claimed = challenge.rewardClaimed;
    final ratio = challenge.progress.clamp(0.0, 1.0).toDouble();
    final edge = readyToClaim
        ? _starGold
        : (claimed ? _doneGreen : accent);
    final barColor = challenge.isCompleted ? _doneGreen : accent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12 + depth),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: claimed ? KidColors.lighten(_doneGreen, 0.5) : Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
              color: edge.withOpacity(readyToClaim ? 1 : 0.5), width: 3),
          boxShadow: [
            BoxShadow(
              color: edge.withOpacity(0.55),
              offset: const Offset(0, depth),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [KidColors.lighten(accent, 0.3), accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border:
                Border.all(color: Colors.white.withOpacity(0.7), width: 3),
              ),
              child: Text(challenge.iconEmoji,
                  style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: _fredoka(size: 16, weight: FontWeight.w800),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    challenge.subtitle,
                    style: _fredoka(
                        size: 12.5,
                        color: KidColors.textMuted,
                        weight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: barColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(end: ratio),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (_, value, __) => Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: value.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (claimed)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _doneGreen,
                  boxShadow: [
                    BoxShadow(
                      color: KidColors.darken(_doneGreen),
                      offset: const Offset(0, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 26),
              )
            else if (readyToClaim)
              _ClaimButton(
                label: 'Claim ⭐${challenge.starReward}',
                onTap: onClaim,
              )
            else
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${challenge.currentCount}/${challenge.targetCount}',
                  style: _fredoka(
                      size: 14,
                      color: KidColors.darken(accent),
                      weight: FontWeight.w800),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ClaimButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _ClaimButton({required this.label, required this.onTap});

  @override
  State<_ClaimButton> createState() => _ClaimButtonState();
}

class _ClaimButtonState extends State<_ClaimButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const depth = 4.0;
    final offset = _down ? 1.0 : depth;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: depth),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          transform: Matrix4.translationValues(0, depth - offset, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _starGold,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: KidColors.darken(_starGold),
                offset: Offset(0, offset),
                blurRadius: 0,
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: _fredoka(
                size: 14, color: Colors.white, weight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}