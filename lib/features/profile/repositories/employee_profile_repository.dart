import 'package:supabase_flutter/supabase_flutter.dart';
import '../../work_hours/models/work_day_model.dart';

class EmployeeProfileRepository {
  final supabase = Supabase.instance.client;

  /// Récupère le profil de l'utilisateur connecté
  Future<Map<String, dynamic>> getCurrentProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Vous devez être connecté pour accéder à votre profil');
      }

      final response =
          await supabase
              .from('user_settings')
              .select()
              .eq('user_id', user.id)
              .single();

      // Ajouter l'email depuis l'authentification aux données du profil
      final dataWithEmail = {
        ...response,
        'email': user.email,
      };

      return dataWithEmail;
    } catch (e) {
      throw Exception('Impossible de récupérer votre profil : ${e.toString()}');
    }
  }

  /// Met à jour le profil de l'utilisateur
  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception(
          'Vous devez être connecté pour mettre à jour votre profil',
        );
      }

      await supabase.from('user_settings').update(data).eq('user_id', user.id);
    } catch (e) {
      throw Exception(
        'Impossible de mettre à jour votre profil : ${e.toString()}',
      );
    }
  }

  /// Récupère tous les jours de travail de l'utilisateur
  Future<List<WorkDay>> getWorkDays() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception(
          'Vous devez être connecté pour accéder à vos jours de travail',
        );
      }

      final response = await supabase
          .from('work_days')
          .select()
          .eq('user_id', user.id);

      return (response as List).map((data) => WorkDay.fromJson(data)).toList();
    } catch (e) {
      throw Exception(
        'Impossible de récupérer vos jours de travail : ${e.toString()}',
      );
    }
  }

  /// Met à jour la liste complète des jours de travail
  Future<void> updateWorkDays(List<WorkDay> workDays) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception(
          'Vous devez être connecté pour mettre à jour vos jours de travail',
        );
      }

      // Supprimer les anciens jours
      await supabase.from('work_days').delete().eq('user_id', user.id);

      // Insérer les nouveaux jours
      if (workDays.isNotEmpty) {
        final workDaysData =
            workDays
                .map((day) => {...day.toJson(), 'employee_id': user.id})
                .toList();
        await supabase.from('work_days').insert(workDaysData);
      }
    } catch (e) {
      throw Exception(
        'Impossible de mettre à jour vos jours de travail : ${e.toString()}',
      );
    }
  }

  /// Ajoute un nouveau jour de travail
  Future<WorkDay> addWorkDay(WorkDay workDay) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception(
          'Vous devez être connecté pour ajouter un jour de travail',
        );
      }

      final data = {...workDay.toJson(), 'user_id': user.id};

      final response =
          await supabase.from('work_days').insert(data).select().single();

      return WorkDay.fromJson(response);
    } catch (e) {
      throw Exception(
        'Impossible d\'ajouter le jour de travail : ${e.toString()}',
      );
    }
  }

  /// Met à jour un jour de travail existant
  Future<WorkDay> updateWorkDay(WorkDay workDay) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception(
          'Vous devez être connecté pour modifier un jour de travail',
        );
      }

      final data = {...workDay.toJson(), 'user_id': user.id};

      final response =
          await supabase
              .from('work_days')
              .update(data)
              .eq('id', workDay.id)
              .select()
              .single();

      return WorkDay.fromJson(response);
    } catch (e) {
      throw Exception(
        'Impossible de modifier le jour de travail : ${e.toString()}',
      );
    }
  }

  /// Supprime un jour de travail
  Future<void> deleteWorkDay(String id) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception(
          'Vous devez être connecté pour supprimer un jour de travail',
        );
      }

      await supabase
          .from('work_days')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception(
        'Impossible de supprimer le jour de travail : ${e.toString()}',
      );
    }
  }
}
