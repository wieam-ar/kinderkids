class RewardItem {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final int starPrice;
  final String category; // 'avatar', 'costume', 'theme', 'sticker'
  final bool isUnlocked;
  final bool isEquipped;

  const RewardItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.starPrice,
    required this.category,
    this.isUnlocked = false,
    this.isEquipped = false,
  });

  RewardItem copyWith({
    bool? isUnlocked,
    bool? isEquipped,
  }) {
    return RewardItem(
      id: id,
      title: title,
      subtitle: subtitle,
      emoji: emoji,
      starPrice: starPrice,
      category: category,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isEquipped: isEquipped ?? this.isEquipped,
    );
  }
}

final List<RewardItem> defaultShopItems = [
  const RewardItem(
    id: 'avatar_lion',
    title: 'Explorer Lion',
    subtitle: 'Brave jungle king',
    emoji: '🦁',
    starPrice: 0,
    category: 'avatar',
    isUnlocked: true,
    isEquipped: true,
  ),
  const RewardItem(
    id: 'avatar_panda',
    title: 'Friendly Panda',
    subtitle: 'Loves bamboo and dancing',
    emoji: '🐼',
    starPrice: 15,
    category: 'avatar',
  ),
  const RewardItem(
    id: 'avatar_fox',
    title: 'Clever Fox',
    subtitle: 'Super smart explorer',
    emoji: '🦊',
    starPrice: 20,
    category: 'avatar',
  ),
  const RewardItem(
    id: 'avatar_unicorn',
    title: 'Magic Unicorn',
    subtitle: 'Rainbow sparkles!',
    emoji: '🦄',
    starPrice: 30,
    category: 'avatar',
  ),
  const RewardItem(
    id: 'avatar_robot',
    title: 'Robo Buddy',
    subtitle: 'Future technology pal',
    emoji: '🤖',
    starPrice: 35,
    category: 'avatar',
  ),
  const RewardItem(
    id: 'costume_crown',
    title: 'Golden Crown',
    subtitle: 'Fit for a royal explorer',
    emoji: '👑',
    starPrice: 10,
    category: 'costume',
  ),
  const RewardItem(
    id: 'costume_glasses',
    title: 'Cool Sunglasses',
    subtitle: 'Looking stylish!',
    emoji: '🕶️',
    starPrice: 12,
    category: 'costume',
  ),
  const RewardItem(
    id: 'costume_wizard',
    title: 'Wizard Hat',
    subtitle: 'Magical powers unlocked',
    emoji: '🧙‍♂️',
    starPrice: 25,
    category: 'costume',
  ),
  const RewardItem(
    id: 'theme_safari',
    title: 'Safari Nature',
    subtitle: 'Sunny trees and savannah',
    emoji: '🌴',
    starPrice: 0,
    category: 'theme',
    isUnlocked: true,
    isEquipped: true,
  ),
  const RewardItem(
    id: 'theme_space',
    title: 'Cosmic Galaxy',
    subtitle: 'Stars, planets and rockets',
    emoji: '🚀',
    starPrice: 25,
    category: 'theme',
  ),
  const RewardItem(
    id: 'theme_underwater',
    title: 'Ocean Deep',
    subtitle: 'Bubbles and colorful coral',
    emoji: '🐠',
    starPrice: 30,
    category: 'theme',
  ),
];
