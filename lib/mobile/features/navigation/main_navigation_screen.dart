import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_ui.dart';
import '../../core/ui/parent_gate.dart';
import '../../data/providers/progress_provider.dart';
import '../adventure/learning_adventure_screen.dart';
import '../creative/creative_studio_screen.dart';
import '../dashboard/home_screen.dart';
import '../explore/explore_world_screen.dart';
import '../shop/reward_shop_screen.dart';

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
    _NavDestination(Icons.home_rounded, 'Home'),
    _NavDestination(Icons.map_rounded, 'Adventure'),
    _NavDestination(Icons.palette_rounded, 'Create'),
    _NavDestination(Icons.explore_rounded, 'Explore'),
    _NavDestination(Icons.store_rounded, 'Shop'),
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: AppShadows.soft(0.1),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌙', style: TextStyle(fontSize: 60)),
              const SizedBox(height: 12),
              const Text(
                'Time for a break!',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 21,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You played a lot today! Your eyes and body need a rest. '
                    'See you tomorrow! 💤',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _requestExtraTime(context),
                  icon: const Icon(Icons.key_rounded, size: 18),
                  label: const Text('Parent: add 15 minutes'),
                ),
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

  const _NavDestination(this.icon, this.label);
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
    final color = isSelected ? AppColors.primary : Colors.grey.shade500;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
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
                  child: Icon(destination.icon, color: color, size: 24),
                ),
                if (badge != null)
                  Positioned(
                    top: -6,
                    right: -22,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.star,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}