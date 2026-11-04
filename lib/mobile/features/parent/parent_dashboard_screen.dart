import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_ui.dart' show showAppSnack;
import '../../core/ui/kid_ui.dart';
import '../../data/providers/progress_provider.dart';

TextStyle _fredoka({
  double size = 15,
  Color color = KidColors.textDark,
  FontWeight weight = FontWeight.w700,
}) =>
    GoogleFonts.fredoka(fontSize: size, fontWeight: weight, color: color);

const Color _gold = Color(0xFFE0A800);

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
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        child: KidCard(
          accent: KidColors.coral,
          radius: 32,
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 8),
              Text('Reset Progress?',
                  style: _fredoka(size: 24, weight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'This resets stars, unlocked levels and shop purchases. '
                    'It cannot be undone.',
                textAlign: TextAlign.center,
                style: _fredoka(
                  size: 14.5,
                  color: KidColors.textMuted,
                  weight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              KidButton(
                label: 'Reset All',
                icon: Icons.restore_rounded,
                color: KidColors.coral,
                expand: true,
                onPressed: () => Navigator.of(dialogCtx).pop(true),
              ),
              const SizedBox(height: 12),
              KidButton(
                label: 'Cancel',
                icon: Icons.close_rounded,
                color: KidColors.green,
                expand: true,
                onPressed: () => Navigator.of(dialogCtx).pop(false),
              ),
            ],
          ),
        ),
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
      body: KidBackground(
        colors: const [Color(0xFFE6DBFF), KidColors.cream],
        child: SafeArea(
          child: Column(
            children: [
              const KidHeader(
                title: 'Parent Dashboard',
                emoji: '👨‍👩‍👧',
                subtitle: 'Progress, screen time and settings',
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
                  children: [
                    KidCard(
                      accent: KidColors.purple,
                      radius: 28,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: KidColors.purple.withOpacity(0.12),
                              border: Border.all(
                                color: KidColors.purple.withOpacity(0.4),
                                width: 2,
                              ),
                            ),
                            child: Text(profile.avatarEmoji,
                                style: const TextStyle(fontSize: 32)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nickname shown on the Home screen',
                                  style: _fredoka(
                                    size: 12,
                                    color: KidColors.textMuted,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  profile.nickname,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _fredoka(
                                      size: 22, weight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                          KidRoundButton(
                            icon: Icons.edit_rounded,
                            color: KidColors.purple,
                            tooltip: 'Edit',
                            onTap: () => _editNickname(context, progress),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _SectionHeader(
                      emoji: '📊',
                      title: 'Learning Statistics',
                      color: KidColors.blue,
                    ),
                    const SizedBox(height: 14),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.75,
                      children: [
                        _StatTile(
                          icon: '🌟',
                          label: 'Stars earned',
                          value: '${profile.totalStars}',
                          color: _gold,
                        ),
                        _StatTile(
                          icon: '🎨',
                          label: 'Saved artworks',
                          value: '${profile.savedArtworkPaths.length}',
                          color: const Color(0xFFFF7A59),
                        ),
                        _StatTile(
                          icon: '🏅',
                          label: 'Badges earned',
                          value: '${profile.earnedBadges.length}',
                          color: KidColors.purple,
                        ),
                        _StatTile(
                          icon: '🧩',
                          label: 'Worlds started',
                          value: '$worldsStarted',
                          color: const Color(0xFF2FBF8F),
                        ),
                        _StatTile(
                          icon: '🚀',
                          label: 'Levels with stars',
                          value: '${starredLevels.length}',
                          color: KidColors.blue,
                        ),
                        _StatTile(
                          icon: '🎯',
                          label: 'Challenges done',
                          value: '$challengesDone',
                          color: KidColors.orange,
                        ),
                      ],
                    ),
                    if (starredLevels.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      KidCard(
                        accent: _gold,
                        radius: 28,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Star History by World',
                                style:
                                _fredoka(size: 16, weight: FontWeight.w800)),
                            const SizedBox(height: 10),
                            for (final entry in starredLevels)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _prettyWorldKey(entry.key),
                                        style: _fredoka(
                                          size: 14,
                                          weight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _gold.withOpacity(0.15),
                                        borderRadius:
                                        BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        '⭐ ${entry.value}',
                                        style: _fredoka(
                                          size: 13,
                                          color: KidColors.darken(_gold, 0.15),
                                          weight: FontWeight.w800,
                                        ),
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
                    const _SectionHeader(
                      emoji: '⏰',
                      title: 'Screen Time',
                      color: KidColors.orange,
                    ),
                    const SizedBox(height: 14),
                    _ScreenTimeCard(
                      limitMinutes: profile.screenTimeLimitMinutes,
                      usedMinutes: progress.usageMinutesToday,
                      remainingMinutes: progress.screenTimeMinutesRemaining,
                      onLimitChanged: progress.updateScreenTimeLimit,
                    ),
                    const SizedBox(height: 24),
                    const _SectionHeader(
                      emoji: '🔊',
                      title: 'Sound & Effects',
                      color: KidColors.green,
                    ),
                    const SizedBox(height: 14),
                    KidCard(
                      accent: KidColors.green,
                      radius: 28,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: SwitchListTile(
                        contentPadding:
                        const EdgeInsets.symmetric(horizontal: 6),
                        activeColor: KidColors.green,
                        title: Text(
                          'Sound Effects & Audio Feedback',
                          style: _fredoka(size: 15),
                        ),
                        value: profile.soundEffectsEnabled,
                        onChanged: progress.toggleSoundEffects,
                      ),
                    ),
                    const SizedBox(height: 28),
                    KidButton(
                      label: 'Reset Child Progress',
                      icon: Icons.restore_rounded,
                      color: KidColors.coral,
                      expand: true,
                      onPressed: () => _confirmReset(context, progress),
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

class _SectionHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.emoji,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 8),
        Text(title, style: _fredoka(size: 20, weight: FontWeight.w800)),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: color.withOpacity(0.25),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return KidCard(
      accent: color,
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: _fredoka(
                    size: 24,
                    color: KidColors.darken(color, 0.1),
                    weight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _fredoka(
                    size: 12,
                    color: KidColors.textMuted,
                    weight: FontWeight.w500,
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
      remainingColor = KidColors.textMuted;
      remainingLabel = 'No limit';
    } else if (remaining == 0) {
      remainingColor = KidColors.coral;
      remainingLabel = 'Time is up';
    } else {
      remainingColor = KidColors.green;
      remainingLabel = '$remaining mins left';
    }

    return KidCard(
      accent: KidColors.orange,
      radius: 28,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⏱️', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Daily limit: ${_value.round()} mins',
                  style: _fredoka(size: 16, weight: FontWeight.w800),
                ),
              ),
              Text(
                remainingLabel,
                style: _fredoka(
                  size: 13,
                  color: KidColors.darken(remainingColor, 0.12),
                  weight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          KidProgressBar(
            value: usedRatio,
            height: 12,
            color: usedRatio >= 1 ? KidColors.coral : KidColors.orange,
          ),
          const SizedBox(height: 6),
          Text(
            'Used today: ${widget.usedMinutes} mins',
            style: _fredoka(
              size: 12,
              color: KidColors.textMuted,
              weight: FontWeight.w500,
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 10,
              activeTrackColor: KidColors.orange,
              inactiveTrackColor: KidColors.orange.withOpacity(0.2),
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
              activeTickMarkColor: Colors.transparent,
              inactiveTickMarkColor: Colors.transparent,
            ),
            child: Slider(
              value: _value,
              min: _min,
              max: _max,
              divisions: 7,
              label: '${_value.round()} mins',
              onChanged: (v) => setState(() => _value = v),
              onChangeEnd: (v) => widget.onLimitChanged(v.round()),
            ),
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
    return Dialog(
      backgroundColor: Colors.transparent,
      child: KidCard(
        accent: KidColors.purple,
        radius: 32,
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Edit Nickname',
                style: _fredoka(size: 24, weight: FontWeight.w800)),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: 16,
              textCapitalization: TextCapitalization.words,
              textAlign: TextAlign.center,
              style: _fredoka(size: 20),
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                hintText: 'Child nickname',
                filled: true,
                fillColor: KidColors.purple.withOpacity(0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                      color: KidColors.purple.withOpacity(0.4), width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                      color: KidColors.purple.withOpacity(0.4), width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide:
                  const BorderSide(color: KidColors.purple, width: 3),
                ),
              ),
            ),
            const SizedBox(height: 12),
            KidButton(
              label: 'Save',
              icon: Icons.check_rounded,
              color: KidColors.green,
              expand: true,
              onPressed: _save,
            ),
            const SizedBox(height: 12),
            KidButton(
              label: 'Cancel',
              icon: Icons.close_rounded,
              color: KidColors.textMuted,
              expand: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}