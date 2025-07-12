import 'package:supabase_flutter/supabase_flutter.dart';

class UserSettings {
  final String firstName;
  final String lastName;
  final String phone;
  final bool notificationsEnabled;
  final String themeMode;
  final String role;
  final bool isBlocked;

  UserSettings({
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.notificationsEnabled = true,
    this.themeMode = 'system',
    this.role = 'user',
    this.isBlocked = false,
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      phone: map['phone'] as String,
      notificationsEnabled: map['notifications_enabled'] as bool? ?? true,
      themeMode: map['theme_mode'] as String? ?? 'system',
      role: map['role'] as String? ?? 'user',
      isBlocked: map['is_blocked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'notifications_enabled': notificationsEnabled,
      'theme_mode': themeMode,
      'role': role,
      'is_blocked': isBlocked,
    };
  }
}

class UserModel {
  final String id;
  final String email;
  final DateTime createdAt;
  final DateTime? lastSignIn;
  final UserSettings? settings;

  UserModel({
    required this.id,
    required this.email,
    required this.createdAt,
    this.lastSignIn,
    this.settings,
  });

  String? get fullName =>
      settings != null ? '${settings!.firstName} ${settings!.lastName}' : null;

  factory UserModel.fromSupabaseUser(
    User user, {
    Map<String, dynamic>? settings,
  }) {
    return UserModel(
      id: user.id,
      email: user.email!,
      createdAt: DateTime.parse(user.createdAt),
      lastSignIn:
          user.lastSignInAt != null ? DateTime.parse(user.lastSignInAt!) : null,
      settings: settings != null ? UserSettings.fromMap(settings) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'last_sign_in': lastSignIn?.toIso8601String(),
    };
  }
}
