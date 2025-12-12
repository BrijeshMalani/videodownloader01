import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

class InitializationHelper {
  Future<FormError?> initialize() async {
    try {
      final completer = Completer<FormError?>();

      final params = ConsentRequestParameters();
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          try {
            if (await ConsentInformation.instance.isConsentFormAvailable()) {
              await _loadConsentForm();
            } else {
              await _initialize();
            }
            completer.complete();
          } catch (e) {
            debugPrint('Error in consent update callback: $e');
            // Continue with initialization even if consent fails
            try {
              await _initialize();
            } catch (initError) {
              debugPrint('Error in _initialize: $initError');
            }
            completer.complete();
          }
        },
        (error) {
          debugPrint('Consent info update error: $error');
          // Continue with initialization even if consent update fails
          try {
            _initialize()
                .then((_) {
                  completer.complete();
                })
                .catchError((e) {
                  debugPrint('Error in _initialize after consent error: $e');
                  completer.complete();
                });
          } catch (e) {
            completer.complete();
          }
        },
      );

      return completer.future;
    } catch (e) {
      debugPrint('Error in InitializationHelper.initialize: $e');
      // Return null to continue app initialization
      return null;
    }
  }

  Future<FormError?> _loadConsentForm() async {
    try {
      final completer = Completer<FormError?>();
      ConsentForm.loadConsentForm(
        (consentForm) async {
          try {
            final status = await ConsentInformation.instance.getConsentStatus();
            if (status == ConsentStatus.required) {
              consentForm.show((formError) {
                if (formError != null) {
                  debugPrint('Consent form error: $formError');
                }
                // Continue with initialization even if form has errors
                _initialize()
                    .then((_) {
                      completer.complete();
                    })
                    .catchError((e) {
                      debugPrint('Error in _initialize after consent form: $e');
                      completer.complete();
                    });
              });
            } else {
              await _initialize();
              completer.complete();
            }
          } catch (e) {
            debugPrint('Error in consent form callback: $e');
            try {
              await _initialize();
            } catch (initError) {
              debugPrint('Error in _initialize: $initError');
            }
            completer.complete();
          }
        },
        (formError) {
          debugPrint('Consent form load error: $formError');
          // Continue with initialization even if form load fails
          try {
            _initialize()
                .then((_) {
                  completer.complete();
                })
                .catchError((e) {
                  debugPrint('Error in _initialize after form load error: $e');
                  completer.complete();
                });
          } catch (e) {
            completer.complete();
          }
        },
      );

      return completer.future;
    } catch (e) {
      debugPrint('Error in _loadConsentForm: $e');
      try {
        await _initialize();
      } catch (initError) {
        debugPrint('Error in _initialize: $initError');
      }
      return null;
    }
  }

  Future<void> _initialize() async {
    try {
      await MobileAds.instance.initialize();
      debugPrint('MobileAds initialized successfully');
    } catch (e) {
      debugPrint('Error initializing MobileAds: $e');
      // Continue even if MobileAds initialization fails
    }
  }
}
