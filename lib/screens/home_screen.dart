import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'package:flutter/services.dart';

import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart' as webview_flutter;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/game_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/offline_storage_service.dart';
import '../services/notification_service.dart';
import '../services/reward_ads_service.dart';
import '../services/interstitial_ads_service.dart';
import '../services/native_ads_service.dart';
import '../services/launcher_shortcuts_service.dart';
import '../services/rate_share_service.dart';
import '../services/consent_dialog_service.dart';
import '../services/connectivity_service.dart';

import '../services/in_app_update_service.dart';
import '../models/game_model.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/blink_sound.dart' as blink_sound;
import '../widgets/gradient_circular_progress_indicator.dart';

// import 'game_player_screen.dart';

// Native Ad Widget that looks like a game tile
class _NativeAdWidget extends StatelessWidget {
  final NativeAd nativeAd;

  const _NativeAdWidget({required this.nativeAd});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
            Color(0xFFEC4899),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AdWidget(ad: nativeAd),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFEC4899),
                      Color(0xFF8B5CF6),
                      Color(0xFF6366F1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'AD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NativeAdPlaceholder extends StatelessWidget {
  const _NativeAdPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
            Color(0xFFEC4899),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'AD',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// Image Carousel Widget with Page Indicators
class _ImageCarousel extends StatefulWidget {
  final List<String> images;
  final String Function(GameModel) resolveImageUrl;

  const _ImageCarousel({
    required this.images,
    required this.resolveImageUrl,
  });

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    final page = _pageController.page?.round() ?? 0;
    if (page != _currentPage) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            pageSnapping: true,
            itemBuilder: (context, index) {
              final imageUrl = widget.images[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: widget.resolveImageUrl(GameModel(
                      imagePath: imageUrl,
                    )),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[800],
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF6366F1),
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[800],
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: Colors.white54,
                      ),
                    ),
                    fadeInDuration: const Duration(milliseconds: 300),
                    fadeInCurve: Curves.easeOut,
                  ),
                ),
              ); // Closes the return statement of itemBuilder
            }, // Closes the itemBuilder function
          ),
        ),
        // Page Indicator
        if (widget.images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentPage
                        ? const Color(0xFF6366F1)
                        : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Horizontal Favourites List with swipe effects
class _HorizontalFavoritesList extends StatefulWidget {
  final List<GameModel> favoriteGames;
  final Function(GameModel) onGameTap;
  final bool Function(GameModel) isPremium;
  final bool Function(GameModel) isFreeForToday;

  const _HorizontalFavoritesList({
    required this.favoriteGames,
    required this.onGameTap,
    required this.isPremium,
    required this.isFreeForToday,
  });

  @override
  State<_HorizontalFavoritesList> createState() =>
      _HorizontalFavoritesListState();
}

class _HorizontalFavoritesListState extends State<_HorizontalFavoritesList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollFavorites(double offset) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final target = (_scrollController.offset + offset).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  String _resolveImageUrl(GameModel game) {
    final url = game.displayImagePath;
    if (kIsWeb && url.startsWith('http')) {
      return 'https://images.weserv.nl/?url=${Uri.encodeComponent(url)}';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final showNavButtons = screenWidth >= 600; // Show buttons on tablet/desktop

    Widget buildItem(GameModel game) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
              Color(0xFFEC4899),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F2E).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: game.imagePath != null && game.imagePath!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: _resolveImageUrl(game),
                            fit: BoxFit.cover,
                            memCacheWidth: 280,
                            memCacheHeight: 280,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[800],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF8B5CF6),
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.games,
                                size: 36,
                                color: Colors.white70,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.games,
                              size: 36,
                              color: Colors.white70,
                            ),
                          ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Text(
                      game.gameName ?? game.name ?? 'Game',
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        height: 1.15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.isFreeForToday(game))
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF10B981),
                          Color(0xFF3B82F6),
                          Color(0xFF6366F1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Text(
                      'FREE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else if (widget.isPremium(game))
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final listView = ListView.separated(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: showNavButtons ? 60 : 12),
      physics: const BouncingScrollPhysics(),
      itemCount: widget.favoriteGames.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final game = widget.favoriteGames[index];
        return InkWell(
          onTap: () => widget.onGameTap(game),
          child: SizedBox(
            width: 140,
            child: Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..setTranslationRaw(0.0, 0.0, 10.0),
              alignment: FractionalOffset.center,
              child: buildItem(game),
            ),
          ),
        );
      },
    );

    if (!showNavButtons) {
      return listView;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        listView,
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: _CategoryNavButton(
              icon: Icons.chevron_left_rounded,
              onTap: () => _scrollFavorites(-220),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _CategoryNavButton(
              icon: Icons.chevron_right_rounded,
              onTap: () => _scrollFavorites(220),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryNavButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFF0F1626).withValues(alpha: 0.85),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          // Glassy effect with semi-transparent background
          color:
              Theme.of(context).appColors.cardBackground.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.5,
          ),
          // Glassy shine effect
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).appColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null)
              trailing!
            else
              Icon(Icons.chevron_right,
                  color: Theme.of(context).appColors.textSecondary, size: 24),
          ],
        ),
      ),
    );
  }
}

class _LinkItem extends StatelessWidget {
  final String title;
  final String url;
  final VoidCallback onTap;

