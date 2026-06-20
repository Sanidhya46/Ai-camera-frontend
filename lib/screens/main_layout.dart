/// Main tabbed layout structure of the SmartShutter app after onboarding.
/// Provides bottom navigation between three main sections: Home (capture modes), Gallery (photo history), and Profile (settings).
/// Manages tab switching through the global app state and maintains a gradient background across all tabs.
/// Serves as the container for all post-onboarding user interactions with the app.

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
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const HomeTab(),
    const GalleryTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      extendBody: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: appState.isDarkMode 
            ? AppTheme.gradientBg(true) 
            : const BoxDecoration(color: Colors.white),
        child: SafeArea(
          bottom: false,
          child: _tabs[appState.selectedTabIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: appState.selectedTabIndex,
        onTap: (index) {
          appState.setTabIndex(index);
        },
        selectedItemColor: AppTheme.brand,
        unselectedItemColor: AppTheme.muted(appState.isDarkMode),
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.photo_library), label: 'Gallery'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
