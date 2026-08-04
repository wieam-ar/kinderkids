import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../data/models/number/number.dart';
import 'Numberpracticeview.dart';

class NumberScreen extends StatefulWidget {
  const NumberScreen({super.key});

  // نفس colors ديال Alphabet
  static const Color primaryBlue = Color(0xFF0F92CA);
  static const Color textDark = Color(0xFF213238);
  static const Color textMuted = Color(0xFF7C8C93);

  @override
  State<NumberScreen> createState() => _NumberScreenState();
}

class _NumberScreenState extends State<NumberScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  NumberData? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final raw = await rootBundle.loadString('assets/data/numbers.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _data = NumberData.fromJson(json));
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
          /// 🌄 Background نفس Alphabet
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_background.png',
              fit: BoxFit.cover,
            ),
          ),

          /// overlay أبيض
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.35),
                    Colors.white.withOpacity(0.8),
                    Colors.white.withOpacity(0.97),
                  ],
                  stops: const [0.0, 0.28, 0.5],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _Header(tabController: _tabController),
                const SizedBox(height: 14),

                /// Card container
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: NumberScreen.primaryBlue.withOpacity(0.12),
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
        child: Text('Error: $_error'),
      );
    }

    if (_data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return TabBarView(
      controller: _tabController,
      children: [
        NumberPracticeView(numbers: _data!.arabic, isArabic: true),
        NumberPracticeView(numbers: _data!.english, isArabic: false),
      ],
    );
  }
}

//// ================= HEADER =================

class _Header extends StatelessWidget {
  final TabController tabController;

  const _Header({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              _CircleButton(
                icon: Icons.arrow_back_ios_new,
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(width: 12),

              const Expanded(
                child: Text(
                  'Numbers',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const Text('🔢', style: TextStyle(fontSize: 20)),
            ],
          ),

          const SizedBox(height: 16),

          _SegmentedTabBar(tabController: tabController),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      color: Colors.white,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 16),
        ),
      ),
    );
  }
}

//// ================= SEGMENTED =================

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
        builder: (_, __) {
          final selectedIndex = tabController.index;

          return Row(
            children: [
              _buildItem(0, 'العربية', selectedIndex),
              _buildItem(1, 'English', selectedIndex),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItem(int index, String text, int selectedIndex) {
    final selected = index == selectedIndex;

    return Expanded(
      child: GestureDetector(
        onTap: () => tabController.animateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: selected ? NumberScreen.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              color: selected ? Colors.white : NumberScreen.textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}