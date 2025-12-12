import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import '../utils/file_utils.dart';

class ConverterService {
  // Convert video to MP3
  static Future<Map<String, dynamic>> convertVideoToMp3(
    String videoPath,
  ) async {
    try {
      final videoFile = File(videoPath);
      if (!await videoFile.exists()) {
        return {'success': false, 'error': 'Video file not found'};
      }

      // Check file size (limit to 100MB for example)
      final fileSize = await videoFile.length();
      final fileSizeInMB = fileSize / (1024 * 1024);

      if (fileSizeInMB > 100) {
        return {
          'success': false,
          'error': 'File size too large. Maximum 100MB allowed.',
        };
      }

      print('Uploading video to API...');
      print('File size: ${fileSizeInMB.toStringAsFixed(2)} MB');
      print('File path: $videoPath');

      // Create multipart request (exactly like Postman form-data)
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      // Get filename from path
      final fileName = videoPath.split('/').last;

      // Validate file extension
      final fileExtension = fileName.toLowerCase().split('.').last;
      final supportedFormats = [
        'mp4',
        'avi',
        'mov',
        'mkv',
        'wmv',
        'flv',
        'webm',
        '3gp',
        'm4v',
      ];

      if (!supportedFormats.contains(fileExtension)) {
        return {
          'success': false,
          'error':
              'Unsupported video format. Supported formats: ${supportedFormats.join(', ')}',
        };
      }

      print('File extension: .$fileExtension');
      print('File size: ${fileSizeInMB.toStringAsFixed(2)} MB');

      // Determine MIME type based on file extension
      String mimeType = 'video/mp4'; // Default
      switch (fileExtension) {
        case 'mp4':
          mimeType = 'video/mp4';
          break;
        case 'avi':
          mimeType = 'video/x-msvideo';
          break;
        case 'mov':
          mimeType = 'video/quicktime';
          break;
        case 'mkv':
          mimeType = 'video/x-matroska';
          break;
        case 'wmv':
          mimeType = 'video/x-ms-wmv';
          break;
        case 'flv':
          mimeType = 'video/x-flv';
          break;
        case 'webm':
          mimeType = 'video/webm';
          break;
        case '3gp':
          mimeType = 'video/3gpp';
          break;
        case 'm4v':
          mimeType = 'video/x-m4v';
          break;
      }

      print('MIME type: $mimeType');

      // Add video file with explicit MIME type (required by server)
      // Server checks Content-Type to validate it's a video file
      request.files.add(
        await http.MultipartFile.fromPath(
          'video', // This is the key name that Postman uses
          videoPath,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      );

      // Don't add extra headers - let the http package handle Content-Type automatically
      // Only add Accept header if needed
      request.headers['Accept'] = 'application/json';

      print('Sending request to: $apiUrl');
      print('Request method: POST');
      print('Body type: form-data');
      print('Form field key: video');
      print(
        'File being uploaded: $fileName (${fileSizeInMB.toStringAsFixed(2)} MB)',
      );

      // Send request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw Exception('Request timeout. Please try again.');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      print('API Response Status: ${response.statusCode}');
      print('API Response Headers: ${response.headers}');
      print('API Response Body length: ${response.body.length}');

      // Log first 500 characters of response for debugging
      if (response.body.length > 0) {
        final preview = response.body.length > 500
            ? response.body.substring(0, 500)
            : response.body;
        print('API Response Body preview: $preview...');
      }

      // Check response content type
      final responseContentType = response.headers['content-type'] ?? 'unknown';
      print('Response Content-Type: $responseContentType');

      // Handle different status codes
      if (response.statusCode == 200) {
        try {
          final jsonResponse = json.decode(response.body);
          print('Parsed JSON response: $jsonResponse');

          // Check response format exactly like Postman shows
          // Postman response: {"success": true, "file": "http://..."}
          if (jsonResponse['success'] == true && jsonResponse['file'] != null) {
            final mp3Url = jsonResponse['file'] as String;
            print('Conversion successful! MP3 URL: $mp3Url');
            return {'success': true, 'mp3Url': mp3Url};
          } else {
            // If success is false, check for error message
            final errorMsg =
                jsonResponse['error']?.toString() ??
                jsonResponse['message']?.toString() ??
                'Conversion failed';
            print('Conversion failed: $errorMsg');
            return {'success': false, 'error': errorMsg};
          }
        } catch (e) {
          print('JSON parse error: $e');
          print('Raw response body: ${response.body}');
          return {'success': false, 'error': 'Invalid response from server'};
        }
      } else if (response.statusCode == 500) {
        // Server error - try to get error message from response
        String errorMessage = 'Server error 500. Please try again later.';

        // Check if response is HTML or JSON
        final contentType = response.headers['content-type'] ?? '';
        final isHtml =
            contentType.contains('text/html') ||
            response.body.trim().startsWith('<!DOCTYPE') ||
            response.body.trim().startsWith('<html');

        if (isHtml) {
          // If HTML response, show generic error message with suggestions
          print('Server returned HTML error page');
          print('This might be due to:');
          print('1. Server is down or overloaded');
          print('2. File format not supported by server');
          print('3. Network connectivity issues');
          print('4. Server configuration issue');

          errorMessage =
              'Server error 500. The server is temporarily unavailable.';
        } else {
          // Try to parse JSON error response
          try {
            final errorResponse = json.decode(response.body);
            if (errorResponse['error'] != null) {
              errorMessage = errorResponse['error'].toString();
            } else if (errorResponse['message'] != null) {
              errorMessage = errorResponse['message'].toString();
            }
          } catch (e) {
            print('Error parsing 500 response: $e');
            // If not JSON and not HTML, show first 200 chars if available
            if (response.body.length > 0) {
              final preview = response.body.length > 200
                  ? response.body.substring(0, 200)
                  : response.body;
              // Remove HTML tags if present
              errorMessage =
                  'Server error 500. ${preview.replaceAll(RegExp(r'<[^>]*>'), '').trim()}';
            } else {
              errorMessage =
                  'Server error 500. Please try again later or use a smaller video file.';
            }
          }
        }

        return {'success': false, 'error': errorMessage};
      } else {
        return {
          'success': false,
          'error':
              'Server error: ${response.statusCode}. ${response.body.isNotEmpty ? response.body.substring(0, 100) : 'Please try again.'}',
        };
      }
    } on TimeoutException {
      print('Request timeout');
      return {
        'success': false,
        'error':
            'Request timeout. File might be too large. Please try with a smaller file.',
      };
    } catch (e) {
      print('Conversion error: $e');
      return {'success': false, 'error': 'Conversion error: ${e.toString()}'};
    }
  }

  static const String apiUrl =
      'https://download.shatars.com/convert/video/audio';

  // Download MP3 from URL and save to Download folder
  static Future<Map<String, dynamic>> downloadAndSaveMp3(
    String mp3Url,
    String originalVideoName,
  ) async {
    try {
      // Request storage permission using FileUtils
      final hasPermission = await FileUtils.requestStoragePermission();
      if (!hasPermission) {
        return {
          'success': false,
          'error':
              'Storage permission denied. Please grant storage permission to download MP3.',
        };
      }

      print('Downloading MP3 from: $mp3Url');

      // Download file
      final response = await http.get(Uri.parse(mp3Url));

      if (response.statusCode == 200) {
        // Generate file name (remove extension and add .mp3)
        final nameWithoutExt = originalVideoName.replaceAll(
          RegExp(r'\.[^.]+$'),
          '',
        );
        final fileName = '$nameWithoutExt.mp3';

        // Get download directory using FileUtils (handles permissions properly)
        final downloadDir = await FileUtils.getDownloadDirectory();

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

        // Save file
        final file = File(finalPath);
        await file.writeAsBytes(response.bodyBytes);

        print('MP3 saved to: $finalPath');

        return {
          'success': true,
          'filePath': finalPath,
          'fileName': path.basename(finalPath),
        };
      } else {
        return {
          'success': false,
          'error': 'Download failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Download error: $e');
      String errorMsg = 'Download error: ${e.toString()}';

      // Provide user-friendly error messages
      if (e.toString().contains('Permission denied') ||
          e.toString().contains('PathAccessException')) {
        errorMsg =
            'Permission denied. Please grant storage permission in app settings.';
      } else if (e.toString().contains('No such file or directory')) {
        errorMsg =
            'Unable to access download folder. Please check storage permissions.';
      }

      return {'success': false, 'error': errorMsg};
    }
  }

  // Clean filename to remove invalid characters
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
}
