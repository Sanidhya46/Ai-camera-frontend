import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      if (kIsWeb) {
        final cameraStatus = await Permission.camera.status;
        setState(() {
          _cameraGranted = cameraStatus.isGranted;
          _storageGranted = true;
        });
      } else {
        final cameraStatus = await Permission.camera.status;
        final storageStatus = await Permission.storage.status;
        setState(() {
          _cameraGranted = cameraStatus.isGranted;
          _storageGranted = storageStatus.isGranted;
        });
      }
    } catch (_) {
      // Fallback if permission handler fails on certain platforms
      setState(() {
        _cameraGranted = true;
        _storageGranted = true;
      });
    }
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb) {
      try {
        final cameraStatus = await Permission.camera.request();
        setState(() {
          _cameraGranted = cameraStatus.isGranted;
          _storageGranted = true;
        });
        if (!_cameraGranted && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission is recommended.')),
          );
        }
        _goToMainLayout();
      } catch (e) {
        // Safe fallback for web environments where request might fail
        _goToMainLayout();
      }
      return;
    }

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

    if (shouldRequest != true) {
      _goToMainLayout();
      return;
    }

    try {
      final cameraStatus = await Permission.camera.request();
      final storageStatus = await Permission.storage.request();
      
      setState(() {
        _cameraGranted = cameraStatus.isGranted;
        _storageGranted = storageStatus.isGranted;
      });

      if (!_cameraGranted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is recommended.')),
        );
      }
      
      _goToMainLayout();
    } catch (_) {
      _goToMainLayout();
    }
  }

  Future<void> _goToMainLayout() async {
    if (!mounted) return;
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.setOnboardingSeen(true);
    await appState.setPermissionsFlowSeen(true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLayout()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Permissions', style: TextStyle(fontSize: 18, color: AppTheme.ink, fontWeight: FontWeight.bold)),
            Text('Only what the app needs', style: TextStyle(fontSize: 12, color: AppTheme.muted.withOpacity(0.9))),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: AppTheme.gradientBg,
        child: SafeArea(
          child: Padding(
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
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassmorphicDecoration,
                  child: Text(
                    kIsWeb
                        ? 'Testing on Web: Browser permissions will be handled automatically when the camera opens. Click "Allow & Continue" to proceed.'
                        : 'Location improves scene-aware pose suggestions in Smart Solo mode. You can skip it and still use the app.',
                    style: const TextStyle(color: AppTheme.muted, fontSize: 13, height: 1.45),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
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
                      onPressed: _requestPermissions,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Allow & Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckRow(String label, bool isRequired, bool isGranted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: AppTheme.glassmorphicDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.ink),
          ),
          if (isGranted)
            const Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.ok, size: 18),
                SizedBox(width: 6),
                Text('Granted', style: TextStyle(color: AppTheme.ok, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isRequired ? AppTheme.ok.withOpacity(0.12) : AppTheme.warn.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isRequired ? 'Required' : 'Optional',
                style: TextStyle(
                  fontSize: 12,
                  color: isRequired ? AppTheme.ok : AppTheme.warn,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

