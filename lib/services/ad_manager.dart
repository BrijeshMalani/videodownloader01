import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../utils/common.dart';

class AdManager {
  static final AdManager _instance = AdManager._internal();

  factory AdManager() => _instance;

  AdManager._internal();

  InterstitialAd? _interstitialAd;
  NativeAd? _nativeAd;
  BannerAd? _bannerAd;
  AppOpenAd? _appOpenAd;
  bool _isInterstitialAdLoaded = false;
  bool _isNativeAdLoaded = false; // Unused
  bool _isBannerAdLoaded = false;
  bool _isAppOpenAdLoaded = false;
  int _retryAttempt = 0;
  static const int maxRetryAttempts = 3;
  VoidCallback? _onAdClosed;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _loadInterstitialAd();
    _loadAppOpenAd();
  }

  void _loadInterstitialAd() {
    // Don't load ad if ad ID is empty
    if (Common.interstitial_ad_id.isEmpty) {
      debugPrint('Interstitial ad ID is empty, skipping ad load');
      return;
    }

    InterstitialAd.load(
      adUnitId: Common.interstitial_ad_id,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
          _retryAttempt = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isInterstitialAdLoaded = false;
          _retryAttempt++;
          if (_retryAttempt <= maxRetryAttempts) {
            Future.delayed(const Duration(seconds: 2), () {
              _loadInterstitialAd();
            });
          }
        },
      ),
    );
  }

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: Common.native_ad_id,
      request: const AdRequest(),
      nativeAdOptions: NativeAdOptions(
        mediaAspectRatio: MediaAspectRatio.landscape,
        videoOptions: VideoOptions(startMuted: true),
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.white,
        cornerRadius: 10.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: Colors.blue,
          style: NativeTemplateFontStyle.monospace,
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black,
          backgroundColor: Colors.white,
          style: NativeTemplateFontStyle.normal,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey,
          backgroundColor: Colors.white,
          style: NativeTemplateFontStyle.normal,
          size: 14.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey,
          backgroundColor: Colors.white,
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _isNativeAdLoaded = true;
          _retryAttempt = 0;
        },
        onAdFailedToLoad: (ad, error) {
          _isNativeAdLoaded = false;
          _retryAttempt++;
          if (_retryAttempt <= maxRetryAttempts) {
            Future.delayed(const Duration(seconds: 2), () {
              _loadNativeAd();
            });
          }
        },
      ),
    )..load();
  }

  void _loadBannerAd() {
    print("Loading Banner Ad");
    if (_bannerAd != null) {
      _bannerAd!.dispose();
    }
    _bannerAd = BannerAd(
      adUnitId: Common.bannar_ad_id,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print("BannerAdLoaded $ad");
          _isBannerAdLoaded = true;
          _retryAttempt = 0;
        },
        onAdFailedToLoad: (ad, error) {
          print("BannerAdError $error");
          _isBannerAdLoaded = false;
          _retryAttempt++;
          if (_retryAttempt <= maxRetryAttempts) {
            Future.delayed(const Duration(seconds: 1), () {
              _loadBannerAd();
            });
          }
          ad.dispose();
        },
      ),
    )..load();
  }

  void _loadAppOpenAd() {
    if (kIsWeb) return; // Skip for web platform

    // Don't load ad if ad ID is empty
    if (Common.app_open_ad_id.isEmpty) {
      debugPrint('App open ad ID is empty, skipping ad load');
      return;
    }

    AppOpenAd.load(
      adUnitId: Common.app_open_ad_id,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          print("App Open Ad Loaded Successfully");
          _appOpenAd = ad;
          _isAppOpenAdLoaded = true;
          _retryAttempt = 0;
        },
        onAdFailedToLoad: (error) {
          print("App Open Ad Failed to Load: $error");
          _isAppOpenAdLoaded = false;
          _retryAttempt++;
          if (_retryAttempt <= maxRetryAttempts) {
            Future.delayed(const Duration(seconds: 2), () {
              _loadAppOpenAd();
            });
          }
          // If ad fails to load, execute the navigation callback immediately
          if (_onAdClosed != null) {
            _onAdClosed!();
            _onAdClosed = null;
          }
        },
      ),
    );
  }

  void showInterstitialAd() async {
    if (Common.addOnOff) {
      if (Common.ads_int_open_count == Common.interNumberShow) {
        Common.interNumberShow = 1;
        Common.recentlyOpened = true;
        if (_isInterstitialAdLoaded && _interstitialAd != null) {
          // Set timestamp when interstitial ad is about to be shown
          Common.lastInterstitialAdTime = DateTime.now();
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (InterstitialAd ad) {
                  ad.dispose();
                  Common.recentlyOpened = false;
                  _isInterstitialAdLoaded = false;
                  _loadInterstitialAd();
                  // Show app open ad after interstitial ad is closed
                  showAppOpenAd();
                },
                onAdFailedToShowFullScreenContent:
                    (InterstitialAd ad, AdError error) {
                      ad.dispose();
                      _isInterstitialAdLoaded = false;
                      Common.recentlyOpened = false;
                      _loadInterstitialAd();
                    },
              );
          _interstitialAd!.show();
        }
      } else {
        Common.recentlyOpened = false;
        Common.interNumberShow++;
      }
    }
  }

  void showAppOpenAd({VoidCallback? onAdClosed}) async {
    if (kIsWeb) {
      if (onAdClosed != null) onAdClosed();
      return;
    }

    if (_isAppOpenAdLoaded && _appOpenAd != null) {
      print("Showing App Open Ad");
      _onAdClosed = onAdClosed;
      _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (AppOpenAd ad) {
          print("App Open Ad Dismissed");
          ad.dispose();
          _isAppOpenAdLoaded = false;
          _loadAppOpenAd();
          // Execute the navigation callback after ad is closed
          if (_onAdClosed != null) {
            _onAdClosed!();
            _onAdClosed = null;
          }
        },
        onAdFailedToShowFullScreenContent: (AppOpenAd ad, AdError error) {
          print("App Open Ad Failed to Show: $error");
          ad.dispose();
          _isAppOpenAdLoaded = false;
          _loadAppOpenAd();
          // Execute the navigation callback if ad fails to show
          if (_onAdClosed != null) {
            _onAdClosed!();
            _onAdClosed = null;
          }
        },
      );
      _appOpenAd!.show();
    } else {
      print("App Open Ad Not Loaded");
      // If ad is not loaded, execute the navigation callback immediately
      if (onAdClosed != null) {
        onAdClosed();
      }
    }
  }

  // Widget getNativeAd() {
  //   if (!_isNativeAdLoaded || _nativeAd == null) {
  //     return const SizedBox.shrink();
  //   }
  //
  //   return CustomNativeAd(nativeAd: _nativeAd!);
  // }

  Future<Widget> getBannerAd() async {
    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  void dispose() {
    _interstitialAd?.dispose();
    _nativeAd?.dispose();
    _bannerAd?.dispose();
    _appOpenAd?.dispose();
  }
}
