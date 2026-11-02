import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ui/app_ui.dart';
import '../../data/providers/progress_provider.dart';

class ArtworkGalleryScreen extends StatelessWidget {
  const ArtworkGalleryScreen({super.key});

  Future<void> _confirmDelete(
      BuildContext context,
      ProgressProvider progress,
      String path,
      ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete this drawing?'),
        content: const Text("You won't be able to get it back."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Keep it'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await progress.removeArtwork(path);
    showAppSnack(messenger, '🗑️ Drawing deleted');
  }

  void _openViewer(BuildContext context, String path, int number) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ArtworkViewer(path: path, number: number),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final savedPaths = progress.profile.savedArtworkPaths;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildAppBar('My Gallery 🖼️'),
      body: savedPaths.isEmpty
          ? const EmptyState(
        emoji: '🎨',
        title: 'No saved drawings yet!',
        message: 'Go to Creative Studio and draw something awesome!',
      )
          : GridView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: savedPaths.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.9,
        ),
        itemBuilder: (context, index) {
          final path = savedPaths[index];
          return _ArtworkCard(
            path: path,
            number: index + 1,
            onOpen: () => _openViewer(context, path, index + 1),
            onDelete: () => _confirmDelete(context, progress, path),
          );
        },
      ),
    );
  }
}

/// Shows the saved image when it can be read, otherwise a brush placeholder.
Widget _artworkImage(String path, {BoxFit fit = BoxFit.cover, int? cacheWidth}) {
  final placeholder = Center(
    child: Icon(Icons.brush_rounded, size: 48, color: Colors.blue.shade300),
  );
  if (kIsWeb) return placeholder;
  return Image.file(
    File(path),
    fit: fit,
    cacheWidth: cacheWidth,
    errorBuilder: (_, __, ___) => placeholder,
  );
}

class _ArtworkCard extends StatelessWidget {
  final String path;
  final int number;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _ArtworkCard({
    required this.path,
    required this.number,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.soft(),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(tag: path, child: _artworkImage(path, cacheWidth: 500)),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.45),
                      ],
                    ),
                  ),
                  child: Text(
                    'Drawing #$number',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  color: Colors.white.withOpacity(0.9),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onDelete,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.delete_rounded,
                        color: AppColors.danger,
                        size: 20,
                      ),
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
}

class _ArtworkViewer extends StatelessWidget {
  final String path;
  final int number;

  const _ArtworkViewer({required this.path, required this.number});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Drawing #$number'),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Hero(
            tag: path,
            child: _artworkImage(path, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}