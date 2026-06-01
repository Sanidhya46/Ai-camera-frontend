import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/core/theme.dart';
import 'package:smart_shutter/screens/main_layout.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _cameraGranted = false;
  bool _storageGranted = false;

  Future<void> _requestPermissions() async {
    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text('SmartShutter needs access to your camera to take photos. Storage permission is optional but recommended for saving photos. Please grant permissions in the next steps.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (shouldRequest != true) return;

    final cameraStatus = await Permission.camera.request();
    final storageStatus = await Permission.storage.request();
    
    setState(() {
      _cameraGranted = cameraStatus.isGranted;
      _storageGranted = storageStatus.isGranted;
    });

    if (_cameraGranted) {
      if (!mounted) return;
      
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.setOnboardingSeen(true);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLayout()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Permissions', style: TextStyle(fontSize: 18, color: AppTheme.ink, fontWeight: FontWeight.bold)),
            Text('Only what the app needs', style: TextStyle(fontSize: 12, color: AppTheme.muted)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCheckRow('Camera access', true, _cameraGranted),
            const SizedBox(height: 12),
            _buildCheckRow('Photos / storage', false, _storageGranted),
            const SizedBox(height: 12),
            _buildCheckRow('Location', false, false),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.line),
                borderRadius: BorderRadius.circular(18),
                color: Colors.white,
              ),
              child: const Text(
                'Location improves scene-aware pose suggestions in Smart Solo mode. You can skip it and still use the app.',
                style: TextStyle(color: AppTheme.muted, fontSize: 13),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _requestPermissions,
                child: const Text('Allow & Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckRow(String label, bool isRequired, bool isGranted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          if (isGranted)
            const Text('✓ Granted', style: TextStyle(color: AppTheme.ok, fontWeight: FontWeight.bold))
          else
            Text(isRequired ? 'Required' : 'Optional', 
                 style: TextStyle(color: isRequired ? AppTheme.ok : AppTheme.warn, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
