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
    // Vérifier si le notifier existe déjà et s'il est toujours valide
    if (_consumptionPriceNotifiers.containsKey(bookingId)) {
      try {
        // Essayer d'accéder à la valeur pour vérifier si le notifier est valide
        final notifier = _consumptionPriceNotifiers[bookingId]!;
        // Si le notifier a déjà été disposé, une exception sera levée ici
        // On l'utilise juste pour le test
        final _ = notifier.value;
        return notifier;
      } catch (e) {
        // Si une exception est levée, le notifier n'est plus valide
        // Le supprimer et en créer un nouveau
        debugPrint(
          'ConsumptionPriceService: Replacing invalid notifier for $bookingId',
        );
        _consumptionPriceNotifiers.remove(bookingId);
      }
    }

    // Créer un nouveau notifier
    _consumptionPriceNotifiers[bookingId] = ValueNotifier<double>(0);
    return _consumptionPriceNotifiers[bookingId]!;
  }

  // Mettre à jour le prix des consommations pour une réservation
  // de manière sécurisée, compatible avec les cycles de vie de Flutter
  void updateConsumptionPrice(String bookingId, double price) {
    // Vérifier d'abord si le notifier existe pour ce bookingId
    if (!_consumptionPriceNotifiers.containsKey(bookingId)) {
      // Si pas de notifier, créer un nouveau mais ne pas notifier tout de suite
      _consumptionPriceNotifiers[bookingId] = ValueNotifier<double>(price);
      return;
    }

    final notifier = _consumptionPriceNotifiers[bookingId]!;

    // Ne mettre à jour que si la valeur a changé
    if (notifier.value != price) {
      // Utiliser un microtask pour éviter les problèmes de mise à jour pendant build
      Future.microtask(() {
        try {
          // Vérifier à nouveau que le notifier existe et n'est pas disposé
          if (_consumptionPriceNotifiers.containsKey(bookingId)) {
            final currentNotifier = _consumptionPriceNotifiers[bookingId]!;
            if (currentNotifier.value != price) {
              currentNotifier.value = price;
            }
          }
        } catch (e) {
          debugPrint('Erreur lors de la mise à jour du prix: $e');
        }
      });
    }
  }

  // Version synchrone pour les mises à jour immédiates
  // À utiliser uniquement lorsque vous avez besoin d'une mise à jour immédiate
  // et que vous êtes sûr que vous n'êtes pas dans un cycle de build
  void updateConsumptionPriceSync(String bookingId, double price) {
    // Vérifier d'abord si le notifier existe pour ce bookingId
    if (!_consumptionPriceNotifiers.containsKey(bookingId)) {
      // Si pas de notifier, créer un nouveau avec la valeur directement
      _consumptionPriceNotifiers[bookingId] = ValueNotifier<double>(price);
      debugPrint('ConsumptionPriceService: Created new notifier with value $price for booking $bookingId');
      return;
    }

    final notifier = _consumptionPriceNotifiers[bookingId]!;

    // Ne mettre à jour que si la valeur a changé pour éviter les notifications inutiles
    if (notifier.value != price) {
      try {
        // Pour la version sync, essayer une mise à jour immédiate d'abord
        try {
          notifier.value = price;
          debugPrint('ConsumptionPriceService: Immediate sync update to $price for booking $bookingId');
        } catch (e) {
          // Si échec immédiat, utiliser microtask comme fallback
          Future.microtask(() {
            try {
              if (_consumptionPriceNotifiers.containsKey(bookingId)) {
                final currentNotifier = _consumptionPriceNotifiers[bookingId]!;
                if (currentNotifier.value != price) {
                  currentNotifier.value = price;
                  debugPrint('ConsumptionPriceService: Deferred sync update to $price for booking $bookingId');
                }
              }
            } catch (e) {
              debugPrint('Erreur lors de la mise à jour différée du prix: $e');
            }
          });
        }
      } catch (e) {
        debugPrint(
          'Erreur lors de la mise à jour synchrone du prix: $e',
        );
      }
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
