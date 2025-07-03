// filepath: /Users/thimotefetu/Sites/Laser-Magique-App/lib/viewmodels/stock_view_model.dart
import 'package:flutter/foundation.dart';
import '../models/stock_item_model.dart';
import '../../../shared/models/consumption_model.dart';
import '../../../shared/services/consumption_price_service.dart';
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

  // Cache local pour les consommations en cours de modification
  // Ce cache est prioritaire sur la base de données pour des mises à jour immédiates
  final Map<String, List<(Consumption, StockItem)>> _localConsumptionsCache =
      {};

  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;
  bool _initialized = false;

  StockViewModel(this.bookingViewModel) {
    initialize();
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
      throw e;
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

      // Rechercher l'article dans le stock local pour une mise à jour optimiste
      final stockItem = items.firstWhere((item) => item.id == stockItemId);

      // Créer une consommation temporaire locale avec un ID unique temporaire
      final tempConsumption = Consumption(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        bookingId: bookingId,
        stockItemId: stockItemId,
        quantity: quantity,
        timestamp: DateTime.now(),
        unitPrice: stockItem.price,
      );

      // Mettre à jour le cache local immédiatement pour une UI réactive
      _updateLocalConsumptionsCache(
        bookingId,
        tempConsumption,
        stockItem,
        true,
      );

      // Effectuer la mise à jour en base de données en arrière-plan
      final result = await _repository.addConsumption(
        bookingId: bookingId,
        stockItemId: stockItemId,
        quantity: quantity,
      );

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

    final updatedConsumption = consumption.copyWith(quantity: newQuantity);
    final previousConsumption = consumption;
    final bookingId = consumption.bookingId;

    // Trouver l'article de stock correspondant
    final stockItem = items.firstWhere(
      (item) => item.id == consumption.stockItemId,
      orElse: () => throw Exception('Article introuvable'),
    );

    try {
      // Mettre à jour immédiatement le cache local pour un affichage instantané
      _updateLocalConsumptionsCache(
        bookingId,
        updatedConsumption,
        stockItem,
        false,
      );

      // Envoyer la mise à jour à la base de données en arrière-plan
      await _repository.updateConsumption(updatedConsumption);

      // Mise à jour du cache permanent une fois la mise à jour confirmée
      Future.microtask(() {
        _updateConsumptionInCache(consumption.bookingId, updatedConsumption);
      });

      // Rafraîchir les données du stock de manière asynchrone
      await refreshStock(silent: true);
    } catch (e) {
      // Restaurer l'ancienne valeur dans les caches en cas d'erreur
      if (_localConsumptionsCache.containsKey(bookingId)) {
        _updateLocalConsumptionsCache(
          bookingId,
          previousConsumption,
          stockItem,
          false,
        );
      }

      Future.microtask(() {
        _updateConsumptionInCache(consumption.bookingId, previousConsumption);
      });
      _error = e.toString();
      rethrow;
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

  // Méthode pour mettre à jour le cache local
  void _updateLocalConsumptionsCache(
    String bookingId,
    Consumption consumption,
    StockItem stockItem,
    bool isNew,
  ) {
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
        notifyLocalUpdate(bookingId);
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

      // Pour éviter les notifications circulaires, vérifier si le total a changé
      final currentTotal = getConsumptionTotal(bookingId);
      if (currentTotal == total) {
        debugPrint('StockViewModel: Skipping update, total unchanged ($total)');
        return;
      }

      try {
        // Mettre à jour le service de prix de manière sûre (post-frame)
        final priceService = ConsumptionPriceService();

        // Utiliser Future.microtask pour éviter les mises à jour pendant la phase de build
        Future.microtask(() {
          try {
            priceService.updateConsumptionPrice(bookingId, total);

            // Notifier le BookingViewModel en dehors du cycle de build
            bookingViewModel.updateBookingInCache(
              bookingId,
              newConsumptionsTotal: total,
            );
            notifyListeners();
          } catch (e) {
            debugPrint('Erreur lors de la mise à jour en arrière-plan: $e');
          }
        });
      } catch (e) {
        debugPrint('Erreur lors de la mise à jour immédiate du prix: $e');

        // Continuer malgré l'erreur pour assurer que l'UI reste réactive
        Future.microtask(() {
          notifyListeners();
        });
      }
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
    final updatedItem = item.copyWith(quantity: newQuantity);
    await _repository.updateStockItem(updatedItem);
    await refreshStock();
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
}
