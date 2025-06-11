import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Singleton pattern
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  Future<void> load() async {
    await dotenv.load(fileName: ".env");
  }

  String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  bool get isValid => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
