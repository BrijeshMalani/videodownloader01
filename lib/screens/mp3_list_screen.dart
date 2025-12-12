import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import '../utils/file_utils.dart';
import '../widgets/WorkingNativeAdWidget.dart';

class MP3ListScreen extends StatefulWidget {
  const MP3ListScreen({super.key});

  @override
  State<MP3ListScreen> createState() => _MP3ListScreenState();
}

class _MP3ListScreenState extends State<MP3ListScreen> {
  List<File> _mp3s = [];
  bool _isLoading = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _playingIndex;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadMP3s();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _duration = duration;
      });
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _position = position;
      });
    });
  }

  Future<void> _loadMP3s() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final mp3s = await FileUtils.getAllMP3s();
      setState(() {
        _mp3s = mp3s;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading MP3s: $e')));
      }
    }
  }

  Future<void> _playAudio(File audioFile, int index) async {
    if (_playingIndex == index && _isPlaying) {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
      return;
    }

    if (_playingIndex != index) {
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(audioFile.path));
    } else {
      await _audioPlayer.resume();
    }

    setState(() {
      _playingIndex = index;
      _isPlaying = true;
    });
  }

  void _pauseAudio() async {
    await _audioPlayer.pause();
    setState(() {
      _isPlaying = false;
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Music'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMP3s),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _mp3s.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No music files found',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _loadMP3s,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Now playing bar (if playing)
                if (_playingIndex != null && _mp3s.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade200,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.music_note, color: Colors.orange),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                FileUtils.getFileName(
                                  _mp3s[_playingIndex!].path,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                              ),
                              onPressed: _isPlaying
                                  ? _pauseAudio
                                  : () => _playAudio(
                                      _mp3s[_playingIndex!],
                                      _playingIndex!,
                                    ),
                              color: Colors.orange,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              _formatDuration(_position),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                            Expanded(
                              child: Slider(
                                value: _duration.inMilliseconds > 0
                                    ? _position.inMilliseconds /
                                          _duration.inMilliseconds
                                    : 0.0,
                                onChanged: (value) {
                                  final position = Duration(
                                    milliseconds:
                                        (value * _duration.inMilliseconds)
                                            .round(),
                                  );
                                  _audioPlayer.seek(position);
                                },
                              ),
                            ),
                            Text(
                              _formatDuration(_duration),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                // MP3 list
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadMP3s,
                    child: ListView.builder(
                      itemCount: _mp3s.length,
                      itemBuilder: (context, index) {
                        final mp3 = _mp3s[index];
                        final fileName = FileUtils.getFileName(mp3.path);
                        final isCurrentPlaying = _playingIndex == index;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 8,
                          ),
                          elevation: 2,
                          color: isCurrentPlaying ? Colors.orange : null,
                          child: ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.music_note,
                                color: Colors.orange,
                              ),
                            ),
                            title: Text(
                              fileName,
                              style: TextStyle(
                                color: isCurrentPlaying
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  path.dirname(mp3.path),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isCurrentPlaying
                                        ? Colors.white70
                                        : Colors.black.withOpacity(0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                FutureBuilder<String>(
                                  future: FileUtils.getFileSize(mp3),
                                  builder: (context, snapshot) {
                                    return Text(
                                      snapshot.data ?? '',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isCurrentPlaying
                                            ? Colors.white70
                                            : Colors.black.withOpacity(0.7),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isCurrentPlaying && _isPlaying)
                                  Icon(
                                    Icons.equalizer,
                                    color: isCurrentPlaying
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                IconButton(
                                  icon: Icon(
                                    isCurrentPlaying && _isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: isCurrentPlaying
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  onPressed: () => _playAudio(mp3, index),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.share,
                                    color: isCurrentPlaying
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  onPressed: () {
                                    Share.shareXFiles([
                                      XFile(mp3.path),
                                    ], text: 'Check out this audio!');
                                  },
                                  color: Colors.blue,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const WorkingNativeAdWidget(),
    );
  }
}
