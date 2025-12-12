import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:io';
import 'dart:async';

class VideoPlayerScreen extends StatefulWidget {
  final File videoFile;
  final String videoTitle;

  const VideoPlayerScreen({
    super.key,
    required this.videoFile,
    required this.videoTitle,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showControls = true;
  bool _isFullScreen = false;
  Timer? _hideControlsTimer;
  double _playbackSpeed = 1.0;
  double _volume = 1.0;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _controller = VideoPlayerController.file(widget.videoFile);
    await _controller.initialize();
    _controller.addListener(_videoListener);
    setState(() {
      _isInitialized = true;
    });
    _controller.play();
    _startHideControlsTimer();
  }

  void _videoListener() {
    if (mounted) {
      setState(() {});
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    _startHideControlsTimer();
  }

  void _seekForward() {
    final newPosition =
        _controller.value.position + const Duration(seconds: 10);
    _controller.seekTo(newPosition);
    _startHideControlsTimer();
  }

  void _seekBackward() {
    final newPosition =
        _controller.value.position - const Duration(seconds: 10);
    _controller.seekTo(newPosition);
    _startHideControlsTimer();
  }

  void _setPlaybackSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    _controller.setPlaybackSpeed(speed);
    _startHideControlsTimer();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      if (_isMuted) {
        _volume = _controller.value.volume;
        _controller.setVolume(0);
      } else {
        _controller.setVolume(_volume);
      }
    });
    _startHideControlsTimer();
  }

  void _setVolume(double volume) {
    setState(() {
      _volume = volume;
      _isMuted = volume == 0;
    });
    _controller.setVolume(volume);
    _startHideControlsTimer();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  Future<void> _shareVideo() async {
    try {
      await Share.shareXFiles([
        XFile(widget.videoFile.path),
      ], text: 'Check out this video: ${widget.videoTitle}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing video: $e')));
      }
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _showControls
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                widget.videoTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: _shareVideo,
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  color: Colors.grey.shade900,
                  onSelected: (value) {
                    if (value == 'speed') {
                      _showSpeedDialog();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'speed',
                      child: Row(
                        children: [
                          Icon(Icons.speed, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'Playback Speed',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
          : null,
      body: _isInitialized
          ? GestureDetector(
              onTap: _toggleControls,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Video Player
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ),

                  // Controls Overlay
                  if (_showControls)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          const Spacer(),

                          // Main Controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Rewind 10s
                              _buildControlButton(
                                icon: Icons.replay_10,
                                onPressed: _seekBackward,
                                size: 40,
                              ),
                              const SizedBox(width: 20),

                              // Play/Pause
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.orange.withOpacity(0.8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.5),
                                      blurRadius: 15,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    _controller.value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                  onPressed: _togglePlayPause,
                                  iconSize: 50,
                                  padding: const EdgeInsets.all(15),
                                ),
                              ),
                              const SizedBox(width: 20),

                              // Forward 10s
                              _buildControlButton(
                                icon: Icons.forward_10,
                                onPressed: _seekForward,
                                size: 40,
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Progress Bar and Time
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                // Progress Slider
                                VideoProgressIndicator(
                                  _controller,
                                  allowScrubbing: true,
                                  colors: VideoProgressColors(
                                    playedColor: Colors.orange,
                                    bufferedColor: Colors.grey.shade600,
                                    backgroundColor: Colors.grey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Time and Volume
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Current Time / Total Time
                                    Text(
                                      '${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),

                                    // Volume Control
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            _isMuted
                                                ? Icons.volume_off
                                                : Icons.volume_up,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          onPressed: _toggleMute,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 100,
                                          child: Slider(
                                            value: _isMuted ? 0 : _volume,
                                            min: 0,
                                            max: 1,
                                            activeColor: Colors.deepPurple,
                                            inactiveColor: Colors.grey.shade700,
                                            onChanged: _setVolume,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Bottom Controls
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Playback Speed
                                _buildBottomControl(
                                  icon: Icons.speed,
                                  label: '${_playbackSpeed}x',
                                  onTap: _showSpeedDialog,
                                ),

                                // Fullscreen
                                _buildBottomControl(
                                  icon: _isFullScreen
                                      ? Icons.fullscreen_exit
                                      : Icons.fullscreen,
                                  label: 'Fullscreen',
                                  onTap: () {
                                    setState(() {
                                      _isFullScreen = !_isFullScreen;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            )
          : const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 30,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: size),
        onPressed: onPressed,
        iconSize: size + 10,
        padding: const EdgeInsets.all(10),
      ),
    );
  }

  Widget _buildBottomControl({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Playback Speed',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSpeedOption(0.25, '0.25x'),
            _buildSpeedOption(0.5, '0.5x'),
            _buildSpeedOption(0.75, '0.75x'),
            _buildSpeedOption(1.0, '1.0x (Normal)'),
            _buildSpeedOption(1.25, '1.25x'),
            _buildSpeedOption(1.5, '1.5x'),
            _buildSpeedOption(2.0, '2.0x'),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedOption(double speed, String label) {
    final isSelected = _playbackSpeed == speed;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.deepPurple : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: Colors.deepPurple)
          : null,
      onTap: () {
        _setPlaybackSpeed(speed);
        Navigator.of(context).pop();
      },
    );
  }
}
