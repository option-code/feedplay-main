import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/game_model.dart';
import 'offline_storage_service.dart';
import 'connectivity_service.dart';

class GameService {
  /// Load all games from assets, preferring games.json (Playgama with clid).
  /// Falls back to data.json (GameMonetize). Returns unified GameModel list.
  static Future<List<GameModel>> _loadAllGamesFromJson() async {
    try {
      String jsonString = '';
      String source = '';

      // Prefer html5.json
      try {
        print('📂 Attempting to load assets/html5.json...');
        jsonString = await rootBundle.loadString('assets/html5.json');
        source = 'html5.json';
      } catch (_) {
        // Fallback to data.json
        print(
            'ℹ️ assets/html5.json not found, falling back to assets/data.json');
        jsonString = await rootBundle.loadString('assets/data.json');
        source = 'data.json';
      }

      if (jsonString.isEmpty) {
        print('❌ $source file is empty!');
        return [];
      }

      print('✅ Successfully loaded $source (${jsonString.length} characters)');
      final dynamic jsonData = json.decode(jsonString);

      final List<GameModel> allGames = [];

      // Check if it's an array (data.json format) or object with segments (games.json format)
      if (jsonData is List) {
        print(
            '📋 Detected array format ($source) with ${jsonData.length} items');
        // data.json format: direct array of games
        for (final gameData in jsonData) {
          try {
            if (gameData is Map<String, dynamic>) {
              final game = GameModel.fromJson(gameData);
              allGames.add(game);
            }
          } catch (e) {
            print('⚠️ Error parsing game: $e');
            // Continue with next game
          }
        }
      } else if (jsonData is Map<String, dynamic>) {
        print('📚 Detected object format ($source)');
        // Playgama format: segments array contains hits array (backward compatibility)
        final List<dynamic> segments = jsonData['segments'] ?? [];

        // Extract all games from all segments
        for (final segment in segments) {
          final hits = segment['hits'] as List<dynamic>?;
          if (hits != null) {
            for (final hit in hits) {
              try {
                final game = GameModel.fromJson(hit as Map<String, dynamic>);
                allGames.add(game);
              } catch (e) {
                print('⚠️ Error parsing game: $e');
                // Continue with next game
              }
            }
          }
        }
      } else {
        print('❌ Unknown JSON format: ${jsonData.runtimeType}');
        return [];
      }

      print('✅ Successfully parsed ${allGames.length} games from $source');
      print('   - Horizontal: ${allGames.where((g) => g.isHorizontal).length}');
      print('   - Vertical: ${allGames.where((g) => g.isVertical).length}');
      return allGames;
    } catch (e, stackTrace) {
      print('❌ Error loading games from assets: $e');
      print('Stack: $stackTrace');
      print(
          '💡 Tip: Ensure assets/games.json (preferred) or assets/data.json exists and is declared in pubspec.yaml');
      return [];
    }
  }

  /// Load horizontal games (from data.json or cache)
  static Future<List<GameModel>> loadHorizontalGames(
      {bool forceRefresh = false}) async {
    final connectivityService = ConnectivityService();
    final isOnline = connectivityService.isOnline;

    // If force refresh, clear cache and load fresh
    if (forceRefresh) {
      try {
        final allGames = await _loadAllGamesFromJson();
        // Filter horizontal games based on screenOrientation
        final horizontalGames =
            allGames.where((game) => game.isHorizontal).toList();

        // Save to cache with fresh data (includes images and genres)
        await OfflineStorageService.saveHorizontalGames(horizontalGames);

        print('✅ Force refreshed horizontal games with images/genres');
        return horizontalGames;
      } catch (e, stackTrace) {
        print('❌ Error force refreshing horizontal games: $e');
        print('Stack: $stackTrace');
        return [];
      }
    }

    // Always load from cache first if available (fast response)
    final hasCachedData = await OfflineStorageService.hasCachedData();

    if (hasCachedData) {
      // Silent load from cache (instant)
      final cachedGames = await OfflineStorageService.loadHorizontalGames();

      // Check if cached games have images/genres (new format)
      // If not, force refresh to get fresh data
      final hasNewFormat = cachedGames.isNotEmpty &&
          (cachedGames.first.images != null ||
              cachedGames.first.genres != null);

      if (!hasNewFormat && isOnline) {
        print('🔄 Cached games missing images/genres, refreshing...');
        // Force refresh in background to get images/genres
        _refreshHorizontalGamesInBackground();
      } else if (isOnline) {
        // Normal background refresh
        _refreshHorizontalGamesInBackground();
      }

      return cachedGames;
    }

    // No cache - load from data.json and save to cache
    try {
      final allGames = await _loadAllGamesFromJson();
      // Filter horizontal games based on screenOrientation
      final horizontalGames =
          allGames.where((game) => game.isHorizontal).toList();

      // Save to cache (permanent) - silent
      await OfflineStorageService.saveHorizontalGames(horizontalGames);

      print(
          '✅ Loaded ${horizontalGames.length} horizontal games with images/genres');
      return horizontalGames;
    } catch (e, stackTrace) {
      print('❌ Error loading horizontal games: $e');
      print('Stack: $stackTrace');
      return [];
    }
  }

