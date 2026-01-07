import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/game_model.dart';
import '../services/game_service.dart';
import '../services/interstitial_ads_service.dart';
import '../services/native_ads_service.dart'; // Import NativeAdsService
import 'game_player_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Import for NativeAdWidget
import '../widgets/gradient_circular_progress_indicator.dart';

class HorizontalGamesScreen extends StatefulWidget {
  const HorizontalGamesScreen({super.key});

  @override
  State<HorizontalGamesScreen> createState() => _HorizontalGamesScreenState();
}

class _HorizontalGamesScreenState extends State<HorizontalGamesScreen> {
  List<GameModel> games = [];
  bool isLoading = true;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _interleavedItems = []; // New list to hold games and ads

  @override
  void initState() {
    super.initState();
    loadGames();
    NativeAdsService.loadNativeAd(); // Start loading native ads
  }

  Future<void> loadGames() async {
    if (!mounted) return;
    try {
      setState(() {
        isLoading = true;
      });
      final loadedGames = await GameService.loadHorizontalGames();
      if (mounted) {
        setState(() {
          games = loadedGames;
          _buildInterleavedItems(); // Call to build the interleaved list
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error in loadGames: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          games = [];
          _interleavedItems = []; // Clear interleaved items on error too
        });
      }
    }
  }

  bool _adInserted = false;

  void _buildInterleavedItems() {
    _interleavedItems.clear();
    _adInserted = false; // Reset the flag when rebuilding the list

    if (kIsWeb) {
      // Agar web par hain, toh ads insert na karein
      _interleavedItems.addAll(filteredGames);
      return;
    }

    final List<int> adPositions = [1]; // Only show ad at position 1

    for (int i = 0; i < filteredGames.length; i++) {
      _interleavedItems.add(filteredGames[i]); // Add the current game

      // Check if an ad should be inserted after this game
      // i is 0-based index, so (i + 1) is the 1-based game number
      int currentGameNumber = i + 1;

      if (adPositions.contains(currentGameNumber) && !_adInserted) {
        final nativeAd = NativeAdsService.getAd();
        if (nativeAd != null) {
          print(
              'Native Ad: Ad found for insertion at position $currentGameNumber');
          _interleavedItems.add(nativeAd);
          _adInserted = true; // Mark ad as inserted
        } else {
          print(
              'Native Ad: No ad available for insertion at position $currentGameNumber');
        }
      }
    }
  }

  List<GameModel> get filteredGames {
    if (searchQuery.isEmpty) return games;
    return games.where((game) {
      final name = (game.gameName ?? game.name ?? '').toLowerCase();
      final category = (game.category ?? '').toLowerCase();
      final query = searchQuery.toLowerCase();
      return name.contains(query) || category.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horizontal Games'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadGames,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search games...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            searchQuery = '';
                            _buildInterleavedItems(); // Rebuild interleaved list
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF0B1C2C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  _buildInterleavedItems(); // Rebuild interleaved list on search query change
                });
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: GradientCircularProgressIndicator(
                      radius: 30.0,
                      strokeWidth: 6.0,
                      colors: [
                        Color(0xFFFF8C42), // Clean Orange
                        Color(0xFFFF1493), // Fresh Pink
                        Color(0xFF9D4EDD), // Vibrant Purple
                        Color(0xFF4361EE), // Clear Blue
                        Color(0xFF34D399), // Emerald Green
                        Color(0xFFFACC15), // Amber Yellow
                      ],
                      duration: Duration(seconds: 3),
                    ),
                  )
                : _interleavedItems.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.games, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No games found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _interleavedItems.length,
                        itemBuilder: (context, index) {
                          final item = _interleavedItems[index];
                          if (item is GameModel) {
                            return _GameCard(game: item);
                          } else if (item is NativeAd) {
                            return _NativeAdCard(ad: item);
                          }
                          return const SizedBox.shrink();
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _GameCard extends StatelessWidget {
  final GameModel game;

  const _GameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    // Capture parent context for navigation after modal closes
    final parentContext = context;

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF10141F),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Game icon
                  if (game.displayImagePath.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        game.displayImagePath,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.games, size: 56),
                      ),
                    ),
                  ] else
                    const Icon(Icons.games, size: 56, color: Colors.white),

                  const SizedBox(height: 18),
                  // App/game name
                  Text(
                    game.gameName ?? game.name ?? 'Unknown Game',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  // Favorite icon
                  IconButton(
                    icon: const Icon(Icons.favorite_border,
                        color: Colors.pinkAccent),
                    onPressed: () {},
                  ),
                  const SizedBox(height: 10),
                  // Description
                  if (game.description != null && game.description!.isNotEmpty)
                    Text(
                      game.description!,
                      style:
                          const TextStyle(fontSize: 14, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  if (game.description == null || game.description!.isEmpty)
                    const Text('-', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  // Play button (optional for actual navigation)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play'),
                    onPressed: () async {
                      Navigator.pop(context); // Close modal
                      if (game.gameUrl.isNotEmpty) {
                        // Store game info for navigation after ad
                        final gameName = game.gameName ?? game.name ?? 'Game';
                        final gameUrl = game.gameUrl;

                        // Show interstitial ad before playing game
                        await InterstitialAdsService.showInterstitialAd(
                          onAdDismissed: () {
                            print(
                                '📴 Interstitial ad dismissed, navigating to game...');
                            // Navigation will happen after await completes
                          },
                          onAdFailed: () {
                            print(
                                '❌ Interstitial ad failed, navigating to game anyway...');
                            // Navigation will happen after await completes
                          },
                        );

                        // Navigate to game after ad is dismissed or failed
                        // Use parent context for navigation (not modal context)
                        await Future.delayed(const Duration(milliseconds: 300));

                        if (parentContext.mounted) {
                          print('🎮 Navigating to game: $gameName');
                          Navigator.push(
                            parentContext,
                            MaterialPageRoute(
                              builder: (context) => GamePlayerScreen(
                                gameName: gameName,
                                gameUrl: gameUrl,
                              ),
                            ),
                          );
                        } else {
                          print(
                              '⚠️ Parent context not mounted, cannot navigate');
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
      child: Card(
        color: const Color(0xFF0A0E1A),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: game.displayImagePath.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: game.displayImagePath,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[800],
                          child: const Center(
                            child: GradientCircularProgressIndicator(
                              radius: 20.0,
                              strokeWidth: 4.0,
                              colors: [
                                Color(0xFFFF8C42), // Clean Orange
                                Color(0xFFFF1493), // Fresh Pink
                                Color(0xFF9D4EDD), // Vibrant Purple
                                Color(0xFF4361EE), // Clear Blue
                                Color(0xFF34D399), // Emerald Green
                                Color(0xFFFACC15), // Amber Yellow
                              ],
                              duration: Duration(seconds: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.games, size: 48),
                        ),
                      )
                    : Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.games, size: 48),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.gameName ?? game.name ?? 'Unknown Game',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (game.category != null)
                    Text(
                      game.category!,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NativeAdCard extends StatelessWidget {
  final NativeAd ad;

  const _NativeAdCard({required this.ad});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0A0E1A),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
