import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:io';

class ApiService {
  static const String baseUrl = 'https://shatars.com';
  static const String downloadBaseUrl = 'https://download.shatars.com';

  // Download Instagram video
  static Future<Map<String, dynamic>> downloadInstagramVideo(String url) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/instagramdownloader.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': url}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to fetch Instagram video');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Download Facebook video
  static Future<Map<String, dynamic>> downloadFacebookVideo(String url) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/facebookdownloader.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': url}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to fetch Facebook video');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Download Twitter/X video
  static Future<Map<String, dynamic>> downloadTwitterVideo(String url) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/twitterdownloader.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': url}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to fetch Twitter video');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Download TikTok video
  static Future<Map<String, dynamic>> downloadTikTokVideo(String url) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tiktokdownloader.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': url}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to fetch TikTok video');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Convert MP4 to MP3
  static Future<Map<String, dynamic>> convertVideoToAudio(
    File videoFile,
  ) async {
    // Check if file exists
    if (!await videoFile.exists()) {
      throw Exception('Video file does not exist');
    }

    // Check file size (limit to 500MB)
    final fileSize = await videoFile.length();
    if (fileSize > 500 * 1024 * 1024) {
      throw Exception('Video file is too large. Maximum size is 500MB');
    }

    print('Converting video: ${videoFile.path}');
    print('File size: ${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB');

    try {
      // Read file bytes to ensure file is accessible
      List<int> fileBytes;
      String fileName;

      try {
        fileBytes = await videoFile.readAsBytes();
        fileName = videoFile.path.split('/').last;
        print('File read successfully: $fileName (${fileBytes.length} bytes)');
      } catch (e) {
        print('Error reading file: $e');
        throw Exception(
          'Cannot read video file. Please select a valid video file.',
        );
      }

      // Create multipart request (same as Postman form-data)
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$downloadBaseUrl/convert/video/audio'),
      );

      // Add video file with field name 'video' using bytes
      request.files.add(
        http.MultipartFile.fromBytes('video', fileBytes, filename: fileName),
      );

      print('Sending request to: $downloadBaseUrl/convert/video/audio');

      // Send request with timeout
      final client = http.Client();
      final streamedResponse = await client
          .send(request)
          .timeout(const Duration(minutes: 10));

      // Get response
      final response = await http.Response.fromStream(streamedResponse);
      client.close();

      // Parse response
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        return jsonResponse;
      } else {
        // Log error for debugging
        print('API Error - Status: ${response.statusCode}');
        print('API Error - Body: ${response.body}');

        if (response.statusCode == 413) {
          throw Exception(
            'File is too large. Please select a smaller video file.',
          );
        } else if (response.statusCode == 400) {
          throw Exception(
            'Invalid video file format. Please select a valid video file.',
          );
        } else if (response.statusCode >= 500) {
          throw Exception('Server error. Please try again later.');
        } else {
          throw Exception(
            'Conversion failed with status code: ${response.statusCode}',
          );
        }
      }
    } on TimeoutException {
      throw Exception(
        'Conversion timeout. Please try again with a smaller file.',
      );
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw Exception('Invalid response format: ${e.message}');
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('SocketException') ||
          errorMsg.contains('Failed host lookup')) {
        throw Exception(
          'No internet connection. Please check your network and try again.',
        );
      }
      rethrow;
    }
  }
}
