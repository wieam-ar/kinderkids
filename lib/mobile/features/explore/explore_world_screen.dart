import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/explore_model.dart';
import '../../data/providers/progress_provider.dart';
import '../science/science_lab_screen.dart';

class ExploreWorldScreen extends StatefulWidget {
  const ExploreWorldScreen({super.key});

  @override
  State<ExploreWorldScreen> createState() => _ExploreWorldScreenState();
}

class _ExploreWorldScreenState extends State<ExploreWorldScreen> {
  static const Color primaryBlue = Color(0xFF0F92CA);
  static const Color textDark = Color(0xFF213238);
  static const Color textMuted = Color(0xFF7C8C93);

  /// Topics whose quiz stars were already collected this session — keeps
  /// the reward honest so the quiz cannot be farmed endlessly.
  final Set<String> _answeredTopicIds = {};

  void _showTopicQuiz(BuildContext context, ExploreTopic topic, String lang) {
    final alreadyAnswered = _answeredTopicIds.contains(topic.id);
    final progress = Provider.of<ProgressProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final options = topic.getOptions(lang);
        String? selectedOptionText;
        bool? isCorrect;
        void handleSelect(
            void Function(void Function()) setModalState, QuizOption opt) {
          setModalState(() {
            selectedOptionText = opt.text;
            isCorrect = opt.isCorrect;
          });
          if (opt.isCorrect && !_answeredTopicIds.contains(topic.id)) {
            _answeredTopicIds.add(topic.id);
            progress.addStars(2);
            progress.incrementChallengeProgress('explore');
          }
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Text('${topic.emoji} ', style: const TextStyle(fontSize: 28)),
                  Expanded(
                    child: Text(
                      topic.getTitle(lang),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.getQuestion(lang),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: textDark),
                  ),
                  const SizedBox(height: 16),
                  ...options.map((opt) {
                    final selected = selectedOptionText == opt.text;
                    Color bg = Colors.grey.shade100;
                    if (selected) {
                      bg = opt.isCorrect
                          ? const Color(0xFF35B24A)
                          : const Color(0xFFFF6B5E);
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: bg,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => handleSelect(setModalState, opt),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    opt.text,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: selected ? Colors.white : textDark,
                                    ),
                                  ),
                                ),
                                if (selected && opt.isCorrect)
                                  const Icon(Icons.check_circle_rounded,
                                      color: Colors.white, size: 20)
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  if (isCorrect == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        alreadyAnswered
                            ? '🎉 Correct! (Stars already collected for this topic)'
                            : '🎉 Correct! Earned +2 Stars!',
                        style: const TextStyle(
                            color: Color(0xFF35B24A),
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final lang = progress.profile.selectedLanguage;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explore World 🌍',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textDark,
                        ),
                      ),
                      Text(
                        'Animals, Nature & Mini Science!',
                        style: TextStyle(fontSize: 13, color: textMuted),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _LangChip('EN', 'en', lang, progress),
                      const SizedBox(width: 4),
                      _LangChip('AR', 'ar', lang, progress),
                      const SizedBox(width: 4),
                      _LangChip('FR', 'fr', lang, progress),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ScienceLabScreen()),
                ),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB48CF2), Color(0xFF8B5CF6)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Text('🔬 ', style: TextStyle(fontSize: 32)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mini Science Lab',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                            Text(
                              'Sink/Float, Color Mixing & Sun Experiments',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: ListView.builder(
                  itemCount: exploreTopics.length,
                  itemBuilder: (context, index) {
                    final topic = exploreTopics[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(topic.emoji,
                                  style: const TextStyle(fontSize: 36)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  topic.getTitle(lang),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: textDark,
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  foregroundColor: Colors.white,
                                  shape: const StadiumBorder(),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                ),
                                onPressed: () =>
                                    _showTopicQuiz(context, topic, lang),
                                icon: const Icon(Icons.help_outline_rounded,
                                    size: 16),
                                label: const Text('Quiz'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            topic.getDesc(lang),
                            style: TextStyle(fontSize: 13, color: textMuted),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final String code;
  final String currentLang;
  final ProgressProvider progress;

  const _LangChip(this.label, this.code, this.currentLang, this.progress);

  @override
  Widget build(BuildContext context) {
    final selected = code == currentLang;
    return GestureDetector(
      onTap: () => progress.setLanguage(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F92CA) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
