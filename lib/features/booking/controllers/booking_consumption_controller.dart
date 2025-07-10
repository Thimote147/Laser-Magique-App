import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../../shared/models/consumption_model.dart';
import '../../inventory/models/stock_item_model.dart';
import '../../../shared/services/consumption_price_service.dart';
import '../../../shared/services/social_deal_service.dart';
import '../../inventory/viewmodels/stock_view_model.dart';
import '../viewmodels/booking_view_model.dart';

/// Controller externe pour gérer l'état des consommations
/// sans provoquer de rebuilds du widget
class BookingConsumptionController {
  static final Map<String, BookingConsumptionController> _instances = {};

  final String bookingId;
  final ConsumptionPriceService _priceService = ConsumptionPriceService();
  final SocialDealService _socialDealService = SocialDealService();

  // État interne
  final ValueNotifier<double> totalAmountNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<List<(Consumption, StockItem)>?> consumptionsNotifier =
      ValueNotifier<List<(Consumption, StockItem)>?>(null);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(true);

  // Map des quantités par consommation
  final Map<String, ValueNotifier<int>> _quantityNotifiers = {};

  bool _isInitialized = false;

  BookingConsumptionController._(this.bookingId);

  /// Factory pour obtenir ou créer un controller pour une réservation
  factory BookingConsumptionController.forBooking(String bookingId) {
    if (!_instances.containsKey(bookingId)) {
      _instances[bookingId] = BookingConsumptionController._(bookingId);
    }
    return _instances[bookingId]!;
  }

  /// Pré-initialiser le service de prix avec la valeur en cache pour éviter la fluctuation
  static void preInitializePriceService(
    BuildContext context,
    String bookingId,
  ) {
    try {
      final stockVM = Provider.of<StockViewModel>(context, listen: false);
      final cachedTotal = stockVM.getConsumptionTotal(bookingId);

      if (cachedTotal > 0) {
        final priceService = ConsumptionPriceService();
        // Synchroniser immédiatement avec la valeur en cache
        priceService.updateConsumptionPriceSync(bookingId, cachedTotal);
        debugPrint(
          'BookingConsumptionController: Pre-initialized price service with $cachedTotal for booking $bookingId',
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de la pré-initialisation: $e');
    }
  }

  /// Initialiser le controller
  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      isLoadingNotifier.value = true;

      final stockVM = Provider.of<StockViewModel>(context, listen: false);

      // AVANT de charger, synchroniser immédiatement avec le cache pour éviter la fluctuation
      final cachedTotal = stockVM.getConsumptionTotal(bookingId);
      if (cachedTotal > 0) {
        totalAmountNotifier.value = cachedTotal;
        _priceService.updateConsumptionPriceSync(bookingId, cachedTotal);
        debugPrint(
          'BookingConsumptionController: Pre-sync with cached total $cachedTotal for booking $bookingId',
        );
      }

      // Charger les consommations depuis le StockViewModel
      final consumptions = await stockVM.getConsumptionsWithStockItems(
        bookingId,
      );

      // Mettre à jour la liste des consommations
      consumptionsNotifier.value = consumptions;

      // Calculer et mettre à jour le total final
      final finalTotalAmount = stockVM.calculateConsumptionTotal(consumptions);

      // Ne mettre à jour que si la valeur finale est différente du cache
      if (finalTotalAmount != cachedTotal) {
        totalAmountNotifier.value = finalTotalAmount;
        _priceService.updateConsumptionPriceSync(bookingId, finalTotalAmount);
        debugPrint(
          'BookingConsumptionController: Final sync with total $finalTotalAmount for booking $bookingId',
        );
      }

      isLoadingNotifier.value = false;
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation du controller: $e');
      isLoadingNotifier.value = false;
    }
  }

  /// Obtenir ou créer un notifier de quantité pour une consommation
  ValueNotifier<int> getQuantityNotifier(
    String consumptionId,
    int initialQuantity,
  ) {
    if (!_quantityNotifiers.containsKey(consumptionId)) {
      _quantityNotifiers[consumptionId] = ValueNotifier<int>(initialQuantity);
    }
    return _quantityNotifiers[consumptionId]!;
  }

