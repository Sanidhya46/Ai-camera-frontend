/// AI-generated shoot plan screen showing personalized pose suggestions for Smart Solo mode.
/// Fetches AI-generated poses from backend based on user's goal, environment, and style preferences.
/// Displays a list of numbered pose instructions with visual placeholders for each suggested shot.
/// Allows users to review the plan before starting capture or go back to adjust setup preferences.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/core/services/api_service.dart';
import 'package:smart_shutter/core/theme.dart';
import 'package:smart_shutter/screens/smart_solo/live_capture_screen.dart';

class AiPlanScreen extends StatefulWidget {
  const AiPlanScreen({super.key});

  @override
  State<AiPlanScreen> createState() => _AiPlanScreenState();
}

class _AiPlanScreenState extends State<AiPlanScreen> {
  bool _isLoading = true;
  bool _isFallbackPlan = false;
  List<dynamic> _poses = [];
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchPlan();
  }

  Future<void> _fetchPlan() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final token = appState.accessToken ?? '';
    final oldSessionId = appState.currentSessionId ?? '';

    bool endedAny = false;
    if (oldSessionId.isNotEmpty) {
      print('Proactively checking existing session $oldSessionId status...');
      final sessionDetail = await _api.getSmartSoloSession(token, oldSessionId);
      if (!sessionDetail.containsKey('error')) {
        final status = sessionDetail['status'] as String?;
        if (status == 'ACTIVE') {
          print('Existing session is active. Proactively ending it...');
          await _api.endSmartSoloSession(token, oldSessionId);
          endedAny = true;
        }
      }
    }
    
    // Check server history for any other active sessions to avoid 409 Conflict (e.g. after hot restarts)
    print('Checking for any dangling active sessions in user history on server...');
    final sessionsResult = await _api.getSmartSoloSessions(token);
    if (!sessionsResult.containsKey('error')) {
      final sessions = sessionsResult['sessions'] as List<dynamic>? ?? [];
      for (final s in sessions) {
        final sMap = s as Map<String, dynamic>;
        final status = sMap['status'] as String?;
        final sid = sMap['session_id'] as String?;
        if (status == 'ACTIVE' && sid != null && sid.isNotEmpty) {
          print('Found dangling active session on server: $sid. Ending it proactively...');
          await _api.endSmartSoloSession(token, sid);
          endedAny = true;
        }
      }
    }
    
    if (endedAny) {
      print('Waiting for server database transaction to commit session termination...');
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    
    appState.clearSession();
    
    final result = await _api.createSmartSoloSession(token);
    
    if (mounted) {
      if (result.containsKey('error')) {
        print('Error creating smart-solo session: ${result['error']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load shoot plan: ${result['error']}')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      final sessionId = result['session_id'] as String;
      final shootPlan = result['shoot_plan'] as Map<String, dynamic>?;
      
      var poseSuggestions = List<String>.from(shootPlan?['pose_suggestions'] ?? []);
      bool isFallback = false;
      if (poseSuggestions.isEmpty) {
        isFallback = true;
        poseSuggestions = [
          "Stand 2 meters back, angle body slightly to side, shoulders relaxed.",
          "Fold arms gently and look directly at camera with a confident expression.",
          "Lean back against a solid wall or structure to create natural body symmetry.",
          "Shift weight onto one leg and look slightly off-camera for a candid feel.",
          "Take a slow walk towards the camera for dynamic motion capture."
        ];
      }
      
      final uploadInterval = result['upload_interval_seconds'] as int? ?? 3;
      final maxPhotos = result['max_photos'] as int? ?? 30;
      
      appState.setCurrentSession(
        sessionId: sessionId,
        shootPlan: shootPlan,
        poseSuggestions: poseSuggestions,
        uploadIntervalSeconds: uploadInterval,
        maxPhotos: maxPhotos,
      );
      
      setState(() {
        _poses = poseSuggestions;
        _isFallbackPlan = isFallback;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI Shoot Plan', style: TextStyle(fontSize: 18, color: AppTheme.ink(isDark), fontWeight: FontWeight.bold)),
            Text(
              '${appState.selectedGoal} · ${appState.selectedEnv}', 
              style: TextStyle(fontSize: 12, color: AppTheme.muted(isDark).withOpacity(0.9)),
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.brand))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (_isFallbackPlan) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.brand2.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.brand2.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: AppTheme.brand2, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Custom AI generation is processing or temporarily offline. Loaded standard visual pose templates.",
                                  style: TextStyle(fontSize: 12, color: AppTheme.ink(isDark), height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      Expanded(
                        child: ListView.builder(
                          itemCount: _poses.length,
                          itemBuilder: (context, index) {
                            final pose = _poses[index] as String;
                            return _buildPoseCard(index + 1, pose, isDark);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                final token = appState.accessToken ?? '';
                                final sessionId = appState.currentSessionId ?? '';
                                if (sessionId.isNotEmpty) {
                                  _api.endSmartSoloSession(token, sessionId);
                                  appState.clearSession();
                                }
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('Edit setup'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
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
                                    MaterialPageRoute(builder: (_) => const LiveCaptureScreen()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text('Start Smart Capture', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
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

  Widget _buildPoseCard(int number, String instruction, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.glassmorphicDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.2),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1E293B).withOpacity(0.4),
                  const Color(0xFF0F172A).withOpacity(0.4),
                ],
              ),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt_outlined, color: AppTheme.brand, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Pose Guideline $number Visual',
                  style: TextStyle(color: AppTheme.muted(isDark), fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppTheme.brand,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  instruction,
                  style: TextStyle(color: AppTheme.ink(isDark), fontSize: 13, height: 1.45, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

