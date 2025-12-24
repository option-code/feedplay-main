import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/company_logo_splash_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/reward_ads_service.dart';
import 'services/interstitial_ads_service.dart';
import 'services/native_ads_service.dart';
import 'services/launcher_shortcuts_service.dart';
import 'services/game_service.dart';

import 'models/game_model.dart';
import 'widgets/shinny_overlay.dart'; // Shiny overlay for all screens
import 'widgets/gradient_circular_progress_indicator.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color screenBackground;
  final Color cardBackground;
  final Color appBarBackground;
  final Color textPrimary;
  final Color textSecondary;
  final Color gradientStart;
  final Color gradientEnd;
  final Color dialogBackground;
  final Color buttonBackground;
  final Color buttonText;

  const AppColors({
    required this.screenBackground,
    required this.cardBackground,
    required this.appBarBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.gradientStart,
    required this.gradientEnd,
    required this.dialogBackground,
    required this.buttonBackground,
    required this.buttonText,
  });

  @override
  ThemeExtension<AppColors> copyWith({
    Color? screenBackground,
    Color? cardBackground,
    Color? appBarBackground,
    Color? textPrimary,
    Color? textSecondary,
    Color? gradientStart,
    Color? gradientEnd,
    Color? dialogBackground,
    Color? buttonBackground,
    Color? buttonText,
  }) {
    return AppColors(
      screenBackground: screenBackground ?? this.screenBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      appBarBackground: appBarBackground ?? this.appBarBackground,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      dialogBackground: dialogBackground ?? this.dialogBackground,
      buttonBackground: buttonBackground ?? this.buttonBackground,
      buttonText: buttonText ?? this.buttonText,
    );
  }

  @override
  ThemeExtension<AppColors> lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      screenBackground:
          Color.lerp(screenBackground, other.screenBackground, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      appBarBackground:
          Color.lerp(appBarBackground, other.appBarBackground, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
      dialogBackground:
          Color.lerp(dialogBackground, other.dialogBackground, t)!,
      buttonBackground:
          Color.lerp(buttonBackground, other.buttonBackground, t)!,
      buttonText: Color.lerp(buttonText, other.buttonText, t)!,
    );
  }
}

extension AppColorsExtension on ThemeData {
  AppColors get appColors => extension<AppColors>()!;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up error widget builder before app starts
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1C2C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                details.exception.toString(),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  };

  // Set orientations only for mobile platforms
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  } catch (e) {
    // Ignore orientation errors on web
  }

  // Initialize and schedule notifications (skip on web)
  try {
    await NotificationService.initialize();
    await NotificationService.scheduleDailyNotifications();
  } catch (e) {
    print('Notification initialization failed: $e');
    // Continue app initialization even if notifications fail
  }

  runApp(const FeedPlayApp());

  // Initialize Google Mobile Ads AFTER first frame is rendered
  // Native WebView pre-warm happens in MainActivity.onCreate() before this
  // This gives WebView time to stabilize before AdMob tries to use it
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // Wait for app to fully render and WebView to stabilize
    await Future.delayed(
        const Duration(seconds: 1)); // Reduced delay after first frame

    try {
      print('🔧 Initializing AdMob...');
      await MobileAds.instance.initialize().then((InitializationStatus status) {
        status.adapterStatuses.forEach((key, value) {
          print('Adapter $key: $value.description');
        });
      });

      // Mark AdMob as initialized for all ad services
      RewardAdsService.setAdMobInitialized(true);
      InterstitialAdsService.setAdMobInitialized(true);
      NativeAdsService.setAdMobInitialized(true);

      // Configure test device to avoid invalid traffic warnings
      final config = RequestConfiguration(
        testDeviceIds: ['904D334B78E14B5945C9A85AE49D9F75'],
      );
      MobileAds.instance.updateRequestConfiguration(config);

      print('✅ AdMob initialized successfully!');
      print('⏳ Preloading ads in 5 seconds...');

      Future.delayed(const Duration(seconds: 1), () async {
        // Reduced delay for ad preloading
        print('📥 Starting ad preload...');
        // Preload both rewarded and interstitial ads
        RewardAdsService.preloadRewardedAd().then((success) {
          if (success) {
            print('✅ Rewarded ad preloaded successfully!');
          } else {
            print(
                '⚠️ Rewarded ad preload failed, will retry when user clicks button');
          }
        });

        InterstitialAdsService.preloadInterstitialAd().then((success) {
          if (success) {
            print('✅ Interstitial ad preloaded successfully!');
          } else {
            print('⚠️ Interstitial ad preload failed, will retry when needed');
          }
        });

        // Preload native ad
        NativeAdsService.preloadNativeAd().then((ad) {
          if (ad != null) {
            print('✅ Native ad preloaded successfully!');
          } else {
            print('⚠️ Native ad preload failed, will retry when needed');
          }
        });

        // Check for app updates after ads are initialized
        // We'll check for updates when the home screen is loaded instead
      });
    } catch (e) {
      print('❌ Ads initialization failed: $e');
      // Continue app initialization even if ads fail
    }
  });
}

