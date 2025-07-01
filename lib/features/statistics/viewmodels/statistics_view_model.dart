import 'package:flutter/material.dart';
import '../models/daily_statistics_model.dart';
import '../repositories/statistics_repository.dart';

class StatisticsViewModel extends ChangeNotifier {
  final StatisticsRepository _repository = StatisticsRepository();

  DailyStatistics? _currentStatistics;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _error;

  final TextEditingController fondOuvertureController = TextEditingController();
  final TextEditingController fondFermetureController = TextEditingController();
  final TextEditingController montantCoffreController = TextEditingController();

  DailyStatistics? get currentStatistics => _currentStatistics;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadStatistics([DateTime? date]) async {
    final targetDate = date ?? _selectedDate;
    _selectedDate = targetDate;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final statistics = await _repository.getDailyStatistics(targetDate);
      final manualFields = await _repository.getManualFields(targetDate);

      _currentStatistics = statistics.copyWith(
        fondCaisseOuverture: manualFields['fond_caisse_ouverture'] ?? 0.0,
        fondCaisseFermeture: manualFields['fond_caisse_fermeture'] ?? 0.0,
        montantCoffre: manualFields['montant_coffre'] ?? 0.0,
      );

      fondOuvertureController.text = _currentStatistics!.fondCaisseOuverture.toStringAsFixed(2);
      fondFermetureController.text = _currentStatistics!.fondCaisseFermeture.toStringAsFixed(2);
      montantCoffreController.text = _currentStatistics!.montantCoffre.toStringAsFixed(2);

    } catch (e) {
      _error = 'Erreur lors du chargement des statistiques: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateManualField(String field, String value) async {
    if (_currentStatistics == null) return;

    try {
      final doubleValue = double.tryParse(value);
      
      switch (field) {
        case 'fond_ouverture':
          await _repository.updateManualFields(
            date: _selectedDate,
            fondCaisseOuverture: doubleValue,
          );
          _currentStatistics = _currentStatistics!.copyWith(
            fondCaisseOuverture: doubleValue ?? 0.0,
          );
          break;
        case 'fond_fermeture':
          await _repository.updateManualFields(
            date: _selectedDate,
            fondCaisseFermeture: doubleValue,
          );
          _currentStatistics = _currentStatistics!.copyWith(
            fondCaisseFermeture: doubleValue ?? 0.0,
          );
          break;
        case 'montant_coffre':
          await _repository.updateManualFields(
            date: _selectedDate,
            montantCoffre: doubleValue,
          );
          _currentStatistics = _currentStatistics!.copyWith(
            montantCoffre: doubleValue ?? 0.0,
          );
          break;
      }
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors de la mise à jour: $e';
      notifyListeners();
    }
  }

  void changeDate(DateTime newDate) {
    if (newDate != _selectedDate) {
      loadStatistics(newDate);
    }
  }

  String formatCurrency(double? amount) {
    if (amount == null) return '0,00 €';
    return '${amount.toStringAsFixed(2).replaceAll('.', ',')} €';
  }

  @override
  void dispose() {
    fondOuvertureController.dispose();
    fondFermetureController.dispose();
    montantCoffreController.dispose();
    super.dispose();
  }
}