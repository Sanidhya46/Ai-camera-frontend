import 'package:flutter/material.dart';
import 'package:smart_shutter/core/theme.dart';
import 'package:smart_shutter/screens/passport/camera_screen.dart';

class PassportGuidelinesScreen extends StatelessWidget {
  const PassportGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Passport / ID Photo', style: TextStyle(fontSize: 18, color: AppTheme.ink, fontWeight: FontWeight.bold)),
            Text('Prepare before opening camera', style: TextStyle(fontSize: 12, color: AppTheme.muted)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.ink),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFFBFCFF)],
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCheckRow('Country / document type', 'India Passport ▼', false),
            const SizedBox(height: 12),
            _buildCheckRow('Plain light background', 'Required', true),
            const SizedBox(height: 12),
            _buildCheckRow('Neutral expression', 'Required', true),
            const SizedBox(height: 12),
            _buildCheckRow('Look straight at camera', 'Required', true),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PassportCameraScreen()));
                },
                child: const Text('Open Camera'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckRow(String label, String value, bool isRequired) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: isRequired ? AppTheme.ok : AppTheme.ink,
              fontWeight: isRequired ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
