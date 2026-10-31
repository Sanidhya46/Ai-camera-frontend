library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/core/theme.dart';
import 'package:smart_shutter/screens/smart_solo/ai_plan_screen.dart';
import 'package:smart_shutter/widgets/app_header.dart';

/// Setup screen for Smart Solo mode where users configure AI shooting preferences.
/// Features:
/// - Consistent AppHeader with back navigation
/// - Scrollable page header: "Smart Solo Setup" and subtitle scroll naturally with the content
/// - Clean 3-options-per-row grid layout with zero overflow
/// - Only image + single-word mode name per option (no lengthy descriptions)
/// - Streamlined bottom action button without redundant chip row.
class SmartSetupScreen extends StatefulWidget {
  const SmartSetupScreen({super.key});

  @override
  State<SmartSetupScreen> createState() => _SmartSetupScreenState();
}

class _SmartSetupScreenState extends State<SmartSetupScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.isDarkMode;

    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBg(isDark),
        child: SafeArea(
          child: Column(
            children: [
              // ── 1. Consistent App Header with Back Navigation ──
              AppHeader(
                showBackButton: true,
                onBack: () => Navigator.pop(context),
              ),

              // ── 2. Scrollable Content (Header + Categories) ──
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Scrollable Screen Title & Subtitle at the Top
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14, top: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: Color(0xFF4F46E5),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Smart Solo Setup',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    fontFamily: 'Outfit',
                                  ),
                                ),
                                Text(
                                  'Tell AI what kind of shot you want',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ── CATEGORY 1: What are you shooting for? ──
                      _buildCategorySection(
                        title: 'What are you shooting for?',
                        isDark: isDark,
                        options: [
                          _SetupOption(
                            name: 'Travel',
                            icon: Icons.flight_takeoff_rounded,
                            accentColor: const Color(0xFF3B82F6),
                            imagePath: 'assets/images/home_page/recent_lake.jpg',
                          ),
                          _SetupOption(
                            name: 'Portrait',
                            icon: Icons.face_retouching_natural_rounded,
                            accentColor: const Color(0xFFEC4899),
                            imagePath: 'assets/images/home_page/recent_curls.jpg',
                          ),
                          _SetupOption(
                            name: 'Fashion',
                            icon: Icons.checkroom_rounded,
                            accentColor: const Color(0xFF8B5CF6),
                            imagePath: 'assets/images/home_page/fashion_street.jpg',
                          ),
                          _SetupOption(
                            name: 'Reel',
                            icon: Icons.videocam_rounded,
                            accentColor: const Color(0xFFF43F5E),
                            imagePath: 'assets/images/home_page/solo_thumb.jpg',
                          ),
                          _SetupOption(
                            name: 'Fitness',
                            icon: Icons.fitness_center_rounded,
                            accentColor: const Color(0xFF10B981),
                            imagePath: 'assets/images/home_page/fitness_athlete.jpg',
                          ),
                          _SetupOption(
                            name: 'Headshot',
                            icon: Icons.badge_outlined,
                            accentColor: const Color(0xFF0EA5E9),
                            imagePath: 'assets/images/home_page/passport_thumb.jpg',
                          ),
                        ],
                        selected: appState.selectedGoal,
                        onSelect: (val) => context.read<AppState>().setSetupOptions(goal: val),
                      ),
                      const SizedBox(height: 14),

                      // ── CATEGORY 2: Environment & Scene ──
                      _buildCategorySection(
                        title: 'Environment & Scene',
                        isDark: isDark,
                        options: [
                          _SetupOption(
                            name: 'City',
                            icon: Icons.location_city_rounded,
                            accentColor: const Color(0xFF64748B),
                            imagePath: 'assets/images/home_page/city_skyline.jpg',
                          ),
                          _SetupOption(
                            name: 'Beach',
                            icon: Icons.beach_access_rounded,
                            accentColor: const Color(0xFF06B6D4),
                            imagePath: 'assets/images/home_page/beach_scene.jpg',
                          ),
                          _SetupOption(
                            name: 'Nature',
                            icon: Icons.forest_rounded,
                            accentColor: const Color(0xFF059669),
                            imagePath: 'assets/images/home_page/nature_forest.jpg',
                          ),
                          _SetupOption(
                            name: 'Café',
                            icon: Icons.local_cafe_rounded,
                            accentColor: const Color(0xFFD97706),
                            imagePath: 'assets/images/home_page/cozy_cafe.jpg',
                          ),
                          _SetupOption(
                            name: 'Studio',
                            icon: Icons.camera_alt_outlined,
                            accentColor: const Color(0xFF6366F1),
                            imagePath: 'assets/images/home_page/studio_room.jpg',
                          ),
                          _SetupOption(
                            name: 'Sunset',
                            icon: Icons.wb_twilight_rounded,
                            accentColor: const Color(0xFFF97316),
                            imagePath: 'assets/images/home_page/recent_sunset.jpg',
                          ),
                        ],
                        selected: appState.selectedEnv,
                        onSelect: (val) => context.read<AppState>().setSetupOptions(env: val),
                      ),
                      const SizedBox(height: 14),

                      // ── CATEGORY 3: Shot type & style ──
                      _buildCategorySection(
                        title: 'Shot type & style',
                        isDark: isDark,
                        options: [
                          _SetupOption(
                            name: 'Full body',
                            icon: Icons.accessibility_new_rounded,
                            accentColor: const Color(0xFF3B82F6),
                            imagePath: 'assets/images/home_page/solo_thumb.jpg',
                          ),
                          _SetupOption(
                            name: 'Half body',
                            icon: Icons.person_rounded,
                            accentColor: const Color(0xFF8B5CF6),
                            imagePath: 'assets/images/home_page/recent_curls.jpg',
                          ),
                          _SetupOption(
                            name: 'Cinematic',
                            icon: Icons.movie_creation_outlined,
                            accentColor: const Color(0xFFE11D48),
                            imagePath: 'assets/images/home_page/recent_sunset.jpg',
                          ),
                          _SetupOption(
                            name: 'Natural',
                            icon: Icons.eco_rounded,
                            accentColor: const Color(0xFF10B981),
                            imagePath: 'assets/images/home_page/nature_forest.jpg',
                          ),
                          _SetupOption(
                            name: 'Close-up',
                            icon: Icons.center_focus_strong_rounded,
                            accentColor: const Color(0xFF6366F1),
                            imagePath: 'assets/images/home_page/passport_thumb.jpg',
                          ),
                          _SetupOption(
                            name: 'Low Angle',
                            icon: Icons.arrow_upward_rounded,
                            accentColor: const Color(0xFFF59E0B),
                            imagePath: 'assets/images/home_page/city_skyline.jpg',
                          ),
                        ],
                        selected: appState.selectedStyle,
                        onSelect: (val) => context.read<AppState>().setSetupOptions(style: val),
                      ),
                      const SizedBox(height: 14),

                      // ── CATEGORY 4: Lighting & Atmosphere ──
                      _buildCategorySection(
                        title: 'Lighting & Atmosphere',
                        isDark: isDark,
                        options: [
                          _SetupOption(
                            name: 'Golden',
                            icon: Icons.wb_sunny_rounded,
                            accentColor: const Color(0xFFF59E0B),
                            imagePath: 'assets/images/home_page/recent_sunset.jpg',
                          ),
                          _SetupOption(
                            name: 'Softbox',
                            icon: Icons.light_mode_rounded,
                            accentColor: const Color(0xFF06B6D4),
                            imagePath: 'assets/images/home_page/studio_room.jpg',
                          ),
                          _SetupOption(
                            name: 'Daylight',
                            icon: Icons.cloud_queue_rounded,
                            accentColor: const Color(0xFF3B82F6),
                            imagePath: 'assets/images/home_page/recent_lake.jpg',
                          ),
                        ],
                        selected: appState.selectedLighting,
                        onSelect: (val) => context.read<AppState>().setSetupOptions(lighting: val),
                      ),
                      const SizedBox(height: 14),

                      // ── CATEGORY 5: Pose Energy & Vibe ──
                      _buildCategorySection(
                        title: 'Pose Energy & Vibe',
                        isDark: isDark,
                        options: [
                          _SetupOption(
                            name: 'Candid',
                            icon: Icons.sentiment_very_satisfied_rounded,
                            accentColor: const Color(0xFF10B981),
                            imagePath: 'assets/images/home_page/recent_curls.jpg',
                          ),
                          _SetupOption(
                            name: 'Bold',
                            icon: Icons.flash_on_rounded,
                            accentColor: const Color(0xFF4F46E5),
                            imagePath: 'assets/images/home_page/fashion_street.jpg',
                          ),
                          _SetupOption(
                            name: 'Motion',
                            icon: Icons.directions_run_rounded,
                            accentColor: const Color(0xFFF97316),
                            imagePath: 'assets/images/home_page/fitness_athlete.jpg',
                          ),
                        ],
                        selected: appState.selectedVibe,
                        onSelect: (val) => context.read<AppState>().setSetupOptions(vibe: val),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // ── 3. Bottom Action Button (Clean: Only Icon + Text) ──
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AiPlanScreen()),
                      );
                    },
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text(
                      'Generate AI Shoot Plan',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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

  Widget _buildCategorySection({
    required String title,
    required bool isDark,
    required List<_SetupOption> options,
    required String selected,
    required Function(String) onSelect,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 12),

          // ── Three options in one row grid, clean image + one text word ──
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: options.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              final opt = options[index];
              final isSelected = opt.name == selected;

              return GestureDetector(
                onTap: () => onSelect(opt.name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF4F46E5).withValues(alpha: isDark ? 0.22 : 0.08)
                        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF4F46E5)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ── Image Header with Icon Badge ──
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                opt.imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Container(
                                  color: opt.accentColor.withValues(alpha: 0.2),
                                  child: Icon(opt.icon, color: opt.accentColor),
                                ),
                              ),
                              // Subtle bottom gradient
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.35),
                                    ],
                                  ),
                                ),
                              ),
                              // Floating Icon Badge
                              Positioned(
                                bottom: 4,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF4F46E5)
                                        : Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(opt.icon, size: 12, color: Colors.white),
                                ),
                              ),
                              // Checkmark badge when selected
                              if (isSelected)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(2.5),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF4F46E5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // ── Single text word about mode ──
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                          child: Text(
                            opt.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected
                                  ? const Color(0xFF4F46E5)
                                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SetupOption {
  final String name;
  final IconData icon;
  final Color accentColor;
  final String imagePath;

  const _SetupOption({
    required this.name,
    required this.icon,
    required this.accentColor,
    required this.imagePath,
  });
}
