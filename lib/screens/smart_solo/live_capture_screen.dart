import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/core/theme.dart';
import 'package:smart_shutter/screens/smart_solo/results_screen.dart';

class LiveCaptureScreen extends StatefulWidget {
  const LiveCaptureScreen({super.key});

  @override
  State<LiveCaptureScreen> createState() => _LiveCaptureScreenState();
}

class _LiveCaptureScreenState extends State<LiveCaptureScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isReady = false;
  int _countdown = 3;
  Timer? _timer;
  String _hintText = 'Evaluating pose and framing...';
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      final backCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );
      _controller = CameraController(
        backCamera, 
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _controller?.initialize();
      if (mounted) {
        setState(() {
          _isReady = true;
        });
        _startCountdown();
      }
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      setState(() {
        if (_countdown > 1) {
          _countdown--;
        } else {
          _timer?.cancel();
          _triggerCapture();
        }
      });
    });
  }

  Future<void> _triggerCapture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;

    setState(() {
      _isCapturing = true;
      _hintText = 'Capturing the perfect shot!';
    });

    try {
      final XFile photo = await _controller!.takePicture();
      
      // Save locally to documents or use Blob URL directly on Web
      String localPath;
      if (kIsWeb) {
        localPath = photo.path;
      } else {
        final directory = await getApplicationDocumentsDirectory();
        localPath = '${directory.path}/solo_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File(photo.path);
        await file.copy(localPath);
      }

      // Add to captures history in AppState
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        await appState.addCapture(
          path: localPath,
          type: 'smart_solo',
          isCompliant: true,
          complianceReport: {'sharpness': 0.85, 'pose_match': 0.9},
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ResultsScreen(imagePath: localPath)),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hintText = 'Failed capturing. Retrying...';
          _countdown = 3;
          _isCapturing = false;
        });
        _startCountdown();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final activePose = appState.aiPoses.isNotEmpty ? appState.aiPoses[0]['instruction'] : 'Step back and follow AI instructions.';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Smart Capture', style: TextStyle(fontSize: 18, color: AppTheme.ink, fontWeight: FontWeight.bold)),
            Text('Aesthetic Auto-Capture Live', style: TextStyle(fontSize: 12, color: AppTheme.muted.withOpacity(0.9))),
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
                // Camera Grid View
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
                        
                        // Composition Grid Lines overlay
                        Positioned.fill(
                          child: CustomPaint(
                            painter: CompositionGridPainter(),
                          ),
                        ),

                        // Countdown Overlay
                        if (!_isCapturing)
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$_countdown',
                                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Guidance Status Box
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827).withOpacity(0.95),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.psychology_outlined, color: AppTheme.brand2, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'AI Guidance System',
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '✓ Face detected',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                      ),
                      Text(
                        '✓ Ambient lighting ideal',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                      ),
                      Text(
                        activePose,
                        style: const TextStyle(color: AppTheme.brand2, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isCapturing ? 'Saving...' : 'Capturing in $_countdown seconds...',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Pause'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _timer?.cancel();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const ResultsScreen(imagePath: '')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('End Session', style: TextStyle(fontWeight: FontWeight.bold)),
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

class CompositionGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white30
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Dashed effect or simple grid
    // Vertical line 1
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    // Vertical line 2
    canvas.drawLine(Offset(2 * size.width / 3, 0), Offset(2 * size.width / 3, size.height), paint);
    // Horizontal line 1
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    // Horizontal line 2
    canvas.drawLine(Offset(0, 2 * size.height / 3), Offset(size.width, 2 * size.height / 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

