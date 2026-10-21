/// Results screen displaying captured Smart Solo mode photos with AI selection.
/// Shows the best shots chosen by AI from the capture session with preview and action buttons.
/// Provides options to save to gallery, use for passport photo generation, or continue capturing.
/// Final workflow screen in Smart Solo mode that allows users to manage and process their aesthetic shots.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'dart:io' show File;
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/core/theme.dart';
import 'package:smart_shutter/core/services/api_service.dart';
import 'package:smart_shutter/screens/main_layout.dart';

class ResultsScreen extends StatefulWidget {
  final String sessionId;
  final Map<String, String> uploadedPhotoPaths;

  const ResultsScreen({
    super.key,
    required this.sessionId,
    this.uploadedPhotoPaths = const {},
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final ApiService _api = ApiService();
  Timer? _pollTimer;
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  
  List<dynamic> _topPhotos = [];
  List<String> _aiRecommendations = [];
  int _selectedIdx = 0;
  bool _isPollingCallActive = false;

  @override
  void initState() {
    super.initState();
    _startResultPolling();
  }

  void _startResultPolling() {
    final appState = Provider.of<AppState>(context, listen: false);
    final token = appState.accessToken ?? '';

    // Poll session status every 2 seconds to check if completed
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted || _isPollingCallActive) return;
      
      _isPollingCallActive = true;
      try {
        final sessionDetail = await _api.getSmartSoloSession(token, widget.sessionId);
        
        if (mounted) {
          if (sessionDetail.containsKey('error')) {
            print('Error checking session status: ${sessionDetail['error']}');
            _pollTimer?.cancel();
            _fallbackClientSideRanking(token);
          } else {
            final status = sessionDetail['status'] as String?;
            final completedAt = sessionDetail['completed_at'];
            
            if (status == 'FAILED') {
              _pollTimer?.cancel();
              _fallbackClientSideRanking(token);
            } else if (status == 'EXPIRED') {
              setState(() {
                _errorMessage = 'This photoshoot session has expired. Please try starting a new session.';
                _isLoading = false;
              });
              _pollTimer?.cancel();
            } else if (status == 'COMPLETED' || completedAt != null) {
              // Session completed, now fetch results (guaranteed 200 OK without console 404!)
              final result = await _api.getSmartSoloResult(token, widget.sessionId);
              
              if (mounted) {
                if (result.containsKey('error')) {
                  _fallbackClientSideRanking(token);
                } else {
                  setState(() {
                    _topPhotos = result['top_photos'] as List<dynamic>? ?? [];
                    _aiRecommendations = List<String>.from(result['ai_recommendations'] ?? []);
                    _isLoading = false;
                  });
                }
              }
              _pollTimer?.cancel();
            }
          }
        }
      } catch (e) {
        print('Error in results polling callback: $e');
      } finally {
        _isPollingCallActive = false;
      }
    });
  }

  Future<void> _fallbackClientSideRanking(String token) async {
    print('Starting client-side fallback ranking for ${widget.uploadedPhotoPaths.length} photos...');
    setState(() {
      _isLoading = true;
    });

    List<Map<String, dynamic>> parsedPhotos = [];

    bool allFailed = true;

    // Query each uploaded photo ID to get its analysis results
    for (final photoId in widget.uploadedPhotoPaths.keys) {
      try {
        final photoDetail = await _api.getSmartSoloPhoto(token, widget.sessionId, photoId);
        if (photoDetail.containsKey('error')) {
          print('Error fetching photo $photoId detail: ${photoDetail['error']}');
          continue;
        }
        
        final status = photoDetail['status'] as String?;
        if (status == 'ANALYZED' && photoDetail.containsKey('scores')) {
          parsedPhotos.add({
            'photo_id': photoId,
            'scores': photoDetail['scores'],
          });
          allFailed = false;
        }
      } catch (e) {
        print('Exception fetching photo $photoId: $e');
      }
    }

    if (allFailed) {
      // AI quota reached or all failed. Do NOT mock scores. Just show all local images.
      for (final photoId in widget.uploadedPhotoPaths.keys) {
        parsedPhotos.add({
          'photo_id': photoId,
          'scores': null,
        });
      }
    } else {
      // Sort photos by overall score descending
      parsedPhotos.sort((a, b) {
        final aOverall = (a['scores'] as Map<String, dynamic>?)?['overall'] as num? ?? 0.0;
        final bOverall = (b['scores'] as Map<String, dynamic>?)?['overall'] as num? ?? 0.0;
        return bOverall.compareTo(aOverall);
      });
    }

    // Take top 3
    final topPhotos = parsedPhotos.take(3).toList();

    if (mounted) {
      setState(() {
        _topPhotos = topPhotos;
        _aiRecommendations = [
          'Ensure your camera is steady to maintain a high sharpness score.',
          'Face your main light source directly to optimize the lighting score.',
          'Try experimenting with a wider range of head angles and expressions in your next photoshoot.'
        ];
        _errorMessage = allFailed ? 'AI service unavailable (Quota reached). Displaying your raw captures.' : null;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSelectedPhoto() async {
    if (_topPhotos.isEmpty) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      for (final photo in _topPhotos) {
        final photoId = photo['photo_id'] as String;
        final scores = photo['scores'] as Map<String, dynamic>?;
        final localPath = widget.uploadedPhotoPaths[photoId];
        
        if (localPath != null) {
          await appState.addCapture(
            path: localPath,
            type: 'smart_solo',
            isCompliant: true,
            complianceReport: scores ?? {},
          );
        }
      }
        
      final isDark = Provider.of<AppState>(context, listen: false).isDarkMode;
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
              Expanded(
                child: Text(
                  'Best shots saved to your gallery!',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : AppTheme.lightLine, width: 1.5),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          elevation: 10,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Error saving photos: $e');
    }

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainLayout()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
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
            Text('Your Best Shots', style: TextStyle(fontSize: 18, color: AppTheme.ink(isDark), fontWeight: FontWeight.bold)),
            Text('AI-selected results', style: TextStyle(fontSize: 12, color: AppTheme.muted(isDark).withOpacity(0.9))),
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
              ? _buildProcessingState(isDark)
              : _errorMessage != null && _topPhotos.isEmpty
                  ? _buildErrorState(isDark)
                  : _buildResultsState(isDark),
        ),
      ),
    );
  }

  Widget _buildProcessingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.glassmorphicDecoration(isDark),
            child: const CircularProgressIndicator(color: AppTheme.brand, strokeWidth: 3.5),
          ),
          const SizedBox(height: 24),
          Text(
            'AI finalising your photoshoot...',
            style: TextStyle(fontSize: 16, color: AppTheme.ink(isDark), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'Running duplicate detection, photo ranking, and generating personalized lighting & composition suggestions.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.muted(isDark), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 48),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(fontSize: 16, color: AppTheme.ink(isDark), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.muted(isDark)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _startResultPolling();
              },
              child: const Text('Retry Polling'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsState(bool isDark) {
    if (_topPhotos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 48, color: AppTheme.muted(isDark)),
            const SizedBox(height: 16),
            Text(
              'No compliant photos taken in this session',
              style: TextStyle(color: AppTheme.ink(isDark), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    final selectedPhoto = _topPhotos[_selectedIdx];
    final selectedPhotoId = selectedPhoto['photo_id'] as String;
    final selectedPhotoPath = widget.uploadedPhotoPaths[selectedPhotoId] ?? '';
    final scores = selectedPhoto['scores'] as Map<String, dynamic>?;
    
    final overallScore = (scores?['overall'] as num? ?? 0.0) * 10;
    final sharpness = (scores?['sharpness'] as num? ?? 0.0) * 10;
    final lighting = (scores?['lighting'] as num? ?? 0.0) * 10;
    final composition = (scores?['composition'] as num? ?? 0.0) * 10;
    final expression = (scores?['expression'] as num? ?? 0.0) * 10;
    final hasScores = scores != null;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Best Shot Preview
          Expanded(
            child: Container(
              decoration: AppTheme.glassmorphicDecoration(isDark),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: selectedPhotoPath.isNotEmpty
                          ? (kIsWeb
                              ? Image.network(
                                  selectedPhotoPath,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(color: AppTheme.brand),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => const Center(
                                    child: Text('Failed to load image preview'),
                                  ),
                                )
                              : Image.file(
                                  File(selectedPhotoPath),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Center(
                                    child: Text('Failed to load image preview'),
                                  ),
                                ))
                          : Center(
                              child: Icon(Icons.image_not_supported_outlined, size: 48, color: AppTheme.muted(isDark)),
                            ),
                    ),
                  ),
                  if (hasScores)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'AI Score: ${overallScore.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'AI Failed',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
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
          const SizedBox(height: 16),
          
          // AI Score Breakdown
          if (hasScores) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildScoreIndicator('Sharpness', sharpness, isDark),
                _buildScoreIndicator('Lighting', lighting, isDark),
                _buildScoreIndicator('Composition', composition, isDark),
                _buildScoreIndicator('Expression', expression, isDark),
              ],
            ),
            const SizedBox(height: 16),
          ] else if (_errorMessage != null) ...[
             Container(
               width: double.infinity,
               padding: const EdgeInsets.all(16),
               decoration: AppTheme.glassmorphicDecoration(isDark).copyWith(
                 border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Row(
                     children: [
                       Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 20),
                       SizedBox(width: 8),
                       Text('AI Analysis Failed', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 14)),
                     ],
                   ),
                   const SizedBox(height: 8),
                   Text(
                     _errorMessage!,
                     style: TextStyle(color: AppTheme.ink(isDark), fontSize: 12),
                   ),
                 ],
               ),
             ),
             const SizedBox(height: 16),
          ],
          
          // Thumbnail grid of alternatives
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_topPhotos.length, (index) {
              final photo = _topPhotos[index];
              final photoId = photo['photo_id'] as String;
              final isSelected = index == _selectedIdx;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIdx = index;
                  });
                },
                child: Container(
                  width: 80,
                  height: 100,
                  decoration: AppTheme.glassmorphicCustom(
                    radius: 14,
                    borderColor: isSelected ? AppTheme.brand : null,
                    isDark: isDark,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: (widget.uploadedPhotoPaths[photoId] ?? '').isNotEmpty
                      ? (kIsWeb
                          ? Image.network(
                              widget.uploadedPhotoPaths[photoId] ?? '',
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(widget.uploadedPhotoPaths[photoId] ?? ''),
                              fit: BoxFit.cover,
                            ))
                      : Center(
                          child: Icon(Icons.image_not_supported_outlined, size: 24, color: AppTheme.muted(isDark)),
                        ),
                ),
              );
            }),
          ),
          
          if (_aiRecommendations.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: AppTheme.glassmorphicDecoration(isDark),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tips_and_updates_outlined, color: AppTheme.brand, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'AI Feedback Suggestions',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.ink(isDark)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ..._aiRecommendations.take(2).map((rec) => Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '• $rec',
                      style: TextStyle(color: AppTheme.muted(isDark), fontSize: 11.5, height: 1.3),
                    ),
                  )),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    final appState = Provider.of<AppState>(context, listen: false);
                    appState.clearSession();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Retake'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.brand.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveSelectedPhoto,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isSaving 
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Save / Share', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreIndicator(String label, num score, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: AppTheme.muted(isDark), fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.brand.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${score.toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 12, color: AppTheme.brand, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
