/// Guidelines screen explaining passport/ID photo requirements before capture.
/// Displays country-specific photo standards with do's and don'ts for composition, lighting, attire, and appearance.
/// Allows users to select between different passport types (India, UK, etc.) before proceeding to camera.
/// Fully theme-aware — adapts to both dark and light modes dynamically.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/core/theme.dart';
import 'package:smart_shutter/screens/passport/camera_screen.dart';

class PassportGuidelinesScreen extends StatefulWidget {
  const PassportGuidelinesScreen({super.key});

  @override
  State<PassportGuidelinesScreen> createState() => _PassportGuidelinesScreenState();
}

class _PassportGuidelinesScreenState extends State<PassportGuidelinesScreen> {
  String _selectedCountry = 'India Passport';

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Passport / ID Photo',
              style: TextStyle(fontSize: 18, color: AppTheme.ink(isDark), fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Prepare before opening camera',
              style: TextStyle(fontSize: 12, color: AppTheme.muted(isDark)),
              overflow: TextOverflow.ellipsis,
            ),
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
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Country dropdown selector
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: AppTheme.glassmorphicDecoration(isDark),
                          child: PopupMenuButton<String>(
                            initialValue: _selectedCountry,
                            offset: const Offset(0, 40),
                            onSelected: (String newValue) {
                              setState(() {
                                _selectedCountry = newValue;
                              });
                            },
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'India Passport',
                                child: Text('India Passport'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'UK Passport',
                                child: Text('UK Passport'),
                              ),
                            ],
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_selectedCountry, style: TextStyle(color: AppTheme.ink(isDark), fontSize: 14, fontWeight: FontWeight.w600)),
                                const Icon(Icons.arrow_drop_down, color: AppTheme.brand),
                              ],
                            ),
                          ),
                        ),
                        
                        // Guidelines list
                        _buildSectionHeader(Icons.camera_alt_outlined, 'Composition & Pose', isDark),
                        _buildRuleItem('Full frontal view, head centered', true, isDark),
                        _buildRuleItem('Eyes open, level and clearly visible', true, isDark),
                        _buildRuleItem('Natural expression, mouth closed', true, isDark),
                        _buildRuleItem('No tilting or turning of the head', false, isDark),
                        
                        _buildSectionHeader(Icons.lightbulb_outline, 'Lighting & Background', isDark),
                        _buildRuleItem('Plain white background only', true, isDark),
                        _buildRuleItem('Even lighting on face & background', true, isDark),
                        _buildRuleItem('No uneven studio lighting or shadows', false, isDark),
                        _buildRuleItem('No over or under-exposure', false, isDark),
                        
                        _buildSectionHeader(Icons.color_lens_outlined, 'Attire & Appearance', isDark),
                        _buildRuleItem('Wear colored attire (e.g., medium blue)', true, isDark),
                        _buildRuleItem('No pure white or patterned clothing', false, isDark),
                        _buildRuleItem('No head coverings (except religious)', false, isDark),
                        _buildRuleItem('No hair across eyes', false, isDark),
                        
                        _buildSectionHeader(Icons.face_retouching_natural, 'Eyeglasses', isDark),
                        _buildRuleItem('Eyes must be fully visible', true, isDark),
                        _buildRuleItem('No tinted or dark lenses', false, isDark),
                        _buildRuleItem('No glare or reflections on lenses', false, isDark),
                        
                        const SizedBox(height: 24),
                        Text(
                          'Standard Size: 2" x 2" (51mm x 51mm)',
                          style: TextStyle(fontSize: 13, color: AppTheme.muted(isDark), fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: Container(
                    decoration: AppTheme.brandGradientDecoration,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const PassportCameraScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('I Understand', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.brand.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.brand, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.ink(isDark)))),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String text, bool isCheck, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isCheck ? Icons.check_circle : Icons.do_not_disturb_alt, 
               color: isCheck ? AppTheme.brand : AppTheme.danger, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 14, color: AppTheme.ink(isDark), height: 1.4)),
          ),
        ],
      ),
    );
  }
}
