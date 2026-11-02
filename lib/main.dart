import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'mobile/data/providers/progress_provider.dart';
import 'mobile/features/navigation/main_navigation_screen.dart';
import 'mobile/features/splash/splash_screen.dart';

void main() {
  runApp(const KinderKidsApp());
}

class KinderKidsApp extends StatelessWidget {
  const KinderKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProgressProvider(),
      child: MaterialApp(
        title: 'Kinderkids',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Poppins',
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        routes: {
          '/home': (context) => const MainNavigationScreen(),
        },
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const KinderKidsApp();
  }
}
