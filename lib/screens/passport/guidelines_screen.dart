import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Passport / ID Photo',
              style: TextStyle(fontSize: 18, color: AppTheme.ink, fontWeight: FontWeight.bold),
            ),
            Text(
              'Prepare before opening camera',
              style: TextStyle(fontSize: 12, color: AppTheme.muted.withOpacity(0.9)),
            ),
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
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Country dropdown selector
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: AppTheme.glassmorphicDecoration,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCountry,
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down, color: AppTheme.brand),
                              style: const TextStyle(color: AppTheme.ink, fontSize: 14, fontWeight: FontWeight.w600),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedCountry = newValue;
                                  });
                                }
                              },
                              items: <String>[
                                'India Passport',
                                'UK Passport',
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        
                        // Guidelines list
                        _buildSectionHeader(Icons.camera_alt_outlined, 'Composition & Pose'),
                        _buildRuleItem('Full frontal view, head centered', true),
                        _buildRuleItem('Eyes open, level and clearly visible', true),
                        _buildRuleItem('Natural expression, mouth closed', true),
                        _buildRuleItem('No tilting or turning of the head', false),
                        
                        _buildSectionHeader(Icons.lightbulb_outline, 'Lighting & Background'),
                        _buildRuleItem('Plain white background only', true),
                        _buildRuleItem('Even lighting on face & background', true),
                        _buildRuleItem('No uneven studio lighting or shadows', false),
                        _buildRuleItem('No over or under-exposure', false),
                        
                        _buildSectionHeader(Icons.color_lens_outlined, 'Attire & Appearance'),
                        _buildRuleItem('Wear colored attire (e.g., medium blue)', true),
                        _buildRuleItem('No pure white or patterned clothing', false),
                        _buildRuleItem('No head coverings (except religious)', false),
                        _buildRuleItem('No hair across eyes', false),
                        
                        _buildSectionHeader(Icons.face_retouching_natural, 'Eyeglasses'),
                        _buildRuleItem('Eyes must be fully visible', true),
                        _buildRuleItem('No tinted or dark lenses', false),
                        _buildRuleItem('No glare or reflections on lenses', false),
                        
                        const SizedBox(height: 24),
                        Text(
                          'Standard Size: 2" x 2" (51mm x 51mm)',
                          style: TextStyle(fontSize: 13, color: AppTheme.muted.withOpacity(0.9), fontWeight: FontWeight.w500),
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
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.brand.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const PassportCameraScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('I Understand', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildSectionHeader(IconData icon, String title) {
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
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.ink)),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String text, bool isCheck) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isCheck ? Icons.check_circle : Icons.do_not_disturb_alt, 
               color: isCheck ? AppTheme.brand : AppTheme.danger, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14, color: AppTheme.ink, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

