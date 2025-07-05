import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/supabase_config.dart';
import '../models/activity_model.dart';

class ActivityRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<Activity>> getAllActivities() async {
    final response = await _client.from('activities').select().order('name');

    return (response as List).map((json) => Activity.fromMap(json)).toList();
  }

  Future<Activity> createActivity({
    required String name,
    String? description,
  }) async {
    final response =
        await _client
            .from('activities')
            .insert({'name': name, 'description': description})
            .select()
            .single();

    return Activity.fromMap(response);
  }

  Future<Activity> updateActivity(Activity activity) async {
    final response =
        await _client
            .from('activities')
            .update({
              'name': activity.name,
              'description': activity.description,
            })
            .eq('id', activity.id)
            .select()
            .single();

    return Activity.fromMap(response);
  }

  Future<void> deleteActivity(String id) async {
    await _client.from('activities').delete().eq('id', id);
  }

  Stream<List<Activity>> streamActivities() {
    return _client
        .from('activities')
        .stream(primaryKey: ['id'])
        .order('name')
        .map(
          (response) =>
              (response as List).map((json) => Activity.fromMap(json)).toList(),
        );
  }
}
