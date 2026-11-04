import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/ui/kid_ui.dart';
import '../../data/models/music/music.dart';
import '../../data/providers/progress_provider.dart';

TextStyle _fredoka({
  double size = 15,
  Color color = KidColors.textDark,
  FontWeight weight = FontWeight.w700,
}) =>
    GoogleFonts.fredoka(fontSize: size, fontWeight: weight, color: color);

/// Music activity screen. Tap any song to play it; a mini-player pinned at
/// the bottom shows progress and lets the child skip songs.
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

  /// Each unique song counts once toward the daily music challenge.
  final Set<String> _playedSongTitles = {};

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

    if (!_playedSongTitles.contains(song.title)) {
      _playedSongTitles.add(song.title);
      final progress = Provider.of<ProgressProvider>(context, listen: false);
      progress.addStars(1);
      progress.incrementChallengeProgress('music');
    }
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
    _playSong((_currentIndex! + 1) % songs.length);
  }

  void _playPrevious() {
    if (_currentIndex == null) return;
    _playSong((_currentIndex! - 1 + songs.length) % songs.length);
  }

  Future<void> _seek(double value) async {
    await _player.seek(Duration(milliseconds: value.toInt()));
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString();
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
      body: KidBackground(
        colors: const [Color(0xFFD5F5DF), KidColors.cream],
        child: SafeArea(
          child: Column(
            children: [
              const KidHeader(
                title: 'Music Time',
                emoji: '🎵',
                subtitle: 'Tap a song to play it',
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                  itemCount: songs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    final isCurrent = _currentIndex == index;
                    final colors = song.colors.map((c) => Color(c)).toList();

                    return _SongTile(
                      song: song,
                      colors: colors,
                      isCurrent: isCurrent,
                      isPlaying: isCurrent && _isPlaying,
                      onTap: () =>
                      isCurrent ? _togglePlayPause() : _playSong(index),
                    );
                  },
                ),
              ),
              if (hasCurrent)
                _MiniPlayer(
                  song: songs[_currentIndex!],
                  isPlaying: _isPlaying,
                  position: _position,
                  duration: _duration,
                  onPlayPause: _togglePlayPause,
                  onNext: _playNext,
                  onPrevious: _playPrevious,
                  onSeek: _seek,
                  formatDuration: _formatDuration,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- song tile

class _SongTile extends StatefulWidget {
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
  State<_SongTile> createState() => _SongTileState();
}

class _SongTileState extends State<_SongTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const depth = 6.0;
    final accent = widget.colors.last;
    final offset = _down ? 2.0 : depth;

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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isCurrent
                ? KidColors.lighten(accent, 0.38)
                : Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: accent.withOpacity(widget.isCurrent ? 0.9 : 0.35),
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
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: widget.colors.length > 1
                        ? widget.colors
                        : [widget.colors.first, widget.colors.first],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.7), width: 3),
                ),
                child: Text(widget.song.emoji,
                    style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _fredoka(size: 17, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.song.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _fredoka(
                        size: 13,
                        color: KidColors.textMuted,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                  boxShadow: [
                    BoxShadow(
                      color: KidColors.darken(accent),
                      offset: const Offset(0, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  widget.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ mini player

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
    final accent = colors.last;
    final double maxMs =
    duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1;
    final double posMs =
    position.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: KidCard(
        accent: accent,
        radius: 30,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 10,
                trackShape: const RoundedRectSliderTrackShape(),
                thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 10),
                overlayShape:
                const RoundSliderOverlayShape(overlayRadius: 18),
                activeTrackColor: accent,
                inactiveTrackColor: accent.withOpacity(0.2),
                thumbColor: Colors.white,
              ),
              child: Slider(value: posMs, max: maxMs, onChanged: onSeek),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatDuration(position),
                    style: _fredoka(
                        size: 12,
                        color: KidColors.textMuted,
                        weight: FontWeight.w600)),
                Text(formatDuration(duration),
                    style: _fredoka(
                        size: 12,
                        color: KidColors.textMuted,
                        weight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(song.emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _fredoka(size: 16, weight: FontWeight.w800),
                  ),
                ),
                KidRoundButton(
                  icon: Icons.skip_previous_rounded,
                  color: accent,
                  onTap: onPrevious,
                ),
                const SizedBox(width: 8),
                KidRoundButton(
                  icon: isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: KidColors.green,
                  onTap: onPlayPause,
                ),
                const SizedBox(width: 8),
                KidRoundButton(
                  icon: Icons.skip_next_rounded,
                  color: accent,
                  onTap: onNext,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}