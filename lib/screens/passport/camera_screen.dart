import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
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
  bool _isReady = false;
  bool _isProcessing = false;
  bool _isAutoMode = false;
  String _hintText = 'Align your face perfectly inside the guide overlay';
  Map<String, dynamic> _lastComplianceReport = {};
  
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      final frontCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );
      _controller = CameraController(
        frontCamera, 
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

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureAndCheck() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _hintText = 'Analyzing face and background... Hold still!';
    });

    try {
      // 1. Take photo
      final XFile rawPhoto = await _controller!.takePicture();
      
      // 2. Upload photo to compliance checker
      Map<String, dynamic> uploadRes;
      if (kIsWeb) {
        final bytes = await rawPhoto.readAsBytes();
        uploadRes = await _apiService.uploadPhoto(rawPhoto.path, bytes: bytes);
      } else {
        uploadRes = await _apiService.uploadPhoto(rawPhoto.path);
      }
      
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
            final Uint8List? photoBytes = await _apiService.downloadPhoto(photoId);
            if (photoBytes != null && mounted) {
              // Save to local documents directory for persistence
              final directory = await getApplicationDocumentsDirectory();
              localPath = '${directory.path}/passport_$photoId.jpg';
              final file = File(localPath);
              await file.writeAsBytes(photoBytes);

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
    return Container(
      decoration: AppTheme.gradientBg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Passport Capture', style: TextStyle(fontSize: 18, color: AppTheme.ink, fontWeight: FontWeight.bold)),
              Text('Align face inside the guide', style: TextStyle(fontSize: 12, color: AppTheme.muted)),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppTheme.ink),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Camera Preview with Guide Overlay
                Expanded(
                  child: Container(
                    decoration: AppTheme.glassmorphicCustom(radius: 24),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isReady && _controller != null)
                          Positioned.fill(
                            child: AspectRatio(
                              aspectRatio: _controller!.value.aspectRatio,
                              child: CameraPreview(_controller!),
                            ),
                          )
                        else
                          const Center(child: CircularProgressIndicator(color: AppTheme.brand)),
                        
                        // Passport Oval & Shoulders Overlay
                        Positioned.fill(
                          child: CustomPaint(
                            painter: PassportGuidePainter(),
                          ),
                        ),

                        // Processing Spinner
                        if (_isProcessing)
                          Container(
                            color: Colors.black45,
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(color: Colors.white),
                                  SizedBox(height: 12),
                                  Text(
                                    'Running AI Checks...',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  )
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Status Box / Live Hints
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _hintText,
                          style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Control Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isProcessing ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _captureAndCheck,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Capture & Verify', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
}

class PassportGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintBg = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final paintLine = Paint()
      ..color = AppTheme.brand.withOpacity(0.7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final paintLineActive = Paint()
      ..color = AppTheme.brand2.withOpacity(0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Outer path
    final pathOuter = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Face Oval
    final ovalWidth = size.width * 0.52;
    final ovalHeight = size.height * 0.42;
    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.44),
      width: ovalWidth,
      height: ovalHeight,
    );
    final pathOval = Path()..addOval(ovalRect);

    // Subtract oval from bg
    final pathBg = Path.combine(PathOperation.difference, pathOuter, pathOval);
    canvas.drawPath(pathBg, paintBg);

    // Draw the oval ring
    canvas.drawOval(ovalRect, paintLine);

    // Draw centering reference lines
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.1),
      Offset(size.width / 2, size.height * 0.9),
      paintLineActive,
    );
    
    // Draw horizontal reference lines (Eyes region ~40% and Chin ~70%)
    canvas.drawLine(
      Offset(size.width / 2 - ovalWidth / 2, size.height * 0.4),
      Offset(size.width / 2 + ovalWidth / 2, size.height * 0.4),
      paintLineActive,
    );
    
    canvas.drawLine(
      Offset(size.width / 2 - ovalWidth / 2, size.height * 0.65),
      Offset(size.width / 2 + ovalWidth / 2, size.height * 0.65),
      paintLineActive,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

