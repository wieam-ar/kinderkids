import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../data/models/video/video.dart';

/// Player dyal video wa7ed, mkhdoum l'atfal:
/// controls kbar, auto-hide, ±10s, replay, fullscreen, error friendly.
/// Video f assets/videos/<file>.
class VideoPlayerScreen extends StatefulWidget {
  final VideoItem video;

  /// kat-t3ayet mra wa7da mnin t-chouf 90% men video
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
    // raje3 l'orientation w system UI
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
        backgroundColor: Colors.black,
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
            const Text('😿', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              "Oops! This video can't play right now",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Go back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
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
                  ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
                  : const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Getting your video ready... 🍿',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
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
            onTap: () => Navigator.of(context).pop(),
            semantics: 'Back',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${widget.video.emoji}  ${widget.video.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
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
            size: 56,
            iconSize: 30,
            onTap: () => _seekBy(-10),
            semantics: 'Back 10 seconds',
          ),
          const SizedBox(width: 24),
          _RoundButton(
            icon: ended
                ? Icons.replay_rounded
                : value.isPlaying
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            size: 80,
            iconSize: 48,
            filled: true,
            onTap: _togglePlayPause,
            semantics: ended
                ? 'Replay'
                : value.isPlaying
                ? 'Pause'
                : 'Play',
          ),
          const SizedBox(width: 24),
          _RoundButton(
            icon: Icons.forward_10_rounded,
            size: 56,
            iconSize: 30,
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
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              _formatDuration(value.position),
              style: const TextStyle(color: Colors.white, fontSize: 13),
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
              style: const TextStyle(color: Colors.white70, fontSize: 13),
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

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final bool filled;
  final VoidCallback onTap;
  final String semantics;

  const _RoundButton({
    required this.icon,
    required this.size,
    required this.iconSize,
    required this.onTap,
    required this.semantics,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantics,
      child: Material(
        color: filled
            ? _VideoPlayerScreenState.accent
            : Colors.black.withOpacity(0.5),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
        ),
      ),
    );
  }
}