import 'package:flutter/foundation.dart';
import '../models/activity_model.dart';
import '../models/formula_model.dart';
import '../repositories/activity_repository.dart';
import '../repositories/formula_repository.dart';

class ActivityFormulaViewModel extends ChangeNotifier {
  final ActivityRepository _activityRepository = ActivityRepository();
  final FormulaRepository _formulaRepository = FormulaRepository();

  List<Activity> _activities = [];
  List<Formula> _formulas = [];
  bool _isLoading = true;
  String? _error;
  Activity? _selectedActivity;

  ActivityFormulaViewModel() {
    _initializeData();
    _setupSubscriptions();
  }

  // Getters
  List<Activity> get activities => List.unmodifiable(_activities);
  List<Formula> get formulas => List.unmodifiable(_formulas);
  bool get isLoading => _isLoading;
  String? get error => _error;
  Activity? get selectedActivity => _selectedActivity;

  void setSelectedActivity(Activity? activity) {
    _selectedActivity = activity;
    notifyListeners();
  }

  // Initialize data
  Future<void> _initializeData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _activities = await _activityRepository.getAllActivities();
      _formulas = await _formulaRepository.getAllFormulas();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error loading data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Setup real-time subscriptions
  void _setupSubscriptions() {
    _activityRepository.streamActivities().listen(
      (activities) {
        _activities = activities;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Subscription error: $e';
        notifyListeners();
      },
    );

    _formulaRepository.streamFormulas().listen(
      (formulas) {
        _formulas = formulas;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Subscription error: $e';
        notifyListeners();
      },
    );
  }

  // Activity methods
  Future<void> addActivity({required String name, String? description}) async {
    try {
      final activity = await _activityRepository.createActivity(
        name: name,
        description: description,
      );
      _activities.add(activity);
      notifyListeners();
    } catch (e) {
      _error = 'Error creating activity: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateActivity(Activity activity) async {
    try {
      final updatedActivity = await _activityRepository.updateActivity(
        activity,
      );
      final index = _activities.indexWhere((a) => a.id == activity.id);
      if (index != -1) {
        _activities[index] = updatedActivity;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error updating activity: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteActivity(String id) async {
    try {
      await _activityRepository.deleteActivity(id);
      _activities.removeWhere((a) => a.id == id);
      _formulas.removeWhere((f) => f.activity.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Error deleting activity: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Formula methods
  Future<void> addFormula({
    required String name,
    String? description,
    required Activity activity,
    required double price,
    required int minParticipants,
    int? maxParticipants,
    required int durationMinutes,
    required int minGames,
    int? maxGames,
  }) async {
    try {
      final formula = await _formulaRepository.createFormula(
        name: name,
        activityId: activity.id,
        description: description,
        price: price,
        minParticipants: minParticipants,
        maxParticipants: maxParticipants,
        durationMinutes: durationMinutes,
        minGames: minGames,
        maxGames: maxGames,
      );
      _formulas.add(formula);
      notifyListeners();
    } catch (e) {
      _error = 'Error creating formula: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateFormula(Formula formula) async {
    try {
      final updatedFormula = await _formulaRepository.updateFormula(formula);
      final index = _formulas.indexWhere((f) => f.id == formula.id);
      if (index != -1) {
        _formulas[index] = updatedFormula;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error updating formula: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteFormula(String id) async {
    try {
      await _formulaRepository.deleteFormula(id);
      _formulas.removeWhere((f) => f.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Error deleting formula: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Helper methods
  List<Formula> getFormulasForActivity(String activityId) {
    return _formulas.where((f) => f.activity.id == activityId).toList();
  }

  Activity? getActivityById(String id) {
    try {
      return _activities.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Formula? getFormulaById(String id) {
    try {
      return _formulas.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  // Refresh data
  Future<void> refresh() async {
    await _initializeData();
  }
}
