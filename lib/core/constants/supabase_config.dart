import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_config.dart';

class SupabaseConfig {
  static final AppConfig _config = AppConfig();
  
  static String get url => _config.supabaseUrl;
  static String get anonKey => _config.supabaseAnonKey;
  
  static SupabaseClient get client => Supabase.instance.client;
  
  static bool get isValid => _config.isValid;
}
