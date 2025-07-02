import 'package:flutter/foundation.dart';

// Classe singleton pour gérer les notifications entre les widgets de consommation et de paiement
class ConsumptionPriceService {
  // Instance singleton
  static final ConsumptionPriceService _instance =
      ConsumptionPriceService._internal();

  // Map de notifiers par ID de réservation
  final Map<String, ValueNotifier<double>> _consumptionPriceNotifiers = {};

  // Constructeur de factory qui renvoie l'instance singleton
  factory ConsumptionPriceService() {
    return _instance;
  }

  // Constructeur privé
  ConsumptionPriceService._internal();

  // Obtenir ou créer un notifier pour une réservation spécifique
  ValueNotifier<double> getNotifierForBooking(String bookingId) {
    if (!_consumptionPriceNotifiers.containsKey(bookingId)) {
      _consumptionPriceNotifiers[bookingId] = ValueNotifier<double>(0);
    }
    return _consumptionPriceNotifiers[bookingId]!;
  }

  // Mettre à jour le prix des consommations pour une réservation
  void updateConsumptionPrice(String bookingId, double price) {
    final notifier = getNotifierForBooking(bookingId);
    // Ne mettre à jour que si la valeur a changé
    // Cela réduit les notifications inutiles
    if (notifier.value != price) {
      notifier.value = price;
    }
  }

  // Nettoyer les notifiers lorsqu'ils ne sont plus nécessaires
  void cleanupNotifier(String bookingId) {
    if (_consumptionPriceNotifiers.containsKey(bookingId)) {
      _consumptionPriceNotifiers[bookingId]?.dispose();
      _consumptionPriceNotifiers.remove(bookingId);
    }
  }

  // Nettoyer tous les notifiers
  void dispose() {
    for (final notifier in _consumptionPriceNotifiers.values) {
      notifier.dispose();
    }
    _consumptionPriceNotifiers.clear();
  }
}
