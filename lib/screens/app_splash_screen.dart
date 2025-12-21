import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'home_screen.dart';
import '../services/game_service.dart';

class AppSplashScreen extends StatefulWidget {
  const AppSplashScreen({super.key});

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen> {
  // Rotating taglines that change on every app restart
  static final List<String> _taglines = [
    'Play Unlimited',
    'Endless Fun Awaits',
    'Your Gaming Paradise',
    'Play Anytime, Anywhere',
    'Discover Amazing Games',
    'Fun Never Ends',
    'Game On, Every Day',
    'Play More, Enjoy More',
    'Your Daily Gaming Fix',
    'Unlimited Entertainment',
    'Games Galore',
    'Play, Win, Repeat',
    'Premium Gaming Experience',
    'Play Without Limits',
    'Gaming Made Simple',
  ];

  late String _currentTagline;

  @override
  void initState() {
    super.initState();
    // Select random tagline on every app restart
    final random = Random();
    _currentTagline = _taglines[random.nextInt(_taglines.length)];
    
    // Preload games in background while showing splash
    // This ensures games are ready when home screen opens
    GameService.loadHorizontalGames(forceRefresh: true);
    GameService.loadVerticalGames(forceRefresh: true);
    
    // Navigate to HomeScreen after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F1419),
              Color(0xFF1A1F2E),
              Color(0xFF0F1419),
            ],
          ),
        ),
        child: Stack(
          children: [
            // App Logo - Centered
            Center(
              child: Image.asset(
                'assets/splash.png',
                fit: BoxFit.contain,
                width: MediaQuery.of(context).size.width * 0.7,
                height: MediaQuery.of(context).size.height * 0.5,
              ),
            ),
            // Rotating Tagline - Clean & Fresh Gradient (No Background/Glow)
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFF8C42), // Clean Orange
                      Color(0xFFFF1493), // Fresh Pink
                      Color(0xFF9D4EDD), // Vibrant Purple
                      Color(0xFF4361EE), // Clear Blue
                    ],
                    stops: [0.0, 0.35, 0.65, 1.0],
                  ).createShader(bounds),
                  child: Text(
                    _currentTagline,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      // No shadows - clean and crisp
                    ),
                    textAlign: TextAlign.center,
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

