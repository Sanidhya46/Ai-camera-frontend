import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'dart:io';
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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SmartShutter',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.ink),
                  ),
                  Text(
                    'Choose how you want to shoot today',
                    style: TextStyle(fontSize: 13, color: AppTheme.muted.withOpacity(0.9)),
                  ),
                ],
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
          const SizedBox(height: 24),
          
          _buildModeCard(
            title: 'Passport / ID Photo',
            subtitle: 'Free mode · Take compliant photos at home',
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.brand),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PassportGuidelinesScreen()));
            },
          ),
          const SizedBox(height: 14),
          
          _buildModeCard(
            title: 'Smart Solo Mode',
            subtitle: isPremium ? 'Premium active · AI-guided aesthetic capture' : 'Premium mode · AI-guided aesthetic capture',
            trailing: Icon(Icons.arrow_forward_ios, size: 14, color: isPremium ? AppTheme.ok : AppTheme.brand2),
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
            decoration: AppTheme.glassmorphicDecoration,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent captures',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.ink),
                ),
                const SizedBox(height: 14),
                if (recentCaptures.isEmpty)
                  Container(
                    height: 110,
                    alignment: Alignment.center,
                    child: Text(
                      'No recent photos yet. Start capturing!',
                      style: TextStyle(color: AppTheme.muted.withOpacity(0.8), fontSize: 13),
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: recentCaptures.map((cap) {
                      final path = cap['path'] as String;
                      final type = cap['type'] as String;
                      return _buildThumb(path, type == 'passport' ? 'ID' : 'Solo');
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: AppTheme.glassmorphicDecoration,
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.ink),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: AppTheme.muted.withOpacity(0.9), fontSize: 13),
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

  Widget _buildThumb(String path, String label) {
    final isUrlOrBlob = kIsWeb || path.startsWith('http') || path.startsWith('blob:');
    final exists = isUrlOrBlob || File(path).existsSync();

    return Container(
      width: 80,
      height: 110,
      decoration: AppTheme.glassmorphicCustom(radius: 14),
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
                  : Image.file(
                      File(path),
                      fit: BoxFit.cover,
                    ),
            )
          else
            const Center(
              child: Icon(Icons.broken_image_outlined, color: AppTheme.muted, size: 20),
            ),
          Container(
            width: double.infinity,
            color: Colors.black54,
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