class FeedPlayApp extends StatefulWidget {
  const FeedPlayApp({super.key});

  @override
  State<FeedPlayApp> createState() => _FeedPlayAppState();
}

class _FeedPlayAppState extends State<FeedPlayApp> {
  String? _deepLinkGameId;

  @override
  void initState() {
    super.initState();
    _checkDeepLink();
  }

  Future<void> _checkDeepLink() async {
    // Check if app was opened from shortcut
    final gameId = await LauncherShortcutsService.getDeepLinkGameId();
    if (gameId != null && mounted) {
      setState(() {
        _deepLinkGameId = gameId;
      });
    }
  }

  Widget _getInitialRoute() {
    // If deep link exists, navigate to game
    if (_deepLinkGameId != null) {
      return _DeepLinkHandler(gameId: _deepLinkGameId!);
    }
    return const CompanyLogoSplashScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FeedPlay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        primaryColor: const Color(0xFF6366F1),
        scaffoldBackgroundColor: const Color(0xFF0F1419),
        cardColor: const Color(0xFF1A1F2E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF8B5CF6),
          surface: Color(0xFF1A1F2E),
          tertiary: Color(0xFFEC4899),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1F2E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        extensions: <ThemeExtension<dynamic>>[
          const AppColors(
            screenBackground: Color(0xFF0F1419),
            cardBackground: Color(0xFF1A1F2E),
            appBarBackground: Color(0xFF1A1F2E),
            textPrimary: Colors.white,
            textSecondary: Color(0xFFA1A1AA),
            gradientStart: Color(0xFF1A1F2E),
            gradientEnd: Color(0xFF0F1419),
            dialogBackground:
                Color(0xFF1A1F2E), // Using cardBackground for dialogs
            buttonBackground: Color(0xFF6366F1), // Primary color for buttons
            buttonText: Colors.white, // White text on buttons
          ),
        ],
      ),
      home: _getInitialRoute(),
      builder: (context, child) {
        // Ensure widget tree is properly built and add shiny overlay
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.0)),
          child: ShinyOverlay(
            enabled: true,
            child: child ??
                const Scaffold(
                  backgroundColor: Color(0xFF0B1C2C),
                  body: Center(
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
                  ),
                ),
          ),
        );
      },
    );
  }
}

// Widget to handle deep link and navigate to game
class _DeepLinkHandler extends StatefulWidget {
  final String gameId;

  const _DeepLinkHandler({required this.gameId});

  @override
  State<_DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<_DeepLinkHandler> {
  @override
  void initState() {
    super.initState();
    _loadAndNavigateToGame();
  }

  Future<void> _loadAndNavigateToGame() async {
    try {
      // Load all games
      final allGames = await GameService.loadHorizontalGames();

      // Find game by ID (matching the ID format used in shortcuts)
      GameModel? targetGame;
      for (final game in allGames) {
        final gameId = _getGameId(game);
        if (gameId == widget.gameId) {
          targetGame = game;
          break;
        }
      }

      if (mounted) {
        if (targetGame != null) {
          // Navigate to game screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => GameScreen(game: targetGame!),
            ),
          );
        } else {
          // Game not found, go to home screen
          print('⚠️ Game not found for deep link: ${widget.gameId}');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      print('❌ Error loading game from deep link: $e');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }

  String _getGameId(GameModel game) {
    // Use same logic as LauncherShortcutsService
    final name = game.gameName ?? game.name ?? '';
    final url = game.gameUrl.isNotEmpty ? game.gameUrl : (game.url ?? '');
    final combined = '$name|$url';
    // Replace special characters that might cause issues (same as service)
    return combined.replaceAll(RegExp(r'[^a-zA-Z0-9|]'), '_');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0B1C2C),
      body: Center(
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
      ),
    );
  }
}
