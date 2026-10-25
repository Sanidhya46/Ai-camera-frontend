/// Home tab displaying available capture modes, featured hero carousel, and recent photo captures.
/// Matches the design mockup accurately with clean typography, rounded cards, and dynamic theme support.
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'dart:io' show File;
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/screens/passport/guidelines_screen.dart';
import 'package:smart_shutter/screens/smart_solo/setup_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning,';
    } else if (hour < 17) {
      return 'Good afternoon,';
    } else {
      return 'Good evening,';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.isDarkMode;
    final userCaptures = appState.captures;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ──── TOP BAR: Logo + Avatar ────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              Row(
                children: [
                  Image.asset(
                    isDark
                        ? 'assets/images/app_logo.png'
                        : 'assets/images/app_logo_light_theme.png',
                    width: 28,
                    height: 28,
                  ),
                  const SizedBox(width: 7),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Smart',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontFamily: 'Outfit',
                          ),
                        ),
                        const TextSpan(
                          text: 'Shutter',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: Color(0xFF3B82F6),
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Profile Avatar
              GestureDetector(
                onTap: () {
                  appState.setTabIndex(2); // Switch to Profile tab
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : Colors.white,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: appState.profilePhotoPath != null
                        ? Image.file(
                            File(appState.profilePhotoPath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => CircleAvatar(
                              backgroundColor: const Color(0xFF4F46E5),
                              child: Text(
                                appState.userInitial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        : Image.asset(
                            'assets/images/home_page/user_avatar.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => CircleAvatar(
                              backgroundColor: const Color(0xFF4F46E5),
                              child: Text(
                                appState.userInitial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ──── GREETINGS HEADLINE (Evenly balanced and compact) ────
          Text(
            _getGreeting(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            'Your perfect shot starts here.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.3,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Capture more. Create more. Powered by AI.',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 10),

          // ──── FEATURED HERO BANNER (Direct image, slightly rounded corners) ────
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SmartSetupScreen()),
              );
            },
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/home_page/home_page_crousel.png',
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
          ),

          const SizedBox(height: 11),

          // ──── CHOOSE YOUR MODE ────
          Text(
            'Choose your mode',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontFamily: 'Outfit',
            ),
          ),

          const SizedBox(height: 7),

          // Mode 1: Passport / ID Photo
          _buildModeCard(
            context,
            isDark: isDark,
            imageAsset: 'assets/images/home_page/passport_thumb.jpg',
            title: 'Passport / ID Photo',
            subtitle: 'Perfect for documents, visas and official use.',
            badge: 'Popular',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PassportGuidelinesScreen()),
              );
            },
          ),

          const SizedBox(height: 7),

          // Mode 2: Smart Solo Mode
          _buildModeCard(
            context,
            isDark: isDark,
            imageAsset: 'assets/images/home_page/solo_thumb.jpg',
            title: 'Smart Solo Mode',
            subtitle: 'AI enhanced, natural & professional shots.',
            badge: null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SmartSetupScreen()),
              );
            },
          ),

          const SizedBox(height: 11),

          // ──── RECENT CAPTURES HEADER ────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Recent captures',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontFamily: 'Outfit',
                ),
              ),
              InkWell(
                onTap: () {
                  appState.setTabIndex(1); // Switch to Gallery tab
                },
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View all',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: Color(0xFF4F46E5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ──── RECENT CAPTURES (REALITY LINKED & EMPTY STATE) ────
          if (userCaptures.isEmpty)
            _buildEmptyGalleryCard(
              isDark: isDark,
              onOpenGallery: () => appState.setTabIndex(1),
            )
          else
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: userCaptures.length,
                itemBuilder: (context, index) {
                  final cap = userCaptures[index];
                  final path = cap['path'] as String;
                  final timeLabel = _formatCaptureTime(cap['timestamp'] as String?);
                  final isAsset = path.startsWith('assets/');
                  return _buildCaptureThumbnail(
                    isDark: isDark,
                    isAsset: isAsset,
                    imagePath: path,
                    timeLabel: timeLabel,
                    onTap: () {
                      final capType = cap['type'] as String? ?? 'passport';
                      appState.setGalleryActiveFilter(capType);
                      appState.setTabIndex(1);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeCard(
    BuildContext context, {
    required bool isDark,
    required String imageAsset,
    required String title,
    required String subtitle,
    required String? badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFF334155)
                : const Color(0xFFE2E8F0).withValues(alpha: 0.7),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          children: [
            // Left thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.asset(
                imageAsset,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 11),

            // Middle info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.2,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Color(0xFF4F46E5),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Right Chevron
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF6366F1),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureThumbnail({
    required bool isDark,
    required bool isAsset,
    required String imagePath,
    required String timeLabel,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 108,
        height: 108,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo Image
              if (isAsset)
                Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                )
              else if (kIsWeb)
                Image.network(
                  imagePath,
                  fit: BoxFit.cover,
                )
              else
                Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),

              // Bottom timestamp chip
              Positioned(
                left: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.image_outlined,
                        size: 9.5,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 3.5),
                      Text(
                        timeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCaptureTime(String? timestampStr) {
    if (timestampStr == null || timestampStr.isEmpty) return 'Recent';
    try {
      final dt = DateTime.parse(timestampStr).toLocal();
      final now = DateTime.now();
      final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
      final isYesterday = dt.year == now.year && dt.month == now.month && dt.day == now.day - 1;

      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      final timeStr = '$hour:$minute $ampm';

      if (isToday) return 'Today, $timeStr';
      if (isYesterday) return 'Yesterday, $timeStr';

      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]}, $timeStr';
    } catch (_) {
      return 'Recent';
    }
  }

  Widget _buildEmptyGalleryCard({
    required bool isDark,
    required VoidCallback onOpenGallery,
  }) {
    return GestureDetector(
      onTap: onOpenGallery,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.5)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Layered photos illustration matching Image 1 ──
          SizedBox(
            width: 96,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Back Left Card (soft blue, tilted left)
                Transform.rotate(
                  angle: -0.21,
                  child: Container(
                    width: 54,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(-1, 2),
                        ),
                      ],
                    ),
                  ),
                ),

                // Back Right Card (soft lavender, tilted right)
                Transform.rotate(
                  angle: 0.17,
                  child: Container(
                    width: 56,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(1, 2),
                        ),
                      ],
                    ),
                  ),
                ),

                // Front Center Card (white card with mountains and sun)
                Transform.rotate(
                  angle: -0.03,
                  child: Container(
                    width: 64,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7.5),
                      child: Stack(
                        children: [
                          // Sky background
                          Container(color: const Color(0xFFF8FAFC)),

                          // Sun in upper right
                          Positioned(
                            top: 6,
                            right: 10,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFCD34D),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),

                          // Mountain peaks
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 26,
                            child: CustomPaint(
                              painter: _MountainPainter(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Title
          Text(
            'Your gallery is waiting',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontFamily: 'Outfit',
            ),
          ),

          const SizedBox(height: 2),

          // Subtitle
          Text(
            'Your captured photos will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 7),

          // Action link: Open gallery ->
          InkWell(
            onTap: onOpenGallery,
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Open gallery',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4F46E5),
                      fontFamily: 'Outfit',
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: Color(0xFF4F46E5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Back mountain (lighter blue)
    final backPaint = Paint()..color = const Color(0xFF93C5FD);
    final backPath = Path()
      ..moveTo(size.width * 0.35, size.height)
      ..lineTo(size.width * 0.65, size.height * 0.2)
      ..lineTo(size.width * 0.95, size.height)
      ..close();
    canvas.drawPath(backPath, backPaint);

    // Front mountain (primary blue)
    final frontPaint = Paint()..color = const Color(0xFF3B82F6);
    final frontPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.38, size.height * 0.15)
      ..lineTo(size.width * 0.78, size.height)
      ..close();
    canvas.drawPath(frontPath, frontPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
