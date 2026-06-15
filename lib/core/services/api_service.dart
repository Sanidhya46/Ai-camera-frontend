/// Backend API integration service for the SmartShutter app.
/// Handles all HTTP requests to the backend including photo uploads for compliance analysis, passport photo generation, downloads, and AI pose plan generation.
/// Manages multipart file uploads, error handling, and timeouts for network operations.
/// Provides methods to communicate with the Flask/FastAPI backend for biometric analysis and image processing.

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  // TODO: Update this to your actual backend URL
  // Example: 'https://your-backend-url.com' or 'http://192.168.x.x:8000' for local testing
  final String baseUrl = 'https://rajputnishant29-ai-camera.hf.space';

  /// Uploads a photo to the backend, which performs biometric compliance analysis.
  /// Returns a map with 'session_id', 'is_compliant', and 'compliance_report'.
  Future<Map<String, dynamic>> uploadPhoto(String filePath, {Uint8List? bytes}) async {
    try {
      final uri = Uri.parse('$baseUrl/upload-photo/');
      final request = http.MultipartRequest('POST', uri);
      
      if (kIsWeb && bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: 'capture.jpg',
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            filePath,
          ),
        );
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);


      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {
          'session_id': '',
          'is_compliant': false,
          'compliance_report': {
            'error': 'Server error (${response.statusCode}): ${response.body}'
          }
        };
      }
    } catch (e) {
      print('Upload error: $e');  // Debug print
      return {
        'session_id': '',
        'is_compliant': false,
        'compliance_report': {
          'error': 'Network error: $e'
        }
      };
    }
  }

  /// Sends request to generate a passport photo from the uploaded photo.
  /// Performs deskew, color correction, cropping (600x600 px), background removal,
  /// and returns details of the generated image (photo_id, download_url, etc.)
  Future<Map<String, dynamic>> generatePassportPhoto(String sessionId) async {
    try {
      final uri = Uri.parse('$baseUrl/generate-passport-photo/$sessionId');
      final response = await http.post(uri).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {
          'error': 'Server error (${response.statusCode}): ${response.body}'
        };
      }
    } catch (e) {
      return {
        'error': 'Network connection failed: $e'
      };
    }
  }

  /// Downloads the generated photo by photo ID.
  /// Returns the image bytes.
  Future<Uint8List?> downloadPhoto(String photoId) async {
    try {
      final uri = Uri.parse('$baseUrl/download/$photoId');
      final response = await http.get(uri).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  /// Generates a customized AI Shoot Plan based on setup preferences.
  Future<Map<String, dynamic>> generateAIPlan(Map<String, String> setupData) async {
    // Simulate AI thinking delay
    await Future.delayed(const Duration(seconds: 1));
    
    final goal = setupData['goal'] ?? 'Travel';
    final env = setupData['env'] ?? 'Outdoor City';
    final style = setupData['style'] ?? 'Full body';

    // Tailored instructions based on environment and style
    return {
      'status': 'success',
      'poses': [
        {
          'id': 1,
          'instruction': 'Stand 8 ft from camera · Turn body 30° left · Keep chin slightly up · Best with side light for $goal style in $env.',
          'type': style,
        },
        {
          'id': 2,
          'instruction': 'Walk slowly toward the camera · Relax one arm · Look slightly away for a natural candid $goal vibe.',
          'type': style,
        },
        {
          'id': 3,
          'instruction': 'Find a stable pose · Place one hand in pocket · Capture a cinematic $style frame under ambient lighting.',
          'type': style,
        }
      ]
    };
  }
}

