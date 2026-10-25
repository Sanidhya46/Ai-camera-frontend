/// Global state management provider for the SmartShutter app.
/// Handles user preferences, premium status, setup selections, AI pose data, and photo capture history.
/// Uses Provider pattern with ChangeNotifier and SharedPreferences for persistent data storage.
/// Auth tokens stored securely in flutter_secure_storage.
/// Manages tab navigation, onboarding tracking, theme mode, and all application-wide state.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:async';
import 'package:smart_shutter/core/services/auth_service.dart';

class AppState extends ChangeNotifier {
  bool _isPremium = false;
  bool _hasSeenOnboarding = false;
  bool _hasSeenPermissionsFlow = false;
  ThemeMode _themeMode = ThemeMode.light; // Default: light theme
  SharedPreferences? _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Auth state
  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _currentUser;
  Timer? _refreshTimer;

  // Active Setup selections
  String _selectedGoal = 'Travel';
  String _selectedEnv = 'Outdoor City';
  String _selectedStyle = 'Full body';

  // AI poses list
  List<dynamic> _aiPoses = [];

  // Smart Solo active session state
  String? _currentSessionId;
  Map<String, dynamic>? _currentShootPlan;
  List<String> _poseSuggestions = [];
  int _uploadIntervalSeconds = 3;
  int _maxPhotos = 30;

  // Capture history list
  List<Map<String, dynamic>> _captures = [];

  // Tab navigation
  int _selectedTabIndex = 0;
  String _galleryActiveFilter = 'passport'; // 'passport' or 'smart_solo'

  // Profile photo path
  String? _profilePhotoPath;

  // ─── Getters ───
  String? get profilePhotoPath => _profilePhotoPath;
  bool get isPremium => _isPremium;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  bool get hasSeenPermissionsFlow => _hasSeenPermissionsFlow;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark || (_themeMode == ThemeMode.system && WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);
  String get selectedGoal => _selectedGoal;
  String get selectedEnv => _selectedEnv;
  String get selectedStyle => _selectedStyle;
  List<dynamic> get aiPoses => _aiPoses;
  String? get currentSessionId => _currentSessionId;
  Map<String, dynamic>? get currentShootPlan => _currentShootPlan;
  List<String> get poseSuggestions => _poseSuggestions;
  int get uploadIntervalSeconds => _uploadIntervalSeconds;
  int get maxPhotos => _maxPhotos;
  List<Map<String, dynamic>> get captures => _captures;
  int get selectedTabIndex => _selectedTabIndex;
  String get galleryActiveFilter => _galleryActiveFilter;

  // Auth getters
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoggedIn => _accessToken != null && _accessToken!.isNotEmpty;

  String get userFirstName => _currentUser?['firstName'] ?? '';
  String get userLastName => _currentUser?['lastName'] ?? '';
  String get userEmail => _currentUser?['email'] ?? '';
  String get userFullName => '${userFirstName} ${userLastName}'.trim();
  String get userInitial {
    if (userFirstName.isNotEmpty) return userFirstName[0].toUpperCase();
    if (userEmail.isNotEmpty) return userEmail[0].toUpperCase();
    return '?';
  }
  String get maskedEmail {
    final email = userEmail;
    if (email.isEmpty) return '';
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '***@$domain';
    return '${name[0]}${'*' * (name.length - 1)}@$domain';
  }
  String get memberSince {
    final createdAt = _currentUser?['createdAt'] as String?;
    if (createdAt == null) return '';
    try {
      final date = DateTime.parse(createdAt);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return '';
    }
  }

  AppState();

  Future<void> init() async {
    await _loadPrefs();
    await _loadAuthState();
    await _loadCapturesForCurrentUser();
    _startTokenRefreshTimer();
  }

