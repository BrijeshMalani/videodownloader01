import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/common.dart';

class WorkingNativeAdWidget extends StatefulWidget {
  const WorkingNativeAdWidget({super.key});

  @override
  State<WorkingNativeAdWidget> createState() => _WorkingNativeAdWidgetState();
}

class _WorkingNativeAdWidgetState extends State<WorkingNativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Delay ad loading to prevent crashes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadNativeAd();
      }
    });
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  void _loadNativeAd() {
    // Don't load if ad ID is empty or ads are disabled
    if (Common.native_ad_id.isEmpty || !Common.addOnOff) {
      debugPrint('Skipping native ad load - ad ID empty or ads disabled');
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🔄 Loading working native ad...');

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
            debugPrint('✅ Working native ad loaded successfully!');
            setState(() {
              _isAdLoaded = true;
              _isLoading = false;
            });
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('❌ Working native ad failed: ${error.message}');
            setState(() {
              _isAdLoaded = false;
              _isLoading = false;
            });
            ad.dispose();
            _nativeAd = null;

            // Retry after a longer delay
            Future.delayed(const Duration(seconds: 30), () {
              if (mounted) {
                _loadNativeAd();
              }
            });
          },
          onAdOpened: (ad) => debugPrint('Native ad opened'),
          onAdClosed: (ad) => debugPrint('Native ad closed'),
          onAdClicked: (ad) => debugPrint('Native ad clicked'),
          onAdImpression: (ad) => debugPrint('Native ad impression'),
        ),
      )..load();
    } catch (e) {
      debugPrint('Error loading native ad: $e');
      setState(() {
        _isAdLoaded = false;
        _isLoading = false;
        _nativeAd = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show ad if enabled, ad ID is not empty, and no active subscription
    if (Common.inAppPurchase ||
        !Common.addOnOff ||
        Common.native_ad_id.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _isAdLoaded && _nativeAd != null
            ? AdWidget(ad: _nativeAd!)
            : Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          Icons.ads_click,
                          color: Colors.grey[400],
                          size: 24,
                        ),
                      const SizedBox(height: 8),
                      Text(
                        _isLoading ? 'Loading Ad...' : 'Ad Not Available',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      if (!_isLoading) ...[
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: _loadNativeAd,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Retry',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
