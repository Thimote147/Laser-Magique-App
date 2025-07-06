import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/game_session_model.dart';

class GameSessionRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<GameSession>> getGameSessionsByBookingId(String bookingId) async {
    try {
      final response = await _supabase
          .from('game_sessions')
          .select('*')
          .eq('booking_id', bookingId)
          .order('game_number', ascending: true);

      return (response as List)
          .map((json) => GameSession.fromMap(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des sessions de jeu: $e');
    }
  }

  Future<GameSession> createGameSession(GameSession gameSession) async {
    try {
      final response = await _supabase
          .from('game_sessions')
          .insert(gameSession.toMap())
          .select()
          .single();

      return GameSession.fromMap(response);
    } catch (e) {
      throw Exception('Erreur lors de la création de la session de jeu: $e');
    }
  }

  Future<GameSession> updateGameSession(GameSession gameSession) async {
    try {
      final response = await _supabase
          .from('game_sessions')
          .update(gameSession.toMap())
          .eq('id', gameSession.id)
          .select()
          .single();

      return GameSession.fromMap(response);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la session de jeu: $e');
    }
  }

  Future<GameSession> updateParticipatingPersons(
    String sessionId,
    int participatingPersons,
    double adjustedPrice,
  ) async {
    try {
      final response = await _supabase
          .from('game_sessions')
          .update({
            'participating_persons': participatingPersons,
            'adjusted_price': adjustedPrice,
          })
          .eq('id', sessionId)
          .select()
          .single();

      return GameSession.fromMap(response);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du nombre de participants: $e');
    }
  }

  Future<GameSession> startGameSession(String sessionId) async {
    try {
      final response = await _supabase
          .from('game_sessions')
          .update({
            'start_time': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', sessionId)
          .select()
          .single();

      return GameSession.fromMap(response);
    } catch (e) {
      throw Exception('Erreur lors du démarrage de la session de jeu: $e');
    }
  }

  Future<GameSession> completeGameSession(String sessionId) async {
    try {
      final response = await _supabase
          .from('game_sessions')
          .update({
            'is_completed': true,
            'completed_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', sessionId)
          .select()
          .single();

      return GameSession.fromMap(response);
    } catch (e) {
      throw Exception('Erreur lors de la finalisation de la session de jeu: $e');
    }
  }

  Future<void> deleteGameSession(String sessionId) async {
    try {
      await _supabase
          .from('game_sessions')
          .delete()
          .eq('id', sessionId);
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la session de jeu: $e');
    }
  }

  Future<List<GameSession>> createDefaultGameSessions(
    String bookingId,
    int numberOfGames,
    int numberOfPersons,
    double pricePerPersonPerGame,
  ) async {
    try {
      final List<Map<String, dynamic>> sessions = [];
      
      for (int i = 1; i <= numberOfGames; i++) {
        sessions.add({
          'booking_id': bookingId,
          'game_number': i,
          'participating_persons': numberOfPersons,
          'adjusted_price': pricePerPersonPerGame * numberOfPersons,
          'is_completed': false,
        });
      }

      final response = await _supabase
          .from('game_sessions')
          .insert(sessions)
          .select();

      return (response as List)
          .map((json) => GameSession.fromMap(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la création des sessions de jeu par défaut: $e');
    }
  }

  Future<double> calculateTotalAdjustedPrice(String bookingId) async {
    try {
      final response = await _supabase
          .from('game_sessions')
          .select('adjusted_price')
          .eq('booking_id', bookingId);

      if (response.isEmpty) {
        return 0.0;
      }

      return (response as List)
          .map((session) => (session['adjusted_price'] as num).toDouble())
          .fold<double>(0.0, (sum, price) => sum + price);
    } catch (e) {
      throw Exception('Erreur lors du calcul du prix total ajusté: $e');
    }
  }
}