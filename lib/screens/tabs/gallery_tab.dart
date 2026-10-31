library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'dart:io' show File, Platform;
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/core/theme.dart';
import 'package:smart_shutter/widgets/app_header.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

/// Gallery tab displaying all captured photos organized by mode (Passport or Smart Solo).
/// Features:
/// - Consistent AppHeader at the top
/// - Multiple image selection mode with batch delete capability
/// - Mode filtering (Passport/ID & Smart Solo Poses)
/// - Fullscreen viewing, exporting to device, and history management.
class GalleryTab extends StatefulWidget {
  const GalleryTab({super.key});

  @override
  State<GalleryTab> createState() => _GalleryTabState();
}

class _GalleryTabState extends State<GalleryTab> {
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedIds.clear();
      }
    });
  }

  void _toggleItemSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<Map<String, dynamic>> items) {
    setState(() {
      _selectedIds.addAll(items.map((e) => e['id'] as String));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected(AppState appState) async {
    if (_selectedIds.isEmpty) return;

    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete $count ${count == 1 ? 'Photo' : 'Photos'}?'),
        content: Text(
          'Are you sure you want to permanently delete $count selected ${count == 1 ? 'photo' : 'photos'} from your gallery?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete $count'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await appState.deleteCaptures(_selectedIds.toList());
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$count ${count == 1 ? 'photo' : 'photos'} deleted successfully',
            ),
            backgroundColor: const Color(0xFF1E293B),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.isDarkMode;
    final activeFilter = appState.galleryActiveFilter;

    // Filter history items based on active tab selection
    final filteredHistory = appState.captures
        .where((c) => c['type'] == activeFilter)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. Consistent App Header (App Logo + SmartShutter + Avatar) ──
        const AppHeader(),

        // ── 2. Gallery Header Bar with Multi-Select Action ──
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSelectionMode
                        ? '${_selectedIds.length} Selected'
                        : 'Gallery',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    _isSelectionMode
                        ? 'Tap images to select or deselect'
                        : '${filteredHistory.length} captures • Long-press photo to select',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),

              // Action buttons (Selection mode actions / Clear all history)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isSelectionMode) ...[
                    // Select All / Deselect All
                    TextButton(
                      onPressed: () {
                        if (_selectedIds.length == filteredHistory.length) {
                          _deselectAll();
                        } else {
                          _selectAll(filteredHistory);
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        _selectedIds.length == filteredHistory.length
                            ? 'Deselect All'
                            : 'Select All',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Delete Selected Button
                    if (_selectedIds.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () => _deleteSelected(appState),
                        icon: const Icon(Icons.delete_outline, size: 15),
                        label: Text('Delete (${_selectedIds.length})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.danger,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),

                    // Cancel selection button
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      tooltip: 'Cancel',
                      onPressed: _toggleSelectionMode,
                    ),
                  ] else ...[
                    if (appState.captures.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          Icons.delete_sweep_outlined,
                          color: isDark
                              ? AppTheme.danger
                              : const Color(0xFFEF4444),
                          size: 22,
                        ),
                        tooltip: 'Clear All History',
                        onPressed: () => _confirmClearAll(context),
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── 3. Filters Row ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildChip(
                'Passport / ID',
                activeFilter == 'passport',
                isDark,
                () {
                  context.read<AppState>().setGalleryActiveFilter('passport');
                },
              ),
              const SizedBox(width: 10),
              _buildChip(
                'Smart Solo Poses',
                activeFilter == 'smart_solo',
                isDark,
                () {
                  context.read<AppState>().setGalleryActiveFilter('smart_solo');
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── 4. Captures Grid ──
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: filteredHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          activeFilter == 'passport'
                              ? Icons.badge_outlined
                              : Icons.person_outline,
                          size: 48,
                          color: AppTheme.muted(isDark),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No ${activeFilter == 'passport' ? 'ID' : 'Solo'} photos found.',
                          style: TextStyle(
                            color: AppTheme.muted(isDark),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                      final isSelected = _selectedIds.contains(id);

                      return _buildThumbItem(
                        context,
                        id,
                        path,
                        isDark,
                        isSelected: isSelected,
                        isSelectionMode: _isSelectionMode,
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleItemSelection(id);
                          } else {
                            _showFullScreenImage(context, id, path);
                          }
                        },
                        onLongPress: () {
                          HapticFeedback.mediumImpact();
                          if (!_isSelectionMode) {
                            setState(() {
                              _isSelectionMode = true;
                              _selectedIds.add(id);
                            });
                          } else {
                            _toggleItemSelection(id);
                          }
                        },
                      );
                    },
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
        content: const Text(
          'Are you sure you want to permanently delete all captured images from history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
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
      setState(() {
        _selectedIds.clear();
        _isSelectionMode = false;
      });
    }
  }

  Widget _buildChip(
    String label,
    bool isActive,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF4F46E5).withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          border: Border.all(
            color: isActive
                ? const Color(0xFF4F46E5)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive
                ? const Color(0xFF4F46E5)
                : (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbItem(
    BuildContext context,
    String id,
    String path,
    bool isDark, {
    required bool isSelected,
    required bool isSelectionMode,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    final isUrlOrBlob =
        kIsWeb || path.startsWith('http') || path.startsWith('blob:');
    final bool exists;

    if (kIsWeb) {
      exists = isUrlOrBlob;
    } else {
      exists = isUrlOrBlob || File(path).existsSync();
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4F46E5)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image Content
            exists
                ? (isUrlOrBlob
                      ? Image.network(path, fit: BoxFit.cover)
                      : kIsWeb
                      ? Image.network(path, fit: BoxFit.cover)
                      : Image.file(File(path), fit: BoxFit.cover))
                : Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: AppTheme.muted(isDark),
                    ),
                  ),

            // Selection Mode Checkbox Badge
            if (isSelectionMode)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF4F46E5)
                        : Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.8),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),

            // Selection Dimming Overlay
            if (isSelectionMode && isSelected)
              Container(color: const Color(0xFF4F46E5).withValues(alpha: 0.22)),
          ],
        ),
      ),
    );
  }

  Future<void> _exportFile(String imagePath) async {
    try {
      Uint8List? bytes;
      if (kIsWeb ||
          imagePath.startsWith('http') ||
          imagePath.startsWith('blob:')) {
        final response = await http.get(Uri.parse(imagePath));
        bytes = response.bodyBytes;
      } else {
        if (!kIsWeb && File(imagePath).existsSync()) {
          bytes = await File(imagePath).readAsBytes();
        }
      }

      if (bytes != null) {
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          final result = await ImageGallerySaverPlus.saveImage(
            bytes,
            quality: 100,
            name: 'smartshutter_photo_${DateTime.now().millisecondsSinceEpoch}',
          );

          if (result['isSuccess'] == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Saved to Device Gallery!'),
                backgroundColor: AppTheme.ok,
              ),
            );
            return;
          }
        }

        // Web or fallback
        final fileName =
            'smartshutter_export_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: bytes,
          mimeType: MimeType.jpeg,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File exported successfully!'),
              backgroundColor: AppTheme.ok,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save file: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  void _showFullScreenImage(BuildContext context, String id, String path) {
    final isUrlOrBlob =
        kIsWeb || path.startsWith('http') || path.startsWith('blob:');

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                        ),
                        tooltip: 'Export',
                        onPressed: () {
                          _exportFile(path);
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppTheme.danger,
                        ),
                        tooltip: 'Delete',
                        onPressed: () async {
                          final shouldDelete = await showDialog<bool>(
                            context: ctx,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Delete Photo'),
                              content: const Text(
                                'Are you sure you want to delete this photo from history?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.danger,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (shouldDelete == true && ctx.mounted) {
                            await ctx.read<AppState>().deleteCapture(id);
                            if (ctx.mounted) Navigator.pop(ctx);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Image Viewer
              Flexible(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: isUrlOrBlob
                        ? Image.network(path, fit: BoxFit.contain)
                        : (kIsWeb
                              ? Image.network(path, fit: BoxFit.contain)
                              : Image.file(File(path), fit: BoxFit.contain)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
