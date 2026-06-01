import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/core/theme.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<AppState>().isPremium;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('Settings and subscription', style: TextStyle(fontSize: 12, color: AppTheme.muted)),
          const SizedBox(height: 16),
          
          _buildCheckRow('Subscription', isPremium ? 'Premium Active' : 'Free User'),
          const SizedBox(height: 12),
          _buildCheckRow('Voice guidance', 'On'),
          const SizedBox(height: 12),
          _buildCheckRow('Default passport country', 'India'),
          const SizedBox(height: 12),
          _buildCheckRow('Privacy & help', 'Open'),
        ],
      ),
    );
  }

  Widget _buildCheckRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(value, style: const TextStyle(fontSize: 13, color: AppTheme.muted)),
        ],
      ),
    );
  }
}
