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

    final arcadeActivity = Activity(
      id: '2',
      name: 'Arcade',
      description: 'Salle de jeux d\'arcade',
      pricePerPerson: 5.0,
    );

    final realityActivity = Activity(
      id: '3',
      name: 'Réalité Virtuelle',
      description: 'Expérience en réalité virtuelle',
      pricePerPerson: 12.0,
    );

    _activities.addAll([laserGameActivity, arcadeActivity, realityActivity]);

    // Ajouter des formules
    _formulas.addAll([
      // Formules pour Laser Game
      Formula(
        id: '1',
        name: 'Standard',
        description: 'Une partie de laser game standard',
        activity: laserGameActivity,
        price: 10.0,
        defaultGameCount: 1,
      ),
      Formula(
        id: '2',
        name: 'Anniversaire',
        description: 'Forfait anniversaire avec 2 parties et une salle privée',
        activity: laserGameActivity,
        price: 15.0,
        minParticipants: 8,
        defaultGameCount: 2,
      ),
      Formula(
        id: '3',
        name: 'Groupe',
        description: 'Forfait pour groupes (écoles, entreprises)',
        activity: laserGameActivity,
        price: 12.0,
        minParticipants: 15,
        maxParticipants: 30,
        defaultGameCount: 2,
      ),

      // Formules pour Arcade
      Formula(
        id: '4',
        name: 'Découverte',
        description: '1 heure de jeux d\'arcade',
        activity: arcadeActivity,
        price: 8.0,
      ),
      Formula(
        id: '5',
        name: 'Passionné',
        description: '3 heures de jeux d\'arcade',
        activity: arcadeActivity,
        price: 20.0,
      ),

      // Formules pour Réalité Virtuelle
      Formula(
        id: '6',
        name: 'Découverte VR',
        description: '30 minutes d\'expérience VR',
        activity: realityActivity,
        price: 15.0,
      ),
      Formula(
        id: '7',
        name: 'Immersion VR',
        description: '1 heure d\'expérience VR',
        activity: realityActivity,
        price: 25.0,
      ),
    ]);

    notifyListeners();
  }
}
