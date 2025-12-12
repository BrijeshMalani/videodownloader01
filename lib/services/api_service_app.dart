import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_data_model.dart';
import 'dart:async';

class AppDataService {
  static const String baseUrl = 'https://shatars.com/getappdata.php';
  static const String pkgId = 'com.example.videodownloader01';

  static Future<AppDataModel?> fetchAppData() async {
    try {
      print('Making API request to: $baseUrl?pkgid=$pkgId');
      final response = await http.get(Uri.parse('$baseUrl?pkgid=$pkgId'));

      print('API Response Status Code: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('Parsed JSON Response: $jsonResponse');

        if (jsonResponse['flag'] == true &&
            jsonResponse['data'] != null &&
            jsonResponse['data'].isNotEmpty) {
          print('Creating AppDataModel from response data');
          final appData = AppDataModel.fromJson(jsonResponse['data'][0]);
          print('Created AppDataModel: $appData');
          return appData;
        } else {
          print('Invalid response format or empty data');
          print('Flag: ${jsonResponse['flag']}');
          print('Data: ${jsonResponse['data']}');
        }
      } else {
        print('API request failed with status code: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      print('Error in fetchAppData: $e');
      return null;
    }
  }
}
