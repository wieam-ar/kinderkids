import 'package:flutter/material.dart';

import '../../core/ui/app_ui.dart';
import '../../data/models/science_model.dart';
import 'lab_common.dart';
import 'lab_i18n.dart';
import 'science_labs.dart';

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
        backgroundColor: AppColors.background,
        appBar: buildAppBar('${_i18n.t('app_title')} 🔬'),
        body: const EmptyState(
          emoji: '🔬',
          title: 'No experiments yet',
          message: 'New experiments are on their way!',
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
      backgroundColor: AppColors.background,
      appBar: buildAppBar('${_i18n.t('app_title')} 🔬'),
      body: Stack(
        children: [
          Positioned.fill(
            child: LabBackdrop(color: color, emojis: _emojis(type)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                            color: _labColor(experiments[i].interactiveType),
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
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              description,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: _i18n.t('listen'),
                        onPressed: () => LabSfx.speak('$title. $description'),
                        icon: Icon(
                          Icons.record_voice_over_rounded,
                          color: color,
                        ),
                      ),
                      IconButton(
                        tooltip:
                        _soundOn ? _i18n.t('mute') : _i18n.t('unmute'),
                        onPressed: () {
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
                        icon: Icon(
                          _soundOn
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                          color: _soundOn ? color : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: LabCard(
                      color: color,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) => FadeTransition(
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
    );
  }
}