library;

import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/core/theme.dart';
import 'package:smart_shutter/core/services/auth_service.dart';
import 'package:smart_shutter/widgets/app_header.dart';
import 'package:smart_shutter/screens/profile/edit_profile_screen.dart';

/// Profile tab displaying user information, settings, and subscription preferences.
/// Features:
/// - Consistent AppHeader at top
/// - Profile card with top-right Pencil edit icon
/// - Dedicated Edit Profile page/popup with 11 details (Email is read-only)
/// - OTP verification for Mobile Number and Email
/// - Additional menus: Privacy policy, App version, Subscription details, Terms and conditions,
///   Follow us on social media (Facebook, Instagram, Pinterest, etc.), and Help & Support form.
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
        // ── 1. Consistent App Header ──
        const AppHeader(),

        // ── 2. Scrollable Settings Content ──
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── User Info Card with Top-Right Pencil Edit Icon ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.25 : 0.05,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Profile Avatar
                                GestureDetector(
                                  onTap: () =>
                                      _showPhotoPicker(context, appState),
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF4F46E5),
                                            width: 2,
                                          ),
                                        ),
                                        child: ClipOval(
                                          child:
                                              appState.profilePhotoPath != null
                                              ? Image.file(
                                                  File(
                                                    appState.profilePhotoPath!,
                                                  ),
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (ctx, err, stack) =>
                                                          _buildDefaultAvatar(
                                                            appState,
                                                          ),
                                                )
                                              : Image.asset(
                                                  'assets/images/home_page/user_avatar.jpg',
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (ctx, err, stack) =>
                                                          _buildDefaultAvatar(
                                                            appState,
                                                          ),
                                                ),
                                        ),
                                      ),
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
                                            size: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // User Name & Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              appState.userFullName.isNotEmpty
                                                  ? appState.userFullName
                                                  : 'Creator',
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ),

                                          // ── PENCIL EDIT ICON AT TOP RIGHT CORNER ──
                                          GestureDetector(
                                            onTap: () => _openEditProfileModal(
                                              context,
                                              appState,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF4F46E5,
                                                ).withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.edit_outlined,
                                                    color: Color(0xFF4F46E5),
                                                    size: 16,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Edit',
                                                    style: TextStyle(
                                                      color: Color(0xFF4F46E5),
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '@${appState.userUsername} · ${appState.userProfession}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        appState.userEmail,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? const Color(0xFF64748B)
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Bio / Status display
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                appState.userStatus,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: isDark
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 18),

                // ── 1. Subscription Details Menu ──
                _buildMenuCard(
                  context,
                  title: 'Subscription Details',
                  subtitle: isPremium
                      ? 'SmartShutter Pro (Active)'
                      : 'Free Tier · Tap to upgrade',
                  subtitleColor: isPremium
                      ? AppTheme.ok
                      : const Color(0xFFF59E0B),
                  icon: Icons.workspace_premium_outlined,
                  iconColor: const Color(0xFFF59E0B),
                  isDark: isDark,
                  onTap: () => _showSubscriptionModal(context, appState),
                ),
                const SizedBox(height: 10),

                // ── 2. App Theme ──
                _buildMenuCard(
                  context,
                  title: 'App Theme',
                  subtitle: _getThemeModeName(appState.themeMode),
                  subtitleColor: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  icon: Icons.palette_outlined,
                  iconColor: const Color(0xFF4F46E5),
                  isDark: isDark,
                  onTap: () => _showThemePicker(context, appState),
                ),
                const SizedBox(height: 10),

                // ── 3. Help and Support (Form) ──
                _buildMenuCard(
                  context,
                  title: 'Help and Support',
                  subtitle: 'FAQs, report issues & contact support team',
                  subtitleColor: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  icon: Icons.support_agent_rounded,
                  iconColor: const Color(0xFF0284C7),
                  isDark: isDark,
                  onTap: () => _showHelpSupportModal(context, appState),
                ),
                const SizedBox(height: 10),

                // ── 4. Follow Us On (Social Media) ──
                _buildMenuCard(
                  context,
                  title: 'Follow Us On',
                  subtitle: 'Instagram, Facebook, Pinterest, Twitter & YouTube',
                  subtitleColor: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  icon: Icons.share_rounded,
                  iconColor: const Color(0xFFEC4899),
                  isDark: isDark,
                  onTap: () => _showSocialMediaModal(context, isDark),
                ),
                const SizedBox(height: 10),

                // ── 5. Privacy Policy ──
                _buildMenuCard(
                  context,
                  title: 'Privacy Policy',
                  subtitle:
                      'Zero image retention · 100% on-device edge processing',
                  subtitleColor: AppTheme.ok,
                  icon: Icons.shield_outlined,
                  iconColor: AppTheme.ok,
                  isDark: isDark,
                  onTap: () => _showPrivacyPolicyModal(context, isDark),
                ),
                const SizedBox(height: 10),

                // ── 6. Terms and Conditions ──
                _buildMenuCard(
                  context,
                  title: 'Terms and Conditions',
                  subtitle: 'Usage guidelines & licensing agreements',
                  subtitleColor: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  icon: Icons.description_outlined,
                  iconColor: const Color(0xFF8B5CF6),
                  isDark: isDark,
                  onTap: () => _showTermsModal(context, isDark),
                ),
                const SizedBox(height: 10),

                // ── 7. App Version ──
                _buildMenuCard(
                  context,
                  title: 'App Version',
                  subtitle: 'v1.2.0 (Build 42) · Up to date',
                  subtitleColor: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  icon: Icons.verified_outlined,
                  iconColor: AppTheme.ok,
                  isDark: isDark,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text('SmartShutter Version'),
                        content: const Text(
                          'You are on the latest version v1.2.0 (Build 42).\nAll AI camera models and compliance engines are up to date.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // ── Log Out Button ──
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
                    child: const Text(
                      'Log Out',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // DEDICATED EDIT PROFILE FULL OVERLAY SCREEN
  // ══════════════════════════════════════════════════════════════════════════════
  void _openEditProfileModal(BuildContext context, AppState appState) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // HELP AND SUPPORT FORM MODAL
  // ══════════════════════════════════════════════════════════════════════════════
  void _showHelpSupportModal(BuildContext context, AppState appState) {
    final isDark = appState.isDarkMode;
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    String selectedCategory = 'Camera & Pose Guidance';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setFormState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Help & Support',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Submit a ticket or view common questions',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Selector
                          Text(
                            'Support Topic',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedCategory,
                                isExpanded: true,
                                dropdownColor: isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                                items:
                                    [
                                          'Camera & Pose Guidance',
                                          'Biometric ID Compliance',
                                          'Subscription & Billing',
                                          'Account & Security',
                                          'Feature Request / Other',
                                        ]
                                        .map(
                                          (c) => DropdownMenuItem(
                                            value: c,
                                            child: Text(
                                              c,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setFormState(() => selectedCategory = val);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Subject Field
                          _buildEditField(
                            label: 'Subject',
                            controller: subjectController,
                            icon: Icons.title_rounded,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 14),

                          // Detailed Message
                          _buildEditField(
                            label: 'Describe your issue or feedback',
                            controller: messageController,
                            icon: Icons.message_outlined,
                            isDark: isDark,
                            maxLines: 4,
                          ),
                          const SizedBox(height: 18),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (subjectController.text.trim().isEmpty ||
                                    messageController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please fill in both Subject and Message',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                Navigator.pop(modalCtx);
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    title: const Text(
                                      'Support Ticket Created!',
                                    ),
                                    content: const Text(
                                      'Ticket #SH-9482 has been submitted to the SmartShutter support team. We usually respond within 12-24 hours via email.',
                                    ),
                                    actions: [
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Done'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(Icons.send_rounded, size: 16),
                              label: const Text('Submit Support Request'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Quick FAQs Section
                          Text(
                            'Quick FAQs',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildFaqItem(
                            'How does Smart Solo pose guidance work?',
                            'AI detects your posture in real-time, providing voice instructions and haptic guidance until your angle matches the preset.',
                            isDark,
                          ),
                          _buildFaqItem(
                            'Are my uploaded photos stored on cloud servers?',
                            'No! SmartShutter adheres to a strict Zero-Retention Policy. All biometric analysis is done on-device or purged immediately after processing.',
                            isDark,
                          ),
                          _buildFaqItem(
                            'What passport standards are supported?',
                            'We support ICAO 9303 standards for US (2x2 inch), UK/Europe (35x45mm), India, Canada, and 140+ countries.',
                            isDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // SOCIAL MEDIA MODAL (FOLLOW US ON)
  // ══════════════════════════════════════════════════════════════════════════════
  void _showSocialMediaModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.share_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Follow Us On Social Media',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                fontFamily: 'Outfit',
                              ),
                            ),
                            Text(
                              'Join our creative community for tutorials & daily tips',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildSocialLinkItem(
                    platform: 'Instagram',
                    handle: '@smartshutter.ai',
                    tag: 'REELS & TIPS',
                    icon: Icons.camera_alt_rounded,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF833AB4),
                        Color(0xFFFD1D1D),
                        Color(0xFFFCB045),
                      ],
                    ),
                    isDark: isDark,
                  ),
                  _buildSocialLinkItem(
                    platform: 'Facebook',
                    handle: 'SmartShutter Official Community',
                    tag: 'COMMUNITY',
                    icon: Icons.facebook,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1877F2), Color(0xFF0052CC)],
                    ),
                    isDark: isDark,
                  ),
                  _buildSocialLinkItem(
                    platform: 'Pinterest',
                    handle: 'SmartShutter Poses & Aesthetics',
                    tag: 'AESTHETICS',
                    icon: Icons.push_pin_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE60023), Color(0xFFBD081C)],
                    ),
                    isDark: isDark,
                  ),
                  _buildSocialLinkItem(
                    platform: 'Twitter / X',
                    handle: '@SmartShutterApp',
                    tag: 'UPDATES',
                    icon: Icons.tag_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF334155)],
                    ),
                    isDark: isDark,
                  ),
                  _buildSocialLinkItem(
                    platform: 'YouTube',
                    handle: 'SmartShutter Tutorials & Masterclasses',
                    tag: 'TUTORIALS',
                    icon: Icons.play_circle_fill_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF0000), Color(0xFFCC0000)],
                    ),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // SUBSCRIPTION DETAILS MODAL
  // ══════════════════════════════════════════════════════════════════════════════
  void _showSubscriptionModal(BuildContext context, AppState appState) {
    final isDark = appState.isDarkMode;
    final isPremium = appState.isPremium;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subscription Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        isPremium
                            ? 'Active Plan: SmartShutter Pro'
                            : 'Current Plan: Free Tier',
                        style: TextStyle(
                          fontSize: 12,
                          color: isPremium
                              ? AppTheme.ok
                              : const Color(0xFFF59E0B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (isPremium ? AppTheme.ok : const Color(0xFFF59E0B))
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isPremium ? 'PRO ACTIVE' : 'FREE TIER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isPremium
                            ? AppTheme.ok
                            : const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Feature list
              _buildSubBenefit(
                'Unlimited AI Biometric Compliance Checks',
                'Analyze lighting, posture, eye line and background compliance',
                isDark,
              ),
              _buildSubBenefit(
                'Full 4K Ultra-HD Photo Export',
                'Download 300 DPI print-ready photo sheets and singles without watermarks',
                isDark,
              ),
              _buildSubBenefit(
                'All Smart Solo Poses & AI Shoot Planner',
                'Unlock 50+ cinematic, fashion, travel and professional guidance poses',
                isDark,
              ),
              _buildSubBenefit(
                'Zero Ad Interruptions & Priority GPU Cloud Inference',
                'Instantaneous pose detection feedback with ultra-low latency',
                isDark,
              ),
              const SizedBox(height: 20),

              // Toggle button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await appState.togglePremium();
                    if (modalCtx.mounted) Navigator.pop(modalCtx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            appState.isPremium
                                ? 'Upgraded to SmartShutter Pro!'
                                : 'Switched back to Free Tier',
                          ),
                          backgroundColor: appState.isPremium
                              ? AppTheme.ok
                              : const Color(0xFF1E293B),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPremium
                        ? const Color(0xFF334155)
                        : const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isPremium
                        ? 'Downgrade to Free Tier'
                        : 'Upgrade to SmartShutter Pro (\$4.99/mo)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // PRIVACY POLICY & TERMS MODALS
  // ══════════════════════════════════════════════════════════════════════════════
  void _showPrivacyPolicyModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Effective Date: November 2026',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    '1. Zero Data Retention Principle:\n'
                    'SmartShutter does not retain, store, or sell any captured biometric facial data or full-resolution photos on our remote servers. Photos uploaded for compliance testing are kept in volatile memory only during the active analysis request and purged immediately.\n\n'
                    '2. On-Device Edge Processing:\n'
                    'Whenever available on supported hardware, pose tracking, framing detection, and face orientation analysis run locally on your device via TensorFlow Lite and CoreML without transmitting video frames over the internet.\n\n'
                    '3. End-to-End Encryption:\n'
                    'All API communications with our backend servers are strictly encrypted using TLS 1.3 over HTTPS.\n\n'
                    '4. User Data Control:\n'
                    'You retain 100% complete ownership of every photograph taken with SmartShutter. You can clear your local photo history or delete your user account at any time.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF334155),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTermsModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Terms and Conditions',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Last updated: November 2026',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    '1. Acceptance of Terms:\n'
                    'By downloading, installing, or using SmartShutter, you agree to comply with and be bound by these terms.\n\n'
                    '2. Photo Compliance & Guarantees:\n'
                    'While SmartShutter uses advanced AI to evaluate biometric standards according to official passport authority specs, acceptance of ID photos is ultimately determined by respective government passport offices.\n\n'
                    '3. Intellectual Property:\n'
                    'All proprietary AI guidance algorithms, visual presets, sound prompts, and application design remain the exclusive intellectual property of SmartShutter.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF334155),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color subtitleColor,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: subtitleColor),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              icon: Icon(icon, size: 18, color: const Color(0xFF4F46E5)),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLinkItem({
    required String platform,
    required String handle,
    required String tag,
    required IconData icon,
    required Gradient gradient,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opening $platform: $handle'),
                backgroundColor: const Color(0xFF1E293B),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            platform,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF475569),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        handle,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubBenefit(String title, String desc, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: AppTheme.ok, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer, bool isDark) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        question,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            answer,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System Default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  Widget _buildModalOption({
    required IconData icon,
    required String title,
    bool isSelected = false,
    bool isDanger = false,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF6366F1).withValues(alpha: 0.12)
                  : (isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF6366F1)
                    : (isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isDanger
                      ? AppTheme.danger
                      : (isSelected
                            ? const Color(0xFF6366F1)
                            : (isDark
                                  ? Colors.white70
                                  : const Color(0xFF475569))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isDanger
                          ? AppTheme.danger
                          : (isSelected
                                ? const Color(0xFF6366F1)
                                : (isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A))),
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF6366F1),
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = appState.isDarkMode;
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose App Theme',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              _buildModalOption(
                icon: Icons.brightness_auto,
                title: 'System Default',
                isSelected: appState.themeMode == ThemeMode.system,
                isDark: isDark,
                onTap: () {
                  appState.setThemeMode(ThemeMode.system);
                  Navigator.pop(ctx);
                },
              ),
              _buildModalOption(
                icon: Icons.light_mode,
                title: 'Light Theme',
                isSelected: appState.themeMode == ThemeMode.light,
                isDark: isDark,
                onTap: () {
                  appState.setThemeMode(ThemeMode.light);
                  Navigator.pop(ctx);
                },
              ),
              _buildModalOption(
                icon: Icons.dark_mode,
                title: 'Dark Theme',
                isSelected: appState.themeMode == ThemeMode.dark,
                isDark: isDark,
                onTap: () {
                  appState.setThemeMode(ThemeMode.dark);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDefaultAvatar(AppState appState) {
    return CircleAvatar(
      backgroundColor: const Color(0xFF4F46E5),
      child: Text(
        appState.userInitial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
    );
  }

  void _showPhotoPicker(BuildContext context, AppState appState) {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = appState.isDarkMode;
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModalOption(
                icon: Icons.camera_alt_rounded,
                title: 'Take a photo',
                isDark: isDark,
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (file != null) {
                    await appState.setProfilePhotoPath(file.path);
                  }
                },
              ),
              _buildModalOption(
                icon: Icons.photo_library_rounded,
                title: 'Choose from gallery',
                isDark: isDark,
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (file != null) {
                    await appState.setProfilePhotoPath(file.path);
                  }
                },
              ),
              if (appState.profilePhotoPath != null)
                _buildModalOption(
                  icon: Icons.delete_outline_rounded,
                  title: 'Remove Photo',
                  isDanger: true,
                  isDark: isDark,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await appState.setProfilePhotoPath(null);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
