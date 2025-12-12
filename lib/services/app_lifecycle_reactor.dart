// import 'package:flutter/widgets.dart';
// import 'app_open_ad_manager.dart';
//
// /// Listens for app lifecycle state changes and shows app open ads when appropriate.
// class AppLifecycleReactor extends WidgetsBindingObserver {
//   final AppOpenAdManager appOpenAdManager;
//
//   AppLifecycleReactor({required this.appOpenAdManager});
//
//   void listenToAppStateChanges() {
//     WidgetsBinding.instance.addObserver(this);
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     // Show the ad if the app is being resumed and was in background
//     if (state == AppLifecycleState.resumed) {
//       appOpenAdManager.onAppResume();
//     } else if (state == AppLifecycleState.paused ||
//         state == AppLifecycleState.inactive) {
//       appOpenAdManager.onAppPause();
//     }
//   }
// }