  /// Mettre à jour le total
  void updateTotal(double newTotal) {
    if (totalAmountNotifier.value != newTotal) {
      totalAmountNotifier.value = newTotal;
      // Utiliser une mise à jour immédiate ET une différée pour maximiser la synchronisation
      _priceService.updateConsumptionPriceSync(bookingId, newTotal);

      // Ajouter un debug pour voir si la synchronisation fonctionne
      debugPrint(
        'BookingConsumptionController: Updated total to $newTotal for booking $bookingId',
      );
    }
  }

  /// Mettre à jour la quantité d'une consommation
  Future<void> updateConsumptionQuantity(
    BuildContext context,
    String consumptionId,
    int newQuantity,
  ) async {
    try {
      final stockVM = Provider.of<StockViewModel>(context, listen: false);
      final currentConsumptions = consumptionsNotifier.value ?? [];

      // Trouver la consommation à mettre à jour
      final consumptionIndex = currentConsumptions.indexWhere(
        (pair) => pair.$1.id == consumptionId,
      );

      if (consumptionIndex == -1) return;

      final consumption = currentConsumptions[consumptionIndex].$1;
      final stockItem = currentConsumptions[consumptionIndex].$2;

      // Mettre à jour l'UI immédiatement
      final quantityNotifier = getQuantityNotifier(
        consumptionId,
        consumption.quantity,
      );
      quantityNotifier.value = newQuantity;

      // Recalculer le prix avec la logique Social Deal
      final bookingVM = Provider.of<BookingViewModel>(context, listen: false);
      final booking = await bookingVM.getBooking(bookingId);
      
      // Créer une liste des consommations existantes (sans celle qu'on modifie)
      final existingConsumptions = currentConsumptions
          .where((pair) => pair.$1.id != consumptionId)
          .map((pair) => pair.$1)
          .toList();

      // Recréer la consommation avec le service Social Deal
      final updatedConsumption = _socialDealService.createConsumption(
        id: consumption.id,
        bookingId: consumption.bookingId,
        stockItemId: consumption.stockItemId,
        quantity: newQuantity,
        timestamp: consumption.timestamp,
        formula: booking.formula,
        stockItem: stockItem,
        bookingPersons: booking.numberOfPersons,
        existingConsumptions: existingConsumptions,
        allStockItems: stockVM.items, // Pass all stock items for proper Social Deal quota calculation
      );

      // Créer une nouvelle liste avec la quantité mise à jour
      final updatedConsumptions = List<(Consumption, StockItem)>.from(
        currentConsumptions,
      );
      updatedConsumptions[consumptionIndex] = (updatedConsumption, stockItem);

      // Calculer le nouveau total
      final newTotal = stockVM.calculateConsumptionTotal(updatedConsumptions);
      updateTotal(newTotal);

      // Mettre à jour en base de données
      await stockVM.updateConsumptionQuantity(
        consumption: consumption,
        newQuantity: newQuantity,
      );

      // Recharger les données pour s'assurer de la cohérence
      if (context.mounted) {
        await reloadConsumptions(context);
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de la quantité: $e');
      // Restaurer l'ancienne valeur en cas d'erreur
      final quantityNotifier = getQuantityNotifier(consumptionId, 0);
      final currentConsumptions = consumptionsNotifier.value ?? [];
      final consumption = currentConsumptions.firstWhere(
        (pair) => pair.$1.id == consumptionId,
        orElse:
            () => (
              Consumption(
                id: '',
                bookingId: '',
                stockItemId: '',
                quantity: 0,
                unitPrice: 0.0,
                timestamp: DateTime.now(),
              ),
              StockItem(
                id: '',
                name: '',
                category: '',
                price: 0.0,
                quantity: 0,
                alertThreshold: 0,
              ),
            ),
      );
      quantityNotifier.value = consumption.$1.quantity;
      rethrow;
    }
  }

  /// Supprimer une consommation
  Future<void> deleteConsumption(
    BuildContext context,
    String consumptionId,
  ) async {
    try {
      final stockVM = Provider.of<StockViewModel>(context, listen: false);
      final currentConsumptions = consumptionsNotifier.value ?? [];

      // Trouver la consommation à supprimer
      final consumptionToDelete = currentConsumptions.firstWhere(
        (pair) => pair.$1.id == consumptionId,
        orElse: () => throw Exception('Consommation non trouvée'),
      );

      final consumption = consumptionToDelete.$1;

      // Mise à jour optimiste de l'UI - supprimer immédiatement de la liste
      final updatedConsumptions =
          currentConsumptions
              .where((pair) => pair.$1.id != consumptionId)
              .toList();

      consumptionsNotifier.value = updatedConsumptions;

      // Calculer et mettre à jour le nouveau total
      final newTotal = stockVM.calculateConsumptionTotal(updatedConsumptions);
      updateTotal(newTotal);

      // Nettoyer le notifier de quantité pour cette consommation
      if (_quantityNotifiers.containsKey(consumptionId)) {
        _quantityNotifiers[consumptionId]?.dispose();
        _quantityNotifiers.remove(consumptionId);
      }

      // Supprimer en base de données
      await stockVM.deleteConsumption(consumption: consumption);

      debugPrint(
        'BookingConsumptionController: Deleted consumption $consumptionId for booking $bookingId',
      );
    } catch (e) {
      debugPrint('Erreur lors de la suppression de la consommation: $e');
      // En cas d'erreur, recharger les données pour restaurer l'état correct
      if (context.mounted) {
        await reloadConsumptions(context);
      }
      rethrow;
    }
  }

  /// Recharger les consommations (méthode publique)
  Future<void> reloadConsumptions(BuildContext context) async {
    debugPrint(
      'BookingConsumptionController: Reloading consumptions for booking $bookingId',
    );
    isLoadingNotifier.value = true;
    try {
      await _reloadConsumptions(context);
    } finally {
      isLoadingNotifier.value = false;
      debugPrint(
        'BookingConsumptionController: Reload completed for booking $bookingId',
      );
    }
  }

  /// Réinitialiser complètement le controller
  Future<void> reset(BuildContext context) async {
    debugPrint(
      'BookingConsumptionController: Resetting controller for booking $bookingId',
    );
    isLoadingNotifier.value = true;
    _isInitialized = false;
    try {
      await initialize(context);
    } finally {
      isLoadingNotifier.value = false;
      debugPrint(
        'BookingConsumptionController: Reset completed for booking $bookingId',
      );
    }
  }

  /// Recharger les consommations
  Future<void> _reloadConsumptions(BuildContext context) async {
    try {
      final stockVM = Provider.of<StockViewModel>(context, listen: false);
      final consumptions = await stockVM.getConsumptionsWithStockItems(
        bookingId,
      );
      consumptionsNotifier.value = consumptions;

      final totalAmount = stockVM.calculateConsumptionTotal(consumptions);
      updateTotal(totalAmount);
    } catch (e) {
      debugPrint('Erreur lors du rechargement des consommations: $e');
    }
  }

  /// Forcer la synchronisation avec le service de prix
  /// (utile quand on revient sur une page)
  Future<void> forceSyncWithPriceService(BuildContext context) async {
    try {
      final stockVM = Provider.of<StockViewModel>(context, listen: false);

      // Obtenir le total actuel depuis le cache ou la base de données
      final cachedTotal = stockVM.getConsumptionTotal(bookingId);
      final currentServiceTotal =
          _priceService.getNotifierForBooking(bookingId).value;

      // Ne synchroniser que si les valeurs sont différentes
      if (cachedTotal > 0 && cachedTotal != currentServiceTotal) {
        totalAmountNotifier.value = cachedTotal;
        _priceService.updateConsumptionPriceSync(bookingId, cachedTotal);
        debugPrint(
          'BookingConsumptionController: Force sync - updated price service with total $cachedTotal for booking $bookingId',
        );
      } else if (cachedTotal == 0 && currentServiceTotal == 0) {
        // Si pas de cache, recharger depuis la base de données
        await _reloadConsumptions(context);
      }
      // Sinon, les valeurs sont déjà synchronisées, ne rien faire
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation forcée: $e');
    }
  }

  /// Nettoyer le controller
  void dispose() {
    totalAmountNotifier.dispose();
    consumptionsNotifier.dispose();
    isLoadingNotifier.dispose();

    for (final notifier in _quantityNotifiers.values) {
      notifier.dispose();
    }
    _quantityNotifiers.clear();

    _priceService.cleanupNotifier(bookingId);
    _instances.remove(bookingId);
  }

  /// Nettoyer tous les controllers
  static void disposeAll() {
    for (final controller in _instances.values) {
      controller.dispose();
    }
    _instances.clear();
  }
}
