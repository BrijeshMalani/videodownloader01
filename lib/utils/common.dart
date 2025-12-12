import 'package:url_launcher/url_launcher.dart';

class Common {
  static String lanopen = "0";
  static String packageName = 'com.example.videodownloader01';

  static bool addOnOff = true; // Temporarily disabled to prevent crashes
  static bool inAppPurchase = false;
  static bool recentlyOpened = false;
  static int interNumberShow = 1;
  static DateTime? lastInterstitialAdTime;
  static bool isAppInBackground = false;

  // Test Ad IDs (for development)
  // static String bannar_ad_id = 'ca-app-pub-3940256099942544/2435281174';
  // static String interstitial_ad_id = 'ca-app-pub-3940256099942544/4411468910';
  // static String interstitial_ad_id1 = 'ca-app-pub-3940256099942544/4411468910';
  // static String interstitial_ad_id2 = 'ca-app-pub-3940256099942544/4411468910';
  // static String native_ad_id = 'ca-app-pub-3940256099942544/3986624511';
  // static String app_open_ad_id = 'ca-app-pub-3940256099942544/5575463023';

  // Production Ad IDs (uncomment and use these for production)
  static String bannar_ad_id = ''; //admobId
  static String interstitial_ad_id = ''; //admobFull
  static String interstitial_ad_id1 = ''; //admobFull
  static String interstitial_ad_id2 = ''; //admobFull
  static String native_ad_id = ''; //admobNative
  static String app_open_ad_id = ''; //rewardedInt

  static String privacy_policy = ''; //rewardedFull
  static String terms_conditions = ''; //rewardedFull2
  static String ads_open_count = ''; //rewardedFull1
  static int ads_int_open_count = 1; //rewardedFull2
  static String adsopen = ''; //startapprewarded 2-show qureka
  static String showvideos = ''; // 2-show videos
  static String Qurekaid = '';
  static String appBundleId = ''; //fbfull
  static String playstore_link =
      'https://play.google.com/store/apps/details?id=com.itvmovie.itvmovie'; //startAppFull

  // No Ads
  static bool no_ads_enabled = true;

  static String no_ads_product_id = 'week';
  static String no_ads_key = 'no_ads_purchased';

  static Future<void> openUrl() async {
    final Uri url = Uri.parse(Qurekaid); // tamaro link
    for (int i = 0; i < int.parse(ads_open_count); i++) {
      if (!await launchUrl(
        url,
        mode: LaunchMode.inAppBrowserView, // Chrome custom tab
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
        ),
      )) {
        throw Exception('Could not launch $url');
      }
    }
  }

  static Future<void> openLink() async {
    final Uri url = Uri.parse(Qurekaid); // tamaro link
    if (!await launchUrl(
      url,
      mode: LaunchMode.inAppBrowserView, // Chrome custom tab
      webViewConfiguration: const WebViewConfiguration(enableJavaScript: true),
    )) {
      throw Exception('Could not launch $url');
    }
  }
}
