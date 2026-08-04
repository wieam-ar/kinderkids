import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../data/models/alphabet/alpha.dart';
import 'Alphabetpracticeview.dart';

/// Replaces the generic ActivityDetailScreen for the "Alphabet" tile.
/// Arabic and English are two fully independent parts (own tab, own
/// progress, own letter-by-letter flow).
class AlphabetScreen extends StatefulWidget {
  const AlphabetScreen({super.key});

  // --- Design tokens (matches home_screen.dart) ------------------------
  static const Color primaryBlue = Color(0xFF0F92CA);
  static const Color primaryBlueDark = Color(0xFF0B6E9B);
  static const Color textDark = Color(0xFF213238);
  static const Color textMuted = Color(0xFF7C8C93);
  // ----------------------------------------------------------------------

  @override
  State<AlphabetScreen> createState() => _AlphabetScreenState();
}

class _AlphabetScreenState extends State<AlphabetScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  AlphabetData? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final raw = await rootBundle.loadString('assets/data/alphabet.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _data = AlphabetData.fromJson(json));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Same safari/nature themed background used on splash /
          // onboarding / home, so this screen feels consistent.
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Soft white wash so the header and card stay readable over
          // the artwork.
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.35),
                    Colors.white.withOpacity(0.8),
                    Colors.white.withOpacity(0.97),
                  ],
                  stops: const [0.0, 0.28, 0.5],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _AlphabetHeader(tabController: _tabController),
                const SizedBox(height: 14),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AlphabetScreen.primaryBlue.withOpacity(0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildBody(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load assets/data/alphabet.json\n$_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AlphabetScreen.textMuted),
          ),
        ),
      );
    }
    if (_data == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: AlphabetScreen.primaryBlue,
        ),
      );
    }
    return TabBarView(
      controller: _tabController,
      children: [
        AlphabetPracticeView(letters: _data!.arabic, isArabic: true),
        AlphabetPracticeView(letters: _data!.english, isArabic: false),
      ],
    );
  }
}

/// Custom header: back button + title, and a pill-shaped segmented
/// control standing in for the old Material TabBar.
class _AlphabetHeader extends StatelessWidget {
  final TabController tabController;

  const _AlphabetHeader({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CircleIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Alphabet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: AlphabetScreen.textDark,
                  ),
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text('🔤', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SegmentedTabBar(tabController: tabController),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: AlphabetScreen.textDark),
        ),
      ),
    );
  }
}

/// Pill-shaped, animated two-way tab switcher (العربية / English) that
/// mirrors the TabController so AlphabetPracticeView keeps working
/// exactly as before.
class _SegmentedTabBar extends StatelessWidget {
  final TabController tabController;

  const _SegmentedTabBar({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F4F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnimatedBuilder(
        animation: tabController,
        builder: (context, _) {
          final selectedIndex = tabController.index;
          return Row(
            children: [
              _buildSegment(context, 0, 'العربية', selectedIndex),
              _buildSegment(context, 1, 'English', selectedIndex),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSegment(
      BuildContext context,
      int index,
      String label,
      int selectedIndex,
      ) {
    final selected = index == selectedIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => tabController.animateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected ? AlphabetScreen.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
              BoxShadow(
                color: AlphabetScreen.primaryBlue.withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AlphabetScreen.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}