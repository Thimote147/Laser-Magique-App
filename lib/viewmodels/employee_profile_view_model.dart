import 'package:flutter/material.dart';
import '../models/work_day_model.dart';

// Enum pour les rôles d'utilisateur
enum UserRole { admin, member }

class EmployeeProfileViewModel extends ChangeNotifier {
  // Informations du profil
  String _firstName = 'Jean';
  String _lastName = 'Dupont';
  String _email = 'jean.dupont@lasermagique.com';
  String _phone = '06 12 34 56 78';
  double _hourlyRate = 12.50; // Taux horaire en euros
  UserRole _role = UserRole.admin; // Rôle par défaut

  // Liste des jours de travail
  final List<WorkDay> _workDays = [];

  // Getters
  String get firstName => _firstName;
  String get lastName => _lastName;
  String get fullName => '$_firstName $_lastName';
  String get email => _email;
  String get phone => _phone;
  double get hourlyRate => _hourlyRate;
  UserRole get role => _role;
  String get roleString =>
      _role == UserRole.admin ? 'Administrateur' : 'Membre';
  List<WorkDay> get workDays => List.unmodifiable(_workDays);

  // Constructeur qui charge les données de test
  EmployeeProfileViewModel() {
    _loadDummyData();
  }

  // Méthode pour mettre à jour les informations du profil
  void updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    double? hourlyRate,
    UserRole? role,
  }) {
    bool hasChanges = false;

    if (firstName != null && firstName != _firstName) {
      _firstName = firstName;
      hasChanges = true;
    }

    if (lastName != null && lastName != _lastName) {
      _lastName = lastName;
      hasChanges = true;
    }

    if (email != null && email != _email) {
      _email = email;
      hasChanges = true;
    }

    if (phone != null && phone != _phone) {
      _phone = phone;
      hasChanges = true;
    }

    if (hourlyRate != null && hourlyRate != _hourlyRate) {
      _hourlyRate = hourlyRate;
      hasChanges = true;
    }

    if (role != null && role != _role) {
      _role = role;
      hasChanges = true;
    }

    if (hasChanges) {
      notifyListeners();
    }
  }

  // Ajouter un jour de travail
  void addWorkDay(WorkDay workDay) {
    _workDays.add(workDay);
    _workDays.sort(
      (a, b) => b.date.compareTo(a.date),
    ); // Tri par date décroissante
    notifyListeners();
  }

  // Supprimer un jour de travail
  void removeWorkDay(String id) {
    _workDays.removeWhere((day) => day.id == id);
    notifyListeners();
  }

  // Calculer les gains du mois en cours
  double getCurrentMonthEarnings() {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    return _workDays
        .where(
          (day) =>
              day.date.month == currentMonth && day.date.year == currentYear,
        )
        .fold(
          0.0,
          (sum, day) =>
              sum + (day.totalAmount ?? day.calculateAmount(_hourlyRate)),
        );
  }

  // Méthode pour charger des données de test
  void _loadDummyData() {
    final now = DateTime.now();

    // Ajouter quelques jours de travail de test
    _workDays.addAll([
      WorkDay(
        id: '1',
        date: DateTime(now.year, now.month, now.day - 1),
        startTime: DateTime(now.year, now.month, now.day - 1, 9, 0),
        endTime: DateTime(now.year, now.month, now.day - 1, 17, 0),
        hoursWorked: 8.0,
        totalAmount: 8.0 * _hourlyRate,
      ),
      WorkDay(
        id: '2',
        date: DateTime(now.year, now.month, now.day - 3),
        startTime: DateTime(now.year, now.month, now.day - 3, 14, 0),
        endTime: DateTime(now.year, now.month, now.day - 3, 22, 0),
        hoursWorked: 8.0,
        totalAmount: 8.0 * _hourlyRate,
      ),
      WorkDay(
        id: '3',
        date: DateTime(now.year, now.month, now.day - 5),
        startTime: DateTime(now.year, now.month, now.day - 5, 10, 0),
        endTime: DateTime(now.year, now.month, now.day - 5, 18, 30),
        hoursWorked: 8.5,
        totalAmount: 8.5 * _hourlyRate,
      ),
      WorkDay(
        id: '4',
        date: DateTime(now.year, now.month - 1, 28),
        startTime: DateTime(now.year, now.month - 1, 28, 9, 0),
        endTime: DateTime(now.year, now.month - 1, 28, 16, 0),
        hoursWorked: 7.0,
        totalAmount: 7.0 * _hourlyRate,
      ),
    ]);

    // Trier par date décroissante
    _workDays.sort((a, b) => b.date.compareTo(a.date));
  }
}
