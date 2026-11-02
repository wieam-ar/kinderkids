import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_ui.dart';
import '../../data/models/reward_item_model.dart';
import '../../data/providers/progress_provider.dart';

class RewardShopScreen extends StatelessWidget {
  const RewardShopScreen({super.key});

  Future<bool> _confirmPurchase(BuildContext context, RewardItem item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 8),
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Buy and equip it for ⭐ ${item.starPrice}?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.star,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text('Buy ⭐ ${item.starPrice}'),
          ),
        ],
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
      backgroundColor: AppColors.background,
      appBar: buildAppBar(
        'Reward Shop 🏆',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: StarsChip(stars: stars)),
          ),
        ],
      ),
      body: items.isEmpty
          ? const EmptyState(
        emoji: '🛍️',
        title: 'The shop is empty',
        message: 'New rewards are coming soon!',
      )
          : GridView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.8,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return _ShopCard(
            item: item,
            canAfford: stars >= item.starPrice,
            onTap: () => _handleTap(context, progress, item),
          );
        },
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  final RewardItem item;
  final bool canAfford;
  final VoidCallback onTap;

  const _ShopCard({
    required this.item,
    required this.canAfford,
    required this.onTap,
  });

  Color get _buttonColor {
    if (item.isEquipped) return AppColors.success;
    if (item.isUnlocked) return AppColors.primary;
    return canAfford ? AppColors.star : Colors.grey.shade400;
  }

  String get _buttonLabel {
    if (item.isEquipped) return 'Equipped ✓';
    if (item.isUnlocked) return 'Equip';
    return '⭐ ${item.starPrice}';
  }

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: item.isEquipped ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: item.isEquipped ? AppColors.success : AppColors.border,
            width: item.isEquipped ? 2 : 1,
          ),
          boxShadow: AppShadows.soft(0.05),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  FittedBox(
                    child: Opacity(
                      opacity: item.isUnlocked || canAfford ? 1 : 0.55,
                      child: Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 56),
                      ),
                    ),
                  ),
                  if (!item.isUnlocked)
                    const Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(
                        Icons.lock_rounded,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _buttonColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                _buttonLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}