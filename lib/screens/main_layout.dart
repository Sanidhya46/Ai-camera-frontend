/// Main tabbed layout structure of the SmartShutter app after onboarding.
/// Provides bottom navigation between four main sections:
/// Home (capture modes & quick camera), Gallery (photo history), AI Tools, and Profile (settings).
/// Custom styled bottom navigation bar matching the aesthetic design.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/core/theme.dart';
import 'package:smart_shutter/screens/tabs/home_tab.dart';
import 'package:smart_shutter/screens/tabs/gallery_tab.dart';
import 'package:smart_shutter/screens/tabs/profile_tab.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final List<Widget> _tabs = [
    const HomeTab(),
    const GalleryTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.isDarkMode;
    final selectedIndex = appState.selectedTabIndex.clamp(0, _tabs.length - 1);

    return Scaffold(
      extendBody: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: isDark 
            ? AppTheme.gradientBg(true) 
            : const BoxDecoration(color: Colors.white),
        child: SafeArea(
          bottom: false,
          child: _tabs[selectedIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context: context,
                  index: 0,
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: selectedIndex == 0,
                  isDark: isDark,
                  onTap: () => appState.setTabIndex(0),
                ),
                _buildNavItem(
                  context: context,
                  index: 1,
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  isSelected: selectedIndex == 1,
                  isDark: isDark,
                  onTap: () => appState.setTabIndex(1),
                ),
                _buildNavItem(
                  context: context,
                  index: 2,
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  isSelected: selectedIndex == 2,
                  isDark: isDark,
                  onTap: () => appState.setTabIndex(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    const activeColor = Color(0xFF4F46E5);
    final inactiveColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 3),
            // Blue bottom indicator bar for active item
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2.5,
              width: isSelected ? 16 : 0,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
