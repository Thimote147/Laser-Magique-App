import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_statistics_model.dart';
import '../models/cash_movement_model.dart';
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

  // Variables pour la vérification du fond de caisse
  double? _previousDayClosingBalance;
  bool _balanceMismatch = false;
  double _balanceDifference = 0.0;

  // Cache pour stocker les résultats des périodes précédentes
  final Map<String, List<DailyStatistics>> _periodCache = {};
  final Map<String, DailyStatistics> _aggregateCache = {};

  final TextEditingController fondOuvertureController = TextEditingController();
  final TextEditingController fondFermetureController = TextEditingController();
  final TextEditingController montantCoffreController = TextEditingController();

  // Variables pour les mouvements de caisse
  List<CashMovement> _cashMovements = [];
  bool _isLoadingMovements = false;

  DailyStatistics? get currentStatistics => _currentStatistics;
  List<DailyStatistics> get periodStatistics => _periodStatistics;
  DateTime get selectedDate => _selectedDate;
  bool get isLoading => _isLoading;
  String? get error => _error;
  PeriodType get periodType => _periodType;

  // Getters pour la vérification du fond de caisse
  bool get balanceMismatch => _balanceMismatch;
  double get balanceDifference => _balanceDifference;
  double? get previousDayClosingBalance => _previousDayClosingBalance;

  // Getters pour les mouvements de caisse
  List<CashMovement> get cashMovements => _cashMovements;
  bool get isLoadingMovements => _isLoadingMovements;

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

          // Récupérer le fond de caisse de fermeture de la veille
          _previousDayClosingBalance = await _repository
              .getPreviousDayClosingBalance(targetDate);

          // Vérifier si le fond d'ouverture correspond au fond de fermeture de la veille
          final fondOuverture = manualFields['fond_caisse_ouverture'] ?? 0.0;
          if (_previousDayClosingBalance != null) {
            _balanceDifference = _previousDayClosingBalance! - fondOuverture;
            _balanceMismatch = _balanceDifference.abs() > 0.01;
          } else {
            _balanceMismatch = false;
            _balanceDifference = 0.0;
          }

          _currentStatistics = statistics.copyWith(
            fondCaisseOuverture: fondOuverture,
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

      // Charger les mouvements de caisse pour la vue jour
      if (_periodType == PeriodType.day) {
        await _loadCashMovements();
      }
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
  } // Une variable pour éviter les mises à jour multiples simultanées

  bool _isUpdatingField = false;

  Future<void> updateManualField(String field, String value) async {
    // Ne permettre la mise à jour que pour la vue jour
    if (_currentStatistics == null || _periodType != PeriodType.day) return;

    // Éviter les mises à jour simultanées qui peuvent causer des problèmes de cohérence
    if (_isUpdatingField) return;
    _isUpdatingField = true;

    try {
      // Assurez-vous que les valeurs décimales utilisent '.' comme séparateur
      String normalizedValue = value.replaceAll(',', '.');
      final doubleValue = double.tryParse(normalizedValue) ?? 0.0;

      switch (field) {
        case 'fond_ouverture':
          // Mettre à jour en mémoire immédiatement
          _currentStatistics = _currentStatistics!.copyWith(
            fondCaisseOuverture: doubleValue,
          );

          // Vérifier et mettre à jour la différence avec le fond de caisse de la veille en temps réel
          if (_previousDayClosingBalance != null) {
            _balanceDifference = _previousDayClosingBalance! - doubleValue;
            _balanceMismatch = _balanceDifference.abs() > 0.01;
          }

          // Notification immédiate pour l'UI
          notifyListeners();

          // Mise à jour dans la base de données
          await _repository.updateManualFields(
            date: _selectedDate,
            fondCaisseOuverture: doubleValue,
          );
          break;

        case 'fond_fermeture':
          // Mettre à jour en mémoire immédiatement
          _currentStatistics = _currentStatistics!.copyWith(
            fondCaisseFermeture: doubleValue,
          );
          // Notification immédiate pour l'UI
          notifyListeners();

          // Mise à jour dans la base de données
          await _repository.updateManualFields(
            date: _selectedDate,
            fondCaisseFermeture: doubleValue,
          );
          break;

        case 'montant_coffre':
          // Mettre à jour en mémoire immédiatement
          _currentStatistics = _currentStatistics!.copyWith(
            montantCoffre: doubleValue,
          );
          // Notification immédiate pour l'UI
          notifyListeners();

          // Mise à jour dans la base de données
          await _repository.updateManualFields(
            date: _selectedDate,
            montantCoffre: doubleValue,
          );
          break;
      }
      // Une notification finale pour s'assurer que l'UI est à jour
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors de la mise à jour: $e';
      notifyListeners();
    } finally {
      // Important: libérer le drapeau pour permettre de futures mises à jour
      _isUpdatingField = false;
    }
  }

  // Méthode pour calculer les espèces théoriques en caisse
  double getTheoricalCashAmount() {
    if (_currentStatistics == null) return 0.0;

    // Calcul: Fond ouverture + Total cash - Montant coffre
    return _currentStatistics!.fondCaisseOuverture +
        _currentStatistics!.totalCash -
        _currentStatistics!.montantCoffre;
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

  // Méthode pour utiliser le fond de caisse de fermeture de la veille comme fond d'ouverture
  Future<void> usePreviousDayClosingBalance() async {
    if (_previousDayClosingBalance == null ||
        _previousDayClosingBalance == 0.0) {
      return;
    }

    // Éviter les mises à jour simultanées
    if (_isUpdatingField) return;
    _isUpdatingField = true;

    try {
      // Mettre à jour directement le contrôleur du fond d'ouverture
      fondOuvertureController.text = _previousDayClosingBalance!
          .toStringAsFixed(2);

      // Mettre à jour les données en mémoire
      if (_currentStatistics != null) {
        _currentStatistics = _currentStatistics!.copyWith(
          fondCaisseOuverture: _previousDayClosingBalance!,
        );
      }

      // Réinitialiser l'état de vérification car maintenant les valeurs correspondent
      _balanceMismatch = false;
      _balanceDifference = 0.0;

      // Mettre à jour le fond d'ouverture avec la valeur de la veille dans la base de données
      await _repository.updateManualFields(
        date: _selectedDate,
        fondCaisseOuverture: _previousDayClosingBalance,
      );

      // Mettre à jour l'interface avec les nouvelles données
      notifyListeners();

      // Ne pas recharger les statistiques complètes car cela pourrait écraser les modifications
      // loadStatistics();
    } catch (e) {
      _error = 'Erreur lors de la mise à jour: $e';
      notifyListeners();
    } finally {
      _isUpdatingField = false;
    }
  }

  // Méthodes pour les mouvements de caisse
  Future<void> _loadCashMovements() async {
    _isLoadingMovements = true;
    notifyListeners();

    try {
      _cashMovements = await _repository.getCashMovements(_selectedDate);
    } catch (e) {
      _error = _formatErrorMessage(e);
      print('Erreur lors du chargement des mouvements de caisse: $e');
    } finally {
      _isLoadingMovements = false;
      notifyListeners();
    }
  }

  Future<void> addCashMovement(CashMovement movement) async {
    try {
      await _repository.addCashMovement(movement);
      await _loadCashMovements();
    } catch (e) {
      _error = _formatErrorMessage(e);
      print('Erreur lors de l\'ajout du mouvement de caisse: $e');
      notifyListeners();
    }
  }

  Future<void> deleteCashMovement(String id) async {
    try {
      print('Tentative de suppression du mouvement de caisse avec ID: $id');
      await _repository.deleteCashMovement(id);
      print('Suppression réussie, rechargement des mouvements...');
      await _loadCashMovements();
      print('Mouvements rechargés avec succès');
      notifyListeners();
    } catch (e) {
      _error = _formatErrorMessage(e);
      print('Erreur lors de la suppression du mouvement de caisse: $e');
      print('Type d\'erreur: ${e.runtimeType}');
      print('Stack trace: ${StackTrace.current}');
      notifyListeners();
    }
  }

  // Calcul du total des mouvements de caisse
  double getTotalCashMovements() {
    double total = 0;
    for (final movement in _cashMovements) {
      if (movement.type == CashMovementType.entry) {
        total += movement.amount;
      } else {
        total -= movement.amount;
      }
    }
    return total;
  }

  @override
  void dispose() {
    fondOuvertureController.dispose();
    fondFermetureController.dispose();
    montantCoffreController.dispose();
    super.dispose();
  }
}
