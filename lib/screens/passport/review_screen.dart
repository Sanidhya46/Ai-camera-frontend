/// Review and export screen showing captured passport photo with compliance report.
/// Displays the captured image, compliance status (compliant/non-compliant), detailed analysis report, and export/share options.
/// Allows users to download the photo, share it, or retake the photo if it fails compliance checks.
/// Final step in passport mode workflow before saving to gallery and returning to main app.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:typed_data';
import 'package:smart_shutter/core/theme.dart';
import 'package:smart_shutter/screens/main_layout.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_saver/file_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_shutter/screens/passport/camera_screen.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

class PassportReviewScreen extends StatefulWidget {
  final String imagePath;
  final Map<String, dynamic> report;

  const PassportReviewScreen({
    super.key,
    required this.imagePath,
    required this.report,
  });

  @override
  State<PassportReviewScreen> createState() => _PassportReviewScreenState();
}

class _PassportReviewScreenState extends State<PassportReviewScreen> {
  bool _isExporting = false;

  Future<void> _exportFile() async {
    setState(() => _isExporting = true);
    
    try {
      // Request storage permission
      PermissionStatus status;
      if (kIsWeb) {
        status = PermissionStatus.granted;
      } else if (Platform.isAndroid) {
        status = await Permission.storage.request();
      } else if (Platform.isIOS) {
        status = await Permission.photos.request();
      } else {
        status = PermissionStatus.granted;
      }

      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Storage permission denied'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
        setState(() => _isExporting = false);
        return;
      }

      Uint8List? bytes;
      if (kIsWeb || widget.imagePath.startsWith('http') || widget.imagePath.startsWith('blob:')) {
        final response = await http.get(Uri.parse(widget.imagePath));
        bytes = response.bodyBytes;
      } else {
        if (File(widget.imagePath).existsSync()) {
          bytes = await File(widget.imagePath).readAsBytes();
        }
      }

      if (bytes != null) {
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          // Save to gallery using image_gallery_saver
          final result = await ImageGallerySaverPlus.saveImage(
            bytes,
            quality: 100,
            name: 'passport_photo_${DateTime.now().millisecondsSinceEpoch}',
          );

          if (result['isSuccess'] == true) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppTheme.ok, shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('Photo saved to Gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ],
                  ),
                  backgroundColor: AppTheme.brand.withOpacity(0.9),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: const BorderSide(color: Colors.black, width: 1.5),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  elevation: 10,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          } else {
            throw Exception('Failed to save to gallery');
          }
        } else if (kIsWeb) {
          // Web: Download
          await FileSaver.instance.saveFile(
            name: 'passport_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
            bytes: bytes,
            mimeType: MimeType.jpeg,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppTheme.ok, shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Photo downloaded', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ],
                ),
                backgroundColor: AppTheme.brand.withOpacity(0.9),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: Colors.black, width: 1.5),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                elevation: 10,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Read compliance parameters
    final bool isFaceCentered = widget.report['face_centred_ok'] ?? true;
    final bool isBgAcceptable = widget.report['lighting_ok'] ?? true; // Lighting ok maps to bg
    final bool isHeadPoseOk = widget.report['head_pose_ok'] ?? true;
    final bool isEyesOpen = widget.report['eyes_open_ok'] ?? true;
    final bool isMouthClosed = widget.report['mouth_closed_ok'] ?? true;
    final bool isNaturalExp = widget.report['natural_expression_ok'] ?? true;
    
    final bool allCriteriaMet = isFaceCentered && isBgAcceptable && isHeadPoseOk && isEyesOpen && isMouthClosed && isNaturalExp;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Review ID Photo', style: TextStyle(fontSize: 18, color: AppTheme.ink, fontWeight: FontWeight.bold)),
            Text(
              widget.report.containsKey('error') ? 'Review guidelines' : 'Compliance result',
              style: TextStyle(fontSize: 12, color: AppTheme.muted.withOpacity(0.9)),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.ink),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AppTheme.ink),
            onPressed: _isExporting ? null : _exportFile,
            tooltip: 'Download photo',
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBg,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Cropped Image preview
                Expanded(
                  child: Container(
                    decoration: AppTheme.glassmorphicDecoration,
                    clipBehavior: Clip.antiAlias,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1.0, // 2x2 inch square
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: (kIsWeb || widget.imagePath.startsWith('http') || widget.imagePath.startsWith('blob:'))
                              ? Image.network(
                                  widget.imagePath,
                                  fit: BoxFit.cover,
                                )
                              : File(widget.imagePath).existsSync()
                                  ? Image.file(
                                      File(widget.imagePath),
                                      fit: BoxFit.cover,
                                    )
                                  : const Center(child: Text('No Preview Available')),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Checklist
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildCheckRow('Face Centering & Position', isFaceCentered, errorGuide: 'Ensure you are facing forward and your head is centered.'),
                        _buildCheckRow('Even Studio Lighting', isBgAcceptable, errorGuide: 'Uneven Studio Lighting detected. Make sure the lighting is even and there are no shadows.'),
                        _buildCheckRow('Direct Eye Contact', isHeadPoseOk && isEyesOpen, errorGuide: 'Look directly at the camera with eyes open.'),
                        _buildCheckRow('Neutral Expression & Mouth Closed', isMouthClosed && isNaturalExp, errorGuide: 'Maintain a natural expression and keep your mouth closed.'),
                        const SizedBox(height: 10),

                        if (allCriteriaMet)
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.ok.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.ok.withOpacity(0.5)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.verified, color: AppTheme.ok),
                                SizedBox(width: 8),
                                Text('All criteria verified', style: TextStyle(color: AppTheme.ok, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const PassportCameraScreen()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Retake'),
                      ),
                    ),
                    if (allCriteriaMet) ...[
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
                            onPressed: _isExporting ? null : () async {
                              await _exportFile();
                              if (mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (_) => const MainLayout()),
                                  (route) => false,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isExporting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : const Text('Save / Export', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckRow(String label, bool isOk, {String? errorGuide}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppTheme.glassmorphicDecoration,
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.ink),
                ),
              ),
              isOk
                  ? const Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.ok, size: 20),
                        SizedBox(width: 4),
                        Text('Pass', style: TextStyle(color: AppTheme.ok, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    )
                  : const Row(
                      children: [
                        Icon(Icons.cancel, color: AppTheme.danger, size: 20),
                        SizedBox(width: 4),
                        Text('Fail', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
            ],
          ),
          if (!isOk && errorGuide != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                errorGuide,
                style: TextStyle(fontSize: 12, color: AppTheme.danger.withOpacity(0.9)),
              ),
            ),
        ],
      ),
    );
  }
}

