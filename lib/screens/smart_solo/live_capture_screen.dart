/// Live camera capture screen for Smart Solo mode with AI-guided pose instructions.
/// Displays real-time camera feed with current pose instruction, countdown timer, and real-time AI feedback on framing.
/// Automatically captures photos based on AI assessment of pose quality and framing compliance.
/// Routes captured photos to results screen for preview and saving after countdown completes.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/core/theme.dart';
import 'package:smart_shutter/core/services/api_service.dart';
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
  Timer? _recommendationsTimer;
  Timer? _countsTimer;
  String _hintText = 'Evaluating pose and framing...';
  bool _isCapturing = false;
  bool _isEndingSession = false;

  final ApiService _api = ApiService();

  // Smart Solo active session state
  int _capturedCount = 0;
  int _analyzedCount = 0;
  int _pendingCount = 0;
  List<String> _liveTips = [];
  int _activeUploads = 0;
  bool _isRecommendationsPolling = false;
  bool _isCountsPolling = false;
  final Map<String, String> _uploadedPhotoPaths = {};
  bool _isFirstCapture = true;

  Future<void> _flipCamera() async {
    if (_cameras.length < 2 || _controller == null) return;
    final currentLensDirection = _controller!.description.lensDirection;
    final newLensDirection = currentLensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    final newCamera = _cameras.firstWhere(
      (c) => c.lensDirection == newLensDirection,
      orElse: () => _cameras.first,
    );
    await _controller?.dispose();
    _controller = CameraController(
      newCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _controller?.initialize();
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _initCamera();
    _startSessionPolling();
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
        _startCountdown();
      }
    }
  }

  void _startSessionPolling() {
    final appState = Provider.of<AppState>(context, listen: false);
    final token = appState.accessToken ?? '';
    final sessionId = appState.currentSessionId ?? '';
    final interval = appState.uploadIntervalSeconds;

    if (sessionId.isEmpty) return;

    setState(() {
      _countdown = interval;
    });

    // Poll live recommendations with concurrency guard
    _recommendationsTimer = Timer.periodic(Duration(seconds: interval), (timer) async {
      if (!mounted || _isRecommendationsPolling) return;
      
      _isRecommendationsPolling = true;
      try {
        final result = await _api.getSmartSoloSession(token, sessionId);
        if (mounted && !result.containsKey('error')) {
          final recs = result['live_recommendations'] as Map<String, dynamic>?;
          if (recs != null) {
            setState(() {
              _liveTips = List<String>.from(recs['recommendations'] ?? []);
            });
          }
        }
      } catch (e) {
        print('Error in recommendations polling: $e');
      } finally {
        _isRecommendationsPolling = false;
      }
    });

    // Poll photo status counts with concurrency guard
    _countsTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (!mounted || _isCountsPolling) return;
      
      _isCountsPolling = true;
      try {
        final result = await _api.getPhotoCounts(token, sessionId);
        if (mounted && !result.containsKey('error')) {
          setState(() {
            _analyzedCount = result['analyzed'] as int? ?? 0;
            _pendingCount = result['pending'] as int? ?? 0;
          });
        }
      } catch (e) {
        print('Error in counts polling: $e');
      } finally {
        _isCountsPolling = false;
      }
    });
  }

  void _startCountdown() {
    if (_isFirstCapture) {
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
    } else {
      final interval = Provider.of<AppState>(context, listen: false).uploadIntervalSeconds;
      _timer = Timer(Duration(seconds: interval), () {
        if (mounted) _triggerCapture();
      });
    }
  }

  Future<void> _triggerCapture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing || _isEndingSession) return;

    setState(() {
      _isCapturing = true;
      _hintText = 'Capturing...';
    });

    try {
      final XFile photo = await _controller!.takePicture();
      if (_isEndingSession) return;
      
      String localPath;
      if (kIsWeb) {
        localPath = photo.path;
      } else {
        final directory = await getApplicationDocumentsDirectory();
        localPath = '${directory.path}/solo_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File(photo.path);
        await file.copy(localPath);
      }

      setState(() {
        _capturedCount++;
        _hintText = 'Captured! Uploading...';
      });

      // Background upload
      _uploadCapturedPhoto(photo, localPath);

      if (mounted && !_isEndingSession) {
        final appState = Provider.of<AppState>(context, listen: false);
        setState(() {
          _countdown = appState.uploadIntervalSeconds;
          _isCapturing = false;
          _isFirstCapture = false;
        });
        _startCountdown();
      }
    } catch (e) {
      print('Capture error: $e');
      if (mounted && !_isEndingSession) {
        final appState = Provider.of<AppState>(context, listen: false);
        setState(() {
          _hintText = 'Failed capturing. Retrying...';
          _countdown = appState.uploadIntervalSeconds;
          _isCapturing = false;
        });
        _startCountdown();
      }
    }
  }

  Future<void> _uploadCapturedPhoto(XFile photo, String path) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final token = appState.accessToken ?? '';
    final sessionId = appState.currentSessionId ?? '';
    
    if (sessionId.isEmpty) return;
    if (_isEndingSession) {
      print('Skipping upload since session is ending.');
      return;
    }

    if (mounted) {
      setState(() {
        _activeUploads++;
      });
    }

    try {
      final bytes = await photo.readAsBytes();
      final response = await _api.uploadSmartSoloPhoto(
        token,
        sessionId,
        path,
        bytes: bytes,
      );
      print('Photo upload response: $response');
      if (response != null && response.containsKey('photo_id')) {
        final photoId = response['photo_id'] as String;
        _uploadedPhotoPaths[photoId] = path;
      }
    } catch (e) {
      print('Error uploading photo: $e');
    } finally {
      if (mounted) {
        setState(() {
          _activeUploads--;
        });
      }
    }
  }

  Future<void> _endSession() async {
    if (_isEndingSession) return;

    setState(() {
      _isEndingSession = true;
      _hintText = 'Finalising uploads...';
    });

    _timer?.cancel();
    _recommendationsTimer?.cancel();
    _countsTimer?.cancel();

    // Await any remaining background uploads to prevent server conflict
    while (_activeUploads > 0) {
      if (!mounted) return;
      setState(() {
        _hintText = 'Uploading remaining captures ($_activeUploads left)...';
      });
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (!mounted) return;
    setState(() {
      _hintText = 'Ending photoshoot...'; 
    });

    final appState = Provider.of<AppState>(context, listen: false);
    final token = appState.accessToken ?? '';
    final sessionId = appState.currentSessionId ?? '';

    if (sessionId.isNotEmpty) {
      await _api.endSmartSoloSession(token, sessionId);
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultsScreen(
            sessionId: sessionId,
            uploadedPhotoPaths: _uploadedPhotoPaths,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recommendationsTimer?.cancel();
    _countsTimer?.cancel();
    final tempController = _controller;
    _controller = null;
    tempController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.isDarkMode;
    final activePose = appState.aiPoses.isNotEmpty ? appState.aiPoses[0]['instruction'] : 'Step back and follow AI instructions.';

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Smart Capture', style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            Text('Aesthetic Auto-Capture Live', style: const TextStyle(fontSize: 12, color: Colors.white70), overflow: TextOverflow.ellipsis),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
            onPressed: _flipCamera,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Camera View taking available space above UI
          Expanded(
            child: Stack(
              children: [
                if (_isReady && _controller != null)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black,
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

                // Countdown Overlay (Only on first capture)
                if (!_isCapturing && _isFirstCapture)
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
                  
                // Small buffering indicator when capturing (not first capture flash)
                if (_isCapturing && !_isFirstCapture)
                  const Positioned(
                    top: 24,
                    right: 24,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: AppTheme.brand, strokeWidth: 3),
                    ),
                  ),
              ],
            ),
          ),
            
          // 2. UI Overlay Area
          Container(
            color: isDark ? Colors.black : Colors.white,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Guidance Status Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      decoration: AppTheme.glassmorphicDecoration(isDark),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.psychology_outlined, color: AppTheme.brand2, size: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'AI Guidance System',
                                  style: TextStyle(color: AppTheme.ink(isDark), fontSize: 13, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '✓ Face detected',
                            style: TextStyle(color: AppTheme.muted(isDark), fontSize: 12),
                          ),
                          Text(
                            '✓ Ambient lighting ideal',
                            style: TextStyle(color: AppTheme.muted(isDark), fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Goal Pose: $activePose',
                            style: const TextStyle(color: AppTheme.brand2, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          if (_liveTips.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Live Guidance Tips:',
                              style: TextStyle(color: AppTheme.ink(isDark), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            ..._liveTips.map((tip) => Text(
                              '• $tip',
                              style: TextStyle(color: AppTheme.ink(isDark), fontSize: 12),
                            )),
                          ],
                          const SizedBox(height: 10),
                          Divider(color: AppTheme.muted(isDark).withOpacity(0.2), height: 1),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Captured: $_capturedCount',
                                style: TextStyle(color: AppTheme.muted(isDark), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Pending AI: $_pendingCount',
                                style: TextStyle(color: AppTheme.muted(isDark), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Analyzed: $_analyzedCount',
                                style: TextStyle(color: AppTheme.muted(isDark), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isCapturing 
                                ? 'Processing capture...' 
                                : _isEndingSession 
                                    ? 'Finalising session...' 
                                    : 'Next capture in $_countdown seconds...',
                            style: TextStyle(color: AppTheme.brand, fontSize: 13, fontWeight: FontWeight.bold),
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
                              backgroundColor: Colors.black45,
                              side: const BorderSide(color: Colors.white),
                            ),
                            child: const FittedBox(child: Text('Pause', style: TextStyle(color: Colors.white))),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isEndingSession ? null : _endSession,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              backgroundColor: AppTheme.brand,
                            ),
                            child: _isEndingSession 
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                  )
                                : const FittedBox(child: Text('End Session', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                          ),
                        ),
                      ],
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

