/// Gallery tab displaying all captured photos organized by mode (Passport or Smart Solo).
/// Provides filtering between modes, full-screen image viewing, download/export, and deletion capabilities.
/// Handles both local files and web-based image storage with cross-platform support.
/// Includes history clearing and individual photo management features for users to organize their work.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'dart:io' show File, Platform;
import 'dart:typed_data';
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/core/theme.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_saver/file_saver.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

class GalleryTab extends StatefulWidget {
  const GalleryTab({super.key});

  @override
  State<GalleryTab> createState() => _GalleryTabState();
}

class _GalleryTabState extends State<GalleryTab> {
  String _activeFilter = 'passport'; // 'passport' or 'smart_solo'

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.isDarkMode;
    
    // Filter history items based on active tab selection
    final filteredHistory = appState.captures.where((c) => c['type'] == _activeFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF090D1A) : Colors.white,
            boxShadow: !isDark ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 4),
                blurRadius: 8,
              ),
            ] : null,
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gallery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? AppTheme.ink(isDark) : Colors.black87)),
                  Text(
                    'Review past outputs and sessions',
                    style: TextStyle(fontSize: 12, color: isDark ? AppTheme.muted(isDark) : Colors.black54),
                  ),
                ],
              ),
              if (appState.captures.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.delete_sweep_outlined, color: isDark ? AppTheme.danger : Colors.white),
                  tooltip: 'Clear History',
                  onPressed: () => _confirmClearAll(context),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Content padding for the rest of the tab
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
          
          // Filters selection Row
          Row(
            children: [
              _buildChip('Passport / ID', _activeFilter == 'passport', isDark, () {
                setState(() => _activeFilter = 'passport');
              }),
              const SizedBox(width: 10),
              _buildChip('Smart Solo Poses', _activeFilter == 'smart_solo', isDark, () {
                setState(() => _activeFilter = 'smart_solo');
              }),
            ],
          ),
          const SizedBox(height: 18),
          
          // Captures Grid View
          Expanded(
            child: filteredHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _activeFilter == 'passport' ? Icons.badge_outlined : Icons.person_outline,
                          size: 48,
                          color: AppTheme.muted(isDark),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No ${_activeFilter == 'passport' ? 'ID' : 'Solo'} photos found.',
                          style: TextStyle(color: AppTheme.muted(isDark), fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1 / 1.25,
                    ),
                    itemCount: filteredHistory.length,
                    itemBuilder: (context, index) {
                      final item = filteredHistory[index];
                      final id = item['id'] as String;
                      final path = item['path'] as String;
                      return _buildThumbItem(context, id, path, isDark);
                    },
                  ),
          ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to permanently delete all captured images from history?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (shouldClear == true && context.mounted) {
      await context.read<AppState>().clearHistory();
    }
  }

  Widget _buildChip(String label, bool isActive, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.brand.withOpacity(0.12) : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: isActive ? AppTheme.brand.withOpacity(0.4) : AppTheme.line(isDark),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? AppTheme.brand : AppTheme.ink(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbItem(BuildContext context, String id, String path, bool isDark) {
    final isUrlOrBlob = kIsWeb || path.startsWith('http') || path.startsWith('blob:');
    final bool exists;
    
    if (kIsWeb) {
      exists = isUrlOrBlob;
    } else {
      exists = isUrlOrBlob || File(path).existsSync();
    }

    return GestureDetector(
      onTap: () {
        if (exists) {
          _showFullScreenImage(context, id, path);
        }
      },
      child: Container(
        decoration: AppTheme.glassmorphicCustom(radius: 14, isDark: isDark),
        clipBehavior: Clip.antiAlias,
        child: exists
            ? (isUrlOrBlob
                ? Image.network(
                    path,
                    fit: BoxFit.cover,
                  )
                : kIsWeb
                    ? Image.network(path, fit: BoxFit.cover)
                    : Image.file(
                        File(path),
                        fit: BoxFit.cover,
                      ))
            : Center(
                child: Icon(Icons.broken_image_outlined, color: AppTheme.muted(isDark)),
              ),
      ),
    );
  }

  Future<void> _exportFile(String imagePath) async {
    try {
      Uint8List? bytes;
      if (kIsWeb || imagePath.startsWith('http') || imagePath.startsWith('blob:')) {
        final response = await http.get(Uri.parse(imagePath));
        bytes = response.bodyBytes;
      } else {
        if (!kIsWeb && File(imagePath).existsSync()) {
          bytes = await File(imagePath).readAsBytes();
        }
      }

      if (bytes != null) {
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          // Save to gallery
          final result = await ImageGallerySaverPlus.saveImage(
            bytes,
            quality: 100,
            name: 'smartshutter_photo_${DateTime.now().millisecondsSinceEpoch}',
          );

          if (result['isSuccess'] == true) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppTheme.ok, shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('Photo saved to Gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ],
                  ),
                  backgroundColor: AppTheme.brand.withOpacity(0.9),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: const BorderSide(color: Colors.black, width: 1.5),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  elevation: 10,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          } else {
            throw Exception('Failed to save');
          }
        } else if (kIsWeb) {
          // Web download
          final fileName = 'smartshutter_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await FileSaver.instance.saveFile(
            name: fileName,
            bytes: bytes,
            mimeType: MimeType.jpeg,
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppTheme.ok, shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Photo downloaded', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ],
                ),
                backgroundColor: AppTheme.brand.withOpacity(0.9),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: Colors.black, width: 1.5),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                elevation: 10,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  void _showFullScreenImage(BuildContext context, String id, String path) {
    final isUrlOrBlob = kIsWeb || path.startsWith('http') || path.startsWith('blob:');
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: isUrlOrBlob
                    ? Image.network(
                        path,
                        fit: BoxFit.contain,
                      )
                    : kIsWeb
                        ? Image.network(path, fit: BoxFit.contain)
                        : Image.file(
                            File(path),
                            fit: BoxFit.contain,
                          ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                CircleAvatar(
                  backgroundColor: AppTheme.brand.withOpacity(0.9),
                  child: IconButton(
                    icon: const Icon(Icons.download_rounded, color: Colors.white),
                    onPressed: () => _exportFile(path),
                  ),
                ),
                CircleAvatar(
                  backgroundColor: AppTheme.danger.withOpacity(0.9),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed: () async {
                      await context.read<AppState>().deleteCapture(id);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

