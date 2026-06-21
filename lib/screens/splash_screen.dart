/// Initial splash screen shown when the app launches.
/// Displays animated logo while checking auth and onboarding status.
/// Routes: No auth → Register, Has auth + no onboarding → Onboarding,
/// Has auth + onboarding done → Main Layout.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/core/services/auth_service.dart';
import 'package:smart_shutter/core/theme.dart';
import 'package:smart_shutter/screens/auth/register_screen.dart';
import 'package:smart_shutter/screens/onboarding_screen.dart';
import 'package:smart_shutter/screens/permissions_screen.dart';
import 'package:smart_shutter/screens/main_layout.dart';

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
    // Wait for animation + brief hold
    await Future.delayed(const Duration(milliseconds: 3200));
    if (!mounted) return;
    
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Case 1: User has auth token — try to use it
    if (appState.isLoggedIn) {
      // Try refreshing profile in background
      try {
        final authService = AuthService();
        final profileResult = await authService.getProfile(appState.accessToken!);
        if (profileResult['success'] == true && mounted) {
          await appState.setCurrentUser(profileResult['data'] as Map<String, dynamic>);
        }
      } catch (_) {
        // Profile refresh failed — continue anyway with cached data
      }

      if (!mounted) return;

      if (!appState.hasSeenOnboarding) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      } else if (!appState.hasSeenPermissionsFlow) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PermissionsScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainLayout()),
        );
      }
    } else {
      // Case 2: No auth token — go to register
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().isDarkMode;

    return Scaffold(
      body: Container(
        color: isDark ? Colors.black : Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: RotationTransition(
                  turns: _rotationAnimation,
                  child: Image.asset(
                    isDark ? 'assets/images/app_logo.png' : 'assets/images/app_logo_light_theme.png',
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
                    'Smart Shutter', 
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
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
