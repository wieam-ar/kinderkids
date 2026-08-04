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
    bgColor: Color(0xFFFCE4EC),
    accentColor: Color(0xFFE0507B),
  ),
  ColoringItem(
    id: 'dinosaur',
    title: 'Dinosaur',
    assetPath: 'assets/images/coloring/dinador.png',
    bgColor: Color(0xFFE2F7E6),
    accentColor: Color(0xFF35B24A),
  ),
  ColoringItem(
    id: 'dog',
    title: 'Puppy',
    assetPath: 'assets/images/coloring/puppy.png',
    bgColor: Color(0xFFFDF3D9),
    accentColor: Color(0xFFE0A800),
  ),
  ColoringItem(
    id: 'mermaid',
    title: 'Mermaid',
    assetPath: 'assets/images/coloring/mermaid.jpg',
    bgColor: Color(0xFFE7E4FB),
    accentColor: Color(0xFF8B5CF6),
  ),
  ColoringItem(
    id: 'cupcake',
    title: 'Cupcake',
    assetPath: 'assets/images/coloring/cupcake.jpeg',
    bgColor: Color(0xFFFFE7EC),
    accentColor: Color(0xFFF25C7A),
  ),
  ColoringItem(
    id: 'car',
    title: 'Car',
    assetPath: 'assets/images/coloring/car.jpeg',
    bgColor: Color(0xFFE1F3FB),
    accentColor: Color(0xFF3AAAE0),
  ),
];