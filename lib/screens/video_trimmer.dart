import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../utils/file_utils.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart';

class VideoCutter extends StatefulWidget {
  const VideoCutter({super.key});

  @override
  State<VideoCutter> createState() => _VideoCutterState();
}

class _VideoCutterState extends State<VideoCutter> {
  String? videoPath;
  VideoPlayerController? _playerController;
  bool _isTrimming = false;
  String _status = 'Select a video to trim';

  Duration _videoDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  Duration _startTime = Duration.zero;
  Duration _endTime = Duration.zero;
  bool _isDraggingStart = false;
  bool _isDraggingEnd = false;
  double _dragStartX = 0.0;
  double _initialStartPosition = 0.0;
  double _initialEndPosition = 0.0;

  @override
  void dispose() {
    _playerController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final hasPermission = await FileUtils.requestStoragePermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission is required'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      if (await file.exists()) {
        setState(() {
          videoPath = file.path;
          _status = 'Video selected';
        });
        await _loadVideo();
      }
    }
  }

  Future<void> _loadVideo() async {
    if (videoPath == null) return;

    _playerController?.dispose();
    _playerController = VideoPlayerController.file(File(videoPath!));

    await _playerController!.initialize();

    setState(() {
      _videoDuration = _playerController!.value.duration;
      _startTime = Duration.zero;
      _endTime = _videoDuration;
      _currentPosition = Duration.zero;
    });

    _playerController!.addListener(_videoListener);
    _playerController!.play();
  }

  void _videoListener() {
    if (!_isDraggingStart && !_isDraggingEnd && mounted) {
      setState(() {
        _currentPosition = _playerController!.value.position;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  Future<void> _trimVideo() async {
    if (videoPath == null) return;
    if (_startTime >= _endTime) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Start time must be less than end time'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isTrimming = true;
      _status = 'Trimming video...';
    });

    try {
      // Request storage permission
      final hasPermission = await FileUtils.requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      // Get output directory
      final downloadDir = await FileUtils.getDownloadDirectory();
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      final outputFileName =
          'trimmed_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final finalOutputPath = path.join(downloadDir.path, outputFileName);

      // Convert Duration to milliseconds
      final startMs = _startTime.inMilliseconds;
      final endMs = _endTime.inMilliseconds;

      // Validate time range
      if (startMs >= endMs) {
        throw Exception('Start time must be less than end time');
      }

      if (startMs < 0 || endMs > _videoDuration.inMilliseconds) {
        throw Exception('Time range is out of bounds');
      }

      setState(() {
        _status = 'Trimming video...';
      });

      // Use platform channel to trim video using native Android MediaMuxer
      const platform = MethodChannel(
        'com.example.videodownloader01/video_trimmer',
      );

      String outputPath;
      try {
        final result = await platform.invokeMethod('trimVideo', {
          'inputPath': videoPath,
          'outputPath': finalOutputPath,
          'startMs': startMs,
          'endMs': endMs,
        });

        if (result == null || result.toString().isEmpty) {
          throw Exception('Video trimming failed - no output path returned');
        }

        outputPath = result.toString();
      } on PlatformException catch (e) {
        throw Exception('Video trimming failed: ${e.message}');
      } catch (e) {
        throw Exception('Video trimming failed: ${e.toString()}');
      }

      if (mounted) {
        setState(() {
          _isTrimming = false;
        });

        if (await File(outputPath).exists()) {
          // Copy to final download directory
          final finalFile = await File(outputPath).copy(finalOutputPath);

          // Delete temporary file if different
          if (outputPath != finalOutputPath) {
            try {
              await File(outputPath).delete();
            } catch (e) {
              // Ignore deletion errors
            }
          }

          setState(() {
            _status = 'Video trimmed successfully!';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Video saved to: ${path.basename(finalFile.path)}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          setState(() {
            _status = 'Failed to trim video';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to trim video. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTrimming = false;
          _status = 'Error: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Video Cutter'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.grey.shade900],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.deepPurple.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.content_cut,
                        color: Colors.deepPurple,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Video Cutter',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select video and trim using timeline',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Pick Video Button
              if (videoPath == null)
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.deepPurple.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.video_library,
                          color: Colors.deepPurple,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Select Video',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Choose a video file to trim',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 25),
                      ElevatedButton.icon(
                        onPressed: _pickVideo,
                        icon: const Icon(Icons.folder, size: 24),
                        label: const Text(
                          'Pick Video',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                        ),
                      ),
                    ],
                  ),
                ),

              // Video Player and Timeline
              if (videoPath != null && _playerController != null) ...[
                // Video Player
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.deepPurple.withOpacity(0.3),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: AspectRatio(
                      aspectRatio: _playerController!.value.aspectRatio,
                      child: VideoPlayer(_playerController!),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Time Display
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Start',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _formatDuration(_startTime),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade700,
                      ),
                      Column(
                        children: [
                          Text(
                            'Current',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _formatDuration(_currentPosition),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.shade700,
                      ),
                      Column(
                        children: [
                          Text(
                            'End',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _formatDuration(_endTime),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Timeline with Draggable Handles
                _buildTimeline(),
                const SizedBox(height: 20),

                // Control Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isTrimming
                            ? null
                            : () {
                                _playerController?.seekTo(_startTime);
                              },
                        icon: const Icon(Icons.skip_previous),
                        label: const Text('Go to Start'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isTrimming
                            ? null
                            : () {
                                if (_playerController!.value.isPlaying) {
                                  _playerController!.pause();
                                } else {
                                  _playerController!.play();
                                }
                              },
                        icon: Icon(
                          _playerController!.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                        label: Text(
                          _playerController!.value.isPlaying ? 'Pause' : 'Play',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isTrimming
                            ? null
                            : () {
                                _playerController?.seekTo(_endTime);
                              },
                        icon: const Icon(Icons.skip_next),
                        label: const Text('Go to End'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Trim Button
                ElevatedButton.icon(
                  onPressed: _isTrimming ? null : _trimVideo,
                  icon: _isTrimming
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.content_cut),
                  label: Text(
                    _isTrimming ? 'Trimming...' : 'Cut Video',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                ),

                // Status
                if (_status.isNotEmpty) ...[
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isTrimming
                          ? Colors.blue.shade900.withOpacity(0.3)
                          : _status.contains('success')
                          ? Colors.green.shade900.withOpacity(0.3)
                          : _status.contains('Failed') ||
                                _status.contains('Error')
                          ? Colors.red.shade900.withOpacity(0.3)
                          : Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isTrimming
                              ? Icons.sync
                              : _status.contains('success')
                              ? Icons.check_circle
                              : _status.contains('Failed') ||
                                    _status.contains('Error')
                              ? Icons.error
                              : Icons.info,
                          color: _isTrimming
                              ? Colors.blue
                              : _status.contains('success')
                              ? Colors.green
                              : _status.contains('Failed') ||
                                    _status.contains('Error')
                              ? Colors.red
                              : Colors.grey,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    if (_videoDuration.inMilliseconds == 0) {
      return const SizedBox.shrink();
    }

    final padding = 40.0;
    final totalWidth = MediaQuery.of(context).size.width - (padding * 2);
    final startPosition =
        (_startTime.inMilliseconds / _videoDuration.inMilliseconds) *
        totalWidth;
    final endPosition =
        (_endTime.inMilliseconds / _videoDuration.inMilliseconds) * totalWidth;
    final currentPosition =
        (_currentPosition.inMilliseconds / _videoDuration.inMilliseconds) *
        totalWidth;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: padding),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Timeline Bar Container
          SizedBox(
            height: 60,
            child: Stack(
              children: [
                // Background progress bar
                Positioned(
                  top: 27,
                  left: 0,
                  child: Container(
                    height: 6,
                    width: totalWidth,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                // Selected range (green)
                if (endPosition > startPosition)
                  Positioned(
                    top: 27,
                    left: startPosition,
                    child: Container(
                      height: 6,
                      width: endPosition - startPosition,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                // Current position indicator
                Positioned(
                  top: 25,
                  left: (currentPosition.clamp(0.0, totalWidth) - 2),
                  child: Container(
                    width: 4,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Start handle (Green Dot - Left side)
                Positioned(
                  top: 18,
                  left: startPosition - 12,
                  child: GestureDetector(
                    onPanStart: (details) {
                      _dragStartX = details.globalPosition.dx;
                      _initialStartPosition = startPosition;
                      setState(() {
                        _isDraggingStart = true;
                      });
                      _playerController?.pause();
                    },
                    onPanUpdate: (details) {
                      final deltaX = details.globalPosition.dx - _dragStartX;
                      var newPosition = _initialStartPosition + deltaX;

                      // Get current end position
                      final currentEndPosition =
                          (_endTime.inMilliseconds /
                              _videoDuration.inMilliseconds) *
                          totalWidth;

                      // Minimum gap in pixels (1 second minimum)
                      final minGapPixels = 30.0;
                      final minGapInMs =
                          (minGapPixels /
                                  totalWidth *
                                  _videoDuration.inMilliseconds)
                              .round();

                      // Clamp position
                      newPosition = newPosition.clamp(
                        0.0,
                        currentEndPosition - minGapPixels,
                      );

                      // Convert to time
                      final newTimeMs =
                          ((newPosition / totalWidth) *
                                  _videoDuration.inMilliseconds)
                              .round();

                      // Update if valid
                      if (newTimeMs < (_endTime.inMilliseconds - minGapInMs) &&
                          newTimeMs >= 0) {
                        final newTime = Duration(milliseconds: newTimeMs);
                        setState(() {
                          _startTime = newTime;
                        });
                        _playerController?.seekTo(_startTime);
                      }
                    },
                    onPanEnd: (_) {
                      setState(() {
                        _isDraggingStart = false;
                      });
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // End handle (Red Dot - Right side)
                Positioned(
                  top: 18,
                  left: endPosition - 12,
                  child: GestureDetector(
                    onPanStart: (details) {
                      _dragStartX = details.globalPosition.dx;
                      _initialEndPosition = endPosition;
                      setState(() {
                        _isDraggingEnd = true;
                      });
                      _playerController?.pause();
                    },
                    onPanUpdate: (details) {
                      final deltaX = details.globalPosition.dx - _dragStartX;
                      var newPosition = _initialEndPosition + deltaX;

                      // Get current start position
                      final currentStartPosition =
                          (_startTime.inMilliseconds /
                              _videoDuration.inMilliseconds) *
                          totalWidth;

                      // Minimum gap in pixels (1 second minimum)
                      final minGapPixels = 30.0;
                      final minGapInMs =
                          (minGapPixels /
                                  totalWidth *
                                  _videoDuration.inMilliseconds)
                              .round();

                      // Clamp position
                      newPosition = newPosition.clamp(
                        currentStartPosition + minGapPixels,
                        totalWidth,
                      );

                      // Convert to time
                      final newTimeMs =
                          ((newPosition / totalWidth) *
                                  _videoDuration.inMilliseconds)
                              .round();

                      // Update if valid
                      if (newTimeMs >
                              (_startTime.inMilliseconds + minGapInMs) &&
                          newTimeMs <= _videoDuration.inMilliseconds) {
                        final newTime = Duration(milliseconds: newTimeMs);
                        setState(() {
                          _endTime = newTime;
                        });
                        _playerController?.seekTo(_endTime);
                      }
                    },
                    onPanEnd: (_) {
                      setState(() {
                        _isDraggingEnd = false;
                      });
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Clickable timeline for seeking and setting start/end
                Positioned(
                  top: 0,
                  left: 0,
                  child: GestureDetector(
                    onTapDown: (details) {
                      if (!_isDraggingStart && !_isDraggingEnd) {
                        final tapX = details.localPosition.dx;
                        final newTime = Duration(
                          milliseconds:
                              ((tapX / totalWidth) *
                                      _videoDuration.inMilliseconds)
                                  .round(),
                        );
                        if (newTime >= Duration.zero &&
                            newTime <= _videoDuration) {
                          setState(() {
                            _currentPosition = newTime;
                          });
                          _playerController?.seekTo(newTime);
                        }
                      }
                    },
                    onLongPressStart: (details) {
                      // On long press, set start or end time based on tap position
                      if (!_isDraggingStart && !_isDraggingEnd) {
                        final tapX = details.localPosition.dx;
                        final tapTime = Duration(
                          milliseconds:
                              ((tapX / totalWidth) *
                                      _videoDuration.inMilliseconds)
                                  .round(),
                        );

                        // Determine if closer to start or end
                        final startDistance =
                            (tapTime.inMilliseconds - _startTime.inMilliseconds)
                                .abs();
                        final endDistance =
                            (tapTime.inMilliseconds - _endTime.inMilliseconds)
                                .abs();

                        if (startDistance < endDistance) {
                          // Set start time
                          if (tapTime < _endTime) {
                            setState(() {
                              _startTime = tapTime;
                            });
                            _playerController?.seekTo(_startTime);
                          }
                        } else {
                          // Set end time
                          if (tapTime > _startTime) {
                            setState(() {
                              _endTime = tapTime;
                            });
                            _playerController?.seekTo(_endTime);
                          }
                        }
                      }
                    },
                    child: Container(
                      width: totalWidth,
                      height: 60,
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Duration text
          Text(
            'Total: ${_formatDuration(_videoDuration)} | '
            'Selected: ${_formatDuration(_endTime - _startTime)}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
