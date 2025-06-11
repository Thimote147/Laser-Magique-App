import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

class SettingsViewModel with ChangeNotifier {
  static const String _notificationsKey = 'notifications_enabled';
  static const String _themeModeKey = 'theme_mode';

  bool _notificationsEnabled = true;
  AppThemeMode _themeMode = AppThemeMode.system;

  SettingsViewModel() {
    _loadPreferences();
  }

  bool get notificationsEnabled => _notificationsEnabled;
  AppThemeMode get themeMode => _themeMode;

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
    final themeModeIndex =
        prefs.getInt(_themeModeKey) ?? 2; // Default to system
    _themeMode = AppThemeMode.values[themeModeIndex];
    notifyListeners();
  }

  Future<void> toggleNotifications(bool value) async {
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
    notifyListeners();
  }
}
