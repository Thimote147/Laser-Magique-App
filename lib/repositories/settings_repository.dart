import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SettingsRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<Map<String, dynamic>> getSettings() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return {'notifications_enabled': true, 'theme_mode': 2};
    }

    final response =
        await _client
            .from('user_settings')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

    return response ??
        {
          'notifications_enabled': true,
          'theme_mode': 2, // system
          'user_id': _client.auth.currentUser?.id,
        };
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final existingSettings =
        await _client
            .from('user_settings')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

    if (existingSettings == null) {
      await _client.from('user_settings').insert({
        ...settings,
        'user_id': userId,
      });
    } else {
      await _client
          .from('user_settings')
          .update(settings)
          .eq('user_id', userId);
    }
  }

  Stream<Map<String, dynamic>> getSettingsStream() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value({'notifications_enabled': true, 'theme_mode': 2});
    }

    return _client
        .from('user_settings')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((event) {
          if (event.isEmpty) {
            return {'notifications_enabled': true, 'theme_mode': 2};
          }
          return event.first;
        });
  }
}
