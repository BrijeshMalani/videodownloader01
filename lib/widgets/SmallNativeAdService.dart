import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/common.dart';

class SmallNativeAdService {
  static final SmallNativeAdService _instance =
      SmallNativeAdService._internal();

  factory SmallNativeAdService() => _instance;

  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _isLoading = false;
  bool _isInitialized = false;

  SmallNativeAdService._internal();

  void initialize() {
    if (_isInitialized) {
      debugPrint('SmallNativeAdService already initialized');
      return;
    }

    debugPrint('Initializing SmallNativeAdService...');
    debugPrint('Ad enabled: ${Common.addOnOff}');
    debugPrint('Native ad ID: ${Common.native_ad_id}');

    // Configure test device for better ad loading
    MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: [
          '188CBD28D7B3F383A267B0FA91535B3B',
        ], // Your test device ID
      ),
    );

    // Check if MobileAds is already initialized
    MobileAds.instance
        .initialize()
        .then((_) {
          debugPrint(
            'MobileAds initialized successfully for SmallNativeAdService',
          );
          _isInitialized = true;
          if (Common.addOnOff && Common.native_ad_id.isNotEmpty) {
            debugPrint('Starting to load native ad...');
            // Delay initial load to avoid conflicts
            Future.delayed(const Duration(seconds: 2), () {
              _loadAd();
            });
          } else {
            debugPrint(
              'Skipping ad load - addOnOff: ${Common.addOnOff}, adId empty: ${Common.native_ad_id.isEmpty}',
            );
          }
        })
        .catchError((error) {
          debugPrint(
            'MobileAds initialization failed for SmallNativeAdService: $error',
          );
          _isInitialized = false;
        });
  }

  void _loadAd() {
    if (!_isInitialized) {
      debugPrint('MobileAds not initialized yet');
      return;
    }

    if (_isLoading) {
      debugPrint('Ad is already loading');
      return;
    }

    if (Common.native_ad_id.isEmpty) {
      debugPrint('Native ad ID is empty, skipping ad load');
      return;
    }

    if (!Common.addOnOff) {
      debugPrint('Ads are disabled');
      return;
    }

    _isLoading = true;
    debugPrint('Loading native ad with ID: ${Common.native_ad_id}');

    try {
      _nativeAd = NativeAd(
        adUnitId: Common.native_ad_id,
        request: const AdRequest(),
        nativeAdOptions: NativeAdOptions(
          mediaAspectRatio: MediaAspectRatio.landscape,
          videoOptions: VideoOptions(startMuted: true),
        ),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.small,
          mainBackgroundColor: Colors.white,
          cornerRadius: 10.0,
          callToActionTextStyle: NativeTemplateTextStyle(
            textColor: Colors.white,
            backgroundColor: Colors.red,
            style: NativeTemplateFontStyle.bold,
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
            _isAdLoaded = true;
            _isLoading = false;
            debugPrint('✅ NativeAd loaded successfully!');
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('❌ SmallNativeAd failed to load: $error');
            debugPrint('Error code: ${error.code}');
            debugPrint('Error message: ${error.message}');
            debugPrint('Error domain: ${error.domain}');
            _isAdLoaded = false;
            _isLoading = false;
            ad.dispose();
            _nativeAd = null;

            // Handle different error types
            int retryDelay = 30; // Default 30 seconds
            if (error.code == 1) {
              // Too many requests - wait longer
              retryDelay = 60;
              debugPrint(
                '⚠️ Too many requests, waiting ${retryDelay}s before retry',
              );
            } else if (error.code == 3) {
              // No fill - wait longer
              retryDelay = 45;
              debugPrint(
                '⚠️ No fill error, waiting ${retryDelay}s before retry',
              );
            }

            // Retry after delay
            Future.delayed(Duration(seconds: retryDelay), () {
              if (Common.addOnOff &&
                  Common.native_ad_id.isNotEmpty &&
                  !_isLoading) {
                debugPrint(
                  '🔄 Retrying to load native ad after ${retryDelay}s...',
                );
                _loadAd();
              }
            });
          },
          onAdOpened: (ad) {
            debugPrint('NativeAd opened');
          },
          onAdClosed: (ad) {
            debugPrint('NativeAd closed');
          },
          onAdClicked: (ad) {
            debugPrint('NativeAd clicked');
          },
          onAdImpression: (ad) {
            debugPrint('NativeAd impression recorded');
          },
        ),
      );

      debugPrint('Starting to load native ad...');
      _nativeAd!.load();
    } catch (e) {
      debugPrint('Exception while creating native ad: $e');
      _isLoading = false;
      _isAdLoaded = false;
    }
  }

  NativeAd? getAd() {
    // Check if user has active subscription

    if (!Common.addOnOff) {
      debugPrint('Ads are disabled');
      return null;
    }

    if (Common.native_ad_id.isEmpty) {
      debugPrint('Native ad ID is empty');
      return null;
    }

    if (!_isInitialized) {
      debugPrint('MobileAds not initialized');
      return null;
    }

    if (_nativeAd != null && _isAdLoaded) {
      final adToReturn = _nativeAd;
      debugPrint("Returning loaded native ad");

      // Reset for next ad
      _nativeAd = null;
      _isAdLoaded = false;

      // Load next ad in background
      Future.delayed(const Duration(milliseconds: 500), () {
        _loadAd();
      });

      return adToReturn;
    } else {
      debugPrint(
        'No ad available, current status - loaded: $_isAdLoaded, loading: $_isLoading',
      );
      if (!_isLoading) {
        _loadAd();
      }
      return null;
    }
  }

  bool get isAdReady => _isAdLoaded;

  bool get isInitialized => _isInitialized;

  void forceReload() {
    debugPrint('🔄 Force reloading native ad...');
    _nativeAd?.dispose();
    _nativeAd = null;
    _isAdLoaded = false;
    _isLoading = false;

    if (_isInitialized && Common.addOnOff && Common.native_ad_id.isNotEmpty) {
      _loadAd();
    }
  }

  void dispose() {
    debugPrint('🗑️ Disposing SmallNativeAdService...');
    _nativeAd?.dispose();
    _nativeAd = null;
    _isAdLoaded = false;
    _isLoading = false;
  }
}
