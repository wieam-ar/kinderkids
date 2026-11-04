import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../core/ui/kid_ui.dart';
import '../../data/models/alphabet/alpha.dart';
import 'alphabet_practice_view.dart';

/// Alphabet: Arabic et English = deux parties indépendantes
/// (own tab, own progress, own letter-by-letter flow).
class AlphabetScreen extends StatefulWidget {
  const AlphabetScreen({super.key});

  // Gardés pour compatibilité avec d'autres fichiers éventuels.
  static const Color primaryBlue = KidColors.blue;
  static const Color primaryBlueDark = KidColors.blueDark;
  static const Color textDark = KidColors.textDark;
  static const Color textMuted = KidColors.textMuted;

  @override
  State<AlphabetScreen> createState() => _AlphabetScreenState();
}

class _AlphabetScreenState extends State<AlphabetScreen>
    with SingleTickerProviderStateMixin {
  static const Color _accent = KidColors.blue;

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
      body: KidBackground(
        child: SafeArea(
          child: Column(
            children: [
              const KidHeader(
                title: 'Alphabet',
                emoji: '🔤',
                subtitle: 'Trace the letters with your finger',
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
            'Could not load assets/data/alphabet.json\n$_error',
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
        AlphabetPracticeView(letters: _data!.arabic, isArabic: true),
        AlphabetPracticeView(letters: _data!.english, isArabic: false),
      ],
    );
  }
}