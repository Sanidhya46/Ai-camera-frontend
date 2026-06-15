/// Global state management provider for the SmartShutter app.
/// Handles user preferences, premium status, setup selections, AI pose data, and photo capture history.
/// Uses Provider pattern with ChangeNotifier and SharedPreferences for persistent data storage.
/// Manages tab navigation, onboarding tracking, and all application-wide state that needs to be accessible across screens.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AppState extends ChangeNotifier {
  bool _isPremium = false;
  bool _hasSeenOnboarding = false;
  bool _hasSeenPermissionsFlow = false;
  SharedPreferences? _prefs;

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

  bool get isPremium => _isPremium;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  bool get hasSeenPermissionsFlow => _hasSeenPermissionsFlow;
  String get selectedGoal => _selectedGoal;
  String get selectedEnv => _selectedEnv;
  String get selectedStyle => _selectedStyle;
  List<dynamic> get aiPoses => _aiPoses;
  List<Map<String, dynamic>> get captures => _captures;
  int get selectedTabIndex => _selectedTabIndex;

  AppState();

  Future<void> init() async {
    await _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _isPremium = _prefs?.getBool('isPremium') ?? false;
    _hasSeenOnboarding = _prefs?.getBool('hasSeenOnboarding') ?? false;
    _hasSeenPermissionsFlow = _prefs?.getBool('hasSeenPermissionsFlow') ?? false;
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

  Future<void> setPremium(bool value) async {
    _isPremium = value;
    await _prefs?.setBool('isPremium', value);
    notifyListeners();
  }

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

  Future<void> addCapture({
    required String path,
    required String type, // 'passport' or 'smart_solo'
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
    
    _captures.insert(0, newCapture); // Prepend to show newest first
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

