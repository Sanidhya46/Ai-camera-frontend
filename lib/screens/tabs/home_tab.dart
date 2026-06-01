import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/core/theme.dart';
import 'package:smart_shutter/screens/passport/guidelines_screen.dart';
import 'package:smart_shutter/screens/smart_solo/paywall_screen.dart';
import 'package:smart_shutter/screens/smart_solo/setup_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<AppState>().isPremium;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SmartShutter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('Choose how you want to shoot today', style: TextStyle(fontSize: 12, color: AppTheme.muted)),
          const SizedBox(height: 20),
          
          _buildModeCard(
            title: 'Passport / ID Photo',
            subtitle: 'Free mode · Take compliant photos at home',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PassportGuidelinesScreen()));
            },
          ),
          const SizedBox(height: 12),
          
          _buildModeCard(
            title: 'Smart Solo Mode ${isPremium ? '✅' : '⭐'}',
            subtitle: isPremium ? 'Premium active · AI-guided aesthetic capture' : 'Premium mode · AI-guided aesthetic capture',
            onTap: () {
              if (isPremium) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartSetupScreen()));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
              }
            },
          ),
          
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.line),
              borderRadius: BorderRadius.circular(18),
            ),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recent captures', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildThumb('ID'),
                    _buildThumb('Solo'),
                    _buildThumb('More'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.line),
          borderRadius: BorderRadius.circular(20),
        ),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildThumb(String label) {
    return Container(
      width: 70,
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFF),
        border: Border.all(color: const Color(0xFFC9D2E3), style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(label, style: const TextStyle(color: Color(0xFF9AA4B2), fontSize: 12)),
    );
  }
}
