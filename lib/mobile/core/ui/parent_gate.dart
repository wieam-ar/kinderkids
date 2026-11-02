import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_ui.dart';

/// Math gate for grown-ups. It only answers "was it solved?" and never
/// navigates, so every caller decides what to do after unlocking.
class ParentGate {
  ParentGate._();

  static Future<bool> verify(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const _ParentGateDialog(),
    );
    return result ?? false;
  }
}

class _ParentGateDialog extends StatefulWidget {
  const _ParentGateDialog();

  @override
  State<_ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<_ParentGateDialog> {
  final Random _random = Random();
  final TextEditingController _controller = TextEditingController();
  late int _a;
  late int _b;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nextQuestion();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _nextQuestion() {
    _a = _random.nextInt(7) + 3; // 3..9
    _b = _random.nextInt(7) + 3;
  }

  void _submit() {
    if (int.tryParse(_controller.text.trim()) == _a * _b) {
      Navigator.of(context).pop(true);
      return;
    }
    // A wrong answer generates a NEW question so a child can't brute-force it.
    setState(() {
      _error = 'Incorrect, here is a new one';
      _controller.clear();
      _nextQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Text('👨‍👩‍👧 ', style: TextStyle(fontSize: 26)),
          Text(
            'Grown-ups Only',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Solve this to continue:'),
          const SizedBox(height: 14),
          Text(
            '$_a × $_b = ?',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 3,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'Answer',
              counterText: '',
              errorText: _error,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
          ),
          onPressed: _submit,
          child: const Text('Enter'),
        ),
      ],
    );
  }
}
