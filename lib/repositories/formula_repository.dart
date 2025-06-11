import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/formula_model.dart';

class FormulaRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<Formula>> getAllFormulas() async {
    final response = await _client
        .from('formulas')
        .select('''
          *,
          activities!inner (
            id,
            name,
            description,
            price_per_person
          )
        ''')
        .order('name');

    return (response as List).map((json) => Formula.fromMap(json)).toList();
  }

  Future<List<Formula>> getFormulasForActivity(String activityId) async {
    final response = await _client
        .from('formulas')
        .select('*, activities(*)')
        .eq('activity_id', activityId)
        .order('name');

    return (response as List).map((json) => Formula.fromMap(json)).toList();
  }

  Future<Formula> createFormula({
    required String name,
    required String activityId,
    String? description,
    required double price,
    int? minParticipants,
    int? maxParticipants,
    int? defaultGameCount,
  }) async {
    final response =
        await _client
            .from('formulas')
            .insert({
              'name': name,
              'activity_id': activityId,
              'description': description,
              'price': price,
              'min_participants': minParticipants,
              'max_participants': maxParticipants,
              'default_game_count': defaultGameCount,
            })
            .select('''
            *,
            activities!inner (
              id,
              name,
              description,
              price_per_person
            )
          ''')
            .maybeSingle();

    if (response == null) {
      throw Exception('Failed to create formula. The response was null.');
    }

    return Formula.fromMap(response);
  }

  Future<Formula> updateFormula(Formula formula) async {
    final response =
        await _client
            .from('formulas')
            .update({
              'name': formula.name,
              'activity_id': formula.activity.id,
              'description': formula.description,
              'price': formula.price,
              'min_participants': formula.minParticipants,
              'max_participants': formula.maxParticipants,
              'default_game_count': formula.defaultGameCount,
            })
            .eq('id', formula.id)
            .select('''
            *,
            activities!inner (
              id,
              name,
              description,
              price_per_person
            )
          ''')
            .maybeSingle();

    if (response == null) {
      throw Exception('Failed to update formula. The response was null.');
    }

    return Formula.fromMap(response);
  }

  Future<void> deleteFormula(String id) async {
    await _client.from('formulas').delete().eq('id', id);
  }

  Stream<List<Formula>> streamFormulas() {
    return _client
        .from('formulas')
        .stream(primaryKey: ['id'])
        .order('name')
        .map(
          (response) =>
              (response as List).map((json) => Formula.fromMap(json)).toList(),
        );
  }
}
