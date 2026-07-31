import 'package:flutter/material.dart';

/// Generic screen opened when the user taps any Discover / Exercise card.
/// Each card passes its own title, icon and color so this single screen
/// can represent Story, Music, Videos, Paint, Draw, Math, Puzzle,
/// Alphabet, Numbers, etc. without duplicating a screen per activity.
class ActivityDetailScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> colors;
  final String subtitle;

  const ActivityDetailScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.colors,
    this.subtitle = 'Get ready to learn and have fun!',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Same safari themed background used on the splash/onboarding
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Soft white wash so the content stays readable over the artwork
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.65),
                    Colors.white.withOpacity(0.85),
                    Colors.white.withOpacity(0.97),
                  ],
                  stops: const [0.0, 0.4, 0.75],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Color(0xFF213238), size: 18),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: colors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colors.last.withOpacity(0.35),
                                blurRadius: 26,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Icon(icon, color: Colors.white, size: 64),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF213238),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 48),
                          child: Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF7C8C93),
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // TODO: replace with the real activity content/game
                        // for this screen (e.g. list of stories, alphabet
                        // grid...).
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}