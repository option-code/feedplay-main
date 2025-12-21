import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

import 'dart:async';

class NativeAdsService {
  static final List<NativeAd> _nativeAds = [];
  static bool _isLoading = false;
  static Completer<NativeAd?>? _loadingCompleter;
  static int _retryCount = 0;
  static const int _maxRetries = 3;
  static bool _isAdMobInitialized = false;
  static const int _maxAds = 10; // Keep up to 10 ads loaded

  /// Set AdMob initialization status
  static void setAdMobInitialized(bool initialized) {
    _isAdMobInitialized = initialized;
  }

  // Test Ad Unit IDs (replace with your actual Ad Unit IDs in production)
  // For Android: ca-app-pub-3940256099942544/2247696110
  // For iOS: ca-app-pub-3940256099942544/3986624511
  static const String _androidAdUnitId =
      'ca-app-pub-2927681167600861/2681613002'; // Replace with your actual AdMob native advanced ad unit ID
  static const String _iosAdUnitId =
      'ca-app-pub-2927681167600861/2681613002'; // Replace with your actual AdMob native advanced ad unit ID

  /// Load a native ad with retry logic
  static Future<NativeAd?> loadNativeAd({bool retry = false}) async {
    // Disable ads on web platform
    if (kIsWeb) {
      print('Native Ad: Ads disabled on web platform');
      return null;
    }

    // Wait for AdMob initialization if not ready
    if (!_isAdMobInitialized && !retry) {
      print('Native Ad: AdMob not initialized yet, waiting...');
      int waitCount = 0;
      while (!_isAdMobInitialized && waitCount < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
      }
      if (!_isAdMobInitialized) {
        print('Native Ad: AdMob initialization timeout, proceeding anyway...');
      }
    }

    if (_nativeAds.isNotEmpty && !retry) {
      print('Native Ad: Ad already loaded, ready to use');
      return _nativeAds.first;
    }

    if (!retry &&
        _loadingCompleter != null &&
        !_loadingCompleter!.isCompleted) {
      print('Native Ad: Ad load already in progress, waiting...');
      return _loadingCompleter!.future;
    }

    if (!retry && _isLoading && _loadingCompleter != null) {
      return _loadingCompleter!.future;
    }

    _isLoading = true;
    final completer = Completer<NativeAd?>();
    _loadingCompleter = completer;

    final adUnitId = kIsWeb
        ? _androidAdUnitId
        : defaultTargetPlatform == TargetPlatform.android
            ? _androidAdUnitId
            : _iosAdUnitId;

    void complete(NativeAd? value) {
      if (!completer.isCompleted) {
        completer.complete(value);
      }
      if (identical(_loadingCompleter, completer)) {
        _loadingCompleter = null;
      }
    }

    try {
      print('Loading native ad (attempt ${_retryCount + 1})...');
      final nativeAd = NativeAd(
        adUnitId: adUnitId,
        request: const AdRequest(),
        factoryId: 'native_ad_factory', // Add this line
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            _isLoading = false;
            _retryCount = 0;
            final loadedAd = ad as NativeAd;
            // Add to list if not already there
            if (!_nativeAds.contains(loadedAd)) {
              _nativeAds.add(loadedAd);
              // Keep only max ads
              if (_nativeAds.length > _maxAds) {
                _nativeAds.first.dispose();
                _nativeAds.removeAt(0);
              }
            }
            print(
                '✅ Native ad loaded successfully! (Total: ${_nativeAds.length})');
            complete(loadedAd);
          },
          onAdFailedToLoad: (ad, error) {
            _isLoading = false;
            try {
              ad.dispose();
            } catch (_) {}
            print(
                '❌ Native ad failed to load: ${error.code} - ${error.message}');

            // Retry for certain errors
            if ((error.code == 0 || error.code == 2) &&
                _retryCount < _maxRetries) {
              _retryCount++;
              final delaySeconds = _retryCount * 2;
              print(
                  '⏳ Retrying native ad load in $delaySeconds seconds (attempt $_retryCount/$_maxRetries)');
              Future.delayed(Duration(seconds: delaySeconds), () async {
                final retryResult = await loadNativeAd(retry: true);
                complete(retryResult);
              });
            } else {
              _retryCount = 0;
              print('❌ Native ad loading failed after all retries');
              complete(null);
            }
          },
          onAdClicked: (ad) {
            print('Native ad clicked');
          },
          onAdImpression: (ad) {
            print('Native ad impression recorded');
          },
        ),
      );

      // Load the ad
      nativeAd.load();
    } catch (e) {
      _isLoading = false;
      print('❌ Exception loading native ad: $e');
      complete(null);
    }

    return completer.future;
  }

  /// Get current native ad (if loaded)
  static NativeAd? getCurrentAd() {
    return _nativeAds.isNotEmpty ? _nativeAds.first : null;
  }

  /// Get a native ad from the pool (round-robin)
  static NativeAd? getAd() {
    if (_nativeAds.isEmpty) {
      print('Native Ad: No ads available in pool');
      return null;
    }
    // Return the first ad in the pool and remove it
    final ad = _nativeAds.removeAt(0);
    print(
        'Native Ad: Retrieved ad from pool and removed (remaining: ${_nativeAds.length})');
    return ad;
  }

  /// Check if any ads are available
  static bool hasAds() {
    final has = _nativeAds.isNotEmpty;
    print(
        'DEBUG: NativeAdsService.hasAds() returned: $has (Ad count: ${_nativeAds.length})');
    return has;
  }

  /// Get ad count
  static int getAdCount() {
    return _nativeAds.length;
  }

  /// Dispose current ads and load new ones
  static Future<NativeAd?> refreshAd() async {
    for (final ad in _nativeAds) {
      ad.dispose();
    }
    _nativeAds.clear();
    return await loadNativeAd();
  }

  /// Preload native ad (call this on app start)
  static Future<NativeAd?> preloadNativeAd() async {
    return await loadNativeAd();
  }

  /// Dispose resources
  static void dispose() {
    for (final ad in _nativeAds) {
      ad.dispose();
    }
    _nativeAds.clear();
    _isLoading = false;
    _loadingCompleter = null;
  }
}
