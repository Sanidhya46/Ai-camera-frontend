/// Premium paywall screen for Smart Solo mode subscription.
/// Displays feature benefits, pricing information, and handles premium subscription activation.
/// Shows free trial details ($4.99/month after 7-day trial) and allows users to unlock premium features or dismiss.
/// Entry point for monetization, guiding users to subscribe for AI-powered aesthetic photo capture capabilities.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/core/theme.dart';
import 'package:smart_shutter/screens/smart_solo/setup_screen.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().isDarkMode;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Unlock Smart Solo', style: TextStyle(fontSize: 18, color: AppTheme.ink(isDark), fontWeight: FontWeight.bold)),
            Text('Your Personal AI Photographer', style: TextStyle(fontSize: 12, color: AppTheme.muted(isDark).withOpacity(0.9))),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.ink(isDark)),
      ),
      body: Container(
        decoration: AppTheme.gradientBg(isDark),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Promotion Header Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    border: Border.all(color: AppTheme.brand.withOpacity(0.35), width: 1.5),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.brand.withOpacity(0.12),
                        blurRadius: 24,
                      )
                    ],
                  ),
                  child: const Text('✨', style: TextStyle(fontSize: 44)),
                ),
                const SizedBox(height: 20),
                
                // Benefits glass card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.glassmorphicDecoration(isDark),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Solo Premium Includes:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.ink(isDark)),
                      ),
                      const SizedBox(height: 14),
                      _buildBenefitRow(Icons.psychology_outlined, 'Tailored AI shoot plans & pose guides', isDark),
                      const SizedBox(height: 10),
                      _buildBenefitRow(Icons.voice_chat_outlined, 'Real-time speak and voice coaching', isDark),
                      const SizedBox(height: 10),
                      _buildBenefitRow(Icons.center_focus_strong_outlined, 'Aesthetic-driven automatic self-capture', isDark),
                      const SizedBox(height: 10),
                      _buildBenefitRow(Icons.star_outline, 'Quality-aware best shot rankings', isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Dynamic pricing card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: AppTheme.glassmorphicCustom(
                    radius: 20,
                    isDark: isDark,
                    borderColor: AppTheme.brand2.withOpacity(0.35),
                  ),
                  width: double.infinity,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.brand2.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.workspace_premium, color: AppTheme.brand2),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Try SmartSolo PRO',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.ink(isDark)),
                            ),
                            Text(
                              'Start your 7-day free trial, then \$4.99/mo',
                              style: TextStyle(color: AppTheme.muted(isDark).withOpacity(0.9), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Maybe later'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.brand.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            await context.read<AppState>().setPremium(true);
                            if (context.mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const SmartSetupScreen()),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Unlock Now', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.brand, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: AppTheme.ink(isDark), fontSize: 13, height: 1.3, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

