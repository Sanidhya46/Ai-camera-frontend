library;

/// Guidelines screen explaining passport/ID photo requirements before capture.
/// Displays country-specific photo standards with do's and don'ts for composition, lighting, attire, and appearance.
/// Allows users to select between different passport types (India, UK, etc.) before proceeding to camera.
/// Fully theme-aware — adapts to both dark and light modes dynamically.

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:provider/provider.dart';
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/core/services/api_service.dart';
import 'package:smart_shutter/core/theme.dart';
import 'package:smart_shutter/screens/passport/camera_screen.dart';
import 'package:smart_shutter/screens/passport/review_screen.dart';

class PassportGuidelinesScreen extends StatefulWidget {
  const PassportGuidelinesScreen({super.key});

  @override
  State<PassportGuidelinesScreen> createState() => _PassportGuidelinesScreenState();
}

class PassportOption {
  final String id;
  final String name;
  final String code;
  final String size;
  final String background;
  final String note;

  const PassportOption({
    required this.id,
    required this.name,
    required this.code,
    required this.size,
    required this.background,
    required this.note,
  });
}

class _PassportGuidelinesScreenState extends State<PassportGuidelinesScreen> {
  static const List<PassportOption> _options = [
    PassportOption(
      id: 'india',
      name: 'India Passport / OCI',
      code: 'IN',
      size: '2" x 2" (51mm x 51mm) or 35mm x 45mm',
      background: 'Plain white or light off-white',
      note: 'Face between 60%-70% of frame, ears clearly visible',
    ),
    PassportOption(
      id: 'uk',
      name: 'UK Passport',
      code: 'UK',
      size: '35mm x 45mm (Standard UK)',
      background: 'Plain cream or light grey',
      note: 'Head height 29mm-34mm, natural expression',
    ),
  ];

  String? _selectedPassportId;
  bool _showValidationError = false;

  PassportOption? get _currentOption {
    if (_selectedPassportId == null) return null;
    try {
      return _options.firstWhere((opt) => opt.id == _selectedPassportId);
    } catch (_) {
      return null;
    }
  }

