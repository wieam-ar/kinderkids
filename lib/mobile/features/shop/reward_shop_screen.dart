import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_ui.dart';
import '../../core/ui/kid_ui.dart';
import '../../data/models/reward_item_model.dart';
import '../../data/providers/progress_provider.dart';

TextStyle _fredoka({
  double size = 15,
  Color color = KidColors.textDark,
  FontWeight weight = FontWeight.w700,
  double? height,
}) =>
    GoogleFonts.fredoka(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );

const Color _starGold = Color(0xFFFFB300);

/// Accent colours cycled across the shop cards.
const List<Color> _cardAccents = [
  Color(0xFF4FC3F7),
  Color(0xFFFFB74D),
  Color(0xFF81C784),
  Color(0xFFBA68C8),
  Color(0xFFF06292),
  Color(0xFFFFD54F),
];

class RewardShopScreen extends StatelessWidget {
  const RewardShopScreen({super.key});

  Future<bool> _confirmPurchase(BuildContext context, RewardItem item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: BoxDecoration(
            color: KidColors.cream,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _starGold, width: 4),
            boxShadow: [
              BoxShadow(
                color: _starGold.withOpacity(0.55),
                offset: const Offset(0, 8),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: _starGold.withOpacity(0.6), width: 3),
                ),
                child: Text(item.emoji, style: const TextStyle(fontSize: 52)),
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: _fredoka(size: 21, weight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Buy and equip it for ⭐ ${item.starPrice}?',
                textAlign: TextAlign.center,
                style: _fredoka(
                    size: 15,
                    color: KidColors.textMuted,
                    weight: FontWeight.w500),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _ChunkyButton(
                      label: 'Not now',
                      color: Colors.white,
                      labelColor: KidColors.textMuted,
                      shadowColor: Colors.grey.shade300,
                      onTap: () => Navigator.of(dialogCtx).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ChunkyButton(
                      label: 'Buy ⭐ ${item.starPrice}',
                      color: _starGold,
                      onTap: () => Navigator.of(dialogCtx).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  Future<void> _handleTap(
      BuildContext context,
      ProgressProvider progress,
      RewardItem item,
      ) async {
    final messenger = ScaffoldMessenger.of(context);

    if (item.isEquipped) return;

    if (!item.isUnlocked) {
      final missing = item.starPrice - progress.profile.totalStars;
      if (missing > 0) {
        showAppSnack(
          messenger,
          '⭐ You need $missing more star${missing == 1 ? '' : 's'}! '
              'Keep playing exercises!',
          color: AppColors.danger,
        );
        return;
      }
      final confirmed = await _confirmPurchase(context, item);
      if (!confirmed) return;
    }

    final success = await progress.buyAndEquipShopItem(item);
    showAppSnack(
      messenger,
      success
          ? '🎉 Equipped ${item.title}!'
          : '⭐ Need more stars! Keep playing exercises!',
      color: success ? AppColors.success : AppColors.danger,
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final items = progress.shopItems;
    final stars = progress.profile.totalStars;

    return Scaffold(
      body: KidBackground(
        colors: const [Color(0xFFFFF0C2), KidColors.cream],
        child: SafeArea(
          child: Column(
            children: [
              const KidHeader(
                title: 'Reward Shop',
                emoji: '🏆',
                subtitle: 'Spend your stars on cool stuff!',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _StarsPill(stars: stars),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const EmptyState(
                  emoji: '🛍️',
                  title: 'The shop is empty',
                  message: 'New rewards are coming soon!',
                )
                    : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                  itemCount: items.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.74,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _ShopCard(
                      item: item,
                      accent: _cardAccents[index % _cardAccents.length],
                      canAfford: stars >= item.starPrice,
                      onTap: () => _handleTap(context, progress, item),
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

// -------------------------------------------------------------- stars pill

class _StarsPill extends StatelessWidget {
  final int stars;
  const _StarsPill({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _starGold, width: 3),
        boxShadow: [
          BoxShadow(
            color: _starGold.withOpacity(0.55),
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⭐', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Text('$stars',
              style: _fredoka(
                  size: 18, color: KidColors.textDark, weight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- shop card

class _ShopCard extends StatefulWidget {
  final RewardItem item;
  final Color accent;
  final bool canAfford;
  final VoidCallback onTap;

  const _ShopCard({
    required this.item,
    required this.accent,
    required this.canAfford,
    required this.onTap,
  });

  @override
  State<_ShopCard> createState() => _ShopCardState();
}

class _ShopCardState extends State<_ShopCard> {
  bool _down = false;

  RewardItem get item => widget.item;

  Color get _buttonColor {
    if (item.isEquipped) return KidColors.green;
    if (item.isUnlocked) return widget.accent;
    return widget.canAfford ? _starGold : Colors.grey.shade400;
  }

  String get _buttonLabel {
    if (item.isEquipped) return 'Equipped ✓';
    if (item.isUnlocked) return 'Equip';
    return '⭐ ${item.starPrice}';
  }

  @override
  Widget build(BuildContext context) {
    const depth = 6.0;
    final accent = item.isEquipped ? KidColors.green : widget.accent;
    final offset = _down ? 2.0 : depth;
    final tappable = !item.isEquipped;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: tappable ? (_) => setState(() => _down = true) : null,
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: tappable ? widget.onTap : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: depth),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          transform: Matrix4.translationValues(0, depth - offset, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: item.isEquipped
                ? KidColors.lighten(accent, 0.45)
                : Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: accent.withOpacity(item.isEquipped ? 0.9 : 0.4),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.55),
                offset: Offset(0, offset),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [KidColors.lighten(accent, 0.42), Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: FittedBox(
                        child: Opacity(
                          opacity: item.isUnlocked || widget.canAfford ? 1 : 0.5,
                          child: Text(
                            item.emoji,
                            style: const TextStyle(fontSize: 56),
                          ),
                        ),
                      ),
                    ),
                    if (!item.isUnlocked)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                                color: Colors.grey.shade300, width: 2),
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            size: 14,
                            color: KidColors.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _fredoka(size: 15, weight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                item.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _fredoka(
                  size: 12,
                  color: KidColors.textMuted,
                  weight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _buttonColor,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: KidColors.darken(_buttonColor),
                      offset: const Offset(0, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  _buttonLabel,
                  style: _fredoka(
                      size: 13, color: Colors.white, weight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ dialog button

class _ChunkyButton extends StatefulWidget {
  final String label;
  final Color color;
  final Color labelColor;
  final Color? shadowColor;
  final VoidCallback onTap;

  const _ChunkyButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.labelColor = Colors.white,
    this.shadowColor,
  });

  @override
  State<_ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<_ChunkyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const depth = 5.0;
    final offset = _down ? 2.0 : depth;
    final shadow = widget.shadowColor ?? KidColors.darken(widget.color);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: depth),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          transform: Matrix4.translationValues(0, depth - offset, 0),
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(24),
            border: widget.shadowColor != null
                ? Border.all(color: widget.shadowColor!, width: 2.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: shadow,
                offset: Offset(0, offset),
                blurRadius: 0,
              ),
            ],
          ),
          child: Text(
            widget.label,
            style: _fredoka(
                size: 15, color: widget.labelColor, weight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}