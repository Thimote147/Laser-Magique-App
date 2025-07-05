import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_statistics_model.dart';
import '../models/cash_movement_model.dart';
import '../../../shared/models/payment_model.dart';
import '../../../shared/models/consumption_model.dart';
import '../../inventory/models/stock_item_model.dart';

class StatisticsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Cache des statistiques
  final Map<String, DailyStatistics> _statisticsCache = {};
  final Map<String, Map<String, double?>> _manualFieldsCache = {};

  // Clé de cache à partir d'une date
  String _getCacheKey(DateTime date) {
    return date.toIso8601String().substring(0, 10);
  }

  Future<DailyStatistics> getDailyStatistics(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Vérifier le cache
    final cacheKey = _getCacheKey(startOfDay);
    if (_statisticsCache.containsKey(cacheKey)) {
      return _statisticsCache[cacheKey]!;
    }

    final stats = await _getStatisticsForDateRange(startOfDay, endOfDay);
    // Mettre en cache
    _statisticsCache[cacheKey] = stats;
    return stats;
  }

  Future<List<DailyStatistics>> getStatisticsForPeriod(
    DateTime start,
    DateTime end,
  ) async {
    final List<DailyStatistics> result = [];
    final days = end.difference(start).inDays + 1;

    // Pour les périodes très longues, utiliser une approche optimisée
    if (days > 30) {
      return _getAggregatedStatisticsForPeriod(start, end);
    }

    // Clone the start date
    var currentDate = DateTime(start.year, start.month, start.day);

    // Fetch statistics for each day in the period
    while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
      final cacheKey = _getCacheKey(currentDate);
      DailyStatistics stats;

      if (_statisticsCache.containsKey(cacheKey)) {
        stats = _statisticsCache[cacheKey]!;
      } else {
        final nextDate = currentDate.add(const Duration(days: 1));
        stats = await _getStatisticsForDateRange(currentDate, nextDate);
        _statisticsCache[cacheKey] = stats;
      }

      result.add(stats);

      // Move to the next day
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return result;
  }

  // Optimisation pour les périodes longues
  Future<List<DailyStatistics>> _getAggregatedStatisticsForPeriod(
    DateTime start,
    DateTime end,
  ) async {
    // Récupérer directement toutes les données de la période en une seule requête
    final paymentsResponse = await _supabase
        .from('payments')
        .select('payment_date, payment_method, amount')
        .gte('payment_date', start.toIso8601String())
        .lte('payment_date', end.toIso8601String());

    final consumptionsResponse = await _supabase
        .from('consumptions')
        .select(
          'timestamp, quantity, unit_price, stock_items:stock_item_id(category)',
        )
        .gte('timestamp', start.toIso8601String())
        .lte('timestamp', end.toIso8601String());

    // Organiser les données par jour
    final Map<String, Map<String, dynamic>> dailyData = {};

    // Initialiser la structure de données pour chaque jour de la période
    var currentDate = DateTime(start.year, start.month, start.day);
    while (currentDate.isBefore(end.add(const Duration(days: 1)))) {
      final dateKey = _getCacheKey(currentDate);
      dailyData[dateKey] = {
        'date': currentDate,
        'totalBancontact': 0.0,
        'totalCash': 0.0,
        'totalVirement': 0.0,
        'totalBoissons': 0.0,
        'totalNourritures': 0.0,
        'categoryTotals': <String, double>{},
        'categoryItemCounts': <String, int>{},
        'paymentMethodTotals': <String, double>{},
        'paymentMethodCounts': <String, int>{},
      };
      currentDate = currentDate.add(const Duration(days: 1));
    }

    // Traiter les paiements
    for (final paymentJson in paymentsResponse) {
      final paymentDate = DateTime.parse(paymentJson['payment_date']);
      final dateKey = _getCacheKey(paymentDate);
      final method = paymentJson['payment_method'];
      final amount = paymentJson['amount']?.toDouble() ?? 0.0;

      if (dailyData.containsKey(dateKey)) {
        switch (method) {
          case 'card':
            dailyData[dateKey]!['totalBancontact'] += amount;
            break;
          case 'cash':
            dailyData[dateKey]!['totalCash'] += amount;
            break;
          case 'transfer':
            dailyData[dateKey]!['totalVirement'] += amount;
            break;
        }

        // Mise à jour des totaux par méthode de paiement
        final methodTotals =
            dailyData[dateKey]!['paymentMethodTotals'] as Map<String, double>;
        methodTotals[method] = (methodTotals[method] ?? 0.0) + amount;

        final methodCounts =
            dailyData[dateKey]!['paymentMethodCounts'] as Map<String, int>;
        methodCounts[method] = (methodCounts[method] ?? 0) + 1;
      }
    }

    // Traiter les consommations
    for (final consumptionJson in consumptionsResponse) {
      final timestamp = DateTime.parse(consumptionJson['timestamp']);
      final dateKey = _getCacheKey(timestamp);
      final quantity = consumptionJson['quantity'] ?? 0;
      final unitPrice = (consumptionJson['unit_price'] ?? 0.0).toDouble();
      final totalPrice = quantity * unitPrice; // Calculate total price
      final stockItemData = consumptionJson['stock_items'];

      if (dailyData.containsKey(dateKey) && stockItemData != null) {
        final category = stockItemData['category'];

        if (category == 'DRINK') {
          dailyData[dateKey]!['totalBoissons'] += totalPrice;
        } else if (category == 'FOOD') {
          dailyData[dateKey]!['totalNourritures'] += totalPrice;
        }

        final categoryTotals =
            dailyData[dateKey]!['categoryTotals'] as Map<String, double>;
        categoryTotals[category] =
            (categoryTotals[category] ?? 0.0) + totalPrice;

        final categoryItemCounts =
            dailyData[dateKey]!['categoryItemCounts'] as Map<String, int>;
        categoryItemCounts[category] =
            (categoryItemCounts[category] ?? 0) + (quantity as int);
      }
    }

    // Récupérer les champs manuels pour chaque jour
    final List<DailyStatistics> result = [];
    for (final entry in dailyData.entries) {
      final data = entry.value;
      final date = data['date'] as DateTime;

      // Récupérer les champs manuels
      Map<String, double?> manualFields;
      if (_manualFieldsCache.containsKey(entry.key)) {
        manualFields = _manualFieldsCache[entry.key]!;
      } else {
        manualFields = await getManualFields(date);
        _manualFieldsCache[entry.key] = manualFields;
      }

      // Créer les listes de catégories et méthodes de paiement
      final categoryTotals = data['categoryTotals'] as Map<String, double>;
      final categoryItemCounts = data['categoryItemCounts'] as Map<String, int>;
      final paymentMethodTotals =
          data['paymentMethodTotals'] as Map<String, double>;
      final paymentMethodCounts =
          data['paymentMethodCounts'] as Map<String, int>;

      final categorieDetails =
          categoryTotals.entries.map((entry) {
            String displayName;
            switch (entry.key) {
              case 'DRINK':
                displayName = 'Boissons';
                break;
              case 'FOOD':
                displayName = 'Nourritures';
                break;
              default:
                displayName = entry.key;
            }

            return CategoryTotal(
              category: entry.key,
              categoryDisplayName: displayName,
              total: entry.value,
              itemCount: categoryItemCounts[entry.key] ?? 0,
            );
          }).toList();

      final methodesPaiementDetails =
          paymentMethodTotals.entries.map((entry) {
            String displayName;
            switch (entry.key) {
              case 'card':
                displayName = 'Bancontact';
                break;
              case 'cash':
                displayName = 'Espèces';
                break;
              case 'transfer':
                displayName = 'Virement';
                break;
              default:
                displayName = entry.key;
            }

            return PaymentMethodTotal(
              method: entry.key,
              methodDisplayName: displayName,
              total: entry.value,
              transactionCount: paymentMethodCounts[entry.key] ?? 0,
            );
          }).toList();

      final stats = DailyStatistics(
        date: date,
        fondCaisseOuverture: manualFields['fond_caisse_ouverture'] ?? 0.0,
        fondCaisseFermeture: manualFields['fond_caisse_fermeture'] ?? 0.0,
        montantCoffre: manualFields['montant_coffre'] ?? 0.0,
        totalBancontact: data['totalBancontact'] as double,
        totalCash: data['totalCash'] as double,
        totalVirement: data['totalVirement'] as double,
        totalBoissons: data['totalBoissons'] as double,
        totalNourritures: data['totalNourritures'] as double,
        categorieDetails: categorieDetails,
        methodesPaiementDetails: methodesPaiementDetails,
      );

      result.add(stats);
      _statisticsCache[entry.key] = stats;
    }

    return result..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<DailyStatistics> _getStatisticsForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    // Récupérer les paiements de la période
    final paymentsResponse = await _supabase
        .from('payments')
        .select('*')
        .gte('payment_date', start.toIso8601String())
        .lt('payment_date', end.toIso8601String());

    // Récupérer les consommations de la période avec les informations des articles de stock
    final consumptionsResponse = await _supabase
        .from('consumptions')
        .select('*, stock_items!inner(*)')
        .gte('timestamp', start.toIso8601String())
        .lt('timestamp', end.toIso8601String());

    double totalBancontact = 0;
    double totalCash = 0;
    double totalVirement = 0;
    double totalBoissons = 0;
    double totalNourritures = 0;

    Map<String, double> categoryTotals = {};
    Map<String, int> categoryItemCounts = {};
    Map<String, double> paymentMethodTotals = {};
    Map<String, int> paymentMethodCounts = {};

    // Traiter les paiements
    for (final paymentJson in paymentsResponse) {
      final payment = Payment.fromJson(paymentJson);

      switch (payment.method) {
        case PaymentMethod.card:
          totalBancontact += payment.amount;
          break;
        case PaymentMethod.cash:
          totalCash += payment.amount;
          break;
        case PaymentMethod.transfer:
          totalVirement += payment.amount;
          break;
      }

      final methodKey = payment.method.toString().split('.').last;
      paymentMethodTotals[methodKey] =
          (paymentMethodTotals[methodKey] ?? 0) + payment.amount;
      paymentMethodCounts[methodKey] =
          (paymentMethodCounts[methodKey] ?? 0) + 1;
    }

    // Traiter les consommations
    for (final consumptionJson in consumptionsResponse) {
      final consumption = Consumption.fromMap(consumptionJson);
      final stockItemData = consumptionJson['stock_items'];

      if (stockItemData != null) {
        final stockItem = StockItem.fromMap(stockItemData);
        final consumptionTotal = consumption.quantity * consumption.unitPrice;

        if (stockItem.category == 'DRINK') {
          totalBoissons += consumptionTotal;
        } else if (stockItem.category == 'FOOD') {
          totalNourritures += consumptionTotal;
        }

        categoryTotals[stockItem.category] =
            (categoryTotals[stockItem.category] ?? 0) + consumptionTotal;
        categoryItemCounts[stockItem.category] =
            (categoryItemCounts[stockItem.category] ?? 0) +
            consumption.quantity;
      }
    }

    final categorieDetails =
        categoryTotals.entries.map((entry) {
          String displayName;
          switch (entry.key) {
            case 'DRINK':
              displayName = 'Boissons';
              break;
            case 'FOOD':
              displayName = 'Nourritures';
              break;
            default:
              displayName = entry.key;
          }

          return CategoryTotal(
            category: entry.key,
            categoryDisplayName: displayName,
            total: entry.value,
            itemCount: categoryItemCounts[entry.key] ?? 0,
          );
        }).toList();

    final methodesPaiementDetails =
        paymentMethodTotals.entries.map((entry) {
          String displayName;
          switch (entry.key) {
            case 'card':
              displayName = 'Bancontact';
              break;
            case 'cash':
              displayName = 'Espèces';
              break;
            case 'transfer':
              displayName = 'Virement';
              break;
            default:
              displayName = entry.key;
          }

          return PaymentMethodTotal(
            method: entry.key,
            methodDisplayName: displayName,
            total: entry.value,
            transactionCount: paymentMethodCounts[entry.key] ?? 0,
          );
        }).toList();

    // Pour les statistiques sur une période, nous utilisons la date de début comme date de référence
    final manualFields = await getManualFields(start);

    return DailyStatistics(
      date: start,
      fondCaisseOuverture: manualFields['fond_caisse_ouverture'] ?? 0.0,
      fondCaisseFermeture: manualFields['fond_caisse_fermeture'] ?? 0.0,
      montantCoffre: manualFields['montant_coffre'] ?? 0.0,
      totalBancontact: totalBancontact,
      totalCash: totalCash,
      totalVirement: totalVirement,
      totalBoissons: totalBoissons,
      totalNourritures: totalNourritures,
      categorieDetails: categorieDetails,
      methodesPaiementDetails: methodesPaiementDetails,
    );
  }

  // Méthode simplifiée pour mettre à jour UN seul champ manuel
  Future<void> updateSingleManualField({
    required DateTime date,
    required String fieldName,
    required double value,
  }) async {
    final dateString = date.toIso8601String().substring(0, 10);
    
    // Valider le nom du champ
    final validFields = ['fond_caisse_ouverture', 'fond_caisse_fermeture', 'montant_coffre'];
    if (!validFields.contains(fieldName)) {
      throw ArgumentError('Nom de champ invalide: $fieldName');
    }

    try {
      // Faire l'upsert avec seulement le champ spécifique
      final data = {
        'date': dateString,
        fieldName: value,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('daily_statistics').upsert(
        data,
        onConflict: 'date',
        ignoreDuplicates: false,
      );

      // Invalider SEULEMENT le cache pour cette date
      final cacheKey = _getCacheKey(date);
      _manualFieldsCache.remove(cacheKey);
      _statisticsCache.remove(cacheKey);
      
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du champ $fieldName: $e');
    }
  }

  // Méthode pour vider le cache d'une date spécifique
  void clearCacheForDate(DateTime date) {
    final cacheKey = _getCacheKey(date);
    _manualFieldsCache.remove(cacheKey);
    _statisticsCache.remove(cacheKey);
  }

  // Méthode pour forcer le rechargement des champs manuels depuis la BDD
  Future<Map<String, double?>> forceRefreshManualFields(DateTime date) async {
    return getManualFields(date, forceRefresh: true);
  }

  // Ancienne méthode maintenue pour compatibilité
  Future<void> updateManualFields({
    required DateTime date,
    double? fondCaisseOuverture,
    double? fondCaisseFermeture,
    double? montantCoffre,
  }) async {
    // Mettre à jour chaque champ individuellement
    if (fondCaisseOuverture != null) {
      await updateSingleManualField(
        date: date,
        fieldName: 'fond_caisse_ouverture',
        value: fondCaisseOuverture,
      );
    }
    if (fondCaisseFermeture != null) {
      await updateSingleManualField(
        date: date,
        fieldName: 'fond_caisse_fermeture',
        value: fondCaisseFermeture,
      );
    }
    if (montantCoffre != null) {
      await updateSingleManualField(
        date: date,
        fieldName: 'montant_coffre',
        value: montantCoffre,
      );
    }
  }

  Future<Map<String, double?>> getManualFields(DateTime date, {bool forceRefresh = false}) async {
    final cacheKey = _getCacheKey(date);
    
    // Vérifier le cache d'abord (sauf si forceRefresh est demandé)
    if (!forceRefresh && _manualFieldsCache.containsKey(cacheKey)) {
      return Map<String, double?>.from(_manualFieldsCache[cacheKey]!);
    }

    final response =
        await _supabase
            .from('daily_statistics')
            .select(
              'fond_caisse_ouverture, fond_caisse_fermeture, montant_coffre',
            )
            .eq('date', date.toIso8601String().substring(0, 10))
            .maybeSingle();

    final result = <String, double?>{
      'fond_caisse_ouverture': response?['fond_caisse_ouverture']?.toDouble(),
      'fond_caisse_fermeture': response?['fond_caisse_fermeture']?.toDouble(),
      'montant_coffre': response?['montant_coffre']?.toDouble(),
    };

    // Mettre en cache le résultat
    _manualFieldsCache[cacheKey] = result;
    
    return result;
  }

  // Récupère uniquement le fond de caisse de fermeture de la veille
  Future<double?> getPreviousDayClosingBalance(DateTime date) async {
    // Calculer la date de la veille
    final previousDay = date.subtract(const Duration(days: 1));

    final response =
        await _supabase
            .from('daily_statistics')
            .select('fond_caisse_fermeture')
            .eq('date', previousDay.toIso8601String().substring(0, 10))
            .maybeSingle();

    return response?['fond_caisse_fermeture']?.toDouble();
  }

  // Méthodes pour les mouvements de caisse
  Future<void> addCashMovement(CashMovement movement) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    final movementData = movement.toJson();

    // Remplacer created_by par l'ID utilisateur réel
    movementData['created_by'] = currentUserId;

    await _supabase.from('cash_movements').insert(movementData);
  }

  Future<List<CashMovement>> getCashMovements(DateTime date) async {
    final response = await _supabase
        .from('cash_movements')
        .select()
        .eq('date', date.toIso8601String().substring(0, 10))
        .order('created_at', ascending: false);

    return response.map((json) => CashMovement.fromJson(json)).toList();
  }

  Future<void> deleteCashMovement(String id) async {
    // Supprimer le mouvement
    await _supabase.from('cash_movements').delete().eq('id', id);
  }
}
