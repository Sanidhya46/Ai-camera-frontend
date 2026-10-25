/// AI Tools tab displaying SmartShutter's AI photography tools and features.
/// Features include Smart Solo framing, Passport Compliance Checker, Background Enhancer, and Auto Retouch.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/screens/passport/guidelines_screen.dart';
import 'package:smart_shutter/screens/smart_solo/setup_screen.dart';

class AiToolsTab extends StatelessWidget {
  const AiToolsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.isDarkMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF4F46E5),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Photography Tools',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Powered by cutting-edge vision models',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tool 1: Smart Solo Auto-Director
          _buildToolCard(
            context,
            isDark: isDark,
            title: 'Smart Solo Auto-Director',
            badge: 'POPULAR',
            badgeColor: const Color(0xFF4F46E5),
            badgeBg: const Color(0xFFEEF2FF),
            description: 'Hands-free automated camera that tracks your pose and captures the perfect aesthetic shot.',
            icon: Icons.person_pin_circle_outlined,
            buttonText: 'Launch Solo Mode',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SmartSetupScreen()),
              );
            },
          ),
          const SizedBox(height: 14),

          // Tool 2: Passport & Visa Compliance Inspector
          _buildToolCard(
            context,
            isDark: isDark,
            title: 'Passport & Visa Compliance AI',
            badge: 'OFFICIAL READY',
            badgeColor: const Color(0xFF10B981),
            badgeBg: const Color(0xFFECFDF5),
            description: 'Validates lighting, background, head ratio, and facial expressions against ICAO standards.',
            icon: Icons.verified_user_outlined,
            buttonText: 'Inspect Passport Photo',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PassportGuidelinesScreen()),
              );
            },
          ),
          const SizedBox(height: 14),

          // Tool 3: Background Remover & Studio Glow
          _buildToolCard(
            context,
            isDark: isDark,
            title: 'AI Background & Studio Glow',
            badge: 'STUDIO',
            badgeColor: const Color(0xFF8B5CF6),
            badgeBg: const Color(0xFFF5F3FF),
            description: 'Instantly isolate subjects, replace backgrounds with solid white/blue, or apply studio lighting.',
            icon: Icons.blur_on_outlined,
            buttonText: 'Select Photo to Edit',
            onTap: () {
              appState.setTabIndex(1); // Go to Gallery
            },
          ),
          const SizedBox(height: 14),

          // Tool 4: Auto Retouch & Smart Framing
          _buildToolCard(
            context,
            isDark: isDark,
            title: 'Auto Retouch & Golden Ratio',
            badge: 'ENHANCE',
            badgeColor: const Color(0xFFF59E0B),
            badgeBg: const Color(0xFFFEF3C7),
            description: 'Automatically balances exposure, skin tone clarity, and aligns subjects with rule-of-thirds.',
            icon: Icons.auto_fix_high_outlined,
            buttonText: 'View Gallery',
            onTap: () {
              appState.setTabIndex(1);
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required bool isDark,
    required String title,
    required String badge,
    required Color badgeColor,
    required Color badgeBg,
    required String description,
    required IconData icon,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0).withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0A0F172A),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: badgeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? badgeColor.withValues(alpha: 0.2) : badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: badgeColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
