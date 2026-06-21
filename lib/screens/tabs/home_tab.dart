/// Home tab displaying available capture modes and recent photos.
/// Shows entry points for Passport/ID Photo mode (free) and Smart Solo Mode (premium).
/// Displays recent captures as thumbnails and indicates premium status if user has an active subscription.
/// Acts as the main hub where users choose their shooting mode and quickly access recent work.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'dart:io' show File;
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/core/theme.dart';
import 'package:smart_shutter/screens/passport/guidelines_screen.dart';
import 'package:smart_shutter/screens/smart_solo/paywall_screen.dart';
import 'package:smart_shutter/screens/smart_solo/setup_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isPremium = appState.isPremium;
    final recentCaptures = appState.captures.take(3).toList();
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Shutter',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? AppTheme.ink(isDark) : Colors.black87),
                    ),
                    Text(
                      'Choose how you want to shoot today',
                      style: TextStyle(fontSize: 12, color: isDark ? AppTheme.muted(isDark) : Colors.black54),
                    ),
                  ],
                ),
              ),
              if (isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.brand.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.brand.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(color: AppTheme.brand, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
          
          _buildModeCard(
            title: 'Passport / ID Photo',
            subtitle: 'Free mode · Take compliant photos at home',
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.brand),
            isDark: isDark,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PassportGuidelinesScreen()));
            },
          ),
          const SizedBox(height: 14),
          
          _buildModeCard(
            title: 'Smart Solo Mode',
            subtitle: isPremium ? 'Premium active · AI-guided aesthetic capture' : 'Premium mode · AI-guided aesthetic capture',
            trailing: Icon(Icons.arrow_forward_ios, size: 14, color: isPremium ? AppTheme.ok : AppTheme.brand2),
            isDark: isDark,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Coming Soon'),
                  content: const Text('Smart Solo Mode is currently under development and will be available in a future update!'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK', style: TextStyle(color: AppTheme.brand)),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: AppTheme.glassmorphicDecoration(isDark),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent captures',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.ink(isDark)),
                ),
                const SizedBox(height: 14),
                if (recentCaptures.isEmpty)
                  Container(
                    height: 110,
                    alignment: Alignment.center,
                    child: Text(
                      'No recent photos yet. Start capturing!',
                      style: TextStyle(color: AppTheme.muted(isDark), fontSize: 13),
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: recentCaptures.map((cap) {
                      final path = cap['path'] as String;
                      return GestureDetector(
                        onTap: () {
                          context.read<AppState>().setTabIndex(1); // Switch to Gallery tab
                        },
                        child: _buildThumb(path, isDark),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required Widget trailing,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: AppTheme.glassmorphicDecoration(isDark),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.ink(isDark)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: AppTheme.muted(isDark), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumb(String path, bool isDark) {
    final isUrlOrBlob = kIsWeb || path.startsWith('http') || path.startsWith('blob:');
    final bool exists;
    
    if (kIsWeb) {
      exists = isUrlOrBlob;
    } else {
      exists = isUrlOrBlob || File(path).existsSync();
    }

    return Container(
      width: 80,
      height: 110,
      decoration: AppTheme.glassmorphicCustom(radius: 14, isDark: isDark),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          if (exists)
            Positioned.fill(
              child: isUrlOrBlob
                  ? Image.network(
                      path,
                      fit: BoxFit.cover,
                    )
                  : kIsWeb
                      ? Image.network(path, fit: BoxFit.cover)
                      : Image.file(
                          File(path),
                          fit: BoxFit.cover,
                        ),
            )
          else
            Center(
              child: Icon(Icons.broken_image_outlined, color: AppTheme.muted(isDark), size: 20),
            ),
        ],
      ),
    );
  }
}

