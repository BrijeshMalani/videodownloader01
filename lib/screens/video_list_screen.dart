import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;
import 'package:cross_file/cross_file.dart';
import 'dart:io';
import '../utils/file_utils.dart';
import '../widgets/WorkingNativeAdWidget.dart';
import 'video_player_screen.dart';

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({super.key});

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  List<File> _videos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final videos = await FileUtils.getAllVideos();
      setState(() {
        _videos = videos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading videos: $e')));
      }
    }
  }

  void _openVideoPlayer(File videoFile, String videoTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            VideoPlayerScreen(videoFile: videoFile, videoTitle: videoTitle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'My Videos',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadVideos,
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: Container(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
              )
            : _videos.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.video_library_outlined,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No videos found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _loadVideos,
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
            : RefreshIndicator(
                onRefresh: _loadVideos,
                color: Colors.orange,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: _videos.length,
                  itemBuilder: (context, index) {
                    final video = _videos[index];
                    final fileName = FileUtils.getFileName(video.path);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, Colors.grey.shade50],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.grey,
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _openVideoPlayer(video, fileName),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail Section
                                Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          alignment: Alignment.center,
                                          children: [
                                            // Play Icon
                                            Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.orange,
                                              ),
                                              padding: const EdgeInsets.all(12),
                                              child: const Icon(
                                                Icons.play_arrow,
                                                color: Colors.white,
                                                size: 30,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // File Size Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: FutureBuilder<String>(
                                        future: FileUtils.getFileSize(video),
                                        builder: (context, snapshot) {
                                          return Text(
                                            snapshot.data ?? '',
                                            style: TextStyle(
                                              color: Colors.orange.shade900,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(width: 16),

                                // Video Info Section
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // File Name
                                      Text(
                                        fileName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                          height: 1.3,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),

                                      // Path
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.folder_outlined,
                                            size: 14,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              path.dirname(video.path),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade400,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Action Buttons
                                      Row(
                                        children: [
                                          // Play Button
                                          Expanded(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                Colors.orange,
                                                Colors.deepOrange,
                                              ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.grey
                                                        .withOpacity(0.5),
                                                    blurRadius: 8,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () => _openVideoPlayer(
                                                    video,
                                                    fileName,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          vertical: 10,
                                                        ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons.play_arrow,
                                                          color: Colors.white,
                                                          size: 20,
                                                        ),
                                                        SizedBox(width: 6),
                                                        Text(
                                                          'Play',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),

                                          // Share Button
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(
                                                0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.blue.withOpacity(
                                                  0.5,
                                                ),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () {
                                                  Share.shareXFiles(
                                                    [XFile(video.path)],
                                                    text:
                                                        'Check out this video!',
                                                  );
                                                },
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(10),
                                                  child: Icon(
                                                    Icons.share,
                                                    color: Colors.blue,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
      bottomNavigationBar: const WorkingNativeAdWidget(),
    );
  }
}
