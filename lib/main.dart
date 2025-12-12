import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:videodownloader01/services/app_open_ad_manager.dart';
import 'package:videodownloader01/utils/common.dart';
import 'package:videodownloader01/widgets/NativeAdService.dart';
import 'package:videodownloader01/widgets/SmallNativeAdService.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();

  // Request tracking permission with error handling
  // try {
  //   await TrackingPermissionHelper.requestTrackingPermission();
  // } catch (e) {
  //   // Handle errors gracefully - this is expected on Android or when not configured
  //   print('Tracking permission request failed: $e');
  // }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final AppOpenAdManager _appOpenAdManager = AppOpenAdManager();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize native ad service safely
    _initializeAds();
  }

  void _initializeAds() async {
    try {
      // Only initialize ads if they are enabled and IDs are provided
      if (Common.addOnOff && Common.native_ad_id.isNotEmpty) {
        SmallNativeAdService().initialize();
        NativeAdService().initialize();
      } else {
        print('Ads disabled or no ad IDs provided, skipping ad initialization');
      }
    } catch (e) {
      print('Error initializing ads: $e');
      // Continue without ads if initialization fails
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App is going to background
      Common.isAppInBackground = true;
    } else if (state == AppLifecycleState.resumed) {
      // App is resuming from background
      if (!Common.inAppPurchase &&
          Common.addOnOff &&
          Common.isAppInBackground &&
          Common.app_open_ad_id.isNotEmpty) {
        if (!_recentlyShownInterstitial()) {
          try {
            _appOpenAdManager.showAdIfAvailable();
          } catch (e) {
            print('Error showing app open ad: $e');
          }
        }
      }
      // Reset background flag after handling resume
      Common.isAppInBackground = false;
    }
  }

  bool _recentlyShownInterstitial() {
    // Check if recently opened flag is true
    if (Common.recentlyOpened) {
      return true;
    }

    // Check if interstitial ad was shown within the last 15 seconds
    if (Common.lastInterstitialAdTime != null) {
      final timeSinceLastAd = DateTime.now().difference(
        Common.lastInterstitialAdTime!,
      );
      if (timeSinceLastAd.inSeconds < 15) {
        return true;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Downloader',
      // navigatorObservers: [FirebaseAnalyticsObserver(analytics: _analytics)],
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.deepPurple,
          secondary: Colors.purple,
          surface: Colors.grey.shade900,
          background: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.grey.shade900,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade800,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
