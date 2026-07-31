import 'package:flutter/material.dart';

/// Page for about.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AboutPage')),
      body: const Center(child: Text('AboutPage')),
    );
  }
}
