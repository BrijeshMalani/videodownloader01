import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/common.dart';

class NativeAdService {
  static final NativeAdService _instance = NativeAdService._internal();

  factory NativeAdService() => _instance;

  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  NativeAdService._internal();

  void initialize() {
    MobileAds.instance.initialize();
    if(Common.addOnOff){
      _loadAd(); // Initial preload
    }
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: Common.native_ad_id,
      request: const AdRequest(),
      nativeAdOptions: NativeAdOptions(
        mediaAspectRatio: MediaAspectRatio.landscape,
        videoOptions: VideoOptions(
          startMuted: true,
        ),
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.white,
        cornerRadius: 10.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: Colors.red,
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
          _isAdLoaded = true;
          debugPrint('NativeAd loaded');
        },
        onAdFailedToLoad: (ad, error) {
          // debugPrint('NativeAd failed to load: $error');
          _isAdLoaded = false;
          ad.dispose();
          _loadAd(); // Retry loading the ad
        },
      ),
    )..load();
  }

  NativeAd? getAd() {
    if(Common.addOnOff){
      if(_isAdLoaded && _nativeAd != null) {
        final adToReturn = _nativeAd;
        _nativeAd = null;
        _isAdLoaded = false;
        _loadAd();

        return adToReturn;
      }
      return null;
    }else{
      return null;
    }

  }

  bool get isAdReady => _isAdLoaded;
}
