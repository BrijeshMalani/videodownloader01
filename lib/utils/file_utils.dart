import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

class FileUtils {
  // Get download directory
  static Future<Directory> getDownloadDirectory() async {
    if (Platform.isAndroid) {
      try {
        // Try to use external storage directory first
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final downloadDir = Directory(
            path.join(externalDir.path, 'Download'),
          );
          if (!await downloadDir.exists()) {
            await downloadDir.create(recursive: true);
          }
          return downloadDir;
        }
      } catch (e) {
        print('Error getting external storage: $e');
      }

      // Fallback to app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory(path.join(appDir.path, 'Download'));
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      return downloadDir;
    } else if (Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      final downloadDir = Directory(path.join(directory.path, 'Download'));
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      return downloadDir;
    }
    final directory = await getApplicationDocumentsDirectory();
    final downloadDir = Directory(path.join(directory.path, 'Download'));
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir;
  }

  // Request storage permission
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+), use media permissions
      if (await Permission.videos.isGranted ||
          await Permission.photos.isGranted) {
        return true;
      }

      // Request media permissions for Android 13+
      final videosStatus = await Permission.videos.request();
      final photosStatus = await Permission.photos.request();

      if (videosStatus.isGranted || photosStatus.isGranted) {
        return true;
      }

      // For Android 10-12, try storage permission
      final storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) {
        return true;
      }

      // For Android 11+, try manage external storage
      final manageStatus = await Permission.manageExternalStorage.request();
      if (manageStatus.isGranted) {
        return true;
      }

      return false;
    }
    return true;
  }

  // Get all video files from device
  static Future<List<File>> getAllVideos() async {
    final List<File> videos = [];
    try {
      final downloadDir = await getDownloadDirectory();
      if (await downloadDir.exists()) {
        await _scanDirectory(downloadDir, videos, [
          '.mp4',
          '.mov',
          '.avi',
          '.mkv',
          '.3gp',
        ]);
      }

      // Also scan common video directories on Android
      if (Platform.isAndroid) {
        final commonDirs = [
          '/storage/emulated/0/DCIM',
          '/storage/emulated/0/Movies',
          '/storage/emulated/0/Videos',
        ];

        for (var dirPath in commonDirs) {
          final dir = Directory(dirPath);
          if (await dir.exists()) {
            await _scanDirectory(dir, videos, [
              '.mp4',
              '.mov',
              '.avi',
              '.mkv',
              '.3gp',
            ]);
          }
        }
      }
    } catch (e) {
      print('Error scanning videos: $e');
    }
    return videos;
  }

  // Get all MP3 files from device
  static Future<List<File>> getAllMP3s() async {
    final List<File> mp3s = [];
    try {
      final downloadDir = await getDownloadDirectory();
      if (await downloadDir.exists()) {
        await _scanDirectory(downloadDir, mp3s, [
          '.mp3',
          '.m4a',
          '.wav',
          '.aac',
        ]);
      }

      // Also scan common music directories on Android
      if (Platform.isAndroid) {
        final commonDirs = [
          '/storage/emulated/0/Music',
          '/storage/emulated/0/Download',
        ];

        for (var dirPath in commonDirs) {
          final dir = Directory(dirPath);
          if (await dir.exists()) {
            await _scanDirectory(dir, mp3s, ['.mp3', '.m4a', '.wav', '.aac']);
          }
        }
      }
    } catch (e) {
      print('Error scanning MP3s: $e');
    }
    return mp3s;
  }

  // Recursively scan directory for files
  static Future<void> _scanDirectory(
    Directory directory,
    List<File> files,
    List<String> extensions,
  ) async {
    try {
      await for (var entity in directory.list(recursive: true)) {
        if (entity is File) {
          final extension = path.extension(entity.path).toLowerCase();
          if (extensions.contains(extension)) {
            files.add(entity);
          }
        }
      }
    } catch (e) {
      print('Error scanning directory ${directory.path}: $e');
    }
  }

  // Get file name from path
  static String getFileName(String filePath) {
    return path.basename(filePath);
  }

  // Get file size
  static Future<String> getFileSize(File file) async {
    try {
      final bytes = await file.length();
      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(2)} KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