  Future<void> _loadCapturesForCurrentUser() async {
    final userId = _currentUser?['id'] ?? _currentUser?['email'] ?? 'guest';
    final key = 'captures_$userId';
    final capturesJson = _prefs?.getString(key) ?? '[]';
    try {
      final List<dynamic> decoded = jsonDecode(capturesJson);
      final loaded = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      
      // Preserve and merge any captures currently in memory (e.g. from guest captures)
      if (_captures.isNotEmpty) {
        for (final cap in _captures) {
          if (!loaded.any((item) => item['id'] == cap['id'] || item['path'] == cap['path'])) {
            loaded.insert(0, cap);
          }
        }
      }
      _captures = loaded;
      await _saveCaptures();
    } catch (_) {
      if (_captures.isEmpty) {
        _captures = [];
      }
    }
  }

  Future<void> _saveCaptures() async {
    final userId = _currentUser?['id'] ?? _currentUser?['email'] ?? 'guest';
    final key = 'captures_$userId';
    await _prefs?.setString(key, jsonEncode(_captures));
  }

  Future<void> _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _isPremium = _prefs?.getBool('isPremium') ?? false;
    _hasSeenOnboarding = _prefs?.getBool('hasSeenOnboarding') ?? false;
    _hasSeenPermissionsFlow = _prefs?.getBool('hasSeenPermissionsFlow') ?? false;
    
    // Migrate old boolean to ThemeMode or read ThemeMode index
    if (_prefs?.containsKey('themeModeIndex') ?? false) {
      final index = _prefs?.getInt('themeModeIndex') ?? ThemeMode.light.index;
      _themeMode = ThemeMode.values[index];
    } else if (_prefs?.containsKey('isDarkMode') ?? false) {
      final isDark = _prefs?.getBool('isDarkMode') ?? false;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      // remove old key
      await _prefs?.remove('isDarkMode');
      await _prefs?.setInt('themeModeIndex', _themeMode.index);
    } else {
      _themeMode = ThemeMode.light; // Default as requested
    }

    _selectedGoal = _prefs?.getString('selectedGoal') ?? 'Travel';
    _selectedEnv = _prefs?.getString('selectedEnv') ?? 'Outdoor City';
    _selectedStyle = _prefs?.getString('selectedStyle') ?? 'Full body';
    _profilePhotoPath = _prefs?.getString('profilePhotoPath');

