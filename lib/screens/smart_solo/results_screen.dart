/// Results screen displaying captured Smart Solo mode photos with AI selection.
/// Shows the best shots chosen by AI from the capture session with preview and action buttons.
/// Provides options to save to gallery, use for passport photo generation, or continue capturing.
/// Final workflow screen in Smart Solo mode that allows users to manage and process their aesthetic shots.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:smart_shutter/core/theme.dart';
import 'package:smart_shutter/screens/main_layout.dart';

class ResultsScreen extends StatelessWidget {
  final String imagePath;

  const ResultsScreen({
    super.key,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Best Shots', style: TextStyle(fontSize: 18, color: AppTheme.ink, fontWeight: FontWeight.bold)),
            Text('AI-selected results', style: TextStyle(fontSize: 12, color: AppTheme.muted.withOpacity(0.9))),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.ink),
      ),
      body: Container(
        decoration: AppTheme.gradientBg,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Best Shot Preview
                Expanded(
                  child: Container(
                    decoration: AppTheme.glassmorphicDecoration,
                    clipBehavior: Clip.antiAlias,
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: imagePath.isNotEmpty
                            ? ((kIsWeb || imagePath.startsWith('http') || imagePath.startsWith('blob:'))
                                ? Image.network(
                                    imagePath,
                                    fit: BoxFit.cover,
                                  )
                                : File(imagePath).existsSync()
                                    ? Image.file(
                                        File(imagePath),
                                        fit: BoxFit.cover,
                                      )
                                    : const Center(child: Text('No Preview Available')))
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [AppTheme.brand.withOpacity(0.07), AppTheme.brand2.withOpacity(0.07)],
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.photo_library_outlined, size: 48, color: AppTheme.muted),
                                    SizedBox(height: 12),
                                    Text('Best shot preview', style: TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // AI tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChip('Best light'),
                    _buildChip('Best pose'),
                    _buildChip('Sharpest image'),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Thumbnail grid of alternatives
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildThumb('Alt 1'),
                    _buildThumb('Alt 2'),
                    _buildThumb('Alt 3'),
                  ],
                ),
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Retake'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.brand.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const MainLayout()),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Save / Share', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.brand.withOpacity(0.12),
        border: Border.all(color: AppTheme.brand.withOpacity(0.4), width: 1.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppTheme.brand, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildThumb(String label) {
    return Container(
      width: 90,
      height: 110,
      decoration: AppTheme.glassmorphicCustom(radius: 14),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF9AA4B2), fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

