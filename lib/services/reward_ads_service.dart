import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class RewardAdsService {
  static RewardedAd? _rewardedAd;
  static bool _isLoading = false;
  static Completer<bool>? _loadingCompleter;
  static int _retryCount = 0;
  static const int _maxRetries = 5; // Increased retries
  static bool _isAdMobInitialized = false;
  
  /// Set AdMob initialization status
  static void setAdMobInitialized(bool initialized) {
    _isAdMobInitialized = initialized;
  }

  // Test Ad Unit IDs (replace with your actual Ad Unit IDs in production)
  // For Android: ca-app-pub-3940256099942544/5224354917
  // For iOS: ca-app-pub-3940256099942544/1712485313
  static const String _androidAdUnitId = 'ca-app-pub-2927681167600861/3447173416';
  static const String _iosAdUnitId = 'ca-app-pub-2927681167600861/3447173416';

  /// Load a rewarded ad with retry logic and return whether an ad became available
  static Future<bool> loadRewardedAd({bool retry = false}) async {
    // Disable ads on web platform
    if (kIsWeb) {
      print('Rewarded Ad: Ads disabled on web platform');
      return false;
    }
    
    // Wait for AdMob initialization if not ready
    if (!_isAdMobInitialized && !retry) {
      print('AdMob not initialized yet, waiting...');
      int waitCount = 0;
      while (!_isAdMobInitialized && waitCount < 50) { // Wait up to 5 seconds
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
      }
      if (!_isAdMobInitialized) {
        print('AdMob initialization timeout, proceeding anyway...');
      }
    }
    
    if (_rewardedAd != null && !retry) {
      print('Ad already loaded, ready to show');
      return true;
    }

    if (!retry && _loadingCompleter != null && !_loadingCompleter!.isCompleted) {
      print('Ad load already in progress, waiting...');
      return _loadingCompleter!.future;
    }

    if (!retry && _isLoading && _loadingCompleter != null) {
      return _loadingCompleter!.future;
    }
    
    _isLoading = true;
    final completer = Completer<bool>();
    _loadingCompleter = completer;
    
    final adUnitId = kIsWeb 
        ? _androidAdUnitId // Default for web (use Android test ID)
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
      print('Loading rewarded ad (attempt ${_retryCount + 1})...');
    await RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
            _retryCount = 0; // Reset retry count on success
            print('✅ Rewarded ad loaded successfully!');
            complete(true);
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
            print('❌ Ad failed to load: ${error.code} - ${error.message}');
            print('Domain: ${error.domain}');
            
            // Retry for JavascriptEngine errors with longer delays
            if (error.code == 0 && 
                (error.message.contains('JavascriptEngine') || 
                 error.message.contains('Unable to obtain')) && 
                _retryCount < _maxRetries) {
              _retryCount++;
              final delaySeconds = _retryCount * 3; // Longer delays: 3s, 6s, 9s, 12s, 15s
              print('⏳ Retrying ad load in $delaySeconds seconds (attempt $_retryCount/$_maxRetries)');
              Future.delayed(Duration(seconds: delaySeconds), () async {
                final retryResult = await loadRewardedAd(retry: true);
                complete(retryResult);
              });
            } else {
              _retryCount = 0; // Reset on final failure
              print('❌ Ad loading failed after all retries');
              complete(false);
            }
        },
      ),
    );
    } catch (e) {
      _isLoading = false;
      print('❌ Exception loading ad: $e');
      complete(false);
    }

    return completer.future;
  }

  /// Rewarded ads show to unlock premium games
  /// Show rewarded ad with callback
  static Future<bool> showRewardedAd({
    required VoidCallback onAdRewarded,
    VoidCallback? onAdFailed,
  }) async {
    print('🎬 Attempting to show rewarded ad...');
    
    // Disable ads on web platform
    if (kIsWeb) {
      print('Rewarded Ad: Ads disabled on web platform, calling reward callback directly');
      onAdRewarded();
      return true;
    }
    
    // Ensure AdMob is initialized
    if (!_isAdMobInitialized) {
      print('⚠️ AdMob not initialized, initializing now...');
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
    if (_rewardedAd == null) {
      print('📥 No ad loaded, loading now...');
      final loaded = await loadRewardedAd();
      if (!loaded) {
        print('❌ Failed to load ad');
        onAdFailed?.call();
        return false;
      }
    }

    if (_rewardedAd == null) {
      print('❌ Ad still not loaded after load attempt');
      onAdFailed?.call();
      return false;
    }

    // Show the ad
    final ad = _rewardedAd!;
    _rewardedAd = null; // Clear reference so we can load a new one

    // Use Completer to properly wait for ad completion
    final Completer<bool> completer = Completer<bool>();
    bool userRewarded = false;

    // Set full screen content callbacks BEFORE showing ad
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        print('✅ Ad is now showing full screen');
      },
      onAdDismissedFullScreenContent: (ad) {
        print('📴 Ad dismissed, user rewarded: $userRewarded');
        ad.dispose();
        // Load next ad for future use (background)
        loadRewardedAd();
        
        // Complete the completer with reward status
        if (!completer.isCompleted) {
          completer.complete(userRewarded);
        }
        
        // If user didn't earn reward, call failed callback
        if (!userRewarded && onAdFailed != null) {
          onAdFailed();
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        print('❌ Ad failed to show: ${error.code} - ${error.message}');
        // Try to load next ad
        loadRewardedAd();
        
        // Complete the completer with failure
        if (!completer.isCompleted) {
          completer.complete(false);
        }
        
        onAdFailed?.call();
      },
    );

    // Show the ad with reward callback
    try {
      print('▶️ Showing ad...');
    ad.show(
      onUserEarnedReward: (ad, reward) {
        userRewarded = true;
          print('🎁 User earned reward: ${reward.type} - ${reward.amount}');
        // Call reward callback immediately when user earns reward
        onAdRewarded();
      },
    );
    } catch (e) {
      print('❌ Exception showing ad: $e');
      ad.dispose();
      _rewardedAd = null;
      if (!completer.isCompleted) {
        completer.complete(false);
      }
      onAdFailed?.call();
    }

    // Wait for ad to complete (dismissed or failed)
    final result = await completer.future;
    return result;
  }

  /// Preload rewarded ad (call this on app start)
  static Future<bool> preloadRewardedAd() async {
    return await loadRewardedAd();
  }

  /// Dispose resources
  static void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isLoading = false;
    _loadingCompleter = null;
  }
}

