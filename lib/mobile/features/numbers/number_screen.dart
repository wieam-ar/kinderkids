import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../core/ui/kid_ui.dart';
import '../../data/models/number/number.dart';
import 'number_practice_view.dart';

/// Numbers: Arabic et English = deux parties indépendantes.
class NumberScreen extends StatefulWidget {
  const NumberScreen({super.key});

  // Gardés pour compatibilité.
  static const Color primaryBlue = KidColors.blue;
  static const Color textDark = KidColors.textDark;
  static const Color textMuted = KidColors.textMuted;

  @override
  State<NumberScreen> createState() => _NumberScreenState();
}

class _NumberScreenState extends State<NumberScreen>
    with SingleTickerProviderStateMixin {
  static const Color _accent = KidColors.purple;

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
      body: KidBackground(
        colors: const [Color(0xFFE6DBFF), KidColors.cream],
        child: SafeArea(
          child: Column(
            children: [
              const KidHeader(
                title: 'Numbers',
                emoji: '🔢',
                subtitle: 'Trace the numbers with your finger',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: KidSegmentedTabs(
                  controller: _tabController,
                  labels: const ['العربية', 'English'],
                  color: _accent,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  child: KidCard(
                    accent: _accent,
                    radius: 32,
                    padding: EdgeInsets.zero,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: _buildBody(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load assets/data/numbers.json\n$_error',
            textAlign: TextAlign.center,
            style: KidText.muted(size: 14),
          ),
        ),
      );
    }
    if (_data == null) {
      return const Center(
        child: CircularProgressIndicator(color: _accent, strokeWidth: 4),
      );
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