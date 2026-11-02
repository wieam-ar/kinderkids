import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_ui.dart';
import '../../data/providers/progress_provider.dart';

class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});

  /// 'alphabet_world_lvl_2' -> 'Alphabet World Level 2'
  static String _prettyWorldKey(String key) {
    final cleaned = key.replaceAll('_lvl_', ' Level ').replaceAll('_', ' ');
    return cleaned
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Future<void> _editNickname(
      BuildContext context,
      ProgressProvider progress,
      ) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => _NicknameDialog(initial: progress.profile.nickname),
    );
    if (newName == null || newName == progress.profile.nickname) return;
    await progress.updateNickname(newName);
  }

  Future<void> _confirmReset(
      BuildContext context,
      ProgressProvider progress,
      ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Progress?'),
        content: const Text(
          'This resets stars, unlocked levels and shop purchases. '
              'It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Reset All'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await progress.resetAllProgress();
    showAppSnack(messenger, '✅ Progress has been reset');
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final profile = progress.profile;

    final starredLevels =
    profile.worldStars.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final worldsStarted =
        starredLevels.map((e) => e.key.split('_lvl_').first).toSet().length;
    final challengesDone =
        progress.dailyChallenges.where((c) => c.isCompleted).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildAppBar('Parent Dashboard 👨‍👩‍👧'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          SoftCard(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Text(profile.avatarEmoji, style: const TextStyle(fontSize: 42)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nickname shown on the Home screen',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        profile.nickname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _editNickname(context, progress),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionTitle('Learning Statistics'),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.9,
            children: [
              _StatTile(
                icon: '🌟',
                label: 'Stars earned',
                value: '${profile.totalStars}',
              ),
              _StatTile(
                icon: '🎨',
                label: 'Saved artworks',
                value: '${profile.savedArtworkPaths.length}',
              ),
              _StatTile(
                icon: '🏅',
                label: 'Badges earned',
                value: '${profile.earnedBadges.length}',
              ),
              _StatTile(
                icon: '🧩',
                label: 'Worlds started',
                value: '$worldsStarted',
              ),
              _StatTile(
                icon: '🚀',
                label: 'Levels with stars',
                value: '${starredLevels.length}',
              ),
              _StatTile(
                icon: '🎯',
                label: 'Challenges done',
                value: '$challengesDone',
              ),
            ],
          ),
          if (starredLevels.isNotEmpty) ...[
            const SizedBox(height: 12),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Star History by World',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  for (final entry in starredLevels)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _prettyWorldKey(entry.key),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '⭐ ${entry.value}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.starDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          const SectionTitle('Screen Time Management'),
          const SizedBox(height: 12),
          _ScreenTimeCard(
            limitMinutes: profile.screenTimeLimitMinutes,
            usedMinutes: progress.usageMinutesToday,
            remainingMinutes: progress.screenTimeMinutesRemaining,
            onLimitChanged: progress.updateScreenTimeLimit,
          ),
          const SizedBox(height: 24),
          const SectionTitle('Sound & Effects'),
          const SizedBox(height: 12),
          SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: const Text(
                'Sound Effects & Audio Feedback',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              value: profile.soundEffectsEnabled,
              onChanged: progress.toggleSoundEffects,
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => _confirmReset(context, progress),
            icon: const Icon(Icons.restore_rounded),
            label: const Text('Reset Child Progress'),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Keeps the slider value locally while dragging and saves only on release,
/// instead of writing to storage on every tick.
class _ScreenTimeCard extends StatefulWidget {
  final int limitMinutes;
  final int usedMinutes;
  final int? remainingMinutes;
  final ValueChanged<int> onLimitChanged;

  const _ScreenTimeCard({
    required this.limitMinutes,
    required this.usedMinutes,
    required this.remainingMinutes,
    required this.onLimitChanged,
  });

  @override
  State<_ScreenTimeCard> createState() => _ScreenTimeCardState();
}

class _ScreenTimeCardState extends State<_ScreenTimeCard> {
  static const double _min = 15;
  static const double _max = 120;

  late double _value;

  @override
  void initState() {
    super.initState();
    _value = _clamp(widget.limitMinutes);
  }

  @override
  void didUpdateWidget(_ScreenTimeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.limitMinutes != widget.limitMinutes) {
      _value = _clamp(widget.limitMinutes);
    }
  }

  double _clamp(int minutes) => minutes.toDouble().clamp(_min, _max).toDouble();

  @override
  Widget build(BuildContext context) {
    final remaining = widget.remainingMinutes;
    final usedRatio = widget.limitMinutes <= 0
        ? 0.0
        : (widget.usedMinutes / widget.limitMinutes).clamp(0.0, 1.0).toDouble();

    final Color remainingColor;
    final String remainingLabel;
    if (remaining == null) {
      remainingColor = AppColors.textMuted;
      remainingLabel = 'No limit';
    } else if (remaining == 0) {
      remainingColor = AppColors.danger;
      remainingLabel = 'Time is up';
    } else {
      remainingColor = AppColors.success;
      remainingLabel = '$remaining mins left';
    }

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Daily limit: ${_value.round()} mins',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                remainingLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: remainingColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: usedRatio,
              minHeight: 8,
              backgroundColor: AppColors.border,
              color: usedRatio >= 1 ? AppColors.danger : AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Used today: ${widget.usedMinutes} mins',
            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          ),
          Slider(
            value: _value,
            min: _min,
            max: _max,
            divisions: 7,
            label: '${_value.round()} mins',
            onChanged: (v) => setState(() => _value = v),
            onChangeEnd: (v) => widget.onLimitChanged(v.round()),
          ),
        ],
      ),
    );
  }
}

class _NicknameDialog extends StatefulWidget {
  final String initial;

  const _NicknameDialog({required this.initial});

  @override
  State<_NicknameDialog> createState() => _NicknameDialogState();
}

class _NicknameDialogState extends State<_NicknameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Edit Nickname'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 16,
        textCapitalization: TextCapitalization.words,
        onSubmitted: (_) => _save(),
        decoration: const InputDecoration(hintText: 'Child nickname'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}