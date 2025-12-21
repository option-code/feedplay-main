import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_model.dart';

class OfflineStorageService {
  static const String _horizontalGamesKey = 'cached_horizontal_games';
  static const String _verticalGamesKey = 'cached_vertical_games';
  static const String _lastUpdateKey = 'games_last_update';
  static const String _categoriesKey = 'cached_categories';
  static const String _unlockedGamesKey = 'unlocked_games';

  // Cache is permanent - never expires

  /// Save horizontal games to local storage
  static Future<void> saveHorizontalGames(List<GameModel> games) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gamesJson = games.map((game) => game.toJson()).toList();
      await prefs.setString(_horizontalGamesKey, jsonEncode(gamesJson));
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
      // Silent cache save
    } catch (e) {
      print('❌ Error saving horizontal games: $e');
    }
  }

  /// Save vertical games to local storage
  static Future<void> saveVerticalGames(List<GameModel> games) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gamesJson = games.map((game) => game.toJson()).toList();
      await prefs.setString(_verticalGamesKey, jsonEncode(gamesJson));
      // Silent cache save
    } catch (e) {
      print('❌ Error saving vertical games: $e');
    }
  }

  /// Save categories to local storage
  static Future<void> saveCategories(List<String> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_categoriesKey, categories);
      // Silent cache save
    } catch (e) {
      print('❌ Error saving categories: $e');
    }
  }

  /// Load horizontal games from local storage
  static Future<List<GameModel>> loadHorizontalGames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gamesString = prefs.getString(_horizontalGamesKey);
      
      if (gamesString == null) {
        return [];
      }

      final gamesJson = jsonDecode(gamesString) as List;
      final games = gamesJson.map((json) => GameModel.fromJson(json)).toList();
      // Silent load from cache
      return games;
    } catch (e) {
      print('❌ Error loading horizontal games: $e');
      return [];
    }
  }

  /// Load vertical games from local storage
  static Future<List<GameModel>> loadVerticalGames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gamesString = prefs.getString(_verticalGamesKey);
      
      if (gamesString == null) {
        return [];
      }

      final gamesJson = jsonDecode(gamesString) as List;
      final games = gamesJson.map((json) => GameModel.fromJson(json)).toList();
      // Silent load from cache
      return games;
    } catch (e) {
      print('❌ Error loading vertical games: $e');
      return [];
    }
  }

  /// Load categories from local storage
  static Future<List<String>> loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categories = prefs.getStringList(_categoriesKey) ?? [];
      // Silent load from cache
      return categories;
    } catch (e) {
      print('❌ Error loading categories: $e');
      return [];
    }
  }

  /// Check if cached data exists (cache is permanent - always valid if exists)
  static Future<bool> isCacheValid() async {
    try {
      final hasCache = await hasCachedData();
      // Silent check
      return hasCache;
    } catch (e) {
      print('❌ Error checking cache validity: $e');
      return false;
    }
  }

  /// Check if any cached data exists
  static Future<bool> hasCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasHorizontal = prefs.containsKey(_horizontalGamesKey);
      final hasVertical = prefs.containsKey(_verticalGamesKey);
      return hasHorizontal || hasVertical;
    } catch (e) {
      print('❌ Error checking cached data: $e');
      return false;
    }
  }

  /// Clear all cached game data (use only for debugging - cache is permanent)
  // Note: Cache is permanent and should not be cleared in normal operation
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_horizontalGamesKey);
      await prefs.remove(_verticalGamesKey);
      await prefs.remove(_categoriesKey);
      await prefs.remove(_lastUpdateKey);
      print('🗑️ Cleared all cached game data (debug only)');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  /// Save unlocked game ID
  static Future<void> unlockGame(String gameId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unlockedGames = prefs.getStringList(_unlockedGamesKey) ?? [];
      if (!unlockedGames.contains(gameId)) {
        unlockedGames.add(gameId);
        await prefs.setStringList(_unlockedGamesKey, unlockedGames);
      }
    } catch (e) {
      print('❌ Error unlocking game: $e');
    }
  }

  /// Check if game is unlocked
  static Future<bool> isGameUnlocked(String gameId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unlockedGames = prefs.getStringList(_unlockedGamesKey) ?? [];
      return unlockedGames.contains(gameId);
    } catch (e) {
      print('❌ Error checking unlocked game: $e');
      return false;
    }
  }

  /// Get all unlocked game IDs
  static Future<Set<String>> getUnlockedGames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final unlockedGames = prefs.getStringList(_unlockedGamesKey) ?? [];
      return unlockedGames.toSet();
    } catch (e) {
      print('❌ Error getting unlocked games: $e');
      return {};
    }
  }

  /// Get cache info for debugging
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getInt(_lastUpdateKey);
      final horizontalCount = await loadHorizontalGames();
      final verticalCount = await loadVerticalGames();
      final categories = await loadCategories();
      
      return {
        'lastUpdate': lastUpdate != null 
            ? DateTime.fromMillisecondsSinceEpoch(lastUpdate).toIso8601String()
            : null,
        'horizontalGamesCount': horizontalCount.length,
        'verticalGamesCount': verticalCount.length,
        'categoriesCount': categories.length,
        'isValid': await isCacheValid(),
        'hasCachedData': await hasCachedData(),
      };
    } catch (e) {
      print('❌ Error getting cache info: $e');
      return {};
    }
  }
}
