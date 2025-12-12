import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import '../utils/file_utils.dart';

class DownloadHelper {
  static Future<File> downloadVideo(
    String url,
    String fileName, {
    Function(int, int)? onProgress,
  }) async {
    try {
      // Request permission first
      final hasPermission = await FileUtils.requestStoragePermission();
      if (!hasPermission) {
        throw Exception(
          'Storage permission denied. Please grant storage permission to download videos.',
        );
      }

      final downloadDir = await FileUtils.getDownloadDirectory();
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // Clean filename to avoid invalid characters
      final cleanFileName = _cleanFileName(fileName);
      final filePath = path.join(downloadDir.path, cleanFileName);

      // If file exists, add timestamp
      var finalPath = filePath;
      if (await File(finalPath).exists()) {
        final nameWithoutExt = path.basenameWithoutExtension(cleanFileName);
        final ext = path.extension(cleanFileName);
        finalPath = path.join(
          downloadDir.path,
          '${nameWithoutExt}_${DateTime.now().millisecondsSinceEpoch}$ext',
        );
      }

      final file = File(finalPath);
      final dio = Dio();

      // Set timeout and headers
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 60);

      await dio.download(
        url,
        finalPath,
        onReceiveProgress: (received, total) {
          if (onProgress != null && total > 0) {
            onProgress(received, total);
          }
        },
      );

      // Verify file was created
      if (!await file.exists()) {
        throw Exception('File was not created successfully');
      }

      return file;
    } catch (e) {
      throw Exception('Download error: $e');
    }
  }

  static String _cleanFileName(String fileName) {
    // Remove invalid characters for file names
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    var cleaned = fileName.replaceAll(invalidChars, '_');

    // Limit length
    if (cleaned.length > 200) {
      final ext = path.extension(cleaned);
      cleaned = '${cleaned.substring(0, 195)}$ext';
    }

    return cleaned;
  }

  static String getFileNameFromUrl(String url, String platform) {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;
    final lastSegment = pathSegments.isNotEmpty
        ? pathSegments.last
        : 'video_${DateTime.now().millisecondsSinceEpoch}';

    // Remove query parameters from filename
    final cleanName = lastSegment.split('?').first;

    // Ensure .mp4 extension
    if (!cleanName.toLowerCase().endsWith('.mp4')) {
      return '${platform}_${DateTime.now().millisecondsSinceEpoch}.mp4';
    }

    return '${platform}_$cleanName';
  }
}
