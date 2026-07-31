import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../data/models/music/music.dart';

/// Music activity screen. Tap any song to play it; a small mini-player
/// pinned at the bottom shows progress and lets the child skip to the
/// next/previous song without leaving the list.
class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final AudioPlayer _player = AudioPlayer();

  int? _currentIndex;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  static const Color primaryBlue = Color(0xFF0F92CA);
  static const Color textDark = Color(0xFF213238);
  static const Color textMuted = Color(0xFF7C8C93);
  static const Color bgColor = Color(0xFFF7FAFC);

  @override
  void initState() {
    super.initState();

    _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state == PlayerState.playing);
    });

    _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d);
    });

    _player.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });

    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      _playNext();
    });
  }

  Future<void> _playSong(int index) async {
    final song = songs[index];
    setState(() {
      _currentIndex = index;
      _position = Duration.zero;
    });
    await _player.stop();
    await _player.play(AssetSource('audios/${song.file}'));
  }

  Future<void> _togglePlayPause() async {
    if (_currentIndex == null) {
      await _playSong(0);
      return;
    }
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.resume();
    }
  }

  void _playNext() {
    if (_currentIndex == null) return;
    final next = (_currentIndex! + 1) % songs.length;
    _playSong(next);
  }

  void _playPrevious() {
    if (_currentIndex == null) return;
    final prev = (_currentIndex! - 1 + songs.length) % songs.length;
    _playSong(prev);
  }

  Future<void> _seek(double value) async {
    final newPosition = Duration(milliseconds: value.toInt());
    await _player.seek(newPosition);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCurrent = _currentIndex != null;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // --- Top bar ---------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: textDark, size: 18),
                  ),
                  const Expanded(
                    child: Text(
                      '🎵 Music Time',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // --- Song list ---------------------------------------------------
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(
                    20, 16, 20, hasCurrent ? 120 : 24),
                itemCount: songs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final song = songs[index];
                  final bool isCurrent = _currentIndex == index;
                  final bool isPlayingThis = isCurrent && _isPlaying;
                  final colors = song.colors.map((c) => Color(c)).toList();

                  return _SongTile(
                    song: song,
                    colors: colors,
                    isCurrent: isCurrent,
                    isPlaying: isPlayingThis,
                    onTap: () => isCurrent
                        ? _togglePlayPause()
                        : _playSong(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: hasCurrent
          ? _MiniPlayer(
        song: songs[_currentIndex!],
        isPlaying: _isPlaying,
        position: _position,
        duration: _duration,
        onPlayPause: _togglePlayPause,
        onNext: _playNext,
        onPrevious: _playPrevious,
        onSeek: _seek,
        formatDuration: _formatDuration,
      )
          : null,
    );
  }
}

class _SongTile extends StatelessWidget {
  final Song song;
  final List<Color> colors;
  final bool isCurrent;
  final bool isPlaying;
  final VoidCallback onTap;

  const _SongTile({
    required this.song,
    required this.colors,
    required this.isCurrent,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isCurrent ? colors.first.withOpacity(0.12) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCurrent
                  ? colors.last.withOpacity(0.4)
                  : const Color(0xFFEFF2F4),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.last.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(song.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: _MusicScreenState.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      song.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: _MusicScreenState.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.last,
                ),
                child: Icon(
                  isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact player pinned at the bottom of the screen while a song is
/// loaded, with a scrub bar and next/previous controls.
class _MiniPlayer extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final ValueChanged<double> onSeek;
  final String Function(Duration) formatDuration;

  const _MiniPlayer({
    required this.song,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onSeek,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    final colors = song.colors.map((c) => Color(c)).toList();
    final double maxMs = duration.inMilliseconds > 0
        ? duration.inMilliseconds.toDouble()
        : 1;
    final double posMs =
    position.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape:
                const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: colors.last,
                inactiveTrackColor: colors.last.withOpacity(0.15),
                thumbColor: colors.last,
              ),
              child: Slider(
                value: posMs,
                max: maxMs,
                onChanged: onSeek,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 0, bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatDuration(position),
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9AA6AB))),
                  Text(formatDuration(duration),
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9AA6AB))),
                ],
              ),
            ),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: colors),
                  ),
                  alignment: Alignment.center,
                  child:
                  Text(song.emoji, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF213238),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onPrevious,
                  icon: const Icon(Icons.skip_previous_rounded,
                      color: Color(0xFF213238)),
                ),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.last,
                  ),
                  child: IconButton(
                    onPressed: onPlayPause,
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onNext,
                  icon: const Icon(Icons.skip_next_rounded,
                      color: Color(0xFF213238)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}