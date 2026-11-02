import 'package:flutter/material.dart';

import '../../core/ui/app_ui.dart';
import '../../data/models/science_model.dart';
import 'science_labs.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ScienceLabScreen extends StatefulWidget {
  const ScienceLabScreen({super.key});

  @override
  State<ScienceLabScreen> createState() => _ScienceLabScreenState();
}

class _ScienceLabScreenState extends State<ScienceLabScreen> {
  int _selectedIndex = 0;
  bool _soundOn = LabSfx.enabled;

  @override
  void initState() {
    super.initState();
    LabSfx.preload();
  }

  @override
  Widget build(BuildContext context) {
    final experiments = scienceExperiments;

    if (experiments.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: buildAppBar('Mini Science Lab 🔬'),
        body: const EmptyState(
          emoji: '🔬',
          title: 'No experiments yet',
          message: 'New experiments are on their way!',
        ),
      );
    }

    final selected = _selectedIndex.clamp(0, experiments.length - 1);
    final exp = experiments[selected];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildAppBar('Mini Science Lab 🔬'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: experiments.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, idx) {
                    final e = experiments[idx];
                    final isSelected = idx == selected;
                    return ChoiceChip(
                      label: Text('${e.emoji} ${e.title}'),
                      selected: isSelected,
                      showCheckmark: false,
                      selectedColor: AppColors.purple,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) {
                        if (idx != selected) {
                          LabSfx.play('pop');
                          LabSfx.tap();
                        }
                        setState(() => _selectedIndex = idx);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exp.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          exp.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: _soundOn ? 'Mute' : 'Unmute',
                    onPressed: () {
                      setState(() {
                        _soundOn = !_soundOn;
                        LabSfx.enabled = _soundOn;
                      });
                      if (_soundOn) LabSfx.play('pop');
                    },
                    icon: Icon(
                      _soundOn
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      color: _soundOn ? AppColors.purple : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SoftCard(
                  radius: 24,
                  child: SizedBox(
                    width: double.infinity,
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
                        key: ValueKey<String>(exp.interactiveType),
                        child: Center(
                          child: SingleChildScrollView(
                            child: ScienceLab(type: exp.interactiveType),
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
      ),
    );
  }
}