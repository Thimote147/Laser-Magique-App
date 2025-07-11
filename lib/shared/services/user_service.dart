import 'package:supabase_flutter/supabase_flutter.dart';

/// Service pour récupérer les informations des utilisateurs
/// Centralise la logique de récupération des noms d'utilisateurs pour les notifications
class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Cache pour éviter les requêtes répétitives
  final Map<String, String> _userNamesCache = {};

  /// Récupère le nom complet d'un utilisateur par son ID
  Future<String> getUserFullName(String userId) async {
    // Vérifier le cache en premier
    if (_userNamesCache.containsKey(userId)) {
      return _userNamesCache[userId]!;
    }

    try {
      final response = await _supabase
          .from('user_settings')
          .select('first_name, last_name')
          .eq('user_id', userId)
          .single();

      final firstName = response['first_name'] as String? ?? '';
      final lastName = response['last_name'] as String? ?? '';
      
      String fullName;
      if (firstName.isEmpty && lastName.isEmpty) {
        fullName = 'Utilisateur inconnu';
      } else {
        fullName = '$firstName $lastName'.trim();
      }

      // Mettre en cache le résultat
      _userNamesCache[userId] = fullName;
      return fullName;
    } catch (e) {
      // En cas d'erreur, retourner un nom par défaut
      final fallbackName = 'Utilisateur ($userId)';
      _userNamesCache[userId] = fallbackName;
      return fallbackName;
    }
  }

  /// Récupère les noms de plusieurs utilisateurs par leurs IDs
  Future<Map<String, String>> getMultipleUserNames(List<String> userIds) async {
    if (userIds.isEmpty) return {};
    
    final Map<String, String> result = {};
    final List<String> uncachedUserIds = [];

    // Vérifier le cache pour chaque utilisateur
    for (final userId in userIds) {
      if (_userNamesCache.containsKey(userId)) {
        result[userId] = _userNamesCache[userId]!;
      } else {
        uncachedUserIds.add(userId);
      }
    }

    // Récupérer les utilisateurs non mis en cache
    if (uncachedUserIds.isNotEmpty) {
      try {
        final response = await _supabase
            .from('user_settings')
            .select('user_id, first_name, last_name')
            .inFilter('user_id', uncachedUserIds);

        for (final user in response) {
          final userId = user['user_id'] as String;
          final firstName = user['first_name'] as String? ?? '';
          final lastName = user['last_name'] as String? ?? '';
          
          String fullName;
          if (firstName.isEmpty && lastName.isEmpty) {
            fullName = 'Utilisateur inconnu';
          } else {
            fullName = '$firstName $lastName'.trim();
          }

          result[userId] = fullName;
          _userNamesCache[userId] = fullName;
        }
        
        // Ajouter les utilisateurs non trouvés
        for (final userId in uncachedUserIds) {
          if (!result.containsKey(userId)) {
            final fallbackName = 'Utilisateur ($userId)';
            result[userId] = fallbackName;
            _userNamesCache[userId] = fallbackName;
          }
        }
      } catch (e) {
        // En cas d'erreur, retourner des noms par défaut
        for (final userId in uncachedUserIds) {
          final fallbackName = 'Utilisateur ($userId)';
          result[userId] = fallbackName;
          _userNamesCache[userId] = fallbackName;
        }
      }
    }
    
    return result;
  }

  /// Récupère le nom de l'utilisateur actuel
  Future<String> getCurrentUserFullName() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      return 'Utilisateur non connecté';
    }
    
    return getUserFullName(currentUser.id);
  }

  /// Vide le cache des noms d'utilisateurs
  void clearCache() {
    _userNamesCache.clear();
  }

  /// Supprime un utilisateur spécifique du cache
  void clearUserFromCache(String userId) {
    _userNamesCache.remove(userId);
  }
}