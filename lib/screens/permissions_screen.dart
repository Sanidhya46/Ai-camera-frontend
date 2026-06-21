/// Permissions request screen shown during app setup to request camera and storage access.
/// Fully theme-aware with dynamic background and card styles.
/// Routes to main layout after permissions are handled.

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
        _goToMainLayout();
      }
      return;
    }

    final isDark = context.read<AppState>().isDarkMode;
    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Permissions Required',
          style: TextStyle(color: AppTheme.ink(isDark)),
        ),
        content: Text(
          'Smart Shutter needs access to your camera to take photos. Storage permission is optional but recommended for saving photos.',
          style: TextStyle(color: AppTheme.muted(isDark)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppTheme.muted(isDark))),
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
    appState.setTabIndex(0);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLayout()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().isDarkMode;

    return Scaffold(
      backgroundColor: AppTheme.surface(isDark),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppTheme.surface(isDark),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF090D1A) : Colors.white,
                  boxShadow: !isDark ? [
                    BoxShadow(
                      color: AppTheme.brand.withOpacity(0.1),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ] : null,
                ),
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Permissions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppTheme.ink(isDark),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Only what the app needs — your privacy is safe',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.muted(isDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCheckRow('Camera access', true, _cameraGranted, isDark, Icons.camera_alt_outlined),
                const SizedBox(height: 12),
                _buildCheckRow('Photos / storage', false, _storageGranted, isDark, Icons.photo_library_outlined),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: AppTheme.glassmorphicDecoration(isDark).copyWith(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF7F8FC),
                    border: Border.all(color: AppTheme.muted(isDark).withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.muted(isDark), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Location improves scene-aware pose suggestions in Smart Solo mode. You can skip it and still use the app.',
                          style: TextStyle(
                            color: AppTheme.muted(isDark),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: Container(
                    decoration: AppTheme.brandGradientDecoration,
                    child: ElevatedButton(
                      onPressed: _requestPermissions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Allow & Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
              ],
            ),
          ),
        ),
      );
  }

  Widget _buildCheckRow(String label, bool isRequired, bool isGranted, bool isDark, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: AppTheme.glassmorphicDecoration(isDark).copyWith(
        border: Border.all(color: AppTheme.muted(isDark).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isGranted ? AppTheme.ok : AppTheme.brand).withOpacity(0.1),
            ),
            child: Icon(
              icon,
              color: isGranted ? AppTheme.ok : AppTheme.brand,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isDark ? 15 : 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.ink(isDark),
              ),
            ),
          ),
          if (isGranted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.ok.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: AppTheme.ok, size: 14),
                  SizedBox(width: 4),
                  Text('Granted', style: TextStyle(color: AppTheme.ok, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (isRequired ? AppTheme.ok : AppTheme.warn).withOpacity(0.1),
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
