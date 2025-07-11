import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class AppVersion {
  final String version;
  final String buildNumber;
  final String description;
  final bool isRequired;
  final String downloadUrl;
  final DateTime releaseDate;

  const AppVersion({
    required this.version,
    required this.buildNumber,
    required this.description,
    this.isRequired = false,
    required this.downloadUrl,
    required this.releaseDate,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      version: json['version'] ?? '',
      buildNumber: json['build_number'] ?? '',
      description: json['description'] ?? '',
      isRequired: json['is_required'] ?? false,
      downloadUrl: json['download_url'] ?? '',
      releaseDate: DateTime.parse(json['release_date'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'build_number': buildNumber,
      'description': description,
      'is_required': isRequired,
      'download_url': downloadUrl,
      'release_date': releaseDate.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'AppVersion(version: $version, buildNumber: $buildNumber, description: $description)';
  }
}

class AppUpdateService extends ChangeNotifier {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  Timer? _checkTimer;
  PackageInfo? _currentPackageInfo;
  AppVersion? _latestVersion;
  bool _isCheckingForUpdates = false;
  String? _lastCheckError;

  final NotificationService _notificationService = NotificationService();

  // Configuration
  static const String _updateCheckUrl = 'https://your-update-server.com/api/latest-version';
  static const Duration _checkInterval = Duration(hours: 6); // Check every 6 hours
  static const String _dismissedVersionKey = 'dismissed_update_version';
  static const String _lastCheckKey = 'last_update_check';

  // Getters
  PackageInfo? get currentPackageInfo => _currentPackageInfo;
  AppVersion? get latestVersion => _latestVersion;
  bool get isCheckingForUpdates => _isCheckingForUpdates;
  String? get lastCheckError => _lastCheckError;
  bool get hasUpdate => _latestVersion != null && _isNewerVersion(_latestVersion!);

  /// Initialize the update service and start periodic checks
  Future<void> initialize() async {
    try {
      _currentPackageInfo = await PackageInfo.fromPlatform();
      await _checkForUpdates();
      _startPeriodicChecks();
    } catch (e) {
      debugPrint('Failed to initialize AppUpdateService: $e');
    }
  }

  /// Start periodic update checks
  void _startPeriodicChecks() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(_checkInterval, (_) => _checkForUpdates());
  }

  /// Stop periodic update checks
  void stopPeriodicChecks() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  /// Manually check for updates
  Future<bool> checkForUpdates() async {
    return await _checkForUpdates();
  }

  /// Internal method to check for updates
  Future<bool> _checkForUpdates() async {
    if (_isCheckingForUpdates || _currentPackageInfo == null) {
      return false;
    }

    _isCheckingForUpdates = true;
    _lastCheckError = null;
    notifyListeners();

    try {
      final latestVersion = await _fetchLatestVersion();
      if (latestVersion != null) {
        _latestVersion = latestVersion;
        await _saveLastCheckTime();

        // Check if this version was already dismissed
        final dismissedVersion = await _getDismissedVersion();
        final shouldNotify = _isNewerVersion(latestVersion) && 
                            dismissedVersion != latestVersion.version;

        if (shouldNotify) {
          _notificationService.notifySystemUpdate(
            latestVersion.version,
            latestVersion.description,
          );
        }

        notifyListeners();
        return _isNewerVersion(latestVersion);
      }
      return false;
    } catch (e) {
      _lastCheckError = e.toString();
      debugPrint('Error checking for updates: $e');
      notifyListeners();
      return false;
    } finally {
      _isCheckingForUpdates = false;
      notifyListeners();
    }
  }

  /// Fetch the latest version from the server
  Future<AppVersion?> _fetchLatestVersion() async {
    try {
      // In a real implementation, you would call your server API
      // For now, return a mock version for demonstration
      if (kDebugMode) {
        // Mock data for development
        return AppVersion(
          version: '2.0.0',
          buildNumber: '100',
          description: 'Nouvelles fonctionnalités Social Deal et système de notifications',
          isRequired: false,
          downloadUrl: 'https://your-app-store.com/download',
          releaseDate: DateTime.now().subtract(const Duration(days: 1)),
        );
      }

      final response = await http.get(
        Uri.parse(_updateCheckUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AppVersion.fromJson(data);
      } else {
        throw Exception('Failed to fetch update info: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Check if a version is newer than the current version
  bool _isNewerVersion(AppVersion version) {
    if (_currentPackageInfo == null) return false;

    final currentVersionParts = _currentPackageInfo!.version.split('.');
    final newVersionParts = version.version.split('.');

    for (int i = 0; i < 3; i++) {
      final currentPart = i < currentVersionParts.length 
          ? int.tryParse(currentVersionParts[i]) ?? 0 
          : 0;
      final newPart = i < newVersionParts.length 
          ? int.tryParse(newVersionParts[i]) ?? 0 
          : 0;

      if (newPart > currentPart) return true;
      if (newPart < currentPart) return false;
    }

    // If versions are equal, check build number
    final currentBuild = int.tryParse(_currentPackageInfo!.buildNumber) ?? 0;
    final newBuild = int.tryParse(version.buildNumber) ?? 0;
    return newBuild > currentBuild;
  }

  /// Mark a version as dismissed so we don't notify about it again
  Future<void> dismissUpdate(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dismissedVersionKey, version);
    } catch (e) {
      debugPrint('Failed to save dismissed version: $e');
    }
  }

  /// Get the dismissed version
  Future<String?> _getDismissedVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_dismissedVersionKey);
    } catch (e) {
      debugPrint('Failed to get dismissed version: $e');
      return null;
    }
  }

  /// Save the last check time
  Future<void> _saveLastCheckTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastCheckKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Failed to save last check time: $e');
    }
  }

  /// Get the last check time
  Future<DateTime?> getLastCheckTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeString = prefs.getString(_lastCheckKey);
      if (timeString != null) {
        return DateTime.parse(timeString);
      }
    } catch (e) {
      debugPrint('Failed to get last check time: $e');
    }
    return null;
  }

  /// Open the app store or download URL
  Future<void> openUpdateLink() async {
    if (_latestVersion?.downloadUrl.isNotEmpty == true) {
      // In a real implementation, you would use url_launcher
      // For now, just print the URL
      debugPrint('Opening update link: ${_latestVersion!.downloadUrl}');
      
      // You could also trigger an in-app browser or external browser here
      // await launchUrl(Uri.parse(_latestVersion!.downloadUrl));
    }
  }

  /// Get update information text for display
  String getUpdateInfoText() {
    if (_latestVersion == null || !hasUpdate) {
      return 'Votre application est à jour';
    }

    return 'Nouvelle version ${_latestVersion!.version} disponible\n${_latestVersion!.description}';
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }
}