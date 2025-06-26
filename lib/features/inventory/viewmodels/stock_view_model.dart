// filepath: /Users/thimotefetu/Sites/Laser-Magique-App/lib/viewmodels/stock_view_model.dart
import 'package:flutter/foundation.dart';
import '../models/stock_item_model.dart';
import '../../../shared/models/consumption_model.dart';
import '../repositories/stock_repository.dart';
import '../../booking/viewmodels/booking_view_model.dart';

class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration expiration;

  CacheEntry({
    required this.data,
    required this.timestamp,
    this.expiration = const Duration(minutes: 5),
  });

  bool get isExpired => DateTime.now().difference(timestamp) > expiration;
}

class ConsumptionCacheEntry {
  final List<(Consumption, StockItem)> consumptions;
  final double total;
  final DateTime timestamp;

  ConsumptionCacheEntry({
    required this.consumptions,
    required this.total,
    required this.timestamp,
  });

  ConsumptionCacheEntry copyWith({
    List<(Consumption, StockItem)>? consumptions,
    double? total,
    DateTime? timestamp,
  }) {
    return ConsumptionCacheEntry(
      consumptions: consumptions ?? this.consumptions,
      total: total ?? this.total,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class StockViewModel extends ChangeNotifier {
  final StockRepository _repository = StockRepository();
  final BookingViewModel bookingViewModel;

  // Cache pour les articles en stock avec expiration
  CacheEntry<List<StockItem>>? _stockCache;
  CacheEntry<List<StockItem>>?
  _allStockCache; // Cache incluant les articles inactifs

  // Cache pour les consommations par réservation avec expiration
  final Map<String, CacheEntry<ConsumptionCacheEntry>> _consumptionsCache = {};

  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;
  bool _initialized = false;

  StockViewModel(this.bookingViewModel);

  // Getters
  List<StockItem> get items => _stockCache?.data ?? [];
  List<StockItem> get allItems =>
      _allStockCache?.data ?? []; // Inclut les articles inactifs
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _initialized;

  // Initialize data
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await refreshStock();
      await refreshAllStock(); // Charger aussi les articles inactifs

      _isLoading = false;
      _initialized = true;
      notifyListeners();
    } catch (e) {
      _error = 'Error loading data: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Rafraîchir les données du stock actif
  Future<void> refreshStock() async {
    try {
      final items = await _repository.getAllStockItems(includeInactive: false);
      _stockCache = CacheEntry<List<StockItem>>(
        data: items,
        timestamp: DateTime.now(),
      );
      notifyListeners();
    } catch (e) {
      _error = 'Error refreshing stock: $e';
      notifyListeners();
    }
  }

  // Rafraîchir tous les articles, y compris inactifs
  Future<void> refreshAllStock() async {
    try {
      final items = await _repository.getAllStockItems(includeInactive: true);
      _allStockCache = CacheEntry<List<StockItem>>(
        data: items,
        timestamp: DateTime.now(),
      );
      notifyListeners();
    } catch (e) {
      _error = 'Error refreshing all stock: $e';
      notifyListeners();
    }
  }

  // Méthodes de gestion des articles en stock
  Future<void> addItem({
    required String name,
    required int quantity,
    required double price,
    required int alertThreshold,
    required String category,
  }) async {
    try {
      await _repository.createStockItem(
        name: name,
        quantity: quantity,
        price: price,
        alertThreshold: alertThreshold,
        category: category,
      );
      await refreshStock();
      await refreshAllStock();
    } catch (e) {
      _error = 'Error adding item: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateItem(StockItem item) async {
    try {
      await _repository.updateStockItem(item);
      await refreshStock();
      await refreshAllStock();
    } catch (e) {
      _error = 'Error updating item: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Au lieu de supprimer, on désactive l'article
  Future<void> deactivateItem(String itemId) async {
    try {
      await _repository.setItemActive(itemId, false);
      await refreshStock();
      await refreshAllStock();
    } catch (e) {
      _error = 'Error deactivating item: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Réactiver un article désactivé
  Future<void> activateItem(String itemId) async {
    try {
      await _repository.setItemActive(itemId, true);
      await refreshStock();
      await refreshAllStock();
    } catch (e) {
      _error = 'Error activating item: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> adjustQuantity(String itemId, int delta) async {
    try {
      final item = items.firstWhere((item) => item.id == itemId);
      if (item.quantity + delta < 0) {
        throw Exception('La quantité ne peut pas être négative');
      }

      final updatedItem = item.copyWith(quantity: item.quantity + delta);
      await updateItem(updatedItem);
    } catch (e) {
      _error = 'Error adjusting quantity: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Modified getters to only return active items
  List<StockItem> get filteredItems {
    final items =
        _stockCache?.isExpired == true ? [] : (_stockCache?.data ?? []);
    final List<StockItem> activeItems =
        items.where((item) => item.isActive).toList().cast<StockItem>();
    return _searchQuery.isEmpty
        ? activeItems
        : activeItems
            .where(
              (item) =>
                  item.name.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();
  }

  List<StockItem> get inactiveItems =>
      (_stockCache?.data ?? []).where((item) => !item.isActive).toList();

  List<StockItem> get drinks =>
      filteredItems
          .where((item) => item.category == 'DRINK' && item.isActive)
          .toList();

  List<StockItem> get food =>
      filteredItems
          .where((item) => item.category == 'FOOD' && item.isActive)
          .toList();

  List<StockItem> get others =>
      filteredItems
          .where((item) => item.category == 'OTHER' && item.isActive)
          .toList();

  List<StockItem> get lowStockItems =>
      filteredItems.where((item) => item.isLowStock).toList();

  // Méthodes de gestion des consommations
  List<(Consumption, StockItem)> getCachedConsumptions(String bookingId) {
    final cacheEntry = _consumptionsCache[bookingId];
    if (cacheEntry != null && !cacheEntry.isExpired) {
      return cacheEntry.data.consumptions;
    }
    return [];
  }

  double getConsumptionTotal(String bookingId) {
    final cacheEntry = _consumptionsCache[bookingId];
    if (cacheEntry != null) {
      return cacheEntry.data.total;
    }
    return 0.0;
  }

  // Invalider tout le cache de consommations
  void invalidateConsumptionsCache() {
    _consumptionsCache.clear();
    notifyListeners();
  }

  // Invalider le cache pour une réservation spécifique
  void invalidateConsumptionsCacheForBooking(String bookingId) {
    _consumptionsCache.remove(bookingId);
    notifyListeners();
  }

  Future<List<(Consumption, StockItem)>> getConsumptionsWithStockItems(
    String bookingId,
  ) async {
    if (!_initialized) {
      await initialize();
    }

    // Vérifier si le cache est valide
    final cachedEntry = _consumptionsCache[bookingId];
    if (cachedEntry != null && !cachedEntry.isExpired) {
      return cachedEntry.data.consumptions;
    }

    try {
      final consumptions = await _repository.getConsumptionsForBooking(
        bookingId,
      );
      final result =
          consumptions.map((consumption) {
            final stockItem = items.firstWhere(
              (item) => item.id == consumption.stockItemId,
              orElse: () => throw Exception('Article introuvable'),
            );
            return (consumption, stockItem);
          }).toList();

      // Mettre à jour le cache avec les nouvelles données
      _updateConsumptionsCache(bookingId, result);

      return result;
    } catch (e) {
      _error = 'Erreur lors de la récupération des consommations: $e';
      notifyListeners();
      // Retourner les données en cache même si expirées en cas d'erreur
      return cachedEntry?.data.consumptions ?? [];
    }
  }

  Future<bool> addConsumption({
    required String bookingId,
    required String stockItemId,
    required int quantity,
  }) async {
    try {
      final result = await _repository.addConsumption(
        bookingId: bookingId,
        stockItemId: stockItemId,
        quantity: quantity,
      );

      final stockItem = items.firstWhere((item) => item.id == stockItemId);

      // Mettre à jour le cache
      _addConsumptionToCache(bookingId, result, stockItem);

      // Rafraîchir le stock car il a été modifié
      await refreshStock();

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> updateConsumptionQuantity({
    required Consumption consumption,
    required int newQuantity,
  }) async {
    if (newQuantity < 1) {
      throw Exception('La quantité ne peut pas être inférieure à 1');
    }

    final updatedConsumption = consumption.copyWith(quantity: newQuantity);
    final previousConsumption = consumption;

    try {
      await _repository.updateConsumption(updatedConsumption);

      // Mise à jour du cache
      _updateConsumptionInCache(consumption.bookingId, updatedConsumption);

      // Rafraîchir les données du stock
      await refreshStock();
    } catch (e) {
      // Restaurer l'ancienne valeur dans le cache en cas d'erreur
      _updateConsumptionInCache(consumption.bookingId, previousConsumption);
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> deleteConsumption({required Consumption consumption}) async {
    final bookingId = consumption.bookingId;
    _removeConsumptionFromCache(bookingId, consumption.id);

    try {
      await _repository.deleteConsumption(consumption.id);
      await refreshStock();
    } catch (e) {
      // Restaurer la consommation dans le cache en cas d'erreur
      final stockItem = items.firstWhere(
        (item) => item.id == consumption.stockItemId,
      );
      _addConsumptionToCache(bookingId, consumption, stockItem);
      _error = 'Error deleting consumption: $e';
      rethrow;
    }
  }

  // Méthodes privées de gestion du cache
  void _updateConsumptionsCache(
    String bookingId,
    List<(Consumption, StockItem)> consumptions,
  ) {
    final total = calculateConsumptionTotal(consumptions);
    _consumptionsCache[bookingId] = CacheEntry<ConsumptionCacheEntry>(
      data: ConsumptionCacheEntry(
        consumptions: consumptions,
        total: total,
        timestamp: DateTime.now(),
      ),
      timestamp: DateTime.now(),
    );
    notifyListeners();
    bookingViewModel.updateBookingTotals(bookingId, total);
  }

  void _addConsumptionToCache(
    String bookingId,
    Consumption consumption,
    StockItem stockItem,
  ) {
    final cacheEntry = _consumptionsCache[bookingId];
    if (cacheEntry != null) {
      final consumptions = List<(Consumption, StockItem)>.from(
        cacheEntry.data.consumptions,
      );
      consumptions.add((consumption, stockItem));
      _updateConsumptionsCache(bookingId, consumptions);
    } else {
      _updateConsumptionsCache(bookingId, [(consumption, stockItem)]);
    }
  }

  void _updateConsumptionInCache(
    String bookingId,
    Consumption updatedConsumption,
  ) {
    final cacheEntry = _consumptionsCache[bookingId];
    if (cacheEntry != null) {
      final consumptions = List<(Consumption, StockItem)>.from(
        cacheEntry.data.consumptions,
      );
      final index = consumptions.indexWhere(
        (pair) => pair.$1.id == updatedConsumption.id,
      );
      if (index != -1) {
        consumptions[index] = (updatedConsumption, consumptions[index].$2);
        _updateConsumptionsCache(bookingId, consumptions);
      }
    }
  }

  void _removeConsumptionFromCache(String bookingId, String consumptionId) {
    final cacheEntry = _consumptionsCache[bookingId];
    if (cacheEntry != null) {
      final consumptions = List<(Consumption, StockItem)>.from(
        cacheEntry.data.consumptions,
      );
      consumptions.removeWhere((pair) => pair.$1.id == consumptionId);
      _updateConsumptionsCache(bookingId, consumptions);
    }
  }

  double calculateConsumptionTotal(
    List<(Consumption, StockItem)> consumptions,
  ) {
    return consumptions.fold(
      0,
      (total, pair) => total + (pair.$1.quantity * pair.$1.unitPrice),
    );
  }

  Future<void> refreshStockItems() async {
    try {
      final items = await _repository.getAllStockItems(includeInactive: true);
      _stockCache = CacheEntry(data: items, timestamp: DateTime.now());
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing stock items: $e');
      rethrow;
    }
  }
}
