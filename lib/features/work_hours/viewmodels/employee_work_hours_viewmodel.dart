import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/work_day_model.dart';

// Cette classe gère les données et la logique pour le suivi des heures des employés
class EmployeeWorkHoursViewModel extends ChangeNotifier {
  // Client Supabase
  final _supabase = Supabase.instance.client;

  // Liste des employés avec leurs heures de travail
  final List<Map<String, dynamic>> _employees = [];

  // Date actuellement sélectionnée pour le rapport
  DateTime _selectedDate = DateTime.now();

  // Filtres appliqués
  String _searchQuery = '';
  String _roleFilter = 'Tous';

  // Options de tri
  String _sortBy = 'Heures';
  bool _sortAscending = false;

  // État de chargement
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Map<String, dynamic>> get employees {
    // Appliquer les filtres et le tri aux employés
    List<Map<String, dynamic>> filteredEmployees =
        _employees.where((employee) {
          // Filtre de recherche
          final searchMatch =
              _searchQuery.isEmpty ||
              employee['name'].toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );

          // Filtre de rôle
          final roleMatch =
              _roleFilter == 'Tous' || employee['role'] == _roleFilter;

          return searchMatch && roleMatch;
        }).toList();

    // Trier les employés
    filteredEmployees.sort((a, b) {
      dynamic valA, valB;

      switch (_sortBy) {
        case 'Heures':
          valA = a['currentMonthHours'] as double;
          valB = b['currentMonthHours'] as double;
          break;
        case 'Montant':
          valA = a['currentMonthAmount'] as double;
          valB = b['currentMonthAmount'] as double;
          break;
        case 'Nom':
          valA = a['name'] as String;
          valB = b['name'] as String;
          return _sortAscending ? valA.compareTo(valB) : valB.compareTo(valA);
        case 'Jours':
          valA = a['daysWorked'] as int;
          valB = b['daysWorked'] as int;
          break;
        default:
          valA = a['currentMonthHours'] as double;
          valB = b['currentMonthHours'] as double;
      }

      return _sortAscending ? valA.compareTo(valB) : valB.compareTo(valA);
    });

    return filteredEmployees;
  }

  DateTime get selectedDate => _selectedDate;
  String get searchQuery => _searchQuery;
  String get roleFilter => _roleFilter;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Changer la date sélectionnée
  Future<void> setSelectedDate(DateTime date) async {
    _selectedDate = date;
    await loadEmployeeData();
    notifyListeners();
  }

  // Définir la recherche
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Définir le filtre de rôle
  void setRoleFilter(String role) {
    _roleFilter = role;
    notifyListeners();
  }

  // Définir le tri
  void setSortBy(String sortBy, {bool? ascending}) {
    if (_sortBy == sortBy && ascending == null) {
      _sortAscending = !_sortAscending;
    } else {
      _sortBy = sortBy;
      _sortAscending = ascending ?? false;
    }
    notifyListeners();
  } // Charger les données des employés

  Future<void> loadEmployeeData() async {
    // Si le chargement est déjà en cours, ne pas le relancer
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Notifier du début du chargement

    try {
      // Récupérer les utilisateurs directement depuis auth.user et joindre avec user_settings
      final response = await _supabase.rpc('get_users_with_settings');

      // Récupérer le mois et l'année sélectionnés
      final month = _selectedDate.month;
      final year = _selectedDate.year;

      // Vider la liste actuelle
      _employees.clear();

      // Traiter chaque utilisateur
      for (final userData in response) {
        // Récupérer les jours de travail pour ce mois
        final workDaysResponse = await _supabase
            .from('work_days')
            .select()
            .eq('user_id', userData['id'])
            .gte('date', DateTime(year, month, 1).toIso8601String())
            .lte('date', DateTime(year, month + 1, 0).toIso8601String());

        // Calculer les heures et montants pour ce mois
        double totalHours = 0;
        double totalAmount = 0;
        final List<WorkDay> workDays = [];

        for (final workDay in workDaysResponse) {
          final day = WorkDay.fromJson(workDay);
          workDays.add(day);
          totalHours += day.hours;
          totalAmount +=
              day.totalAmount ?? (day.hours * (userData['hourly_rate'] ?? 0));
        }

        // Créer l'objet employé avec toutes les données
        final Map<String, dynamic> employee = {
          'id': userData['id'],
          'name':
              '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'
                  .trim(),
          'email': userData['email'],
          'role': _mapRoleFromDb(userData['role']),
          'hourlyRate': userData['hourly_rate'] ?? 0.0,
          'currentMonthHours': totalHours,
          'currentMonthAmount': totalAmount,
          'totalHours': totalHours,
          'totalAmount': totalAmount,
          'avatarUrl':
              userData['avatar_url'] ??
              'https://ui-avatars.com/api/?name=${Uri.encodeComponent((userData['first_name'] ?? '') + " " + (userData['last_name'] ?? ''))}&background=random',
          'daysWorked': workDays.length,
          'startDate':
              userData['created_at'] != null
                  ? _formatDate(DateTime.parse(userData['created_at']))
                  : '',
          'workDays': workDays,
        };

        _employees.add(employee);
      }

      _isLoading = false;
      notifyListeners(); // Notifier de la fin du chargement
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erreur lors du chargement des données: $e';
      notifyListeners(); // Notifier de l'erreur
    }
  }

  // Mapper les rôles de la base de données aux rôles affichés
  String _mapRoleFromDb(String? dbRole) {
    switch (dbRole) {
      case 'admin':
        return 'Administrateur';
      case 'manager':
        return 'Gérant';
      case 'member':
        return 'Membre';
      default:
        return 'Membre';
    }
  }

  // Formater une date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Obtenir les jours de travail d'un employé pour le mois sélectionné
  Future<List<WorkDay>> getEmployeeWorkDays(String employeeId) async {
    try {
      // Récupérer le mois et l'année sélectionnés
      final month = _selectedDate.month;
      final year = _selectedDate.year;

      // Récupérer les jours de travail
      final response = await _supabase
          .from('work_days')
          .select()
          .eq('user_id', employeeId)
          .gte('date', DateTime(year, month, 1).toIso8601String())
          .lte('date', DateTime(year, month + 1, 0).toIso8601String());

      // Convertir les données en objets WorkDay
      final List<WorkDay> workDays =
          response.map<WorkDay>((data) => WorkDay.fromJson(data)).toList();

      // Trier par date
      workDays.sort((a, b) => b.date.compareTo(a.date));

      return workDays;
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des jours de travail: $e',
      );
    }
  }
}
