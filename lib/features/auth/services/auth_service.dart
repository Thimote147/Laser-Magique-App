import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/supabase_config.dart';
import '../../profile/models/user_model.dart';

class AuthService {
  final _supabase = SupabaseConfig.client;

  Future<UserModel?> _getUserWithSettings(User user) async {
    try {
      // S'assurer que les user_settings existent
      await _ensureUserSettingsExist(user);

      final settings =
          await _supabase
              .from('user_settings')
              .select()
              .eq('user_id', user.id)
              .single();
      developer.log('Settings récupérés pour l\'utilisateur \\${user.id}');
      return UserModel.fromSupabaseUser(user, settings: settings);
    } catch (e) {
      developer.log('Erreur lors de la récupération des settings: $e');
      return UserModel.fromSupabaseUser(user);
    }
  }

  Future<UserModel?> get currentUserWithSettings async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return _getUserWithSettings(user);
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<void> _createUserSettings({
    required String userId,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      developer.log(
        'Début de création des user_settings pour l\'utilisateur $userId',
      );

      final response =
          await _supabase
              .from('user_settings')
              .insert({
                'user_id': userId,
                'first_name': firstName,
                'last_name': lastName,
                'phone': phone,
                'role': 'member',
              })
              .select()
              .single();

      developer.log('User settings créés avec succès: $response');
    } catch (e, stackTrace) {
      developer.log(
        'Erreur lors de la création des user_settings',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Erreur lors de la création du profil: $e');
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      developer.log('Début du processus d\'inscription pour $email');

      // 1. Créer le compte utilisateur
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'phone': phone,
          'pending_settings_creation': true,
        },
      );

      developer.log(
        'Réponse de signUp: user=${authResponse.user != null}, session=${authResponse.session != null}',
      );

      if (authResponse.user == null) {
        throw Exception('L\'inscription a échoué: pas d\'utilisateur créé');
      }

      developer.log('Utilisateur créé avec l\'ID: ${authResponse.user!.id}');

      // L'inscription est réussie, mais l'utilisateur doit confirmer son email
      developer.log('Un email de confirmation a été envoyé à $email');
      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Erreur lors de l\'inscription',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Cette méthode sera appelée après la confirmation de l'email
  Future<void> completeUserSetup(User user) async {
    try {
      // Vérifier si les settings sont en attente de création
      if (user.userMetadata?['pending_settings_creation'] == true) {
        await _createUserSettings(
          userId: user.id,
          firstName: user.userMetadata?['first_name'] ?? '',
          lastName: user.userMetadata?['last_name'] ?? '',
          phone: user.userMetadata?['phone'] ?? '',
        );

        // Mettre à jour les métadonnées pour indiquer que les settings sont créés
        await _supabase.auth.updateUser(
          UserAttributes(
            data: {
              ...user.userMetadata ?? {},
              'pending_settings_creation': false,
            },
          ),
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Erreur lors de la finalisation du profil',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Erreur lors de la finalisation du profil: $e');
    }
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      developer.log('Tentative de connexion pour $email');
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        developer.log('Connexion réussie pour ${response.user!.id}');

        // Vérifier et compléter la configuration si nécessaire
        if (response.user!.userMetadata?['pending_settings_creation'] == true) {
          await completeUserSetup(response.user!);
        }

        return _getUserWithSettings(response.user!);
      }

      developer.log('Connexion échouée: pas d\'utilisateur retourné');
      return null;
    } catch (e, stackTrace) {
      developer.log(
        'Erreur lors de la connexion',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> _ensureUserSettingsExist(User user) async {
    try {
      // Vérifie si l'utilisateur a déjà des settings
      final existing =
          await _supabase
              .from('user_settings')
              .select()
              .eq('user_id', user.id)
              .maybeSingle();

      if (existing == null) {
        // Si aucun setting n'existe, créer avec des valeurs par défaut
        await _supabase.from('user_settings').insert({
          'user_id': user.id,
          'first_name': user.userMetadata?['first_name'] ?? '',
          'last_name': user.userMetadata?['last_name'] ?? '',
          'phone': user.phone ?? '',
          'notifications_enabled': true,
          'theme_mode': 'system',
          'role': 'member',
        });
        developer.log('User settings créés pour ${user.id}');
      }
    } catch (e) {
      developer.log(
        'Erreur lors de la vérification/création des user_settings: $e',
      );
      rethrow;
    }
  }
}