    notifyListeners();
  }

  Future<void> _loadAuthState() async {
    try {
      _accessToken = await _secureStorage.read(key: 'accessToken');
      _refreshToken = await _secureStorage.read(key: 'refreshToken');
      final userJson = await _secureStorage.read(key: 'currentUser');
      if (userJson != null && userJson.isNotEmpty) {
        _currentUser = jsonDecode(userJson) as Map<String, dynamic>;
      }
    } catch (_) {
      // Secure storage may fail on first install
    }
    notifyListeners();
  }

  // ─── Theme ───
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs?.setInt('themeModeIndex', mode.index);
    notifyListeners();
  }

  // ─── Subscription ───
  Future<void> togglePremium() async {
    _isPremium = !_isPremium;
    await _prefs?.setBool('is_premium', _isPremium);
    notifyListeners();
  }

  Future<void> setIsPremium(bool value) async {
    _isPremium = value;
    await _prefs?.setBool('is_premium', _isPremium);
    notifyListeners();
  }

  // ─── Auth ───
  Future<void> setAuthTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _secureStorage.write(key: 'accessToken', value: accessToken);
    await _secureStorage.write(key: 'refreshToken', value: refreshToken);
    _startTokenRefreshTimer();
    notifyListeners();
  }

  Future<void> setCurrentUser(Map<String, dynamic> user) async {
    _currentUser = user;
    await _secureStorage.write(key: 'currentUser', value: jsonEncode(user));
    await _loadCapturesForCurrentUser();
    notifyListeners();
  }

  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null || _refreshToken!.isEmpty) return false;
    try {
      final authService = AuthService();
      final result = await authService.refreshToken(_refreshToken!);
      if (result['success'] == true) {
        final newAccess = result['accessToken'] as String? ?? '';
        final newRefresh = result['refreshToken'] as String? ?? _refreshToken!;
        await setAuthTokens(accessToken: newAccess, refreshToken: newRefresh);
        return true;
      } else if (result['error'] != null && result['error'].toString().contains('401')) {
        await clearAuth();
      }
    } catch (e) {
      print('Error refreshing token: $e');
    }
    return false;
  }

  Future<void> clearAuth() async {
    _refreshTimer?.cancel();
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
    _captures = [];
    _aiPoses = [];
    _currentSessionId = null;
    _currentShootPlan = null;
    _poseSuggestions = [];
    await _loadCapturesForCurrentUser();
    try {
      await _secureStorage.delete(key: 'accessToken');
      await _secureStorage.delete(key: 'refreshToken');
      await _secureStorage.delete(key: 'currentUser');
    } catch (_) {}
    notifyListeners();
  }

  void _startTokenRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (_refreshToken != null && _refreshToken!.isNotEmpty) {
        print('Pre-emptively refreshing token (every 5 minutes)...');
        await refreshAccessToken();
      }
    });
  }

  void setCurrentSession({
    required String sessionId,
    required Map<String, dynamic>? shootPlan,
    required List<String> poseSuggestions,
    required int uploadIntervalSeconds,
    required int maxPhotos,
  }) {
    _currentSessionId = sessionId;
    _currentShootPlan = shootPlan;
    _poseSuggestions = poseSuggestions;
    _uploadIntervalSeconds = uploadIntervalSeconds;
    _maxPhotos = maxPhotos;
    notifyListeners();
  }

  void clearSession() {
    _currentSessionId = null;
    _currentShootPlan = null;
    _poseSuggestions = [];
    notifyListeners();
  }

  // ─── Premium ───
  Future<void> setPremium(bool value) async {
    _isPremium = value;
    await _prefs?.setBool('isPremium', value);
    notifyListeners();
  }

  // ─── Onboarding ───
  Future<void> setOnboardingSeen(bool value) async {
    _hasSeenOnboarding = value;
    await _prefs?.setBool('hasSeenOnboarding', value);
    notifyListeners();
  }

  Future<void> setPermissionsFlowSeen(bool value) async {
    _hasSeenPermissionsFlow = value;
    await _prefs?.setBool('hasSeenPermissionsFlow', value);
    notifyListeners();
  }

  // ─── Setup Options ───
  Future<void> setSetupOptions({String? goal, String? env, String? style}) async {
    if (goal != null) {
      _selectedGoal = goal;
      await _prefs?.setString('selectedGoal', goal);
    }
    if (env != null) {
      _selectedEnv = env;
      await _prefs?.setString('selectedEnv', env);
    }
    if (style != null) {
      _selectedStyle = style;
      await _prefs?.setString('selectedStyle', style);
    }
    notifyListeners();
  }

  void setAiPoses(List<dynamic> poses) {
    _aiPoses = poses;
    notifyListeners();
  }

  void setTabIndex(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  void setGalleryActiveFilter(String filter) {
    _galleryActiveFilter = filter;
    notifyListeners();
  }

  // ─── Captures ───
  Future<void> addCapture({
    required String path,
    required String type,
    required bool isCompliant,
    Map<String, dynamic>? complianceReport,
    List<String>? altPaths,
  }) async {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final serialNumber = _captures.length + 1;
    final id = '$dateStr-$serialNumber';

    final newCapture = {
      'id': id,
      'path': path,
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
      'isCompliant': isCompliant,
      'complianceReport': complianceReport ?? {},
      'altPaths': altPaths ?? [],
    };
    
    _captures.insert(0, newCapture);
    await _saveCaptures();
    notifyListeners();
  }

  Future<void> deleteCapture(String id) async {
    _captures.removeWhere((item) => item['id'] == id);
    await _saveCaptures();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _captures = [];
    await _saveCaptures();
    notifyListeners();
  }

  Future<void> setProfilePhotoPath(String? path) async {
    _profilePhotoPath = path;
    if (path != null) {
      await _prefs?.setString('profilePhotoPath', path);
    } else {
      await _prefs?.remove('profilePhotoPath');
    }
    notifyListeners();
  }
}
