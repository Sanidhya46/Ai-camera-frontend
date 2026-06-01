import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
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
      _controller = CameraController(frontCamera, ResolutionPreset.high);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.line, width: 2),
                  borderRadius: BorderRadius.circular(22),
                  color: AppTheme.brand.withOpacity(0.04),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isReady && _controller != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: CameraPreview(_controller!),
                      ),
                    // Passport oval overlay
                    Container(
                      width: MediaQuery.of(context).size.width * 0.5,
                      height: MediaQuery.of(context).size.height * 0.35,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.brand.withOpacity(0.45), width: 3),
                        borderRadius: BorderRadius.circular(150), // Oval
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Live hints: Move slightly up · Background too dark · Hold still for auto-capture',
                style: TextStyle(color: Colors.white, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PassportReviewScreen()));
                    },
                    child: const Text('Capture'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
