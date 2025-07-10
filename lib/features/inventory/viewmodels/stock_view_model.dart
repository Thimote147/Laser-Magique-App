// filepath: /Users/thimotefetu/Sites/Laser-Magique-App/lib/viewmodels/stock_view_model.dart
import 'package:flutter/foundation.dart';
import '../models/stock_item_model.dart';
import '../../../shared/models/consumption_model.dart';
import '../../../shared/models/formula_model.dart';
import '../../../shared/services/consumption_price_service.dart';
import '../../../shared/services/social_deal_service.dart';
import '../../../shared/services/notification_service.dart';
import '../repositories/stock_repository.dart';
import '../../booking/viewmodels/booking_view_model.dart';
import 'dart:async';

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
  final SocialDealService _socialDealService = SocialDealService();
  final NotificationService _notificationService = NotificationService();

  // Cache pour les articles en stock avec expiration
  CacheEntry<List<StockItem>>? _stockCache;
  CacheEntry<List<StockItem>>?
  _allStockCache; // Cache incluant les articles inactifs

  // Cache pour les consommations par réservation avec expiration
  final Map<String, CacheEntry<ConsumptionCacheEntry>> _consumptionsCache = {};

  // Cache local pour les consommations en cours de modification
  // Ce cache est prioritaire sur la base de données pour des mises à jour immédiates
  final Map<String, List<(Consumption, StockItem)>> _localConsumptionsCache =
      {};

  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;
  bool _initialized = false;
  
  // Realtime subscription management
  StreamSubscription<List<StockItem>>? _stockItemsSubscription;
  StreamSubscription<List<Consumption>>? _consumptionsSubscription;
  final Map<String, StreamSubscription<List<Consumption>>> _consumptionSubscriptions = {};

  StockViewModel(this.bookingViewModel) {
    initialize();
    _initializeRealtimeSubscriptions();
  }
  
  // Initialize realtime subscriptions
  void _initializeRealtimeSubscriptions() {
    _repository.initializeRealtimeSubscriptions();
    
    // Subscribe to stock items changes
    _stockItemsSubscription = _repository.stockItemsStream.listen(
      (stockItems) {
        _handleRealtimeStockItemsUpdate(stockItems);
      },
      onError: (error) {
        debugPrint('Error in stock items stream: $error');
      },
    );
    
    // Subscribe to consumptions changes
    _consumptionsSubscription = _repository.consumptionsStream.listen(
      (consumptions) {
        _handleRealtimeConsumptionsUpdate(consumptions);
      },
      onError: (error) {
        debugPrint('Error in consumptions stream: $error');
      },
    );
  }
  
  // Handle realtime stock items updates
  void _handleRealtimeStockItemsUpdate(List<StockItem> stockItems) {
    debugPrint('StockViewModel: Received realtime stock items update with ${stockItems.length} items');
    
    // Update cache immediately
    _stockCache = CacheEntry<List<StockItem>>(
      data: stockItems.where((item) => item.isActive).toList(),
      timestamp: DateTime.now(),
    );
    
    _allStockCache = CacheEntry<List<StockItem>>(
      data: stockItems,
      timestamp: DateTime.now(),
    );
    
    // Notify listeners immediately for UI update
    notifyListeners();
  }
  
  // Handle realtime consumptions updates
  void _handleRealtimeConsumptionsUpdate(List<Consumption> consumptions) {
    debugPrint('StockViewModel: Received realtime consumptions update with ${consumptions.length} consumptions');
    
    // Group consumptions by booking ID
    final Map<String, List<Consumption>> consumptionsByBooking = {};
    for (final consumption in consumptions) {
      if (!consumptionsByBooking.containsKey(consumption.bookingId)) {
        consumptionsByBooking[consumption.bookingId] = [];
      }
      consumptionsByBooking[consumption.bookingId]!.add(consumption);
    }
    
    // Update cache for each booking
    for (final entry in consumptionsByBooking.entries) {
      final bookingId = entry.key;
      final bookingConsumptions = entry.value;
      
      // Convert to (Consumption, StockItem) pairs
      final consumptionPairs = bookingConsumptions.map((consumption) {
        final stockItem = findStockItemById(consumption.stockItemId);
        if (stockItem != null) {
          return (consumption, stockItem);
        }
        return null;
      }).whereType<(Consumption, StockItem)>().toList();
      
      // Update cache
      _updateConsumptionsCache(bookingId, consumptionPairs);
    }
    
    // Notify listeners
    notifyListeners();
  }
  
  // Subscribe to consumptions for a specific booking
  void subscribeToBookingConsumptions(String bookingId) {
    if (_consumptionSubscriptions.containsKey(bookingId)) {
      return; // Already subscribed
    }
    
    _consumptionSubscriptions[bookingId] = _repository.getConsumptionsStreamForBooking(bookingId).listen(
      (consumptions) {
        _handleBookingConsumptionsUpdate(bookingId, consumptions);
      },
      onError: (error) {
        debugPrint('Error in booking consumptions stream for $bookingId: $error');
      },
    );
  }
  
  // Unsubscribe from consumptions for a specific booking
  void unsubscribeFromBookingConsumptions(String bookingId) {
    _consumptionSubscriptions[bookingId]?.cancel();
    _consumptionSubscriptions.remove(bookingId);
  }
  
  // Handle booking-specific consumptions updates
  void _handleBookingConsumptionsUpdate(String bookingId, List<Consumption> consumptions) {
    debugPrint('StockViewModel: Received booking consumptions update for $bookingId with ${consumptions.length} consumptions');
    
    // Convert to (Consumption, StockItem) pairs
    final consumptionPairs = consumptions.map((consumption) {
      final stockItem = findStockItemById(consumption.stockItemId);
      if (stockItem != null) {
        return (consumption, stockItem);
      }
      return null;
    }).whereType<(Consumption, StockItem)>().toList();
    
    // Update cache for this booking
    _updateConsumptionsCache(bookingId, consumptionPairs);
    
    // Notify listeners
    notifyListeners();
  }
  
  @override
  void dispose() {
    _stockItemsSubscription?.cancel();
    _consumptionsSubscription?.cancel();
    
    // Cancel all booking-specific subscriptions
    for (final subscription in _consumptionSubscriptions.values) {
      subscription.cancel();
    }
    _consumptionSubscriptions.clear();
    
    // Dispose repository
    _repository.dispose();
    
    super.dispose();
  }

  // Getters
  List<StockItem> get items => _stockCache?.data ?? [];
  List<StockItem> get allItems =>
      _allStockCache?.data ?? []; // Inclut les articles inactifs
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _initialized;

  // Initialize data
  Future<void> initialize() async {
    if (_initialized && !_stockCache!.isExpired) return;

    try {
      _isLoading = true;
      _error = null;
      // Notifier de manière asynchrone
      Future.microtask(() {
        notifyListeners();
      });

      // Rafraîchir le stock en parallèle pour optimiser le chargement
      await Future.wait([
        refreshStock(silent: true),
        refreshAllStock(silent: true), // Charger aussi les articles inactifs
      ]);

      _isLoading = false;
      _initialized = true;

      // Notifier de manière asynchrone
      Future.microtask(() {
        notifyListeners();
      });
    } catch (e) {
      _error = 'Error loading data: $e';
      _isLoading = false;

      // Notifier de manière asynchrone
      Future.microtask(() {
        notifyListeners();
      });
    }
  }

  // Force une initialisation même si déjà initialisé
  Future<void> forceInitialize() async {
    try {
      _isLoading = true;
      _error = null;
      // Notifier de manière asynchrone
      Future.microtask(() {
        notifyListeners();
      });

      // Rafraîchir le stock en parallèle pour optimiser le chargement
      await Future.wait([
        refreshStock(silent: true),
        refreshAllStock(silent: true), // Charger aussi les articles inactifs
      ]);

      _isLoading = false;
      _initialized = true;

      // Notifier de manière asynchrone
      Future.microtask(() {
        notifyListeners();
      });
    } catch (e) {
      _error = 'Error loading data: $e';
      _isLoading = false;

      // Notifier de manière asynchrone
      Future.microtask(() {
        notifyListeners();
      });
      // Propager l'erreur pour que le gestionnaire puisse la capturer
      rethrow;
    }
  }

  // Rafraîchir les données du stock actif
  Future<void> refreshStock({bool silent = false}) async {
    try {
      final items = await _repository.getAllStockItems(includeInactive: false);
      _stockCache = CacheEntry<List<StockItem>>(
        data: items,
        timestamp: DateTime.now(),
      );

      if (!silent) {
        notifyListeners();
      } else {
        debugPrint('StockViewModel: Silent stock refresh completed');
      }
    } catch (e) {
      _error = 'Error refreshing stock: $e';
      if (!silent) {
        notifyListeners();
      }
    }
  }

  // Rafraîchir tous les articles, y compris inactifs
  Future<void> refreshAllStock({bool silent = false}) async {
    try {
      final items = await _repository.getAllStockItems(includeInactive: true);
      _allStockCache = CacheEntry<List<StockItem>>(
        data: items,
        timestamp: DateTime.now(),
      );

      if (!silent) {
        // Notifier de manière asynchrone
        Future.microtask(() {
          notifyListeners();
        });
      } else {
        debugPrint('StockViewModel: Silent all stock refresh completed');
      }
    } catch (e) {
      _error = 'Error refreshing all stock: $e';
      if (!silent) {
        // Notifier de manière asynchrone
        Future.microtask(() {
          notifyListeners();
        });
      }
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
      // Get the current item to compare quantities
      final currentItem = items.firstWhere(
        (i) => i.id == item.id,
        orElse: () => item, // If not found, use the new item
      );
      
      await _repository.updateStockItem(item);
      await refreshStock();
      await refreshAllStock();
      
      // Send stock update notification only if quantity changed
      if (currentItem.quantity != item.quantity) {
        _notificationService.notifyStockUpdated(
          item.name,
          item.quantity,
          isLowStock: item.isLowStock,
        );
        
        // Send low stock alert if item becomes low stock
        if (item.isLowStock && !currentItem.isLowStock) {
          _notificationService.notifyStockAlert(
            item.name,
            item.quantity,
            item.alertThreshold,
          );
        }
      }
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

      final newQuantity = item.quantity + delta;
      final updatedItem = item.copyWith(quantity: newQuantity);
      await updateItem(updatedItem);
      
      // Send stock update notification
      _notificationService.notifyStockUpdated(
        item.name,
        newQuantity,
        isLowStock: updatedItem.isLowStock,
      );
      
      // Send low stock alert if item becomes low stock
      if (updatedItem.isLowStock && !item.isLowStock) {
        _notificationService.notifyStockAlert(
          item.name,
          newQuantity,
          item.alertThreshold,
        );
      }
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

  List<StockItem> get drinks {
    final items = _stockCache?.isExpired == true ? <StockItem>[] : (_stockCache?.data ?? <StockItem>[]);
    return items
        .where((item) => item.category == 'DRINK' && item.isActive)
        .toList();
  }

  List<StockItem> get food {
    final items = _stockCache?.isExpired == true ? <StockItem>[] : (_stockCache?.data ?? <StockItem>[]);
    return items
        .where((item) => item.category == 'FOOD' && item.isActive)
        .toList();
  }

  List<StockItem> get others {
    final items = _stockCache?.isExpired == true ? <StockItem>[] : (_stockCache?.data ?? <StockItem>[]);
    return items
        .where((item) => item.category == 'OTHER' && item.isActive)
        .toList();
  }

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
    // D'abord, vérifier le cache local pour avoir la valeur la plus à jour
    if (_localConsumptionsCache.containsKey(bookingId) &&
        _localConsumptionsCache[bookingId]!.isNotEmpty) {
      // Calculer le total à partir des données locales
      return calculateConsumptionTotal(_localConsumptionsCache[bookingId]!);
    }

    // Sinon, utiliser le cache persistant
    final cacheEntry = _consumptionsCache[bookingId];
    if (cacheEntry != null) {
      return cacheEntry.data.total;
    }

    // Si aucun cache n'est disponible, charger les données de manière asynchrone
    // et retourner 0 temporairement
    _loadConsumptionsAsync(bookingId);
    return 0.0;
  }

  // Invalider tout le cache de consommations
  void invalidateConsumptionsCache() {
    _consumptionsCache.clear();
    _localConsumptionsCache.clear();
    // Utiliser Future.microtask pour éviter de notifier pendant la phase de build
    Future.microtask(() {
      notifyListeners();
    });
  }

  // Invalider le cache pour une réservation spécifique
  void invalidateConsumptionsCacheForBooking(String bookingId) {
    _consumptionsCache.remove(bookingId);
    _localConsumptionsCache.remove(bookingId);
    // Utiliser Future.microtask pour éviter de notifier pendant la phase de build
    Future.microtask(() {
      notifyListeners();
    });
  }

  Future<List<(Consumption, StockItem)>> getConsumptionsWithStockItems(
    String bookingId,
  ) async {
    if (!_initialized) {
      await initialize();
    }
    
    // Subscribe to realtime updates for this booking
    subscribeToBookingConsumptions(bookingId);

    // Vérifier d'abord le cache local pour avoir les données les plus récentes
    if (_localConsumptionsCache.containsKey(bookingId) &&
        _localConsumptionsCache[bookingId]!.isNotEmpty) {
      return _localConsumptionsCache[bookingId]!;
    }

    // Ensuite vérifier le cache persistant
    final cachedEntry = _consumptionsCache[bookingId];
    if (cachedEntry != null && !cachedEntry.isExpired) {
      // Copier les données du cache persistant vers le cache local
      _localConsumptionsCache[bookingId] = List.from(
        cachedEntry.data.consumptions,
      );
      return cachedEntry.data.consumptions;
    }

    try {
      // Si pas de cache valide, chercher en base de données
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

      // Mettre à jour les deux caches
      _updateConsumptionsCache(bookingId, result);
      _localConsumptionsCache[bookingId] = List.from(result);

      return result;
    } catch (e) {
      _error = 'Erreur lors de la récupération des consommations: $e';
      // Utiliser Future.microtask pour éviter de notifier pendant la phase de build
      Future.microtask(() {
        notifyListeners();
      });

      // Retourner les données en cache même si expirées en cas d'erreur
      if (_localConsumptionsCache.containsKey(bookingId)) {
        return _localConsumptionsCache[bookingId]!;
      }
      return cachedEntry?.data.consumptions ?? [];
    }
  }

  Future<bool> addConsumption({
    required String bookingId,
    required String stockItemId,
    required int quantity,
  }) async {
    try {
      debugPrint(
        'StockViewModel: Adding consumption - bookingId: $bookingId, stockItemId: $stockItemId, quantity: $quantity',
      );

      // Rechercher l'article avec la méthode dédiée pour assurer la cohérence
      final stockItem = findStockItemById(stockItemId);
      if (stockItem == null) {
        throw Exception('Article non trouvé (ID: $stockItemId)');
      }

      debugPrint(
        'StockViewModel: Found stock item: ${stockItem.name} (ID: ${stockItem.id})',
      );

      // Get the booking to access its formula
      final booking = await bookingViewModel.getBooking(bookingId);

      // Get existing consumptions for this booking from local cache + persistent cache
      List<(Consumption, StockItem)> existingConsumptions = [];
      
      // Fast lookup from cache (debug prints removed for performance)
      
      // Priorité 1: Cache local (contient les ajouts récents)
      if (_localConsumptionsCache.containsKey(bookingId)) {
        existingConsumptions = List.from(_localConsumptionsCache[bookingId]!);
      } 
      // Priorité 2: Cache persistant
      else if (_consumptionsCache.containsKey(bookingId)) {
        existingConsumptions = List.from(_consumptionsCache[bookingId]!.data.consumptions);
      }
      // Priorité 3: Base de données (si aucun cache disponible)
      else {
        existingConsumptions = await getConsumptionsWithStockItems(bookingId);
      }

      // Create consumption with Social Deal logic
      final tempConsumption = _socialDealService.createConsumption(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        bookingId: bookingId,
        stockItemId: stockItemId,
        quantity: quantity,
        timestamp: DateTime.now(),
        formula: booking.formula,
        stockItem: stockItem,
        bookingPersons: booking.numberOfPersons,
        existingConsumptions: existingConsumptions.map((pair) => pair.$1).toList(),
        allStockItems: items, // Pass all stock items for proper Social Deal quota calculation
      );
      
      // Social Deal pricing calculated (debug logs removed for performance)

      // Mettre à jour le cache local immédiatement pour une UI réactive
      _updateLocalConsumptionsCache(
        bookingId,
        tempConsumption,
        stockItem,
        true,
      );
      
      // Notifier immédiatement sans throttling après la mise à jour du cache local
      _notifyListenersImmediate(bookingId);

      // Effectuer la mise à jour en base de données en arrière-plan
      final result = await _repository.addConsumption(
        bookingId: bookingId,
        stockItemId: stockItemId,
        quantity: quantity,
        unitPrice: tempConsumption.unitPrice,
        isIncluded: tempConsumption.isIncluded,
      );

      // Debug: vérifier que la consommation de la DB a les bonnes valeurs
      debugPrint('🔍 DB Result: unitPrice=${result.unitPrice}, isIncluded=${result.isIncluded}, totalPrice=${result.totalPrice}');
      
      // Remplacer la consommation temporaire par la vraie dans le cache local
      _replaceLocalConsumption(
        bookingId,
        tempConsumption.id,
        result,
        stockItem,
      );

      // Mettre à jour le cache permanent
      _addConsumptionToCache(bookingId, result, stockItem);

      // Rafraîchir le stock car il a été modifié
      // Utiliser un flag pour éviter les notifications multiples
      await refreshStock(silent: true);

      debugPrint('StockViewModel: Consumption added successfully');
      
      // Send notification for consumption added
      _notificationService.notifyConsumptionAdded(
        bookingId,
        stockItem.name,
        quantity,
      );
      
      // Check if stock became low after consumption and send alert
      final updatedStockItem = findStockItemById(stockItemId);
      if (updatedStockItem != null && updatedStockItem.isLowStock) {
        _notificationService.notifyStockAlert(
          updatedStockItem.name,
          updatedStockItem.quantity,
          updatedStockItem.alertThreshold,
        );
      }
      
      // Notifier tous les listeners pour déclencher la mise à jour des UI
      Future.microtask(() {
        notifyListeners();
      });
      
      return true;
    } catch (e) {
      // En cas d'erreur, supprimer la consommation temporaire du cache local
      if (_localConsumptionsCache.containsKey(bookingId)) {
        _localConsumptionsCache[bookingId]?.removeWhere(
          (pair) => pair.$1.id.startsWith('temp_'),
        );
        notifyLocalUpdate(bookingId);
      }

      _error = e.toString();
      debugPrint('StockViewModel: Error adding consumption: $e');
      // Utiliser Future.microtask pour éviter de notifier pendant la phase de build
      Future.microtask(() {
        notifyListeners();
      });
      return false;
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    // Utiliser Future.microtask pour éviter de notifier pendant la phase de build
    Future.microtask(() {
      notifyListeners();
    });
  }

  Future<void> updateConsumptionQuantity({
    required Consumption consumption,
    required int newQuantity,
  }) async {
    if (newQuantity < 1) {
      throw Exception('La quantité ne peut pas être inférieure à 1');
    }

    final bookingId = consumption.bookingId;
    final previousConsumption = consumption;

    // Trouver l'article de stock correspondant
    final stockItem = items.firstWhere(
      (item) => item.id == consumption.stockItemId,
      orElse: () => throw Exception('Article introuvable'),
    );

    try {
      // 1. Mettre à jour immédiatement la quantité pour la réactivité UI
      final tempConsumption = consumption.copyWith(quantity: newQuantity);
      _updateLocalConsumptionsCache(
        bookingId,
        tempConsumption,
        stockItem,
        false,
      );
      
      // Notifier immédiatement pour la réactivité UI
      notifyLocalUpdate(bookingId);

      // 2. Effectuer les calculs complexes en arrière-plan
      _performAsyncPricingUpdate(
        bookingId,
        consumption,
        newQuantity,
        stockItem,
        previousConsumption,
      );
    } catch (e) {
      // Restaurer l'ancienne valeur en cas d'erreur
      _updateLocalConsumptionsCache(
        bookingId,
        previousConsumption,
        stockItem,
        false,
      );
      notifyLocalUpdate(bookingId);
      _error = e.toString();
      rethrow;
    }
  }

  // Méthode asynchrone pour les calculs de pricing complexes sans bloquer l'UI
  Future<void> _performAsyncPricingUpdate(
    String bookingId,
    Consumption originalConsumption,
    int newQuantity,
    StockItem stockItem,
    Consumption previousConsumption,
  ) async {
    try {
      // Get booking info (peut être mis en cache)
      final booking = await bookingViewModel.getBooking(bookingId);
      
      Consumption finalConsumption;
      
      // Vérifier si c'est un Social Deal qui nécessite un recalcul
      if (booking.formula.type == FormulaType.socialDeal && stockItem.includedInSocialDeal) {
        // Utiliser les données du cache local plutôt que la DB pour être plus rapide
        final localConsumptions = _localConsumptionsCache[bookingId] ?? [];
        final otherConsumptions = localConsumptions
            .where((pair) => pair.$1.id != originalConsumption.id)
            .map((pair) => pair.$1)
            .toList();
        
        // Calculs Social Deal en arrière-plan
        final pricing = _socialDealService.calculateConsumptionPricing(
          formula: booking.formula,
          stockItem: stockItem,
          quantity: newQuantity,
          bookingPersons: booking.numberOfPersons,
          existingConsumptions: otherConsumptions,
          allStockItems: items, // Pass all stock items for proper Social Deal quota calculation
        );
        
        finalConsumption = originalConsumption.copyWith(
          quantity: newQuantity,
          unitPrice: pricing['unitPrice'] as double,
          isIncluded: pricing['isIncluded'] as bool,
          // totalPrice is calculated dynamically based on unitPrice and isIncluded
        );
        
        // Background pricing completed
      } else {
        // Non-Social Deal, simple mise à jour
        finalConsumption = originalConsumption.copyWith(quantity: newQuantity);
      }

      // Mettre à jour le cache local avec les vrais prix
      _updateLocalConsumptionsCache(
        bookingId,
        finalConsumption,
        stockItem,
        false,
      );
      
      // Notifier de la mise à jour des prix
      notifyLocalUpdate(bookingId);

      // Sauvegarder en DB en arrière-plan
      await _repository.updateConsumption(finalConsumption);
      
      // Mettre à jour le cache persistant
      _updateConsumptionInCache(bookingId, finalConsumption);
      
      // Rafraîchir le stock silencieusement
      await refreshStock(silent: true);
      
    } catch (e) {
      debugPrint('Erreur dans les calculs de pricing en arrière-plan: $e');
      // En cas d'erreur, restaurer la consommation précédente
      _updateLocalConsumptionsCache(
        bookingId,
        previousConsumption,
        stockItem,
        false,
      );
      notifyLocalUpdate(bookingId);
    }
  }

  Future<void> deleteConsumption({required Consumption consumption}) async {
    final bookingId = consumption.bookingId;

    // Rechercher l'article de stock correspondant pour le cache local
    final stockItem = items.firstWhere(
      (item) => item.id == consumption.stockItemId,
      orElse: () => throw Exception('Article introuvable'),
    );

    // Retirer immédiatement du cache local pour une UI réactive
    if (_localConsumptionsCache.containsKey(bookingId)) {
      _localConsumptionsCache[bookingId]?.removeWhere(
        (pair) => pair.$1.id == consumption.id,
      );
      notifyLocalUpdate(bookingId);
    }

    // Retirer également du cache permanent de manière asynchrone
    Future.microtask(() {
      _removeConsumptionFromCache(bookingId, consumption.id);
    });

    try {
      // Envoyer la suppression à la base de données en arrière-plan
      await _repository.deleteConsumption(consumption.id);
      await refreshStock(silent: true);

      // En cas de succès, on notifie à nouveau pour s'assurer que tout est à jour
      notifyLocalUpdate(bookingId);
    } catch (e) {
      debugPrint('Erreur lors de la suppression de la consommation: $e');

      // Gérer la restauration de la consommation en cas d'erreur
      if (_localConsumptionsCache.containsKey(bookingId)) {
        // Restaurer la consommation dans le cache local
        _localConsumptionsCache[bookingId]?.add((consumption, stockItem));

        // Restaurer également dans le cache persistant
        if (_consumptionsCache.containsKey(bookingId)) {
          final persistentCache = _consumptionsCache[bookingId]!;
          final persistentConsumptions = List<(Consumption, StockItem)>.from(
            persistentCache.data.consumptions,
          );

          persistentConsumptions.add((consumption, stockItem));

          // Mettre à jour le cache persistant
          final total = calculateConsumptionTotal(persistentConsumptions);
          _consumptionsCache[bookingId] = CacheEntry(
            data: ConsumptionCacheEntry(
              consumptions: persistentConsumptions,
              total: total,
              timestamp: DateTime.now(),
            ),
            timestamp: DateTime.now(),
          );
        }

        // Notifier la restauration
        notifyLocalUpdate(bookingId);
      }

      // Rethrow pour permettre au widget de gérer l'erreur visuellement
      rethrow;
    }
  }

  // Map pour tracking des dernières mises à jour par booking
  final Map<String, int> _lastUpdateTimestamps = {};

  // Méthodes privées de gestion du cache
  void _updateConsumptionsCache(
    String bookingId,
    List<(Consumption, StockItem)> consumptions,
  ) {
    final total = calculateConsumptionTotal(consumptions);

    // Vérifier si la valeur a réellement changé avant de déclencher des notifications
    final existingEntry = _consumptionsCache[bookingId];
    final hasChanged =
        existingEntry == null ||
        existingEntry.data.total != total ||
        !_compareConsumptionLists(
          existingEntry.data.consumptions,
          consumptions,
        );

    if (!hasChanged) {
      return; // Sortir immédiatement si rien n'a changé
    }

    // Mettre à jour le cache immédiatement
    _consumptionsCache[bookingId] = CacheEntry<ConsumptionCacheEntry>(
      data: ConsumptionCacheEntry(
        consumptions: consumptions,
        total: total,
        timestamp: DateTime.now(),
      ),
      timestamp: DateTime.now(),
    );

    // Synchroniser avec le cache local
    _localConsumptionsCache[bookingId] = List.from(consumptions);

    // Debounce pour éviter trop de mises à jour
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastUpdate = _lastUpdateTimestamps[bookingId] ?? 0;

    if (now - lastUpdate < 100) {
      // Si moins de 100ms depuis la dernière mise à jour, ignorer
      return;
    }

    _lastUpdateTimestamps[bookingId] = now;

    // Mettre à jour le service de prix de manière sécurisée
    try {
      final priceService = ConsumptionPriceService();
      priceService.updateConsumptionPrice(bookingId, total);

      // Mettre à jour les totaux de réservation de manière asynchrone pour éviter les boucles
      Future.microtask(() {
        try {
          bookingViewModel.updateBookingTotals(bookingId, total);
          notifyListeners();
        } catch (e) {
          debugPrint('Erreur lors de la mise à jour des totaux: $e');
        }
      });
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du prix: $e');
      Future.microtask(() {
        notifyListeners();
      });
    }
  }

  // Helper pour comparer deux listes de consommations
  bool _compareConsumptionLists(
    List<(Consumption, StockItem)> list1,
    List<(Consumption, StockItem)> list2,
  ) {
    if (list1.length != list2.length) return false;

    // Comparer par ID et quantité pour détecter les changements pertinents
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].$1.id != list2[i].$1.id ||
          list1[i].$1.quantity != list2[i].$1.quantity) {
        return false;
      }
    }

    return true;
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
    
    // S'assurer que les notifications sont propagées
    notifyLocalUpdate(bookingId);
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
        
        // S'assurer que les notifications sont propagées
        notifyLocalUpdate(bookingId);
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
      
      // S'assurer que les notifications sont propagées
      notifyLocalUpdate(bookingId);
    }
  }

  // Méthode pour mettre à jour le cache local
  void _updateLocalConsumptionsCache(
    String bookingId,
    Consumption consumption,
    StockItem stockItem,
    bool isNew,
  ) {
    // Fast local cache update (debug logs removed for performance)
    if (!_localConsumptionsCache.containsKey(bookingId)) {
      _localConsumptionsCache[bookingId] = [];
    }

    final localConsumptions = _localConsumptionsCache[bookingId]!;

    if (isNew) {
      // Ajouter la nouvelle consommation
      localConsumptions.add((consumption, stockItem));
    } else {
      // Mettre à jour une consommation existante
      final index = localConsumptions.indexWhere(
        (pair) => pair.$1.id == consumption.id,
      );
      if (index != -1) {
        localConsumptions[index] = (consumption, stockItem);
      } else {
        // Si non trouvée, l'ajouter quand même
        localConsumptions.add((consumption, stockItem));

        // Synchroniser avec le cache persistant si nécessaire
        if (_consumptionsCache.containsKey(bookingId)) {
          final persistentCache = _consumptionsCache[bookingId]!;
          final persistentConsumptions = List<(Consumption, StockItem)>.from(
            persistentCache.data.consumptions,
          );

          // Si elle n'est pas dans le cache persistant non plus, l'ajouter
          if (!persistentConsumptions.any(
            (pair) => pair.$1.id == consumption.id,
          )) {
            persistentConsumptions.add((consumption, stockItem));

            // Mettre à jour le cache persistant
            final total = calculateConsumptionTotal(persistentConsumptions);
            _consumptionsCache[bookingId] = CacheEntry(
              data: ConsumptionCacheEntry(
                consumptions: persistentConsumptions,
                total: total,
                timestamp: DateTime.now(),
              ),
              timestamp: DateTime.now(),
            );
          }
        }
      }
    }

    // Recalculer le total et notifier
    notifyLocalUpdate(bookingId);
  }

  // Remplacer une consommation temporaire par sa version permanente
  void _replaceLocalConsumption(
    String bookingId,
    String tempId,
    Consumption permanentConsumption,
    StockItem stockItem,
  ) {
    if (_localConsumptionsCache.containsKey(bookingId)) {
      final localConsumptions = _localConsumptionsCache[bookingId]!;
      final index = localConsumptions.indexWhere(
        (pair) => pair.$1.id == tempId,
      );
      if (index != -1) {
        localConsumptions[index] = (permanentConsumption, stockItem);
        _notifyListenersImmediate(bookingId);
      }
    }
  }

  // Notifier les changements locaux sans attendre la base de données
  void notifyLocalUpdate(String bookingId) {
    if (_localConsumptionsCache.containsKey(bookingId)) {
      // Limiter la fréquence des mises à jour
      if (_shouldThrottleUpdate(bookingId)) {
        debugPrint('StockViewModel: Throttling update for $bookingId');
        return;
      }

      final localConsumptions = _localConsumptionsCache[bookingId]!;
      final total = calculateConsumptionTotal(localConsumptions);

      debugPrint('StockViewModel: Notifying local update for $bookingId with total $total');

      try {
        // Mettre à jour le service de prix immédiatement
        final priceService = ConsumptionPriceService();
        priceService.updateConsumptionPriceSync(bookingId, total);

        // Notifier immédiatement les listeners pour une UI réactive
        notifyListeners();

        // Mettre à jour le BookingViewModel de manière asynchrone pour éviter les conflits
        Future.microtask(() {
          try {
            bookingViewModel.updateBookingInCache(
              bookingId,
              newConsumptionsTotal: total,
            );
          } catch (e) {
            debugPrint('Erreur lors de la mise à jour en arrière-plan: $e');
          }
        });
      } catch (e) {
        debugPrint('Erreur lors de la mise à jour immédiate du prix: $e');

        // Continuer malgré l'erreur pour assurer que l'UI reste réactive
        notifyListeners();
      }
    }
  }

  double calculateConsumptionTotal(
    List<(Consumption, StockItem)> consumptions,
  ) {
    return consumptions.fold(
      0,
      (total, pair) => total + pair.$1.totalPrice,
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

  Future<void> incrementQuantity(StockItem item) async {
    await _updateItemQuantity(item, item.quantity + 1);
  }

  Future<void> decrementQuantity(StockItem item) async {
    if (item.quantity > 0) {
      await _updateItemQuantity(item, item.quantity - 1);
    }
  }

  Future<void> incrementQuantityBy(StockItem item, int amount) async {
    await _updateItemQuantity(item, item.quantity + amount);
  }

  Future<void> _updateItemQuantity(StockItem item, int newQuantity) async {
    final oldQuantity = item.quantity;
    final updatedItem = item.copyWith(quantity: newQuantity);
    await _repository.updateStockItem(updatedItem);
    await refreshStock();
    
    // Send stock update notification
    _notificationService.notifyStockUpdated(
      item.name,
      newQuantity,
      isLowStock: updatedItem.isLowStock,
    );
    
    // Send low stock alert if item becomes low stock
    if (updatedItem.isLowStock && oldQuantity > item.alertThreshold) {
      _notificationService.notifyStockAlert(
        item.name,
        newQuantity,
        item.alertThreshold,
      );
    }
  }

  // Helper pour éviter trop de notifications rapprochées
  final Map<String, int> _lastUpdateTimes = {};
  final int _minUpdateInterval = 100; // ms minimum entre deux mises à jour

  bool _shouldThrottleUpdate(String bookingId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastUpdate = _lastUpdateTimes[bookingId] ?? 0;

    if (now - lastUpdate < _minUpdateInterval) {
      return true;
    }

    _lastUpdateTimes[bookingId] = now;
    return false;
  }

  // Notification immédiate sans throttling (pour les ajouts de consommation)
  void _notifyListenersImmediate(String bookingId) {
    if (_localConsumptionsCache.containsKey(bookingId)) {
      final localConsumptions = _localConsumptionsCache[bookingId]!;
      final total = calculateConsumptionTotal(localConsumptions);

      debugPrint('StockViewModel: Immediate notify for $bookingId with total $total');

      try {
        // Mettre à jour le service de prix immédiatement
        final priceService = ConsumptionPriceService();
        priceService.updateConsumptionPriceSync(bookingId, total);

        // Notifier immédiatement les listeners
        notifyListeners();

        // Forcer la mise à jour des timestamps pour éviter les conflits
        _lastUpdateTimes[bookingId] = DateTime.now().millisecondsSinceEpoch;

        debugPrint('StockViewModel: Immediate notification sent for $bookingId');
      } catch (e) {
        debugPrint('StockViewModel: Error in immediate notification: $e');
      }
    }
  }

  // Méthode permettant de trouver un article par son ID de manière cohérente
  StockItem? findStockItemById(String stockItemId) {
    try {
      // Chercher d'abord dans la liste des articles actifs
      if (_stockCache?.data != null) {
        final found = _stockCache!.data.firstWhere(
          (item) => item.id == stockItemId,
          orElse: () => throw Exception('Not found in active items'),
        );
        return found;
      }

      // Si non trouvé ou pas de cache, chercher dans tous les articles
      if (_allStockCache?.data != null) {
        final found = _allStockCache!.data.firstWhere(
          (item) => item.id == stockItemId,
          orElse: () => throw Exception('Not found in all items'),
        );
        return found;
      }

      return null;
    } catch (e) {
      debugPrint('Error finding stock item: $e');
      return null;
    }
  }

  // Set pour éviter les chargements multiples simultanés
  final Set<String> _loadingConsumptions = {};

  // Charger les consommations de manière asynchrone pour une réservation
  void _loadConsumptionsAsync(String bookingId) {
    // Éviter les chargements multiples simultanés
    if (_loadingConsumptions.contains(bookingId)) {
      return;
    }

    _loadingConsumptions.add(bookingId);
    
    debugPrint('StockViewModel: Loading consumptions async for booking $bookingId');

    Future.microtask(() async {
      try {
        final consumptions = await getConsumptionsWithStockItems(bookingId);
        final total = calculateConsumptionTotal(consumptions);

        // Mettre à jour le cache persistant
        _consumptionsCache[bookingId] = CacheEntry(
          data: ConsumptionCacheEntry(
            consumptions: consumptions,
            total: total,
            timestamp: DateTime.now(),
          ),
          timestamp: DateTime.now(),
        );

        // Mettre à jour le service de prix
        final priceService = ConsumptionPriceService();
        priceService.updateConsumptionPriceSync(bookingId, total);

        debugPrint('StockViewModel: Loaded consumptions for booking $bookingId with total $total');
        
        // Notifier les listeners
        notifyListeners();
      } catch (e) {
        debugPrint('StockViewModel: Error loading consumptions for booking $bookingId: $e');
      } finally {
        _loadingConsumptions.remove(bookingId);
      }
    });
  }
  
  // Clean up unused subscription when booking is closed
  void cleanupBookingSubscription(String bookingId) {
    unsubscribeFromBookingConsumptions(bookingId);
    _localConsumptionsCache.remove(bookingId);
    _consumptionsCache.remove(bookingId);
  }
}
