import 'package:flutter/material.dart';
import '../models/work_day_model.dart';
import '../repositories/employee_profile_repository.dart';

// Enum pour les rôles d'utilisateur
enum UserRole { admin, member }

class EmployeeProfileViewModel extends ChangeNotifier {
  final _repository = EmployeeProfileRepository();

  // État de chargement et erreur
  bool _isLoading = false;
  String? _error;

  // Informations du profil
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _phone = '';
  UserRole _role = UserRole.member;
  double _hourlyRate = 0.0;

  // Liste des jours de travail
  List<WorkDay> _workDays = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get firstName => _firstName;
  String get lastName => _lastName;
  String get fullName => '$_firstName $_lastName';
  String get email => _email;
  String get phone => _phone;
  double get hourlyRate => _hourlyRate;
  UserRole get role => _role;
  String get roleString =>
      _role == UserRole.admin ? 'Administrateur' : 'Membre';
  String get initials =>
      _firstName.isNotEmpty && _lastName.isNotEmpty
          ? '${_firstName[0]}${_lastName[0]}'.toUpperCase()
          : '';
  List<WorkDay> get workDays => List.unmodifiable(_workDays);
  String? get userId => _repository.supabase.auth.currentUser?.id;

  // Constructeur qui charge les données du profil
  EmployeeProfileViewModel() {
    _loadProfile();
  }

  // Charger les données du profil depuis la base de données
  Future<void> _loadProfile() async {
    print('Loading profile...'); // Debug log
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Charger le profil
      final profileData = await _repository.getCurrentProfile();
      print('Received profile data: $profileData'); // Debug log
      _updateFromJson(profileData);

      // Charger les jours de travail
      final workDaysData = await _repository.getWorkDays();
      _workDays.clear();
      _workDays.addAll(workDaysData);

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mettre à jour le profil
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    UserRole? role,
    double? hourlyRate,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updates = {
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (hourlyRate != null) 'hourly_rate': hourlyRate,
        if (role != null) 'role': role.toString(),
      };

      await _repository.updateProfile(updates);
      await _loadProfile(); // Recharger le profil pour avoir les données à jour
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Mettre à jour les jours de travail
  Future<void> updateWorkDays(List<WorkDay> workDays) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _repository.updateWorkDays(workDays);
      _workDays.clear();
      _workDays.addAll(workDays);

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mettre à jour le modèle à partir des données JSON
  void _updateFromJson(Map<String, dynamic> json) {
    print('Updating from JSON: $json');
    _firstName = json['first_name'] ?? '';
    _lastName = json['last_name'] ?? '';
    _phone = json['phone'] ?? '';
    _email = json['email'] ?? ''; // Email venant de l'authentification

    // Ces champs ne sont pas tous dans user_settings, donc on met des valeurs par défaut
    _role = json['user_id'] != null ? UserRole.member : UserRole.admin;
    _hourlyRate = (json['hourly_rate'] ?? 0.0).toDouble();

    print(
      'Updated values: firstName=$_firstName, lastName=$_lastName, email=$_email, phone=$_phone, hourlyRate=$_hourlyRate, role=$_role',
    ); // Debug log
  }

  // Calculer les totaux pour le mois en cours
  double get totalHoursThisMonth {
    final now = DateTime.now();
    return _workDays
        .where(
          (day) => day.date.year == now.year && day.date.month == now.month,
        )
        .fold(0.0, (sum, day) => sum + day.hours);
  }

  double get totalEarningsThisMonth {
    final now = DateTime.now();
    return _workDays
        .where(
          (day) => day.date.year == now.year && day.date.month == now.month,
        )
        .fold(0.0, (sum, day) => sum + (day.totalAmount ?? 0.0));
  }

  // Get current month earnings (adding this missing method)
  double getCurrentMonthEarnings() {
    final now = DateTime.now();
    return _workDays
        .where(
          (day) => day.date.year == now.year && day.date.month == now.month,
        )
        .fold(0.0, (sum, day) => sum + (day.totalAmount ?? 0.0));
  }

  // Méthodes pour gérer les jours de travail
  Future<void> addWorkDay(WorkDay workDay) async {
    try {
      _isLoading = true;
      notifyListeners();

      final savedWorkDay = await _repository.addWorkDay(workDay);
      _workDays.add(savedWorkDay);
      _workDays.sort((a, b) => b.date.compareTo(a.date));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateWorkDay(WorkDay workDay) async {
    try {
      _isLoading = true;
      notifyListeners();

      final updatedWorkDay = await _repository.updateWorkDay(workDay);
      final index = _workDays.indexWhere((w) => w.id == workDay.id);
      if (index >= 0) {
        _workDays[index] = updatedWorkDay;
        _workDays.sort((a, b) => b.date.compareTo(a.date));
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteWorkDay(String workDayId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _repository.deleteWorkDay(workDayId);
      _workDays.removeWhere((w) => w.id == workDayId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
