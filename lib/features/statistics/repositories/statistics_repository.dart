import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/daily_statistics_model.dart';
import '../../../shared/models/payment_model.dart';
import '../../../shared/models/consumption_model.dart';
import '../../inventory/models/stock_item_model.dart';

class StatisticsRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<DailyStatistics> getDailyStatistics(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Récupérer les paiements de la journée
    final paymentsResponse = await _supabase
        .from('payments')
        .select('*')
        .gte('payment_date', startOfDay.toIso8601String())
        .lt('payment_date', endOfDay.toIso8601String());

    // Récupérer les consommations de la journée avec les informations des articles de stock
    final consumptionsResponse = await _supabase
        .from('consumptions')
        .select('*, stock_items!inner(*)')
        .gte('timestamp', startOfDay.toIso8601String())
        .lt('timestamp', endOfDay.toIso8601String());

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
      paymentMethodTotals[methodKey] = (paymentMethodTotals[methodKey] ?? 0) + payment.amount;
      paymentMethodCounts[methodKey] = (paymentMethodCounts[methodKey] ?? 0) + 1;
    }

    // Traiter les consommations
    for (final consumptionJson in consumptionsResponse) {
      final consumption = Consumption.fromMap(consumptionJson);
      final stockItemData = consumptionJson['stock_items'];
      
      if (stockItemData != null) {
        final stockItem = StockItem.fromMap(stockItemData);
        final consumptionTotal = consumption.totalPrice;

        if (stockItem.category == 'DRINK') {
          totalBoissons += consumptionTotal;
        } else if (stockItem.category == 'FOOD') {
          totalNourritures += consumptionTotal;
        }

        categoryTotals[stockItem.category] = (categoryTotals[stockItem.category] ?? 0) + consumptionTotal;
        categoryItemCounts[stockItem.category] = (categoryItemCounts[stockItem.category] ?? 0) + consumption.quantity;
      }
    }

    final categorieDetails = categoryTotals.entries.map((entry) {
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

    final methodesPaiementDetails = paymentMethodTotals.entries.map((entry) {
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

    return DailyStatistics(
      date: date,
      fondCaisseOuverture: 0.0, // À renseigner manuellement
      fondCaisseFermeture: 0.0, // À renseigner manuellement
      montantCoffre: 0.0, // À renseigner manuellement
      totalBancontact: totalBancontact,
      totalCash: totalCash,
      totalVirement: totalVirement,
      totalBoissons: totalBoissons,
      totalNourritures: totalNourritures,
      categorieDetails: categorieDetails,
      methodesPaiementDetails: methodesPaiementDetails,
    );
  }

  Future<void> updateManualFields({
    required DateTime date,
    double? fondCaisseOuverture,
    double? fondCaisseFermeture,
    double? montantCoffre,
  }) async {
    final data = <String, dynamic>{};
    
    if (fondCaisseOuverture != null) {
      data['fond_caisse_ouverture'] = fondCaisseOuverture;
    }
    if (fondCaisseFermeture != null) {
      data['fond_caisse_fermeture'] = fondCaisseFermeture;
    }
    if (montantCoffre != null) {
      data['montant_coffre'] = montantCoffre;
    }
    
    data['date'] = date.toIso8601String().substring(0, 10);
    data['updated_at'] = DateTime.now().toIso8601String();

    await _supabase
        .from('daily_statistics')
        .upsert(data);
  }

  Future<Map<String, double?>> getManualFields(DateTime date) async {
    final response = await _supabase
        .from('daily_statistics')
        .select('fond_caisse_ouverture, fond_caisse_fermeture, montant_coffre')
        .eq('date', date.toIso8601String().substring(0, 10))
        .maybeSingle();

    return {
      'fond_caisse_ouverture': response?['fond_caisse_ouverture']?.toDouble(),
      'fond_caisse_fermeture': response?['fond_caisse_fermeture']?.toDouble(),
      'montant_coffre': response?['montant_coffre']?.toDouble(),
    };
  }
}