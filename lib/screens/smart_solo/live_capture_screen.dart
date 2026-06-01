import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
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
      _controller = CameraController(backCamera, ResolutionPreset.high);
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
            Text('Smart Capture', style: TextStyle(fontSize: 18, color: AppTheme.ink, fontWeight: FontWeight.bold)),
            Text('Pose 1 of 3 · Session live', style: TextStyle(fontSize: 12, color: AppTheme.muted)),
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
                  border: Border.all(color: AppTheme.brand.withOpacity(0.35), width: 2),
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
                    // Focus lines overlay
                    Positioned.fill(
                      child: Container(
                        margin: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.brand.withOpacity(0.35), width: 2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Text('Face detected ✅', style: TextStyle(color: Colors.white, fontSize: 13)),
                  Text('Lighting good ✅', style: TextStyle(color: Colors.white, fontSize: 13)),
                  Text('Step back a little ⬅️', style: TextStyle(color: Colors.white, fontSize: 13)),
                  SizedBox(height: 8),
                  Text('Capturing in 3…2…1', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Pause'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ResultsScreen()));
                    },
                    child: const Text('End Session'),
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
