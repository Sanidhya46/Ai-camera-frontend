import 'package:flutter/material.dart';
import 'package:smart_shutter/core/theme.dart';

class GalleryTab extends StatelessWidget {
  const GalleryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gallery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('Past outputs and sessions', style: TextStyle(fontSize: 12, color: AppTheme.muted)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildChip('Passport', true),
              const SizedBox(width: 8),
              _buildChip('Smart Solo', false),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1 / 1.25,
              children: [
                _buildThumb('ID 1'),
                _buildThumb('ID 2'),
                _buildThumb('Solo 1'),
                _buildThumb('Solo 2'),
                _buildThumb('Solo 3'),
                _buildThumb('More'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.brand.withOpacity(0.1) : Colors.white,
        border: Border.all(color: isActive ? AppTheme.brand.withOpacity(0.35) : AppTheme.line),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label, 
        style: TextStyle(
          fontSize: 12, 
          color: isActive ? AppTheme.brand : AppTheme.ink,
        ),
      ),
    );
  }

  Widget _buildThumb(String label) {
    return Container(
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