  // Background refresh - updates cache silently (no user alerts)
  static Future<void> _refreshHorizontalGamesInBackground() async {
    try {
      final allGames = await _loadAllGamesFromJson();
      // Filter horizontal games based on screenOrientation
      final horizontalGames =
          allGames.where((game) => game.isHorizontal).toList();

      // Silently update cache in background
      await OfflineStorageService.saveHorizontalGames(horizontalGames);
    } catch (e) {
      // Silent error - no user alert
      print('⚠️ Background refresh failed: $e');
    }
  }

  /// Load vertical games (from data.json or cache)
  static Future<List<GameModel>> loadVerticalGames(
      {bool forceRefresh = false}) async {
    final connectivityService = ConnectivityService();
    final isOnline = connectivityService.isOnline;

    // If force refresh, clear cache and load fresh
    if (forceRefresh) {
      try {
        final allGames = await _loadAllGamesFromJson();
        // Filter vertical games based on screenOrientation
        final verticalGames =
            allGames.where((game) => game.isVertical).toList();

        // Save to cache with fresh data (includes images and genres)
        await OfflineStorageService.saveVerticalGames(verticalGames);

        print('✅ Force refreshed vertical games with images/genres');
        return verticalGames;
      } catch (e, stackTrace) {
        print('❌ Error force refreshing vertical games: $e');
        print('Stack: $stackTrace');
        return [];
      }
    }

    // Always load from cache first if available (fast response)
    final hasCachedData = await OfflineStorageService.hasCachedData();

    if (hasCachedData) {
      // Silent load from cache (instant)
      final cachedGames = await OfflineStorageService.loadVerticalGames();

      // Check if cached games have images/genres (new format)
      // If not, force refresh to get fresh data
      final hasNewFormat = cachedGames.isNotEmpty &&
          (cachedGames.first.images != null ||
              cachedGames.first.genres != null);

      if (!hasNewFormat && isOnline) {
        print('🔄 Cached games missing images/genres, refreshing...');
        // Force refresh in background to get images/genres
        _refreshVerticalGamesInBackground();
      } else if (isOnline) {
        // Normal background refresh
        _refreshVerticalGamesInBackground();
      }

      return cachedGames;
    }

    // No cache - load from data.json and save to cache
    try {
      final allGames = await _loadAllGamesFromJson();
      // Filter vertical games based on screenOrientation
      final verticalGames = allGames.where((game) => game.isVertical).toList();

      // Save to cache (permanent) - silent
      await OfflineStorageService.saveVerticalGames(verticalGames);

      print(
          '✅ Loaded ${verticalGames.length} vertical games with images/genres');
      return verticalGames;
    } catch (e, stackTrace) {
      print('❌ Error loading vertical games: $e');
      print('Stack: $stackTrace');
      return [];
    }
  }

  // Background refresh - updates cache silently (no user alerts)
  static Future<void> _refreshVerticalGamesInBackground() async {
    try {
      final allGames = await _loadAllGamesFromJson();
      // Filter vertical games based on screenOrientation
      final verticalGames = allGames.where((game) => game.isVertical).toList();

      // Silently update cache in background
      await OfflineStorageService.saveVerticalGames(verticalGames);
    } catch (e) {
      // Silent error - no user alert
      print('⚠️ Background refresh failed: $e');
    }
  }
}
