import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../l10n/app_localizations.dart';

class BrandSplashScreen extends StatefulWidget {
  const BrandSplashScreen({super.key});

  @override
  State<BrandSplashScreen> createState() => _BrandSplashScreenState();
}

class _BrandSplashScreenState extends State<BrandSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // 1.2s total duration: first 0.9s solid, last 0.3s fade-out
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _startSplashSequence();
  }

  void _startSplashSequence() {
    // Hold solid for 900ms, then fade for 300ms (Total = 1200ms = 1.2s)
    Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        _fadeController.forward().then((_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const RootNavigationSelector(),
                transitionDuration: Duration.zero,
              ),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String _getSlogan(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return l10n?.welcomeSlogan ?? '당신에게 꼭 맞는 여행';
  }

  @override
  Widget build(BuildContext context) {
    final slogan = _getSlogan(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0355E9), // Official Brand Blue
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Official App Icon (PNG 원본 100% 보준)
              Image.asset(
                'assets/brand/official/nampo_gogo_app_icon_official.png',
                width: 170.0,
                height: 170.0,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20.0),

              // Slogan Text
              Text(
                slogan,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
