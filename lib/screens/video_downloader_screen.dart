import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/ad_manager.dart';
import '../services/api_service.dart';
import '../models/video_data.dart';
import '../utils/common.dart';
import '../utils/download_helper.dart';
import '../utils/file_utils.dart';
import '../widgets/WorkingNativeAdWidget.dart';

class VideoDownloaderScreen extends StatefulWidget {
  final String? platform;

  const VideoDownloaderScreen({super.key, this.platform});

  @override
  State<VideoDownloaderScreen> createState() => _VideoDownloaderScreenState();
}

class _VideoDownloaderScreenState extends State<VideoDownloaderScreen> {
  final TextEditingController _urlController = TextEditingController();
  VideoData? _videoData;
  bool _isLoading = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _errorMessage;

  String get _platformName {
    switch (widget.platform?.toLowerCase()) {
      case 'instagram':
        return 'Instagram';
      case 'facebook':
        return 'Facebook';
      case 'twitter':
        return 'Twitter/X';
      case 'tiktok':
        return 'TikTok';
      default:
        return 'Video';
    }
  }

  IconData get _platformIcon {
    switch (widget.platform?.toLowerCase()) {
      case 'instagram':
        return Icons.camera_alt;
      case 'facebook':
        return Icons.facebook;
      case 'twitter':
        return Icons.alternate_email;
      case 'tiktok':
        return Icons.music_video;
      default:
        return Icons.video_library;
    }
  }

  Color get _platformColor {
    switch (widget.platform?.toLowerCase()) {
      case 'instagram':
        return Colors.purple;
      case 'facebook':
        return Colors.blue;
      case 'twitter':
        return Colors.black;
      case 'tiktok':
        return Colors.black;
      default:
        return Colors.deepPurple;
    }
  }

  Future<void> _fetchVideo() async {
    if (Common.adsopen == "2") {
      Common.openUrl();
    }
    AdManager().showInterstitialAd();
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid URL';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _videoData = null;
    });

    try {
      Map<String, dynamic> response;

      switch (widget.platform?.toLowerCase()) {
        case 'instagram':
          response = await ApiService.downloadInstagramVideo(url);
          break;
        case 'facebook':
          response = await ApiService.downloadFacebookVideo(url);
          break;
        case 'twitter':
          response = await ApiService.downloadTwitterVideo(url);
          break;
        case 'tiktok':
          response = await ApiService.downloadTikTokVideo(url);
          break;
        default:
          // Try to detect platform from URL
          if (url.contains('instagram.com')) {
            response = await ApiService.downloadInstagramVideo(url);
          } else if (url.contains('facebook.com')) {
            response = await ApiService.downloadFacebookVideo(url);
          } else if (url.contains('x.com') || url.contains('twitter.com')) {
            response = await ApiService.downloadTwitterVideo(url);
          } else if (url.contains('tiktok.com')) {
            response = await ApiService.downloadTikTokVideo(url);
          } else {
            throw Exception('Unsupported platform');
          }
      }

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _videoData = VideoData.fromJson(response['data']);
          _isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch video');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadVideo() async {
    if (_videoData == null) return;

    // Request storage permission
    final hasPermission = await FileUtils.requestStoragePermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission is required to download videos'),
          ),
        );
      }
      return;
    }

    if (Common.adsopen == "2") {
      Common.openUrl();
    }
    AdManager().showInterstitialAd();

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final fileName = DownloadHelper.getFileNameFromUrl(
        _videoData!.videoUrl,
        widget.platform ?? 'video',
      );

      await DownloadHelper.downloadVideo(
        _videoData!.videoUrl,
        fileName,
        onProgress: (received, total) {
          setState(() {
            _downloadProgress = received / total;
          });
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video downloaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Download failed';
        final errorStr = e.toString();

        if (errorStr.contains('Permission denied') ||
            errorStr.contains('permission')) {
          errorMessage =
              'Storage permission denied. Please grant storage permission in app settings.';
        } else if (errorStr.contains('Network') ||
            errorStr.contains('timeout')) {
          errorMessage =
              'Network error. Please check your internet connection.';
        } else if (errorStr.contains('path') ||
            errorStr.contains('PathAccessException')) {
          errorMessage = 'Cannot save file. Please check storage permissions.';
        } else {
          errorMessage =
              'Download failed: ${errorStr.replaceAll('Exception: ', '').replaceAll('Download error: ', '')}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black45,
      appBar: AppBar(
        title: Text('$_platformName Downloader'),
        backgroundColor: _platformColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // URL Input
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Enter $_platformName URL',
                labelStyle: const TextStyle(color: Colors.white),
                hintText: 'Paste video URL here',
                hintStyle: const TextStyle(color: Colors.white),
                prefixIcon: Icon(_platformIcon, color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                filled: true,
                fillColor: Colors.black45,
              ),
            ),
            const SizedBox(height: 20),
            // Fetch Button
            ElevatedButton(
              onPressed: _isLoading ? null : _fetchVideo,
              style: ElevatedButton.styleFrom(
                backgroundColor: _platformColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Fetch Video',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            // Error Message
            if (_errorMessage != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Video Preview
            if (_videoData != null) ...[
              const SizedBox(height: 30),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Thumbnail
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: _videoData!.thumbnail,
                        height: 250,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 250,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 250,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.error, size: 50),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Username
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 20,
                                color: _platformColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _videoData!.username,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Caption
                          if (_videoData!.caption != null) ...[
                            Text(
                              _videoData!.caption!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                          ],
                          // Stats
                          Row(
                            children: [
                              if (_videoData!.likeCount != null) ...[
                                Icon(
                                  Icons.favorite,
                                  size: 16,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${_videoData!.likeCount}',
                                  style: TextStyle(color: Colors.black),
                                ),
                                const SizedBox(width: 15),
                              ],
                              if (_videoData!.commentCount != null) ...[
                                Icon(
                                  Icons.comment,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${_videoData!.commentCount}',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Download Button
                          if (_isDownloading)
                            Column(
                              children: [
                                LinearProgressIndicator(
                                  value: _downloadProgress,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _platformColor,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${(_downloadProgress * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _platformColor,
                                  ),
                                ),
                              ],
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: _downloadVideo,
                              icon: const Icon(Icons.download),
                              label: const Text('Download Video'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _platformColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                  horizontal: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: const WorkingNativeAdWidget(),
    );
  }
}
