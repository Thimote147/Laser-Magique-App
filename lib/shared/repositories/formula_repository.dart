import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/supabase_config.dart';
import '../models/formula_model.dart';

class FormulaRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<Formula>> getAllFormulas() async {
    try {
      final response = await _client
          .from('formulas')
          .select('''
            *,
            type,
            activity:activities (
              id,
              name,
              description
            )
          ''')
          .order('name', ascending: true);

      return (response as List).map((json) {
        return Formula.fromMap(json);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Formula>> getFormulasForActivity(String activityId) async {
    final response = await _client
        .from('formulas')
        .select('''
          *,
          type,
          activity:activities (
            id,
            name,
            description
          )
        ''')
        .eq('activity_id', activityId)
        .order('name', ascending: true);

    return (response as List).map((json) => Formula.fromMap(json)).toList();
  }

  Future<Formula> createFormula({
    required String name,
    required String activityId,
    String? description,
    required double price,
    required int minParticipants,
    int? maxParticipants,
    required int durationMinutes,
    required int minGames,
    int? maxGames,
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
              'duration_minutes': durationMinutes,
              'min_games': minGames,
              'max_games': maxGames,
            })
            .select('''
          *,
          type,
          activity:activities (
            id,
            name,
            description
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
              'duration_minutes': formula.durationMinutes,
              'min_games': formula.minGames,
              'max_games': formula.maxGames,
              'type': formula.type.name,
            })
            .eq('id', formula.id)
            .select('''
          *,
          type,
          activities (
            id,
            name,
            description
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
    return _client.from('formulas').stream(primaryKey: ['id']).asyncMap((
      response,
    ) async {
      // Pour chaque mise à jour du stream, on récupère les formules complètes
      return await getAllFormulas();
    });
  }
}
