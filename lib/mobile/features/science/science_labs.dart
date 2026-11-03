import 'package:flutter/material.dart';

import 'lab_color_war.dart';
import 'lab_sink_float.dart';
import 'lab_space.dart';

export 'lab_common.dart' show LabSfx, showStageComplete;
export 'lab_i18n.dart';

// ---------------------------------------------------------------------------
// Public entry point: use this anywhere you need an interactive lab.
//   ScienceLab(type: exp.interactiveType)
// ---------------------------------------------------------------------------

class ScienceLab extends StatelessWidget {
  final String type;

  const ScienceLab({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case 'sink_float':
        return const SinkFloatLab();
      case 'color_mix':
      case 'color_war':
        return const ColorWarLab();
      default:
        return const SpaceLab();
    }
  }
}