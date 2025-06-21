import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/settings_repository.dart';

enum AppThemeMode { light, dark, system }

class SettingsViewModel with ChangeNotifier {
  final SettingsRepository _repository = SettingsRepository();
  bool _isLoading = false;
  String? _error;

  bool _notificationsEnabled = true;
  AppThemeMode _themeMode = AppThemeMode.system;

  SettingsViewModel() {
    _initializeSettings();
  }

  bool get notificationsEnabled => _notificationsEnabled;
  AppThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _initializeSettings() {
    // First load from local storage for immediate UI response
    _loadLocalPreferences();

    // Then subscribe to remote changes
    _repository.getSettingsStream().listen(
      (settings) {
        _updateFromRemote(settings);
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  Future<void> _loadLocalPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      final themeModeIndex =
          prefs.getInt('theme_mode') ?? 2; // Default to system
      _themeMode = AppThemeMode.values[themeModeIndex];
      notifyListeners();

      // Load remote settings
      _isLoading = true;
      notifyListeners();

      final remoteSettings = await _repository.getSettings();
      _updateFromRemote(remoteSettings);
      _saveToLocalPreferences();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateFromRemote(Map<String, dynamic> settings) {
    _notificationsEnabled = settings['notifications_enabled'] ?? true;

    // Gérer la conversion du theme_mode
    final themeModeSetting = settings['theme_mode'];
    if (themeModeSetting != null) {
      if (themeModeSetting is int) {
        _themeMode = AppThemeMode.values[themeModeSetting];
      } else if (themeModeSetting is String) {
        // Si c'est une chaîne, essayons de la convertir en entier
        try {
          _themeMode = AppThemeMode.values[int.parse(themeModeSetting)];
        } catch (e) {
          // Si la conversion échoue, utiliser la valeur par défaut (system)
          _themeMode = AppThemeMode.system;
        }
      } else {
        // Si le type n'est ni int ni String, utiliser la valeur par défaut
        _themeMode = AppThemeMode.system;
      }
    } else {
      // Si pas de valeur, utiliser la valeur par défaut
      _themeMode = AppThemeMode.system;
    }

    _saveToLocalPreferences();
    notifyListeners();
  }

  Future<void> _saveToLocalPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setInt('theme_mode', _themeMode.index);
  }

  Future<void> toggleNotifications(bool value) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.updateSettings({
        'notifications_enabled': value,
        'theme_mode': _themeMode.index,
      });

      _notificationsEnabled = value;
      await _saveToLocalPreferences();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.updateSettings({
        'notifications_enabled': _notificationsEnabled,
        'theme_mode': mode.index,
      });

      _themeMode = mode;
      await _saveToLocalPreferences();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
