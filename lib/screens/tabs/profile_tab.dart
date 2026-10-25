/// Profile tab displaying user settings, subscription status, and app preferences.
/// Shows premium/free tier status with ability to toggle subscription, voice guidance mode, and passport specifications.
/// Displays security information and lets users manage their account preferences and app settings.
/// Serves as the control center for personalization and account management within SmartShutter.
/// Automatically fetches user profile data from auth/me endpoint on load.

import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
                      // Avatar with Photo Upload badge
                      GestureDetector(
                        onTap: () => _showPhotoPicker(context, appState),
                        child: Stack(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF4F46E5),
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: appState.profilePhotoPath != null
                                    ? Image.file(
                                        File(appState.profilePhotoPath!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, stack) => _buildDefaultAvatar(appState),
                                      )
                                    : _buildDefaultAvatar(appState),
                              ),
                            ),
                            // Camera edit icon badge
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4F46E5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 13,
                                ),
                              ),
                            ),
                          ],
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
          const SizedBox(height: 18),
          
          // ── 1. Subscription Details Menu ──
          _buildPreferencesCard(
            context,
            'Subscription Details',
            isPremium ? 'SmartShutter Pro (Active)' : 'Free Tier · Tap to upgrade',
            isPremium ? AppTheme.ok : const Color(0xFFF59E0B),
            isDark,
            trailing: const Icon(Icons.workspace_premium_outlined, color: Color(0xFFF59E0B), size: 22),
            onTap: () => _showSubscriptionModal(context, appState),
          ),
          const SizedBox(height: 10),
          
          // ── 2. App Theme ──
          _buildPreferencesCard(
            context,
            'App Theme',
            _getThemeModeName(appState.themeMode),
            AppTheme.ink(isDark),
            isDark,
            trailing: const Icon(Icons.palette_outlined, color: AppTheme.brand, size: 22),
            onTap: () => _showThemePicker(context, appState),
          ),
          const SizedBox(height: 10),
          
          // ── 3. Voice Guidance Mode ──
          _buildPreferencesCard(
            context,
            'Voice Guidance Mode',
            'On · Speaking instructions',
            AppTheme.ink(isDark),
            isDark,
            trailing: const Icon(Icons.volume_up, color: AppTheme.brand, size: 22),
          ),
          const SizedBox(height: 10),
          
          // ── 4. Default Passport Spec ──
          _buildPreferencesCard(
            context,
            'Default Passport Spec',
            'India · 2x2 inch 300 DPI',
            AppTheme.ink(isDark),
            isDark,
            trailing: const Icon(Icons.flag_outlined, color: AppTheme.brand, size: 22),
          ),
          const SizedBox(height: 10),
          
          // ── 5. Privacy Policy ──
          _buildPreferencesCard(
            context,
            'Privacy Policy',
            'Zero data retention · 100% on-device',
            AppTheme.ok,
            isDark,
            trailing: const Icon(Icons.shield_outlined, color: AppTheme.ok, size: 22),
            onTap: () => _showPrivacyPolicyModal(context, isDark),
          ),
          const SizedBox(height: 10),

          // ── 6. Terms of Service ──
          _buildPreferencesCard(
            context,
            'Terms of Service',
            'Usage guidelines & licensing',
            AppTheme.ink(isDark),
            isDark,
            trailing: const Icon(Icons.description_outlined, color: AppTheme.brand, size: 22),
            onTap: () => _showTermsModal(context, isDark),
          ),
          const SizedBox(height: 10),

          // ── 7. App Version ──
          _buildPreferencesCard(
            context,
            'App Version',
            'v1.2.0 (Build 42) · Up to date',
            AppTheme.muted(isDark),
            isDark,
            trailing: const Icon(Icons.verified_outlined, color: AppTheme.ok, size: 20),
          ),
          const SizedBox(height: 20),
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                await appState.clearAuth();
                if (mounted) {
                  nav.pushNamedAndRemoveUntil('/', (route) => false);
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

  Widget _buildDefaultAvatar(AppState appState) {
    return Image.asset(
      'assets/images/home_page/user_avatar.jpg',
      fit: BoxFit.cover,
      errorBuilder: (ctx, err, stack) => CircleAvatar(
        backgroundColor: const Color(0xFF4F46E5),
        child: Text(
          appState.userInitial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  void _showPhotoPicker(BuildContext context, AppState appState) {
    final isDark = appState.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Profile Photo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.ink(isDark),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF4F46E5)),
                  title: Text('Take Photo', style: TextStyle(color: AppTheme.ink(isDark), fontWeight: FontWeight.w600)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.camera, maxWidth: 1000, maxHeight: 1000);
                    if (picked != null) {
                      await appState.setProfilePhotoPath(picked.path);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF4F46E5)),
                  title: Text('Choose from Gallery', style: TextStyle(color: AppTheme.ink(isDark), fontWeight: FontWeight.w600)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1000, maxHeight: 1000);
                    if (picked != null) {
                      await appState.setProfilePhotoPath(picked.path);
                    }
                  },
                ),
                if (appState.profilePhotoPath != null)
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: AppTheme.danger),
                    title: const Text('Remove Photo', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w600)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await appState.setProfilePhotoPath(null);
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSubscriptionModal(BuildContext context, AppState appState) {
    final isDark = appState.isDarkMode;
    final isPremium = appState.isPremium;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.workspace_premium, color: Color(0xFFF59E0B), size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPremium ? 'SmartShutter Pro (Active)' : 'Upgrade to Pro',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.ink(isDark),
                            ),
                          ),
                          Text(
                            isPremium ? 'Full access unlocked' : '\$4.99/month · Cancel anytime',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.muted(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildBenefitRow(Icons.check_circle, 'Unlimited biometric AI passport exports', isDark),
                _buildBenefitRow(Icons.check_circle, 'Multi-angle Smart Solo poses with auto-shutter', isDark),
                _buildBenefitRow(Icons.check_circle, 'Zero watermarks and high-res download', isDark),
                _buildBenefitRow(Icons.check_circle, 'Cloud backup & priority processing queue', isDark),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      appState.togglePremium();
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            appState.isPremium
                                ? 'SmartShutter Pro activated!'
                                : 'Switched to Free tier.',
                          ),
                          backgroundColor: const Color(0xFF4F46E5),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPremium ? const Color(0xFF334155) : const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      isPremium ? 'Downgrade to Free' : 'Unlock Pro Access',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBenefitRow(IconData icon, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.ok, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: AppTheme.ink(isDark)),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: AppTheme.ok, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Privacy Policy',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.ink(isDark)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildPolicyItem('Zero Permanent Photo Storage', 'Your captured photos and face scans are analyzed on your device or in memory and never retained on remote servers without your explicit saving.', isDark),
                _buildPolicyItem('Biometric Privacy', 'Facial geometry data is solely used to verify passport compliance guidelines (eyes open, head tilt) and immediately discarded.', isDark),
                _buildPolicyItem('Local Device Encryption', 'Photos saved to your history remain strictly on your local device storage unless you choose to share them.', isDark),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTermsModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.description_outlined, color: AppTheme.brand, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Terms of Service',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.ink(isDark)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildPolicyItem('License & Usage', 'SmartShutter provides automated AI assistance for personal and commercial photo composition and standard passport cropping.', isDark),
                _buildPolicyItem('Official Compliance Note', 'While our algorithm aligns with standard ICAO 9303 specifications, always verify your destination country specific embassy guidelines.', isDark),
                _buildPolicyItem('Subscriptions & Auto-Renewal', 'Pro subscriptions renew on a monthly basis and can be managed or cancelled at any time from your account settings.', isDark),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPolicyItem(String title, String desc, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.ink(isDark))),
          const SizedBox(height: 2),
          Text(desc, style: TextStyle(fontSize: 12, color: AppTheme.muted(isDark), height: 1.35)),
        ],
      ),
    );
  }
}

