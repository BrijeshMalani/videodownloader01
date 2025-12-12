import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_manager.dart';
import '../services/api_service_app.dart';
import '../services/app_open_ad_manager.dart';
import '../utils/common.dart';
import '../utils/initialization_helper.dart';
import '../utils/preferences.dart';
import '../widgets/NativeAdService.dart';
import '../widgets/SmallNativeAdService.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final _initializationHelper = InitializationHelper();
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  Future<void> _initialize() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializationHelper.initialize();
    });
  }

  final AppOpenAdManager _appOpenAdManager = AppOpenAdManager();

  @override
  void initState() {
    super.initState();
    _initialize();
    setupRemoteConfig();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * 3.14159,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _navigateToNext();
  }

  Future<void> setupRemoteConfig() async {
    try {
      final data = await AppDataService.fetchAppData();
      print('API Response: $data');

      if (data != null) {
        if (data.rewardedFull.isNotEmpty) {
          print('Setting privacy policy: ${data.rewardedFull}');
          Common.privacy_policy = data.rewardedFull;
        }
        if (data.rewardedFull2.isNotEmpty) {
          print('Setting terms and conditions: ${data.rewardedFull2}');
          Common.terms_conditions = data.rewardedFull2;
        }
        if (data.startAppFull.isNotEmpty) {
          print('Setting playstore link: ${data.startAppFull}');
          Common.playstore_link = data.startAppFull;
        }
        if (data.gamezopId.isNotEmpty) {
          print('Interstitial show count: ${data.gamezopId}');
          Common.ads_int_open_count = int.parse(data.gamezopId);
        }
        if (data.rewardedFull1.isNotEmpty) {
          print('Ads Open Count: ${data.rewardedFull1}');
          Common.ads_open_count = data.rewardedFull1;
        }
        if (data.startAppNative.isNotEmpty) {
          print('show videos: ${data.startAppNative}');
          Common.showvideos = data.startAppNative;
        }
        if (data.startAppRewarded.isNotEmpty) {
          print('Ads open area: ${data.startAppRewarded}');
          Common.adsopen = data.startAppRewarded;
        }

        if (data.qurekaId.isNotEmpty) {
          print('qureka link: ${data.qurekaId}');
          Common.Qurekaid = data.qurekaId;
        }
        if (data.fbFull.isNotEmpty) {
          print('Apple app bundle Id: ${data.fbFull}');
          Common.appBundleId = data.fbFull;
        }
        //Google ads
        if (data.admobId.isNotEmpty) {
          print('Setting banner ad ID: ${data.admobId}');
          Common.bannar_ad_id = data.admobId;
          // Common.bannar_ad_id = "ca-app-pub-3940256099942544/6300978111";
        }
        if (data.admobFull.isNotEmpty) {
          print('Setting interstitial ad ID: ${data.admobFull}');
          Common.interstitial_ad_id = data.admobFull;
          // Common.interstitial_ad_id = "ca-app-pub-3940256099942544/1033173712";
        }
        if (data.admobFull1.isNotEmpty) {
          print('Setting interstitial ad ID1: ${data.admobFull1}');
          Common.interstitial_ad_id1 = data.admobFull1;
          // Common.interstitial_ad_id1 = "ca-app-pub-3940256099942544/1033173712";
        }
        if (data.admobFull2.isNotEmpty) {
          print('Setting interstitial ad ID2: ${data.admobFull2}');
          Common.interstitial_ad_id2 = data.admobFull2;
        }
        if (data.admobNative.isNotEmpty) {
          print('Setting native ad ID: ${data.admobNative}');
          Common.native_ad_id = data.admobNative;
          // Common.native_ad_id = "ca-app-pub-3940256099942544/2247696110";
        }
        if (data.rewardedInt.isNotEmpty) {
          print('Setting app open ad ID: ${data.rewardedInt}');
          Common.app_open_ad_id = data.rewardedInt;
          // Common.app_open_ad_id = "ca-app-pub-3940256099942544/9257395921";
        }
      }

      // Initialize Mobile Ads SDK
      try {
        await MobileAds.instance.initialize();
        print('MobileAds initialized successfully in splash screen');
      } catch (e) {
        print('Error initializing MobileAds in splash screen: $e');
        // Continue even if MobileAds fails
      }

      Common.addOnOff = true;

      if (Common.addOnOff) {
        try {
          // Initialize only the necessary ad services
          AdManager().initialize();
          SmallNativeAdService().initialize();
          NativeAdService().initialize();
          // Load app open ad and show it when loaded (on app start)
          if (Common.app_open_ad_id.isNotEmpty) {
            _appOpenAdManager.loadAd(
              onAdLoaded: () {
                // Show ad immediately when loaded (app start)
              },
            );
          } else {
            // No app open ad, proceed normally
          }
        } catch (e) {
          print('Error initializing ad services: $e');
        }
      } else {
        print('Subscription active - Ads disabled');
      }
    } catch (e) {
      print('Error in setupRemoteConfig: $e');
      // Initialize MobileAds even if API fails
      try {
        await MobileAds.instance.initialize();
        Common.addOnOff = true;

        // Try to load and show app open ad even if API failed
        if (Common.addOnOff && Common.app_open_ad_id.isNotEmpty) {
          _appOpenAdManager.loadAd(onAdLoaded: () {});
        } else {}
      } catch (initError) {
        print('Error initializing MobileAds after API failure: $initError');
      }
    }
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;

    final isOnboardingCompleted = await Preferences.isOnboardingCompleted();

    if (isOnboardingCompleted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.purple.shade800,
              Colors.indigo.shade900,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background particles
            ...List.generate(
              20,
              (index) => Positioned(
                left: (index * 50.0) % MediaQuery.of(context).size.width,
                top: (index * 80.0) % MediaQuery.of(context).size.height,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value + index,
                      child: Opacity(
                        opacity: 0.3,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.white, Colors.purple.shade300],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.5),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_circle_filled,
                            size: 80,
                            color: Colors.deepPurple,
                          ),
                        ),
                      );
                    },
                  ).animate().fadeIn(duration: 1000.ms).scale(delay: 200.ms),
                  const SizedBox(height: 30),
                  const Text(
                        'Video Downloader',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 1000.ms)
                      .slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 10),
                  const Text(
                    'Download videos from all platforms',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ).animate().fadeIn(delay: 800.ms, duration: 1000.ms),
                  const SizedBox(height: 50),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ).animate().fadeIn(delay: 1000.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
