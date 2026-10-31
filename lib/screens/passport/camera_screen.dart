/// Live camera capture screen for passport/ID photo mode.
/// Displays real-time camera feed with a guide overlay for face alignment, captures photos, and sends them to backend for compliance analysis.
/// Features auto-capture mode, manual capture, compliance feedback, and transitions to review screen after capture.
/// Handles camera initialization, permissions, and integration with the API service for biometric analysis.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:smart_shutter/core/services/api_service.dart';
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/core/theme.dart';
import 'package:smart_shutter/screens/passport/review_screen.dart';

class PassportCameraScreen extends StatefulWidget {
  const PassportCameraScreen({super.key});

  @override
  State<PassportCameraScreen> createState() => _PassportCameraScreenState();
}

class _PassportCameraScreenState extends State<PassportCameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = -1;
  bool _isReady = false;
  bool _isProcessing = false;
  bool _isAutoMode = false;
  int _loadingStep = 1;
  String _hintText = 'Align your face perfectly inside the guide overlay';
  Map<String, dynamic> _lastComplianceReport = {};
  Timer? _guideTimer;
  bool _showGuide = true;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initCamera();
    _guideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showGuide = false);
    });
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required')),
        );
      }
      return;
    }

    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      if (_selectedCameraIndex == -1) {
        _selectedCameraIndex = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
        if (_selectedCameraIndex == -1) _selectedCameraIndex = 0;
      }
      _controller = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _controller?.initialize();
      if (mounted) {
        setState(() {
          _isReady = true;
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    setState(() {
      _isReady = false;
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    });
    await _controller?.dispose();
    _controller = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _controller?.initialize();
    if (mounted) {
      setState(() {
        _isReady = true;
      });
    }
  }

  @override
  void dispose() {
    _guideTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureAndCheck() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessing)
      return;

    setState(() {
      _isProcessing = true;
      _loadingStep = 1;
      _hintText = 'Analyzing face and background... Hold still!';
    });

    try {
      // 1. Take photo
      final XFile rawPhoto = await _controller!.takePicture();

      // Start the loading animation future
      final loadingStepsFuture = () async {
        setState(() {
          _loadingStep = 1;
        });
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted || !_isProcessing) return;
        setState(() {
          _loadingStep = 2;
        });
        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted || !_isProcessing) return;
        setState(() {
          _loadingStep = 3;
        });
        await Future.delayed(const Duration(milliseconds: 1500));
      }();

      // 2. Upload photo to compliance checker
      final uploadFuture = () async {
        if (kIsWeb) {
          final bytes = await rawPhoto.readAsBytes();
          return await _apiService.uploadPhoto(rawPhoto.path, bytes: bytes);
        } else {
          return await _apiService.uploadPhoto(rawPhoto.path);
        }
      }();

      await Future.wait([loadingStepsFuture, uploadFuture]);
      Map<String, dynamic> uploadRes = await uploadFuture;

      final String sessionId = uploadRes['session_id'] ?? '';
      final bool isCompliant = uploadRes['is_compliant'] ?? false;
      final report = uploadRes['compliance_report'] ?? {};

      setState(() {
        _lastComplianceReport = report;
      });

      if (isCompliant && sessionId.isNotEmpty) {
        setState(() {
          _hintText = 'Compliance passed! Generating passport photo...';
        });

        // 3. Generate cropped white-bg passport photo
        final generateRes = await _apiService.generatePassportPhoto(sessionId);
        final String photoId = generateRes['photo_id'] ?? '';

        if (photoId.isNotEmpty) {
          // 4. Handle persistence based on platform
          String localPath;
          if (kIsWeb) {
            localPath = '${_apiService.baseUrl}/download/$photoId';

            // Add to AppState history
            final appState = Provider.of<AppState>(context, listen: false);
            await appState.addCapture(
              path: localPath,
              type: 'passport',
              isCompliant: true,
              complianceReport: report,
            );

            setState(() {
              _isProcessing = false;
              _hintText = 'Success!';
            });

            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => PassportReviewScreen(
                    imagePath: localPath,
                    report: report,
                  ),
                ),
              );
            }
            return;
          } else {
            // Mobile: Download final photo
            final Uint8List? photoBytes = await _apiService.downloadPhoto(
              photoId,
            );
            if (photoBytes != null && mounted) {
              // Save to local documents directory for persistence
              final directory = await getApplicationDocumentsDirectory();
              localPath = '${directory.path}/passport_$photoId.jpg';
              final file = File(localPath);
              await file.writeAsBytes(photoBytes);

              try {
                await ImageGallerySaverPlus.saveFile(localPath);
              } catch (e) {
                debugPrint('Failed to save to gallery: $e');
              }

              // Add to AppState history
              final appState = Provider.of<AppState>(context, listen: false);
              await appState.addCapture(
                path: localPath,
                type: 'passport',
                isCompliant: true,
                complianceReport: report,
              );

              setState(() {
                _isProcessing = false;
                _hintText = 'Success!';
              });

              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PassportReviewScreen(
                      imagePath: localPath,
                      report: report,
                    ),
                  ),
                );
              }
              return;
            }
          }
        }

        setState(() {
          _hintText = 'Could not generate photo. Please try again.';
        });
      } else {
        setState(() {
          _isProcessing = false;
        });

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PassportReviewScreen(
                imagePath: rawPhoto.path,
                report: report,
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _hintText = 'Error during capture: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: Column(
        children: [
          // Top 11%
          Expanded(
            flex: 11,
            child: Container(
              color: isDark ? AppTheme.surface(isDark) : Colors.white,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: AppTheme.ink(isDark)),
                          onPressed: _isProcessing ? null : () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Passport Capture',
                                style: TextStyle(fontSize: 18, color: AppTheme.ink(isDark), fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Align face inside the guide',
                                style: TextStyle(fontSize: 12, color: AppTheme.muted(isDark)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Middle 73%
          Expanded(
            flex: 73,
            child: Stack(
              children: [
                if (_isReady && _controller != null)
                  Positioned.fill(
                    child: ClipRect(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          var cameraRatio = _controller!.value.aspectRatio;
                          var containerRatio = constraints.maxWidth / constraints.maxHeight;
                          
                          if (containerRatio < 1 && cameraRatio > 1) {
                            cameraRatio = 1 / cameraRatio;
                          } else if (containerRatio > 1 && cameraRatio < 1) {
                            cameraRatio = 1 / cameraRatio;
                          }

                          double scale = containerRatio / cameraRatio;
                          if (scale < 1.0) {
                            scale = 1.0 / scale;
                          }

                          return Transform.scale(
                            scale: scale,
                            child: Center(
                              child: CameraPreview(_controller!),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  const Center(
                    child: CircularProgressIndicator(color: AppTheme.brand),
                  ),
                
                Positioned.fill(
                  child: CustomPaint(painter: PassportGuidePainter()),
                ),

                if (_showGuide)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.info_outline, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _hintText,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_isProcessing) _buildProcessingOverlay(isDark),
              ],
            ),
          ),

          // Bottom 16%
          Expanded(
            flex: 16,
            child: Container(
              width: double.infinity,
              color: isDark ? AppTheme.surface(isDark) : Colors.white,
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Recent Photo Thumbnail (left side)
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 32),
                          child: Consumer<AppState>(
                            builder: (context, appState, child) {
                              final recentCaptures = appState.captures.where((c) => c['type'] == 'passport').toList();
                              final recentPhoto = recentCaptures.isNotEmpty ? recentCaptures.last['path'] as String : null;
                              return GestureDetector(
                                onTap: () {},
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppTheme.brand.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.ink(isDark), width: 1.5),
                                    image: recentPhoto != null
                                        ? DecorationImage(
                                            image: (kIsWeb || recentPhoto.startsWith('http') || recentPhoto.startsWith('blob:'))
                                                ? NetworkImage(recentPhoto)
                                                : FileImage(File(recentPhoto)) as ImageProvider,
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: recentPhoto == null
                                      ? const Icon(Icons.photo_library_outlined, color: Colors.white, size: 20)
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // Capture Button (center)
                    GestureDetector(
                      onTap: _isProcessing ? null : _captureAndCheck,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isProcessing ? Colors.grey : null,
                          gradient: _isProcessing ? null : const LinearGradient(colors: [AppTheme.brand, AppTheme.brand2]),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                      ),
                    ),

                    // Flip Camera Button (right side mirror of left)
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 32),
                          child: GestureDetector(
                            onTap: _isProcessing ? null : _switchCamera,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.flip_camera_ios, color: AppTheme.ink(isDark), size: 24),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingOverlay(bool isDark) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.65),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 36),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      color: AppTheme.brand,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Analyzing Passport Photo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.ink(isDark),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _loadingStep == 1
                        ? 'Verifying face position & frame...'
                        : _loadingStep == 2
                            ? 'Checking lighting & background...'
                            : 'Finalizing compliance check...',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.muted(isDark),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PassportGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintBg = Paint()
      ..color = Colors.black.withOpacity(0.42)
      ..style = PaintingStyle.fill;

    final paintLine = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    // Outer path
    final pathOuter = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Face Oval
    final ovalWidth = size.width * 0.54;
    final ovalHeight = size.height * 0.44;
    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.44),
      width: ovalWidth,
      height: ovalHeight,
    );
    final pathOval = Path()..addOval(ovalRect);

    // Subtract oval from bg
    final pathBg = Path.combine(PathOperation.difference, pathOuter, pathOval);
    canvas.drawPath(pathBg, paintBg);

    // Draw the clean, distraction-free oval boundary
    canvas.drawOval(ovalRect, paintLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
