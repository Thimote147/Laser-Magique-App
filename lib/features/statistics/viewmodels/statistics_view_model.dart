import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_statistics_model.dart';
import '../repositories/statistics_repository.dart';

enum PeriodType { day, week, month, year }

class StatisticsViewModel extends ChangeNotifier {
  final StatisticsRepository _repository = StatisticsRepository();

  DailyStatistics? _currentStatistics;
  List<DailyStatistics> _periodStatistics = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _error;
  PeriodType _periodType = PeriodType.day;

  // Cache pour stocker les résultats des périodes précédentes
  final Map<String, List<DailyStatistics>> _periodCache = {};
  final Map<String, DailyStatistics> _aggregateCache = {};

  final TextEditingController fondOuvertureController = TextEditingController();
  final TextEditingController fondFermetureController = TextEditingController();
  final TextEditingController montantCoffreController = TextEditingController();

  DailyStatistics? get currentStatistics => _currentStatistics;
  List<DailyStatistics> get periodStatistics => _periodStatistics;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get error => _error;
  PeriodType get periodType => _periodType;

  // Dates de début et fin en fonction de la période sélectionnée
  DateTime get startDate {
    switch (_periodType) {
      case PeriodType.day:
        return DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        );
      case PeriodType.week:
        final weekDay = _selectedDate.weekday;
        return _selectedDate.subtract(Duration(days: weekDay - 1));
      case PeriodType.month:
        return DateTime(_selectedDate.year, _selectedDate.month, 1);
      case PeriodType.year:
        return DateTime(_selectedDate.year, 1, 1);
    }
  }

  DateTime get endDate {
    switch (_periodType) {
      case PeriodType.day:
        return DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        );
      case PeriodType.week:
        final weekDay = _selectedDate.weekday;
        return _selectedDate.add(Duration(days: 7 - weekDay));
      case PeriodType.month:
        final lastDay =
            DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
        return DateTime(_selectedDate.year, _selectedDate.month, lastDay);
      case PeriodType.year:
        return DateTime(_selectedDate.year, 12, 31);
    }
  }

  // Clé de cache pour une période
  String _getPeriodCacheKey(DateTime start, DateTime end, PeriodType type) {
    return '${start.toIso8601String().substring(0, 10)}_${end.toIso8601String().substring(0, 10)}_$type';
  }

  // Statistiques agrégées pour la période
  DailyStatistics get periodAggregateStatistics {
    if (_periodStatistics.isEmpty) {
      return DailyStatistics(
        date: _selectedDate,
        fondCaisseOuverture: 0,
        fondCaisseFermeture: 0,
        montantCoffre: 0,
        totalBancontact: 0,
        totalCash: 0,
        totalVirement: 0,
        totalBoissons: 0,
        totalNourritures: 0,
        categorieDetails: [],
        methodesPaiementDetails: [],
      );
    }

    double totalBancontact = 0;
    double totalCash = 0;
    double totalVirement = 0;
    double totalBoissons = 0;
    double totalNourritures = 0;

    for (var stat in _periodStatistics) {
      totalBancontact += stat.totalBancontact;
      totalCash += stat.totalCash;
      totalVirement += stat.totalVirement;
      totalBoissons += stat.totalBoissons;
      totalNourritures += stat.totalNourritures;
    }

    // On utilise les données du premier jour pour fondCaisseOuverture et du dernier jour pour fondCaisseFermeture
    final fondOuverture =
        _periodStatistics.isNotEmpty
            ? _periodStatistics.first.fondCaisseOuverture
            : 0;
    final fondFermeture =
        _periodStatistics.isNotEmpty
            ? _periodStatistics.last.fondCaisseFermeture
            : 0;

    // On somme tous les montants coffre
    double totalMontantCoffre = 0;
    for (var stat in _periodStatistics) {
      totalMontantCoffre += stat.montantCoffre;
    }

    return DailyStatistics(
      date: startDate,
      fondCaisseOuverture: fondOuverture.toDouble(),
      fondCaisseFermeture: fondFermeture.toDouble(),
      montantCoffre: totalMontantCoffre,
      totalBancontact: totalBancontact,
      totalCash: totalCash,
      totalVirement: totalVirement,
      totalBoissons: totalBoissons,
      totalNourritures: totalNourritures,
      categorieDetails:
          [], // Une implémentation plus complète pourrait agréger ces données
      methodesPaiementDetails:
          [], // Une implémentation plus complète pourrait agréger ces données
    );
  }

  // Obtenir les statistiques groupées par mois pour la vue année
  List<DailyStatistics> get monthlyAggregatedStatistics {
    if (_periodType != PeriodType.year || _periodStatistics.isEmpty) {
      return _periodStatistics;
    }

    // Créer un map pour regrouper les statistiques par mois
    Map<int, List<DailyStatistics>> statsByMonth = {};

    // Regrouper les statistiques par mois
    for (var stat in _periodStatistics) {
      final month = stat.date.month;
      if (!statsByMonth.containsKey(month)) {
        statsByMonth[month] = [];
      }
      statsByMonth[month]!.add(stat);
    }

    // Agréger les statistiques pour chaque mois
    List<DailyStatistics> monthlyStats = [];
    for (var month = 1; month <= 12; month++) {
      if (statsByMonth.containsKey(month)) {
        double totalBancontact = 0;
        double totalCash = 0;
        double totalVirement = 0;
        double totalBoissons = 0;
        double totalNourritures = 0;
        double totalMontantCoffre = 0;

        for (var stat in statsByMonth[month]!) {
          totalBancontact += stat.totalBancontact;
          totalCash += stat.totalCash;
          totalVirement += stat.totalVirement;
          totalBoissons += stat.totalBoissons;
          totalNourritures += stat.totalNourritures;
          totalMontantCoffre += stat.montantCoffre;
        }

        // Date représentant le premier jour du mois
        final date = DateTime(_selectedDate.year, month, 1);

        monthlyStats.add(
          DailyStatistics(
            date: date,
            fondCaisseOuverture:
                0, // Ces valeurs ne sont pas pertinentes pour la vue mensuelle
            fondCaisseFermeture: 0,
            montantCoffre: totalMontantCoffre,
            totalBancontact: totalBancontact,
            totalCash: totalCash,
            totalVirement: totalVirement,
            totalBoissons: totalBoissons,
            totalNourritures: totalNourritures,
            categorieDetails: [],
            methodesPaiementDetails: [],
          ),
        );
      } else {
        // Ajouter un mois vide pour maintenir la continuité
        monthlyStats.add(
          DailyStatistics(
            date: DateTime(_selectedDate.year, month, 1),
            fondCaisseOuverture: 0,
            fondCaisseFermeture: 0,
            montantCoffre: 0,
            totalBancontact: 0,
            totalCash: 0,
            totalVirement: 0,
            totalBoissons: 0,
            totalNourritures: 0,
            categorieDetails: [],
            methodesPaiementDetails: [],
          ),
        );
      }
    }

    return monthlyStats;
  }

  // Méthode pour formater les erreurs de manière plus lisible
  String _formatErrorMessage(dynamic error) {
    if (error is PostgrestException) {
      // Formater les erreurs Supabase PostgreSQL
      String message = 'Erreur de base de données: ${error.message}';
      if (error.details != null) {
        message += '\nDétails: ${error.details}';
      }
      return message;
    } else {
      return 'Erreur: $error';
    }
  }

  Future<void> loadStatistics([DateTime? date]) async {
    final targetDate = date ?? _selectedDate;
    _selectedDate = targetDate;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final periodCacheKey = _getPeriodCacheKey(
        startDate,
        endDate,
        _periodType,
      );

      // Vérifier si nous avons déjà ces données en cache
      if (_periodCache.containsKey(periodCacheKey)) {
        _periodStatistics = _periodCache[periodCacheKey]!;
        if (_periodStatistics.isNotEmpty) {
          // Calcul des statistiques selon le type de période
          _currentStatistics =
              _periodType == PeriodType.day
                  ? _periodStatistics.first
                  : periodAggregateStatistics;

          // Si c'est la vue année, préparer les données mensuelles
          if (_periodType == PeriodType.year) {
            _periodStatistics = monthlyAggregatedStatistics;
          }

          _updateControllers();
        } else {
          _currentStatistics = null;
          _resetControllers();
        }
      } else {
        // Chargement depuis le repository
        if (_periodType == PeriodType.day) {
          final statistics = await _repository.getDailyStatistics(targetDate);
          final manualFields = await _repository.getManualFields(targetDate);

          _currentStatistics = statistics.copyWith(
            fondCaisseOuverture: manualFields['fond_caisse_ouverture'] ?? 0.0,
            fondCaisseFermeture: manualFields['fond_caisse_fermeture'] ?? 0.0,
            montantCoffre: manualFields['montant_coffre'] ?? 0.0,
          );

          _periodStatistics = [_currentStatistics!];
          _updateControllers();
        } else {
          // Chargement des statistiques sur une période
          _periodStatistics = await _repository.getStatisticsForPeriod(
            startDate,
            endDate,
          );

          if (_periodStatistics.isNotEmpty) {
            // Pour l'année, utilisez les statistiques agrégées complètes
            _currentStatistics = periodAggregateStatistics;

            // Si c'est la vue année, assurez-vous que nous avons des données pour chaque mois
            if (_periodType == PeriodType.year) {
              // Cette méthode ajoutera des mois vides si nécessaire
              // pour s'assurer que nous avons 12 points de données
              _periodStatistics = monthlyAggregatedStatistics;
            }

            _updateControllers();
          } else {
            _currentStatistics = null;
            _resetControllers();
          }
        }

        // Mettre en cache les résultats
        _periodCache[periodCacheKey] = _periodStatistics;
      }

      // Mettre en cache les statistiques agrégées
      _aggregateCache[periodCacheKey] = periodAggregateStatistics;
    } catch (e) {
      _error = _formatErrorMessage(e);
      print('Erreur de chargement: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Méthodes utilitaires pour la mise à jour des contrôleurs
  void _updateControllers() {
    // Mettre à jour les contrôleurs de saisie manuelle uniquement pour la vue jour
    if (_currentStatistics != null && _periodType == PeriodType.day) {
      fondOuvertureController.text = _currentStatistics!.fondCaisseOuverture
          .toStringAsFixed(2);
      fondFermetureController.text = _currentStatistics!.fondCaisseFermeture
          .toStringAsFixed(2);
      montantCoffreController.text = _currentStatistics!.montantCoffre
          .toStringAsFixed(2);
    }
  }

  void _resetControllers() {
    fondOuvertureController.text = "0.00";
    fondFermetureController.text = "0.00";
    montantCoffreController.text = "0.00";
  }

  // Cette méthode sera appelée avec le statut d'administrateur de l'utilisateur
  void changePeriodType(PeriodType type, {bool isAdmin = false}) {
    // Si l'utilisateur n'est pas administrateur, il ne peut utiliser que la vue jour
    if (!isAdmin && type != PeriodType.day) {
      return; // Ne rien faire si ce n'est pas un administrateur qui essaie de changer la vue
    }

    if (_periodType != type) {
      _periodType = type;
      loadStatistics(_selectedDate);
      notifyListeners();
    }
  }

  Future<void> updateManualField(String field, String value) async {
    // Ne permettre la mise à jour que pour la vue jour
    if (_currentStatistics == null || _periodType != PeriodType.day) return;

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
