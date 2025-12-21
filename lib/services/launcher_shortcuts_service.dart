import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../models/game_model.dart';

class LauncherShortcutsService {
  static const MethodChannel _channel = MethodChannel(
    'com.betapix.feedplay/shortcuts',
  );

  /// Check if platform supports shortcuts (Android 7.1+)
  static bool get isSupported {
    // Web platform doesn't support Platform.isAndroid
    if (kIsWeb) {
      return false;
    }
    try {
      return Platform.isAndroid;
    } catch (e) {
      // Platform check failed (e.g., on web)
      return false;
    }
  }

  /// Create shortcuts for 2 premium games
  /// Games format: "gameId|gameName|gameImage,gameId2|gameName2|gameImage2"
  static Future<bool> createShortcuts(List<GameModel> games) async {
    // User ne shortcut prompt ko disable karne ke liye kaha hai.
    // Isliye, hum shortcut creation logic ko skip kar rahe hain.
    print('⚠️ Launcher shortcuts creation is disabled as per user request.');
    return false;
  }

  /// Get deep link game ID if app was opened from shortcut
  static Future<String?> getDeepLinkGameId() async {
    if (!isSupported) {
      return null;
    }

    try {
      final gameId = await _channel.invokeMethod<String>('getDeepLinkGameId');
      if (gameId != null && gameId.isNotEmpty) {
        print('🔗 Deep link game ID received: $gameId');
        return gameId;
      }
      return null;
    } catch (e) {
      print('❌ Error getting deep link game ID: $e');
      return null;
    }
  }
}
