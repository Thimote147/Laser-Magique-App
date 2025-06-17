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
          activity:activities (
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
        .select('''
          *,
          activity:activities (
            id,
            name,
            description,
            price_per_person
          )
        ''')
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
    int? minGames,
    int? maxGames,
    bool? isGameCountFixed,
  }) async {
    final response =
        await _client
            .from('formulas')
            .insert({
              'name': name,
              'activity_id': activityId,
              'description': description,
              'price': price,
              'min_persons': minParticipants,
              'max_persons': maxParticipants,
              'default_game_count': defaultGameCount,
              'min_games': minGames,
              'max_games': maxGames,
              'is_game_count_fixed': isGameCountFixed,
            })
            .select('''
          *,
          activity:activities (
            id,
            name,
            description,
            price_per_person
          )
        ''')
            .single();

    return Formula.fromMap(response);
  }

  Future<Formula> updateFormula(Formula formula) async {
    final response =
        await _client
            .from('formulas')
            .update({
              'name': formula.name,
              'description': formula.description,
              'price': formula.price,
              'min_persons': formula.minParticipants,
              'max_persons': formula.maxParticipants,
              'default_game_count': formula.defaultGameCount,
              'min_games': formula.minGames,
              'max_games': formula.maxGames,
              'is_game_count_fixed': formula.isGameCountFixed,
            })
            .eq('id', formula.id)
            .select('''
          *,
          activities (
            id,
            name,
            description,
            price_per_person
          )
        ''')
            .single();

    final activity = response['activities'];
    response['activity'] = activity;
    return Formula.fromMap(response);
  }

  Future<void> deleteFormula(String id) async {
    await _client.from('formulas').delete().eq('id', id);
  }

  Stream<List<Formula>> streamFormulas() {
    return _client.from('formulas').stream(primaryKey: ['id']).execute().asyncMap(
      (response) async {
        // Pour chaque mise à jour du stream, on récupère les formules complètes
        return await getAllFormulas();
      },
    );
  }
}
