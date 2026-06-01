import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  bool _isPremium = false;
  bool _hasSeenOnboarding = false;
  SharedPreferences? _prefs;

  bool get isPremium => _isPremium;
  bool get hasSeenOnboarding => _hasSeenOnboarding;

  AppState() {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _isPremium = _prefs?.getBool('isPremium') ?? false;
    _hasSeenOnboarding = _prefs?.getBool('hasSeenOnboarding') ?? false;
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
}
