import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_ui.dart' show showAppSnack;
import '../../core/ui/kid_ui.dart';
import '../../core/ui/parent_gate.dart';
import '../../data/providers/progress_provider.dart';
import '../adventure/learning_adventure_screen.dart';
import '../creative/creative_studio_screen.dart';
import '../dashboard/home_screen.dart';
import '../explore/explore_world_screen.dart';
import '../shop/reward_shop_screen.dart';

TextStyle _fredoka({
  double size = 15,
  Color color = KidColors.textDark,
  FontWeight weight = FontWeight.w700,
}) =>
    GoogleFonts.fredoka(fontSize: size, fontWeight: weight, color: color);

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  static const int _shopIndex = 4;

  static const List<Widget> _screens = [
    HomeScreen(),
    LearningAdventureScreen(),
    CreativeStudioScreen(),
    ExploreWorldScreen(),
    RewardShopScreen(),
  ];

  static const List<_NavDestination> _destinations = [
    _NavDestination(Icons.home_rounded, 'Home', KidColors.blue),
    _NavDestination(Icons.map_rounded, 'Adventure', Color(0xFFF2994A)),
    _NavDestination(Icons.palette_rounded, 'Create', Color(0xFFFF7BA9)),
    _NavDestination(Icons.explore_rounded, 'Explore', Color(0xFF2FBF8F)),
    _NavDestination(Icons.store_rounded, 'Shop', KidColors.purple),
  ];

  int _currentIndex = 0;
  Timer? _usageTimer;
  bool _isAppActive = true;
  bool _timeUpDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Count one minute at a time, only while the app is visible.
    _usageTimer = Timer.periodic(const Duration(minutes: 1), (_) => _onTick());
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScreenTime());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppActive = state == AppLifecycleState.resumed;
    if (_isAppActive) _checkScreenTime();
  }

  @override
  void dispose() {
    _usageTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _onTick() async {
    if (!_isAppActive || !mounted) return;
    await context.read<ProgressProvider>().addUsageMinute();
    _checkScreenTime();
  }

  void _checkScreenTime() {
    if (!mounted || _timeUpDialogOpen) return;
    if (context.read<ProgressProvider>().isScreenTimeExceeded) {
      _showTimeUpDialog();
    }
  }

  Future<void> _showTimeUpDialog() async {
    _timeUpDialogOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _TimeUpDialog(),
    );
    _timeUpDialogOpen = false;
    // If the parent granted too little time, the lock comes back right away.
    _checkScreenTime();
  }

  @override
  Widget build(BuildContext context) {
    final stars = context.select<ProgressProvider, int>(
          (p) => p.profile.totalStars,
    );

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border(
            top: BorderSide(
              color: KidColors.purple.withOpacity(0.18),
              width: 3,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: KidColors.purple.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Row(
              children: [
                for (var i = 0; i < _destinations.length; i++)
                  Expanded(
                    child: _NavItem(
                      destination: _destinations[i],
                      isSelected: _currentIndex == i,
                      badge: i == _shopIndex ? '⭐$stars' : null,
                      onTap: () => setState(() => _currentIndex = i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeUpDialog extends StatelessWidget {
  const _TimeUpDialog();

  static const int _extraMinutes = 15;

  Future<void> _requestExtraTime(BuildContext context) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final progress = context.read<ProgressProvider>();

    final unlocked = await ParentGate.verify(context);
    if (!unlocked) return;

    await progress.grantExtraMinutes(_extraMinutes);
    navigator.pop();
    showAppSnack(messenger, '➕ $_extraMinutes extra minutes granted for today!');
  }

  @override
  Widget build(BuildContext context) {
    // The child can't dismiss this dialog: only a parent can unlock more time.
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: KidCard(
          accent: KidColors.purple,
          radius: 32,
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌙', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 8),
              Text(
                'Time for a break!',
                style: _fredoka(size: 26, weight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'You played a lot today! Your eyes and body need a rest. '
                    'See you tomorrow! 💤',
                textAlign: TextAlign.center,
                style: _fredoka(
                  size: 15,
                  color: KidColors.textMuted,
                  weight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              KidButton(
                label: 'Parent: add 15 minutes',
                icon: Icons.key_rounded,
                color: KidColors.purple,
                expand: true,
                onPressed: () => _requestExtraTime(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavDestination {
  final IconData icon;
  final String label;
  final Color color;

  const _NavDestination(this.icon, this.label, this.color);
}

class _NavItem extends StatelessWidget {
  final _NavDestination destination;
  final bool isSelected;
  final String? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final color = destination.color;
    final fg = isSelected ? Colors.white : KidColors.textMuted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          padding: const EdgeInsets.symmetric(vertical: 8),
          transform: Matrix4.translationValues(0, isSelected ? -4 : 0, 0),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [KidColors.lighten(color, 0.08), color],
            )
                : null,
            borderRadius: BorderRadius.circular(22),
            border: isSelected
                ? Border.all(color: Colors.white.withOpacity(0.6), width: 3)
                : null,
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: KidColors.darken(color),
                offset: const Offset(0, 5),
                blurRadius: 0,
              ),
            ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedScale(
                    scale: isSelected ? 1.15 : 1,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(destination.icon, color: fg, size: 26),
                  ),
                  if (badge != null)
                    Positioned(
                      top: -8,
                      right: -26,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB82E),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          badge!,
                          style: _fredoka(
                            size: 10,
                            color: Colors.white,
                            weight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _fredoka(
                  size: 11.5,
                  color: fg,
                  weight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}