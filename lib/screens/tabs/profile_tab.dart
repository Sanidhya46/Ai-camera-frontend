/// Profile tab displaying user settings, subscription status, and app preferences.
/// Shows premium/free tier status with ability to toggle subscription, voice guidance mode, and passport specifications.
/// Displays security information and lets users manage their account preferences and app settings.
/// Serves as the control center for personalization and account management within SmartShutter.
/// Automatically fetches user profile data from auth/me endpoint on load.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/core/theme.dart';
import 'package:smart_shutter/core/services/auth_service.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Fetch user profile when profile tab loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    final appState = context.read<AppState>();
    if (!appState.isLoggedIn) {
      setState(() => _isLoading = false);
      return;
    }

    final authService = AuthService();
    final result = await authService.getProfile(appState.accessToken!);

    if (result['success'] == true && mounted) {
      await appState.setCurrentUser(result['data'] as Map<String, dynamic>);
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isPremium = appState.isPremium;
    final isDark = appState.isDarkMode;

    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF090D1A) : Colors.white,
            boxShadow: !isDark ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 4),
                blurRadius: 8,
              ),
            ] : null,
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? AppTheme.ink(isDark) : Colors.black87)),
              Text('Settings and subscription preferences', style: TextStyle(fontSize: 12, color: isDark ? AppTheme.muted(isDark) : Colors.black54)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info Card
          if (appState.isLoggedIn)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassmorphicDecoration(isDark),
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppTheme.brand))
                : Row(
                    children: [
                      // Avatar
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [AppTheme.brand, AppTheme.brand2],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            appState.userInitial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appState.userFullName.isNotEmpty ? appState.userFullName : 'User',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.ink(isDark),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              appState.maskedEmail.isNotEmpty ? appState.maskedEmail : appState.userEmail,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.muted(isDark),
                              ),
                            ),
                            if (appState.memberSince.isNotEmpty)
                              Text(
                                'Member since ${appState.memberSince}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.muted(isDark),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
            ),
          const SizedBox(height: 24),
          
          _buildPreferencesCard(
            context,
            'Subscription Plan',
            isPremium ? 'Premium Active (PRO)' : 'Free Tier',
            isPremium ? AppTheme.ok : AppTheme.brand2,
            isDark,
            trailing: Switch.adaptive(
              value: isPremium,
              activeColor: AppTheme.brand,
              onChanged: (val) async {
                await context.read<AppState>().setPremium(val);
              },
            ),
          ),
          const SizedBox(height: 12),
          
          _buildPreferencesCard(
            context,
            'App Theme',
            _getThemeModeName(appState.themeMode),
            AppTheme.ink(isDark),
            isDark,
            trailing: const Icon(Icons.palette_outlined, color: AppTheme.brand, size: 22),
            onTap: () => _showThemePicker(context, appState),
          ),
          const SizedBox(height: 12),
          
          _buildPreferencesCard(
            context,
            'Voice Guidance Mode',
            'On · Speaking instructions',
            AppTheme.ink(isDark),
            isDark,
            trailing: const Icon(Icons.volume_up, color: AppTheme.brand, size: 22),
          ),
          const SizedBox(height: 12),
          
          _buildPreferencesCard(
            context,
            'Default Passport Spec',
            'India · 2x2 inch 300 DPI',
            AppTheme.ink(isDark),
            isDark,
            trailing: const Icon(Icons.flag_outlined, color: AppTheme.brand, size: 22),
          ),
          const SizedBox(height: 12),
          
          _buildPreferencesCard(
            context,
            'Privacy & Data Security',
            '100% Secure Local Processing',
            AppTheme.ok,
            isDark,
            trailing: const Icon(Icons.shield_outlined, color: AppTheme.ok, size: 22),
          ),
          const SizedBox(height: 12),
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await appState.clearAuth();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.danger,
                side: const BorderSide(color: AppTheme.danger),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
          ),
        ),
      ],
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return 'System Default';
      case ThemeMode.light: return 'Light';
      case ThemeMode.dark: return 'Dark';
    }
  }

  void _showThemePicker(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: appState.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'Select Theme',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.ink(appState.isDarkMode),
                  ),
                ),
              ),
              _buildThemeTile(context, appState, 'System Default', ThemeMode.system, Icons.brightness_auto),
              _buildThemeTile(context, appState, 'Light', ThemeMode.light, Icons.light_mode),
              _buildThemeTile(context, appState, 'Dark', ThemeMode.dark, Icons.dark_mode),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeTile(BuildContext context, AppState appState, String title, ThemeMode mode, IconData icon) {
    final isSelected = appState.themeMode == mode;
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, size: 20, color: isSelected ? AppTheme.brand : AppTheme.muted(appState.isDarkMode)),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          color: AppTheme.ink(appState.isDarkMode),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, size: 18, color: AppTheme.brand) : null,
      onTap: () {
        appState.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildPreferencesCard(
    BuildContext context,
    String title,
    String value,
    Color valueColor,
    bool isDark, {
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: AppTheme.glassmorphicDecoration(isDark),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.ink(isDark)),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 13, color: valueColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
      ),
    );
  }
}

