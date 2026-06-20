/// Global state management provider for the SmartShutter app.
/// Handles user preferences, premium status, setup selections, AI pose data, and photo capture history.
/// Uses Provider pattern with ChangeNotifier and SharedPreferences for persistent data storage.
/// Auth tokens stored securely in flutter_secure_storage.
/// Manages tab navigation, onboarding tracking, theme mode, and all application-wide state.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

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

  // Active Setup selections
  String _selectedGoal = 'Travel';
  String _selectedEnv = 'Outdoor City';
  String _selectedStyle = 'Full body';

  // AI poses list
  List<dynamic> _aiPoses = [];

  // Capture history list
  List<Map<String, dynamic>> _captures = [];

  // Tab navigation
  int _selectedTabIndex = 0;

  // ─── Getters ───
  bool get isPremium => _isPremium;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  bool get hasSeenPermissionsFlow => _hasSeenPermissionsFlow;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark || (_themeMode == ThemeMode.system && WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);
  String get selectedGoal => _selectedGoal;
  String get selectedEnv => _selectedEnv;
  String get selectedStyle => _selectedStyle;
  List<dynamic> get aiPoses => _aiPoses;
  List<Map<String, dynamic>> get captures => _captures;
  int get selectedTabIndex => _selectedTabIndex;

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
    
    // Load captures
    final capturesJson = _prefs?.getString('captures') ?? '[]';
    try {
      final List<dynamic> decoded = jsonDecode(capturesJson);
      _captures = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (_) {
      _captures = [];
    }

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

  // ─── Auth ───
  Future<void> setAuthTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _secureStorage.write(key: 'accessToken', value: accessToken);
    await _secureStorage.write(key: 'refreshToken', value: refreshToken);
    notifyListeners();
  }

  Future<void> setCurrentUser(Map<String, dynamic> user) async {
    _currentUser = user;
    await _secureStorage.write(key: 'currentUser', value: jsonEncode(user));
    notifyListeners();
  }

  Future<void> clearAuth() async {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
    try {
      await _secureStorage.delete(key: 'accessToken');
      await _secureStorage.delete(key: 'refreshToken');
      await _secureStorage.delete(key: 'currentUser');
    } catch (_) {}
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
    await _prefs?.setString('captures', jsonEncode(_captures));
    notifyListeners();
  }

  Future<void> deleteCapture(String id) async {
    _captures.removeWhere((item) => item['id'] == id);
    await _prefs?.setString('captures', jsonEncode(_captures));
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _captures = [];
    await _prefs?.setString('captures', '[]');
    notifyListeners();
  }
}
