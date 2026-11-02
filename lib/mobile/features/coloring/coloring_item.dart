import 'package:flutter/material.dart';

/// One coloring-book page: a title, the outline artwork asset, and a
/// pastel card background/accent color used on the picker grid.
class ColoringItem {
  final String id;
  final String title;
  final String assetPath; // outline PNG: dark lines, white/transparent fill
  final Color bgColor;
  final Color accentColor;

  const ColoringItem({
    required this.id,
    required this.title,
    required this.assetPath,
    required this.bgColor,
    required this.accentColor,
  });
}

/// Edit this list to add/remove coloring pages. Each [assetPath] must be
/// a line-art PNG (dark outline, light/white enclosed regions) added to
/// pubspec.yaml under assets, e.g.:
///
/// flutter:
///   assets:
///     - assets/images/coloring/
const List<ColoringItem> kColoringItems = [
  ColoringItem(
    id: 'unicorn',
    title: 'Unicorn',
    assetPath: 'assets/images/coloring/unicorne.png',
    bgColor: Color(0xFFFCE4EC), // rose
    accentColor: Color(0xFFE0507B),
  ),
  ColoringItem(
    id: 'dinosaur',
    title: 'Dinosaur',
    assetPath: 'assets/images/coloring/dinador.png',
    bgColor: Color(0xFFE2F7E6), // vert
    accentColor: Color(0xFF35B24A),
  ),
  ColoringItem(
    id: 'dog',
    title: 'Puppy',
    assetPath: 'assets/images/coloring/puppy.png',
    bgColor: Color(0xFFF6EBDD), // beige / brun
    accentColor: Color(0xFFB5793B),
  ),
  ColoringItem(
    id: 'mermaid',
    title: 'Mermaid',
    assetPath: 'assets/images/coloring/mermaid.jpg',
    bgColor: Color(0xFFE7E4FB), // violet
    accentColor: Color(0xFF8B5CF6),
  ),
  ColoringItem(
    id: 'cupcake',
    title: 'Cupcake',
    assetPath: 'assets/images/coloring/cupcake.jpeg',
    bgColor: Color(0xFFFFE8E0), // corail
    accentColor: Color(0xFFFF7F6B),
  ),
  ColoringItem(
    id: 'car',
    title: 'Car',
    assetPath: 'assets/images/coloring/car.jpeg',
    bgColor: Color(0xFFE1F3FB), // bleu ciel
    accentColor: Color(0xFF3AAAE0),
  ),
  ColoringItem(
    id: 'Cats',
    title: 'Cats',
    assetPath: 'assets/images/coloring/Cats.png',
    bgColor: Color(0xFFFFE9D6), // orange doux
    accentColor: Color(0xFFF28C28),
  ),
  ColoringItem(
    id: 'Duck',
    title: 'Duck',
    assetPath: 'assets/images/coloring/Duck.png',
    bgColor: Color(0xFFFFF6BF), // jaune citron
    accentColor: Color(0xFFF2C200),
  ),
  ColoringItem(
    id: 'HotAirBalloons',
    title: 'HotAirBalloons',
    assetPath: 'assets/images/coloring/HotAirBalloons.png',
    bgColor: Color(0xFFE4E9FF), // indigo clair
    accentColor: Color(0xFF4F6BED),
  ),
  ColoringItem(
    id: 'OceanAnimals',
    title: 'OceanAnimals',
    assetPath: 'assets/images/coloring/OceanAnimals.png',
    bgColor: Color(0xFFD8F5F2), // turquoise
    accentColor: Color(0xFF17A398),
  ),
  ColoringItem(
    id: 'Turtle',
    title: 'Turtle',
    assetPath: 'assets/images/coloring/Turtle.png',
    bgColor: Color(0xFFEAF6D2), // vert lime
    accentColor: Color(0xFF7CB518),
  ),
];