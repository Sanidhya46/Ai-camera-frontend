library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/core/services/auth_service.dart';
import 'package:smart_shutter/screens/auth/auth_screen.dart';
import 'package:smart_shutter/screens/permissions_screen.dart';
import 'package:smart_shutter/screens/main_layout.dart';

/// Initial landing / splash screen shown when the app launches.
/// Displays splash_screen_image.png for 2.5 seconds.
/// - If user is logged in: navigates to MainLayout (or PermissionsScreen).
/// - If not logged in: smoothly navigates to the dedicated AuthScreen (Sign-In & Sign-Up).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    // Show landing image for 2.5 seconds
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final appState = Provider.of<AppState>(context, listen: false);

    // If user is already authenticated
    if (appState.isLoggedIn) {
      try {
        final profileResult = await _authService.getProfile(appState.accessToken!);
        if (profileResult['success'] == true && mounted) {
          await appState.setCurrentUser(profileResult['data'] as Map<String, dynamic>);
        } else if (profileResult['error'] != null &&
            profileResult['error'].toString().contains('401')) {
          await appState.clearAuth();
        }
      } catch (_) {}

      if (!mounted) return;

      if (!appState.hasSeenOnboarding) {
        await appState.setOnboardingSeen(true);
      }

      if (!mounted) return;

      bool hasPermissions = true;
      try {
        final cameraStatus = await Permission.camera.status;
        if (!kIsWeb) {
          final storageStatus = await Permission.storage.status;
          hasPermissions = cameraStatus.isGranted && storageStatus.isGranted;
        } else {
          hasPermissions = cameraStatus.isGranted;
        }
      } catch (_) {}

      if (!mounted) return;

      if (!appState.hasSeenPermissionsFlow || !hasPermissions) {
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
      // User is not logged in: smoothly navigate to the dedicated AuthScreen page
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AuthScreen(initialMode: AuthInitialMode.login),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Splash Screen Landing Image ──
          Image.asset(
            'assets/images/splash_screen/splash_screen_image.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
          ),

          // ── Subtle bottom loading indicator ──
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Starting SmartShutter...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
