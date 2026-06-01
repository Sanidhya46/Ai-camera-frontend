import 'package:flutter/material.dart';
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
  List<dynamic> _poses = [];
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchPlan();
  }

  Future<void> _fetchPlan() async {
    final result = await _api.generateAIPlan({});
    if (mounted) {
      setState(() {
        _poses = result['poses'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI Shoot Plan', style: TextStyle(fontSize: 18, color: AppTheme.ink, fontWeight: FontWeight.bold)),
            Text('Pose 1 of 3', style: TextStyle(fontSize: 12, color: AppTheme.muted)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.ink),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.brand))
          : Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: _poses.length,
                      itemBuilder: (context, index) {
                        final pose = _poses[index];
                        return _buildPoseCard(pose['instruction']);
                      },
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Edit setup'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context, 
                              MaterialPageRoute(builder: (_) => const LiveCaptureScreen())
                            );
                          },
                          child: const Text('Start Smart Capture'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPoseCard(String instruction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 92,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFC9D2E3), style: BorderStyle.solid),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFAFBFF), Colors.white],
              ),
            ),
            alignment: Alignment.center,
            child: const Text('Pose illustration', style: TextStyle(color: AppTheme.muted, fontSize: 12)),
          ),
          const SizedBox(height: 10),
          Text(instruction, style: const TextStyle(color: AppTheme.muted, fontSize: 13, height: 1.45)),
        ],
      ),
    );
  }
}
