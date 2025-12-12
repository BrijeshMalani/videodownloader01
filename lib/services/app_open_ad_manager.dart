import 'dart:ui';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/common.dart';

class AppOpenAdManager {
  static final AppOpenAdManager _instance = AppOpenAdManager._internal();
  factory AppOpenAdManager() => _instance;
  AppOpenAdManager._internal();

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;

  void loadAd({VoidCallback? onAdLoaded}) {
    AppOpenAd.load(
      adUnitId: Common.app_open_ad_id,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          print("AppOpenAdLoaded");
          _appOpenAd = ad;
          if (onAdLoaded != null) {
            onAdLoaded();
          }
        },
        onAdFailedToLoad: (error) {
          print('AppOpenAd failed to load: $error');
          if (onAdLoaded != null) {
            onAdLoaded(); // Call callback even on failure to continue app flow
          }
        },
      ),
      // orientation: AppOpenAd.orientationPortrait,
    );
  }

  void showAdIfAvailable() async {
    if (_appOpenAd == null || _isShowingAd) return;

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => _isShowingAd = true,
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        _appOpenAd = null;
        loadAd(); // Preload next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        _appOpenAd = null;
        loadAd();
      },
    );

    _appOpenAd!.show();
  }

  void showAdWithCallback({required VoidCallback onAdDismissed}) async {
    if (_appOpenAd == null || _isShowingAd) {
      onAdDismissed();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => _isShowingAd = true,
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        _appOpenAd = null;
        loadAd();
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print("AdError----- $error");
        _isShowingAd = false;
        _appOpenAd = null;
        loadAd();
        onAdDismissed();
      },
    );

    _appOpenAd!.show();
  }
}
