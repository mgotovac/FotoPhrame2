import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../../../providers/slideshow_provider.dart';
import '../../../providers/volume_provider.dart';

class VideoDisplay extends StatefulWidget {
  final String filePath;

  const VideoDisplay({super.key, required this.filePath});

  @override
  State<VideoDisplay> createState() => _VideoDisplayState();
}

class _VideoDisplayState extends State<VideoDisplay> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _showControls = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _controller = VideoPlayerController.file(File(widget.filePath));
    try {
      await _controller.initialize();
      if (!mounted) return;
      // Start muted
      await _controller.setVolume(0.0);
      await _controller.play();

      _controller.addListener(_onPlayerUpdate);

      Provider.of<SlideshowProvider>(context, listen: false)
          .setVideoPlaying(true);

      setState(() => _initialized = true);
    } catch (e) {
      setState(() => _hasError = true);
    }
  }

  void _onPlayerUpdate() {
    if (!mounted) return;

    if (_controller.value.position >= _controller.value.duration &&
        _controller.value.duration > Duration.zero) {
      final slideshow =
          Provider.of<SlideshowProvider>(context, listen: false);
      slideshow.onVideoCompleted();
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _showControls = false);
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlayerUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off, color: Colors.white54, size: 64),
              SizedBox(height: 16),
              Text('Failed to play video',
                  style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
    }

    if (!_initialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white54),
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),
            if (_showControls) _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Consumer<VolumeProvider>(
      builder: (context, volumeProvider, _) {
        return Positioned(
          bottom: 40,
          left: 40,
          right: 40,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    volumeProvider.isMuted
                        ? Icons.volume_off
                        : Icons.volume_up,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    await volumeProvider.toggleMute();
                    await _controller.setVolume(
                        volumeProvider.isMuted ? 0.0 : volumeProvider.volume);
                  },
                ),
                Expanded(
                  child: Slider(
                    value: volumeProvider.volume,
                    onChanged: (value) async {
                      await volumeProvider.setVolume(value);
                      await _controller.setVolume(value);
                    },
                    activeColor: Colors.white,
                    inactiveColor: Colors.white24,
                  ),
                ),
                // Video progress
                Text(
                  _formatDuration(_controller.value.position),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
