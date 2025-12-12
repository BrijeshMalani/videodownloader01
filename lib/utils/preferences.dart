import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyDarkMode = 'dark_mode';

  // Check if onboarding is completed
  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  // Set onboarding as completed
  static Future<void> setOnboardingCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingCompleted, value);
  }

  // Get dark mode preference
  static Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? true;
  }

  // Set dark mode preference
  static Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }
}