  bool _validateSelection() {
    if (_selectedPassportId == null) {
      setState(() => _showValidationError = true);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Please select a passport option first before proceeding.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          duration: const Duration(seconds: 3),
        ),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().isDarkMode;
    final selected = _currentOption;

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
                        // Country dropdown selector (NO default - user must select first)
                        GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (ctx) => SafeArea(
                                child: SingleChildScrollView(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Center(
                                          child: Container(
                                            width: 40,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: isDark ? Colors.white24 : Colors.black12,
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Select Passport / Visa Standard',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Choose India or UK document requirements',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ..._options.map((opt) {
                                          final isSelected = _selectedPassportId == opt.id;
                                          return InkWell(
                                            onTap: () {
                                              Navigator.pop(ctx);
                                              setState(() {
                                                _selectedPassportId = opt.id;
                                                _showValidationError = false;
                                              });
                                            },
                                            borderRadius: BorderRadius.circular(12),
                                            child: Container(
                                              margin: const EdgeInsets.only(bottom: 10),
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? AppTheme.brand.withValues(alpha: 0.12)
                                                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? AppTheme.brand
                                                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                                  width: isSelected ? 1.5 : 1.0,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 38,
                                                    height: 38,
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                      color: isSelected
                                                          ? AppTheme.brand.withValues(alpha: 0.2)
                                                          : (isDark ? Colors.white12 : const Color(0xFFEEF2FF)),
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Text(
                                                      opt.code,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                        color: isSelected ? AppTheme.brand : (isDark ? Colors.white : const Color(0xFF4F46E5)),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          opt.name,
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.bold,
                                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          opt.size,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (isSelected)
                                                    const Icon(Icons.check_circle_rounded, color: AppTheme.brand, size: 20),
                                                ],
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _showValidationError
                                    ? const Color(0xFFEF4444)
                                    : (selected != null
                                        ? AppTheme.brand
                                        : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                                width: _showValidationError ? 2.0 : (selected != null ? 1.5 : 1.0),
                              ),
                              boxShadow: [
                                if (_showValidationError)
                                  BoxShadow(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                else
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _showValidationError
                                        ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                                        : (selected != null
                                            ? AppTheme.brand.withValues(alpha: 0.12)
                                            : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: selected != null
                                      ? Text(
                                          selected.code,
                                          style: const TextStyle(
                                            color: AppTheme.brand,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        )
                                      : Icon(
                                          Icons.badge_outlined,
                                          color: _showValidationError ? const Color(0xFFEF4444) : AppTheme.brand,
                                          size: 19,
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selected != null
                                            ? selected.name
                                            : 'Select Passport / ID Type',
                                        style: TextStyle(
                                          color: _showValidationError
                                              ? const Color(0xFFEF4444)
                                              : (selected != null
                                                  ? AppTheme.ink(isDark)
                                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _showValidationError
                                            ? 'Required: Tap here to select passport standard'
                                            : (selected != null ? selected.size : 'Choose country standard before proceeding'),
                                        style: TextStyle(
                                          color: _showValidationError
                                              ? const Color(0xFFEF4444)
                                              : AppTheme.muted(isDark),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down_circle_outlined,
                                  color: _showValidationError ? const Color(0xFFEF4444) : AppTheme.brand,
                                  size: 22,
                                ),
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
                        _buildRuleItem(
                          selected != null ? selected.background : 'Plain white or neutral background required',
                          true,
                          isDark,
                        ),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: selected != null
                                ? AppTheme.brand.withValues(alpha: 0.08)
                                : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected != null
                                  ? AppTheme.brand.withValues(alpha: 0.2)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                selected != null
                                    ? 'Standard Size: ${selected.size}'
                                    : 'Please select a passport option above to view specifications',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: selected != null ? AppTheme.ink(isDark) : AppTheme.muted(isDark),
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (selected != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  selected.note,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.muted(isDark),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                // ── Option 1: Take Photo with Camera ──
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Container(
                    decoration: AppTheme.brandGradientDecoration,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (!_validateSelection()) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const PassportCameraScreen()),
                        );
                      },
                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      label: const Text(
                        'Take Photo with Camera',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Option 2: Upload from Gallery ──
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (!_validateSelection()) return;
                      _handleUploadFromGallery(context);
                    },
                    icon: const Icon(Icons.photo_library_outlined, color: AppTheme.brand, size: 20),
                    label: Text(
                      'Upload from Gallery',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.ink(isDark),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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

  Future<void> _handleUploadFromGallery(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final apiService = ApiService();

    // Show loading modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: appState.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.brand),
              const SizedBox(height: 16),
              Text(
                'Analyzing biometric compliance...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ink(appState.isDarkMode),
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final uploadRes = kIsWeb
          ? await apiService.uploadPhoto(picked.path, bytes: await picked.readAsBytes())
          : await apiService.uploadPhoto(picked.path);

      final String sessionId = uploadRes['session_id'] ?? '';
      final bool isCompliant = uploadRes['is_compliant'] ?? false;
      final report = (uploadRes['compliance_report'] as Map<String, dynamic>?) ?? {};

      if (mounted) Navigator.pop(context); // Close loading dialog

      if (isCompliant && sessionId.isNotEmpty) {
        final generateRes = await apiService.generatePassportPhoto(sessionId);
        final String photoId = generateRes['photo_id'] ?? '';

        String finalPath = picked.path;
        if (photoId.isNotEmpty) {
          if (kIsWeb) {
            finalPath = '${apiService.baseUrl}/download/$photoId';
          } else {
            final photoBytes = await apiService.downloadPhoto(photoId);
            if (photoBytes != null) {
              final directory = await getApplicationDocumentsDirectory();
              finalPath = '${directory.path}/passport_$photoId.jpg';
              final file = File(finalPath);
              await file.writeAsBytes(photoBytes);
              try {
                await ImageGallerySaverPlus.saveFile(finalPath);
              } catch (_) {}
            }
          }
        }

        await appState.addCapture(
          path: finalPath,
          type: 'passport',
          isCompliant: true,
          complianceReport: report,
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PassportReviewScreen(imagePath: finalPath, report: report),
            ),
          );
        }
      } else {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PassportReviewScreen(imagePath: picked.path, report: report),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close dialog if still open
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PassportReviewScreen(imagePath: picked.path, report: const {}),
          ),
        );
      }
    }
  }

  Widget _buildSectionHeader(IconData icon, String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.brand.withValues(alpha: 0.12),
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
