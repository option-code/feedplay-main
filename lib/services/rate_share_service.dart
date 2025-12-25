import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:in_app_review/in_app_review.dart';

class RateShareService {
  static const String _hasRatedKey = 'has_rated_app';
  static const String _hasSharedKey = 'has_shared_app';
  static const String _lastRateReminderDateKey = 'last_rate_reminder_date';
  static const String _lastShareReminderDateKey = 'last_share_reminder_date';
  static const String _rateReminderDismissedKey = 'rate_reminder_dismissed';
  static const String _shareReminderDismissedKey = 'share_reminder_dismissed';
  static const String _gamesPlayedCountKey = 'games_played_count';
  static const String _rateDialogShownKey = 'rate_dialog_shown';
  static const String _shareDialogShownKey = 'share_dialog_shown';

  /// Check if user has already rated the app
  static Future<bool> hasRated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasRatedKey) ?? false;
  }

  /// Check if user has already shared the app
  static Future<bool> hasShared() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSharedKey) ?? false;
  }

  /// Mark app as rated
  static Future<void> markAsRated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasRatedKey, true);
    await prefs.setBool(_rateReminderDismissedKey, false);
    await prefs.remove(_lastRateReminderDateKey);
  }

  /// Mark app as shared
  static Future<void> markAsShared() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSharedKey, true);
    await prefs.setBool(_shareReminderDismissedKey, false);
    await prefs.remove(_lastShareReminderDateKey);
  }

  /// Get games played count
  static Future<int> getGamesPlayedCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_gamesPlayedCountKey) ?? 0;
  }

  /// Increment games played count
  static Future<int> incrementGamesPlayedCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_gamesPlayedCountKey) ?? 0;
    final newCount = currentCount + 1;
    await prefs.setInt(_gamesPlayedCountKey, newCount);
    print('🎮 Games played count: $newCount');
    return newCount;
  }

  /// Check if rate reminder should be shown (after 2 games)
  static Future<bool> shouldShowRateReminder() async {
    // Don't show if user has already rated
    if (await hasRated()) return false;

    // Don't show if already shown
    final prefs = await SharedPreferences.getInstance();
    final rateDialogShown = prefs.getBool(_rateDialogShownKey) ?? false;
    if (rateDialogShown) return false;

    // Show after 2 games played
    final gamesPlayed = await getGamesPlayedCount();
    return gamesPlayed >= 2;
  }

  /// Check if share reminder should be shown (after 4 games)
  static Future<bool> shouldShowShareReminder() async {
    // Don't show if user has already shared
    if (await hasShared()) return false;

    // Don't show if already shown
    final prefs = await SharedPreferences.getInstance();
    final shareDialogShown = prefs.getBool(_shareDialogShownKey) ?? false;
    if (shareDialogShown) return false;

    // Show after 4 games played
    final gamesPlayed = await getGamesPlayedCount();
    return gamesPlayed >= 4;
  }

  /// Mark rate dialog as shown
  static Future<void> markRateDialogShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rateDialogShownKey, true);
  }

  /// Mark share dialog as shown
  static Future<void> markShareDialogShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_shareDialogShownKey, true);
  }

  /// Update last rate reminder date (when user clicks "Later")
  static Future<void> updateLastRateReminderDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastRateReminderDateKey,
      DateTime.now().toIso8601String(),
    );
    await prefs.setBool(_rateReminderDismissedKey, true);
    // Don't mark as shown, so it can be shown again later
  }

  /// Update last share reminder date (when user clicks "Later")
  static Future<void> updateLastShareReminderDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastShareReminderDateKey,
      DateTime.now().toIso8601String(),
    );
    await prefs.setBool(_shareReminderDismissedKey, true);
    // Don't mark as shown, so it can be shown again later
  }

  /// Open app store for rating
  static Future<void> rateApp() async {
    try {
      final InAppReview inAppReview = InAppReview.instance;

      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        // We don't mark as rated here because the user might dismiss the dialog
        // without actually leaving a review.
      } else {
        // Fallback to opening the store listing if in-app review is not available
        // Android Play Store URL (replace with your actual package name)
        const androidUrl =
            'https://play.google.com/store/apps/details?id=com.betapix.feedplay';
        // iOS App Store URL (replace with your actual app ID)
        const iosUrl = 'https://apps.apple.com/app/id1234567890';

        // Detect platform and use appropriate URL
        final url = Uri.parse(
          defaultTargetPlatform == TargetPlatform.iOS ? iosUrl : androidUrl,
        );

        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          // We can mark as rated here, as the user is explicitly taken to the store.
          await markAsRated();
        }
      }
    } catch (e) {
      print('Error opening app store or showing in-app review: $e');
    }
  }

  /// Share the app
  static Future<void> shareApp() async {
    try {
      await HapticFeedback.mediumImpact();
      await SharePlus.instance.share(
        ShareParams(
          text:
              'Check out FeedPlay - Your Gateway to HTML5 Gaming!\n\nPlay unlimited games anytime, anywhere!\n\nDownload now: https://play.google.com/store/apps/details?id=com.betapix.feedplay',
          subject: 'FeedPlay - Amazing Games App',
        ),
      );
      await markAsShared();
    } catch (e) {
      print('Error sharing app: $e');
    }
  }
}