  const _LinkItem({
    required this.title,
    required this.url,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF172136).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                  Text(
                    url,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.open_in_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late ScrollController _scrollController;
  DateTime? _lastAdRefreshTime; // Track last ad refresh time

  List<GameModel> horizontalGames = [];

  List<String> categories = [];
  bool isLoading =
      false; // Start with false since games are preloaded in splash
  String searchQuery = '';
  String selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _categoryScrollController = ScrollController();

  Set<String> favoriteGameIds = {};
  bool _isSearchBarVisible = false;
  Set<String> premiumGameIds = {}; // Store unique IDs of premium games
  Set<String> freeForTodayIds =
      {}; // Store IDs of 2 premium games that are free today
  List<GameModel> verticalGames = []; // Store vertical games separately
  Set<String> unlockedGameIds = {}; // Cache unlocked game IDs
  BuildContext? _currentModalContext; // Track open modal context

  // Connectivity
  final ConnectivityService _connectivityService = ConnectivityService();

  List<GameModel> get favoriteGames {
    // Get unique favorite games using Set to avoid duplicates
    final Set<String> seenIds = {};
    return horizontalGames.where((g) {
      if (!isFavorite(g)) return false;
      final uniqueId = _getUniqueGameId(g);
      if (seenIds.contains(uniqueId)) return false;
      seenIds.add(uniqueId);
      return true;
    }).toList();
  }

  Future<void> _upgradeFavoriteIdsIfNeeded() async {
    // If stored favorites are legacy (name-only), convert them to name|url
    if (favoriteGameIds.isEmpty) return;
    final bool hasLegacy = favoriteGameIds.any((id) => !id.contains('|'));
    if (!hasLegacy) return;

    final Map<String, String> nameToUnique = {
      for (final g in horizontalGames)
        (g.gameName ?? g.name ?? ''): _getUniqueGameId(g)
    };

    final Set<String> upgraded = favoriteGameIds.map((id) {
      if (id.contains('|')) return id; // already upgraded
      final mapped = nameToUnique[id];
      return mapped ?? id; // if not found, keep as-is to avoid data loss
    }).toSet();

    if (mounted) {
      setState(() {
        favoriteGameIds = upgraded;
      });
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_games', favoriteGameIds.toList());
  }

  void _scrollCategories(double offset) {
    if (!_categoryScrollController.hasClients) return;
    final position = _categoryScrollController.position;
    final target = (_categoryScrollController.offset + offset)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    _categoryScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addObserver(this);

    // Initialize connectivity service
    _connectivityService.initialize();

    // Unlocked games reset on every app restart (session-based, like premium games)
    unlockedGameIds = {};

    // Listen to connectivity changes (silent - no user alerts)
    _connectivityService.connectionChange.listen((bool isConnected) {
      if (mounted) {
        // Silent background refresh when back online
        if (isConnected) {
          // Silently refresh cache in background
          loadGames();
        }
        // Offline mode - automatically uses cached data (silent)
      }
    });

    loadFavorites();
    // Preload games in background before showing home screen
    // This prevents loading spinner from showing after splash
    loadGames(forceRefresh: true).then((_) {
      // Games loaded, ready to show
    });

    // Preload native ads (load multiple for better coverage)
    print('🎯 Starting native ad preload...');
    NativeAdsService.preloadNativeAd().then((ad) {
      print(
          '🎯 Native ad preload result: ${ad != null ? "SUCCESS" : "FAILED"}');
      if (mounted && ad != null) {
        print(
            '✅ Native ad preloaded. Total ads: ${NativeAdsService.getAdCount()}');
        // Load additional ads in background
        for (int i = 0; i < 2; i++) {
          Future.delayed(Duration(seconds: (i + 1) * 3), () {
            NativeAdsService.loadNativeAd().then((newAd) {
              if (newAd != null && mounted) {
                print(
                    '✅ Additional native ad loaded (${i + 1}/2). Total: ${NativeAdsService.getAdCount()}');
              }
            });
          });
        }
      } else {
        print('❌ Native ad preload failed or widget not mounted');
      }
    }).catchError((error) {
      print('❌ Native ad preload error: $error');
    });

    // Note: Rate/Share reminders are now shown based on games played count
    // (Rate after 2 games, Share after 4 games)

    // Check and show launcher shortcuts permission dialog
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _checkAndShowShortcutsPermission();
      }
    });

    // Show consent dialog on first launch
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        ConsentDialogService.showConsentDialogIfNeeded(context);
      }
    });

    // Check for app updates on launch
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        InAppUpdateService.checkForUpdateOnLaunch(context);
      }
    });
  }

  // Check and show launcher shortcuts permission dialog
  Future<void> _checkAndShowShortcutsPermission() async {
    // Only show on Android
    if (!LauncherShortcutsService.isSupported) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasAskedBefore =
          prefs.getBool('launcher_shortcuts_permission_asked') ?? false;
      final userAllowed = prefs.getBool('launcher_shortcuts_allowed') ?? false;

      // If user already allowed, create shortcuts (wait for games to load)
      if (userAllowed) {
        // Wait a bit for games to load, then create shortcuts
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _createShortcutsForPremiumGames();
          }
        });
        return;
      }

      // If we've asked before and user said no, don't ask again
      if (hasAskedBefore) {
        return;
      }

      // Show permission dialog
      if (!mounted) return;

      // showDialog(
      //   context: context,
      //   barrierDismissible: false,
      //   builder: (BuildContext dialogContext) {
      //     return AlertDialog(
      //       backgroundColor: const Color(0xFF1A1F2E),
      //       shape: RoundedRectangleBorder(
      //         borderRadius: BorderRadius.circular(20),
      //       ),
      //       title: const Text(
      //         'Home Screen Shortcuts',
      //         style: TextStyle(
      //           color: Colors.white,
      //           fontSize: 20,
      //           fontWeight: FontWeight.bold,
      //         ),
      //       ),
      //       content: const Text(
      //         'Kya aap chahenge ke premium games aapke home screen par shortcut ke tor pe show hon? Aap shortcuts se directly games play kar sakte hain.',
      //         style: TextStyle(
      //           color: Colors.white70,
      //           fontSize: 16,
      //         ),
      //       ),
      //       actions: [
      //         TextButton(
      //           onPressed: () async {
      //             // User said no
      //             final prefs = await SharedPreferences.getInstance();
      //             await prefs.setBool(
      //                 'launcher_shortcuts_permission_asked', true);
      //             await prefs.setBool('launcher_shortcuts_allowed', false);
      //             if (mounted && dialogContext.mounted) {
      //               Navigator.of(dialogContext).pop();
      //             }
      //           },
      //           child: const Text(
      //             'Not Now',
      //             style: TextStyle(color: Colors.white54),
      //           ),
      //         ),
      //         ElevatedButton(
      //           onPressed: () async {
      //             // User said yes
      //             final prefs = await SharedPreferences.getInstance();
      //             await prefs.setBool(
      //                 'launcher_shortcuts_permission_asked', true);
      //             await prefs.setBool('launcher_shortcuts_allowed', true);
      //             if (mounted && dialogContext.mounted) {
      //               Navigator.of(dialogContext).pop();
      //             }
      //             // Create shortcuts
      //             _createShortcutsForPremiumGames();
      //           },
      //           style: ElevatedButton.styleFrom(
      //             backgroundColor: const Color(0xFF6366F1),
      //             foregroundColor: Colors.white,
      //             shape: RoundedRectangleBorder(
      //               borderRadius: BorderRadius.circular(12),
      //             ),
      //           ),
      //           child: const Text('Allow'),
      //         ),
      //       ],
      //     );
      //   },
      // );
    } catch (e) {
      print('❌ Error showing shortcuts permission dialog: $e');
    }
  }

  // Create shortcuts for 2 premium games
  Future<void> _createShortcutsForPremiumGames() async {
    try {
      // Wait for games to be loaded
      if (horizontalGames.isEmpty) {
        print('⏳ Waiting for games to load before creating shortcuts...');
        // Retry after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _createShortcutsForPremiumGames();
          }
        });
        return;
      }

      // Get premium games
      final premiumGames =
          horizontalGames.where((game) => isPremium(game)).toList();

      if (premiumGames.length < 2) {
        print(
            '⚠️ Not enough premium games to create shortcuts (found ${premiumGames.length}, need 2)');
        return;
      }

      // Take first 2 premium games
      final gamesForShortcuts = premiumGames.take(2).toList();

      print(
          '📱 Creating shortcuts for ${gamesForShortcuts.length} premium games:');
      for (final game in gamesForShortcuts) {
        print('   - ${game.gameName ?? game.name}');
      }

      final success =
          await LauncherShortcutsService.createShortcuts(gamesForShortcuts);

      if (success) {
        print('✅ Launcher shortcuts created successfully');
      } else {
        print('❌ Failed to create launcher shortcuts');
      }
    } catch (e) {
      print('❌ Error creating shortcuts: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _categoryScrollController.dispose();
    _searchController.dispose();
    _connectivityService.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _currentModalContext = null;
    super.dispose();
  }

  // Helper function to check if index should show an ad (only if ad is actually loaded)
  // Works for ALL categories: All, Premium, Favourites, and all other categories
  static const int _adGap = 10;

  bool _shouldShowAd(int index) {
    // Disable native ads on web platform
    if (kIsWeb) {
      return false;
    }

    print('DEBUG: _shouldShowAd called for index: $index');
    if (filteredGames.isEmpty) {
      print('DEBUG: _shouldShowAd: filteredGames is empty, returning false');
      return false;
    }
    final shouldShow = index % _adGap == 0;
    print(
        'DEBUG: _shouldShowAd: index $index, gap: $_adGap, shouldShow: $shouldShow');
    return shouldShow;
  }

  // Helper function to get actual game index accounting for ads that are actually displayed
  int _getGameIndex(int displayIndex) {
    if (kIsWeb) { // Agar web par hain, toh ads ko account na karein
      return displayIndex;
    }
    final adCount = (displayIndex ~/ _adGap) + 1;
    return displayIndex - adCount;
  }

  // Get total item count including only ads that are actually loaded and displayed
  // Works for ALL categories: All, Premium, Favourites, and all other categories
  int _getTotalItemCount() {
    final gameCount = filteredGames.length;
    if (gameCount == 0) return 0;

    if (kIsWeb) { // Agar web par hain, toh total item count sirf games ka count hoga
      return gameCount;
    }

    int displayIndex = 0;
    int gamesPlaced = 0;
    while (gamesPlaced < gameCount) {
      if (displayIndex % _adGap == 0) {
        displayIndex++;
        continue;
      }
      gamesPlaced++;
      displayIndex++;
    }
    return displayIndex;
  }

  // Rate/Share dialogs are now shown in GameScreen based on games played count
  // (Rate after 2 games, Share after 4 games)

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getStringList('favorite_games') ?? [];
    setState(() {
      favoriteGameIds = favoritesJson.toSet();
    });
  }

  String _getUniqueGameId(GameModel game) {
    // Use name + URL combination for unique ID to avoid duplicates
    final name = game.gameName ?? game.name ?? '';
    final url = game.gameUrl.isNotEmpty ? game.gameUrl : (game.url ?? '');
    return '$name|$url';
  }

  // Get display name (before colon if exists)
  String _getDisplayName(GameModel game) {
    final fullName = game.gameName ?? game.name ?? 'Unknown Game';
    // If name contains ":", show only the part before colon
    if (fullName.contains(':')) {
      return fullName.split(':').first.trim();
    }
    return fullName;
  }

  void _setPremiumGames(List<GameModel> allGames) {
    if (allGames.isEmpty) return;

    // Get total count and select 70% of games randomly
    final totalGames = allGames.length;
    // Calculate 70% of total games (rounded up)
    final premiumCount = (totalGames * 0.7).ceil();

    // Create a list of all unique game IDs
    final allGameIds = allGames.map((g) => _getUniqueGameId(g)).toList();

    // Shuffle and select random 70% of games
    // Note: Shuffle creates random order - sequence will be different each time app restarts
    final shuffled = List<String>.from(allGameIds)..shuffle();
    premiumGameIds = shuffled.take(premiumCount).toSet();

    // Select 2 random premium games as "free for today"
    final premiumList = premiumGameIds.toList()..shuffle();
    freeForTodayIds = premiumList.take(5).toSet();

    // Debug: Print premium games info
    print('🔒 Premium Games Info:');
    print('   Total Games: $totalGames');
    print('   Premium Games Count: $premiumCount (70% of total games)');
    print(
        '   Free Games Count: ${totalGames - premiumCount} (30% of total games)');
    print('   Free for Today: ${freeForTodayIds.length} games');
    print('   Selection: Random (shuffled)');
    print(
        '   Note: Premium games are selected randomly, different 70% games on each app restart');
  }

  bool isPremium(GameModel game) {
    final gameId = _getUniqueGameId(game);
    return premiumGameIds.contains(gameId);
  }

  bool isFreeForToday(GameModel game) {
    final gameId = _getUniqueGameId(game);
    return freeForTodayIds.contains(gameId);
  }

  /// Check if game is unlocked (either free for today or unlocked via ad)
  Future<bool> isGameUnlocked(GameModel game) async {
    final gameId = _getUniqueGameId(game);
    // Free for today games are always unlocked
    if (isFreeForToday(game)) return true;
    // Check if premium game is unlocked
    if (isPremium(game)) {
      return unlockedGameIds.contains(gameId);
    }
    // Non-premium games are always unlocked
    return true;
  }

  String _resolveImageUrl(GameModel game) {
    final url = game.displayImagePath;
    if (kIsWeb && url.startsWith('http')) {
      // Use an image proxy to avoid CORS issues on web
      return 'https://images.weserv.nl/?url=${Uri.encodeComponent(url)}';
    }
    return url;
  }

  Future<void> toggleFavorite(GameModel game) async {
    final prefs = await SharedPreferences.getInstance();
    final gameId = _getUniqueGameId(game);

    setState(() {
      if (favoriteGameIds.contains(gameId)) {
        favoriteGameIds.remove(gameId);
      } else {
        favoriteGameIds.add(gameId);
      }
    });

    await prefs.setStringList('favorite_games', favoriteGameIds.toList());
  }

  bool isFavorite(GameModel game) {
    final gameId = _getUniqueGameId(game);
    return favoriteGameIds.contains(gameId);
  }

  void _showGameModal(BuildContext context, GameModel game) {
    // Capture parent context for navigation after modal closes
    final parentContext = context;

    // Always open from root navigator to avoid being blocked by lingering overlays after many ads
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      clipBehavior: Clip.hardEdge,
      builder: (context) {
        // Store modal context for pull-to-refresh closing
        _currentModalContext = context;
        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              _currentModalContext = null;
            }
          },
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Stack(
                children: [
                  Container(
                    margin: EdgeInsets.zero,
                    constraints: const BoxConstraints.expand(),
                    decoration: BoxDecoration(
                      // Enhanced glassy gradient for modal
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF1A1F2E).withValues(alpha: 0.95),
                          const Color(0xFF0F1419).withValues(alpha: 0.98),
                          const Color(0xFF0A0E1A).withValues(alpha: 1.0),
                        ],
                      ),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(32)),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      // Enhanced glassy shine effect for modal
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 25,
                          offset: const Offset(0, -10),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(top: 12, right: 12),
                              child: IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.white),
                                iconSize: 24,
                                onPressed: () async {
                                  await SystemSound.play(SystemSoundType.click);
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: game.imagePath != null &&
                                      game.imagePath!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: _resolveImageUrl(game),
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      // Optimize memory for small game icons
                                      memCacheWidth:
                                          240, // 120px * 2 for retina
                                      memCacheHeight: 240,
                                      placeholder: (context, url) => Container(
                                        width: 120,
                                        height: 120,
                                        color: Colors.grey[800],
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF8B5CF6),
                                            strokeWidth: 3,
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        width: 120,
                                        height: 120,
                                        color: Colors.grey[800],
                                        child: const Icon(Icons.games,
                                            size: 60, color: Colors.white),
                                      ),
                                      fadeInDuration:
                                          const Duration(milliseconds: 200),
                                      fadeInCurve: Curves.easeOut,
                                    )
                                  : Container(
                                      width: 120,
                                      height: 120,
                                      color: Colors.grey[800],
                                      child: const Icon(Icons.games,
                                          size: 60, color: Colors.white),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            _getDisplayName(game),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          IconButton(
                            icon: Icon(
                              isFavorite(game)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite(game)
                                  ? Colors.red
                                  : Colors.white70,
                              size: 32,
                            ),
                            onPressed: () async {
                              await SystemSound.play(SystemSoundType.click);
                              await toggleFavorite(game);
                              if (mounted) setState(() {});
                              setModalState(() {});
                            },
                          ),
                          const SizedBox(height: 16),
                          if (game.description != null &&
                              game.description!.isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                game.description!,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'No description available',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          // Swipeable Images Carousel
                          if (game.images != null &&
                              game.images!.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _ImageCarousel(
                                images: game.images!,
                                resolveImageUrl: _resolveImageUrl),
                          ],
                          // Genres Display
                          if (game.genres != null &&
                              game.genres!.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Genres',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: game.genres!.map((genre) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF6366F1),
                                              Color(0xFF8B5CF6),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF6366F1)
                                                  .withValues(alpha: 0.2),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          genre,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          // Mobile Ready Display
                          if (game.mobileReady != null &&
                              game.mobileReady!.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Available On',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: game.mobileReady!.map((platform) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF10B981),
                                              Color(0xFF3B82F6),
                                              Color(0xFF6366F1),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF10B981)
                                                  .withValues(alpha: 0.5),
                                              blurRadius: 12,
                                              spreadRadius: 2,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              platform.contains('Android')
                                                  ? Icons.android
                                                  : platform.contains('IOS')
                                                      ? Icons.phone_iphone
                                                      : Icons.desktop_windows,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              platform.replaceAll('For ', ''),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          // Additional Info Row (Gender, In-Game Purchases, Languages)
                          if ((game.gender != null &&
                                  game.gender!.isNotEmpty) ||
                              (game.inGamePurchases != null &&
                                  game.inGamePurchases!.isNotEmpty) ||
                              (game.supportedLanguages != null &&
                                  game.supportedLanguages!.isNotEmpty)) ...[
                            const SizedBox(height: 20),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Gender
                                  if (game.gender != null &&
                                      game.gender!.isNotEmpty) ...[
                                    Row(
                                      children: [
                                        const Icon(Icons.people,
                                            size: 18, color: Colors.white70),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Gender: ',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          game.gender!.join(', '),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  // In-Game Purchases
                                  if (game.inGamePurchases != null &&
                                      game.inGamePurchases!.isNotEmpty) ...[
                                    Row(
                                      children: [
                                        const Icon(Icons.shopping_cart,
                                            size: 18, color: Colors.white70),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'In-Game Purchases: ',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          game.inGamePurchases!,
                                          style: TextStyle(
                                            color: game.inGamePurchases == 'Yes'
                                                ? const Color(0xFF10B981)
                                                : Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  // Supported Languages
                                  if (game.supportedLanguages != null &&
                                      game.supportedLanguages!.isNotEmpty) ...[
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.language,
                                            size: 18, color: Colors.white70),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Languages: ',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Expanded(
                                          child: Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            children: game.supportedLanguages!
                                                .map((lang) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  lang,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FutureBuilder<bool>(
                              future: isGameUnlocked(game),
                              builder: (context, snapshot) {
                                final isUnlocked = snapshot.data ?? false;
                                final isLocked = isPremium(game) &&
                                    !isFreeForToday(game) &&
                                    !isUnlocked;

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () async {
                                      if (game.gameUrl.isEmpty) return;

                                      // Check network connectivity
                                      bool isOnline =
                                          await ConnectivityService()
                                              .checkConnection();
                                      if (!isOnline) {
                                        if (parentContext.mounted) {
                                          ScaffoldMessenger.of(parentContext)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "You're offline",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                ),
                                              ),
                                              backgroundColor:
                                                  Colors.transparent,
                                              elevation: 0,
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                        return; // Prevent game launch if offline
                                      }

                                      // Check if game is locked
                                      if (isLocked) {
                                        // Show loading indicator
                                        if (!context.mounted) return;
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (context) => const Center(
                                            child: CircularProgressIndicator(
                                                color: Color(0xFF6366F1)),
                                          ),
                                        );

                                        // Show rewarded ad (waits until ad completes)
                                        final rewarded = await RewardAdsService
                                            .showRewardedAd(
                                          onAdRewarded: () {
                                            // Unlock the game (session-based, resets on app restart)
                                            final gameId =
                                                _getUniqueGameId(game);
                                            unlockedGameIds.add(gameId);

                                            // Update modal state to reflect unlock
                                            setModalState(() {});
                                          },
                                          onAdFailed: () {
                                            // Silent error handling - ad failed or user dismissed without reward
                                          },
                                        );

                                        // Close loading dialog after ad completes
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                        }

                                        // If user earned reward, close modal and play game
                                        if (rewarded && context.mounted) {
                                          // Close modal
                                          Navigator.pop(context);

                                          // Navigate to game
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  GameScreen(game: game),
                                            ),
                                          );
                                        }
                                        // If ad didn't reward, just close loading - modal stays open
                                      } else {
                                        // Game is unlocked - show interstitial ad before playing
                                        // Store game reference and close modal
                                        final gameToPlay = game;
                                        if (!context.mounted) return;
                                        Navigator.pop(context); // Close modal

                                        // Show loading indicator before interstitial ad
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (context) => const Center(
                                            child: CircularProgressIndicator(
                                                color: Color(0xFF6366F1)),
                                          ),
                                        );

                                        // Check if the game is "free for today"
                                        if (isFreeForToday(gameToPlay)) {
                                          print(
                                              '🎮 Free game, navigating directly to game: ${gameToPlay.gameName}');
                                        } else {
                                          // Show interstitial ad, then navigate to game using parent context
                                          await InterstitialAdsService
                                              .showInterstitialAd(
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
                                        }

                                        // Close loading dialog after ad completes
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                        }

                                        // Navigate to game after ad is dismissed or failed
                                        // Use parent context for navigation (not modal context)
                                        await Future.delayed(
                                            const Duration(milliseconds: 300));

                                        if (parentContext.mounted) {
                                          print(
                                              '🎮 Navigating to game: ${gameToPlay.gameName}');
                                          Navigator.push(
                                            parentContext,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  GameScreen(game: gameToPlay),
                                            ),
                                          );
                                        } else {
                                          print(
                                              '⚠️ Parent context not mounted, cannot navigate');
                                        }
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(18),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: isLocked
                                              ? [
                                                  const Color(0xFF6366F1),
                                                  const Color(0xFF8B5CF6),
                                                  const Color(0xFFEC4899),
                                                ]
                                              : [
                                                  const Color(0xFF10B981),
                                                  const Color(0xFF3B82F6),
                                                  const Color(0xFF6366F1),
                                                ],
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isLocked
                                                    ? const Color(0xFF6366F1)
                                                    : const Color(0xFF10B981))
                                                .withValues(alpha: 0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 18),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            isLocked
                                                ? Icons.lock_open_rounded
                                                : Icons.play_arrow_rounded,
                                            size: 28,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            isLocked
                                                ? 'Watch Ad to Unlock'
                                                : 'Play Now',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showSettingsModal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // User has scrolled to the end of the list
      _refreshAds();
    } else if (_scrollController.position.pixels ==
        _scrollController.position.minScrollExtent) {
      // User has scrolled to the beginning of the list
      _refreshAds();
    } else {
      // Implement time-based refresh if not at the ends
      _refreshAds();
    }
  }

  void _refreshAds() {
    final now = DateTime.now();
    if (_lastAdRefreshTime == null ||
        now.difference(_lastAdRefreshTime!) > const Duration(seconds: 30)) {
      NativeAdsService.refreshAd().then((_) {
        if (mounted) {
          setState(() {
            _lastAdRefreshTime = now;
          });
        }
      });
    }
  }

  Future<void> loadGames({bool forceRefresh = false}) async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }
    final hGames =
        await GameService.loadHorizontalGames(forceRefresh: forceRefresh);
    final vGames =
        await GameService.loadVerticalGames(forceRefresh: forceRefresh);

    List<String> uniqueCategories = [];

    // Try to load categories from cache first
    final cachedCategories = await OfflineStorageService.loadCategories();
    if (cachedCategories.isNotEmpty && (hGames.isEmpty && vGames.isEmpty)) {
      // If no games but cached categories exist, use them
      uniqueCategories = cachedCategories
          .where((cat) => cat != 'All' && cat != 'Premium')
          .toList();
      // Silent load from cache
    } else if (hGames.isNotEmpty || vGames.isNotEmpty) {
      // Extract categories from games
      final Map<String, String> lowerToOriginal = {};
      for (final game in [...hGames, ...vGames]) {
        final raw = game.category?.trim();
        if (raw == null || raw.isEmpty) continue;
        final lower = raw.toLowerCase();
        lowerToOriginal.putIfAbsent(lower, () => raw);
      }
      uniqueCategories = lowerToOriginal.values.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      // Always cache categories (permanent)
      await OfflineStorageService.saveCategories(
          ['All', 'Premium', ...uniqueCategories]);
    }

    // Combine horizontal and vertical games, removing duplicates
    final allGames = <GameModel>[];
    final seenGameIds = <String>{};

    // Add horizontal games first
    for (final game in hGames) {
      final gameId = _getUniqueGameId(game);
      if (!seenGameIds.contains(gameId)) {
        allGames.add(game);
        seenGameIds.add(gameId);
      }
    }

    // Add vertical games, skipping duplicates
    for (final game in vGames) {
      final gameId = _getUniqueGameId(game);
      if (!seenGameIds.contains(gameId)) {
        allGames.add(game);
        seenGameIds.add(gameId);
      }
    }

    // Only set premium games if they haven't been set yet (first time only)
    // This ensures premium games don't change on pull-to-refresh
    // They will only change on full app restart when state is reset
    if (premiumGameIds.isEmpty && allGames.isNotEmpty) {
      _setPremiumGames(allGames);
    }

    if (mounted) {
      setState(() {
        horizontalGames = allGames;
        verticalGames = vGames.where((g) {
          final gameId = _getUniqueGameId(g);
          return !seenGameIds.contains(gameId) ||
              (seenGameIds.contains(gameId) &&
                  hGames.any((hg) => _getUniqueGameId(hg) == gameId));
        }).toList(); // Store vertical games separately for favorites filter
        categories = ['All', 'Premium', ...uniqueCategories];
        isLoading = false;
        selectedCategory = 'All';
      });
    }

    await _upgradeFavoriteIdsIfNeeded();
  }

  List<GameModel> get filteredGames {
    if (selectedCategory == 'Favourites') {
      // Show all favorite games in grid format
      var favs = favoriteGames;
      if (searchQuery.isNotEmpty) {
        favs = favs
            .where((g) => (g.gameName ?? g.name ?? '')
                .toLowerCase()
                .contains(searchQuery.toLowerCase()))
            .toList();
      }
      // Remove duplicates from favorites
      final uniqueFavs = <GameModel>[];
      final seenIds = <String>{};
      for (final game in favs) {
        final gameId = _getUniqueGameId(game);
        if (!seenIds.contains(gameId)) {
          uniqueFavs.add(game);
          seenIds.add(gameId);
        }
      }
      return uniqueFavs;
    }
    var games = horizontalGames;
    if (selectedCategory == 'Premium') {
      // Show only premium (locked) games (including 2 free for today)
      // Favorite games will also show in Premium category
      games = games.where((g) => isPremium(g)).toList();

      // Sort: FREE games first in Premium category
      games.sort((a, b) {
        final aFree = isFreeForToday(a);
        final bFree = isFreeForToday(b);
        if (aFree && !bFree) return -1;
        if (!aFree && bFree) return 1;
        return 0;
      });
    } else if (selectedCategory == 'All') {
      // In "All" category, exclude FREE games only
      // Favorite games will also show in All category
      games = games.where((g) => !isFreeForToday(g)).toList();
    } else {
      // Other categories: exclude FREE games and filter by category
      // Favorite games will also show in their original categories
      games = games
          .where((g) => !isFreeForToday(g) && g.category == selectedCategory)
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      games = games
          .where((g) => (g.gameName ?? g.name ?? '')
              .toLowerCase()
              .contains(searchQuery.toLowerCase()))
          .toList();
    }

    // Remove duplicates from filtered games list
    final uniqueGames = <GameModel>[];
    final seenIds = <String>{};
    for (final game in games) {
      final gameId = _getUniqueGameId(game);
      if (!seenIds.contains(gameId)) {
        uniqueGames.add(game);
        seenIds.add(gameId);
      }
    }

    return uniqueGames;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    int gridCrossAxisCount = 2;
    double gridChildAspectRatio = 0.75;
    double gridSpacing = 18;

    if (screenWidth >= 1800) {
      gridCrossAxisCount = 6;
      gridChildAspectRatio = 0.95;
      gridSpacing = 20;
    } else if (screenWidth >= 1500) {
      gridCrossAxisCount = 5;
      gridChildAspectRatio = 0.95;
      gridSpacing = 18;
    } else if (screenWidth >= 1200) {
      gridCrossAxisCount = 4;
      gridChildAspectRatio = 0.9;
      gridSpacing = 18;
    } else if (screenWidth >= 900) {
      gridCrossAxisCount = 3;
      gridChildAspectRatio = 0.82;
      gridSpacing = 16;
    } else if (screenWidth >= 700) {
      gridCrossAxisCount = 3;
      gridChildAspectRatio = 0.78;
      gridSpacing = 16;
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.3, 0.7, 1.0],
            colors: [
              Color(0xFF0A0E1A),
              Color(0xFF0F1419),
              Color(0xFF1A1F2E),
              Color(0xFF0F1419),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () async {
              if (_currentModalContext != null) {
                Navigator.pop(_currentModalContext!);
                _currentModalContext = null;
              }
              await loadGames(forceRefresh: true);
            },
            color: const Color(0xFF6366F1),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              cacheExtent: 500, // Cache 500px of items for smoother scrolling
              slivers: [
                // New Modern Header with App Name
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF6366F1)
                                            .withValues(alpha: 0.4),
                                        blurRadius: 15,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.asset(
                                      'assets/splash.png',
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF6366F1),
                                                Color(0xFF8B5CF6)
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          child: const Icon(Icons.games,
                                              color: Colors.white, size: 28),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                // VR Depth Search Button - pops out of screen
                                Transform(
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.001)
                                    ..setTranslationRaw(0.0, 0.0, 8.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      // Glassy effect with semi-transparent background
                                      color: const Color(0xFF1A1F2E)
                                          .withValues(alpha: 0.6),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.25),
                                        width: 1.5,
                                      ),
                                      // VR depth shadows - multiple layers
                                      boxShadow: [
                                        // Deep shadow for VR pop-out
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.6),
                                          blurRadius: 25,
                                          spreadRadius: 6,
                                          offset: const Offset(0, 12),
                                        ),
                                        // Mid shadow
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.4),
                                          blurRadius: 18,
                                          spreadRadius: 4,
                                          offset: const Offset(0, 8),
                                        ),
                                        // Glassy shine
                                        BoxShadow(
                                          color: Colors.white
                                              .withValues(alpha: 0.15),
                                          blurRadius: 20,
                                          spreadRadius: -8,
                                          offset: const Offset(-8, -8),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () {
                                          setState(
                                              () => _isSearchBarVisible = true);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(14),
                                          child: const Icon(
                                              Icons.search_rounded,
                                              color: Colors.white,
                                              size: 22),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // VR Depth Settings Button - pops out of screen
                                Transform(
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.001)
                                    ..setTranslationRaw(0.0, 0.0, 8.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      // Glassy effect with semi-transparent background
                                      color: const Color(0xFF1A1F2E)
                                          .withValues(alpha: 0.6),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.25),
                                        width: 1.5,
                                      ),
                                      // VR depth shadows - multiple layers
                                      boxShadow: [
                                        // Deep shadow for VR pop-out
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.6),
                                          blurRadius: 25,
                                          spreadRadius: 6,
                                          offset: const Offset(0, 12),
                                        ),
                                        // Mid shadow
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.4),
                                          blurRadius: 18,
                                          spreadRadius: 4,
                                          offset: const Offset(0, 8),
                                        ),
                                        // Glassy shine
                                        BoxShadow(
                                          color: Colors.white
                                              .withValues(alpha: 0.15),
                                          blurRadius: 20,
                                          spreadRadius: -8,
                                          offset: const Offset(-8, -8),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () =>
                                            _showSettingsModal(context),
                                        child: Container(
                                          padding: const EdgeInsets.all(14),
                                          child: ShaderMask(
                                            shaderCallback: (Rect bounds) =>
                                                const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0xFF6366F1),
                                                Color(0xFF8B5CF6),
                                                Color(0xFFEC4899),
                                                Color(0xFFF97316),
                                              ],
                                            ).createShader(bounds),
                                            blendMode: BlendMode.srcIn,
                                            child: const Icon(
                                              Icons.settings_rounded,
                                              size: 22,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Search Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 8,
                      bottom: _isSearchBarVisible
                          ? 12
                          : 0, // Add bottom spacing when search bar is visible
                    ),
                    child: _isSearchBarVisible
                        ? Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF6366F1),
                                  Color(0xFF8B5CF6),
                                  Color(0xFFEC4899),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1)
                                      .withValues(alpha: 0.6),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(3),
                            child: Container(
                              decoration: BoxDecoration(
                                // Enhanced glassy effect for search input
                                color: const Color(0xFF1A1F2E)
                                    .withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(17),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 1.5,
                                ),
                                // Glassy shine effect
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    blurRadius: 15,
                                    spreadRadius: -5,
                                    offset: const Offset(-3, -3),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: 'Search games...',
                                  hintStyle: TextStyle(
                                      color: Theme.of(context)
                                          .appColors
                                          .textSecondary
                                          .withValues(alpha: 0.7)),
                                  prefixIcon: const Icon(Icons.search_rounded,
                                      color: Color(0xFF8B5CF6), size: 22),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.close_rounded,
                                        color: Colors.white70, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _isSearchBarVisible = false;
                                        _searchController.clear();
                                        searchQuery = '';
                                      });
                                    },
                                  ),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 16),
                                ),
                                style: TextStyle(
                                    color:
                                        Theme.of(context).appColors.textPrimary,
                                    fontSize: 16),
                                onChanged: (val) =>
                                    setState(() => searchQuery = val),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                // Category Chips
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: _isSearchBarVisible ? 0 : 8,
                      bottom: 8,
                    ),
                    child: SizedBox(
                      height: 60,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final bool showCategoryNav = screenWidth >= 900;
                          final double horizontalPadding =
                              showCategoryNav ? 72 : 20;

                          final listView = ListView.separated(
                            controller: _categoryScrollController,
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding),
                            itemCount: categories.length + 1,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, idx) {
                              String cat;
                              if (idx == 0) {
                                cat = 'Favourites';
                              } else {
                                cat = categories[idx - 1];
                              }
                              final selected = cat == selectedCategory;
                              final depth = selected ? 1.2 : 0.8;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                child: Transform(
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.001)
                                    ..setTranslationRaw(0.0, 0.0, depth * 6.0),
                                  alignment: FractionalOffset.center,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: selected
                                          ? const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0xFF6366F1),
                                                Color(0xFF8B5CF6),
                                                Color(0xFFEC4899)
                                              ],
                                            )
                                          : null,
                                      color: selected
                                          ? null
                                          : const Color(0xFF1A1F2E)
                                              .withValues(alpha: 0.6),
                                      border: Border.all(
                                        color: selected
                                            ? Colors.transparent
                                            : Colors.white
                                                .withValues(alpha: 0.25),
                                        width: selected ? 0 : 1.5,
                                      ),
                                      boxShadow: selected
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF6366F1)
                                                    .withValues(alpha: 0.7),
                                                blurRadius: 25,
                                                spreadRadius: 6,
                                                offset: const Offset(0, 12),
                                              ),
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.5),
                                                blurRadius: 20,
                                                spreadRadius: 4,
                                                offset: const Offset(0, 8),
                                              ),
                                              BoxShadow(
                                                color: const Color(0xFF6366F1)
                                                    .withValues(alpha: 0.5),
                                                blurRadius: 18,
                                                spreadRadius: 2,
                                                offset: const Offset(0, 6),
                                              ),
                                            ]
                                          : [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.5),
                                                blurRadius: 20,
                                                spreadRadius: 5,
                                                offset: const Offset(0, 8),
                                              ),
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 15,
                                                spreadRadius: 3,
                                                offset: const Offset(0, 5),
                                              ),
                                              BoxShadow(
                                                color: Colors.white
                                                    .withValues(alpha: 0.1),
                                                blurRadius: 15,
                                                spreadRadius: -5,
                                                offset: const Offset(-3, -3),
                                              ),
                                            ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () => setState(
                                            () => selectedCategory = cat),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 18, vertical: 11),
                                          child: Text(
                                            cat,
                                            style: TextStyle(
                                              color: selected
                                                  ? Colors.white
                                                  : const Color(0xFFA1A1AA),
                                              fontWeight: selected
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                              fontSize: 13,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );

                          if (!showCategoryNav) {
                            return listView;
                          }

                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              listView,
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: _CategoryNavButton(
                                    icon: Icons.chevron_left_rounded,
                                    onTap: () => _scrollCategories(-220),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: _CategoryNavButton(
                                    icon: Icons.chevron_right_rounded,
                                    onTap: () => _scrollCategories(220),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                // Only show horizontal favorites list in "All" category
                if (favoriteGames.isNotEmpty && selectedCategory == 'All') ...[
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.favorite,
                                color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Your Favourites',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 160,
                      child: _HorizontalFavoritesList(
                        favoriteGames: favoriteGames,
                        onGameTap: (game) => _showGameModal(context, game),
                        isPremium: isPremium,
                        isFreeForToday: isFreeForToday,
                      ),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                // Show professional premium games banner when Premium category is selected
                if (selectedCategory == 'Premium')
                  SliverToBoxAdapter(
                    child: Transform(
                      // VR depth transform - banner pops out
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..setTranslationRaw(0.0, 0.0, 10.0),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF6366F1),
                              Color(0xFF8B5CF6),
                              Color(0xFFEC4899),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          // VR depth shadows - banner pops out of screen
                          boxShadow: [
                            // Deep shadow (farthest)
                            BoxShadow(
                              color: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.8),
                              blurRadius: 40,
                              spreadRadius: 8,
                              offset: const Offset(0, 20),
                            ),
                            // Mid shadow
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 35,
                              spreadRadius: 6,
                              offset: const Offset(0, 15),
                            ),
                            // Close shadow
                            BoxShadow(
                              color: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.6),
                              blurRadius: 28,
                              spreadRadius: 4,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(Icons.stars_rounded,
                                  color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Premium Games',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Most played games by our users',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.95),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (filteredGames.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text('No games found',
                            style: TextStyle(
                                color:
                                    Theme.of(context).appColors.textSecondary,
                                fontSize: 18)),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          //native ads show 1,10,20,40
                          // Check if this index should show an ad (only if ad is loaded)
                          if (_shouldShowAd(index)) {
                            // Show native ad - use current ad or get from pool
                            final ad = NativeAdsService.getAd();
                            print(
                                'DEBUG: NativeAdsService.getAd() returned: $ad');
                            if (ad != null) {
                              // Don't print every time to avoid spam
                              if (index == 5) {
                                print(
                                    '📢 Displaying native ad at index $index');
                              }
                              return _NativeAdWidget(nativeAd: ad);
                            }
                            try {
                              NativeAdsService.loadNativeAd();
                            } catch (_) {}
                            return const _NativeAdPlaceholder();
                            // If ad not loaded, show game instead (don't leave empty space)
                            // Fall through to show game at this position
                          }

                          // Show game tile (either normal position or replacing failed ad)
                          final gameIndex = _getGameIndex(index);
                          if (gameIndex >= filteredGames.length) {
                            return const SizedBox.shrink();
                          }

                          final game = filteredGames[gameIndex];
                          final isFreeGame = isFreeForToday(game);
                          final isFavGame = isFavorite(game);

                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration:
                                Duration(milliseconds: 320 + (gameIndex * 35)),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              final slideOffset = (1 - value) * 40;
                              return Transform.translate(
                                offset: Offset(0, slideOffset),
                                child: Transform.scale(
                                  scale: 0.92 + (value * 0.08),
                                  child: Opacity(
                                    opacity: value.clamp(0.0, 1.0),
                                    child: child,
                                  ),
                                ),
                              );
                            },
                            child: InkWell(
                              onTap: () => _showGameModal(context, game),
                              borderRadius: BorderRadius.circular(26),
                              child: Transform(
                                // VR depth transform - makes element pop out
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001) // Perspective
                                  ..setTranslationRaw(
                                      0.0, 0.0, 12.0), // Z-axis - pop out
                                alignment: FractionalOffset.center,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(26),
                                    gradient: isFreeGame
                                        ? const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF10B981),
                                              Color(0xFF3B82F6),
                                              Color(0xFF6366F1),
                                            ],
                                          )
                                        : const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF6366F1),
                                              Color(0xFF8B5CF6),
                                              Color(0xFFEC4899),
                                            ],
                                          ),
                                    // VR depth shadows - multiple layers for realistic depth
                                    boxShadow: [
                                      // Deep shadow (farthest from screen - VR effect)
                                      BoxShadow(
                                        color: (isFreeGame
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFF6366F1))
                                            .withValues(alpha: 0.8),
                                        blurRadius: 40,
                                        spreadRadius: 8,
                                        offset: const Offset(0, 20),
                                      ),
                                      // Mid shadow layer
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.7),
                                        blurRadius: 35,
                                        spreadRadius: 6,
                                        offset: const Offset(0, 15),
                                      ),
                                      // Close shadow (near screen)
                                      BoxShadow(
                                        color: (isFreeGame
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFF6366F1))
                                            .withValues(alpha: 0.6),
                                        blurRadius: 25,
                                        spreadRadius: 4,
                                        offset: const Offset(0, 10),
                                      ),
                                      // Colored glow for VR pop-out effect
                                      BoxShadow(
                                        color: (isFreeGame
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFF6366F1))
                                            .withValues(alpha: 0.4),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(5),
                                  child: Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    decoration: BoxDecoration(
                                      // Glassy effect for game tiles
                                      color: const Color(0xFF1A1F2E)
                                          .withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(21),
                                      border: Border.all(
                                        color: isFreeGame
                                            ? const Color(0xFF10B981)
                                                .withValues(alpha: 0.5)
                                            : Colors.white
                                                .withValues(alpha: 0.2),
                                        width: 1.8,
                                      ),
                                      // Enhanced glassy shine effect - water-like reflection
                                      boxShadow: [
                                        // Top-left shine (light reflection)
                                        BoxShadow(
                                          color: Colors.white
                                              .withValues(alpha: 0.15),
                                          blurRadius: 20,
                                          spreadRadius: -8,
                                          offset: const Offset(-6, -6),
                                        ),
                                        // Bottom shadow for depth
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.4),
                                          blurRadius: 15,
                                          spreadRadius: 2,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Expanded(
                                          flex: 4,
                                          child: ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                    top: Radius.circular(17)),
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                game.imagePath != null &&
                                                        game.imagePath!
                                                            .isNotEmpty
                                                    ? CachedNetworkImage(
                                                        imageUrl:
                                                            _resolveImageUrl(
                                                                game),
                                                        width: double.infinity,
                                                        height: double.infinity,
                                                        fit: BoxFit.cover,
                                                        alignment:
                                                            Alignment.center,
                                                        // Optimize memory usage with cache dimensions (2x for retina)
                                                        memCacheWidth:
                                                            400, // Approx 200px * 2 for retina
                                                        memCacheHeight:
                                                            600, // Approx 300px * 2 for retina
                                                        placeholder:
                                                            (context, url) =>
                                                                Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            gradient:
                                                                LinearGradient(
                                                              begin: Alignment
                                                                  .topLeft,
                                                              end: Alignment
                                                                  .bottomRight,
                                                              colors: [
                                                                Colors
                                                                    .grey[800]!,
                                                                Colors
                                                                    .grey[900]!,
                                                              ],
                                                            ),
                                                          ),
                                                          child: const Center(
                                                            child:
                                                                CircularProgressIndicator(
                                                              color: Color(
                                                                  0xFF6366F1),
                                                              strokeWidth: 2,
                                                            ),
                                                          ),
                                                        ),
                                                        errorWidget: (context,
                                                                url, error) =>
                                                            Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            gradient:
                                                                LinearGradient(
                                                              begin: Alignment
                                                                  .topLeft,
                                                              end: Alignment
                                                                  .bottomRight,
                                                              colors: [
                                                                Colors
                                                                    .grey[800]!,
                                                                Colors
                                                                    .grey[900]!,
                                                              ],
                                                            ),
                                                          ),
                                                          child: const Icon(
                                                              Icons.games,
                                                              size: 48,
                                                              color: Colors
                                                                  .white70),
                                                        ),
                                                        fadeInDuration:
                                                            const Duration(
                                                                milliseconds:
                                                                    200),
                                                        fadeInCurve:
                                                            Curves.easeOut,
                                                      )
                                                    : Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          gradient:
                                                              LinearGradient(
                                                            begin: Alignment
                                                                .topLeft,
                                                            end: Alignment
                                                                .bottomRight,
                                                            colors: [
                                                              Colors.grey[800]!,
                                                              Colors.grey[900]!,
                                                            ],
                                                          ),
                                                        ),
                                                        child: const Icon(
                                                            Icons.games,
                                                            size: 48,
                                                            color:
                                                                Colors.white70),
                                                      ),
                                                // Enhanced FREE badge
                                                if (isFreeGame)
                                                  Positioned(
                                                    top: 8,
                                                    left: 8,
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 10,
                                                          vertical: 6),
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            const LinearGradient(
                                                          colors: [
                                                            Color(0xFF10B981),
                                                            Color(0xFF3B82F6),
                                                            Color(0xFF6366F1)
                                                          ],
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(16),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: const Color(
                                                                    0xFF10B981)
                                                                .withValues(
                                                                    alpha: 0.6),
                                                            blurRadius: 8,
                                                            spreadRadius: 2,
                                                            offset:
                                                                const Offset(
                                                                    0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: const Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.star,
                                                              color:
                                                                  Colors.white,
                                                              size: 14),
                                                          SizedBox(width: 4),
                                                          Text(
                                                            'FREE',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              letterSpacing:
                                                                  0.5,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                else if (isPremium(game))
                                                  Positioned(
                                                    top: 8,
                                                    left: 8,
                                                    child: Container(
                                                      width: 36,
                                                      height: 36,
                                                      decoration: BoxDecoration(
                                                        color: Colors.black
                                                            .withValues(
                                                                alpha: 0.7),
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withValues(
                                                                    alpha: 0.5),
                                                            blurRadius: 4,
                                                            spreadRadius: 1,
                                                          ),
                                                        ],
                                                      ),
                                                      child: const Icon(
                                                        Icons.lock,
                                                        size: 20,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                // Enhanced favorite icon
                                                if (isFavGame)
                                                  Positioned(
                                                    top: 8,
                                                    right: 8,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red
                                                            .withValues(
                                                                alpha: 0.9),
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.red
                                                                .withValues(
                                                                    alpha: 0.5),
                                                            blurRadius: 6,
                                                            spreadRadius: 1,
                                                          ),
                                                        ],
                                                      ),
                                                      child: const Icon(
                                                        Icons.favorite,
                                                        size: 16,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 8),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.black
                                                      .withValues(alpha: 0.3),
                                                  Colors.black
                                                      .withValues(alpha: 0.5),
                                                ],
                                              ),
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                      bottom:
                                                          Radius.circular(12)),
                                            ),
                                            child: Center(
                                              child: Text(
                                                game.gameName ??
                                                    game.name ??
                                                    'Game',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: isFreeGame
                                                      ? FontWeight.bold
                                                      : FontWeight.w600,
                                                  letterSpacing: 0.2,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: _getTotalItemCount(),
                        addAutomaticKeepAlives:
                            false, // Don't keep off-screen items alive
                        addRepaintBoundaries:
                            true, // Add repaint boundaries for better performance
                        addSemanticIndexes:
                            false, // Disable semantic indexes for better performance
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridCrossAxisCount,
                        childAspectRatio: gridChildAspectRatio,
                        crossAxisSpacing: gridSpacing,
                        mainAxisSpacing: gridSpacing,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final bool? savedNotificationPreference =
        prefs.getBool('notifications_enabled');
    final bool actualNotificationStatus =
        await NotificationService.checkNotificationPermissions();

    setState(() {
      // If a preference is saved, use it, but ensure it doesn't contradict the actual permission status.
      // If actualNotificationStatus is false, _notificationsEnabled must be false.
      _notificationsEnabled =
          savedNotificationPreference ?? true && actualNotificationStatus;
      if (!actualNotificationStatus) {
        _notificationsEnabled = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).appColors.screenBackground,
      appBar: AppBar(
        title: Text('Settings',
            style: TextStyle(color: Theme.of(context).appColors.textPrimary)),
        backgroundColor: Theme.of(context).appColors.appBarBackground,
        foregroundColor: Theme.of(context).appColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).appColors.gradientStart,
              Theme.of(context).appColors.gradientEnd,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App Icon
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                      Color(0xFFEC4899),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.6),
                      blurRadius: 25,
                      spreadRadius: 3,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/icon.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.games,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // App Name
              Text(
                'FeedPlay',
                style: TextStyle(
                  color: Theme.of(context).appColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              // Settings Options
              _SettingsItem(
                icon: Icons.info_outline,
                title: 'About',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _SettingsItem(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: (val) async {
                    if (val) {
                      final granted = await NotificationService
                          .requestNotificationPermissions();
                      if (granted == true) {
                        setState(() => _notificationsEnabled = true);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('notifications_enabled', true);
                        await NotificationService.scheduleDailyNotifications();
                      } else {
                        // If permission denied, revert the switch
                        setState(() => _notificationsEnabled = false);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('notifications_enabled', false);
                      }
                    } else {
                      setState(() => _notificationsEnabled = false);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('notifications_enabled', false);
                      await NotificationService.cancelAllNotifications();
                    }
                  },
                  // Pass the current state value
                  key: ValueKey(_notificationsEnabled),
                  thumbColor: WidgetStateProperty.resolveWith<Color?>(
                    (states) => states.contains(WidgetState.selected)
                        ? const Color(0xFF6366F1)
                        : null,
                  ),
                  trackColor: WidgetStateProperty.resolveWith<Color?>(
                    (states) => states.contains(WidgetState.selected)
                        ? const Color(0xFF8B5CF6)
                        : null,
                  ),
                ),
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _SettingsItem(
                icon: Icons.share_outlined,
                title: 'Share App',
                onTap: () async {
                  await RateShareService.shareApp();
                },
              ),
              const SizedBox(height: 12),
              _SettingsItem(
                icon: Icons.star_outline,
                title: 'Rate App',
                onTap: () async {
                  await RateShareService.rateApp();
                },
              ),

              const SizedBox(height: 12),
              _SettingsItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HelpSupportScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return GestureDetector(
                      onTap: () {
                        InAppUpdateService.checkForUpdateAndShowDialog(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          // Glassy effect with semi-transparent background
                          color: const Color(0xFF1A1F2E).withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                          // Glassy shine effect
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.1),
                              blurRadius: 20,
                              spreadRadius: -5,
                              offset: const Offset(-5, -5),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                              offset: const Offset(5, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF6366F1),
                                    Color(0xFF8B5CF6)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6366F1)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.info_outline,
                                  color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                'Check for Updates',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '${snapshot.data!.version}+${snapshot.data!.buildNumber}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios,
                                color: Colors.white54, size: 16),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).appColors.screenBackground,
      appBar: AppBar(
        title: Text('About FeedPlay',
            style: TextStyle(color: Theme.of(context).appColors.textPrimary)),
        backgroundColor: Theme.of(context).appColors.appBarBackground,
        foregroundColor: Theme.of(context).appColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).appColors.gradientStart,
              Theme.of(context).appColors.gradientEnd,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF8B5CF6),
                      Color(0xFF3B82F6),
                      Color(0xFF6366F1),
                    ],
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/icon.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.games, size: 40, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Text(
                'FeedPlay',
                style: TextStyle(
                    color: Theme.of(context).appColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              // Game Provider
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Game Provider',
                  style: TextStyle(
                      color: Theme.of(context).appColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              // Playgama Description
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).appColors.cardBackground,
                      Theme.of(context)
                          .appColors
                          .cardBackground
                          .withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Playgama',
                      style: TextStyle(
                        color: Theme.of(context).appColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Playgama provides access to over 2,000+ free HTML5 games. Enjoy a diverse collection of casual, puzzle, action, and adventure games optimized for mobile and desktop.',
                      style: TextStyle(
                        color: Theme.of(context).appColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Ads Info
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Advertisement',
                  style: TextStyle(
                      color: Theme.of(context).appColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Ads that appear before playing games (in the app) are from FeedPlay. Ads shown during gameplay (inside the games) are from our game partner Playgama.',
                  style: TextStyle(
                      color: Theme.of(context).appColors.textSecondary,
                      fontSize: 13,
                      height: 1.5),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: 24),
              // Policies
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Policies',
                  style: TextStyle(
                      color: Theme.of(context).appColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              _LinkItem(
                title: 'Privacy Policy',
                url: 'View Policy',
                onTap: () async {
                  const url = 'https://feedplay.vercel.app/Privacy_Policy.html';
                  if (kIsWeb) {
                    // On web, open in browser
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  } else {
                    // On mobile, open in WebView
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const _WebViewScreen(
                          title: 'Privacy Policy',
                          url: url,
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              _LinkItem(
                title: 'Terms & Conditions',
                url: 'View Terms',
                onTap: () async {
                  const url =
                      'https://feedplay.vercel.app/Terms_Conditions.html';
                  if (kIsWeb) {
                    // On web, open in browser
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  } else {
                    // On mobile, open in WebView
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const _WebViewScreen(
                          title: 'Terms & Conditions',
                          url: url,
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchSupportEmail(
    BuildContext context, {
    required String subject,
    required String body,
  }) async {
    const supportEmail = 'am.abdulmueed3@gmail.com';

    // Use explicit encoding so spaces/newlines don't show as '+' in some email apps
    final encodedSubject = Uri.encodeComponent(subject);
    final encodedBody = Uri.encodeComponent(body);
    final mailtoUri = Uri.parse(
      'mailto:$supportEmail?subject=$encodedSubject&body=$encodedBody',
    );

    bool opened = false;
    try {
      opened = await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }

    if (opened) return;

    final fallbackUri = Uri.parse(
      'https://mail.google.com/mail/?view=cm&fs=1&to=${Uri.encodeComponent(supportEmail)}&su=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    if (await canLaunchUrl(fallbackUri)) {
      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'No email app found. Please install an email app to contact support.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).appColors.screenBackground,
      appBar: AppBar(
        title: Text('Help & Support',
            style: TextStyle(color: Theme.of(context).appColors.textPrimary)),
        backgroundColor: Theme.of(context).appColors.appBarBackground,
        foregroundColor: Theme.of(context).appColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).appColors.gradientStart,
              Theme.of(context).appColors.gradientEnd,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bug Report
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1A1F2E).withValues(alpha: 0.8),
                      const Color(0xFF0F1419).withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.bug_report_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Report Bug',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        await _launchSupportEmail(
                          context,
                          subject: 'Bug Report - FeedPlay',
                          body: '''
App Name: FeedPlay
Time: $now

Issue Details:
- What went wrong?
- On which screen did it happen?
- Any steps to reproduce the issue?

Additional Info (optional):
- Device model:
- Android version:

[Please attach screenshots if possible]''',
                        );
                      },
                      icon: const Icon(Icons.email_rounded,
                          color: Color(0xFF6366F1)),
                      label: const Text(
                        'Send Bug Report via Email',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF6366F1).withValues(alpha: 0.2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Request New Game
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1A1F2E).withValues(alpha: 0.8),
                      const Color(0xFF0F1419).withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_circle_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Request New Game',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () async {
                        await _launchSupportEmail(
                          context,
                          subject: 'New Game Request - FeedPlay',
                          body: '''
App Name: FeedPlay

Game Details:
- Game name:
- Game link/URL:
- Game category (e.g. Action, Puzzle, Racing, Casual):

Anything else you want to add:''',
                        );
                      },
                      icon: const Icon(Icons.email_rounded,
                          color: Color(0xFF6366F1)),
                      label: const Text(
                        'Request Game via Email',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF6366F1).withValues(alpha: 0.2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// WebView Screen for opening URLs in app
class _WebViewScreen extends StatefulWidget {
  final String title;
  final String url;

  const _WebViewScreen({
    required this.title,
    required this.url,
  });

  @override
  State<_WebViewScreen> createState() => _WebViewScreenState();
}

// GameScreen - React Native style implementation
class GameScreen extends StatefulWidget {
  final GameModel game;

  const GameScreen({
    super.key,
    required this.game,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _loading =
      false; // Start with false for faster response (like React Native)
  double _progress = 0;
  bool _isFirstTimePlay = false;

  // Get display name (before colon if exists)
  String _getDisplayName(GameModel game) {
    final fullName = game.gameName ?? game.name ?? 'Unknown Game';
    // If name contains ":", show only the part before colon
    if (fullName.contains(':')) {
      return fullName.split(':').first.trim();
    }
    return fullName;
  }

  // Get unique game ID for tracking
  String _getUniqueGameId(GameModel game) {
    final name = game.gameName ?? game.name ?? '';
    final url = game.gameUrl.isNotEmpty ? game.gameUrl : (game.url ?? '');
    return '$name|$url';
  }

  // Check if this is first time playing the game
  Future<bool> _checkIfFirstTimePlay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gameId = _getUniqueGameId(widget.game);
      final playedGames = prefs.getStringList('played_games') ?? [];
      return !playedGames.contains(gameId);
    } catch (e) {
      print('Error checking first time play: $e');
      return true; // Default to first time if error
    }
  }

  // Mark game as played
  Future<void> _markGameAsPlayed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gameId = _getUniqueGameId(widget.game);
      final playedGames = prefs.getStringList('played_games') ?? [];
      if (!playedGames.contains(gameId)) {
        playedGames.add(gameId);
        await prefs.setStringList('played_games', playedGames);
      }
    } catch (e) {
      print('Error marking game as played: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    // Handle screen orientation for better game playing experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    print('🎮 Game Screen mounted - rotation enabled');

    // Check if first time playing
    _checkIfFirstTimePlay().then((isFirstTime) {
      if (mounted) {
        setState(() {
          _isFirstTimePlay = isFirstTime;
        });
      }
    });
  }

  @override
  void dispose() {
    // Restore system UI when leaving game
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    print('🎮 Game Screen unmounted');
    super.dispose();
  }

  // Handle load start (like React Native handleLoadStart)
  void handleLoadStart() {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }
  }

  // Handle load end (like React Native handleLoadEnd)
  void handleLoadEnd() async {
    if (mounted) {
      setState(() {
        _loading = false;
      });
      // Mark game as played when it loads successfully (for tracking unique games)
      if (_isFirstTimePlay) {
        await _markGameAsPlayed();
      }

      // Increment games played count (track total games played, not unique)
      // This is used for rate/share dialogs
      final gamesPlayedCount =
          await RateShareService.incrementGamesPlayedCount();
      print(
          '🎮 Game loaded successfully. Total games played: $gamesPlayedCount');

      // Check if we should show rate/share dialog
      // Show rate dialog after 2 games, share dialog after 4 games
      if (gamesPlayedCount == 2) {
        // Show rate dialog after a short delay (while game is playing)
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _checkAndShowRateDialog();
          }
        });
      }
    }
  }

  // Check and show rate dialog
  Future<void> _checkAndShowRateDialog() async {
    final shouldShow = await RateShareService.shouldShowRateReminder();
    if (shouldShow && mounted) {
      _showRateDialogInGame();
    }
  }

  // Show rate dialog in game screen
  void _showRateDialogInGame() async {
    final localContext = context;
    await blink_sound.ensureBlinkAudioUnlocked();
    if (!localContext.mounted) return;
    await RateShareService.rateApp();
    await RateShareService.markRateDialogShown();
  }

  // Handle error silently (no dialog shown)
  void handleError() {
    if (mounted) {
      setState(() {
        _loading = false;
      });
      // Silent error handling - no dialog shown
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mobile platform - use InAppWebView (like React Native WebView)
    return Scaffold(
      backgroundColor: const Color(0xFF0D1421),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Game Header with gradient and stylish design
            Container(
              height: 70,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF8B5CF6),
                    Color(0xFF3B82F6),
                    Color(0xFF6366F1),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    // Modern Back Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        color: Colors.white,
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Back',
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Game Title with App Name
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FeedPlay',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getDisplayName(widget.game),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Spacer to balance the back button
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),

            // WebView container (like React Native webView style)
            Expanded(
              child: Stack(
                children: [
                  // InAppWebView (equivalent to React Native WebView)
                  InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: WebUri(
                          widget.game.gameUrl), // source={{ uri: game.famobi }}
                    ),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true, // javaScriptEnabled={true}
                      mediaPlaybackRequiresUserGesture:
                          false, // mediaPlaybackRequiresUserAction={false}
                      useHybridComposition:
                          true, // Enable hybrid composition to avoid blank screen on some Android devices
                      allowsInlineMediaPlayback:
                          true, // allowsInlineMediaPlayback={true}
                      allowsBackForwardNavigationGestures: false,
                      allowFileAccessFromFileURLs: true,
                      allowUniversalAccessFromFileURLs: true,
                      clearCache: false,
                      supportZoom: true, // scalesPageToFit={true}
                      builtInZoomControls: false,
                      displayZoomControls: false,
                      userAgent:
                          'Mozilla/5.0 (Linux; Android 13; SM-G991B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                      useShouldOverrideUrlLoading: true,
                      useOnLoadResource: true,
                      mixedContentMode: MixedContentMode
                          .MIXED_CONTENT_ALWAYS_ALLOW, // mixedContentMode="compatibility"
                    ),
                    onWebViewCreated: (controller) {
                      // WebView controller initialized
                    },
                    onCreateWindow: (controller, onCreateWindowRequest) async {
                      // Allow popups for games (some games use window.open for features)
                      // Open in same window instead of blocking
                      if (onCreateWindowRequest.request.url != null) {
                        await controller.loadUrl(
                            urlRequest: URLRequest(
                                url: onCreateWindowRequest.request.url!));
                      }
                      return true; // Allow the window creation
                    },
                    onLoadStart: (controller, url) {
                      handleLoadStart(); // onLoadStart={handleLoadStart}
                    },
                    onLoadStop: (controller, url) async {
                      handleLoadEnd(); // onLoadEnd={handleLoadEnd}

                      // Inject game optimization CSS
                      await controller.evaluateJavascript(source: '''
                        try {
                          var style = document.createElement('style');
                          style.innerHTML = `
                            * { box-sizing: border-box; }
                            html, body { 
                              margin: 0 !important; 
                              padding: 0 !important; 
                              width: 100% !important; 
                              height: 100% !important; 
                              overflow: hidden !important;
                              background: #0D1421 !important;
                            }
                            canvas, iframe, embed, object {
                              max-width: 100vw !important;
                              max-height: 100vh !important;
                              width: 100% !important;
                              height: 100% !important;
                              border: none !important;
                            }
                            .game-container, .game-wrapper, .game-frame, 
                            #game-container, #game-wrapper, #game-frame,
                            .unity-container, .phaser-game, .construct-game {
                              width: 100% !important;
                              height: 100% !important;
                              margin: 0 !important;
                              padding: 0 !important;
                            }
                            .header, .footer, .nav, .navigation, .menu {
                              display: none !important;
                            }
                          `;
                          document.head.appendChild(style);
                          console.log('Game optimization applied');
                        } catch (error) {
                          console.error('Game optimization failed:', error);
                        }
                      ''');
                    },
                    onProgressChanged: (controller, progress) {
                      if (mounted) {
                        setState(() {
                          _progress = progress / 100;
                        });
                      }
                    },
                    onReceivedError: (controller, request, error) {
                      print('WebView error: ${error.description}');
                      handleError(); // onError={handleError}
                    },
                    shouldOverrideUrlLoading:
                        (controller, navigationAction) async {
                      // Allow all HTTP/HTTPS navigations for games
                      // Only block non-http(s) schemes (like app intents, file://, etc.)
                      final uri = navigationAction.request.url;
                      if (uri == null) return NavigationActionPolicy.ALLOW;

                      final scheme = uri.scheme.toLowerCase();
                      if (scheme.isEmpty) {
                        return NavigationActionPolicy.ALLOW;
                      }

                      // Only block non-http(s) schemes (app intents, file://, etc.)
                      // Allow all HTTP/HTTPS to ensure games load properly
                      if (scheme != 'http' && scheme != 'https') {
                        return NavigationActionPolicy.CANCEL;
                      }

                      // Allow all HTTP/HTTPS navigations (including ad domains)
                      // Games may need to load resources from various domains
                      return NavigationActionPolicy.ALLOW;
                    },
                  ),

                  // Loading overlay (like React Native loading state)
                  if (_loading)
                    Container(
                      color: const Color(0xFF0D1421),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const GradientCircularProgressIndicator(
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
                            const SizedBox(height: 16),
                            Text(
                              _isFirstTimePlay
                                  ? 'First launch may take 5-10 seconds\nto optimize game performance'
                                  : 'Loading ${_getDisplayName(widget.game)}...',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            ShaderMask(
                              shaderCallback: (bounds) {
                                return const LinearGradient(
                                  colors: [
                                    Color(0xFFFF8C42), // Clean Orange
                                    Color(0xFFFF1493), // Fresh Pink
                                    Color(0xFF9D4EDD), // Vibrant Purple
                                    Color(0xFF4361EE), // Clear Blue
                                    Color(0xFF34D399), // Emerald Green
                                    Color(0xFFFACC15), // Amber Yellow
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds);
                              },
                              child: LinearProgressIndicator(
                                value: _progress,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

class _WebViewScreenState extends State<_WebViewScreen> {
  webview_flutter.WebViewController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = webview_flutter.WebViewController()
      ..setJavaScriptMode(webview_flutter.JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0D1421))
      ..setNavigationDelegate(
        webview_flutter.NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onWebResourceError: (webview_flutter.WebResourceError error) {
            print('WebView error: ${error.description}');
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1421),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF121B2B),
        foregroundColor: Colors.white,
      ),
      body: _isLoading || _controller == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            )
          : _controller != null
              ? webview_flutter.WebViewWidget(controller: _controller!)
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Failed to load page',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
    );
  }
}

// _GameWebViewScreenState removed - games now open in external browser
