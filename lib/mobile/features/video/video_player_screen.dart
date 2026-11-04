import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../../data/models/video/video.dart';

TextStyle _fredoka({
  double size = 15,
  Color color = Colors.white,
  FontWeight weight = FontWeight.w700,
}) =>
    GoogleFonts.fredoka(fontSize: size, fontWeight: weight, color: color);

/// Player for a single video, made for kids:
/// big controls, auto-hide, ±10s, replay, fullscreen, friendly errors.
/// Video file lives in assets/videos/<file>.
class VideoPlayerScreen extends StatefulWidget {
  final VideoItem video;

  /// called once when 90% of the video has been watched
  final VoidCallback? onWatched;

  const VideoPlayerScreen({super.key, required this.video, this.onWatched});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with WidgetsBindingObserver {
  static const Color accent = Color(0xFFE0507B);

  late final VideoPlayerController _controller;
  Timer? _hideTimer;

  bool _initialized = false;
  bool _error = false;
  bool _showControls = true;
  bool _fullscreen = false;
  bool _watchedFired = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = VideoPlayerController.asset(
      'assets/videos/${widget.video.file}',
    );
    _controller.addListener(_onTick);
    _init();
  }

  Future<void> _init() async {
    try {
      await _controller.initialize();
      if (!mounted) return;
      setState(() => _initialized = true);
      await _controller.play();
      _restartHideTimer();
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  void _onTick() {
    final v = _controller.value;
    if (v.hasError && !_error && mounted) {
      setState(() => _error = true);
      return;
    }
    if (!_watchedFired &&
        v.isInitialized &&
        v.duration.inMilliseconds > 0 &&
        v.position.inMilliseconds >= v.duration.inMilliseconds * 0.9) {
      _watchedFired = true;
      widget.onWatched?.call();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _initialized) {
      _controller.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    _controller.removeListener(_onTick);
    _controller.dispose();
    // restore orientation + system UI
    SystemChrome.setPreferredOrientations(
      const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ---------------- Controls logic ----------------

  bool get _ended {
    final v = _controller.value;
    return v.isInitialized &&
        v.duration.inMilliseconds > 0 &&
        v.position.inMilliseconds >= v.duration.inMilliseconds - 300 &&
        !v.isPlaying;
  }

  void _restartHideTimer() {
    _hideTimer?.cancel();
    if (!_controller.value.isPlaying) return;
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _restartHideTimer();
  }

  Future<void> _togglePlayPause() async {
    HapticFeedback.selectionClick();
    if (_ended) {
      await _controller.seekTo(Duration.zero);
      await _controller.play();
    } else if (_controller.value.isPlaying) {
      await _controller.pause();
      _hideTimer?.cancel();
    } else {
      await _controller.play();
    }
    if (!mounted) return;
    setState(() => _showControls = true);
    _restartHideTimer();
  }

  Future<void> _seekBy(int seconds) async {
    HapticFeedback.selectionClick();
    final v = _controller.value;
    var target = v.position + Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    if (target > v.duration) target = v.duration;
    await _controller.seekTo(target);
    _restartHideTimer();
  }

  Future<void> _toggleFullscreen() async {
    HapticFeedback.selectionClick();
    final next = !_fullscreen;
    setState(() => _fullscreen = next);
    if (next) {
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _restartHideTimer();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF14121F),
        body: SafeArea(
          child: _error ? _buildError() : _buildPlayer(),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😿', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            Text(
              "Oops! This video can't play right now",
              textAlign: TextAlign.center,
              style: _fredoka(size: 20, weight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            _ChunkyButton(
              label: 'Go back',
              icon: Icons.arrow_back_rounded,
              color: accent,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Video (tap = show/hide controls)
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _initialized ? _toggleControls : null,
            child: Center(
              child: _initialized
                  ? Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_fullscreen ? 0 : 24),
                ),
                clipBehavior: Clip.antiAlias,
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              )
                  : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                      color: accent, strokeWidth: 5),
                  const SizedBox(height: 18),
                  Text(
                    'Getting your video ready... 🍿',
                    style: _fredoka(
                        size: 16,
                        color: Colors.white70,
                        weight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Controls overlay
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !_showControls,
            child: AnimatedOpacity(
              opacity: _showControls ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: _controller,
                builder: (_, value, __) => Column(
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: _initialized
                          ? _buildCenterControls(value)
                          : const SizedBox.shrink(),
                    ),
                    if (_initialized) _buildBottomBar(value),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          _RoundButton(
            icon: Icons.arrow_back_ios_new_rounded,
            size: 48,
            iconSize: 20,
            color: Colors.white,
            iconColor: const Color(0xFF213238),
            onTap: () => Navigator.of(context).pop(),
            semantics: 'Back',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: accent.withOpacity(0.8), width: 2.5),
              ),
              child: Text(
                '${widget.video.emoji}  ${widget.video.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _fredoka(size: 17, weight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterControls(VideoPlayerValue value) {
    final ended = _ended;
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RoundButton(
            icon: Icons.replay_10_rounded,
            size: 58,
            iconSize: 30,
            color: const Color(0xFF7B61FF),
            onTap: () => _seekBy(-10),
            semantics: 'Back 10 seconds',
          ),
          const SizedBox(width: 22),
          _RoundButton(
            icon: ended
                ? Icons.replay_rounded
                : value.isPlaying
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            size: 84,
            iconSize: 50,
            color: accent,
            onTap: _togglePlayPause,
            semantics: ended
                ? 'Replay'
                : value.isPlaying
                ? 'Pause'
                : 'Play',
          ),
          const SizedBox(width: 22),
          _RoundButton(
            icon: Icons.forward_10_rounded,
            size: 58,
            iconSize: 30,
            color: const Color(0xFF7B61FF),
            onTap: () => _seekBy(10),
            semantics: 'Forward 10 seconds',
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(VideoPlayerValue value) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: Row(
          children: [
            Text(
              _formatDuration(value.position),
              style: _fredoka(size: 13, weight: FontWeight.w600),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  colors: const VideoProgressColors(
                    playedColor: accent,
                    bufferedColor: Colors.white24,
                    backgroundColor: Colors.white12,
                  ),
                ),
              ),
            ),
            Text(
              _formatDuration(value.duration),
              style: _fredoka(
                  size: 13, color: Colors.white70, weight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: _fullscreen ? 'Exit fullscreen' : 'Fullscreen',
              onPressed: _toggleFullscreen,
              icon: Icon(
                _fullscreen
                    ? Icons.fullscreen_exit_rounded
                    : Icons.fullscreen_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- buttons

/// Round 3D button that sinks when pressed.
class _RoundButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;
  final String semantics;

  const _RoundButton({
    required this.icon,
    required this.size,
    required this.iconSize,
    required this.onTap,
    required this.semantics,
    required this.color,
    this.iconColor = Colors.white,
  });

  @override
  State<_RoundButton> createState() => _RoundButtonState();
}

class _RoundButtonState extends State<_RoundButton> {
  bool _down = false;

  Color _darken(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - 0.18).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    const depth = 5.0;
    final offset = _down ? 2.0 : depth;

    return Semantics(
      button: true,
      label: widget.semantics,
      child: GestureDetector(
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
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              border: Border.all(
                  color: Colors.white.withOpacity(0.55), width: 3),
              boxShadow: [
                BoxShadow(
                  color: _darken(widget.color),
                  offset: Offset(0, offset),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Icon(widget.icon,
                color: widget.iconColor, size: widget.iconSize),
          ),
        ),
      ),
    );
  }
}

class _ChunkyButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ChunkyButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<_ChunkyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const depth = 6.0;
    final offset = _down ? 2.0 : depth;
    final hsl = HSLColor.fromColor(widget.color);
    final shadow =
    hsl.withLightness((hsl.lightness - 0.18).clamp(0.0, 1.0)).toColor();

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
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.55), width: 3),
            boxShadow: [
              BoxShadow(
                color: shadow,
                offset: Offset(0, offset),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(widget.label,
                  style: _fredoka(size: 17, weight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}