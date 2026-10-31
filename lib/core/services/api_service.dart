/// Backend API integration service for the SmartShutter app.
/// Handles all HTTP requests to the backend including photo uploads for compliance analysis, passport photo generation, downloads, and AI pose plan generation.
/// Manages multipart file uploads, error handling, and timeouts for network operations.
/// Provides methods to communicate with the Flask/FastAPI backend for biometric analysis and image processing.

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http_parser/http_parser.dart';

class ApiService {
  // TODO: Update this to your actual backend URL
  // Example: 'https://your-backend-url.com' or 'http://192.168.x.x:8000' for local testing
  final String baseUrl = 'https://rajputnishant29-ai-camera.hf.space';

  static Future<String?> Function()? onTokenExpired;

  /// Uploads a photo to the backend, which performs biometric compliance analysis.
  /// Returns a map with 'session_id', 'is_compliant', and 'compliance_report'.
  Future<Map<String, dynamic>> uploadPhoto(String filePath, {Uint8List? bytes}) async {
    try {
      final uri = Uri.parse('$baseUrl/upload-photo/');
      print('[API 1 Hit] POST $uri');

      final request = http.MultipartRequest('POST', uri);
      
      if (kIsWeb && bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: 'capture.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            filePath,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamedResponse);

      print('[API 1 Response] Status: ${response.statusCode}');
      print('[API 1 Response Body] ${response.body}');

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
      print('[API 1 Error] uploadPhoto error: $e');
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
      print('[API 2 Hit] POST $uri');

      final response = await http.post(uri).timeout(const Duration(seconds: 120));

      print('[API 2 Response] Status: ${response.statusCode}');
      print('[API 2 Response Body] ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {
          'error': 'Server error (${response.statusCode}): ${response.body}'
        };
      }
    } catch (e) {
      print('[API 2 Error] generatePassportPhoto error: $e');
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
      print('[API 3 Hit] GET $uri');

      final response = await http.get(uri).timeout(const Duration(seconds: 120));

      print('[API 3 Response] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      print('[API 3 Error] downloadPhoto error: $e');
    }
    return null;
  }

  /// Creates a new Smart Solo session.
  /// POST /api/v1/smart-solo/sessions
  Future<Map<String, dynamic>> createSmartSoloSession(String token) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/smart-solo/sessions');
      print('[API 10 Hit] POST $uri');
      print('[API 10 Headers] Authorization: Bearer $token');
      
      var response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 120));

      print('[API 10 Response] Status: ${response.statusCode}');
      print('[API 10 Response Body] ${response.body}');

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401 && onTokenExpired != null) {
        print('[API 10 Auth] Token expired. Requesting refresh...');
        final newToken = await onTokenExpired!();
        if (newToken != null && newToken.isNotEmpty) {
          print('[API 10 Auth] Token refreshed successfully. Retrying request...');
          print('[API 10 Retry Hit] POST $uri');
          response = await http.post(
            uri,
            headers: {
              'Authorization': 'Bearer $newToken',
              'Content-Type': 'application/json',
            },
          ).timeout(const Duration(seconds: 120));
          print('[API 10 Retry Response] Status: ${response.statusCode}');
          print('[API 10 Retry Response Body] ${response.body}');
          if (response.statusCode == 201) {
            return jsonDecode(response.body) as Map<String, dynamic>;
          }
        }
      } else if (response.statusCode == 409) {
        print('[API 10 Conflict] Conflict 409: There is already an ACTIVE session on the server for this user. Automatically terminating it and retrying session creation...');
        try {
          final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
          final contextData = errorBody['context'] as Map<String, dynamic>?;
          final activeSessionId = contextData?['session_id'] as String?;

          if (activeSessionId != null && activeSessionId.isNotEmpty) {
            print('[API 10 Conflict] Active session found: $activeSessionId. Ending it first...');
            await endSmartSoloSession(token, activeSessionId);
            
            print('[API 10 Conflict] Waiting for server database to update status...');
            await Future.delayed(const Duration(milliseconds: 1000));
            
            print('[API 10 Retry Hit] POST $uri');
            response = await http.post(
              uri,
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            ).timeout(const Duration(seconds: 120));

            print('[API 10 Retry Response] Status: ${response.statusCode}');
            print('[API 10 Retry Response Body] ${response.body}');

            if (response.statusCode == 201) {
              return jsonDecode(response.body) as Map<String, dynamic>;
            }
          }
        } catch (innerException) {
          print('[API 10 Conflict Error] Error during conflict resolution: $innerException');
        }
        return {'error': 'Failed to create session: 409 (Conflict)'};
      }
      return {'error': 'Failed to create session: ${response.statusCode}'};
    } catch (e) {
      print('[API 10 Error] createSmartSoloSession error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  /// Retrieves full session details including shoot plan and live recommendations.
  /// GET /api/v1/smart-solo/sessions/{session_id}
  Future<Map<String, dynamic>> getSmartSoloSession(String token, String sessionId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/smart-solo/sessions/$sessionId');
      print('[API 12 Hit] GET $uri');
      print('[API 12 Headers] Authorization: Bearer $token');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 60));

      print('[API 12 Response] Status: ${response.statusCode}');
      print('[API 12 Response Body] ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401 && onTokenExpired != null) {
        print('[API 12 Auth] Token expired. Requesting refresh...');
        final newToken = await onTokenExpired!();
        if (newToken != null && newToken.isNotEmpty) {
          print('[API 12 Auth] Token refreshed successfully. Retrying request...');
          print('[API 12 Retry Hit] GET $uri');
          final response2 = await http.get(
            uri,
            headers: {
              'Authorization': 'Bearer $newToken',
            },
          ).timeout(const Duration(seconds: 60));
          print('[API 12 Retry Response] Status: ${response2.statusCode}');
          print('[API 12 Retry Response Body] ${response2.body}');
          if (response2.statusCode == 200) {
            return jsonDecode(response2.body) as Map<String, dynamic>;
          }
          return {'error': 'Failed to fetch session: ${response2.statusCode}'};
        }
      }
      return {'error': 'Failed to fetch session: ${response.statusCode}'};
    } catch (e) {
      print('[API 12 Error] getSmartSoloSession error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  /// Uploads a photo to an active Smart Solo session.
  /// POST /api/v1/smart-solo/sessions/{session_id}/photos
  Future<Map<String, dynamic>> uploadSmartSoloPhoto(
    String token,
    String sessionId,
    String filePath, {
    Uint8List? bytes,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/smart-solo/sessions/$sessionId/photos');
      print('[API 15 Hit] POST $uri');
      print('[API 15 Headers] Authorization: Bearer $token');

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      if (kIsWeb) {
        if (bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'file',
              bytes,
              filename: 'frame.jpg',
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        } else {
          print('[API 15 Error] uploadSmartSoloPhoto error: bytes is null on Web');
          return {'error': 'Bytes parameter is required on Web platform.'};
        }
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            filePath,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamedResponse);

      print('[API 15 Response] Status: ${response.statusCode}');
      print('[API 15 Response Body] ${response.body}');

      if (response.statusCode == 202) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 409) {
        print('[API 15 Conflict] Conflict 409: Photo upload rejected by server because session is not ACTIVE (it is currently in ENDING, COMPLETED, or FAILED status).');
      } else if (response.statusCode == 401 && onTokenExpired != null) {
        print('[API 15 Auth] Token expired. Requesting refresh...');
        final newToken = await onTokenExpired!();
        if (newToken != null && newToken.isNotEmpty) {
          print('[API 15 Auth] Token refreshed successfully. Retrying upload...');
          print('[API 15 Retry Hit] POST $uri');
          final request2 = http.MultipartRequest('POST', uri);
          request2.headers['Authorization'] = 'Bearer $newToken';
          if (kIsWeb) {
            if (bytes != null) {
              request2.files.add(
                http.MultipartFile.fromBytes(
                  'file',
                  bytes,
                  filename: 'frame.jpg',
                  contentType: MediaType('image', 'jpeg'),
                ),
              );
            }
          } else {
            request2.files.add(
              await http.MultipartFile.fromPath(
                'file',
                filePath,
                contentType: MediaType('image', 'jpeg'),
              ),
            );
          }
          final streamedResponse2 = await request2.send().timeout(const Duration(seconds: 120));
          final response2 = await http.Response.fromStream(streamedResponse2);
          print('[API 15 Retry Response] Status: ${response2.statusCode}');
          print('[API 15 Retry Response Body] ${response2.body}');
          if (response2.statusCode == 202) {
            return jsonDecode(response2.body) as Map<String, dynamic>;
          }
          return {'error': 'Failed to upload photo: ${response2.statusCode}'};
        }
      }
      return {'error': 'Failed to upload photo: ${response.statusCode}'};
    } catch (e) {
      print('[API 15 Error] uploadSmartSoloPhoto error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  /// Gets photo counts for a session.
  /// GET /api/v1/smart-solo/sessions/{session_id}/photo-counts
  Future<Map<String, dynamic>> getPhotoCounts(String token, String sessionId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/smart-solo/sessions/$sessionId/photo-counts');
      print('[API 14 Hit] GET $uri');
      print('[API 14 Headers] Authorization: Bearer $token');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 60));

      print('[API 14 Response] Status: ${response.statusCode}');
      print('[API 14 Response Body] ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401 && onTokenExpired != null) {
        print('[API 14 Auth] Token expired. Requesting refresh...');
        final newToken = await onTokenExpired!();
        if (newToken != null && newToken.isNotEmpty) {
          print('[API 14 Auth] Token refreshed successfully. Retrying request...');
          print('[API 14 Retry Hit] GET $uri');
          final response2 = await http.get(
            uri,
            headers: {
              'Authorization': 'Bearer $newToken',
            },
          ).timeout(const Duration(seconds: 60));
          if (response2.statusCode == 200) {
            return jsonDecode(response2.body) as Map<String, dynamic>;
          }
          return {'error': 'Failed to get photo counts: ${response2.statusCode}'};
        }
      }
      return {'error': 'Failed to get photo counts: ${response.statusCode}'};
    } catch (e) {
      print('getPhotoCounts error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  /// Retrieves individual photo AI scores.
  /// GET /api/v1/smart-solo/sessions/{session_id}/photos/{photo_id}
  Future<Map<String, dynamic>> getSmartSoloPhoto(String token, String sessionId, String photoId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/smart-solo/sessions/$sessionId/photos/$photoId');
      print('[API 16 Hit] GET $uri');
      print('[API 16 Headers] Authorization: Bearer $token');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 120));

      print('[API 16 Response] Status: ${response.statusCode}');
      print('[API 16 Response Body] ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401 && onTokenExpired != null) {
        print('[API 16 Auth] Token expired. Requesting refresh...');
        final newToken = await onTokenExpired!();
        if (newToken != null && newToken.isNotEmpty) {
          print('[API 16 Auth] Token refreshed successfully. Retrying request...');
          print('[API 16 Retry Hit] GET $uri');
          final response2 = await http.get(
            uri,
            headers: {
              'Authorization': 'Bearer $newToken',
            },
          ).timeout(const Duration(seconds: 120));
          print('[API 16 Retry Response] Status: ${response2.statusCode}');
          print('[API 16 Retry Response Body] ${response2.body}');
          if (response2.statusCode == 200) {
            return jsonDecode(response2.body) as Map<String, dynamic>;
          }
          return {'error': 'Failed to get photo detail: ${response2.statusCode}'};
        }
      }
      return {'error': 'Failed to get photo detail: ${response.statusCode}'};
    } catch (e) {
      print('[API 16 Error] getSmartSoloPhoto error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  /// Ends a Smart Solo session.
  /// POST /api/v1/smart-solo/sessions/{session_id}/end
  Future<Map<String, dynamic>> endSmartSoloSession(String token, String sessionId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/smart-solo/sessions/$sessionId/end');
      print('[API 13 Hit] POST $uri');
      print('[API 13 Headers] Authorization: Bearer $token');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 120));

      print('[API 13 Response] Status: ${response.statusCode}');
      print('[API 13 Response Body] ${response.body}');

      if (response.statusCode == 202) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 409) {
        print('[API 13 Conflict] Conflict 409: Session termination failed because the session has already been finalized or ended.');
      } else if (response.statusCode == 401 && onTokenExpired != null) {
        print('[API 13 Auth] Token expired. Requesting refresh...');
        final newToken = await onTokenExpired!();
        if (newToken != null && newToken.isNotEmpty) {
          print('[API 13 Auth] Token refreshed successfully. Retrying request...');
          print('[API 13 Retry Hit] POST $uri');
          final response2 = await http.post(
            uri,
            headers: {
              'Authorization': 'Bearer $newToken',
              'Content-Type': 'application/json',
            },
          ).timeout(const Duration(seconds: 120));
          print('[API 13 Retry Response] Status: ${response2.statusCode}');
          print('[API 13 Retry Response Body] ${response2.body}');
          if (response2.statusCode == 202) {
            return jsonDecode(response2.body) as Map<String, dynamic>;
          }
          return {'error': 'Failed to end session: ${response2.statusCode}'};
        }
      }
      return {'error': 'Failed to end session: ${response.statusCode}'};
    } catch (e) {
      print('[API 13 Error] endSmartSoloSession error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  /// Retrieves finalized session result.
  /// GET /api/v1/smart-solo/sessions/{session_id}/result
  /// Returns 404 while session is not completed.
  Future<Map<String, dynamic>> getSmartSoloResult(String token, String sessionId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/smart-solo/sessions/$sessionId/result');
      print('[API 17 Hit] GET $uri');
      print('[API 17 Headers] Authorization: Bearer $token');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 60));

      print('[API 17 Response] Status: ${response.statusCode}');
      print('[API 17 Response Body] ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401 && onTokenExpired != null) {
        print('[API 17 Auth] Token expired. Requesting refresh...');
        final newToken = await onTokenExpired!();
        if (newToken != null && newToken.isNotEmpty) {
          print('[API 17 Auth] Token refreshed successfully. Retrying request...');
          print('[API 17 Retry Hit] GET $uri');
          final response2 = await http.get(
            uri,
            headers: {
              'Authorization': 'Bearer $newToken',
            },
          ).timeout(const Duration(seconds: 60));
          print('[API 17 Retry Response] Status: ${response2.statusCode}');
          print('[API 17 Retry Response Body] ${response2.body}');
          if (response2.statusCode == 200) {
            return jsonDecode(response2.body) as Map<String, dynamic>;
          } else if (response2.statusCode == 404) {
            return {'status': 'processing'};
          }
          return {'error': 'Failed to get result: ${response2.statusCode}'};
        }
      } else if (response.statusCode == 404) {
        return {'status': 'processing'};
      }
      return {'error': 'Failed to get result: ${response.statusCode}'};
    } catch (e) {
      print('[API 17 Error] getSmartSoloResult error: $e');
      return {'error': 'Network error: $e'};
    }
  }

  /// Fetches paginated session history for the user.
  /// GET /api/v1/smart-solo/sessions
  Future<Map<String, dynamic>> getSmartSoloSessions(String token) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/smart-solo/sessions');
      print('[API 11 Hit] GET $uri');
      print('[API 11 Headers] Authorization: Bearer $token');

      var response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 60));

      print('[API 11 Response] Status: ${response.statusCode}');
      print('[API 11 Response Body] ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401 && onTokenExpired != null) {
        print('[API 11 Auth] Token expired. Requesting refresh...');
        final newToken = await onTokenExpired!();
        if (newToken != null && newToken.isNotEmpty) {
          print('[API 11 Auth] Token refreshed successfully. Retrying request...');
          print('[API 11 Retry Hit] GET $uri');
          final response2 = await http.get(
            uri,
            headers: {
              'Authorization': 'Bearer $newToken',
            },
          ).timeout(const Duration(seconds: 60));
          print('[API 11 Retry Response] Status: ${response2.statusCode}');
          print('[API 11 Retry Response Body] ${response2.body}');
          if (response2.statusCode == 200) {
            return jsonDecode(response2.body) as Map<String, dynamic>;
          }
        }
      }
      return {'error': 'Failed to fetch session history: ${response.statusCode}'};
    } catch (e) {
      print('[API 11 Error] getSmartSoloSessions error: $e');
      return {'error': 'Network error: $e'};
    }
  }
}

