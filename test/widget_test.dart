import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinderkids/main.dart';
import 'package:kinderkids/mobile/data/providers/progress_provider.dart';
import 'package:kinderkids/mobile/features/dashboard/home_screen.dart';
import 'package:kinderkids/mobile/features/splash/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Give repository-driven initialization room to finish before asserting.
Future<void> settleProvider(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'KinderKidsApp is wrapped in a ProgressProvider',
    (tester) async {
      await tester.pumpWidget(const KinderKidsApp());
      await settleProvider(tester);

      final context = tester.element(find.byType(SplashScreen));
      expect(
        Provider.of<ProgressProvider>(context, listen: false),
        isNotNull,
      );

      // Let the splash slide navigate so no test timers stay pending.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'HomeScreen greets the child using their profile',
    (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ProgressProvider()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await settleProvider(tester);

      // Personalized greeting from the persisted profile (default nickname).
      expect(find.textContaining('Hi,'), findsOneWidget);
      // The daily challenge strip is rendered.
      expect(find.text('Daily Challenges'), findsOneWidget);
      // Exercise sections exist.
      expect(find.text('Discover our app'), findsOneWidget);
      expect(find.text('Exercises'), findsOneWidget);
      expect(find.text('Science Lab'), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'HomeScreen star counter reflects provider stars',
    (tester) async {
      // Hydrate + mutate the provider with real async time so the
      // repository futures (shared_preferences mock) complete.
      final provider = ProgressProvider();
      await tester.runAsync(() async {
        for (var i = 0; i < 20 && provider.isLoading; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        await provider.addStars(5);
      });

      final totalStars = provider.profile.totalStars;

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider.value(value: provider)],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await settleProvider(tester);

      expect(find.text('⭐ '), findsAny);
      expect(find.text('$totalStars'), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
