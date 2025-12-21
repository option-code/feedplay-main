import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class InterstitialAdsService {
  static InterstitialAd? _interstitialAd;
  static bool _isLoading = false;
  static Completer<bool>? _loadingCompleter;
  static int _retryCount = 0;
  static const int _maxRetries = 3;
  static bool _isAdMobInitialized = false;

  /// Set AdMob initialization status
  static void setAdMobInitialized(bool initialized) {
    _isAdMobInitialized = initialized;
  }

  // Test Ad Unit IDs (replace with your actual Ad Unit IDs in production)
  // For Android: ca-app-pub-3940256099942544/1033173712
  // For iOS: ca-app-pub-3940256099942544/4411468910
  static const String _androidAdUnitId =
      'ca-app-pub-2927681167600861/5531137620';
  static const String _iosAdUnitId = 'ca-app-pub-2927681167600861/5531137620';

  /// Load an interstitial ad with retry logic
  static Future<bool> loadInterstitialAd({bool retry = false}) async {
    // Disable ads on web platform
    if (kIsWeb) {
      print('Interstitial Ad: Ads disabled on web platform');
      return false;
    }

    // Wait for AdMob initialization if not ready
    if (!_isAdMobInitialized && !retry) {
      print('Interstitial: AdMob not initialized yet, waiting...');
      int waitCount = 0;
      while (!_isAdMobInitialized && waitCount < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
      }
      if (!_isAdMobInitialized) {
        print(
            'Interstitial: AdMob initialization timeout, proceeding anyway...');
      }
    }

    if (_interstitialAd != null && !retry) {
      print('Interstitial: Ad already loaded, ready to show');
      return true;
    }

    if (!retry &&
        _loadingCompleter != null &&
        !_loadingCompleter!.isCompleted) {
      print('Interstitial: Ad load already in progress, waiting...');
      return _loadingCompleter!.future;
    }

    if (!retry && _isLoading && _loadingCompleter != null) {
      return _loadingCompleter!.future;
    }

    _isLoading = true;
    final completer = Completer<bool>();
    _loadingCompleter = completer;

    final adUnitId = kIsWeb
        ? _androidAdUnitId
        : defaultTargetPlatform == TargetPlatform.android
            ? _androidAdUnitId
            : _iosAdUnitId;

    void complete(bool value) {
      if (!completer.isCompleted) {
        completer.complete(value);
      }
      if (identical(_loadingCompleter, completer)) {
        _loadingCompleter = null;
      }
    }

    try {
      print('Interstitial: Loading ad (attempt ${_retryCount + 1})...');
      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isLoading = false;
            _retryCount = 0;
            print('✅ Interstitial ad loaded successfully!');
            complete(true);
          },
          onAdFailedToLoad: (error) {
            _isLoading = false;
            print(
                '❌ Interstitial ad failed to load: ${error.code} - ${error.message}');

            // Retry for JavascriptEngine errors
            if (error.code == 0 &&
                (error.message.contains('JavascriptEngine') ||
                    error.message.contains('Unable to obtain')) &&
                _retryCount < _maxRetries) {
              _retryCount++;
              final delaySeconds = _retryCount * 2;
              print(
                  '⏳ Retrying interstitial ad load in $delaySeconds seconds (attempt $_retryCount/$_maxRetries)');
              Future.delayed(Duration(seconds: delaySeconds), () async {
                final retryResult = await loadInterstitialAd(retry: true);
                complete(retryResult);
              });
            } else {
              _retryCount = 0;
              print('❌ Interstitial ad loading failed after all retries');
              complete(false);
            }
          },
        ),
      );
    } catch (e) {
      _isLoading = false;
      print('❌ Exception loading interstitial ad: $e');
      complete(false);
    }

    return completer.future;
  }

  /// Interstitial ads show before playing games (in the app)
  /// Show interstitial ad with callback
  static Future<bool> showInterstitialAd({
    VoidCallback? onAdDismissed,
    VoidCallback? onAdFailed,
  }) async {
    print('🎬 Attempting to show interstitial ad...');

    // Disable ads on web platform
    if (kIsWeb) {
      print(
          'Interstitial Ad: Ads disabled on web platform, calling dismissed callback directly');
      onAdDismissed?.call();
      return true;
    }

    // Ensure AdMob is initialized
    if (!_isAdMobInitialized) {
      print('⚠️ Interstitial: AdMob not initialized, initializing now...');
      try {
        await MobileAds.instance.initialize();
        _isAdMobInitialized = true;
      } catch (e) {
        print('❌ Failed to initialize AdMob: $e');
        onAdFailed?.call();
        return false;
      }
    }

    // Load ad if not already loaded
    if (_interstitialAd == null) {
      print('📥 Interstitial: No ad loaded, loading now...');
      final loaded = await loadInterstitialAd();
      if (!loaded) {
        print('❌ Interstitial: Failed to load ad');
        onAdFailed?.call();
        return false;
      }
    }

    if (_interstitialAd == null) {
      print('❌ Interstitial: Ad still not loaded after load attempt');
      onAdFailed?.call();
      return false;
    }

    // Show the ad
    final ad = _interstitialAd!;
    _interstitialAd = null; // Clear reference so we can load a new one

    // Use Completer to properly wait for ad completion
    final Completer<bool> completer = Completer<bool>();

    // Set full screen content callbacks BEFORE showing ad
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        print('✅ Interstitial ad is now showing full screen');
      },
      onAdDismissedFullScreenContent: (ad) {
        print('📴 Interstitial ad dismissed');
        ad.dispose();
        // Load next ad for future use (background)
        loadInterstitialAd();

        // Complete the completer
        if (!completer.isCompleted) {
          completer.complete(true);
        }

        // Call dismissed callback
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        print(
            '❌ Interstitial ad failed to show: ${error.code} - ${error.message}');
        // Try to load next ad
        loadInterstitialAd();

        // Complete the completer with failure
        if (!completer.isCompleted) {
          completer.complete(false);
        }

        onAdFailed?.call();
      },
    );

    // Show the ad
    try {
      print('▶️ Showing interstitial ad...');
      ad.show();
    } catch (e) {
      print('❌ Exception showing interstitial ad: $e');
      ad.dispose();
      _interstitialAd = null;
      if (!completer.isCompleted) {
        completer.complete(false);
      }
      onAdFailed?.call();
    }

    // Wait for ad to complete (dismissed or failed)
    final result = await completer.future;
    return result;
  }

  /// Preload interstitial ad (call this on app start)
  static Future<bool> preloadInterstitialAd() async {
    return await loadInterstitialAd();
  }

  /// Dispose resources
  static void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isLoading = false;
    _loadingCompleter = null;
  }
}
