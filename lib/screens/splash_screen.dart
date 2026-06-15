/// Initial splash screen shown when the app launches.
/// Displays an animated logo and app name while checking user's onboarding, permissions, and camera access status.
/// Routes to the appropriate next screen based on app state: onboarding, permissions, or main layout.
/// Uses elegant animations for logo rotation and text fade to create a polished first impression.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/screens/onboarding_screen.dart';
import 'package:smart_shutter/screens/permissions_screen.dart';
import 'package:smart_shutter/screens/main_layout.dart';
import 'package:smart_shutter/core/theme.dart';
import 'package:permission_handler/permission_handler.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _textScaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..forward();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0)
        .animate(_controller);
        
    _rotationAnimation = Tween<double>(begin: 0.0, end: 220 / 360)
        .chain(CurveTween(curve: const Interval(0.0, 1.0, curve: Curves.easeIn)))
        .animate(_controller);

    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: const Interval(0.6, 1.0, curve: Curves.easeIn)))
        .animate(_controller);

    _textScaleAnimation = Tween<double>(begin: 0.8, end: 1.0)
        .chain(CurveTween(curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic)))
        .animate(_controller);

    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Wait for animation (2200ms) + 1 second hold so user sees the text
    await Future.delayed(const Duration(milliseconds: 3200));
    if (!mounted) return;
    
    final appState = Provider.of<AppState>(context, listen: false);
    
    bool cameraGranted = false;
    try {
      final status = await Permission.camera.status;
      cameraGranted = status.isGranted;
    } catch (_) {}

    // If permissions already shown or granted, go to main layout
    if (appState.hasSeenPermissionsFlow || cameraGranted) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainLayout()),
        );
      }
    } else if (appState.hasSeenOnboarding) {
      // If onboarding seen but permissions not shown, go to permissions
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PermissionsScreen()),
      );
    } else {
      // First time: show onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: RotationTransition(
                  turns: _rotationAnimation,
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 64,
                    height: 64,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FadeTransition(
                opacity: _textOpacityAnimation,
                child: ScaleTransition(
                  scale: _textScaleAnimation,
                  child: Text(
                    'SmartShutter', 
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
