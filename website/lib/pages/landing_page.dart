import 'package:flutter/material.dart';

/// Page for landing.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LandingPage')),
      body: const Center(child: Text('LandingPage')),
    );
  }
}
