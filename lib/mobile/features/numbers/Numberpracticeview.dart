import 'package:flutter/material.dart';
import '../../data/models/number/number.dart';
import 'Numbertracescreen.dart';

class NumberPracticeView extends StatefulWidget {
  final List<NumberItem> numbers;
  final bool isArabic;

  const NumberPracticeView({
    super.key,
    required this.numbers,
    required this.isArabic,
  });

  @override
  State<NumberPracticeView> createState() => _NumberPracticeViewState();
}

class _NumberPracticeViewState extends State<NumberPracticeView> {
  static const Color primaryBlue = Color(0xFF0F92CA);
  static const Color primaryBlueDark = Color(0xFF0B6E9B);

  final Set<int> _completed = {};

  Future<void> _openTrace(NumberItem item, int index) async {
    final success = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NumberTraceScreen(
          item: item,
          isArabic: widget.isArabic,
        ),
      ),
    );
    if (success == true && mounted) {
      setState(() => _completed.add(index));
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.numbers.length;
    final progress = total == 0 ? 0.0 : _completed.length / total;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isArabic ? 'تقدمك' : 'Your progress',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF213238),
                    ),
                  ),
                  Text(
                    '${_completed.length}/$total',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: primaryBlueDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE4EEF2),
                  valueColor: const AlwaysStoppedAnimation(primaryBlue),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            itemCount: total,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              final item = widget.numbers[index];
              final done = _completed.contains(index);
              return _NumberCard(
                item: item,
                done: done,
                onTap: () => _openTrace(item, index),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NumberCard extends StatelessWidget {
  final NumberItem item;
  final bool done;
  final VoidCallback onTap;

  const _NumberCard({
    required this.item,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: done ? const Color(0xFFE2F7E6) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: done
                  ? const Color(0xFF35B24A)
                  : const Color(0xFFE4EEF2),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.symbol,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF213238),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.word,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7C8C93),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (done)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(Icons.check_circle_rounded,
                      color: Color(0xFF35B24A), size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}