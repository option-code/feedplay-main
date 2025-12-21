import 'package:flutter/material.dart';
import 'dart:async';
import 'app_splash_screen.dart';

class CompanyLogoSplashScreen extends StatefulWidget {
  const CompanyLogoSplashScreen({super.key});

  @override
  State<CompanyLogoSplashScreen> createState() => _CompanyLogoSplashScreenState();
}

class _CompanyLogoSplashScreenState extends State<CompanyLogoSplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to app splash screen after 2 seconds
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AppSplashScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1C2C),
      body: Center(
        child: Image.asset(
          'assets/co_splash.png',
          fit: BoxFit.contain,
          width: MediaQuery.of(context).size.width * 0.7,
          height: MediaQuery.of(context).size.height * 0.7,
        ),
      ),
    );
  }
}
