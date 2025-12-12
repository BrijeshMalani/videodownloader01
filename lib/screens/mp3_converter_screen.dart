import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../services/ad_manager.dart';
import '../services/converter_service.dart';
import '../utils/common.dart';
import '../utils/file_utils.dart';
import '../widgets/WorkingNativeAdWidget.dart';

class MP3ConverterScreen extends StatefulWidget {
  const MP3ConverterScreen({super.key});

  @override
  State<MP3ConverterScreen> createState() => _MP3ConverterScreenState();
}

class _MP3ConverterScreenState extends State<MP3ConverterScreen> {
  File? _selectedVideo;
  bool _isConverting = false;
  bool _isDownloading = false;
  double _conversionProgress = 0.0;
  double _downloadProgress = 0.0;
  String? _convertedFileUrl;
  String? _errorMessage;
  String _conversionStatus = '';
  String? _mp3DownloadUrl;
  String? _originalVideoName;

  Future<void> _pickVideoFromGallery() async {
    try {
      // Request permissions first
      final hasPermission = await FileUtils.requestStoragePermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Storage permission is required to pick videos from gallery',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Use file_picker to select video file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        if (await file.exists()) {
          setState(() {
            _selectedVideo = file;
            _convertedFileUrl = null;
            _errorMessage = null;
          });
        } else {
          throw Exception('Selected file does not exist');
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        String errorMsg = 'Error picking video';

        if (e.code == 'permission_denied' ||
            e.code == 'photo_access_denied' ||
            e.code == 'video_access_denied' ||
            e.message?.toLowerCase().contains('permission') == true) {
          errorMsg =
              'Permission denied. Please grant storage permission in app settings.';
        } else {
          errorMsg = 'Error: ${e.message ?? e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Error picking video';
        final errorStr = e.toString();

        if (errorStr.contains('permission') ||
            errorStr.contains('Permission')) {
          errorMsg =
              'Permission denied. Please grant storage permission in app settings.';
        } else if (errorStr.contains('cancel') ||
            errorStr.contains('Cancel') ||
            errorStr.contains('User cancelled')) {
          // User cancelled, don't show error
          return;
        } else if (errorStr.contains('User canceled') ||
            errorStr.contains('user_canceled')) {
          // User cancelled, don't show error
          return;
        } else {
          errorMsg =
              'Error: ${errorStr.replaceAll('Exception: ', '').replaceAll('Error: ', '')}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _convertVideo() async {
    if (Common.adsopen == "2") {
      Common.openUrl();
    }
    AdManager().showInterstitialAd();
    if (_selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a video file'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if file exists
    if (!await _selectedVideo!.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected video file does not exist'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isConverting = true;
      _isDownloading = false;
      _conversionStatus = 'Converting video...';
      _conversionProgress = 0.0;
      _errorMessage = null;
    });

    // Simulate progress
    _updateProgress();

    try {
      // Step 1: Convert video to MP3 via API using ConverterService
      final videoFileName = _selectedVideo!.path.split('/').last;
      final conversionResult = await ConverterService.convertVideoToMp3(
        _selectedVideo!.path,
      );

      if (conversionResult['success'] != true ||
          conversionResult['mp3Url'] == null) {
        setState(() {
          _isConverting = false;
          _conversionStatus = '';
        });

        if (mounted) {
          final errorMsg = conversionResult['error'] ?? 'Conversion failed';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorMsg,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
        return;
      }

      // Show ad if AdManager exists (optional)
      try {
        // AdManager().showInterstitialAd();
      } catch (e) {
        // AdManager not available, ignore
      }

      // Step 2: Store MP3 URL for download button
      final mp3Url = conversionResult['mp3Url'] as String;

      setState(() {
        _isConverting = false;
        _isDownloading = false;
        _conversionStatus = 'Conversion successful!';
        _mp3DownloadUrl = mp3Url;
        _convertedFileUrl = mp3Url;
        _originalVideoName = videoFileName;
        _conversionProgress = 1.0;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conversion successful!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() {
        _isConverting = false;
        _isDownloading = false;
        _conversionStatus = '';
        _errorMessage = e
            .toString()
            .replaceAll('Exception: ', '')
            .replaceAll('Error: ', '');
      });

      if (mounted) {
        String errorMsg = 'Conversion failed';
        final errorStr = e.toString();

        if (errorStr.contains('timeout') || errorStr.contains('Timeout')) {
          errorMsg =
              'Request timeout. Please check your internet connection and try again.';
        } else if (errorStr.contains('Network') ||
            errorStr.contains('SocketException')) {
          errorMsg =
              'No internet connection. Please check your network and try again.';
        } else if (errorStr.contains('Server error') ||
            errorStr.contains('500')) {
          errorMsg = 'Server error. Please try again later.';
        } else {
          errorMsg = errorStr
              .replaceAll('Exception: ', '')
              .replaceAll('Error: ', '');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  void _updateProgress() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted && _isConverting && _conversionProgress < 0.9) {
        setState(() {
          _conversionProgress += 0.1;
        });
        _updateProgress();
      }
    });
  }

  void _updateDownloadProgress() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _isDownloading && _downloadProgress < 0.9) {
        setState(() {
          _downloadProgress += 0.1;
        });
        _updateDownloadProgress();
      }
    });
  }

  Future<void> _downloadMP3([String? url]) async {
    if (Common.adsopen == "2") {
      Common.openUrl();
    }
    AdManager().showInterstitialAd();
    // Use _mp3DownloadUrl if available, otherwise use provided url or _convertedFileUrl
    final downloadUrl = url ?? _mp3DownloadUrl ?? _convertedFileUrl;
    if (downloadUrl == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No download URL available'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.1; // Start with 10% to show download started
    });

    try {
      // Simulate progress while downloading
      _updateDownloadProgress();

      // Use ConverterService to download and save MP3
      final originalVideoName = _originalVideoName ?? 'converted_video';
      final downloadResult = await ConverterService.downloadAndSaveMp3(
        downloadUrl,
        originalVideoName,
      );

      if (downloadResult['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'MP3 downloaded successfully!\nSaved to: ${downloadResult['filePath'] ?? 'Download folder'}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
          setState(() {
            _isDownloading = false;
            _downloadProgress = 1.0;
          });
        }
      } else {
        throw Exception(downloadResult['error'] ?? 'Download failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Convert to MP3'),
        backgroundColor: Colors.orange.shade700,
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
                    color: Colors.orange.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.transform,
                        color: Colors.orange,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Convert Video to MP3',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select a video file to convert to audio format',
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
              // Pick from Gallery Button
              if (_selectedVideo == null)
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.video_library,
                          color: Colors.orange,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Select Video from Gallery',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Choose a video file to convert to MP3 format',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 25),
                      ElevatedButton.icon(
                        onPressed: _pickVideoFromGallery,
                        icon: const Icon(Icons.folder, size: 24),
                        label: const Text(
                          'Pick from Gallery',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
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
              // Selected video info
              if (_selectedVideo != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.video_file,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              FileUtils.getFileName(_selectedVideo!.path),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            FutureBuilder<String>(
                              future: FileUtils.getFileSize(_selectedVideo!),
                              builder: (context, snapshot) {
                                return Text(
                                  'Size: ${snapshot.data ?? 'Unknown'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade400,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _selectedVideo = null;
                            _convertedFileUrl = null;
                            _errorMessage = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade700),
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
              // Convert button
              if (_selectedVideo != null &&
                  !_isConverting &&
                  !_isDownloading) ...[
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _convertVideo,
                  icon: const Icon(Icons.transform),
                  label: const Text(
                    'Convert to MP3',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                ),
              ],
              // Conversion progress
              if (_isConverting) ...[
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.sync, color: Colors.orange, size: 40),
                      const SizedBox(height: 15),
                      Text(
                        _conversionStatus.isNotEmpty
                            ? _conversionStatus
                            : 'Converting video to MP3...',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      LinearProgressIndicator(
                        value: _conversionProgress,
                        backgroundColor: Colors.grey.shade800,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.orange,
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        '${(_conversionProgress * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Download progress
              if (_isDownloading) ...[
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.download, color: Colors.green, size: 40),
                      const SizedBox(height: 15),
                      const Text(
                        'Downloading MP3...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      LinearProgressIndicator(
                        value: _downloadProgress,
                        backgroundColor: Colors.grey.shade800,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.green,
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        '${(_downloadProgress * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Success message
              if (_convertedFileUrl != null &&
                  !_isConverting &&
                  !_isDownloading) ...[
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.green.shade900.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.green.shade700),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Conversion Successful!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your MP3 file is ready to download',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _downloadMP3(),
                        icon: const Icon(Icons.download),
                        label: const Text('Download MP3'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: const WorkingNativeAdWidget(),
    );
  }
}
