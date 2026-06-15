/// Profile tab displaying user settings, subscription status, and app preferences.
/// Shows premium/free tier status with ability to toggle subscription, voice guidance mode, and passport specifications.
/// Displays security information and lets users manage their account preferences and app settings.
/// Serves as the control center for personalization and account management within SmartShutter.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/core/theme.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isPremium = appState.isPremium;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.ink)),
          Text('Settings and subscription preferences', style: TextStyle(fontSize: 13, color: AppTheme.muted.withOpacity(0.9))),
          const SizedBox(height: 24),
          
          _buildPreferencesCard(
            context,
            'Subscription Plan',
            isPremium ? 'Premium Active (PRO)' : 'Free Tier',
            isPremium ? AppTheme.ok : AppTheme.brand2,
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
            'Voice Guidance Mode',
            'On · Speaking instructions',
            AppTheme.ink,
            trailing: const Icon(Icons.volume_up, color: AppTheme.brand, size: 22),
          ),
          const SizedBox(height: 12),
          
          _buildPreferencesCard(
            context,
            'Default Passport Spec',
            'India · 2x2 inch 300 DPI',
            AppTheme.ink,
            trailing: const Icon(Icons.flag_outlined, color: AppTheme.brand, size: 22),
          ),
          const SizedBox(height: 12),
          
          _buildPreferencesCard(
            context,
            'Privacy & Data Security',
            '100% Secure Local Processing',
            AppTheme.ok,
            trailing: const Icon(Icons.shield_outlined, color: AppTheme.ok, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard(
    BuildContext context,
    String title,
    String value,
    Color valueColor, {
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: AppTheme.glassmorphicDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.ink),
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
    );
  }
}

