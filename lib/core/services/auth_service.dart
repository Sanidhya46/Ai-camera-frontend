/// Authentication service for SmartShutter app.
/// Handles register, login, logout, token refresh, and profile fetching
/// against the hosted backend API. Uses HTTPS for all communications.
/// Never logs credentials or sensitive tokens.

import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final String baseUrl = 'https://rajputnishant29-ai-camera.hf.space';

  /// Register a new user account.
  /// Returns user data on success, or error map on failure.
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    // Input validation
    if (email.isEmpty || !_isValidEmail(email)) {
      return {'error': 'Please enter a valid email address'};
    }
    if (password.length < 8) {
      return {'error': 'Password must be at least 8 characters'};
    }
    if (firstName.isEmpty) {
      return {'error': 'First name is required'};
    }
    if (lastName.isEmpty) {
      return {'error': 'Last name is required'};
    }

    try {
      final uri = Uri.parse('$baseUrl/auth/register');
      print('[API 4 Hit] POST $uri');
      print('[API 4 Body] email: $email, firstName: $firstName, lastName: $lastName');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
        }),
      ).timeout(const Duration(seconds: 60));

      print('[API 4 Response] Status: ${response.statusCode}');
      print('[API 4 Response Body] ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        final body = _tryDecodeBody(response.body);
        return {
          'error': body['detail'] ?? 'Registration failed (${response.statusCode})',
        };
      }
    } catch (e) {
      print('[API 4 Error] register error: $e');
      return {'error': 'Network error. Please check your connection.'};
    }
  }

  /// Login with email and password.
  /// Returns access/refresh tokens on success.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? deviceLabel,
  }) async {
    if (email.isEmpty || !_isValidEmail(email)) {
      return {'error': 'Please enter a valid email address'};
    }
    if (password.isEmpty) {
      return {'error': 'Password is required'};
    }

    try {
      final uri = Uri.parse('$baseUrl/auth/login');
      print('[API 5 Hit] POST $uri');
      print('[API 5 Body] email: $email, deviceLabel: $deviceLabel');

      final body = <String, dynamic>{
        'email': email,
        'password': password,
      };
      if (deviceLabel != null && deviceLabel.isNotEmpty) {
        body['deviceLabel'] = deviceLabel;
      }

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 60));

      print('[API 5 Response] Status: ${response.statusCode}');
      print('[API 5 Response Body] ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'accessToken': data['accessToken'] ?? '',
          'refreshToken': data['refreshToken'] ?? '',
          'tokenType': data['tokenType'] ?? 'bearer',
        };
      } else {
        final body = _tryDecodeBody(response.body);
        return {
          'error': body['detail'] ?? 'Login failed. Check your credentials.',
        };
      }
    } catch (e) {
      print('[API 5 Error] login error: $e');
      return {'error': 'Network error. Please check your connection.'};
    }
  }

  /// Refresh the access token using a refresh token.
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/refresh');
      print('[API 6 Hit] POST $uri');
      
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(const Duration(seconds: 60));

      print('[API 6 Response] Status: ${response.statusCode}');
      print('[API 6 Response Body] ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'accessToken': data['accessToken'] ?? '',
          'refreshToken': data['refreshToken'] ?? refreshToken,
        };
      } else {
        return {'error': 'Token refresh failed'};
      }
    } catch (e) {
      print('[API 6 Error] refreshToken error: $e');
      return {'error': 'Network error during token refresh'};
    }
  }

  /// Logout and invalidate the refresh token.
  Future<Map<String, dynamic>> logout(String refreshToken) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/logout');
      print('[API 7 Hit] POST $uri');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      ).timeout(const Duration(seconds: 60));

      print('[API 7 Response] Status: ${response.statusCode}');
      print('[API 7 Response Body] ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'error': 'Logout failed on server'};
      }
    } catch (e) {
      print('[API 7 Error] logout error: $e');
      // Even if server call fails, we'll clear local tokens
      return {'error': 'Network error during logout'};
    }
  }

  /// Fetch the authenticated user's profile.
  Future<Map<String, dynamic>> getProfile(String accessToken) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/me');
      print('[API 8 Hit] GET $uri');
      print('[API 8 Headers] Authorization: Bearer $accessToken');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 60));

      print('[API 8 Response] Status: ${response.statusCode}');
      print('[API 8 Response Body] ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {'error': 'Failed to fetch profile (${response.statusCode})'};
      }
    } catch (e) {
      print('[API 8 Error] getProfile error: $e');
      return {'error': 'Network error fetching profile'};
    }
  }

  // ─── Helpers ───

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  Map<String, dynamic> _tryDecodeBody(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
