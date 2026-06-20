/// Three-page onboarding screen matching the exact design from reference images.
/// Page 1: Passport Photo feature
/// Page 2: Smart Solo capture feature
/// Page 3: One App with multiple possibilities
/// Features white image placeholder areas, accurate page indicators (1/3, 2/3, 3/3).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/core/theme.dart';
import 'package:smart_shutter/screens/permissions_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _complete();
    }
  }

  void _complete() {
    context.read<AppState>().setOnboardingSeen(true);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PermissionsScreen()),
    );
  }
     
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF010209) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Page indicator in top right
            Padding(
              padding: const EdgeInsets.only(top: 12, right: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_currentPage + 1}/3',
                    style: const TextStyle(
                      color: Color(0xFF8B5CF6),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // Page view takes all remaining space
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildPage(
                    title: 'Your Passport\nPhoto, ',
                    highlightedTitle: 'Perfected.',
                    subtitle:
                        'Get UK & India passport size photos\nin seconds. AI ensures perfect size,\nlighting & background.',
                    imagePath: isDark 
                        ? 'images/onboarding/dark_theme/1st_image_passport.png'
                        : 'images/onboarding/light_theme/1st_image_passport.png',
                    isDark: isDark,
                  ),
                  _buildPage(
                    title: 'Smart Solo,\n',
                    highlightedTitle: 'Captured ',
                    afterHighlight: 'for You.',
                    subtitle:
                        'Place your phone, relax and let AI\nguide you. We capture the best shots\nwhen you look your best.',
                    imagePath: isDark
                        ? 'images/onboarding/dark_theme/2nd_image_smart_solo.png'
                        : 'images/onboarding/light_theme/2nd_image_smart_solo.png',
                    isDark: isDark,
                  ),
                  _buildPage(
                    title: 'One App.\nEndless ',
                    highlightedTitle: 'Possibilities.',
                    subtitle:
                        'From passport photos to professional\nshots—SmartShutter works with your\nphone or any external camera.',
                    imagePath: isDark
                        ? 'images/onboarding/dark_theme/3rd_image_oneapp.png'
                        : 'images/onboarding/light_theme/3rd_image_oneapp.png',
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            // Bottom section: dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Divider(color: const Color(0xFFE5E7EB), thickness: isDark ? 0.5 : 1.0),
                  const SizedBox(height: 8),
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: isActive
                              ? const Color(0xFF8B5CF6)
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFD1D5DB)),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == 2 ? 'Get Started' : 'Next',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
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

  /// Builds a single onboarding page with title, subtitle, and image.
  /// Everything fits without scrolling.
  Widget _buildPage({
    required String title,
    required String highlightedTitle,
    String? afterHighlight,
    required String subtitle,
    required String imagePath,
    required bool isDark,
  }) {
    return Column(
      children: [
        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                height: 1.2,
                fontFamily: 'Outfit',
              ),
              children: [
                TextSpan(
                  text: title,
                  style: TextStyle(color: AppTheme.ink(isDark)),
                ),
                TextSpan(
                  text: highlightedTitle,
                  style: const TextStyle(color: Color(0xFF8B5CF6)),
                ),
                if (afterHighlight != null)
                  TextSpan(
                    text: afterHighlight,
                    style: TextStyle(color: AppTheme.ink(isDark)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.muted(isDark),
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Image – takes all remaining vertical space, no scroll
        Expanded(
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
            width: double.infinity,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
