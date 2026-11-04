import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/ui/app_ui.dart';
import '../../core/ui/kid_ui.dart';
import '../../data/models/science_model.dart';
import 'lab_common.dart';
import 'lab_i18n.dart';
import 'science_labs.dart';

TextStyle _fredoka({
  double size = 15,
  Color color = KidColors.textDark,
  FontWeight weight = FontWeight.w700,
  double? height,
}) =>
    GoogleFonts.fredoka(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );

class ScienceLabScreen extends StatefulWidget {
  const ScienceLabScreen({super.key});

  @override
  State<ScienceLabScreen> createState() => _ScienceLabScreenState();
}

class _ScienceLabScreenState extends State<ScienceLabScreen> {
  final LabI18n _i18n = LabI18n.instance;
  int _selectedIndex = 0;
  bool _soundOn = LabSfx.enabled;

  @override
  void initState() {
    super.initState();
    LabSfx.preload();
    _i18n.load(); // saved language, or the phone language the first time
  }

  @override
  void dispose() {
    LabSfx.stopSpeech();
    super.dispose();
  }

  // ---- Per-lab look + texts ------------------------------------------------

  String _tabKey(String type) {
    switch (type) {
      case 'sink_float':
        return 'sink';
      case 'color_mix':
      case 'color_war':
        return 'color';
      default:
        return 'space';
    }
  }

  Color _labColor(String type) {
    switch (_tabKey(type)) {
      case 'sink':
        return Colors.lightBlue;
      case 'color':
        return Colors.pink;
      default:
        return Colors.deepPurple;
    }
  }

  List<String> _emojis(String type) {
    switch (_tabKey(type)) {
      case 'sink':
        return const ['💧', '🫧', '🦆', '🍎'];
      case 'color':
        return const ['🎨', '🖌️', '💜', '🍊'];
      default:
        return const ['⭐', '✨', '🪐', '🌙'];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds the whole screen (texts + RTL) when the language changes.
    return AnimatedBuilder(
      animation: _i18n,
      builder: (context, _) => Directionality(
        textDirection: _i18n.direction,
        child: _buildScreen(context),
      ),
    );
  }

  Widget _buildScreen(BuildContext context) {
    final experiments = scienceExperiments;

    if (experiments.isEmpty) {
      return Scaffold(
        body: KidBackground(
          colors: const [Color(0xFFE6DDFB), KidColors.cream],
          child: SafeArea(
            child: Column(
              children: [
                KidHeader(
                  title: _i18n.t('app_title'),
                  emoji: '🔬',
                  subtitle: '',
                ),
                const Expanded(
                  child: EmptyState(
                    emoji: '🔬',
                    title: 'No experiments yet',
                    message: 'New experiments are on their way!',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final selected = _selectedIndex.clamp(0, experiments.length - 1);
    final exp = experiments[selected];
    final type = exp.interactiveType;
    final key = _tabKey(type);
    final color = _labColor(type);
    final title = _i18n.t('tab_$key');
    final description = _i18n.t('desc_$key');

    return Scaffold(
      backgroundColor: KidColors.cream,
      body: Stack(
        children: [
          Positioned.fill(
            child: LabBackdrop(color: color, emojis: _emojis(type)),
          ),
          SafeArea(
            child: Column(
              children: [
                KidHeader(
                  title: _i18n.t('app_title'),
                  emoji: '🔬',
                  subtitle: title,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const LabLangBar(),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            for (var i = 0; i < experiments.length; i++) ...[
                              Expanded(
                                child: LabTabButton(
                                  emoji: experiments[i].emoji,
                                  label: _i18n.t(
                                    'tab_${_tabKey(experiments[i].interactiveType)}',
                                  ),
                                  color:
                                  _labColor(experiments[i].interactiveType),
                                  selected: i == selected,
                                  onTap: () {
                                    if (i != selected) {
                                      LabSfx.stopSpeech();
                                      LabSfx.play('pop');
                                      LabSfx.tap();
                                    }
                                    setState(() => _selectedIndex = i);
                                  },
                                ),
                              ),
                              if (i != experiments.length - 1)
                                const SizedBox(width: 8),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ---- info card: description + listen / mute ----
                        _InfoCard(
                          color: color,
                          emoji: exp.emoji,
                          description: description,
                          soundOn: _soundOn,
                          listenTooltip: _i18n.t('listen'),
                          soundTooltip:
                          _soundOn ? _i18n.t('mute') : _i18n.t('unmute'),
                          onListen: () => LabSfx.speak('$title. $description'),
                          onToggleSound: () {
                            setState(() {
                              _soundOn = !_soundOn;
                              LabSfx.enabled = _soundOn;
                            });
                            if (_soundOn) {
                              LabSfx.play('pop');
                            } else {
                              LabSfx.stopSpeech();
                            }
                          },
                        ),
                        const SizedBox(height: 12),

                        Expanded(
                          child: LabCard(
                            color: color,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, anim) =>
                                  FadeTransition(
                                    opacity: anim,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.08, 0),
                                        end: Offset.zero,
                                      ).animate(anim),
                                      child: child,
                                    ),
                                  ),
                              child: KeyedSubtree(
                                key: ValueKey<String>(type),
                                child: Center(
                                  child: SingleChildScrollView(
                                    child: ScienceLab(type: type),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

// ---------------------------------------------------------------- info card

class _InfoCard extends StatelessWidget {
  final Color color;
  final String emoji;
  final String description;
  final bool soundOn;
  final String listenTooltip;
  final String soundTooltip;
  final VoidCallback onListen;
  final VoidCallback onToggleSound;

  const _InfoCard({
    required this.color,
    required this.emoji,
    required this.description,
    required this.soundOn,
    required this.listenTooltip,
    required this.soundTooltip,
    required this.onListen,
    required this.onToggleSound,
  });

  @override
  Widget build(BuildContext context) {
    const depth = 5.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: depth),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: color.withOpacity(0.45), width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              offset: const Offset(0, depth),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KidColors.lighten(color, 0.38),
                border: Border.all(color: color, width: 3),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                description,
                style: _fredoka(
                  size: 13.5,
                  color: KidColors.textMuted,
                  weight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: listenTooltip,
              child: KidRoundButton(
                icon: Icons.record_voice_over_rounded,
                color: color,
                onTap: onListen,
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: soundTooltip,
              child: KidRoundButton(
                icon: soundOn
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                color: soundOn ? KidColors.green : Colors.grey.shade400,
                onTap: onToggleSound,
              ),
            ),
          ],
        ),
      ),
    );
  }
}