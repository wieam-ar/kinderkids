class OnboardingItem {
  final String title;
  final String description;
  final String lottiePath;

  const OnboardingItem({
    required this.title,
    required this.description,
    required this.lottiePath,
  });
}

const List<OnboardingItem> onboardingItems = [
  OnboardingItem(
    title: "Let's Learn",
    description:
    "Welcome to the adventure kids world\nwhere you can play, learn and listen to\nyour favorite music",
    lottiePath: 'assets/loties/panda_waving.json',
  ),
  OnboardingItem(
    title: "Let's Play",
    description:
    "Welcome to the adventure kids world\nwhere you can play, learn and listen to\nyour favorite music",
    lottiePath: 'assets/loties/panda_talk.json',
  ),
  OnboardingItem(
    title: "Let's Dance",
    description:
    "Welcome to the adventure kids world\nwhere you can play, learn and listen to\nyour favorite music",
    lottiePath: 'assets/loties/lazy_panda.json',
  ),
];