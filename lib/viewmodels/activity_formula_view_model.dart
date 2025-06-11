import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/activity_model.dart';
import '../models/formula_model.dart';

class ActivityFormulaViewModel extends ChangeNotifier {
  // Liste des activités disponibles
  final List<Activity> _activities = [];

  // Liste des formules disponibles
  final List<Formula> _formulas = [];

  // Getters pour accéder aux listes
  List<Activity> get activities => List.unmodifiable(_activities);
  List<Formula> get formulas => List.unmodifiable(_formulas);

  // Méthode pour ajouter une activité
  void addActivity({
    required String name,
    String? description,
    double? pricePerPerson,
  }) {
    final activity = Activity(
      id: const Uuid().v4(),
      name: name,
      description: description,
      pricePerPerson: pricePerPerson,
    );

    _activities.add(activity);
    notifyListeners();
  }

  // Méthode pour ajouter une formule
  void addFormula({
    required String name,
    String? description,
    required Activity activity,
    required double price,
    int? minParticipants,
    int? maxParticipants,
    int? defaultGameCount,
  }) {
    final formula = Formula(
      id: const Uuid().v4(),
      name: name,
      description: description,
      activity: activity,
      price: price,
      minParticipants: minParticipants,
      maxParticipants: maxParticipants,
      defaultGameCount: defaultGameCount,
    );

    _formulas.add(formula);
    notifyListeners();
  }

  // Méthode pour supprimer une activité
  void removeActivity(String activityId) {
    _activities.removeWhere((activity) => activity.id == activityId);

    // Supprimer également toutes les formules liées à cette activité
    _formulas.removeWhere((formula) => formula.activity.id == activityId);

    notifyListeners();
  }

  // Méthode pour supprimer une formule
  void removeFormula(String formulaId) {
    _formulas.removeWhere((formula) => formula.id == formulaId);
    notifyListeners();
  }

  // Méthode pour mettre à jour une activité
  void updateActivity(Activity updatedActivity) {
    final index = _activities.indexWhere(
      (activity) => activity.id == updatedActivity.id,
    );

    if (index != -1) {
      _activities[index] = updatedActivity;

      // Mettre à jour les formules qui utilisent cette activité
      for (int i = 0; i < _formulas.length; i++) {
        if (_formulas[i].activity.id == updatedActivity.id) {
          _formulas[i] = _formulas[i].copyWith(activity: updatedActivity);
        }
      }

      notifyListeners();
    }
  }

  // Méthode pour mettre à jour une formule
  void updateFormula(Formula updatedFormula) {
    final index = _formulas.indexWhere(
      (formula) => formula.id == updatedFormula.id,
    );

    if (index != -1) {
      _formulas[index] = updatedFormula;
      notifyListeners();
    }
  }

  // Méthode pour récupérer les formules d'une activité spécifique
  List<Formula> getFormulasForActivity(String activityId) {
    return _formulas
        .where((formula) => formula.activity.id == activityId)
        .toList();
  }

  // Méthode pour trouver une activité par ID
  Activity? getActivityById(String id) {
    try {
      return _activities.firstWhere((activity) => activity.id == id);
    } catch (e) {
      return null;
    }
  }

  // Méthode pour trouver une formule par ID
  Formula? getFormulaById(String id) {
    try {
      return _formulas.firstWhere((formula) => formula.id == id);
    } catch (e) {
      return null;
    }
  }

  // Méthode pour charger des données de test (pour démo)
  void loadDummyData() {
    // Ajouter des activités
    final laserGameActivity = Activity(
      id: '1',
      name: 'Laser Game',
      description: 'Jeu de tir laser en arène',
      pricePerPerson: 8.0,
    );

    _activities.add(laserGameActivity);

    // Ajouter des formules
    _formulas.addAll([
      // Formules pour Laser Game
      Formula(
        id: '1',
        name: 'Groupe',
        description:
            'Formule groupe standard: 2 à 20 joueurs, nombre de parties flexible',
        activity: laserGameActivity,
        price: 8.0,
        minParticipants: 2,
        maxParticipants: 20,
        defaultGameCount: 1,
        minGameCount: 1,
        maxGameCount: null, // Illimité
      ),
      Formula(
        id: '2',
        name: 'Anniversaire',
        description:
            'Forfait anniversaire avec salle privée: 10 à 20 joueurs, exactement 3 parties',
        activity: laserGameActivity,
        price: 15.0,
        minParticipants: 10,
        maxParticipants: 20,
        defaultGameCount: 3,
        minGameCount: 3,
        maxGameCount: 3,
        fixedGameCount: true, // Le nombre de parties est fixe
      ),
      Formula(
        id: '3',
        name: 'Social Deal',
        description:
            'Offre promotionnelle Social Deal: 4 à 20 joueurs, 2 à 3 parties',
        activity: laserGameActivity,
        price: 12.0,
        minParticipants: 4,
        maxParticipants: 20,
        defaultGameCount: 2,
        minGameCount: 2,
        maxGameCount: 3,
      ),
      Formula(
        id: '4',
        name: 'Team Building',
        description:
            'Formule pour les entreprises: nombre de joueurs et parties illimité',
        activity: laserGameActivity,
        price: 10.0,
        minParticipants: null, // Illimité
        maxParticipants: null, // Illimité
        defaultGameCount: 2,
        minGameCount: null, // Illimité
        maxGameCount: null, // Illimité
      ),
    ]);

    notifyListeners();
  }
}
